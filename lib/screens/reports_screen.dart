import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange _selectedRange = DateTimeRange(
    start:
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
        23, 59, 59),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Reports'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Select Period',
            onSelected: (val) {
              if (val == 'date') _selectSingleDate();
              if (val == 'range') _selectDateRange();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'date', child: Text('Select Single Date')),
              const PopupMenuItem(
                  value: 'range', child: Text('Select Date Range')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('order_status', isEqualTo: 'delivered')
                  .where('created_at',
                  isGreaterThanOrEqualTo: _selectedRange.start)
                  .where('created_at', isLessThanOrEqualTo: _selectedRange.end)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                      CircularProgressIndicator(color: AppColors.maroon));
                }

                final orders = snapshot.data!.docs
                    .map((d) => OrderModel.fromFirestore(
                    d.id, d.data() as Map<String, dynamic>))
                    .toList();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildPremiumHeader(orders),
                          _sectionHeader('Order History'),
                        ],
                      ),
                    ),
                    if (orders.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                            child: Text('No finalized sales in this period')),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                _buildOrderCompactCard(orders[index]),
                            childCount: orders.length,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: 32.verticalSpace),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
            bottom:
            BorderSide(color: AppColors.maroon.withValues(alpha: 0.05))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            _filterChip('Today', _isToday(_selectedRange)),
            10.horizontalSpace,
            _filterChip('Yesterday', _isYesterday(_selectedRange)),
            10.horizontalSpace,
            _filterChip('Last 7 Days', _isLast7Days(_selectedRange)),
            10.horizontalSpace,
            _filterChip('This Month', _isThisMonth(_selectedRange)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool active) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 11.sp,
              fontWeight: active ? FontWeight.bold : FontWeight.w500)),
      selected: active,
      onSelected: (val) {
        if (!val) return;
        setState(() {
          final now = DateTime.now();
          if (label == 'Today') {
            _selectedRange = DateTimeRange(
              start: DateTime(now.year, now.month, now.day),
              end: DateTime(now.year, now.month, now.day, 23, 59, 59),
            );
          } else if (label == 'Yesterday') {
            final yest = now.subtract(const Duration(days: 1));
            _selectedRange = DateTimeRange(
              start: DateTime(yest.year, yest.month, yest.day),
              end: DateTime(yest.year, yest.month, yest.day, 23, 59, 59),
            );
          } else if (label == 'Last 7 Days') {
            _selectedRange = DateTimeRange(
              start: DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 7)),
              end: DateTime(now.year, now.month, now.day, 23, 59, 59),
            );
          } else if (label == 'This Month') {
            _selectedRange = DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month, now.day, 23, 59, 59),
            );
          }
        });
      },
      selectedColor: AppColors.gold.withValues(alpha: 0.3),
      labelStyle: TextStyle(
          color: active
              ? AppColors.maroonDark
              : AppColors.maroon.withValues(alpha: 0.6)),
      backgroundColor: Colors.transparent,
      side: BorderSide(
          color: active ? AppColors.gold : AppColors.maroon.withValues(alpha: 0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      showCheckmark: false,
    );
  }

  Widget _buildPremiumHeader(List<OrderModel> orders) {
    double totalSales = orders.fold(0, (acc, item) => acc + item.total);
    double totalDiscounts =
        orders.fold(0, (acc, item) => acc + item.couponDiscount);
    int totalOrders = orders.length;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.maroon, AppColors.maroonDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                    color: AppColors.maroon.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedRange.start) +
                        (_selectedRange.start.day == _selectedRange.end.day &&
                            _selectedRange.start.month ==
                                _selectedRange.end.month
                            ? ''
                            : ' - ${DateFormat('dd MMM yyyy').format(_selectedRange.end)}'),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                16.verticalSpace,
                Text(
                  'Total Revenue',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      letterSpacing: 0.5),
                ),
                4.verticalSpace,
                Text(
                  '₹${totalSales.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          16.verticalSpace,
          _metricBox('Total Orders', totalOrders.toString(),
              Icons.receipt_long_outlined),
          if (totalDiscounts > 0) ...[
            12.verticalSpace,
            _metricBox('Coupon Discounts Given', '₹${totalDiscounts.toStringAsFixed(0)}',
                Icons.local_offer_outlined),
          ],
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.maroon, size: 20.sp),
          ),
          16.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              2.verticalSpace,
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Text(title,
          style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark.withValues(alpha: 0.8))),
    );
  }

  Widget _buildOrderCompactCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 5)
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id))),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.receipt_outlined,
                  color: AppColors.maroon, size: 18.sp),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id.substring(0, 6).toUpperCase()}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  2.verticalSpace,
                  Text(
                      order.createdAt != null ? DateFormat('hh:mm a').format(order.createdAt!) : '--',
                      style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
                ],
              ),
            ),
            Text('₹${order.total.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.maroon,
                    fontSize: 13.sp)),
            8.horizontalSpace,
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _selectSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedRange.start,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => _dateTheme(child!),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = DateTimeRange(
          start: DateTime(picked.year, picked.month, picked.day),
          end: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
        );
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
      builder: (context, child) => _dateTheme(child!),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = DateTimeRange(
          start: picked.start,
          end: DateTime(
              picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
      });
    }
  }

  Widget _dateTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.maroon,
          onPrimary: Colors.white,
          surface: AppColors.cream,
          secondaryContainer: AppColors.maroon.withValues(alpha: 0.12),
          onSecondaryContainer: AppColors.maroon,
        ),
      ),
      child: child,
    );
  }

  bool _isToday(DateTimeRange range) {
    final now = DateTime.now();
    return range.start.day == now.day &&
        range.start.month == now.month &&
        range.start.year == now.year &&
        range.start.day == range.end.day;
  }

  bool _isYesterday(DateTimeRange range) {
    final yest = DateTime.now().subtract(const Duration(days: 1));
    return range.start.day == yest.day &&
        range.start.month == yest.month &&
        range.start.year == yest.year &&
        range.start.day == range.end.day;
  }

  bool _isLast7Days(DateTimeRange range) {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return range.start.day == start.day &&
        range.start.month == start.month &&
        range.start.year == start.year;
  }

  bool _isThisMonth(DateTimeRange range) {
    final now = DateTime.now();
    return range.start.day == 1 &&
        range.start.month == now.month &&
        range.start.year == now.year;
  }
}