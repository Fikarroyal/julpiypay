import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _busy = false;
  String? _lastAction;

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _lastAction = label;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) context.showSnack('$label failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    final transactions = await ref.read(transactionRepoProvider).getFiltered(const TransactionFilter());
    final categories = await ref.read(categoryRepoProvider).getAll();
    final accounts = await ref.read(accountRepoProvider).getAll();

    final rows = <List<dynamic>>[
      ['date', 'type', 'category', 'account', 'to_account', 'amount', 'note'],
    ];
    for (final t in transactions) {
      final category = categories.where((c) => c.id == t.categoryId).cast<CategoryModel?>().firstWhere((_) => true, orElse: () => null);
      final account = accounts.where((a) => a.id == t.accountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);
      final toAccount = accounts.where((a) => a.id == t.toAccountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);
      rows.add([
        DateFormatter.toDb(t.date),
        t.type.name,
        category?.name ?? '',
        account?.name ?? '',
        toAccount?.name ?? '',
        t.amount,
        t.note ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final fileName = 'julpiypay_transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'Julpiypay transaction export');
    if (mounted) context.showSnack('Exported ${transactions.length} transactions to CSV');
  }

  Future<void> _exportJson() async {
    final transactions = await ref.read(transactionRepoProvider).getFiltered(const TransactionFilter());
    final categories = await ref.read(categoryRepoProvider).getAll();
    final accounts = await ref.read(accountRepoProvider).getAll();
    final budgets = await ref.read(budgetRepoProvider).getAll();
    final goals = await ref.read(savingGoalRepoProvider).getAll();
    final bills = await ref.read(billRepoProvider).getAll();

    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'budgets': budgets.map((b) => b.toMap()).toList(),
      'saving_goals': goals.map((g) => g.toMap()).toList(),
      'bills': bills.map((b) => b.toMap()).toList(),
    };

    final dir = await getTemporaryDirectory();
    final fileName = 'julpiypay_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

    await Share.shareXFiles([XFile(file.path)], text: 'Julpiypay full data export');
    if (mounted) context.showSnack('Exported all data to JSON');
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    if (rows.isEmpty) {
      if (mounted) context.showSnack('CSV file is empty', isError: true);
      return;
    }

    final categories = await ref.read(categoryRepoProvider).getAll();
    final accounts = await ref.read(accountRepoProvider).getAll();
    final categoryByName = {for (final c in categories) c.name.toLowerCase(): c};
    final accountByName = {for (final a in accounts) a.name.toLowerCase(): a};

    var imported = 0;
    var skipped = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) {
        skipped++;
        continue;
      }
      try {
        final date = DateTime.parse(row[0].toString());
        final type = TransactionType.values.firstWhere((t) => t.name == row[1].toString());
        final categoryName = row[2].toString();
        final accountName = row[3].toString();
        final amount = double.parse(row[5].toString());
        final note = row.length > 6 ? row[6].toString() : null;

        final account = accountByName[accountName.toLowerCase()];
        if (account == null) {
          skipped++;
          continue;
        }
        final category = categoryByName[categoryName.toLowerCase()];

        await ref.read(transactionRepoProvider).insert(TransactionModel(
              type: type,
              amount: amount,
              categoryId: category?.id,
              accountId: account.id!,
              date: date,
              note: note?.isEmpty == true ? null : note,
              createdAt: DateTime.now(),
            ));
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    notifyDataChanged(ref);
    if (mounted) {
      context.showSnack('Imported $imported transactions${skipped > 0 ? ' ($skipped skipped)' : ''}');
    }
  }

  Future<void> _backup() async {
    final dbPath = await AppDatabase.instance.dbPath;
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      if (mounted) context.showSnack('No database found yet', isError: true);
      return;
    }
    final dir = await getTemporaryDirectory();
    final fileName = 'julpiypay_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
    final backupFile = await dbFile.copy('${dir.path}/$fileName');
    await Share.shareXFiles([XFile(backupFile.path)], text: 'Julpiypay database backup');
    if (mounted) context.showSnack('Backup created and ready to share');
  }

  Future<void> _restore() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Restore backup?',
      message: 'This will replace all current data with the selected backup file. This cannot be undone.',
      confirmLabel: 'Restore',
    );
    if (!confirmed) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['db']);
    if (result == null || result.files.single.path == null) return;

    final pickedFile = File(result.files.single.path!);
    final dbPath = await AppDatabase.instance.dbPath;

    await AppDatabase.instance.reset();
    await pickedFile.copy(dbPath);

    notifyDataChanged(ref);
    if (mounted) context.showSnack('Data restored successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
          children: [
            Text('EXPORT', style: context.textStyles.labelSmall?.copyWith(letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _ActionTile(
              icon: LucideIcons.fileSpreadsheet,
              label: 'Export as CSV',
              subtitle: 'Spreadsheet, friendly transaction list',
              loading: _busy && _lastAction == 'Export CSV',
              onTap: () => _run('Export CSV', _exportCsv),
            ),
            _ActionTile(
              icon: LucideIcons.fileJson,
              label: 'Export as JSON',
              subtitle: 'Full data export including budgets & goals',
              loading: _busy && _lastAction == 'Export JSON',
              onTap: () => _run('Export JSON', _exportJson),
            ),
            const SizedBox(height: 24),
            Text('IMPORT', style: context.textStyles.labelSmall?.copyWith(letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _ActionTile(
              icon: LucideIcons.fileUp,
              label: 'Import from CSV',
              subtitle: 'Match Julpiypay\'s export format: date, type, category, account, to_account, amount, note',
              loading: _busy && _lastAction == 'Import CSV',
              onTap: () => _run('Import CSV', _importCsv),
            ),
            const SizedBox(height: 24),
            Text('BACKUP & RESTORE', style: context.textStyles.labelSmall?.copyWith(letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _ActionTile(
              icon: LucideIcons.databaseBackup,
              label: 'Backup database',
              subtitle: 'Save a full local copy you can store anywhere',
              loading: _busy && _lastAction == 'Backup',
              onTap: () => _run('Backup', _backup),
            ),
            _ActionTile(
              icon: LucideIcons.rotateCcw,
              label: 'Restore from backup',
              subtitle: 'Replace current data with a .db backup file',
              danger: true,
              loading: _busy && _lastAction == 'Restore',
              onTap: () => _run('Restore', _restore),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Row(
                children: [
                  const IconBadge(icon: LucideIcons.shieldCheck, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All your financial data stays on this device. Julpiypay never sends your data to any server.',
                      style: context.textStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.expense : context.colors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: loading ? null : onTap,
        child: Row(
          children: [
            IconBadge(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.textStyles.bodySmall),
                ],
              ),
            ),
            if (loading)
              const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(LucideIcons.chevronRight, size: 16, color: context.textStyles.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
