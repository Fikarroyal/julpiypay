import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  Future<void> _showTagForm({TagModel? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    await showAppBottomSheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(existing == null ? 'Add tag' : 'Edit tag', style: context.textStyles.titleLarge),
          const SizedBox(height: 16),
          AppTextField(controller: controller, label: 'Tag name', hint: 'e.g. Work, Family, Travel'),
          const SizedBox(height: 20),
          AppButton(
            label: 'Save',
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                context.showSnack('Tag name is required', isError: true);
                return;
              }
              if (existing == null) {
                await ref.read(tagRepoProvider).insert(TagModel(name: name));
              } else {
                await ref.read(tagRepoProvider).update(TagModel(id: existing.id, name: name));
              }
              notifyDataChanged(ref);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _delete(TagModel tag) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${tag.name}"?',
      message: 'This tag will be removed from all transactions.',
    );
    if (!confirmed) return;
    await ref.read(tagRepoProvider).delete(tag.id!);
    notifyDataChanged(ref);
    if (mounted) context.showSnack('Tag deleted');
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagForm(),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: tagsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10), child: SkeletonCard(height: 54))),
          ),
          error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
          data: (tags) {
            if (tags.isEmpty) {
              return EmptyState(
                icon: LucideIcons.tags,
                title: 'No tags yet',
                message: 'Create tags like Work, Family, or Travel to organize transactions.',
                actionLabel: 'Add tag',
                onAction: () => _showTagForm(),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = tags[i];
                return Slidable(
                  key: ValueKey(t.id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.5,
                    children: [
                      SlidableAction(
                        onPressed: (_) => _showTagForm(existing: t),
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        icon: LucideIcons.pencil,
                        label: 'Edit',
                        borderRadius: BorderRadius.circular(14),
                      ),
                      const SizedBox(width: 6),
                      SlidableAction(
                        onPressed: (_) => _delete(t),
                        backgroundColor: AppColors.expense,
                        foregroundColor: Colors.white,
                        icon: LucideIcons.trash2,
                        label: 'Delete',
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ],
                  ),
                  child: AppCard(
                    child: Row(
                      children: [
                        const IconBadge(icon: LucideIcons.tag, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(t.name, style: context.textStyles.bodyLarge)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
