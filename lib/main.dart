import 'package:flutter/material.dart';
import 'package:gpoint/pages/my_home_page_state.dart';
import 'package:gpoint/pages/splash.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('juegosBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamer Point demo',
      home: Splash(), 
    );
  }
}
