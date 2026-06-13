import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'care_log_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  // Full plant data passed from catalog
  final Map<String, dynamic> plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        // Plant name as title
        title: Text(
          plant['name'] ?? 'SPECIMEN',
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
                          plant['species'] ?? 'Unknown',
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
                          plant['cultivar'] ?? 'Unknown',
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
                    _formatDate(plant['dateAdded']),
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
            _detailSection('LORE', plant['lore']),
            const SizedBox(height: 14),
            // Care instructions section
            _detailSection('CARE INSTRUCTIONS', plant['careInstructions']),
            const SizedBox(height: 14),
            // Watch for section
            _detailSection('WATCH FOR', plant['watchFor']),
            const SizedBox(height: 32),
            // View care log button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CareLogScreen(plant: plant),
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