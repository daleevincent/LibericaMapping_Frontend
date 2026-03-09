// lib/screens/main_dashboard.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';
import '../utils/app_theme.dart';
import '../widgets/farm_search_bar.dart';
import '../widgets/farm_marker.dart';
import 'tree_map_screen.dart' hide AppConstants;

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  GoogleMapController? _mapController;
  final FarmService _farmService = FarmService();

  List<Farm> _farms = [];
  Farm? _selectedFarm;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _showFarmCard = false;

  static const CameraPosition _batangasCenter = CameraPosition(
    target: LatLng(AppConstants.batangasCenterLat, AppConstants.batangasCenterLng),
    zoom: AppConstants.defaultZoom,
  );

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    final farms = await _farmService.getAllFarms();
    setState(() {
      _farms = farms;
      _isLoading = false;
    });
    _buildMarkers();
  }

  void _buildMarkers() {
    final markers = _farms.map((farm) {
      return Marker(
        markerId: MarkerId(farm.id),
        position: LatLng(farm.latitude, farm.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: farm.name,
          snippet: '${farm.libericaTrees} trees | ${farm.dnaVerifiedTrees} DNA verified',
        ),
        onTap: () => _onFarmTapped(farm),
      );
    }).toSet();

    setState(() => _markers = markers);
  }

  void _onFarmTapped(Farm farm) {
    setState(() {
      _selectedFarm = farm;
      _showFarmCard = true;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(farm.latitude, farm.longitude),
          zoom: AppConstants.farmZoom,
        ),
      ),
    );
  }

  void _onFarmSelected(Farm? farm) {
    if (farm == null) {
      setState(() {
        _selectedFarm = null;
        _showFarmCard = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_batangasCenter),
      );
    } else {
      _onFarmTapped(farm);
    }
  }

  void _viewTreeMap(Farm farm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreeMapScreen(farm: farm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: _batangasCenter,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) {
              if (_showFarmCard) {
                setState(() => _showFarmCard = false);
              }
            },
          ),

          // Loading
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading farms...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // Top Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // App Title strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Geo-mapping of Coffee Liberica Farms – Batangas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Search Bar
                  FarmSearchBar(
                    farms: _farms,
                    selectedFarm: _selectedFarm,
                    onFarmSelected: _onFarmSelected,
                  ),
                ],
              ),
            ),
          ),

          // Farm Count Badge
          Positioned(
            top: 130,
            right: 16,
            child: SafeArea(
              child: Column(
                children: [
                  _buildMapControl(Icons.my_location, () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(_batangasCenter),
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.add, () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  }),
                  const SizedBox(height: 4),
                  _buildMapControl(Icons.remove, () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  }),
                ],
              ),
            ),
          ),

          // Farm info card at bottom
          if (_showFarmCard && _selectedFarm != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _showFarmCard ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _showFarmCard ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: FarmInfoCard(
                    farm: _selectedFarm!,
                    onViewTrees: () => _viewTreeMap(_selectedFarm!),
                    onClose: () => setState(() => _showFarmCard = false),
                  ),
                ),
              ),
            ),

          // Farm count indicator
          if (!_showFarmCard)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_farms.length} farms in Batangas • Tap a pin to explore',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
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
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }
}