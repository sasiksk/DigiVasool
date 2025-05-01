import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyCard1 extends StatefulWidget {
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
  _EmptyCard1State createState() => _EmptyCard1State();
}

class _EmptyCard1State extends State<EmptyCard1> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 5, right: 5),
      width:
          widget.screenWidth - 25, // Full width minus padding (20 on each side)
      child: InkWell(
        onTap: _toggleExpand,
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
                  Color(0xFFEAE9D9), // Soft Cream
                  Color(0xFFD6DAF0), // Light Lavender
                  Color(0xFFC2D9F7), // Gentle Sky Blue
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title ?? 'Default Title',
                        style: TextStyle(
                          fontFamily: GoogleFonts.tinos().fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 23, 56, 1),
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: const Color.fromARGB(255, 23, 56, 1),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 10), // Increased spacing for better layout
                  if (_isExpanded)
                    DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: GoogleFonts.tinos().fontFamily,
                        color: Colors.blueGrey,
                      ), // Set default text color to white
                      child: widget.content, // Add content here
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
