import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';
import 'gallery_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';


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
  // Controls the search input
  final TextEditingController _searchController = TextEditingController();
  // Filtered list of plants
  List<dynamic> _filteredPlants = [];
  // Care logs per plantId, loaded after the catalog so sort/filter/attention
  // features have real history instead of guessing from dateAdded alone
  final Map<String, List<dynamic>> _careLogsByPlant = {};
  // Current sort key: 'name' | 'dateAdded' | 'lastCared'
  String _sortBy = 'name';
  // Selected care-type filter, null means show all
  String? _careTypeFilter;
  // A plant with no log (or none in this many days) surfaces as needing attention
  static const int _attentionThresholdDays = 14;
  // plantIds with a quick-log water request currently in flight
  final Set<String> _wateringInFlight = {};
  // true once care-history has loaded at least once (from network or cache).
  // Until then, _needsAttention stays false for everyone -- otherwise every
  // plant flashes "needs attention" during the gap between plants loading
  // and their care logs arriving (most visible right after a fresh install,
  // when there's no cache yet and the first load has nothing to fall back on)
  bool _careLogsLoaded = false;
  static const List<String> _careTypes = [
    'Watering',
    'Fertilizing',
    'Repotting',
    'Pruning',
    'Leaf Cleaning',
    'Drama',
    'Other',
  ];

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

  String get _plantsCacheKey => 'plants_${widget.userId}';
  String get _careLogsCacheKey => 'careLogs_${widget.userId}';

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
          _isLoading = false;
        });
        _applyFilters();
        _fetchCareLogsForPlants();
        // Cache the live result as the offline fallback
        await Hive.box('offlineCache').put(_plantsCacheKey, response.body);
      } else {
        await _loadPlantsFromCache('Failed to load plants.');
      }
    } catch (e) {
      // No network -- fall back to whatever was last cached
      await _loadPlantsFromCache('Connection error. Please try again.');
    }
  }

  // Loads the last-cached plant list when the live fetch fails; only shows
  // the hard error if there's nothing cached to fall back to
  Future<void> _loadPlantsFromCache(String errorIfEmpty) async {
    final cached = Hive.box('offlineCache').get(_plantsCacheKey) as String?;
    if (cached == null) {
      setState(() {
        _errorMessage = errorIfEmpty;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _plants = jsonDecode(cached);
      _isLoading = false;
    });
    _applyFilters();
    _loadCareLogsFromCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline — showing cached specimens.')),
      );
    }
  }

  void _loadCareLogsFromCache() {
    final cached = Hive.box('offlineCache').get(_careLogsCacheKey) as String?;
    if (cached == null) return;
    final decoded = jsonDecode(cached) as Map<String, dynamic>;
    setState(() {
      _careLogsByPlant
        ..clear()
        ..addAll(decoded.map((key, value) => MapEntry(key, value as List<dynamic>)));
      _careLogsLoaded = true;
    });
    _applyFilters();
  }

  // Signs out of the current account and clears remembered credentials,
  // so a different account can log in without reinstalling the app
  Future<void> _logout() async {
    await AuthService().clearCredentials();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0d1500),
        title: Text(
          'SIGN OUT',
          style: GoogleFonts.orbitron(
            fontSize: 13,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          'End this session and return to the login screen?',
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
              _logout();
            },
            child: const Text(
              'SIGN OUT',
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

  // Fetches each plant's care history in parallel — needed for the
  // "last cared for" sort, the care-type filter, and the attention flag
  Future<void> _fetchCareLogsForPlants() async {
    final Map<String, List<dynamic>> logs = {};
    await Future.wait(_plants.map((plant) async {
      final plantId = plant['plantId'] as String;
      try {
        final response = await http.get(
          Uri.parse(
            'https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/carelogs?plantId=$plantId',
          ),
        );
        if (response.statusCode == 200) {
          logs[plantId] = jsonDecode(response.body);
        }
      } catch (e) {
        // A single plant's request failing shouldn't erase its last-known
        // history -- it's merged in below only when it actually succeeds
      }
    }));
    if (!mounted) return;

    if (logs.isEmpty && _plants.isNotEmpty) {
      // Every request failed (likely offline) -- keep last-known history
      _loadCareLogsFromCache();
      return;
    }

    // Merge rather than replace: a plant whose request failed this round
    // keeps its previous data instead of being wrongly flagged as overdue
    setState(() {
      _careLogsByPlant.addAll(logs);
      _careLogsLoaded = true;
    });
    _applyFilters();
    // Cache the full merged map, not just this round's results, so a
    // partial fetch never overwrites the cache with incomplete history
    await Hive.box('offlineCache').put(_careLogsCacheKey, jsonEncode(_careLogsByPlant));
  }

  // Refetches care history for just one plant. Used after a quick-log so the
  // attention list updates as soon as that write actually lands, instead of
  // waiting on a full re-fetch of every plant's history (which is what made
  // the water-drop button feel inconsistent -- its timing depended on how
  // long the *entire* catalog's care logs took to come back).
  Future<void> _fetchCareLogForPlant(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/carelogs?plantId=$plantId',
        ),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _careLogsByPlant[plantId] = jsonDecode(response.body));
        _applyFilters();
        await Hive.box('offlineCache')
            .put(_careLogsCacheKey, jsonEncode(_careLogsByPlant));
      }
    } catch (e) {
      // Leave last-known history in place if this refetch fails
    }
  }

  // Most recent dateLogged for a plant, or null if it has no care history
  DateTime? _lastCaredDate(String plantId) {
    final logs = _careLogsByPlant[plantId];
    if (logs == null || logs.isEmpty) return null;
    DateTime? latest;
    for (final log in logs) {
      final logged = DateTime.tryParse(log['dateLogged']?.toString() ?? '');
      if (logged != null && (latest == null || logged.isAfter(latest))) {
        latest = logged;
      }
    }
    return latest;
  }

  // True if a plant has never been logged, or not within the threshold.
  // Before care history has loaded at least once, nothing is flagged --
  // otherwise every plant reads as overdue during the initial load.
  bool _needsAttention(String plantId) {
    if (!_careLogsLoaded) return false;
    final lastCared = _lastCaredDate(plantId);
    if (lastCared == null) return true;
    return DateTime.now().difference(lastCared).inDays >= _attentionThresholdDays;
  }

  bool _hasCareType(String plantId, String careType) {
    final logs = _careLogsByPlant[plantId];
    if (logs == null) return false;
    return logs.any((log) => log['careType'] == careType);
  }

  // Recomputes _filteredPlants from the search box, the care-type filter,
  // and the current sort order
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final result = _plants.where((plant) {
      final name = (plant['name'] ?? '').toString().toLowerCase();
      final species = (plant['species'] ?? '').toString().toLowerCase();
      final cultivar = (plant['cultivar'] ?? '').toString().toLowerCase();
      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          species.contains(query) ||
          cultivar.contains(query);
      final matchesCareType = _careTypeFilter == null ||
          _hasCareType(plant['plantId'], _careTypeFilter!);
      return matchesSearch && matchesCareType;
    }).toList();

    result.sort((a, b) {
      switch (_sortBy) {
        case 'dateAdded':
          final aDate = DateTime.tryParse(a['dateAdded']?.toString() ?? '') ??
              DateTime(1970);
          final bDate = DateTime.tryParse(b['dateAdded']?.toString() ?? '') ??
              DateTime(1970);
          return bDate.compareTo(aDate); // newest first
        case 'lastCared':
          final aDate = _lastCaredDate(a['plantId']);
          final bDate = _lastCaredDate(b['plantId']);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return -1; // never logged surfaces first
          if (bDate == null) return 1;
          return aDate.compareTo(bDate); // longest overdue first
        default:
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
      }
    });

    setState(() => _filteredPlants = result);
  }

  // Logs a watering entry directly from the catalog card, without opening
  // the plant detail screen
  Future<void> _quickLogWater(Map<String, dynamic> plant) async {
    final plantId = plant['plantId'] as String;
    // Ignore taps while a log for this plant is already in flight -- without
    // this, a fast double-tap fires two overlapping requests whose refetches
    // can land out of order
    if (_wateringInFlight.contains(plantId)) return;
    setState(() => _wateringInFlight.add(plantId));
    try {
      final response = await http.post(
        Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/carelogs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plantId': plantId,
          'careType': 'Watering',
          'notes': '',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Wait for the refetch so the attention list updates before we
        // report success, instead of leaving it to land whenever it lands
        await _fetchCareLogForPlant(plantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged watering for ${plant['name'] ?? 'specimen'}.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log care. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _wateringInFlight.remove(plantId));
    }
  }

  void _confirmWaterAll() {
    final count = _filteredPlants.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0d1500),
        title: Text(
          'WATER ALL',
          style: GoogleFonts.orbitron(
            fontSize: 13,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Log a watering entry for all $count specimen${count == 1 ? '' : 's'} currently shown?',
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
              _waterAll();
            },
            child: const Text(
              'WATER ALL',
              style: TextStyle(
                color: Color(0xFFaaff00),
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logs a watering entry for every plant currently shown (respects any
  // active search/filter) in one pass
  Future<void> _waterAll() async {
    final targets = List<dynamic>.from(_filteredPlants);
    int successCount = 0;

    await Future.wait(targets.map((plant) async {
      try {
        final response = await http.post(
          Uri.parse('https://xt71zwxu10.execute-api.us-east-1.amazonaws.com/carelogs'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'plantId': plant['plantId'],
            'careType': 'Watering',
            'notes': '',
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          successCount++;
        }
      } catch (e) {
        // Counted as a miss -- reflected in the summary snackbar below
      }
    }));

    _fetchCareLogsForPlants();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == targets.length
              ? 'Logged watering for all $successCount specimens.'
              : 'Logged watering for $successCount of ${targets.length} specimens.',
        ),
      ),
    );
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
          // Water All — logs a watering entry for every currently visible
          // specimen in one tap, for the "just water everything" routine
          IconButton(
            onPressed: _filteredPlants.isEmpty ? null : _confirmWaterAll,
            tooltip: 'Water all',
            icon: const Icon(
              Icons.water_drop,
              color: Color(0x77aaff00),
              size: 20,
            ),
          ),
          // Gallery view button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GalleryScreen(plants: _plants),
                ),
              );
            },
            icon: const Icon(
              Icons.photo_library_outlined,
              color: Color(0x77aaff00),
              size: 20,
            ),
          ),
          // Sign out — clears the remembered account so another one can log in
          IconButton(
            onPressed: _confirmLogout,
            tooltip: 'Sign out',
            icon: const Icon(
              Icons.logout,
              color: Color(0x77aaff00),
              size: 20,
            ),
          ),
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
                      color: Color(0xFFffb000),
                      fontFamily: 'monospace',
                    ),
                  ),
                )
              : Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilters(),
                      style: const TextStyle(
                        color: Color(0xFFaaff00),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: 'SEARCH SPECIMENS...',
                        hintStyle: const TextStyle(
                          color: Color(0x33aaff00),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0x55aaff00),
                          size: 18,
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
                  ),
                  // Sort and care-type filter controls
                  _buildToolbarRow(),
                  // Plant list, with an attention section pinned to the top
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final attentionPlants = _filteredPlants
                            .where((p) => _needsAttention(p['plantId']))
                            .toList();
                        final restPlants = _filteredPlants
                            .where((p) => !_needsAttention(p['plantId']))
                            .toList();

                        if (_filteredPlants.isEmpty) {
                          return const Center(
                            child: Text(
                              'NO SPECIMENS MATCH',
                              style: TextStyle(
                                color: Color(0x55aaff00),
                                fontFamily: 'monospace',
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                          );
                        }

                        return ListView(
                          children: [
                            if (attentionPlants.isNotEmpty) ...[
                              _sectionHeader(
                                'NEEDS ATTENTION (${attentionPlants.length})',
                                const Color(0xFFffb000),
                              ),
                              ...attentionPlants.map(_buildPlantCard),
                              if (restPlants.isNotEmpty)
                                _sectionHeader('ALL SPECIMENS', const Color(0xFFaaff00)),
                            ],
                            ...restPlants.map(_buildPlantCard),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          // Navigate to add plant screen
          backgroundColor: const Color(0xFFaaff00),
          foregroundColor: const Color(0xFF080d00),
          onPressed: () async {
            final message = await Navigator.push<String?>(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlantScreen(userId: widget.userId),
              ),
            );
            // Refresh the catalog after returning
            _fetchPlants();
            if (message != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
          child: const Icon(Icons.add),
        ),
    );
  }

  // Sort-by and care-type-filter dropdowns shown above the plant list
  Widget _buildToolbarRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _dropdownShell(
              icon: Icons.sort,
              child: DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF0d1500),
                style: const TextStyle(
                  color: Color(0xFFaaff00),
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('NAME')),
                  DropdownMenuItem(value: 'dateAdded', child: Text('DATE ADDED')),
                  DropdownMenuItem(value: 'lastCared', child: Text('LAST CARED')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortBy = value);
                  _applyFilters();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dropdownShell(
              icon: Icons.filter_alt_outlined,
              child: DropdownButton<String?>(
                value: _careTypeFilter,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF0d1500),
                style: const TextStyle(
                  color: Color(0xFFaaff00),
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                hint: const Text(
                  'ALL CARE TYPES',
                  style: TextStyle(
                    color: Color(0x77aaff00),
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ALL CARE TYPES'),
                  ),
                  ..._careTypes.map(
                    (type) => DropdownMenuItem<String?>(
                      value: type,
                      child: Text(type.toUpperCase()),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _careTypeFilter = value);
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownShell({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1500),
        border: Border.all(color: const Color(0x33aaff00)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0x77aaff00)),
          const SizedBox(width: 6),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontFamily: 'monospace',
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlantCard(dynamic plant) {
    final plantId = plant['plantId'] as String;
    final attention = _needsAttention(plantId);
    final tabBorderColor =
        attention ? const Color(0x80ffb000) : const Color(0x4Daaff00);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        // Navigate to plant detail on tap
        onTap: () async {
          final message = await Navigator.push<String?>(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDetailScreen(plant: plant),
            ),
          );
          // Refresh catalog when returning from detail
          _fetchPlants();
          if (message != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File folder tab with plant name, attention flag, and quick-log
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0d1500),
                border: Border(
                  top: BorderSide(color: tabBorderColor),
                  left: BorderSide(color: tabBorderColor),
                  right: BorderSide(color: tabBorderColor),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
              child: Row(
                children: [
                  if (attention)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: Color(0xFFffb000),
                      ),
                    ),
                  Expanded(
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
                  // Quick-log a watering entry without opening the detail screen
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _quickLogWater(plant),
                      borderRadius: BorderRadius.circular(2),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _wateringInFlight.contains(plantId)
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFFaaff00),
                                ),
                              )
                            : const Icon(
                                Icons.water_drop_outlined,
                                size: 14,
                                color: Color(0xFFaaff00),
                              ),
                      ),
                    ),
                  ),
                ],
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo thumbnail, only if imageUrl exists
                  if (plant['imageUrl'] != null && plant['imageUrl'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0x59aaff00)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            plant['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            // Shows nothing while loading to avoid layout flicker
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(width: 50, height: 50);
                            },
                            // Hides broken images gracefully
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(width: 50, height: 50);
                            },
                          ),
                        ),
                      ),
                    ),
                  // Text content
                  Expanded(
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
          ],
        ),
      ),
    );
  }
}