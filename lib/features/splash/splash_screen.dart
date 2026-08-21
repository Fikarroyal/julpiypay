import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final Animation<double> _scale =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeIn));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingStatusProvider, (previous, next) {
      if (next == null) return;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        context.go(next ? '/home' : '/onboarding');
      });
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(LucideIcons.wallet, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text('Julpiypay',
                    style: AppTextStyles.amount(Colors.white, size: 30).copyWith(letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Your money, clearly managed.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
