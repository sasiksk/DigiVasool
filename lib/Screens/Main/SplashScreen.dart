import 'package:vasool_diary/Screens/Main/IntroductionDcreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../finance_provider.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  BoxDecoration _gradientBackground() {
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

  InputDecoration _textFieldDecoration() {
    return InputDecoration(
      labelText: 'Enter Name',
      labelStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: const Color.fromARGB(255, 236, 238, 237),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white),
      ),
      prefixIcon: const Icon(Icons.account_balance, color: Colors.blue),
    );
  }

  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      elevation: 5,
    );
  }

  void _showAlertDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 210, 240, 223),
        title: Text(title),
        content: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.tinos().fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          decoration: _gradientBackground(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Image.asset(
                    'assets/intro_image.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextField(
                    controller: _controller,
                    decoration: _textFieldDecoration(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          Colors.blue,
                          Colors.lightBlueAccent
                        ],
                        stops: [0.2, 0.5, 0.9],
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ElevatedButton(
                      style: _elevatedButtonStyle(),
                      onPressed: () async {
                        if (_controller.text.isEmpty) {
                          _showAlertDialog(
                              context, 'Message', 'Kindly Enter Your Name');
                        } else {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setBool('isFirstLaunch', false);
                          ref
                              .read(financeProvider.notifier)
                              .saveFinanceName(_controller.text);

                          // var manageExternalStorageStatus =
                          //     await Permission.manageExternalStorage.request();
                          // var storageStatus =
                          //     await Permission.storage.request();
                          // var status = await Permission.sms.status;
                          // if (!status.isGranted) {
                          //   status = await Permission.sms.request();
                          // }
                          // print('SMS Permission Status: $status');
                          if (/*manageExternalStorageStatus.isGranted ||
                              storageStatus.isGranted && status.isGranted*/
                              1 == 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          } else {
                            _showAlertDialog(context, 'Permission Required',
                                'Storage permissions are required to proceed.');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const IntroductionScreen()),
                            );
                          }
                        }
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.tinos().fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Sri Selva Vinayaga Software Solutions',
                  style: GoogleFonts.tinos(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
