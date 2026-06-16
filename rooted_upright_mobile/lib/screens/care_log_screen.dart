import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'add_care_log_screen.dart';

class CareLogScreen extends StatefulWidget {
  // Plant data passed from detail screen
  final Map<String, dynamic> plant;

  const CareLogScreen({super.key, required this.plant});

  @override
  State<CareLogScreen> createState() => _CareLogScreenState();
}

class _CareLogScreenState extends State<CareLogScreen> {
  // Care logs loaded from API
  List<dynamic> _careLogs = [];
  // Tracks loading state
  bool _isLoading = true;
  // Holds any error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch care logs when screen loads
    _fetchCareLogs();
  }

  Future<void> _fetchCareLogs() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/carelogs?plantId=${widget.plant['plantId']}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Parse the JSON response into a list
          _careLogs = jsonDecode(response.body);
          // Sort by date, most recent first
          _careLogs.sort(
            (a, b) => (b['dateLogged'] ?? '').compareTo(a['dateLogged'] ?? ''),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load care logs.';
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
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        title: Text(
          '${widget.plant['name']} // CARE LOG',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFaaff00)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0x33aaff00), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFaaff00)),
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
          : _careLogs.isEmpty
          ? const Center(
              child: Text(
                'NO CARE LOGS YET',
                style: TextStyle(
                  color: Color(0x55aaff00),
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _careLogs.length,
              itemBuilder: (context, index) {
                final log = _careLogs[index];
                return Container(
                  // Care log entry card
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d1500),
                    border: Border.all(color: const Color(0x33aaff00)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Care type
                          Text(
                            (log['careType'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFaaff00),
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          // Date logged
                          Text(
                            _formatDate(log['dateLogged']),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0x77aaff00),
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      if (log['notes'] != null &&
                          log['notes'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            log['notes'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0x99aaff00),
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        floatingActionButton: FloatingActionButton(
        // Navigate to add care log screen
        backgroundColor: const Color(0xFFaaff00),
        foregroundColor: const Color(0xFF080d00),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCareLogScreen(plant: widget.plant),
            ),
          );
          // Refresh care logs after returning
          _fetchCareLogs();
        },
        child: const Icon(Icons.add),
      ),
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
