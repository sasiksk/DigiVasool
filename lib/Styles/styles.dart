import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  static final TextStyle titleTextStyle = GoogleFonts.tinos(
    textStyle: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.blueAccent,
    ),
  );

  static final TextStyle subtitleTextStyle = GoogleFonts.tinos(
    textStyle: const TextStyle(
      fontSize: 18,
      color: Colors.black,
    ),
  );

  static final TextStyle footerTextStyle = GoogleFonts.tinos(
    textStyle: const TextStyle(
      fontSize: 12,
      color: Color.fromARGB(137, 13, 59, 2),
      fontStyle: FontStyle.italic,
    ),
  );

  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue.shade900,
    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    elevation: 5,
  );
}
