// lib/screens/farms_directory_screen.dart

import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';
import '../utils/app_theme.dart';
import 'tree_map_screen.dart';

class FarmsDirectoryScreen extends StatefulWidget {
  const FarmsDirectoryScreen({super.key});

  @override
  State<FarmsDirectoryScreen> createState() => _FarmsDirectoryScreenState();
}

class _FarmsDirectoryScreenState extends State<FarmsDirectoryScreen> {
  final FarmService _farmService = FarmService();
  final TextEditingController _searchController = TextEditingController();

  List<Farm> _farms = [];
  List<Farm> _filteredFarms = [];
  bool _isLoading = true;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    final farms = await _farmService.getAllFarms();
    setState(() {
      _farms = farms;
      _filteredFarms = farms;
      _isLoading = false;
    });
  }

  void _filterFarms(String query) {
    setState(() {
      _filteredFarms = _farms
          .where((f) =>
              f.name.toLowerCase().contains(query.toLowerCase()) ||
              f.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
    _sortFarms();
  }

  void _sortFarms() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredFarms.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'trees':
          _filteredFarms.sort((a, b) => b.libericaTrees.compareTo(a.libericaTrees));
          break;
        case 'verified':
          _filteredFarms.sort(
              (a, b) => b.dnaVerifiedTrees.compareTo(a.dnaVerifiedTrees));
          break;
        case 'size':
          _filteredFarms.sort((a, b) => b.fieldSize.compareTo(a.fieldSize));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.list_alt_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farms Directory',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'All registered Liberica farms',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterFarms,
                  decoration: const InputDecoration(
                    hintText: 'Search farms...',
                    hintStyle: TextStyle(color: AppTheme.textLight),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textLight),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sort options
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Sort by: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...[
                    ('name', 'Name'),
                    ('trees', 'Trees'),
                    ('verified', 'Verified'),
                    ('size', 'Size'),
                  ].map(
                    (s) => GestureDetector(
                      onTap: () {
                        setState(() => _sortBy = s.$1);
                        _sortFarms();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _sortBy == s.$1
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          s.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _sortBy == s.$1
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_filteredFarms.length} farm${_filteredFarms.length != 1 ? 's' : ''} found',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textLight,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Farm list
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _filteredFarms.length,
                  itemBuilder: (context, index) {
                    final farm = _filteredFarms[index];
                    return _buildFarmCard(farm);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmCard(Farm farm) {
    final rate = farm.libericaTrees > 0
        ? (farm.dnaVerifiedTrees / farm.libericaTrees * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: AppTheme.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 13, color: AppTheme.textLight),
                          const SizedBox(width: 2),
                          Text(
                            farm.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade100),

          // Stats row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildMiniStat(
                    '${farm.fieldSize} ha', 'Field Size', AppTheme.accent),
                _buildDivider(),
                _buildMiniStat('${farm.libericaTrees}', 'Liberica Trees',
                    AppTheme.nonVerifiedColor),
                _buildDivider(),
                _buildMiniStat('${farm.dnaVerifiedTrees}', 'DNA Verified',
                    AppTheme.dnaVerifiedColor),
                _buildDivider(),
                _buildMiniStat('${rate.toStringAsFixed(0)}%', 'Rate',
                    rate >= 70 ? AppTheme.dnaVerifiedColor : AppTheme.accent),
              ],
            ),
          ),

          // View trees button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TreeMapScreen(farm: farm),
                    ),
                  );
                },
                icon: const Icon(Icons.forest_rounded, size: 16),
                label: const Text('View Tree Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.grey.shade200,
    );
  }
}