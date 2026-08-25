import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GalleryScreen extends StatelessWidget {
  // Full plant list passed from catalog
  final List<dynamic> plants;

  const GalleryScreen({super.key, required this.plants});

  @override
  Widget build(BuildContext context) {
    // Only show plants that have a photo
    final plantsWithPhotos = plants.where((plant) =>
        plant['imageUrl'] != null && plant['imageUrl'].toString().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        title: Text(
          'SPECIMEN GALLERY',
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
      body: plantsWithPhotos.isEmpty
          ? const Center(
              child: Text(
                'NO PHOTOS YET',
                style: TextStyle(
                  color: Color(0x55aaff00),
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              // Two columns, square tiles
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: plantsWithPhotos.length,
              itemBuilder: (context, index) {
                final plant = plantsWithPhotos[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo
                      Image.network(
                        plant['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: const Color(0xFF0d1500));
                        },
                      ),
                      // Name label overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(0xCC080d00),
                          child: Text(
                            plant['name'] ?? 'Unknown',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFaaff00),
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}