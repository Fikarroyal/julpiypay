import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../app/theme/app_theme.dart';
import '../data/models.dart';
import 'utils.dart';

/// Container kartu standar — dipakai di seluruh aplikasi supaya elevation,
/// radius, dan border konsisten (bukan "card di mana-mana" yang berlebihan).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.theme.dividerColor, width: 1),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color bg;
    Color fg;
    BorderSide? border;
    switch (variant) {
      case AppButtonVariant.primary:
        bg = colors.primary;
        fg = colors.onPrimary;
        border = null;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.primaryLight.withOpacity(context.isDark ? 0.12 : 1);
        fg = colors.primary;
        border = null;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.expense.withOpacity(0.1);
        fg = AppColors.expense;
        border = null;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = context.textStyles.bodyLarge?.color ?? Colors.black;
        border = BorderSide(color: context.theme.dividerColor);
        break;
    }

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          side: border,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: child,
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.onTap,
    this.readOnly = false,
    this.suffix,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffix;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.textStyles.labelLarge),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onTap: onTap,
          readOnly: readOnly,
          autovalidateMode: autovalidateMode,
          style: context.textStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: context.textStyles.bodySmall?.color)
                : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Input nominal besar dengan format Rupiah otomatis — dipakai sebagai
/// fokus utama pada form Tambah Transaksi.
class AmountInput extends StatefulWidget {
  const AmountInput({super.key, required this.controller, required this.color});

  final TextEditingController controller;
  final Color color;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final number = digits.isEmpty ? 0 : int.parse(digits);
    final formatted = number == 0 ? '' : CurrencyFormatter.format(number).replaceAll('Rp ', '');
    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Rp', style: context.textStyles.titleMedium?.copyWith(color: widget.color)),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onChanged,
          textAlign: TextAlign.center,
          style: AppTextStyles.amount(widget.color, size: 40),
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: '0',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? context.colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(context.isDark ? 0.25 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? activeColor : context.theme.dividerColor),
        ),
        child: Text(
          label,
          style: context.textStyles.labelLarge?.copyWith(
            color: selected ? activeColor : context.textStyles.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: context.textStyles.titleMedium),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: TextStyle(color: context.colors.primary)),
          ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: context.textStyles.bodySmall, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.amount(context.textStyles.bodyLarge!.color!, size: 17)),
        ],
      ),
    );
  }
}

/// Lingkaran icon berwarna — dipakai konsisten untuk kategori, akun, dsb.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.22 : 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: icon, color: context.colors.primary, size: 64),
          const SizedBox(height: 20),
          Text(title, style: context.textStyles.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message,
              style: context.textStyles.bodySmall, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            AppButton(label: actionLabel!, onPressed: onAction, expand: false, icon: LucideIcons.plus),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: LucideIcons.triangleAlert, color: AppColors.expense, size: 64),
          const SizedBox(height: 20),
          Text('Terjadi kesalahan', style: context.textStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            message ?? 'Data keuangan gagal dimuat.',
            style: context.textStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Coba lagi', onPressed: onRetry, expand: false, icon: LucideIcons.refreshCw),
        ],
      ),
    );
  }
}

