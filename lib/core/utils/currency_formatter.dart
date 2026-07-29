import 'package:flutter/services.dart';

abstract final class CurrencyFormatter {
  static String formatColones(num amount) {
    final digits = amount.round().abs().toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '${amount < 0 ? '-' : ''}₡ $formatted';
  }
}

class DigitsOnlyInputFormatter extends TextInputFormatter {
  const DigitsOnlyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.text.contains(RegExp(r'[^0-9]')) ? oldValue : newValue;
  }
}
