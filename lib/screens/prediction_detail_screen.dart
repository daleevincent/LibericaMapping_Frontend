// lib/screens/prediction_detail_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/farm.dart';
import '../models/prediction.dart';
import '../services/farm_service.dart';
import '../utils/app_theme.dart';
import '../utils/mock_tree_data.dart';
import 'tree_map_screen.dart';

class PredictionDetailScreen extends StatefulWidget {
  final Prediction prediction;

  const PredictionDetailScreen({super.key, required this.prediction});

  @override
  State<PredictionDetailScreen> createState() => _PredictionDetailScreenState();
}

class _PredictionDetailScreenState extends State<PredictionDetailScreen> {
  final FarmService _farmService = FarmService();
  bool _isNavigating = false;

  Prediction get p => widget.prediction;

  // ── Navigate to Tree Map ──────────────────────────────────────────────────

  // Returns the matched farm or null. Sets _noFarmReason if not found.
  String? _noFarmReason;

  Future<void> _viewOnTreeMap() async {
    // Only Liberica results can navigate to a farm
    if (!p.isLiberica) return;

    if (!p.hasCoordinates) {
      _showSnack('No GPS coordinates in this prediction.', isError: true);
      return;
    }

    setState(() {
      _isNavigating = true;
      _noFarmReason = null;
    });

    final lat = p.latitude!;
    final lng = p.longitude!;
    final coords = LatLng(lat, lng);

    // 1. Try exact match first, then nearest within 50m
    final result = MockTreeData.findByCoordinates(lat, lng) ??
        MockTreeData.findNearest(lat, lng, thresholdMeters: 50);

    Farm? targetFarm;

    try {
      final farms = await _farmService.getAllFarms();
      if (result != null) {
        // Found a nearby tree — navigate to its farm
        try {
          targetFarm = farms.firstWhere((f) => f.id == result.tree.farmId);
        } catch (_) {
          targetFarm = _buildMockFarm(result);
        }
      }
      // No tree match within threshold — no farm found
    } catch (_) {
      if (result != null) targetFarm = _buildMockFarm(result);
    }

    setState(() => _isNavigating = false);
    if (!mounted) return;

    if (targetFarm == null) {
      // GPS is valid but no farm found nearby — show warning on map
      setState(() => _noFarmReason =
          'No registered farm found near this GPS location.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreeMapScreen(farm: targetFarm!, highlightCoords: coords),
      ),
    );
  }

