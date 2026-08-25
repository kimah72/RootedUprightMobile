// main.dart - Entry point for the Rooted Upright application.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rooted_upright_mobile/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local cache so the catalog still has something to show when offline
  await Hive.initFlutter();
  await Hive.openBox('offlineCache');
  // takes my root widget and hands it to Flutter to render.
  runApp(const RootedUprightApp());
} class RootedUprightApp extends StatelessWidget {
  const RootedUprightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rooted Upright',
      theme: ThemeData(),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false
    );
  }
}