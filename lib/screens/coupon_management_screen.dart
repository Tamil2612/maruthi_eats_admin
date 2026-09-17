import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/coupon.dart';
import '../theme/app_theme.dart';
import 'coupon_form_screen.dart';

class CouponManagementScreen extends StatelessWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load coupons. Please try again.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }

          final coupons = snapshot.data?.docs.map((d) => 
            CouponModel.fromFirestore(d.id, d.data() as Map<String, dynamic>)
          ).toList() ?? [];

          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64.sp, color: AppColors.gold.withValues(alpha: 0.3)),
                  16.verticalSpace,
                  const Text('No coupons created yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  24.verticalSpace,
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CouponFormScreen()),
                    ),
                    child: const Text('Add First Coupon'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: coupons.length,
            separatorBuilder: (ctx, i) => 12.verticalSpace,
            itemBuilder: (context, i) {
              final coupon = coupons[i];
              return _CouponCard(coupon: coupon);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CouponFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: EdgeInsets.all(16.w),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CouponFormScreen(existing: coupon)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.maroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  coupon.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.maroon,
                      fontSize: 14.sp),
                ),
              ),
              ),
              8.horizontalSpace,
              Switch.adaptive(
                value: coupon.isActive,
                activeColor: AppColors.maroon,
                onChanged: (val) {
                  FirebaseFirestore.instance
                      .collection('coupons')
                      .doc(coupon.id)
                      .update({'is_active': val});
                },
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              12.verticalSpace,
              Wrap(
                spacing: 10.w,
                runSpacing: 4.h,
                children: [
                  Text('₹${coupon.amount.toStringAsFixed(0)} OFF',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: AppColors.textDark)),
                  if (coupon.minOrderValue > 0)
                    Text(
                        'min. order ₹${coupon.minOrderValue.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                ],
              ),
              8.verticalSpace,
              if (coupon.expiryDate != null)
                Row(
                  children: [
                    Icon(Icons.event_available, size: 12.sp, color: Colors.grey),
                    4.horizontalSpace,
                    Text(
                      'Expires: ${DateFormat('dd MMM yyyy').format(coupon.expiryDate!)}',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
