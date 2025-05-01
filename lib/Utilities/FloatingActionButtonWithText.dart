import 'package:flutter/material.dart';

class FloatingActionButtonWithText extends StatelessWidget {
  final String label;
  final Widget navigateTo;
  final IconData? icon;
  final String? heroTag;
  final MaterialColor? color; // Optional color

  const FloatingActionButtonWithText({
    super.key,
    required this.label,
    required this.navigateTo,
    this.icon,
    this.heroTag,
    this.color, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => navigateTo),
        );
      },
      icon: icon != null
          ? Icon(
              icon,
              color: Colors.white,
            )
          : null,
      label: Text(label,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
      backgroundColor: color ??
          Colors.blueAccent.shade700, // Use provided color or default to blue
      heroTag: heroTag, // Set the heroTag if provided
    );
  }
}
