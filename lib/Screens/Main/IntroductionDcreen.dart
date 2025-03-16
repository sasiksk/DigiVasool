import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:DigiVasool/Screens/Main/SplashScreen.dart';
import 'package:DigiVasool/Styles/styles.dart';
import 'package:DigiVasool/Widgets/common_widgets.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: CommonWidgets.gradientBackground(),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Welcome to Digi Vasool',
                style: AppStyles.titleTextStyle,
              ),
              const SizedBox(height: 20),
              Text(
                '"Effortlessly manage your lending and borrowing activities with our app. Start by entering a record name and track your daily and weekly transactions with ease."',
                textAlign: TextAlign.center,
                style: AppStyles.subtitleTextStyle,
              ),
              const SizedBox(height: 40),
              Image.asset(
                'assets/intro_image.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: AppStyles.elevatedButtonStyle,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SplashScreen()),
                  );
                },
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.tinos().fontFamily,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Sri Selva Vinayaga Software Solutions',
                style: AppStyles.footerTextStyle,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
