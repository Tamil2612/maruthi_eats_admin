import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }

          final order = OrderModel.fromFirestore(
              snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
          final next = nextStatus(order.orderStatus);

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
                    StatusBadge(status: order.orderStatus),
                  ],
                ),
                if (order.createdAt != null) ...[
                  4.verticalSpace,
                  Text(
                    _formatTime(order.createdAt!),
                    style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 12.sp),
                  ),
                ],
                24.verticalSpace,

                // Customer Details Section
                _SectionTitle(title: 'Customer Details', icon: Icons.person_outline),
                8.verticalSpace,
                _CustomerInfoCard(customerId: order.customerId),
                24.verticalSpace,

                // Items Section
                _SectionTitle(title: 'Order Items', icon: Icons.restaurant_menu_outlined),
                8.verticalSpace,
                _ItemsCard(order: order),
                24.verticalSpace,

                // Delivery Section
                _SectionTitle(title: 'Delivery Address', icon: Icons.location_on_outlined),
                8.verticalSpace,
                _InfoCard(
                  child: Text(
                    order.deliveryAddress,
                    style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.8), fontSize: 14.sp),
                  ),
                ),
                24.verticalSpace,

                // Payment Section
                _SectionTitle(title: 'Payment Information', icon: Icons.payments_outlined),
                8.verticalSpace,
                _PaymentCard(order: order),

                if (order.paymentMode == 'cod' && order.paymentStatus != 'cod_collected') ...[
                  12.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark Cash Collected'),
                      onPressed: () => _updatePaymentStatus(context, 'cod_collected'),
                    ),
                  ),
                ],

                32.verticalSpace,

                // Actions Section
                if (order.orderStatus != OrderStatus.cancelled &&
                    order.orderStatus != OrderStatus.delivered) ...[
                  if (next != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: () => _updateStatus(context, next),
                        child: Text('Mark as ${orderStatusLabel(next)}'),
                      ),
                    ),
                  12.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => _confirmCancel(context),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                ],
                40.verticalSpace,
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, OrderStatus status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'order_status': orderStatusToString(status),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('status_log')
        .add({
      'status': orderStatusToString(status),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updatePaymentStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'payment_status': status,
    });
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (context.mounted) {
        await _updateStatus(context, OrderStatus.cancelled);
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return isToday ? 'Today, $time' : '${dt.day}/${dt.month}/${dt.year}, $time';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.maroon),
        8.horizontalSpace,
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp, letterSpacing: 0.2),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final String customerId;
  const _CustomerInfoCard({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(customerId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _InfoCard(child: Text('Loading customer info...', style: TextStyle(fontSize: 14.sp)));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        final phone = data['phone'] ?? 'No phone';

        return _InfoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  4.verticalSpace,
                  Text(phone, style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 12.sp)),
                ],
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  foregroundColor: AppColors.success,
                  padding: EdgeInsets.all(8.w),
                  minimumSize: Size.zero,
                ),
                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                icon: Icon(Icons.call, size: 18.sp),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final OrderModel order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        children: [
          ...order.items.map((item) {
            final qty = (item['qty'] ?? 1) as int;
            final price = (item['price'] ?? 0).toDouble();
            final isCombo = item['is_combo'] == true;
            final bundleItems = item['bundle_items'] as List?;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} × $qty',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13.sp,
                            color:
                                isCombo ? AppColors.maroon : AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '₹${(price * qty).toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
                if (isCombo && bundleItems != null)
                  Padding(
                    padding: EdgeInsets.only(left: 12.w, bottom: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: bundleItems.map((bi) {
                        final bMap = bi as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          child: Text(
                            '• ${bMap['qty']}x ${bMap['item_name']}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          }),
          Divider(height: 20.h),
          if (order.itemTotal != null) _billRow('Item Total', order.itemTotal!),
          if (order.couponDiscount > 0)
            _billRow(
              order.couponCode != null
                  ? 'Coupon (${order.couponCode})'
                  : 'Coupon Discount',
              -order.couponDiscount,
              isDiscount: true,
            ),
          if (order.deliveryFee != null)
            _billRow('Delivery Fee', order.deliveryFee!),
          if (order.itemTotal != null || order.deliveryFee != null)
            8.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp)),
              Text('₹${order.total.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16.sp,
                      color: AppColors.maroon)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.6),
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final OrderModel order;
  const _PaymentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.paymentStatus.contains('paid') || order.paymentStatus == 'cod_collected';
    return _InfoCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.paymentMode == 'upi' ? 'UPI Payment' : 'Cash on Delivery',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
              4.verticalSpace,
              Text(order.paymentStatus.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? AppColors.success : AppColors.warning
                  )),
            ],
          ),
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? AppColors.success : AppColors.warning,
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}