import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import 'orders_screen.dart';
import 'menu_management_screen.dart';
import 'reports_screen.dart';
import 'promotions_parent_screen.dart';

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
    PromotionsParentScreen(),
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
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/coupon.png', false,
                width: 24.w, height: 28.h),
            activeIcon: _buildIcon('assets/icons/coupon.png', true,
                width: 24.w, height: 28.h),
            label: 'Offers',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(
    String path,
    bool active, {
    double? width,
    double? height,
  }) {
    return Image.asset(
      path,
      width: width ?? 32.w,
      height: height ?? 32.w,
      color:
          active ? AppColors.maroon : AppColors.textDark.withValues(alpha: 0.4),
    );
  }
}
