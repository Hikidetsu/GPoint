import 'package:flutter/material.dart';
import 'package:gpoint/pages/my_home_page_state.dart';
import 'package:logger/logger.dart';
import 'package:gpoint/pages/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamer Point demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Splash(),
    );
  }
}
