import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditPlantScreen extends StatefulWidget {
  // Full plant data to pre-populate the form
  final Map<String, dynamic> plant;

  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  // Form controllers pre-populated with existing plant data
  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _cultivarController;
  late TextEditingController _loreController;
  late TextEditingController _careController;
  late TextEditingController _watchController;

  // Tracks submission in progress
  bool _isSubmitting = false;
  // Holds any error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate controllers with existing plant data
    _nameController = TextEditingController(text: widget.plant['name'] ?? '');
    _speciesController = TextEditingController(text: widget.plant['species'] ?? '');
    _cultivarController = TextEditingController(text: widget.plant['cultivar'] ?? '');
    _loreController = TextEditingController(text: widget.plant['lore'] ?? '');
    _careController = TextEditingController(text: widget.plant['careInstructions'] ?? '');
    _watchController = TextEditingController(text: widget.plant['watchFor'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        title: Text(
          'EDIT SPECIMEN',
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
            // Name field
            _formField('SPECIMEN NAME', _nameController, 'e.g. Luna Lovegood'),
            const SizedBox(height: 16),
            // Species field
            _formField('SPECIES', _speciesController, 'e.g. Monstera deliciosa'),
            const SizedBox(height: 16),
            // Cultivar field
            _formField('CULTIVAR', _cultivarController, 'e.g. Thai Constellation'),
            const SizedBox(height: 16),
            // Lore field
            _formField('LORE', _loreController, 'every plant has a story...', maxLines: 3),
            const SizedBox(height: 16),
            // Care instructions field
            _formField('CARE INSTRUCTIONS', _careController, 'light, water, humidity...', maxLines: 3),
            const SizedBox(height: 16),
            // Watch for field
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
                onPressed: _isSubmitting ? null : _updatePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFaaff00),
                  foregroundColor: const Color(0xFF080d00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  _isSubmitting ? 'UPDATING...' : 'UPDATE SPECIMEN',
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
  // Sends updated plant data to the API
  Future<void> _updatePlant() async {
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
      final response = await http.put(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plantId': widget.plant['plantId'],
          'userId': widget.plant['userId'],
          'name': _nameController.text.trim(),
          'species': _speciesController.text.trim(),
          'cultivar': _cultivarController.text.trim(),
          'lore': _loreController.text.trim(),
          'careInstructions': _careController.text.trim(),
          'watchFor': _watchController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'Failed to update specimen. Try again.';
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