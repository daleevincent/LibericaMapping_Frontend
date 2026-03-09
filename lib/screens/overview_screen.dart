// lib/screens/overview_screen.dart

import 'package:flutter/material.dart';
import '../services/farm_service.dart';
import '../utils/app_theme.dart';
import '../widgets/stats_card.dart';
import '../utils/mock_data.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = FarmService().getSummaryStats();
    final farms = MockData.farms;
    final totalTrees = stats['totalLibericaTrees'] as int;
    final totalDna = stats['totalDnaVerifiedTrees'] as int;
    final verificationRate =
        totalTrees > 0 ? (totalDna / totalTrees * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Liberica Farm Statistics – Batangas',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '☕ DNA Verification Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${verificationRate.toStringAsFixed(1)}% of all Liberica trees DNA verified',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: verificationRate / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.accent),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$totalDna verified',
                          style: const TextStyle(
                            color: AppTheme.accentLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$totalTrees total trees',
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

              const SizedBox(height: 24),

              // Stats grid
              const Text(
                'Summary Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  StatsCard(
                    title: 'Total Farms',
                    value: '${stats['totalFarms']}',
                    icon: Icons.location_on_rounded,
                    iconColor: AppTheme.accent,
                    subtitle: 'Across Batangas province',
                  ),
                  StatsCard(
                    title: 'Total Field Area',
                    value: '${(stats['totalFieldSize'] as double).toStringAsFixed(1)} ha',
                    icon: Icons.crop_square_rounded,
                    iconColor: AppTheme.primaryLight,
                    subtitle: 'Mapped farm area',
                  ),
                  StatsCard(
                    title: 'Liberica Trees',
                    value: '$totalTrees',
                    icon: Icons.park_rounded,
                    iconColor: AppTheme.nonVerifiedColor,
                    subtitle: 'Mapped total',
                  ),
                  StatsCard(
                    title: 'DNA Verified',
                    value: '$totalDna',
                    icon: Icons.biotech_rounded,
                    iconColor: AppTheme.dnaVerifiedColor,
                    subtitle: '${verificationRate.toStringAsFixed(0)}% verification rate',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Per-farm breakdown
              const Text(
                'Farm Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...farms.map((farm) {
                final rate = farm.libericaTrees > 0
                    ? (farm.dnaVerifiedTrees / farm.libericaTrees * 100)
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              farm.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${rate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: rate >= 70
                                  ? AppTheme.dnaVerifiedColor
                                  : AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        farm.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate / 100,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            rate >= 70
                                ? AppTheme.dnaVerifiedColor
                                : AppTheme.accent,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${farm.dnaVerifiedTrees} / ${farm.libericaTrees} trees DNA verified',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${farm.fieldSize} ha',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}