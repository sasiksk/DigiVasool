import 'package:flutter/material.dart';

class CommonWidgets {
  static BoxDecoration gradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 241, 245, 245),
          Color.fromARGB(255, 95, 109, 101)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
