import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'care_log_screen.dart';
import 'edit_plant_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PlantDetailScreen extends StatefulWidget {
  // Full plant data passed from catalog
  final Map<String, dynamic> plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  // Current plant data -- may be refreshed after edit
  late Map<String, dynamic> _plant;
  // True while a photo replace/remove is in flight
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Initialize with passed plant data
    _plant = widget.plant;
  }

  // Refreshes plant data from API after edit
  Future<void> _refreshPlant() async {
    try {
      
      final response = await http.get(
        Uri.parse(
          'https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants?userId=${_plant['userId']}',
        ),
      );
      
      if (response.statusCode == 200) {
        final plants = jsonDecode(response.body) as List;
        final updated = plants.firstWhere(
          (p) => p['plantId'] == _plant['plantId'],
          orElse: () => _plant,
        );
        if (mounted) {
          setState(() {
            _plant = updated;
          });
        }
      }
    } catch (e) {
      // Keep existing data if refresh fails
    }
  }

  // Deletes plant from DynamoDB
  Future<void> _deletePlant() async {
    try {
      final response = await http.delete(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plantId': _plant['plantId'],
          'userId': _plant['userId'],
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, 'Specimen removed from the catalog.');
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  // Shows confirmation before deleting
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0d1500),
        title: Text(
          'DELETE SPECIMEN',
          style: GoogleFonts.orbitron(
            fontSize: 13,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Remove ${_plant['name']} from the catalog permanently?',
          style: const TextStyle(
            color: Color(0x99aaff00),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0x77aaff00),
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlant();
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Color(0xFFffb000),
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Picks a new photo, uploads it to S3 via a presigned URL, and saves the
  // resulting imageUrl -- lets a photo be swapped without the full edit form
  Future<void> _replacePhoto() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUpdatingPhoto = true);
    try {
      final urlResponse = await http.post(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/upload-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plantId': _plant['plantId'], 'fileType': 'jpg'}),
      );

      if (urlResponse.statusCode == 200) {
        final urlData = jsonDecode(urlResponse.body);
        final bytes = await File(picked.path).readAsBytes();
        await http.put(
          Uri.parse(urlData['uploadUrl']),
          headers: {'Content-Type': 'image/jpg'},
          body: bytes,
        );
        await _savePhotoUrl(urlData['imageUrl']);
      }
    } catch (e) {
      // Upload failed -- photo simply stays as it was
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  void _confirmRemovePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0d1500),
        title: Text(
          'REMOVE PHOTO',
          style: GoogleFonts.orbitron(
            fontSize: 13,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          "Remove this specimen's photo?",
          style: TextStyle(
            color: Color(0x99aaff00),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0x77aaff00),
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removePhoto();
            },
            child: const Text(
              'REMOVE',
              style: TextStyle(
                color: Color(0xFFffb000),
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removePhoto() async {
    setState(() => _isUpdatingPhoto = true);
    await _savePhotoUrl('');
    if (mounted) setState(() => _isUpdatingPhoto = false);
  }

  // Persists imageUrl via the full-record update Lambda -- every field is
  // resent since updatePlant overwrites the whole item rather than patching it
  Future<void> _savePhotoUrl(String imageUrl) async {
    try {
      final response = await http.put(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plantId': _plant['plantId'],
          'name': _plant['name'],
          'species': _plant['species'],
          'cultivar': _plant['cultivar'],
          'lore': _plant['lore'],
          'careInstructions': _plant['careInstructions'],
          'watchFor': _plant['watchFor'],
          'imageUrl': imageUrl,
        }),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _plant = {..._plant, 'imageUrl': imageUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(imageUrl.isEmpty ? 'Photo removed.' : 'Photo updated.'),
          ),
        );
      }
    } catch (e) {
      // Silent failure keeps parity with existing upload error handling
    }
  }

  // Small circular icon control overlaid on the photo (replace / remove)
  Widget _photoOverlayButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color color = const Color(0xFFaaff00),
  }) {
    return Material(
      color: Colors.black.withAlpha(0xAA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        // Plant name as title
        title: Text(
          _plant['name'] ?? 'SPECIMEN',
          key: ValueKey(_plant['name']),
          style: GoogleFonts.orbitron(
            fontSize: 16,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(
          // Back arrow in Toxic Lime
          color: Color(0xFFaaff00),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SPECIMEN FILE',
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 3,
                  color: Color(0x55aaff00),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant photo -- overlay controls allow replace/remove without
            // opening the full edit flow
            if (_plant['imageUrl'] != null && _plant['imageUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x33aaff00)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    // Tap to view full screen
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              elevation: 0,
                              iconTheme: const IconThemeData(color: Color(0xFFaaff00)),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.network(_plant['imageUrl']),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _plant['imageUrl'],
                        fit: BoxFit.contain,
                        // Shows loading indicator while image downloads
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 220,
                            color: const Color(0xFF0d1500),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFaaff00),
                              ),
                            ),
                          );
                        },
                        // Shows fallback if image fails to load
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 220,
                            color: const Color(0xFF0d1500),
                            child: const Center(
                              child: Text(
                                'IMAGE UNAVAILABLE',
                                style: TextStyle(
                                  color: Color(0x55aaff00),
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                    // Replace / remove controls
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _photoOverlayButton(
                            icon: Icons.image_outlined,
                            onTap: _isUpdatingPhoto ? null : _replacePhoto,
                          ),
                          const SizedBox(width: 8),
                          _photoOverlayButton(
                            icon: Icons.delete_outline,
                            color: const Color(0xFFffb000),
                            onTap: _isUpdatingPhoto ? null : _confirmRemovePhoto,
                          ),
                        ],
                      ),
                    ),
                    if (_isUpdatingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(0x88),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFaaff00),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: _isUpdatingPhoto ? null : _replacePhoto,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x33aaff00)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: _isUpdatingPhoto
                          ? const CircularProgressIndicator(
                              color: Color(0xFFaaff00),
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Color(0x77aaff00),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'ADD PHOTO',
                                  style: TextStyle(
                                    color: Color(0x77aaff00),
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            // Genus and cultivar boxes
            Row(
              children: [
                // Genus box
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x33aaff00)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENUS',
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: Color(0x55aaff00),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _plant['species'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFaaff00),
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Cultivar box
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x33aaff00)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CULTIVAR',
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: Color(0x55aaff00),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _plant['cultivar'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFaaff00),
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date acquired box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x33aaff00)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATE ACQUIRED',
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Color(0x55aaff00),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_plant['dateAdded']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFaaff00),
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0x22aaff00)),
            const SizedBox(height: 14),
            // Lore section
            _detailSection('LORE', _plant['lore']),
            const SizedBox(height: 14),
            // Care instructions section
            _detailSection('CARE INSTRUCTIONS', _plant['careInstructions']),
            const SizedBox(height: 14),
            // Watch for section
            _detailSection('WATCH FOR', _plant['watchFor']),
            const SizedBox(height: 32),
            // Actions — icon row replaces the old stacked buttons so the
            // three choices read as equal-weight, related actions
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    icon: Icons.edit_outlined,
                    label: 'EDIT',
                    color: const Color(0xFFaaff00),
                    onTap: () async {
                      final message = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPlantScreen(plant: _plant),
                        ),
                      );
                      // Wait briefly for DynamoDB to finish writing
                      await Future.delayed(const Duration(milliseconds: 500));
                      _refreshPlant();
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionTile(
                    icon: Icons.history,
                    label: 'CARE LOG',
                    color: const Color(0xFFaaff00),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CareLogScreen(plant: _plant),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionTile(
                    icon: Icons.delete_outline,
                    label: 'DELETE',
                    color: const Color(0xFFffb000),
                    onTap: _confirmDelete,
                  ),
                ),
              ],
            ),
            // extra clearance so the row clears a gesture nav bar
            SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // Compact icon+label action button — used for the Edit/Care Log/Delete row
  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(0x77)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable detail section widget
  Widget _detailSection(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0x55aaff00),
            fontFamily: 'monospace',
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value?.toString() ?? 'Not specified',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFaaff00),
            fontFamily: 'monospace',
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // Formats ISO timestamp to readable date
  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(rawDate.toString());
      return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return rawDate.toString();
    }
  }
}