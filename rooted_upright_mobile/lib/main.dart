// main.dart - Entry point for the Rooted Upright application.

import 'package:flutter/material.dart';
import 'package:rooted_upright_mobile/screens/login_screen.dart';
import 'screens/catalog_screen.dart';

void main() {
  // takes my root widget and hands it to Flutter to render.
  runApp(const RootedUprightApp());
} class RootedUprightApp extends StatelessWidget {
  const RootedUprightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        // Named routes for navigation
        '/catalog': (context) => const CatalogScreen(),
      },
      title: 'Rooted Upright',
      theme: ThemeData(),
      home: const LoginScreen(),
    );
  }
}