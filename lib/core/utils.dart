import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format angka menjadi Rupiah: "Rp 1.250.000" (tanpa desimal, sesuai spek UI).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num value) => _format.format(value);

  /// Format dengan tanda +/- otomatis sesuai tipe transaksi.
  static String formatSigned(num value, {required bool isExpense}) {
    final sign = isExpense ? ', ' : '+ ';
    return '$sign${_format.format(value.abs())}';
  }

  /// Parse input pengguna (bisa mengandung titik/koma/"Rp") jadi double murni.
  static double parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.parse(cleaned);
  }
}

class DateFormatter {
  DateFormatter._();

  static final _dayMonthYear = DateFormat('d MMM yyyy', 'id_ID');
  static final _dayMonthYearFull = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final _time = DateFormat('HH:mm');
  static final _dbFormat = DateFormat('yyyy-MM-dd');

  static String short(DateTime date) => _dayMonthYear.format(date);
  static String full(DateTime date) => _dayMonthYearFull.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String time(DateTime date) => _time.format(date);
  static String toDb(DateTime date) => _dbFormat.format(date);
  static DateTime fromDb(String value) => DateTime.parse(value);

  /// Label grup untuk daftar transaksi: "Hari ini", "Kemarin", atau tanggal.
  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return _dayMonthYear.format(date);
  }

  static String dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return 'Terlambat ${diff.abs()} hari';
    if (diff == 0) return 'Jatuh tempo hari ini';
    if (diff == 1) return 'Jatuh tempo besok';
    return 'Jatuh tempo dalam $diff hari';
  }
}

class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount must be greater than 0';
    final parsed = CurrencyFormatter.parse(value);
    if (parsed <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static String? name(String? value, {int minLength = 2, String field = 'Name'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    if (value.trim().length < minLength) return '$field must be at least $minLength characters';
    return null;
  }

  static String? category(int? value) => value == null ? 'Category is required' : null;

  static String? savingGoalTarget(double target, double current) {
    if (target <= current) return 'Target amount must be greater than current amount';
    return null;
  }
}

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Size get screenSize => MediaQuery.of(this).size;

  /// Padding horizontal yang menyesuaikan lebar layar — sempit di HP kecil,
  /// lebih lega di tablet — supaya layout tetap nyaman di semua ukuran.
  double get horizontalPadding {
    final width = screenSize.width;
    if (width < 360) return 14;
    if (width >= 900) return 40;
    if (width >= 600) return 32;
    return 20;
  }

  /// True untuk layar lebar (tablet/desktop) supaya konten bisa dibatasi
  /// lebarnya dan tidak melebar tak wajar.
  bool get isWideScreen => screenSize.width >= 600;

  /// Lebar konten maksimum pada layar lebar supaya form/list tidak
  /// membentang penuh dan tetap enak dibaca.
  double get maxContentWidth => isWideScreen ? 560 : double.infinity;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
