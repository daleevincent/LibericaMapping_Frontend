// lib/screens/liberica_map_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/prediction.dart';
import '../services/prediction_service.dart';
import '../utils/app_theme.dart';
import 'prediction_detail_screen.dart';

class LibericaMapScreen extends StatefulWidget {
  const LibericaMapScreen({super.key});

  @override
  State<LibericaMapScreen> createState() => _LibericaMapScreenState();
}

class _LibericaMapScreenState extends State<LibericaMapScreen> {
  final PredictionService _service = PredictionService();
  GoogleMapController? _mapController;

  List<Prediction> _liberica = [];

  // Groups samples by rounded lat/lng key so stacked ones are detected
  Map<String, List<Prediction>> _groups = {};

  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _selectedKey; // currently tapped group key

  static const CameraPosition _batangasCenter = CameraPosition(
    target: LatLng(AppConstants.batangasCenterLat, AppConstants.batangasCenterLng),
    zoom: AppConstants.defaultZoom,
  );

  // Round to 6 decimal places for grouping key
  String _locationKey(Prediction p) =>
      '${p.latitude!.toStringAsFixed(6)}_${p.longitude!.toStringAsFixed(6)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _selectedKey = null;
    });
    try {
      final all = await _service.getAllPredictions();
      _liberica = all.where((p) => p.isLiberica && p.hasCoordinates).toList();

      // Group by exact GPS location
      _groups = {};
      for (final p in _liberica) {
        final key = _locationKey(p);
        _groups.putIfAbsent(key, () => []).add(p);
      }

      await _buildMarkers();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buildMarkers() async {
    final Set<Marker> markers = {};

    for (final entry in _groups.entries) {
      final key   = entry.key;
      final group = entry.value;
      final first = group.first;
      final count = group.length;
      final isSelected = _selectedKey == key;

      final icon = await _buildCircleIcon(
        color: isSelected ? AppTheme.accent : AppTheme.primary,
        size: isSelected ? 56 : 44,
        count: count,
      );

      markers.add(Marker(
        markerId: MarkerId(key),
        position: LatLng(first.latitude!, first.longitude!),
        icon: icon,
        onTap: () => _onMarkerTap(key, group),
        anchor: const Offset(0.5, 0.5),
      ));
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  // Circle with optional count badge
  Future<BitmapDescriptor> _buildCircleIcon({
    required Color color,
    required double size,
    required int count,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final double r = size / 2;

    // Outer glow
    canvas.drawCircle(Offset(r, r), r,
        Paint()..color = color.withValues(alpha: 0.25));
    // White ring
    canvas.drawCircle(Offset(r, r), r * 0.72,
        Paint()..color = Colors.white);
    // Colored fill
    canvas.drawCircle(Offset(r, r), r * 0.58,
        Paint()..color = color);

    // Draw count badge if more than 1 sample at this location
    if (count > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: r * 0.55,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(r - tp.width / 2, r - tp.height / 2),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<void> _onMarkerTap(String key, List<Prediction> group) async {
    final isDeselect = _selectedKey == key;
    setState(() => _selectedKey = isDeselect ? null : key);
    await _buildMarkers();

    if (!isDeselect && mounted) {
      final first = group.first;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(first.latitude!, first.longitude!),
            zoom: AppConstants.farmZoom,
          ),
        ),
      );
      // Show bottom sheet listing all samples at this location
      _showSamplesSheet(group);
    }
  }

  void _showSamplesSheet(List<Prediction> group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SamplesBottomSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Google Map ───────────────────────────────────────
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: _batangasCenter,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) {
              if (_selectedKey != null) {
                setState(() => _selectedKey = null);
                _buildMarkers();
              }
            },
          ),

          // ── Loading overlay ──────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text('Loading samples...',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),

          // ── Header (matches main dashboard) ─────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Liberica Sample Locations'
                              ' · ${_liberica.length} found',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 20, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Empty state ──────────────────────────────────────────────────
          if (!_isLoading && _liberica.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded,
                        size: 56,
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('No Liberica Samples Yet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Classify a plant sample first.\nOnly Liberica results appear here.',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom sheet listing all samples at a tapped location ─────────────────────

class _SamplesBottomSheet extends StatelessWidget {
  final List<Prediction> group;
  const _SamplesBottomSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${group.length} Sample${group.length > 1 ? 's' : ''} at this Location',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${group.first.latitude!.toStringAsFixed(5)}, '
                      '${group.first.longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontFamily: 'Courier'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Sample list — scrollable if many
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: group.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildSampleTile(context, group[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleTile(BuildContext context, Prediction p, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PredictionDetailScreen(prediction: p),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coffea Liberica',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dnaVerifiedColor)),
                  Text(
                    '${p.modeLabel}  •  ${p.confidenceLabel} confidence',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}