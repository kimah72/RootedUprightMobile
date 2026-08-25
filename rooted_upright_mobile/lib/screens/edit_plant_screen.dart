import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  // Selected new image file, if user picks a replacement
  File? _selectedImage;
  // Image picker instance
  final ImagePicker _picker = ImagePicker();

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

  // Opens camera or gallery to select a replacement image
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

  // Uploads new image to S3 via presigned URL, returns the image URL
  Future<String?> _uploadImage(String plantId) async {
    if (_selectedImage == null) return null;

    try {
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

        final imageBytes = await _selectedImage!.readAsBytes();
        await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': 'image/jpg'},
          body: imageBytes,
        );

        return imageUrl;
      }
    } catch (e) {
      // Image upload failed
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
            // Photo preview -- shows new selection, existing photo, or placeholder
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
                    : (widget.plant['imageUrl'] != null && widget.plant['imageUrl'].toString().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.network(
                              widget.plant['imageUrl'],
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
      // Upload new image if one was selected, otherwise keep existing
      String? imageUrl = widget.plant['imageUrl'];
      if (_selectedImage != null) {
        final newImageUrl = await _uploadImage(widget.plant['plantId']);
        if (newImageUrl != null) {
          imageUrl = newImageUrl;
        }
      }

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
          'imageUrl': imageUrl,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, 'Specimen updated.');
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