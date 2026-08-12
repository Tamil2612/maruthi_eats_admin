import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../utils/time_utils.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _tabs = ['Active', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        title: const Text('Orders Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OrdersList(statusGroup: _StatusGroup.active),
          _OrdersList(statusGroup: _StatusGroup.delivered),
          _OrdersList(statusGroup: _StatusGroup.cancelled),
        ],
      ),
    );
  }
}

enum _StatusGroup { active, delivered, cancelled }

class _OrdersList extends StatelessWidget {
  final _StatusGroup statusGroup;

  const _OrdersList({required this.statusGroup});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load orders'));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.maroon));
        }

        final allOrders = snapshot.data!.docs
            .map((d) => OrderModel.fromFirestore(
                d.id, d.data() as Map<String, dynamic>))
            .toList();

        final filtered = allOrders.where((o) {
          switch (statusGroup) {
            case _StatusGroup.active:
              return o.orderStatus != OrderStatus.delivered &&
                  o.orderStatus != OrderStatus.cancelled;
            case _StatusGroup.delivered:
              return o.orderStatus == OrderStatus.delivered;
            case _StatusGroup.cancelled:
              return o.orderStatus == OrderStatus.cancelled;
          }
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64.sp, color: AppColors.gold.withOpacity(0.3)),
                16.verticalSpace,
                Text(
                  statusGroup == _StatusGroup.active
                      ? 'All orders cleared!'
                      : 'No orders here',
                  style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.5),
                      fontSize: 16.sp),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemBuilder: (context, i) => _OrderCard(order: filtered[i]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final next = nextStatus(order.orderStatus);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 6).toUpperCase()}',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
                StatusBadge(status: order.orderStatus),
              ],
            ),
            4.verticalSpace,
            Text(
              TimeUtils.formatTimeAgo(order.createdAt),
              style: TextStyle(color: Colors.grey, fontSize: 11.sp),
            ),
            12.verticalSpace,
            const Divider(height: 1),
            12.verticalSpace,

            // Items Summary
            Text(
              order.items
                  .map((it) => '${it['qty']}x ${it['name']}')
                  .join(', '),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            8.verticalSpace,
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13.sp, color: Colors.grey),
                4.horizontalSpace,
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${order.total.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon),
                    ),
                    Text(
                      order.paymentMode.toUpperCase(),
                      style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold),
                    ),
                  ],
                ),
                if (next != null)
                  ElevatedButton(
                    onPressed: () => _updateStatus(context, next),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      textStyle: TextStyle(fontSize: 12.sp),
                    ),
                    child: Text(
                      'Move to ${orderStatusLabel(next)}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, OrderStatus status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'order_status': orderStatusToString(status)});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order moved to ${orderStatusLabel(status)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }
}
