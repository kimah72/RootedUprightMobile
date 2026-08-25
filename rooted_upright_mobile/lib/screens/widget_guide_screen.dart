import 'package:flutter/material.dart';
import '../widgets/widget_guide.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetGuideScreen extends StatelessWidget {
  const WidgetGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    // Amber terminal background
    backgroundColor: const Color(0xFF080d00),
    appBar: AppBar(
      // Terminal header
      backgroundColor: const Color(0xFF080d00),
      elevation: 0,
      title: Text(
        'WIDGET.SYS // A GUIDED HAIKU',
        style: GoogleFonts.shareTechMono(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFffb000),
          letterSpacing: 2,
        ),
      ),
      iconTheme: const IconThemeData(
        // Back arrow in amber
        color: Color(0xFFffb000),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0x33ffb000),
          height: 1,
        ),
      ),
    ),
    body: WidgetGuide(),
  );
  
  }
}