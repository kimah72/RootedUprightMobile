import 'package:flutter/material.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Void background
      backgroundColor: const Color(0xFF080d00),
      body: Center(
        child: Text(
          'PLANT CATALOG',
          style: TextStyle(
            color: const Color(0xFFaaff00),
            fontFamily: 'monospace',
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
