import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyCard1 extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final String? title;
  final Widget content;

  const EmptyCard1({
    required this.screenHeight,
    required this.screenWidth,
    this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 05, left: 05, right: 05),
      height:
          screenHeight * 0.15, // Slightly increased height to avoid overflow
      width: screenWidth - 25, // Full width minus padding (20 on each side)
      child: Card(
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 235, 231, 208),
                Color.fromARGB(255, 227, 228, 241),
                Color.fromARGB(255, 243, 231, 245)
              ], // Gradient background
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0), // Increased padding
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to start
              children: <Widget>[
                Center(
                  child: Text(
                    title ?? 'Default Title',
                    style: TextStyle(
                      fontFamily: GoogleFonts.tinos().fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 23, 56, 1),
                      // White text color
                    ),
                  ),
                ),
                const SizedBox(
                    height: 10), // Increased spacing for better layout
                DefaultTextStyle(
                  style: TextStyle(
                      fontFamily: GoogleFonts.tinos().fontFamily,
                      color: Colors.white), // Set default text color to white
                  child: content, // Add content here
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
