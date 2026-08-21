import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showAppBottomSheet<ThemeMode>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          ...ThemeMode.values.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(m == ThemeMode.light
                    ? LucideIcons.sun
                    : m == ThemeMode.dark
                        ? LucideIcons.moon
                        : LucideIcons.smartphone),
                title: Text(_themeLabel(m)),
                trailing: current == m ? Icon(LucideIcons.check, color: context.colors.primary) : null,
                onTap: () => Navigator.pop(context, m),
              )),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setMode(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 100),
          children: [
            profileAsync.when(
              loading: () => const SkeletonCard(height: 90),
              error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
              data: (profile) => AppCard(
                onTap: () => context.push('/profile/edit'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryLight.withOpacity(context.isDark ? 0.2 : 1),
                      child: Icon(LucideIcons.userRound, size: 28, color: context.colors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.displayName ?? 'You', style: context.textStyles.titleMedium),
                          const SizedBox(height: 2),
                          Text('Monthly target: ${CurrencyFormatter.format(profile?.monthlyIncomeTarget ?? 0)}',
                              style: context.textStyles.bodySmall),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18, color: context.textStyles.bodySmall?.color),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('MANAGE', style: context.textStyles.labelSmall?.copyWith(letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _MenuTile(icon: LucideIcons.tags, label: 'Categories', onTap: () => context.push('/categories')),
            _MenuTile(icon: LucideIcons.wallet, label: 'Accounts', onTap: () => context.push('/accounts')),
            _MenuTile(icon: LucideIcons.piggyBank, label: 'Saving Goals', onTap: () => context.push('/saving_goals')),
            _MenuTile(icon: LucideIcons.receiptText, label: 'Bills', onTap: () => context.push('/bills')),
            _MenuTile(icon: LucideIcons.tag, label: 'Tags', onTap: () => context.push('/tags')),
            _MenuTile(icon: LucideIcons.repeat, label: 'Recurring Transactions', onTap: () => context.push('/recurring')),
            const SizedBox(height: 24),
            Text('PREFERENCES', style: context.textStyles.labelSmall?.copyWith(letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _MenuTile(
              icon: themeMode == ThemeMode.dark
                  ? LucideIcons.moon
                  : themeMode == ThemeMode.light
                      ? LucideIcons.sun
                      : LucideIcons.smartphone,
              label: 'Appearance',
              value: _themeLabel(themeMode),
              onTap: () => _pickTheme(context, ref),
            ),
            _MenuTile(icon: LucideIcons.database, label: 'Data management', onTap: () => context.push('/profile/data')),
            const SizedBox(height: 20),
            Center(
              child: Text('Julpiypay · Your money, clearly managed.',
                  style: context.textStyles.bodySmall, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.value});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: context.textStyles.bodyLarge?.color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
            if (value != null) ...[
              Text(value!, style: context.textStyles.bodySmall),
              const SizedBox(width: 6),
            ],
            Icon(LucideIcons.chevronRight, size: 16, color: context.textStyles.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
