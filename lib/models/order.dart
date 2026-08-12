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
      return OrderStatus.confirmed;
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
  final String paymentMode; // 'upi' | 'cod'
  final String paymentStatus;
  final OrderStatus orderStatus;
  final String deliveryAddress;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.items,
    required this.total,
    required this.paymentMode,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryAddress,
    this.createdAt,
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
          });
        }
      }
    }

    return OrderModel(
      id: id,
      customerId: data['customer_id'] ?? '',
      items: parsedItems,
      total: (data['total'] ?? 0).toDouble(),
      paymentMode: data['payment_mode'] ?? 'cod',
      paymentStatus: data['payment_status'] ?? 'pending',
      orderStatus: orderStatusFromString(data['order_status'] ?? 'placed'),
      deliveryAddress: data['delivery_address'] ?? 'No address provided',
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }
}
