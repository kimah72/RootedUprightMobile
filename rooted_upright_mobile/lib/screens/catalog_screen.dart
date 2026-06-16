import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';


class CatalogScreen extends StatefulWidget {
  // userId passed from login screen
  final String userId;

  const CatalogScreen({super.key, required this.userId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Plants loaded from API
  List<dynamic> _plants = [];
  // Tracks loading state
  bool _isLoading = true;
  // Holds any error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch plants when screen loads
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/plants?userId=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Parse the JSON response into a list
          _plants = jsonDecode(response.body);
          // Sort alphabetically by plant name
          _plants.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load plants.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        // Catalog app bar
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        title: Text(
          'SPECIMEN CATALOG',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        actions: [
          // Shows total plant count
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x33aaff00)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${_plants.length}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0x77aaff00),
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0x33aaff00),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                // Toxic lime loading spinner
                color: Color(0xFFaaff00),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFff0000),
                      fontFamily: 'monospace',
                    ),
                  ),
                )
              : ListView.builder(
                  // Builds one card per plant
                  itemCount: _plants.length,
                  itemBuilder: (context, index) {
                    final plant = _plants[index];
                    return GestureDetector(
                      // Navigate to plant detail on tap
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlantDetailScreen(plant: plant),
                          ),
                        );
                      },
                      child: Container(
                        // Specimen card
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111f00),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFFaaff00),
                            width: 3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Plant name
                                Text(
                                  plant['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFaaff00),
                                    letterSpacing: 1,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                // Cultivar badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x11aaff00),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    (plant['cultivar'] ?? '').toString().toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0x55aaff00),
                                      letterSpacing: 1,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Species
                            Text(
                              plant['species'] ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0x77aaff00),
                                letterSpacing: 1,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Lore
                            Text(
                              plant['lore'] ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0x55aaff00),
                                fontFamily: 'monospace',
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          // Navigate to add plant screen
          backgroundColor: const Color(0xFFaaff00),
          foregroundColor: const Color(0xFF080d00),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlantScreen(userId: widget.userId),
              ),
            );
            // Refresh the catalog after returning
            _fetchPlants();
          },
          child: const Icon(Icons.add),
        ),
    );
  }
}