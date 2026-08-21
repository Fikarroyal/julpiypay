import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  Future<void> _delete(CategoryModel category) async {
    final isUsed = await ref.read(categoryRepoProvider).isUsed(category.id!);
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${category.name}"?',
      message: isUsed
          ? 'This category is already used by transactions or budgets. Deleting it will not remove those records, but they will show as uncategorized.'
          : 'This category will be permanently removed.',
    );
    if (!confirmed) return;
    await ref.read(categoryRepoProvider).delete(category.id!);
    notifyDataChanged(ref);
    if (mounted) context.showSnack('Category deleted');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.textStyles.bodySmall?.color,
          indicatorColor: context.colors.primary,
          tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/categories/add',
            extra: _tabController.index == 0 ? CategoryType.expense : CategoryType.income),
        child: const Icon(LucideIcons.plus),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(type: CategoryType.expense, onDelete: _delete),
          _CategoryList(type: CategoryType.income, onDelete: _delete),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type, required this.onDelete});
  final CategoryType type;
  final Future<void> Function(CategoryModel) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(type));
    return categoriesAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(5, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10), child: SkeletonCard(height: 60))),
      ),
      error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
      data: (categories) {
        if (categories.isEmpty) {
          return EmptyState(
            icon: LucideIcons.tags,
            title: 'No categories yet',
            message: 'Create your first ${type == CategoryType.expense ? 'expense' : 'income'} category.',
            actionLabel: 'Add category',
            onAction: () => context.push('/categories/add', extra: type),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = categories[i];
            return Slidable(
              key: ValueKey(c.id),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.5,
                children: [
                  SlidableAction(
                    onPressed: (_) => context.push('/categories/edit/${c.id}'),
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    icon: LucideIcons.pencil,
                    label: 'Edit',
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 6),
                  SlidableAction(
                    onPressed: (_) => onDelete(c),
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                    icon: LucideIcons.trash2,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(14),
                  ),
                ],
              ),
              child: AppCard(
                onTap: () => context.push('/categories/edit/${c.id}'),
                child: Row(
                  children: [
                    IconBadge(icon: iconFromKey(c.icon), color: colorFromHex(c.color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          if (c.description?.isNotEmpty == true)
                            Text(c.description!, style: context.textStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 16, color: context.textStyles.bodySmall?.color),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
