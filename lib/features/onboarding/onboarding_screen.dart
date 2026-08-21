import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/demo_seeder.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardPage(this.icon, this.title, this.subtitle);
}

const _pages = [
  _OnboardPage(LucideIcons.notebookPen, 'Track your money',
      'Catat setiap pemasukan dan pengeluaran dengan cepat, kurang dari 10 detik.'),
  _OnboardPage(LucideIcons.chartPie, 'Understand your spending',
      'Lihat kemana uangmu pergi lewat laporan dan grafik yang jelas.'),
  _OnboardPage(LucideIcons.target, 'Reach your financial goals',
      'Atur anggaran, tabungan, dan tagihan supaya target finansialmu tercapai.'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;
  bool _loading = false;

  Future<void> _finish({required bool useDemo}) async {
    setState(() => _loading = true);
    try {
      if (useDemo) {
        await DemoSeeder().seed();
      }
      await ref.read(profileRepoProvider).save(UserProfileModel(
            displayName: 'Kamu',
            monthlyIncomeTarget: 10000000,
            savingTargetPercent: 20,
            onboardingComplete: true,
          ));
      await ref.read(onboardingStatusProvider.notifier).complete();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      context.showSnack('Gagal menyiapkan data: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _loading ? null : () => _finish(useDemo: false),
                  child: const Text('Lewati'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(context.isDark ? 0.15 : 1),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(page.icon, size: 52, color: context.colors.primary),
                        ),
                        const SizedBox(height: 36),
                        Text(page.title,
                            style: context.textStyles.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(page.subtitle,
                            style: context.textStyles.bodyMedium, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? context.colors.primary : context.theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isLast
                  ? Column(
                      children: [
                        AppButton(
                          label: 'Mulai dengan data demo',
                          icon: LucideIcons.sparkles,
                          loading: _loading,
                          onPressed: () => _finish(useDemo: true),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Mulai dari awal',
                          variant: AppButtonVariant.ghost,
                          loading: _loading,
                          onPressed: () => _finish(useDemo: false),
                        ),
                      ],
                    )
                  : AppButton(
                      label: 'Lanjut',
                      icon: LucideIcons.arrowRight,
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
