import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildAmountBlock(String label, double amount,
    {bool centerAlign = false,
    double textSize = 20,
    Color labelColor = Colors.deepPurpleAccent,
    Color valueColor = Colors.purpleAccent}) {
  return Column(
    crossAxisAlignment:
        centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: textSize - 2,
          fontWeight: FontWeight.bold,
          color: labelColor,
        ),
      ),
      TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: amount),
        duration: const Duration(milliseconds: 700),
        builder: (context, value, child) {
          final formattedValue = NumberFormat.currency(
            decimalDigits: 2,
            symbol: '₹',
            locale: 'en_IN',
          ).format(value);
          return Text(
            formattedValue,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          );
        },
      ),
    ],
  );
}
