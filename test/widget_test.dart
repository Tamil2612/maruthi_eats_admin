import 'package:flutter_test/flutter_test.dart';
import 'package:maruthi_eats_admin/models/order.dart';

void main() {
  test('order status follows the staff workflow', () {
    expect(nextStatus(OrderStatus.placed), OrderStatus.preparing);
    expect(nextStatus(OrderStatus.confirmed), OrderStatus.preparing);
    expect(nextStatus(OrderStatus.preparing), OrderStatus.outForDelivery);
    expect(nextStatus(OrderStatus.outForDelivery), OrderStatus.delivered);
    expect(nextStatus(OrderStatus.delivered), isNull);
    expect(nextStatus(OrderStatus.cancelled), isNull);
  });
}
