import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../budgets/budgets_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialTab;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.arrowLeftRight), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.walletCards), label: 'Budgets'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.chartNoAxesCombined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.userRound), label: 'Profile'),
        ],
      ),
    );
  }
}