  Farm _buildMockFarm(TreeLocationResult result) {
    return Farm(
      mongoId:          '',
      id:               result.tree.farmId,
      ownerId:          0,
      name:             result.farmName,
      cityId:           0,
      cityName:         result.farmLocation,
      barangayName:     '',
      latitude:         result.tree.latitude,
      longitude:        result.tree.longitude,
      totalTrees:       0,
      dnaVerifiedCount: 0,
      hasDnaVerified:   false,
      boundary:         const [],
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLiberica = p.isLiberica;
    final resultColor = isLiberica ? AppTheme.dnaVerifiedColor : Colors.red.shade600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: resultColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                p.finalPrediction,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      resultColor,
                      resultColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      isLiberica
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Result badge ───────────────────────────────────────
                  _buildResultBadge(isLiberica, resultColor),
                  const SizedBox(height: 20),

                  // ── Confidence card ────────────────────────────────────
                  _buildSectionTitle('Classification Result'),
                  const SizedBox(height: 10),
                  _buildConfidenceCard(resultColor),
                  const SizedBox(height: 20),

                  // ── Individual predictions ─────────────────────────────
                  if (p.individualPredictions.isNotEmpty) ...[
                    _buildSectionTitle('Individual Predictions'),
                    const SizedBox(height: 10),
                    _buildIndividualPredictions(),
                    const SizedBox(height: 20),
                  ],

                  // ── GradCAM image ──────────────────────────────────────
                  if (p.hasGradCam) ...[
                    _buildSectionTitle('GradCAM Heatmap'),
                    const SizedBox(height: 10),
                    _buildGradCamImage(),
                    const SizedBox(height: 20),
                  ],

                  // ── GPS & Mini Map ─────────────────────────────────────
                  _buildSectionTitle('GPS Location'),
                  const SizedBox(height: 10),
                  _buildGpsCard(resultColor),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result badge ───────────────────────────────────────────────────────────

  Widget _buildResultBadge(bool isLiberica, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isLiberica ? Icons.eco_rounded : Icons.block_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLiberica ? 'Coffea Liberica Detected' : 'Not Coffea Liberica',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '${p.modeLabel}  •  ${p.confidenceLabel} confidence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Confidence card ────────────────────────────────────────────────────────

  Widget _buildConfidenceCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confidence Score',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              Text(
                p.confidenceLabel,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p.confidenceRatio / 100,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailChip(
                  Icons.category_rounded, 'Plant Part', p.modeLabel),
              _buildDetailChip(
                  Icons.biotech_rounded, 'Analysis', 'MobileNetV2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textLight)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  // ── Individual predictions ─────────────────────────────────────────────────

  Widget _buildIndividualPredictions() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: p.individualPredictions.entries.map((entry) {
          final key = entry.key;
          final val = entry.value;
          final isLib = val.prediction.toLowerCase() == 'liberica';
          final barColor = isLib ? AppTheme.dnaVerifiedColor : Colors.red.shade400;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _partLabel(key),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                    Row(
                      children: [
                        Text(
                          val.prediction,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: barColor),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${val.confidence.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: val.confidence / 100,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _partLabel(String key) {
    switch (key) {
      case 'leaf':   return '🍃 Leaf';
      case 'bark':   return '🪵 Bark';
      case 'cherry': return '🍒 Cherry';
      default:       return key;
    }
  }

  // ── GradCAM image ──────────────────────────────────────────────────────────

  Widget _buildGradCamImage() {
    try {
      final base64Str = p.gradCamImage!.contains(',')
          ? p.gradCamImage!.split(',')[1]
          : p.gradCamImage!;
      final Uint8List bytes = base64Decode(base64Str);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  // ── GPS card + mini map ────────────────────────────────────────────────────

  Widget _buildGpsCard(Color resultColor) {
    // ── Not Liberica ─────────────────────────────────────────────────────────
    if (!p.isLiberica) {
      return Column(
        children: [
          if (p.hasCoordinates) ...[
            // Show coords and mini map but with a "not registered" notice
            Row(
              children: [
                Expanded(child: _buildCoordChip('Latitude', p.latitude!.toStringAsFixed(6))),
                const SizedBox(width: 10),
                Expanded(child: _buildCoordChip('Longitude', p.longitude!.toStringAsFixed(6))),
              ],
            ),
            const SizedBox(height: 12),
            _buildMiniMap(LatLng(p.latitude!, p.longitude!), resultColor),
            const SizedBox(height: 12),
          ],
          _buildNoFarmBanner(
            icon: Icons.block_rounded,
            color: Colors.red.shade600,
            title: 'Not a Liberica Sample',
            subtitle: 'This sample was not identified as Coffea Liberica. '
                'It cannot be linked to a registered farm.',
          ),
        ],
      );
    }

    // ── Liberica but no GPS coords ───────────────────────────────────────────
    if (!p.hasCoordinates) {
      return _buildNoFarmBanner(
        icon: Icons.location_off_rounded,
        color: Colors.orange.shade700,
        title: 'No GPS Coordinates',
        subtitle: 'No location was recorded for this classification.',
      );
    }

    final coords = LatLng(p.latitude!, p.longitude!);

    // ── Liberica with GPS ────────────────────────────────────────────────────
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCoordChip('Latitude', p.latitude!.toStringAsFixed(6))),
            const SizedBox(width: 10),
            Expanded(child: _buildCoordChip('Longitude', p.longitude!.toStringAsFixed(6))),
          ],
        ),
        const SizedBox(height: 12),
        _buildMiniMap(coords, resultColor),
        const SizedBox(height: 12),

        // No farm warning (shown after failed navigation attempt)
        if (_noFarmReason != null) ...[
          _buildNoFarmBanner(
            icon: Icons.location_searching_rounded,
            color: Colors.orange.shade700,
            title: 'No Farm Found Nearby',
            subtitle: _noFarmReason!,
          ),
          const SizedBox(height: 12),
        ],

        // View on Tree Map button — only for Liberica
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isNavigating ? null : _viewOnTreeMap,
            icon: _isNavigating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.map_rounded, size: 18),
            label: Text(
              _isNavigating ? 'Searching...' : 'View on Tree Map',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMap(LatLng coords, Color markerColor) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: coords,
            initialZoom: 17,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.liberica.map',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: coords,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      p.isLiberica ? Icons.eco_rounded : Icons.block_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFarmBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textLight)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFamily: 'Courier',
              )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}