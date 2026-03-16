// lib/screens/manage_farm_screen.dart
//
// Full manage farm screen:
//   1. Farm selector dropdown
//   2. Editable: Farm Info, Location, Coordinates, Boundary
//   3. Tree list table with DNA verified checkboxes
//   4. Save / Cancel buttons

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/farm.dart';
import '../models/tree.dart';
import '../services/farm_service.dart';
import '../services/tree_service.dart';
import '../utils/app_theme.dart';

class ManageFarmScreen extends StatefulWidget {
  final List<Farm> farms;

  const ManageFarmScreen({super.key, required this.farms});

  @override
  State<ManageFarmScreen> createState() => _ManageFarmScreenState();
}

class _ManageFarmScreenState extends State<ManageFarmScreen> {
  final FarmService _farmService = FarmService();
  final TreeService _treeService = TreeService();
  final _formKey = GlobalKey<FormState>();

  // ── Farm selector ─────────────────────────────────────────────────────────
  Farm? _selectedFarm;
  bool _isLoadingTrees = false;
  bool _isSaving = false;

  // ── Form controllers ──────────────────────────────────────────────────────
  final _nameCtrl      = TextEditingController();
  final _ownerIdCtrl   = TextEditingController();
  final _cityIdCtrl    = TextEditingController();
  final _cityNameCtrl  = TextEditingController();
  final _barangayCtrl  = TextEditingController();
  final _latCtrl       = TextEditingController();
  final _lngCtrl       = TextEditingController();

  // ── Boundary ──────────────────────────────────────────────────────────────
  List<Map<String, TextEditingController>> _boundaryPoints = [];

