// lib/screens/tree_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/farm.dart';
import '../models/tree.dart';
import '../services/tree_service.dart';
import '../utils/app_theme.dart';

class TreeMapScreen extends StatefulWidget {
  final Farm farm;

  const TreeMapScreen({super.key, required this.farm});

  @override
  State<TreeMapScreen> createState() => _TreeMapScreenState();
}

class _TreeMapScreenState extends State<TreeMapScreen> {
  final TreeService _treeService = TreeService();
  final MapController _mapController = MapController();

  List<CoffeeTree> _trees = [];
  CoffeeTree? _selectedTree;
  bool _isLoading = true;
  bool _showDnaOnly = false;
  bool _showNonDnaOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  Future<void> _loadTrees() async {
    final trees = await _treeService.getTreesForFarm(widget.farm.id);
    setState(() {
      _trees = trees;
      _isLoading = false;
    });
  }

  List<CoffeeTree> get _filteredTrees {
    if (_showDnaOnly) return _trees.where((t) => t.isDnaVerified).toList();
    if (_showNonDnaOnly) return _trees.where((t) => !t.isDnaVerified).toList();
    return _trees;
  }

  @override
  Widget build(BuildContext context) {
    final farm = widget.farm;

    return Scaffold(
      body: Stack(
        children: [
          // flutter_map (Leaflet-style)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(farm.latitude, farm.longitude),
              initialZoom: AppConstants.treeZoom,
              onTap: (_, _) => setState(() => _selectedTree = null),
            ),
            children: [
              // Base tile layer (OpenStreetMap)
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.liberica.map',
              ),

              // Farm polygon boundary
              if (farm.polygonCoordinates.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: farm.polygonCoordinates,
                      color: AppTheme.polygonFill,
                      borderColor: AppTheme.polygonBorder,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),

              // Tree circle markers
              if (!_isLoading)
                CircleLayer(
                  circles: _filteredTrees.map((tree) {
                    final isSelected = _selectedTree?.treeId == tree.treeId;
                    final color = tree.isDnaVerified
                        ? AppTheme.dnaVerifiedColor
                        : AppTheme.nonVerifiedColor;

                    return CircleMarker(
                      point: LatLng(tree.latitude, tree.longitude),
                      radius: isSelected ? 14 : 10,
                      color: color.withValues(alpha: isSelected ? 0.9 : 0.7),
                      borderColor: isSelected ? Colors.white : color,
                      borderStrokeWidth: isSelected ? 3 : 1.5,
                      useRadiusInMeter: false,
                    );
                  }).toList(),
                ),

              // Tappable markers overlay
              if (!_isLoading)
                MarkerLayer(
                  markers: _filteredTrees.map((tree) {
                    return Marker(
                      point: LatLng(tree.latitude, tree.longitude),
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedTree =
                              _selectedTree?.treeId == tree.treeId
                                  ? null
                                  : tree;
                        }),
                        child: Container(color: Colors.transparent),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + Title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.farm.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${_filteredTrees.length} trees displayed',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All Trees',
                          !_showDnaOnly && !_showNonDnaOnly,
                          () => setState(() {
                            _showDnaOnly = false;
                            _showNonDnaOnly = false;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '🧬 DNA Verified',
                          _showDnaOnly,
                          () => setState(() {
                            _showDnaOnly = !_showDnaOnly;
                            _showNonDnaOnly = false;
                          }),
                          color: AppTheme.dnaVerifiedColor,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '🌿 Non-Verified',
                          _showNonDnaOnly,
                          () => setState(() {
                            _showNonDnaOnly = !_showNonDnaOnly;
                            _showDnaOnly = false;
                          }),
                          color: AppTheme.nonVerifiedColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            top: 160,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem('DNA Verified', AppTheme.dnaVerifiedColor),
                    const SizedBox(height: 4),
                    _buildLegendItem('Non-Verified', AppTheme.nonVerifiedColor),
                    const SizedBox(height: 4),
                    _buildLegendItem('Farm Boundary', AppTheme.polygonBorder,
                        isPolygon: true),
                  ],
                ),
              ),
            ),
          ),

          // Selected tree popup
          if (_selectedTree != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildTreePopup(_selectedTree!),
            ),

          // Bottom stats bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Row(
                children: [
                  _buildBottomStat(
                    'Total Trees',
                    '${_trees.length}',
                    Icons.park_rounded,
                    AppTheme.primary,
                  ),
                  _buildBottomStat(
                    'DNA Verified',
                    '${_trees.where((t) => t.isDnaVerified).length}',
                    Icons.biotech_rounded,
                    AppTheme.dnaVerifiedColor,
                  ),
                  _buildBottomStat(
                    'Non-Verified',
                    '${_trees.where((t) => !t.isDnaVerified).length}',
                    Icons.eco_rounded,
                    AppTheme.nonVerifiedColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (color ?? AppTheme.primary) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color,
      {bool isPolygon = false}) {
    return Row(
      children: [
        isPolygon
            ? Container(
                width: 16,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTreePopup(CoffeeTree tree) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tree.isDnaVerified
                  ? AppTheme.dnaVerifiedColor.withValues(alpha: 0.12)
                  : AppTheme.nonVerifiedColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tree.isDnaVerified ? Icons.biotech_rounded : Icons.eco_rounded,
              color: tree.isDnaVerified
                  ? AppTheme.dnaVerifiedColor
                  : AppTheme.nonVerifiedColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tree.treeId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tree.latitude.toStringAsFixed(6)}, ${tree.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tree.isDnaVerified
                        ? AppTheme.dnaVerifiedColor.withValues(alpha: 0.12)
                        : AppTheme.nonVerifiedColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tree.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tree.isDnaVerified
                          ? AppTheme.dnaVerifiedColor
                          : AppTheme.nonVerifiedColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedTree = null),
            child: const Icon(Icons.close, color: AppTheme.textLight, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// Expose AppConstants here since it's needed in this file
class AppConstants {
  static const double treeZoom = 17.0;
}