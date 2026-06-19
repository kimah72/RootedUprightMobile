import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'care_log_screen.dart';
import 'edit_plant_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
        if (mounted) Navigator.pop(context);
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
            // Plant photo, shown only if one exists
            if (_plant['imageUrl'] != null && _plant['imageUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
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
            // Edit button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPlantScreen(plant: _plant),
                    ),
                  );
                    // Wait briefly for DynamoDB to finish writing
                    await Future.delayed(const Duration(milliseconds: 500));
                    _refreshPlant();
                  },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFaaff00),
                  side: const BorderSide(color: Color(0x77aaff00)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  'EDIT SPECIMEN',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // View care log button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CareLogScreen(plant: _plant),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFaaff00),
                  foregroundColor: const Color(0xFF080d00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  'VIEW CARE LOG',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
                        const SizedBox(height: 12),
            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _confirmDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFffb000),
                  side: const BorderSide(color: Color(0x77ffb000)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  'DELETE SPECIMEN',
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