import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_shell.dart';
import '../features/transactions/add_edit_transaction_screen.dart';
import '../features/transactions/transaction_detail_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/categories/add_edit_category_screen.dart';
import '../features/accounts/accounts_screen.dart';
import '../features/accounts/add_edit_account_screen.dart';
import '../features/accounts/transfer_screen.dart';
import '../features/budgets/add_edit_budget_screen.dart';
import '../features/saving_goals/saving_goals_screen.dart';
import '../features/saving_goals/add_edit_saving_goal_screen.dart';
import '../features/bills/bills_screen.dart';
import '../features/bills/add_edit_bill_screen.dart';
import '../features/tags/tags_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/recurring/add_edit_recurring_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/data_management_screen.dart';
import '../data/models.dart';

/// Transisi standar Julpiypay untuk setiap perpindahan halaman: halaman baru
/// masuk dengan fade + slide halus dari kanan, sementara halaman di
/// belakangnya meredup tipis — kesan modern & konsisten di seluruh app,
/// tanpa transisi platform default yang datar.
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved);
      final fadeIn = Tween<double>(begin: 0, end: 1).animate(curved);
      final recede = Tween<double>(begin: 1, end: 0.88).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(opacity: recede, child: child),
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', pageBuilder: (context, state) => _buildPage(const SplashScreen(), state)),
      GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) => _buildPage(const OnboardingScreen(), state)),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return _buildPage(HomeShell(initialTab: tab), state);
        },
      ),

      // Transactions
      GoRoute(
        path: '/transactions/add',
        pageBuilder: (context, state) {
          final type = state.extra as TransactionType?;
          return _buildPage(AddEditTransactionScreen(initialType: type), state);
        },
      ),
      GoRoute(
        path: '/transactions/edit/:id',
        pageBuilder: (context, state) => _buildPage(
            AddEditTransactionScreen(transactionId: int.parse(state.pathParameters['id']!)), state),
      ),
      GoRoute(
        path: '/transactions/detail/:id',
        pageBuilder: (context, state) => _buildPage(
            TransactionDetailScreen(transactionId: int.parse(state.pathParameters['id']!)), state),
      ),

      // Categories
      GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => _buildPage(const CategoriesScreen(), state)),
      GoRoute(
        path: '/categories/add',
        pageBuilder: (context, state) =>
            _buildPage(AddEditCategoryScreen(initialType: state.extra as CategoryType?), state),
      ),
      GoRoute(
        path: '/categories/edit/:id',
        pageBuilder: (context, state) => _buildPage(
            AddEditCategoryScreen(categoryId: int.parse(state.pathParameters['id']!)), state),
      ),

      // Accounts
      GoRoute(
          path: '/accounts', pageBuilder: (context, state) => _buildPage(const AccountsScreen(), state)),
      GoRoute(
          path: '/accounts/add',
          pageBuilder: (context, state) => _buildPage(const AddEditAccountScreen(), state)),
      GoRoute(
        path: '/accounts/edit/:id',
        pageBuilder: (context, state) => _buildPage(
            AddEditAccountScreen(accountId: int.parse(state.pathParameters['id']!)), state),
      ),
      GoRoute(
          path: '/accounts/transfer',
          pageBuilder: (context, state) => _buildPage(const TransferScreen(), state)),

      // Budgets
      GoRoute(
          path: '/budgets/add',
          pageBuilder: (context, state) => _buildPage(const AddEditBudgetScreen(), state)),
      GoRoute(
        path: '/budgets/edit/:id',
        pageBuilder: (context, state) =>
            _buildPage(AddEditBudgetScreen(budgetId: int.parse(state.pathParameters['id']!)), state),
      ),

      // Saving goals
      GoRoute(
          path: '/saving_goals',
          pageBuilder: (context, state) => _buildPage(const SavingGoalsScreen(), state)),
      GoRoute(
          path: '/saving_goals/add',
          pageBuilder: (context, state) => _buildPage(const AddEditSavingGoalScreen(), state)),
      GoRoute(
        path: '/saving_goals/edit/:id',
        pageBuilder: (context, state) =>
            _buildPage(AddEditSavingGoalScreen(goalId: int.parse(state.pathParameters['id']!)), state),
      ),

      // Bills
      GoRoute(path: '/bills', pageBuilder: (context, state) => _buildPage(const BillsScreen(), state)),
      GoRoute(
          path: '/bills/add',
          pageBuilder: (context, state) => _buildPage(const AddEditBillScreen(), state)),
      GoRoute(
        path: '/bills/edit/:id',
        pageBuilder: (context, state) =>
            _buildPage(AddEditBillScreen(billId: int.parse(state.pathParameters['id']!)), state),
      ),

      // Tags
      GoRoute(path: '/tags', pageBuilder: (context, state) => _buildPage(const TagsScreen(), state)),

      // Recurring
      GoRoute(
          path: '/recurring',
          pageBuilder: (context, state) => _buildPage(const RecurringScreen(), state)),
      GoRoute(
          path: '/recurring/add',
          pageBuilder: (context, state) => _buildPage(const AddEditRecurringScreen(), state)),
      GoRoute(
        path: '/recurring/edit/:id',
        pageBuilder: (context, state) => _buildPage(
            AddEditRecurringScreen(recurringId: int.parse(state.pathParameters['id']!)), state),
      ),

      // Profile
      GoRoute(
          path: '/profile/edit',
          pageBuilder: (context, state) => _buildPage(const EditProfileScreen(), state)),
      GoRoute(
          path: '/profile/data',
          pageBuilder: (context, state) => _buildPage(const DataManagementScreen(), state)),
    ],
  );
});
