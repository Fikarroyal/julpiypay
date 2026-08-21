import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  BillStatus? _statusFilter;

  Future<void> _markAsPaid(BillModel bill) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark "${bill.name}" as paid?',
      message: 'An expense of ${CurrencyFormatter.format(bill.amount)} will be recorded on ${bill.isRecurring ? 'this account and the bill will roll over to next month' : 'this account'}.',
      confirmLabel: 'Mark as paid',
      danger: false,
    );
    if (!confirmed) return;

    await ref.read(transactionRepoProvider).insert(TransactionModel(
          type: TransactionType.expense,
          amount: bill.amount,
          categoryId: bill.categoryId,
          accountId: bill.accountId,
          date: DateTime.now(),
          note: 'Bill payment: ${bill.name}',
          createdAt: DateTime.now(),
        ));

    if (bill.isRecurring) {
      final nextMonth = DateTime(bill.dueDate.year, bill.dueDate.month + 1, bill.dueDate.day);
      await ref.read(billRepoProvider).update(bill.copyWith(dueDate: nextMonth, isPaid: false));
    } else {
      await ref.read(billRepoProvider).update(bill.copyWith(isPaid: true));
    }
    notifyDataChanged(ref);
    if (mounted) context.showSnack('Bill marked as paid');
  }

  Future<void> _delete(BillModel bill) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${bill.name}"?',
      message: 'This bill will be permanently removed.',
    );
    if (!confirmed) return;
    await ref.read(billRepoProvider).delete(bill.id!);
    notifyDataChanged(ref);
    if (mounted) context.showSnack('Bill deleted');
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bills/add'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppChip(label: 'All', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                    const SizedBox(width: 8),
                    AppChip(label: 'Upcoming', selected: _statusFilter == BillStatus.upcoming, onTap: () => setState(() => _statusFilter = BillStatus.upcoming)),
                    const SizedBox(width: 8),
                    AppChip(label: 'Due today', color: AppColors.warning, selected: _statusFilter == BillStatus.dueToday, onTap: () => setState(() => _statusFilter = BillStatus.dueToday)),
                    const SizedBox(width: 8),
                    AppChip(label: 'Overdue', color: AppColors.expense, selected: _statusFilter == BillStatus.overdue, onTap: () => setState(() => _statusFilter = BillStatus.overdue)),
                    const SizedBox(width: 8),
                    AppChip(label: 'Paid', selected: _statusFilter == BillStatus.paid, onTap: () => setState(() => _statusFilter = BillStatus.paid)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: billsAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: List.generate(4, (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10), child: SkeletonCard(height: 84))),
                ),
                error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
                data: (bills) {
                  final filtered = _statusFilter == null
                      ? bills
                      : bills.where((b) => b.status == _statusFilter).toList();
                  filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.receiptText,
                      title: 'No bills here',
                      message: 'Add a bill to get reminders before it is due.',
                      actionLabel: 'Add bill',
                      onAction: () => context.push('/bills/add'),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(context.horizontalPadding, 4, context.horizontalPadding, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final b = filtered[i];
                      final color = b.status == BillStatus.overdue
                          ? AppColors.expense
                          : b.status == BillStatus.dueToday
                              ? AppColors.warning
                              : b.status == BillStatus.paid
                                  ? AppColors.income
                                  : context.colors.primary;
                      return AppCard(
                        onTap: () => context.push('/bills/edit/${b.id}'),
                        child: Row(
                          children: [
                            IconBadge(
                                icon: b.status == BillStatus.paid ? LucideIcons.checkCheck : LucideIcons.receiptText,
                                color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name, style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    b.status == BillStatus.paid ? 'Paid' : DateFormatter.dueLabel(b.dueDate),
                                    style: context.textStyles.bodySmall?.copyWith(color: color),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(CurrencyFormatter.format(b.amount),
                                    style: AppTextStyles.amount(context.textStyles.bodyLarge!.color!, size: 14)),
                                const SizedBox(height: 4),
                                if (b.status != BillStatus.paid)
                                  GestureDetector(
                                    onTap: () => _markAsPaid(b),
                                    child: Text('Mark as paid',
                                        style: TextStyle(color: context.colors.primary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () => _delete(b),
                                    child: const Text('Delete', style: TextStyle(color: AppColors.expense, fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
