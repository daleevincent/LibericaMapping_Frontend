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
import 'package:image_picker/image_picker.dart';
import '../models/prediction.dart';
import '../services/prediction_service.dart';
import '../utils/app_theme.dart';

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
  final ImagePicker _picker = ImagePicker();

  late TabController _tabController;

  // ── Classify tab state ───────────────────────────────────────────────────
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes; // used for preview + upload on web
  String _plantPartMode = 'leaf';
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isClassifying = false;
  Prediction? _result;

  // ── History tab state ────────────────────────────────────────────────────
  List<Prediction> _history = [];
  bool _isLoadingHistory = true;
  String _historyFilter = 'all'; // all | leaf | bark | cherry | mix

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

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageFile  = picked;
        _selectedImageBytes = bytes;
        _result = null;
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

  List<Prediction> get _filteredHistory {
    if (_historyFilter == 'all') return _history;
    return _history.where((p) => p.plantPartMode == _historyFilter).toList();
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

  void _reset() {
    setState(() {
      _selectedImageFile  = null;
      _selectedImageBytes = null;
      _result = null;
      _latController.clear();
      _lngController.clear();
      _plantPartMode = 'leaf';
    });
  }

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // ── Image picker ─────────────────────────────────────────────────
          _buildSectionLabel('1. Select Image'),
          const SizedBox(height: 10),
          _buildImagePicker(),

          const SizedBox(height: 20),

          // ── Plant part mode ──────────────────────────────────────────────
          _buildSectionLabel('2. Plant Part'),
          const SizedBox(height: 10),
          _buildModePicker(),

          const SizedBox(height: 20),

          // ── GPS coordinates ──────────────────────────────────────────────
          _buildSectionLabel('3. GPS Coordinates'),
          const SizedBox(height: 10),
          _buildCoordinateFields(),

          const SizedBox(height: 24),

          // ── Classify button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isClassifying ? null : _classify,
              icon: _isClassifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search_rounded, size: 20),
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

          // ── Result ───────────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(_result!),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(),
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
                  // Replace image button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: AppTheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to take photo or choose from gallery',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Image Source',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
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
    return Row(
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

    return Container(
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
                    valueColor: AlwaysStoppedAnimation<Color>(resultColor),
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

          // Grad-CAM heatmap (base64 image from backend)
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
                    style: TextStyle(fontSize: 11, color: AppTheme.textLight),
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

          // Individual model predictions (for mix mode)
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
                      final isLib = pred.prediction.toLowerCase() == 'liberica';
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
                                organ[0].toUpperCase() + organ.substring(1),
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
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(c),
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
    );
  }

  // Decode base64 string ("data:image/png;base64,...") to image widget
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
    return Column(
      children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHistoryFilterChip('all', 'All'),
                ..._modes.map((m) =>
                    _buildHistoryFilterChip(
                        m['value'] as String, m['label'] as String)),
              ],
            ),
          ),
        ),

        // Summary counts
        if (!_isLoadingHistory)
          _buildHistorySummary(),

        // List
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

  Widget _buildHistorySummary() {
    final all = _history.length;
    final liberica = _history.where((p) => p.isLiberica).length;
    final notLiberica = all - liberica;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _buildHistoryStat('$all', 'Total', AppTheme.textSecondary),
          _buildHistoryStat('$liberica', 'Liberica', AppTheme.dnaVerifiedColor),
          _buildHistoryStat('$notLiberica', 'Not Liberica', Colors.red.shade400),
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

    return Container(
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
        trailing: Container(
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