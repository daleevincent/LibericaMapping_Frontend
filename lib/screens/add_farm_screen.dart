// lib/screens/add_farm_screen.dart
//
// Full-screen form to add a new farm.
// Fields match the MongoDB farm document schema exactly.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';
import '../utils/app_theme.dart';

class AddFarmScreen extends StatefulWidget {
  const AddFarmScreen({super.key});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final FarmService _farmService = FarmService();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  List<Farm> _existingFarms = [];

  // ── Duplicate warning state ───────────────────────────────────────────────
  Farm? _duplicateFarm; // non-null = duplicate detected

  // ── Form controllers ──────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _ownerIdCtrl     = TextEditingController();
  final _cityIdCtrl      = TextEditingController();
  final _cityNameCtrl    = TextEditingController();
  final _barangayCtrl    = TextEditingController();
  final _latCtrl         = TextEditingController();
  final _lngCtrl         = TextEditingController();
  final _totalTreesCtrl  = TextEditingController(text: '0');
  final _dnaCountCtrl    = TextEditingController(text: '0');
  bool _hasDnaVerified   = false;

  // ── Boundary points ───────────────────────────────────────────────────────
  final List<Map<String, TextEditingController>> _boundaryPoints = [];

  @override
  void initState() {
    super.initState();
    _loadExistingFarms();
    _nameCtrl.addListener(_checkDuplicate);
    _cityIdCtrl.addListener(_checkDuplicate);
    _latCtrl.addListener(_checkDuplicate);
    _lngCtrl.addListener(_checkDuplicate);
  }

  Future<void> _loadExistingFarms() async {
    try {
      final farms = await _farmService.getAllFarms();
      setState(() => _existingFarms = farms);
    } catch (_) {}
  }

