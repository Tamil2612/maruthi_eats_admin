import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
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

  Stream<QuerySnapshot> _buildStream() {
    final baseQuery = FirebaseFirestore.instance.collection('orders');

    switch (statusGroup) {
      case _StatusGroup.active:
        return baseQuery
            .where('order_status', whereIn: ['placed', 'confirmed', 'preparing', 'out_for_delivery'])
            .orderBy('created_at', descending: true)
            .limit(100)
            .snapshots();
      case _StatusGroup.delivered:
        return baseQuery
            .where('order_status', isEqualTo: 'delivered')
            .orderBy('created_at', descending: true)
            .limit(50)
            .snapshots();
      case _StatusGroup.cancelled:
        return baseQuery
            .where('order_status', isEqualTo: 'cancelled')
            .orderBy('created_at', descending: true)
            .limit(50)
            .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load orders'));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.maroon));
        }

        final filtered = snapshot.data!.docs
            .map((d) => OrderModel.fromFirestore(
            d.id, d.data() as Map<String, dynamic>))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64.sp, color: AppColors.gold.withValues(alpha: 0.3)),
                16.verticalSpace,
                Text(
                  statusGroup == _StatusGroup.active
                      ? 'All orders cleared!'
                      : 'No orders here',
                  style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.5),
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
          itemBuilder: (context, i) => _OrderCard(
            // Keyed by order so a card's "updating" state can never jump to a
            // different order when the list reorders.
            key: ValueKey(filtered[i].id),
            order: filtered[i],
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;

  const _OrderCard({super.key, required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  // True from the tap until the live list shows the new status. The status
  // change takes a few seconds on the server, so the button shows progress
  // instead of looking frozen (and cannot be tapped twice).
  bool _busy = false;
  Timer? _releaseTimer;

  OrderModel get order => widget.order;

  @override
  void didUpdateWidget(covariant _OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderStatus != widget.order.orderStatus) {
      // The new status has arrived: release the button.
      _releaseTimer?.cancel();
      _busy = false;
    }
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = nextStatus(order.orderStatus);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${(order.id.length >= 6 ? order.id.substring(0, 6) : order.id).toUpperCase()}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14.sp),
                        ),
                        if (order.validationStatus == 'flagged') ...[
                          6.horizontalSpace,
                          Icon(Icons.warning_amber_rounded, size: 15.sp, color: AppColors.error),
                        ],
                      ],
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
                  order.items.map((it) => '${it['qty']}x ${it['name']}').join(', '),
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
                        onPressed: _busy ? null : () => _updateStatus(next),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          textStyle: TextStyle(fontSize: 12.sp),
                        ),
                        child: _busy
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textDark,
                              ),
                            ),
                            8.horizontalSpace,
                            const Text('Updating...'),
                          ],
                        )
                            : Text(
                          order.orderStatus == OrderStatus.placed
                              ? 'Accept Order'
                              : 'Move to ${orderStatusLabel(next)}',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);

    final error = await OrderService.updateStatus(order.id, status);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Order moved to ${orderStatusLabel(status)}')),
    );
    // Keep the button locked until the live list reflects the new status
    // (didUpdateWidget); this timer is only a safety net.
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _busy = false);
    });
  }
}