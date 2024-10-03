import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TransactionCodeGenerator extends StatefulWidget {
  const TransactionCodeGenerator({super.key});

  @override
  State<TransactionCodeGenerator> createState() => _TransactionCodeGeneratorState();
}

class _TransactionCodeGeneratorState extends State<TransactionCodeGenerator> {
   final Uuid _uuid = Uuid();

  String generateTransactionCode() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MM').format(now);
    String uuid = _uuid.v4();

    String transactionCode = 'B-${formattedDate}${uuid.substring(0, 5)}';

    return transactionCode;
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}