  void _checkDuplicate() {
    final name   = _nameCtrl.text.trim().toLowerCase();
    final cityId = int.tryParse(_cityIdCtrl.text.trim());
    final lat    = double.tryParse(_latCtrl.text.trim());
    final lng    = double.tryParse(_lngCtrl.text.trim());

    if (name.isEmpty || cityId == null || lat == null || lng == null) {
      if (_duplicateFarm != null) setState(() => _duplicateFarm = null);
      return;
    }

    Farm? found;
    for (final farm in _existingFarms) {
      final sameName   = farm.name.trim().toLowerCase() == name;
      final sameCityId = farm.cityId == cityId;
      final sameLat    = (farm.latitude  - lat).abs() < 0.00001;
      final sameLng    = (farm.longitude - lng).abs() < 0.00001;
      if (sameName && sameCityId && sameLat && sameLng) {
        found = farm;
        break;
      }
    }

    if (found != _duplicateFarm) setState(() => _duplicateFarm = found);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerIdCtrl.dispose();
    _cityIdCtrl.dispose();
    _cityNameCtrl.dispose();
    _barangayCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _totalTreesCtrl.dispose();
    _dnaCountCtrl.dispose();
    for (final p in _boundaryPoints) {
      p['lat']!.dispose();
      p['lng']!.dispose();
    }
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    // Block save if duplicate detected
    if (_duplicateFarm != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '⚠️ A farm with the same details already exists. Please review the warning above.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build boundary list
      final boundary = <LatLng>[];
      for (final point in _boundaryPoints) {
        final lat = double.tryParse(point['lat']!.text.trim());
        final lng = double.tryParse(point['lng']!.text.trim());
        if (lat != null && lng != null) {
          boundary.add(LatLng(lat, lng));
        }
      }

      final farm = Farm(
        mongoId:          '',
        id:               int.tryParse(_ownerIdCtrl.text.trim()) ?? 0,
        ownerId:          int.tryParse(_ownerIdCtrl.text.trim()) ?? 0,
        name:             _nameCtrl.text.trim(),
        cityId:           int.tryParse(_cityIdCtrl.text.trim()) ?? 0,
        cityName:         _cityNameCtrl.text.trim(),
        barangayName:     _barangayCtrl.text.trim(),
        latitude:         double.parse(_latCtrl.text.trim()),
        longitude:        double.parse(_lngCtrl.text.trim()),
        totalTrees:       int.tryParse(_totalTreesCtrl.text.trim()) ?? 0,
        dnaVerifiedCount: int.tryParse(_dnaCountCtrl.text.trim()) ?? 0,
        hasDnaVerified:   _hasDnaVerified,
        boundary:         boundary,
      );

      await _farmService.addFarm(farm);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${farm.name} added successfully!'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // return true = refresh list
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add farm: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

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
            Text('Add New Farm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Fill in all farm details',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Farm Info ─────────────────────────────────────────────────
              _buildSection('Farm Information', Icons.eco_rounded, [
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Farm Name',
                  hint: 'e.g. Reyes Coffee Farm',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Farm name is required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _ownerIdCtrl,
                  label: 'Owner ID',
                  hint: 'e.g. 1',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Owner ID is required' : null,
                ),
              ]),

              const SizedBox(height: 16),

              // ── Location ──────────────────────────────────────────────────
              _buildSection('Location', Icons.location_on_rounded, [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityIdCtrl,
                        label: 'City ID',
                        hint: 'e.g. 41014070',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityNameCtrl,
                        label: 'City Name',
                        hint: 'e.g. Lipa City',
                        validator: (v) => v == null || v.isEmpty
                            ? 'City name is required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _barangayCtrl,
                  label: 'Barangay Name',
                  hint: 'e.g. Tangob',
                  validator: (v) => v == null || v.isEmpty
                      ? 'Barangay name is required'
                      : null,
                ),
              ]),

              const SizedBox(height: 16),

              // ── Coordinates ───────────────────────────────────────────────
              _buildSection('Farm Coordinates', Icons.gps_fixed, [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _latCtrl,
                        label: 'Latitude',
                        hint: 'e.g. 13.9288',
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lngCtrl,
                        label: 'Longitude',
                        hint: 'e.g. 121.1998',
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 16),

              // ── Tree counts ───────────────────────────────────────────────
              _buildSection('Tree Data', Icons.park_rounded, [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _totalTreesCtrl,
                        label: 'Total Trees',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _dnaCountCtrl,
                        label: 'DNA Verified Count',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      setState(() => _hasDnaVerified = !_hasDnaVerified),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hasDnaVerified
                          ? AppTheme.dnaVerifiedColor.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasDnaVerified
                            ? AppTheme.dnaVerifiedColor.withValues(alpha: 0.4)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hasDnaVerified
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _hasDnaVerified
                              ? AppTheme.dnaVerifiedColor
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _hasDnaVerified
                              ? 'Has DNA Verified Trees'
                              : 'No DNA Verified Trees',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _hasDnaVerified
                                ? AppTheme.dnaVerifiedColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Boundary ──────────────────────────────────────────────────
              _buildSection('Farm Boundary', Icons.crop_free_rounded, [
                if (_boundaryPoints.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.textLight),
                        SizedBox(width: 8),
                        Text(
                          'No boundary points added yet',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                for (int i = 0; i < _boundaryPoints.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _boundaryPoints[i]['lat']!,
                            label: 'Lat',
                            hint: '13.9288',
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: _boundaryPoints[i]['lng']!,
                            label: 'Lng',
                            hint: '121.1998',
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeBoundaryPoint(i),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
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
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('Add Boundary Point'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Duplicate warning ─────────────────────────────────────────
              if (_duplicateFarm != null) _buildDuplicateWarning(_duplicateFarm!),

              const SizedBox(height: 24),

              // ── Save button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || _duplicateFarm != null) ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _duplicateFarm != null
                              ? Icons.block_rounded
                              : Icons.save_rounded,
                          size: 20),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _duplicateFarm != null
                            ? 'Duplicate — Cannot Save'
                            : 'Save Farm',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _duplicateFarm != null
                        ? Colors.orange.shade300
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Duplicate warning card ────────────────────────────────────────────────

  Widget _buildDuplicateWarning(Farm farm) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Duplicate Farm Detected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A farm with the same name, city, and coordinates already exists in the database:',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDuplicateRow(Icons.eco_rounded, 'Name', farm.name),
                _buildDuplicateRow(Icons.location_city_rounded, 'City', '${farm.cityName} (ID: ${farm.cityId})'),
                _buildDuplicateRow(Icons.place_rounded, 'Barangay', farm.barangayName),
                _buildDuplicateRow(Icons.gps_fixed, 'Coordinates',
                    '${farm.latitude.toStringAsFixed(5)}, ${farm.longitude.toStringAsFixed(5)}'),
                _buildDuplicateRow(Icons.park_rounded, 'Trees',
                    '${farm.totalTrees} total · ${farm.dnaVerifiedCount} DNA verified'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Saving is disabled until you change the conflicting fields.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.orange.shade400),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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