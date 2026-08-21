import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _incomeTargetController = TextEditingController();
  final _savingTargetController = TextEditingController(text: '20');
  int? _preferredAccountId;
  int _monthStart = 1;
  bool _saving = false;
  bool _loaded = false;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(profileRepoProvider).get();
    setState(() {
      _profile = profile;
      _nameController.text = profile?.displayName ?? '';
      _incomeTargetController.text = (profile?.monthlyIncomeTarget ?? 0).toStringAsFixed(0);
      _savingTargetController.text = (profile?.savingTargetPercent ?? 20).toStringAsFixed(0);
      _preferredAccountId = profile?.preferredAccountId;
      _monthStart = profile?.financialMonthStart ?? 1;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeTargetController.dispose();
    _savingTargetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      context.showSnack('Name is required', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = UserProfileModel(
        displayName: _nameController.text.trim(),
        monthlyIncomeTarget: CurrencyFormatter.parse(_incomeTargetController.text),
        savingTargetPercent: double.tryParse(_savingTargetController.text) ?? 20,
        preferredAccountId: _preferredAccountId,
        financialMonthStart: _monthStart,
        themeMode: _profile?.themeMode ?? 'system',
        onboardingComplete: true,
      );
      await ref.read(profileRepoProvider).save(model);
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack('Profile updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAccount() async {
    final accounts = await ref.read(accountsProvider.future);
    final selected = await showAppBottomSheet<int>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Preferred account', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          ...accounts.map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: iconFromKey(a.icon), color: colorFromHex(a.color)),
                title: Text(a.name),
                onTap: () => Navigator.pop(context, a.id),
              )),
        ],
      ),
    );
    if (selected != null) setState(() => _preferredAccountId = selected);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final accountsAsync = ref.watch(accountsProvider);
    final account = (accountsAsync.valueOrNull ?? []).where((a) => a.id == _preferredAccountId).cast<dynamic>().firstWhere((_) => true, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
          children: [
            AppTextField(controller: _nameController, label: 'Display name'),
            const SizedBox(height: 20),
            AppTextField(
              controller: _incomeTargetController,
              label: 'Monthly income target',
              keyboardType: TextInputType.number,
              prefixIcon: LucideIcons.target,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _savingTargetController,
              label: 'Saving target (%)',
              keyboardType: TextInputType.number,
              prefixIcon: LucideIcons.piggyBank,
            ),
            const SizedBox(height: 20),
            Text('Preferred account', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickAccount,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.wallet, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(account?.name ?? 'None selected')),
                  const Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Financial month starts on day $_monthStart', style: context.textStyles.labelLarge),
            Slider(
              value: _monthStart.toDouble(),
              min: 1,
              max: 28,
              divisions: 27,
              activeColor: context.colors.primary,
              onChanged: (v) => setState(() => _monthStart = v.round()),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Save profile', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
