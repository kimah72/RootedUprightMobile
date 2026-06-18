import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditCareLogScreen extends StatefulWidget {
  // Care log data to pre-populate the form
  final Map<String, dynamic> careLog;

  const EditCareLogScreen({super.key, required this.careLog});

  @override
  State<EditCareLogScreen> createState() => _EditCareLogScreenState();
}

class _EditCareLogScreenState extends State<EditCareLogScreen> {
  // Selected care type -- pre-populated
  late String _careType;
  // Notes controller -- pre-populated
  late TextEditingController _notesController;
  // Tracks submission in progress
  bool _isSubmitting = false;
  // Holds any error message
  String? _errorMessage;

  // Care type options
  final List<String> _careTypes = [
    'Watering',
    'Fertilizing',
    'Repotting',
    'Pruning',
    'Leaf Cleaning',
    'Drama',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing care log data
    _careType = widget.careLog['careType'] ?? 'Watering';
    _notesController = TextEditingController(text: widget.careLog['notes'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        title: Text(
          'EDIT CARE LOG',
          style: GoogleFonts.orbitron(
            fontSize: 14,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Care type label
            const Text(
              'CARE TYPE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 3,
                color: Color(0x99aaff00),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            // Care type dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0d1500),
                border: Border.all(color: const Color(0x33aaff00)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _careType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0d1500),
                  style: const TextStyle(
                    color: Color(0xFFaaff00),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  items: _careTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _careType = value ?? 'Watering';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Notes label
            const Text(
              'NOTES',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 3,
                color: Color(0x99aaff00),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(
                color: Color(0xFFaaff00),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: 'Update your care notes...',
                hintStyle: const TextStyle(
                  color: Color(0x33aaff00),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                filled: true,
                fillColor: const Color(0xFF0d1500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: const BorderSide(color: Color(0x33aaff00)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: const BorderSide(color: Color(0x33aaff00)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: const BorderSide(color: Color(0xFFaaff00)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFffb000),
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _updateCareLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFaaff00),
                  foregroundColor: const Color(0xFF080d00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  _isSubmitting ? 'UPDATING...' : 'UPDATE LOG',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sends updated care log to the API
  Future<void> _updateCareLog() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await http.put(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/carelogs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'logId': widget.careLog['logId'],
          'plantId': widget.careLog['plantId'],
          'careType': _careType,
          'notes': _notesController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'Failed to update log. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}