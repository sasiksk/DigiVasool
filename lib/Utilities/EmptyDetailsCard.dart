import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';

class EmptyCard extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final String? title;
  final List<Widget> items;

  EmptyCard({
    required this.screenHeight,
    required this.screenWidth,
    this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.blueGrey.shade100,
      Colors.blueGrey.shade200,
      Colors.blueGrey.shade300,
      Colors.blueGrey.shade400,
      Colors.blueGrey.shade500,
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 100.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: false,
        autoPlayAnimationDuration: Duration(milliseconds: 1000),
        viewportFraction: 0.33,
      ),
      items: items.asMap().entries.map((entry) {
        int index = entry.key;
        Widget item = entry.value;
        return Builder(
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                color:
                    colors[index % colors.length], // Assign color from the list
                borderRadius: BorderRadius.circular(15), // Rounded corners
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent,

                    Colors.blueGrey.shade800, // Ending color
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, // Shadow color
                    offset: Offset(0, 4), // Shadow position
                    blurRadius: 10, // Blur effect
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8.0), // Add padding to each item
              child: item, // Directly use the item
            );
          },
        );
      }).toList(),
    ); // Spacing between title and carousel
  }
}
