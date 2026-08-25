import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  // Selected image file
  File? _selectedImage;
  // Image picker instance
  final ImagePicker _picker = ImagePicker();

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
        // Extract plantId from response to upload image
        final responseData = jsonDecode(response.body);
        final plantId = responseData['plantId'];
        final imageUrl = await _uploadImage(plantId);

        // Save imageUrl to plant record if upload succeeded
        if (imageUrl != null) {
          await http.put(
            Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'plantId': plantId,
              'name': _nameController.text.trim(),
              'species': _speciesController.text.trim(),
              'cultivar': _cultivarController.text.trim(),
              'lore': _loreController.text.trim(),
              'careInstructions': _careController.text.trim(),
              'watchFor': _watchController.text.trim(),
              'imageUrl': imageUrl,
            }),
          );
        }

        if (!mounted) return;
        Navigator.pop(context, 'Specimen added to the catalog.');
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
  // Opens camera or gallery to select an image
  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }
// Uploads image to S3 via presigned URL, returns the image URL
Future<String?> _uploadImage(String plantId) async {
  if (_selectedImage == null) return null;

  try {
    // Get presigned URL from Lambda
    final urlResponse = await http.post(
      Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/upload-url'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'plantId': plantId,
        'fileType': 'jpg',
      }),
    );

    if (urlResponse.statusCode == 200) {
      final urlData = jsonDecode(urlResponse.body);
      final uploadUrl = urlData['uploadUrl'];
      final imageUrl = urlData['imageUrl'];

      // Upload image directly to S3
      final imageBytes = await _selectedImage!.readAsBytes();
      await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpg'},
        body: imageBytes,
      );

      return imageUrl;
    }
  } catch (e) {
    // Image upload failed silently -- plant still saves
  }
  return null;
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
              // Plant photo section
              const Text(
                'SPECIMEN PHOTO',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 3,
                  color: Color(0x99aaff00),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
             // Photo preview or placeholder
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: const Color(0xFF0d1500),
                  border: Border.all(color: const Color(0x33aaff00)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'NO PHOTO SELECTED',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0x33aaff00),
                              fontFamily: 'monospace',
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              // Camera and gallery buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text(
                        'CAMERA',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFaaff00),
                        side: const BorderSide(color: Color(0x55aaff00)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text(
                        'GALLERY',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFaaff00),
                        side: const BorderSide(color: Color(0x55aaff00)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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