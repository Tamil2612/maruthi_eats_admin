import 'package:cloud_functions/cloud_functions.dart';
import '../models/order.dart';

/// Order actions that run on Cloud Functions. Every method returns `null` on
/// success, or a short message that is safe to show to the staff member.
class OrderService {
  OrderService._();

  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  static Future<String?> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call(data);
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Something went wrong (${e.code}). Please try again.';
    } catch (_) {
      return 'Could not reach the server. Check the connection and try again.';
    }
  }

  static Future<String?> updateStatus(String orderId, OrderStatus status) {
    if (status == OrderStatus.cancelled) {
      return _call('cancel_order', {'order_id': orderId});
    }
    return _call('update_order_status', {
      'order_id': orderId,
      'order_status': orderStatusToString(status),
    });
  }

  static Future<String?> markCodCollected(String orderId) =>
      _call('mark_cod_collected', {'order_id': orderId});

  static Future<String?> retryRefund(String orderId) =>
      _call('retry_refund', {'order_id': orderId});
}
