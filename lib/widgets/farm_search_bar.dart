// lib/widgets/farm_search_bar.dart

import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../utils/app_theme.dart';

class FarmSearchBar extends StatefulWidget {
  final List<Farm> farms;
  final Farm? selectedFarm;
  final ValueChanged<Farm?> onFarmSelected;

  const FarmSearchBar({
    super.key,
    required this.farms,
    this.selectedFarm,
    required this.onFarmSelected,
  });

  @override
  State<FarmSearchBar> createState() => _FarmSearchBarState();
}

class _FarmSearchBarState extends State<FarmSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Farm> _filteredFarms = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredFarms = widget.farms;
    if (widget.selectedFarm != null) {
      _controller.text = widget.selectedFarm!.name;
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _filterFarms(String query) {
    setState(() {
      _filteredFarms = widget.farms
          .where((f) =>
              f.name.toLowerCase().contains(query.toLowerCase()) ||
              f.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: _filteredFarms.length,
                itemBuilder: (context, index) {
                  final farm = _filteredFarms[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.eco_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    title: Text(
                      farm.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      farm.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                    onTap: () {
                      _controller.text = farm.name;
                      widget.onFarmSelected(farm);
                      _closeDropdown();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                onTap: () {
                  if (!_isOpen) _openDropdown();
                },
                onChanged: (v) {
                  _filterFarms(v);
                  if (!_isOpen) _openDropdown();
                },
                decoration: const InputDecoration(
                  hintText: 'Search or select a farm...',
                  hintStyle: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (widget.selectedFarm != null)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  widget.onFarmSelected(null);
                  _filterFarms('');
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.close, color: AppTheme.textLight, size: 18),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  if (_isOpen) {
                    _closeDropdown();
                  } else {
                    _openDropdown();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isOpen ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}