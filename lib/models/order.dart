import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { placed, confirmed, preparing, outForDelivery, delivered, cancelled }

OrderStatus orderStatusFromString(String status) {
  switch (status) {
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'out_for_delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'placed':
    default:
      return OrderStatus.placed;
  }
}

String orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.placed:
      return 'placed';
    case OrderStatus.confirmed:
      return 'confirmed';
    case OrderStatus.preparing:
      return 'preparing';
    case OrderStatus.outForDelivery:
      return 'out_for_delivery';
    case OrderStatus.delivered:
      return 'delivered';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.placed:
      return 'New Order';
    case OrderStatus.confirmed:
      return 'Confirmed';
    case OrderStatus.preparing:
      return 'Preparing';
    case OrderStatus.outForDelivery:
      return 'Out for Delivery';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

/// The next status a staff member can move an order to, in sequence.
/// Returns null if the order is already at a terminal state.
OrderStatus? nextStatus(OrderStatus current) {
  switch (current) {
    case OrderStatus.placed:
      return OrderStatus.preparing;
    case OrderStatus.confirmed:
      return OrderStatus.preparing;
    case OrderStatus.preparing:
      return OrderStatus.outForDelivery;
    case OrderStatus.outForDelivery:
      return OrderStatus.delivered;
    case OrderStatus.delivered:
    case OrderStatus.cancelled:
      return null;
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final double? itemTotal;
  final double? deliveryFee;
  final String? couponCode;
  final double couponDiscount;
  final String paymentMode; // 'upi' | 'cod'
  final String paymentStatus;
  // Written by the backend: 'pending' | 'processed' | 'failed' | 'retry_requested'
  final String? refundStatus;
  final double? refundAmount;
  final String? refundError;
  final OrderStatus orderStatus;
  final String deliveryAddress;
  final DateTime? createdAt;
  // Set by the on_order_created Cloud Function shortly after the order is
  // written. Absent until that function has run, so treat null/'ok' the
  // same (not flagged) — see backend/functions/main.py.
  final String? validationStatus;
  final List<String> validationNotes;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.items,
    required this.total,
    this.itemTotal,
    this.deliveryFee,
    this.couponCode,
    this.couponDiscount = 0.0,
    required this.paymentMode,
    required this.paymentStatus,
    this.refundStatus,
    this.refundAmount,
    this.refundError,
    required this.orderStatus,
    required this.deliveryAddress,
    this.createdAt,
    this.validationStatus,
    this.validationNotes = const [],
  });

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    // Safely parse items list with defaults
    final rawItems = data['items'] as List?;
    final List<Map<String, dynamic>> parsedItems = [];

    if (rawItems != null) {
      for (var item in rawItems) {
        if (item is Map) {
          parsedItems.add({
            'name': item['name'] ?? 'Unknown Item',
            'qty': (item['qty'] ?? 1).toInt(),
            'price': (item['price'] ?? 0).toDouble(),
            'is_combo': item['is_combo'] ?? false,
            'bundle_items': item['bundle_items'] as List?,
          });
        }
      }
    }

    return OrderModel(
      id: id,
      customerId: data['customer_id'] ?? '',
      items: parsedItems,
      total: (data['total'] ?? 0).toDouble(),
      itemTotal: data['item_total'] != null ? (data['item_total'] as num).toDouble() : null,
      deliveryFee: data['delivery_fee'] != null ? (data['delivery_fee'] as num).toDouble() : null,
      couponCode: data['coupon_code'],
      couponDiscount: (data['coupon_discount'] ?? 0).toDouble(),
      paymentMode: data['payment_mode'] ?? 'cod',
      paymentStatus: data['payment_status'] ?? 'pending',
      refundStatus: data['refund_status'] as String?,
      refundAmount: (data['refund_amount'] as num?)?.toDouble(),
      refundError: data['refund_error'] as String?,
      orderStatus: orderStatusFromString(data['order_status'] ?? 'placed'),
      deliveryAddress: data['delivery_address'] ?? 'No address provided',
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      validationStatus: data['validation_status'] as String?,
      validationNotes: (data['validation_notes'] is List)
          ? (data['validation_notes'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}