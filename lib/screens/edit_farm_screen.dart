// lib/screens/edit_farm_screen.dart
//
// Full-screen admin editor for a single farm.
// Features:
//   • View all trees for this farm
//   • Add a new tree (lat, lng, DNA verified toggle)
//   • Delete an existing tree
//   • Save calls PUT /api/farms/:id  and  POST/DELETE /api/trees

import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../models/tree.dart';
import '../services/tree_service.dart';
import '../utils/app_theme.dart';

class EditFarmScreen extends StatefulWidget {
  final Farm farm;

  const EditFarmScreen({super.key, required this.farm});

  @override
  State<EditFarmScreen> createState() => _EditFarmScreenState();
}

class _EditFarmScreenState extends State<EditFarmScreen> {
  final TreeService _treeService = TreeService();

  // ── Tree list state ──────────────────────────────────────────────────────
  List<CoffeeTree> _trees = [];
  bool _isLoadingTrees = true;

  // ── Add-tree form controllers ────────────────────────────────────────────
  final _latController  = TextEditingController();
  final _lngController  = TextEditingController();
  bool _isDnaVerified   = false;
  bool _isAddingTree    = false;  // loading indicator for POST
  bool _showAddForm     = false;

  // ── Track pending deletes locally before save ────────────────────────────
  final Set<String> _pendingDeletes = {};

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadTrees() async {
    try {
      final trees = await _treeService.getTreesForFarm(widget.farm.id);
      setState(() {
        _trees = trees;
        _isLoadingTrees = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrees = false);
      _showSnack('Failed to load trees: $e', isError: true);
    }
  }

  // ── Add tree ─────────────────────────────────────────────────────────────

  Future<void> _addTree() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      _showSnack('Please enter valid latitude and longitude.', isError: true);
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      _showSnack('Coordinates are out of valid range.', isError: true);
      return;
    }

    setState(() => _isAddingTree = true);

    final newTree = CoffeeTree(
      treeId:    '${widget.farm.id}_T${(_trees.length + 1).toString().padLeft(3, '0')}',
      farmId:    widget.farm.id,
      latitude:  lat,
      longitude: lng,
      status:    _isDnaVerified
                     ? TreeStatus.dnaVerified
                     : TreeStatus.nonDnaVerified,
    );

    try {
      // POST to backend — replace with actual API call when backend is ready
      // final saved = await _treeService.addTree(newTree);
      // For now, add locally:
      setState(() {
        _trees.add(newTree);
        _latController.clear();
        _lngController.clear();
        _isDnaVerified = false;
        _showAddForm   = false;
        _isAddingTree  = false;
      });
      _showSnack('Tree added successfully.');
    } catch (e) {
      setState(() => _isAddingTree = false);
      _showSnack('Failed to add tree: $e', isError: true);
    }
  }

  // ── Delete tree ──────────────────────────────────────────────────────────

  void _confirmDelete(CoffeeTree tree) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Tree?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tree.treeId,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${tree.latitude.toStringAsFixed(6)}, ${tree.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 12),
            const Text('This action cannot be undone.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTree(tree);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTree(CoffeeTree tree) async {
    try {
      // DELETE to backend — replace with actual API call when backend is ready
      // await _treeService.deleteTree(tree.mongoId);
      // For now, remove locally:
      setState(() {
        _trees.removeWhere((t) => t.treeId == tree.treeId);
        _pendingDeletes.add(tree.treeId);
      });
      _showSnack('Tree ${tree.treeId} deleted.');
    } catch (e) {
      _showSnack('Failed to delete tree: $e', isError: true);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _dnaCount  => _trees.where((t) => t.isDnaVerified).length;
  int get _totalCount => _trees.length;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.farm.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.farm.location,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => setState(() => _showAddForm = !_showAddForm),
              icon: Icon(
                _showAddForm ? Icons.close : Icons.add,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _showAddForm ? 'Cancel' : 'Add Tree',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Farm summary bar ─────────────────────────────────────────────
          _buildSummaryBar(),

          // ── Add tree form (collapsible) ──────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showAddForm ? _buildAddTreeForm() : const SizedBox.shrink(),
          ),

          // ── Tree list ────────────────────────────────────────────────────
          Expanded(
            child: _isLoadingTrees
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _trees.isEmpty
                    ? _buildEmptyState()
                    : _buildTreeList(),
          ),
        ],
      ),
    );
  }

  // ── Summary bar ──────────────────────────────────────────────────────────

  Widget _buildSummaryBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildStat('$_totalCount', 'Total Trees', AppTheme.primary),
          _buildDivider(),
          _buildStat('$_dnaCount', 'DNA Verified', AppTheme.dnaVerifiedColor),
          _buildDivider(),
          _buildStat(
            '${_totalCount - _dnaCount}',
            'Non-Verified',
            AppTheme.nonVerifiedColor,
          ),
          _buildDivider(),
          _buildStat(
            _totalCount > 0
                ? '${(_dnaCount / _totalCount * 100).toStringAsFixed(0)}%'
                : '0%',
            'Rate',
            AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
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
            style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1, height: 32, color: Colors.grey.shade200,
      );

  // ── Add tree form ────────────────────────────────────────────────────────

  Widget _buildAddTreeForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.add_location_alt_rounded,
                  color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Add New Tree',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Coordinate fields
          Row(
            children: [
              Expanded(
                child: _buildCoordField(
                  controller: _latController,
                  label: 'Latitude',
                  hint: 'e.g. 13.928890',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoordField(
                  controller: _lngController,
                  label: 'Longitude',
                  hint: 'e.g. 121.199803',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // DNA Verified toggle
          GestureDetector(
            onTap: () => setState(() => _isDnaVerified = !_isDnaVerified),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDnaVerified
                    ? AppTheme.dnaVerifiedColor.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDnaVerified
                      ? AppTheme.dnaVerifiedColor.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isDnaVerified
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(_isDnaVerified),
                      color: _isDnaVerified
                          ? AppTheme.dnaVerifiedColor
                          : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isDnaVerified ? 'DNA Verified' : 'Non-DNA Verified',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _isDnaVerified
                              ? AppTheme.dnaVerifiedColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const Text(
                        'Tap to toggle status',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Color preview dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _isDnaVerified
                          ? AppTheme.dnaVerifiedColor
                          : AppTheme.nonVerifiedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAddingTree ? null : _addTree,
              icon: _isAddingTree
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isAddingTree ? 'Adding...' : 'Add Tree'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
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
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Tree list ────────────────────────────────────────────────────────────

  Widget _buildTreeList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _trees.length,
      itemBuilder: (context, index) => _buildTreeTile(_trees[index], index),
    );
  }

  Widget _buildTreeTile(CoffeeTree tree, int index) {
    final isVerified = tree.isDnaVerified;
    final color =
        isVerified ? AppTheme.dnaVerifiedColor : AppTheme.nonVerifiedColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

        // Color-coded circle indicator
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        title: Text(
          tree.treeId,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${tree.latitude.toStringAsFixed(8)},  ${tree.longitude.toStringAsFixed(8)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tree.statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),

        // Delete button
        trailing: GestureDetector(
          onTap: () => _confirmDelete(tree),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 18,
            ),
          ),
        ),

        isThreeLine: true,
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forest_rounded,
              size: 64, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No trees yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Add Tree" to insert the first tree.',
            style: TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}