// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';

// class CustomRupiahFormatter extends TextInputFormatter {
//   final NumberFormat formatter = NumberFormat.currency(
//       locale: 'id_ID',
//       symbol: '',
//       decimalDigits: 1);

//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     if (newValue.text.isEmpty) {
//       return newValue.copyWith(text: '');
//     }

//     String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

//     if (newText.indexOf('.') != newText.lastIndexOf('.')) {
//       return oldValue;
//     }

//     if (newText.startsWith('.')) {
//       newText = '0$newText';
//     }

//     double value = double.tryParse(newText) ?? 0.0;

//     String formattedText = formatter.format(value).replaceAll(',', '.');

//     return newValue.copyWith(
//       text: formattedText,
//       selection: TextSelection.collapsed(offset: formattedText.length),
//     );
//   }
// }
import 'package:flutter/services.dart';

class CustomRupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (cleaned.contains('.')) {
      List<String> parts = cleaned.split('.');

      if (parts.length > 2) {
        parts = [parts[0], parts[1]];
        cleaned = '${parts[0]}.${parts[1]}';
      }

      String wholeNumber = _formatThousands(parts[0]);

      String decimal =
          parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];

      String formatted = '$wholeNumber.$decimal';

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      String formatted = _formatThousands(cleaned);

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String _formatThousands(String value) {
    value = value.replaceAll('.', '');

    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]}.';

    return value.replaceAllMapped(reg, mathFunc);
  }
}
