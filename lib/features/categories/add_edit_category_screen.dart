import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  const AddEditCategoryScreen({super.key, this.categoryId, this.initialType});
  final int? categoryId;
  final CategoryType? initialType;

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  CategoryType _type = CategoryType.expense;
  String _icon = kCategoryIconKeys.first;
  Color _color = AppColors.categoryPalette.first;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? CategoryType.expense;
    if (_isEdit) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final category = await ref.read(categoryRepoProvider).getById(widget.categoryId!);
    if (category == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _nameController.text = category.name;
      _descController.text = category.description ?? '';
      _type = category.type;
      _icon = category.icon;
      _color = colorFromHex(category.color);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final model = CategoryModel(
        id: widget.categoryId,
        name: _nameController.text.trim(),
        type: _type,
        icon: _icon,
        color: colorToHex(_color),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
      if (_isEdit) {
        await ref.read(categoryRepoProvider).update(model);
      } else {
        await ref.read(categoryRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Category updated' : 'Category added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save category: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit category' : 'Add category')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
            children: [
              Center(
                child: IconBadge(icon: iconFromKey(_icon), color: _color, size: 72),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.theme.dividerColor),
                ),
                child: Row(
                  children: CategoryType.values.map((t) {
                    final selected = _type == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: _isEdit ? null : () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? context.colors.primary.withOpacity(context.isDark ? 0.25 : 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(t == CategoryType.expense ? 'Expense' : 'Income',
                              style: TextStyle(
                                  color: selected ? context.colors.primary : context.textStyles.bodyMedium?.color,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _nameController,
                label: 'Category name',
                hint: 'e.g. Food, Transport',
                validator: (v) => Validators.name(v, field: 'Category name'),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Optional',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text('Icon', style: context.textStyles.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kCategoryIconKeys.map((key) {
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
              AppButton(label: 'Save category', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