  // ── Trees ─────────────────────────────────────────────────────────────────
  List<CoffeeTree> _trees = [];
  // Track DNA verified state per tree: treeId → bool
  Map<String, bool> _dnaState = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerIdCtrl.dispose();
    _cityIdCtrl.dispose();
    _cityNameCtrl.dispose();
    _barangayCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _disposeBoundary();
    super.dispose();
  }

  void _disposeBoundary() {
    for (final p in _boundaryPoints) {
      p['lat']!.dispose();
      p['lng']!.dispose();
    }
  }

  // ── Load farm into form ───────────────────────────────────────────────────

  Future<void> _onFarmSelected(Farm? farm) async {
    if (farm == null) return;

    // Dispose old boundary controllers
    _disposeBoundary();

    setState(() {
      _selectedFarm = farm;
      _nameCtrl.text     = farm.name;
      _ownerIdCtrl.text  = farm.ownerId.toString();
      _cityIdCtrl.text   = farm.cityId.toString();
      _cityNameCtrl.text = farm.cityName;
      _barangayCtrl.text = farm.barangayName;
      _latCtrl.text      = farm.latitude.toString();
      _lngCtrl.text      = farm.longitude.toString();

      // Rebuild boundary controllers
      _boundaryPoints = farm.boundary.map((p) => {
        'lat': TextEditingController(text: p.latitude.toString()),
        'lng': TextEditingController(text: p.longitude.toString()),
      }).toList();

      _trees = [];
      _dnaState = {};
      _isLoadingTrees = true;
    });

    // Load trees for this farm
    try {
      final trees = await _treeService.getTreesByFarm(farm.id);
      setState(() {
        _trees = trees;
        _dnaState = { for (final t in trees) t.treeId: t.isDnaVerified };
        _isLoadingTrees = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrees = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load trees: $e'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  // ── Boundary management ───────────────────────────────────────────────────

  void _addBoundaryPoint() {
    setState(() {
      _boundaryPoints.add({
        'lat': TextEditingController(),
        'lng': TextEditingController(),
      });
    });
  }

  void _removeBoundaryPoint(int index) {
    setState(() {
      _boundaryPoints[index]['lat']!.dispose();
      _boundaryPoints[index]['lng']!.dispose();
      _boundaryPoints.removeAt(index);
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_selectedFarm == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Build updated boundary
      final boundary = <LatLng>[];
      for (final p in _boundaryPoints) {
        final lat = double.tryParse(p['lat']!.text.trim());
        final lng = double.tryParse(p['lng']!.text.trim());
        if (lat != null && lng != null) boundary.add(LatLng(lat, lng));
      }

      // Build updated farm
      final updatedFarm = _selectedFarm!.copyWith(
        name:         _nameCtrl.text.trim(),
        ownerId:      int.tryParse(_ownerIdCtrl.text.trim()) ?? _selectedFarm!.ownerId,
        cityId:       int.tryParse(_cityIdCtrl.text.trim()) ?? _selectedFarm!.cityId,
        cityName:     _cityNameCtrl.text.trim(),
        barangayName: _barangayCtrl.text.trim(),
        latitude:     double.tryParse(_latCtrl.text.trim()) ?? _selectedFarm!.latitude,
        longitude:    double.tryParse(_lngCtrl.text.trim()) ?? _selectedFarm!.longitude,
        boundary:     boundary,
        // Recount from current DNA state
        dnaVerifiedCount: _dnaState.values.where((v) => v).length,
        hasDnaVerified:   _dnaState.values.any((v) => v),
      );

      await _farmService.updateFarm(updatedFarm);

      // Update DNA verified status for each tree that changed
      for (final tree in _trees) {
        final newDna = _dnaState[tree.treeId] ?? tree.isDnaVerified;
        if (newDna != tree.isDnaVerified) {
          // Uncomment when backend tree PATCH/PUT route is ready:
          // await _treeService.updateTreeDna(tree.mongoId, newDna);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${updatedFarm.name} updated successfully!'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _cancel() => Navigator.pop(context);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Farm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Select a farm to edit',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Farm selector ─────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildFarmDropdown(),
            ),

            // ── Form body ─────────────────────────────────────────────────
            Expanded(
              child: _selectedFarm == null
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection('Farm Information',
                              Icons.eco_rounded, _buildFarmInfoFields()),
                          const SizedBox(height: 16),
                          _buildSection('Location',
                              Icons.location_on_rounded, _buildLocationFields()),
                          const SizedBox(height: 16),
                          _buildSection('Farm Coordinates',
                              Icons.gps_fixed, _buildCoordinateFields()),
                          const SizedBox(height: 16),
                          _buildSection('Farm Boundary',
                              Icons.crop_free_rounded, _buildBoundaryFields()),
                          const SizedBox(height: 16),
                          _buildSection('Tree List',
                              Icons.park_rounded, _buildTreeTable()),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),

            // ── Save / Cancel buttons ─────────────────────────────────────
            if (_selectedFarm != null)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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

  // ── Farm dropdown ─────────────────────────────────────────────────────────

  Widget _buildFarmDropdown() {
    return DropdownButtonFormField<Farm>(
      initialValue: _selectedFarm,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Choose Farm to Manage',
        labelStyle:
            const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.eco_rounded,
            color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      hint: const Text('Select a farm...', style: TextStyle(fontSize: 13)),
      items: widget.farms.map((farm) {
        return DropdownMenuItem<Farm>(
          value: farm,
          child: Text(
            '${farm.name} · ${farm.location}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onFarmSelected,
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded,
              size: 64, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Select a farm above to start editing',
              style:
                  TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ── Field groups ──────────────────────────────────────────────────────────

  Widget _buildFarmInfoFields() {
    return Column(
      children: [
        _buildField(_nameCtrl, 'Farm Name', required: true),
        const SizedBox(height: 12),
        _buildField(_ownerIdCtrl, 'Owner ID',
            keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildField(_cityIdCtrl, 'City ID',
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_cityNameCtrl, 'City Name')),
          ],
        ),
        const SizedBox(height: 12),
        _buildField(_barangayCtrl, 'Barangay Name', required: true),
      ],
    );
  }

  Widget _buildCoordinateFields() {
    return Row(
      children: [
        Expanded(
          child: _buildField(_latCtrl, 'Latitude',
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              required: true),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildField(_lngCtrl, 'Longitude',
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              required: true),
        ),
      ],
    );
  }

  Widget _buildBoundaryFields() {
    return Column(
      children: [
        if (_boundaryPoints.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.textLight),
                SizedBox(width: 6),
                Text('No boundary points',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
        for (int i = 0; i < _boundaryPoints.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(_boundaryPoints[i]['lat']!, 'Lat',
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                signed: true, decimal: true))),
                const SizedBox(width: 6),
                Expanded(
                    child: _buildField(_boundaryPoints[i]['lng']!, 'Lng',
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                signed: true, decimal: true))),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _removeBoundaryPoint(i),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 16),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addBoundaryPoint,
            icon: const Icon(Icons.add_location_alt_rounded, size: 16),
            label: const Text('Add Boundary Point'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Tree table ────────────────────────────────────────────────────────────

  Widget _buildTreeTable() {
    if (_isLoadingTrees) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_trees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: AppTheme.textLight),
            SizedBox(width: 8),
            Text('No trees found for this farm',
                style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Row(
          children: [
            _buildTreeChip(
                '${_trees.length} Total', AppTheme.primary),
            const SizedBox(width: 8),
            _buildTreeChip(
                '${_dnaState.values.where((v) => v).length} Verified',
                AppTheme.dnaVerifiedColor),
            const SizedBox(width: 8),
            _buildTreeChip(
                '${_dnaState.values.where((v) => !v).length} Unverified',
                AppTheme.nonVerifiedColor),
          ],
        ),
        const SizedBox(height: 12),

        // Table header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 42,
                child: Text('DNA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ),
              Expanded(
                child: Text('Tree ID',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ),
              Expanded(
                child: Text('Latitude',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ),
              Expanded(
                child: Text('Longitude',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),

        // Tree rows
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trees.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final tree = _trees[index];
              final isDna = _dnaState[tree.treeId] ?? tree.isDnaVerified;
              return InkWell(
                onTap: () => setState(
                    () => _dnaState[tree.treeId] = !isDna),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Transform.scale(
                          scale: 0.85,
                          child: Checkbox(
                            value: isDna,
                            onChanged: (v) => setState(
                                () => _dnaState[tree.treeId] = v ?? false),
                            activeColor: AppTheme.dnaVerifiedColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(tree.treeId,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ),
                      Expanded(
                        child: Text(
                            tree.latitude.toStringAsFixed(5),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ),
                      Expanded(
                        child: Text(
                            tree.longitude.toStringAsFixed(5),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTreeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 17),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  // ── Text field helper ─────────────────────────────────────────────────────

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}