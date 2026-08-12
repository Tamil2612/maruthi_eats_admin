import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import 'orders_screen.dart';
import 'menu_management_screen.dart';
import 'reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    OrdersScreen(),
    MenuManagementScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/home.png', false),
            activeIcon: _buildIcon('assets/icons/home.png', true),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/menu.png', false),
            activeIcon: _buildIcon('assets/icons/menu.png', true),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/reports.png', false),
            activeIcon: _buildIcon('assets/icons/reports.png', true),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String path, bool active) {
    return Image.asset(
      path,
      width: 32.w,
      height: 32.w,
      color: active ? AppColors.maroon : AppColors.textDark.withValues(alpha: 0.4),
    );
  }
}
