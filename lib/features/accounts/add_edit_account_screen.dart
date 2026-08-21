import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  const AddEditAccountScreen({super.key, this.accountId});
  final int? accountId;

  @override
  ConsumerState<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  AccountType _type = AccountType.cash;
  String _icon = kAccountIconKeys.first;
  Color _color = AppColors.categoryPalette.first;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final account = await ref.read(accountRepoProvider).getById(widget.accountId!);
    if (account == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _nameController.text = account.name;
      _balanceController.text = account.initialBalance.toStringAsFixed(0);
      _type = account.type;
      _icon = account.icon;
      _color = colorFromHex(account.color);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final model = AccountModel(
        id: widget.accountId,
        name: _nameController.text.trim(),
        type: _type,
        initialBalance: CurrencyFormatter.parse(_balanceController.text),
        icon: _icon,
        color: colorToHex(_color),
        createdAt: DateTime.now(),
      );
      if (_isEdit) {
        await ref.read(accountRepoProvider).update(model);
      } else {
        await ref.read(accountRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Account updated' : 'Account added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save account: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _typeLabel(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.eWallet:
        return 'E, wallet';
      case AccountType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit account' : 'Add account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
            children: [
              Center(child: IconBadge(icon: iconFromKey(_icon), color: _color, size: 72)),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                label: 'Account name',
                hint: 'e.g. BCA, Cash, GoPay',
                validator: (v) => Validators.name(v, field: 'Account name'),
              ),
              const SizedBox(height: 20),
              Text('Account type', style: context.textStyles.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AccountType.values
                    .map((t) => AppChip(
                          label: _typeLabel(t),
                          selected: _type == t,
                          onTap: () => setState(() => _type = t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _balanceController,
                label: _isEdit ? 'Initial balance' : 'Starting balance',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.banknote,
                validator: (v) => Validators.required(v, field: 'Balance'),
              ),
              const SizedBox(height: 20),
              Text('Icon', style: context.textStyles.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kAccountIconKeys.map((key) {
                  final selected = _icon == key;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? _color.withOpacity(0.15) : context.theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? _color : context.theme.dividerColor, width: selected ? 1.6 : 1),
                      ),
                      child: Icon(iconFromKey(key), size: 19, color: selected ? _color : context.textStyles.bodySmall?.color),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Color', style: context.textStyles.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppColors.categoryPalette.map((c) {
                  final selected = _color.value == c.value;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: context.textStyles.bodyLarge!.color!, width: 2) : null,
                      ),
                      child: selected ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              AppButton(label: 'Save account', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
