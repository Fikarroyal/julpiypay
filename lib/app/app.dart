import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import '../providers/providers.dart';

class JulpiypayApp extends ConsumerWidget {
  const JulpiypayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Julpiypay',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      // Builder global: (1) membatasi text scale device supaya layout tidak
      // pecah saat pengguna set font aksesibilitas ekstra besar, dan
      // (2) membatasi lebar konten di layar lebar (tablet/desktop) supaya
      // UI mobile-first tetap enak dilihat, bukan melebar penuh tak wajar.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
        final isWide = mediaQuery.size.width >= 600;

        Widget content = child ?? const SizedBox.shrink();
        if (isWide) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: content,
            ),
          );
        }
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: content,
        );
      },
    );
  }
}
