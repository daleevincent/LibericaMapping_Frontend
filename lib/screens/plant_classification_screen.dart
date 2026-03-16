// lib/screens/plant_classification_screen.dart
//
// Tab 3 — Plant Classification
// Features:
//   • Pick or capture a photo of a coffee plant
//   • Choose plant part mode: leaf / bark / cherry / mix
//   • Enter GPS coordinates (or auto-detect)
//   • Send to MobileNetV2 backend for Liberica prediction
//   • Display result + confidence + Grad-CAM heatmap
//   • Browse history of all past predictions from MongoDB

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/farm.dart';
import '../models/prediction.dart';
import '../services/farm_service.dart';
import '../services/prediction_service.dart';
import '../utils/app_theme.dart';
import '../utils/mock_tree_data.dart';
import 'tree_map_screen.dart';
import 'prediction_detail_screen.dart';
import 'liberica_map_screen.dart';

class PlantClassificationScreen extends StatefulWidget {
  const PlantClassificationScreen({super.key});

  @override
  State<PlantClassificationScreen> createState() =>
      _PlantClassificationScreenState();
}

class _PlantClassificationScreenState
    extends State<PlantClassificationScreen>
    with SingleTickerProviderStateMixin {
  final PredictionService _service = PredictionService();
  final FarmService _farmService = FarmService();
  final ImagePicker _picker = ImagePicker();

  late TabController _tabController;

  // ── Classify tab state ───────────────────────────────────────────────────
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String _plantPartMode = 'leaf';
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isClassifying = false;
  Prediction? _result;

  // ── GPS state ────────────────────────────────────────────────────────────
  bool _autoGps = true;          // toggle: auto-fill coords from device GPS
  bool _isFetchingGps = false;   // spinner while fetching
  String? _gpsError;             // error message if permission denied / fail

  // ── History tab state ────────────────────────────────────────────────────
  List<Prediction> _history = [];
  bool _isLoadingHistory = true;
  String _historyFilter = 'all';      // all | leaf | bark | cherry | mix
  String _resultFilter  = 'all';      // all | liberica | not_liberica

  static const List<Map<String, dynamic>> _modes = [
    {'value': 'leaf',   'label': 'Leaf',     'icon': Icons.eco_rounded},
    {'value': 'bark',   'label': 'Bark',     'icon': Icons.park_rounded},
    {'value': 'cherry', 'label': 'Cherry',   'icon': Icons.circle},
    {'value': 'mix',    'label': 'Combined', 'icon': Icons.auto_awesome},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImageFile  = picked;
      _selectedImageBytes = bytes;
    });
    // Auto-fetch GPS right after taking the photo if toggle is on
    if (_autoGps) await _fetchGps();
  }

  // ── GPS location ──────────────────────────────────────────────────────────

  Future<void> _fetchGps() async {
    setState(() {
      _isFetchingGps = true;
      _gpsError = null;
    });
    try {
      // Check & request permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = perm == LocationPermission.deniedForever
              ? 'Location permission permanently denied. Enable it in Settings.'
              : 'Location permission denied.';
          _isFetchingGps = false;
        });
        return;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'Location services are disabled. Please turn on GPS.';
          _isFetchingGps = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        _isFetchingGps = false;
        _gpsError = null;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Could not get location: $e';
        _isFetchingGps = false;
      });
    }
  }

  // ── Classification ────────────────────────────────────────────────────────

  Future<void> _classify() async {
    if (_selectedImageFile == null || _selectedImageBytes == null) {
      _showSnack('Please select or capture an image first.', isError: true);
      return;
    }
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      _showSnack('Please enter valid GPS coordinates.', isError: true);
      return;
    }

    setState(() {
      _isClassifying = true;
      _result = null;
    });

    try {
      final prediction = await _service.predict(
        imageFile:     _selectedImageFile!,
        imageBytes:    _selectedImageBytes!,
        plantPartMode: _plantPartMode,
        latitude:      lat,
        longitude:     lng,
      );
      setState(() {
        _result = prediction;
        _isClassifying = false;
      });
      _loadHistory();
    } catch (e) {
      setState(() => _isClassifying = false);
      _showSnack('Classification failed: $e', isError: true);
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final predictions = await _service.getAllPredictions();
      setState(() {
        _history = predictions;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  // ── View on Tree Map ──────────────────────────────────────────────────────

  Future<void> _viewOnTreeMap(Prediction p) async {
    if (p.latitude == null || p.longitude == null) {
      _showSnack('No GPS coordinates in this prediction.', isError: true);
      return;
    }

    final lat = p.latitude!;
    final lng = p.longitude!;
    final coords = LatLng(lat, lng);

    // Find which farm this tree belongs to via mock data
    final result = MockTreeData.findByCoordinates(lat, lng);

    Farm? targetFarm;

    if (result != null) {
      // Match found — load the real farm from backend (or fallback to mock)
      try {
        final farms = await _farmService.getAllFarms();
        targetFarm = farms.firstWhere(
          (f) => f.id == result.tree.farmId,
          orElse: () => _buildMockFarm(result),
        );
      } catch (_) {
        targetFarm = _buildMockFarm(result);
      }
    } else {
      // No tree match — still navigate to the closest farm or first farm
      try {
        final farms = await _farmService.getAllFarms();
        if (farms.isNotEmpty) targetFarm = farms.first;
      } catch (_) {}
    }

    if (!mounted) return;

    if (targetFarm == null) {
      _showSnack('Could not find a matching farm.', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreeMapScreen(
          farm: targetFarm!,
          highlightCoords: coords,
        ),
      ),
    );
  }

  /// Builds a minimal Farm object from mock data when backend is unavailable
  Farm _buildMockFarm(TreeLocationResult result) {
    return Farm(
      mongoId:          '',
      id:               result.tree.farmId,
      ownerId:          0,
      name:             result.farmName,
      cityId:           0,
      cityName:         result.farmLocation.split(', ').last,
      barangayName:     result.farmLocation.split(', ').first,
      latitude:         result.tree.latitude,
      longitude:        result.tree.longitude,
      totalTrees:       0,
      dnaVerifiedCount: 0,
      hasDnaVerified:   false,
      boundary:         const [],
    );
  }


  List<Prediction> get _filteredHistory {
    var list = _history;
    // Filter by plant part
    if (_historyFilter != 'all') {
      list = list.where((p) => p.plantPartMode == _historyFilter).toList();
    }
    // Filter by result
    if (_resultFilter == 'liberica') {
      list = list.where((p) => p.isLiberica).toList();
    } else if (_resultFilter == 'not_liberica') {
      list = list.where((p) => !p.isLiberica).toList();
    }
    return list;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _resetInputs() {
    setState(() {
      _selectedImageFile  = null;
      _selectedImageBytes = null;
      _latController.clear();
      _lngController.clear();
      _plantPartMode = 'leaf';
      _gpsError = null;
      // _result is intentionally kept — only replaced by new classification
    });
  }

  bool get _hasAnyInput =>
      _selectedImageBytes != null ||
      _latController.text.isNotEmpty ||
      _lngController.text.isNotEmpty ||
      _plantPartMode != 'leaf';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildClassifyTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.biotech_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plant Classification',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'MobileNetV2 Liberica Prediction',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textLight,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Classify'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  // ── Classify tab ──────────────────────────────────────────────────────────

  Widget _buildClassifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Step 1: Photo ─────────────────────────────────────────────────
          _buildStepCard(
            step: '1',
            title: 'Take a Photo',
            subtitle: 'Camera only — field capture required',
            child: _buildImagePicker(),
          ),

          const SizedBox(height: 14),

          // ── Step 2: Plant Part ────────────────────────────────────────────
          _buildStepCard(
            step: '2',
            title: 'Plant Part',
            subtitle: 'Select the part you photographed',
            child: _buildModePicker(),
          ),

          const SizedBox(height: 14),

          // ── Step 3: GPS ───────────────────────────────────────────────────
          _buildStepCard(
            step: '3',
            title: 'GPS Coordinates',
            subtitle: 'Auto-filled from your device location',
            child: _buildCoordinateFields(),
          ),

          const SizedBox(height: 20),

          // ── Action buttons ────────────────────────────────────────────────
          Row(
            children: [
              if (_hasAnyInput) ...[
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isClassifying ? null : _resetInputs,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isClassifying ? null : _classify,
                    icon: _isClassifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.biotech_rounded, size: 20),
                    label: Text(
                      _isClassifying ? 'Analysing...' : 'Classify Plant',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Result ────────────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResultCard(_result!),
          ],
        ],
      ),
    );
  }

  // Step card wrapper — clean numbered card UI
  Widget _buildStepCard({
    required String step,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _selectedImageBytes == null ? _takePhoto : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImageBytes != null
                ? AppTheme.primary
                : Colors.grey.shade300,
            width: _selectedImageBytes != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: _selectedImageBytes != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Retake button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Retake',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Clear button
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: _resetInputs,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 40,
                        color: AppTheme.primary.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to take a photo',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Camera only — no gallery upload',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildModePicker() {
    return Row(
      children: _modes.map((mode) {
        final isSelected = _plantPartMode == mode['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _plantPartMode = mode['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    mode['icon'] as IconData,
                    color: isSelected ? Colors.white : AppTheme.textLight,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoordinateFields() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Auto GPS toggle row ─────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.gps_fixed,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto GPS',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text('Fill coordinates from device location',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ),
              Switch(
                value: _autoGps,
                onChanged: (v) async {
                  setState(() => _autoGps = v);
                  if (v) await _fetchGps();
                },
                activeThumbColor: AppTheme.primary,
                activeTrackColor: AppTheme.primaryLight,
              ),
            ],
          ),

          // ── GPS status indicator ────────────────────────────────────────
          if (_isFetchingGps) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary),
                ),
                SizedBox(width: 8),
                Text('Getting your location...',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.primary)),
              ],
            ),
          ],

          if (_gpsError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFF57C00)), // orange.shade700
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_gpsError!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE65100))), // orange.shade800
                  ),
                  GestureDetector(
                    onTap: _fetchGps,
                    child: const Text('Retry',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Lat / Lng fields ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildCoordField(
                    controller: _latController,
                    label: 'Latitude',
                    hint: 'e.g. 13.9288'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoordField(
                    controller: _lngController,
                    label: 'Longitude',
                    hint: 'e.g. 121.1998'),
              ),
            ],
          ),

          // Manual refresh button
          if (!_autoGps) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isFetchingGps ? null : _fetchGps,
                icon: const Icon(Icons.my_location_rounded, size: 15),
                label: const Text('Get Current Location',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Result card ───────────────────────────────────────────────────────────

  Widget _buildResultCard(Prediction p) {
    final isLiberica = p.isLiberica;
    final resultColor =
        isLiberica ? AppTheme.dnaVerifiedColor : Colors.red.shade600;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: resultColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: resultColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Result header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLiberica
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: resultColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.finalPrediction,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: resultColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Confidence: ${p.confidenceLabel}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Confidence bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Confidence',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500)),
                        Text(p.confidenceLabel,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: resultColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.confidenceRatio / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(resultColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Details row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildResultDetail(
                      'Plant Part',
                      p.modeLabel,
                      Icons.category_rounded,
                    ),
                    _buildResultDetail(
                      'Latitude',
                      p.latitude?.toStringAsFixed(6) ?? 'N/A',
                      Icons.gps_fixed,
                    ),
                    _buildResultDetail(
                      'Longitude',
                      p.longitude?.toStringAsFixed(6) ?? 'N/A',
                      Icons.explore_rounded,
                    ),
                  ],
                ),
              ),

              // Grad-CAM heatmap
              if (p.hasGradCam) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gradient_rounded,
                              size: 16, color: AppTheme.accent),
                          SizedBox(width: 6),
                          Text(
                            'Grad-CAM Visualization',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Highlighted regions influenced the prediction',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildBase64Image(p.gradCamImage!),
                      ),
                    ],
                  ),
                ),
              ],

              // Individual model predictions (mix mode)
              if (p.individualPredictions.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Per-Model Results',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final entry in p.individualPredictions.entries)
                        Builder(builder: (context) {
                          final organ = entry.key;
                          final pred  = entry.value;
                          final isLib = pred.prediction.toLowerCase() ==
                              'liberica';
                          final c = isLib
                              ? AppTheme.dnaVerifiedColor
                              : Colors.red.shade400;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    organ[0].toUpperCase() +
                                        organ.substring(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pred.confidence / 100,
                                      backgroundColor:
                                          Colors.grey.shade100,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(c),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${pred.confidence.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: c,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── View on Tree Map button ─────────────────────────────────────────
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _viewOnTreeMap(p),
            icon: const Icon(Icons.map_rounded, size: 16),
            label: const Text(
              'View on Tree Map',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildBase64Image(String base64Str) {
    try {
      final data = base64Str.contains(',')
          ? base64Str.split(',').last
          : base64Str;
      final bytes = base64Decode(data);
      return Image.memory(bytes, width: double.infinity, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        height: 100,
        color: Colors.grey.shade100,
        child: const Center(
          child: Text('Grad-CAM unavailable',
              style: TextStyle(color: AppTheme.textLight)),
        ),
      );
    }
  }

  Widget _buildResultDetail(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppTheme.textLight),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  // ── History tab ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    final libericaCount = _history.where((p) => p.isLiberica).length;
    return Column(
      children: [
        // ── Row 1: Result filter ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildResultFilterChip('all', 'All', AppTheme.primary),
                _buildResultFilterChip(
                    'liberica', '🌿 Liberica', AppTheme.dnaVerifiedColor),
                _buildResultFilterChip(
                    'not_liberica', '✗ Not Liberica', Colors.red.shade500),
              ],
            ),
          ),
        ),

        // ── Row 2: Plant part filter ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHistoryFilterChip('all', 'All Parts'),
                ..._modes.map((m) => _buildHistoryFilterChip(
                    m['value'] as String, m['label'] as String)),
              ],
            ),
          ),
        ),

        // ── Summary counts + Map button ───────────────────────────────────
        if (!_isLoadingHistory) _buildHistorySummary(libericaCount),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _isLoadingHistory
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : _filteredHistory.isEmpty
                  ? _buildHistoryEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (_, i) =>
                            _buildHistoryTile(_filteredHistory[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildResultFilterChip(String value, String label, Color activeColor) {
    final isSelected = _resultFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _resultFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryFilterChip(String value, String label) {
    final isSelected = _historyFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _historyFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySummary(int libericaCount) {
    final all = _history.length;
    final notLiberica = all - libericaCount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _buildHistoryStat('$all', 'Total', AppTheme.textSecondary),
          _buildHistoryStat('$libericaCount', 'Liberica', AppTheme.dnaVerifiedColor),
          _buildHistoryStat('$notLiberica', 'Not Liberica', Colors.red.shade400),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: libericaCount == 0
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LibericaMapScreen(),
                      ),
                    ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: libericaCount > 0
                    ? AppTheme.primary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_rounded,
                      size: 13,
                      color: libericaCount > 0
                          ? Colors.white
                          : AppTheme.textLight),
                  const SizedBox(width: 5),
                  Text(
                    'View Map',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: libericaCount > 0
                          ? Colors.white
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Prediction p) {
    final isLiberica = p.isLiberica;
    final color =
        isLiberica ? AppTheme.dnaVerifiedColor : Colors.red.shade500;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionDetailScreen(prediction: p),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLiberica
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          p.finalPrediction,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              '${p.modeLabel}  •  ${p.confidenceLabel} confidence',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              '${p.latitude?.toStringAsFixed(5) ?? 'N/A'}, ${p.longitude?.toStringAsFixed(5) ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.confidenceLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHistoryEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 56, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No predictions yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('Use the Classify tab to analyse a plant.',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}