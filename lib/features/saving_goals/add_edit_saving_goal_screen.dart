import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditSavingGoalScreen extends ConsumerStatefulWidget {
  const AddEditSavingGoalScreen({super.key, this.goalId});
  final int? goalId;

  @override
  ConsumerState<AddEditSavingGoalScreen> createState() => _AddEditSavingGoalScreenState();
}

class _AddEditSavingGoalScreenState extends ConsumerState<AddEditSavingGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController(text: '0');
  final _descController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 180));
  String _icon = 'piggyBank';
  Color _color = AppColors.primary;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.goalId != null;

  static const _goalIcons = ['piggyBank', 'plane', 'home', 'graduationCap', 'car', 'gift', 'heartPulse', 'gamepad2'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final goals = await ref.read(savingGoalRepoProvider).getAll();
    final goal = goals.where((g) => g.id == widget.goalId).cast<SavingGoalModel?>().firstWhere((_) => true, orElse: () => null);
    if (goal == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _nameController.text = goal.name;
      _targetController.text = goal.targetAmount.toStringAsFixed(0);
      _currentController.text = goal.currentAmount.toStringAsFixed(0);
      _descController.text = goal.description ?? '';
      _deadline = goal.deadline;
      _icon = goal.icon;
      _color = colorFromHex(goal.color);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final target = CurrencyFormatter.parse(_targetController.text);
    final current = CurrencyFormatter.parse(_currentController.text);
    if (target <= current) {
      context.showSnack('Target amount must be greater than current amount', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = SavingGoalModel(
        id: widget.goalId,
        name: _nameController.text.trim(),
        targetAmount: target,
        currentAmount: current,
        deadline: _deadline,
        icon: _icon,
        color: colorToHex(_color),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
      if (_isEdit) {
        await ref.read(savingGoalRepoProvider).update(model);
      } else {
        await ref.read(savingGoalRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Saving goal updated' : 'Saving goal added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save goal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit saving goal' : 'Add saving goal')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
            children: [
              Center(child: IconBadge(icon: iconFromKey(_icon), color: _color, size: 72)),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                label: 'Goal name',
                hint: 'e.g. Emergency Fund, Bali Trip',
                validator: (v) => Validators.name(v, field: 'Goal name'),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _targetController,
                label: 'Target amount',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.target,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _currentController,
                label: 'Current amount',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.banknote,
              ),
              const SizedBox(height: 20),
              Text('Deadline', style: context.textStyles.labelLarge),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormatter.short(_deadline)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(controller: _descController, label: 'Description', hint: 'Optional', maxLines: 2),
              const SizedBox(height: 20),
              Text('Icon', style: context.textStyles.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _goalIcons.map((key) {
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
              AppButton(label: 'Save goal', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
