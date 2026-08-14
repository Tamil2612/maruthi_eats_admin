import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import 'coupon_management_screen.dart';
import 'offer_management_screen.dart';

class PromotionsParentScreen extends StatefulWidget {
  const PromotionsParentScreen({super.key});

  @override
  State<PromotionsParentScreen> createState() => _PromotionsParentScreenState();
}

class _PromotionsParentScreenState extends State<PromotionsParentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions & Offers'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Coupons'),
            Tab(text: 'Special Offers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CouponManagementScreen(),
          OfferManagementScreen(),
        ],
      ),
    );
  }
}
