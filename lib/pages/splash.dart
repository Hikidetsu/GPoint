import 'package:flutter/material.dart';
import 'package:gpoint/pages/my_home_page_state.dart';

class Splash extends StatefulWidget {
  const Splash ({Key? key}) : super (key: key);

  @override
  State<Splash> createState() =>_SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MyHomePage(title: "GPoint")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 76, 144, 223), 
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/Gsinfondo.png', 
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 16), 
            const Text(
              'Tu bibloteca de juegos en un solo lugar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}