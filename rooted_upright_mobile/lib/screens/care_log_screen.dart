import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CareLogScreen extends StatefulWidget {
  // Plant data passed from detail screen
  final Map<String, dynamic> plant;

  const CareLogScreen({super.key, required this.plant});

  @override
  State<CareLogScreen> createState() => _CareLogScreenState();
}

class _CareLogScreenState extends State<CareLogScreen> {
  // Care logs loaded from API
  List<dynamic> _careLogs = [];
  // Tracks loading state
  bool _isLoading = true;
  // Holds any error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch care logs when screen loads
    _fetchCareLogs();
  }

  Future<void> _fetchCareLogs() async {
    // API call goes here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        title: Text(
          '${widget.plant['name']} // CARE LOG',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFaaff00),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0x33aaff00),
            height: 1,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'CARE LOG COMING SOON',
          style: TextStyle(
            color: Color(0xFFaaff00),
            fontFamily: 'monospace',
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}