// lib/widgets/farm_marker.dart

import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../utils/app_theme.dart';

class FarmInfoCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onViewTrees;
  final VoidCallback onClose;

  const FarmInfoCard({
    super.key,
    required this.farm,
    required this.onViewTrees,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final verificationPct = farm.libericaTrees > 0
        ? (farm.dnaVerifiedTrees / farm.libericaTrees * 100).toStringAsFixed(1)
        : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            farm.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStat(
                      'Coordinates',
                      '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}',
                      Icons.gps_fixed,
                    ),
                    const SizedBox(width: 12),
                    _buildStat(
                      'Field Size',
                      '${farm.fieldSize} ha',
                      Icons.crop_square_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStat(
                      'Liberica Trees',
                      '${farm.libericaTrees}',
                      Icons.park_rounded,
                      color: AppTheme.nonVerifiedColor,
                    ),
                    const SizedBox(width: 12),
                    _buildStat(
                      'DNA Verified',
                      '${farm.dnaVerifiedTrees} ($verificationPct%)',
                      Icons.biotech_rounded,
                      color: AppTheme.dnaVerifiedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DNA Verification Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$verificationPct%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.dnaVerifiedColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: farm.libericaTrees > 0
                            ? farm.dnaVerifiedTrees / farm.libericaTrees
                            : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                            AppTheme.dnaVerifiedColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewTrees,
                    icon: const Icon(Icons.forest_rounded, size: 18),
                    label: const Text('View Tree Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon,
      {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color ?? AppTheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color ?? AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}