/// Skeleton shimmer sederhana — dipakai untuk state loading, bukan
/// CircularProgressIndicator polos di tengah layar.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.height = 16, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.isDark ? AppColors.darkCard : const Color(0xFFEDF1EF);
    final highlight = context.isDark ? AppColors.darkBorder : const Color(0xFFF7F9F8);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(base, highlight, _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 90});
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            const LoadingSkeleton(height: 44, width: 44, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  LoadingSkeleton(height: 14, width: 140),
                  SizedBox(height: 8),
                  LoadingSkeleton(height: 12, width: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet standar — rounded top, drag handle, padding konsisten.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required Widget child, bool scrollable = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                scrollable ? Flexible(child: SingleChildScrollView(child: child)) : child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Dialog konfirmasi generik — dipakai untuk semua aksi hapus.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: context.textStyles.titleMedium),
      content: Text(message, style: context.textStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: danger ? AppColors.expense : context.colors.primary),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Baris satu transaksi — dipakai di Dashboard (recent) & halaman Transaksi.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    this.onTap,
  });

  final TransactionModel transaction;
  final CategoryModel? category;
  final AccountModel? account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final color = isTransfer ? AppColors.info : (isExpense ? AppColors.expense : AppColors.income);
    final icon = isTransfer
        ? LucideIcons.arrowLeftRight
        : (category?.icon != null ? iconFromKey(category!.icon) : LucideIcons.circleDollarSign);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            IconBadge(icon: icon, color: category != null ? colorFromHex(category!.color) : color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTransfer ? 'Transfer' : (category?.name ?? 'Tanpa kategori'),
                    style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : (account?.name ?? ''),
                    style: context.textStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isTransfer
                  ? CurrencyFormatter.format(transaction.amount)
                  : CurrencyFormatter.formatSigned(transaction.amount, isExpense: isExpense),
              style: AppTextStyles.amount(color, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress bar linear dengan warna sesuai persentase (dipakai budget).
class ProgressStatusBar extends StatelessWidget {
  const ProgressStatusBar({super.key, required this.percent});
  final double percent; // 0..1+

  @override
  Widget build(BuildContext context) {
    Color color;
    if (percent >= 1) {
      color = AppColors.expense;
    } else if (percent >= 0.8) {
      color = AppColors.warning;
    } else {
      color = AppColors.primary;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: percent.clamp(0, 1).toDouble(),
        minHeight: 8,
        backgroundColor: context.theme.dividerColor,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Mapping string key (disimpan di DB) ke IconData Lucide, supaya icon
/// kategori/akun bisa dipilih user lalu dipersist sebagai string.
IconData iconFromKey(String key) {
  const map = <String, IconData>{
    'utensils': LucideIcons.utensils,
    'car': LucideIcons.car,
    'shoppingBag': LucideIcons.shoppingBag,
    'home': LucideIcons.house,
    'zap': LucideIcons.zap,
    'heartPulse': LucideIcons.heartPulse,
    'graduationCap': LucideIcons.graduationCap,
    'gift': LucideIcons.gift,
    'gamepad2': LucideIcons.gamepad2,
    'plane': LucideIcons.plane,
    'wifi': LucideIcons.wifi,
    'phone': LucideIcons.phone,
    'briefcase': LucideIcons.briefcase,
    'trendingUp': LucideIcons.trendingUp,
    'coins': LucideIcons.coins,
    'wallet': LucideIcons.wallet,
    'landmark': LucideIcons.landmark,
    'creditCard': LucideIcons.creditCard,
    'smartphone': LucideIcons.smartphone,
    'piggyBank': LucideIcons.piggyBank,
    'dumbbell': LucideIcons.dumbbell,
    'baby': LucideIcons.baby,
    'pawPrint': LucideIcons.pawPrint,
    'film': LucideIcons.film,
    'droplet': LucideIcons.droplet,
    'flame': LucideIcons.flame,
    'scissors': LucideIcons.scissors,
    'shirt': LucideIcons.shirt,
    'book': LucideIcons.book,
  };
  return map[key] ?? LucideIcons.circleDollarSign;
}

const List<String> kCategoryIconKeys = [
  'utensils', 'car', 'shoppingBag', 'home', 'zap', 'heartPulse', 'graduationCap',
  'gift', 'gamepad2', 'plane', 'wifi', 'phone', 'briefcase', 'trendingUp',
  'coins', 'dumbbell', 'baby', 'pawPrint', 'film', 'droplet', 'flame', 'scissors',
  'shirt', 'book',
];

const List<String> kAccountIconKeys = [
  'wallet', 'landmark', 'creditCard', 'smartphone', 'piggyBank', 'coins',
];

Color colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

String colorToHex(Color color) =>
    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
