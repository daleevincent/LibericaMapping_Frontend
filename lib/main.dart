// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_dashboard.dart';
import 'screens/overview_screen.dart';
import 'screens/farms_directory_screen.dart';
import 'screens/admin_login_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LibericaMapApp());
}

class LibericaMapApp extends StatelessWidget {
  const LibericaMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liberica Farm Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MainDashboardScreen(),
    OverviewScreen(),
    FarmsDirectoryScreen(),
    AdminLoginScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.map_rounded, Icons.map_outlined, 'Mapping'),
                _buildNavItem(1, Icons.bar_chart_rounded,
                    Icons.bar_chart_outlined, 'Overview'),
                _buildNavItem(2, Icons.list_alt_rounded,
                    Icons.list_alt_outlined, 'Directory'),
                _buildNavItem(
                    3, Icons.admin_panel_settings_rounded,
                    Icons.admin_panel_settings_outlined, 'Admin'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey(isActive),
                color: isActive ? AppTheme.primary : AppTheme.textLight,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}