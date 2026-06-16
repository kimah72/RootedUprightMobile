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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh plants when returning to catalog
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: GestureDetector(
                        // Navigate to plant detail on tap
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailScreen(plant: plant),
                            ),
                          );
                            // Refresh catalog when returning from detail
                            _fetchPlants();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // File folder tab with plant name
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0d1500),
                                border: Border(
                                  top: BorderSide(color: Color(0x4Daaff00)),
                                  left: BorderSide(color: Color(0x4Daaff00)),
                                  right: BorderSide(color: Color(0x4Daaff00)),
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(3),
                                  topRight: Radius.circular(3),
                                ),
                              ),
                              child: Text(
                                plant['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFaaff00),
                                  letterSpacing: 1,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            // Card body
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF080d00),
                                border: Border.all(color: const Color(0x40aaff00)),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Species and cultivar
                                  Text(
                                    '${plant['species'] ?? ''} // ${plant['cultivar'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0x80aaff00),
                                      letterSpacing: 1,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Lore
                                  Text(
                                    plant['lore'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0x59aaff00),
                                      fontFamily: 'monospace',
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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