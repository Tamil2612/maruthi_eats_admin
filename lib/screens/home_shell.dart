import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/new_order_overlay.dart';
import 'orders_screen.dart';
import 'menu_management_screen.dart';
import 'reports_screen.dart';
import 'promotions_parent_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription? _orderSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _alertedOrders = {};
  OrderModel? _pendingOrder;

  static const _screens = [
    OrdersScreen(),
    MenuManagementScreen(),
    ReportsScreen(),
    PromotionsParentScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startOrderListener();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startOrderListener() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('order_status', isEqualTo: 'placed')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final order = OrderModel.fromFirestore(change.doc.id, data);
            if (!_alertedOrders.contains(order.id)) {
              _showAlert(order);
            }
          }
        }
      }
    });
  }

  Future<void> _showAlert(OrderModel order) async {
    _alertedOrders.add(order.id);
    setState(() {
      _pendingOrder = order;
    });

    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc(order.id);
      await orderRef.update({
        'order_status': orderStatusToString(OrderStatus.preparing),
        'updated_at': FieldValue.serverTimestamp(),
      });
      await orderRef.collection('status_log').add({
        'status': orderStatusToString(OrderStatus.preparing),
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _pendingOrder = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _screens[_index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: [
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/home.png', false),
                activeIcon: _buildIcon('assets/icons/home.png', true),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/menu.png', false),
                activeIcon: _buildIcon('assets/icons/menu.png', true),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/reports.png', false),
                activeIcon: _buildIcon('assets/icons/reports.png', true),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/coupon.png', false,
                    width: 24.w, height: 28.h),
                activeIcon: _buildIcon('assets/icons/coupon.png', true,
                    width: 24.w, height: 28.h),
                label: 'Offers',
              ),
            ],
          ),
        ),
        if (_pendingOrder != null)
          NewOrderOverlay(
            order: _pendingOrder!,
            onAccept: () => _acceptOrder(_pendingOrder!),
            onDismiss: () => setState(() => _pendingOrder = null),
          ),
      ],
    );
  }

  Widget _buildIcon(
    String path,
    bool active, {
    double? width,
    double? height,
  }) {
    return Image.asset(
      path,
      width: width ?? 32.w,
      height: height ?? 32.w,
      color:
          active ? AppColors.maroon : AppColors.textDark.withValues(alpha: 0.4),
    );
  }
}
