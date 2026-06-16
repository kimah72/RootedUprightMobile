import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddPlantScreen extends StatefulWidget {
  // userId needed to associate plant with user
  final String userId;

  const AddPlantScreen({super.key, required this.userId});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _cultivarController = TextEditingController();
  final TextEditingController _loreController = TextEditingController();
  final TextEditingController _careController = TextEditingController();
  final TextEditingController _watchController = TextEditingController();

  // Tracks submission in progress
  bool _isSubmitting = false;
  // Holds any error message
  String? _errorMessage;

  // Submits new plant to the API
  Future<void> _submitPlant() async {
    // Validate name field
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'SPECIMEN NAME is required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'name': _nameController.text.trim(),
          'species': _speciesController.text.trim(),
          'cultivar': _cultivarController.text.trim(),
          'lore': _loreController.text.trim(),
          'careInstructions': _careController.text.trim(),
          'watchFor': _watchController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Go back to catalog on success
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'Failed to add specimen. Try again.';
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
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF080d00),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080d00),
          elevation: 0,
          title: Text(
            'NEW SPECIMEN',
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
              // Name field -- required
              _formField('SPECIMEN NAME', _nameController, 'e.g. Luna Lovegood'),
              const SizedBox(height: 16),
              // Species field
              _formField('SPECIES', _speciesController, 'e.g. Monstera deliciosa'),
              const SizedBox(height: 16),
              // Cultivar field
              _formField('CULTIVAR', _cultivarController, 'e.g. Thai Constellation'),
              const SizedBox(height: 16),
              // Lore field -- multiline
              _formField('LORE', _loreController, 'every plant has a story...', maxLines: 3),
              const SizedBox(height: 16),
              // Care instructions field -- multiline
              _formField('CARE INSTRUCTIONS', _careController, 'light, water, humidity...', maxLines: 3),
              const SizedBox(height: 16),
              // Watch for field -- multiline
              _formField('WATCH FOR', _watchController, 'pests, root rot...', maxLines: 2),
              const SizedBox(height: 32),
              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFff0000),
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPlant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFaaff00),
                    foregroundColor: const Color(0xFF080d00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'ADDING...' : 'ADD SPECIMEN',
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
  // Reusable form field widget
  Widget _formField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 3,
            color: Color(0x99aaff00),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Color(0xFFaaff00),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: hint,
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
      ],
    );
  }
}