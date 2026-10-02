import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // NOTE: Android never changes the sound / importance of an existing channel.
  // The id was bumped (_v2) so the channel is re-created with the alarm
  // audio attributes below. The old channel is deleted in _setupLocal().
  static const String channelId = 'new_orders_channel_v2';
  static const String _legacyChannelId = 'new_orders_channel';
  static const String channelName = 'New Orders';
  static const String channelDescription =
      'Alerts for incoming restaurant orders';

  static const MethodChannel _overlayChannel =
  MethodChannel('com.example.maruthi_eats_admin/overlay');

  bool _localReady = false;
  Future<void>? _permissionFlow;

  // ---------------------------------------------------------------------------
  // Native bridge (MainActivity.kt)
  // ---------------------------------------------------------------------------

  Future<bool> _invokeBool(String method, {bool fallback = true}) async {
    if (kIsWeb) return true;
    try {
      return await _overlayChannel.invokeMethod<bool>(method) ?? fallback;
    } catch (e) {
      // Also lands here inside the FCM background isolate, where MainActivity's
      // channel does not exist. Returning the fallback avoids nagging the user.
      debugPrint('Native call "$method" failed: $e');
      return fallback;
    }
  }

  /// "Display over other apps" (SYSTEM_ALERT_WINDOW).
  Future<bool> checkOverlayPermission() => _invokeBool('checkOverlayPermission');

  /// Opens the "Display over other apps" settings page.
  Future<bool> requestOverlayPermission() =>
      _invokeBool('requestOverlayPermission');

  /// Android 14+ "Full screen notifications" permission. true on older versions.
  Future<bool> canUseFullScreenIntent() => _invokeBool('canUseFullScreenIntent');

  /// Opens the full-screen-intent settings page (only call when not allowed).
  Future<bool> requestFullScreenIntentPermission() =>
      _invokeBool('requestFullScreenIntentPermission');

  /// Brings the activity to the front and wakes the screen. Only works from
  /// the main isolate (i.e. while the Flutter engine of the UI is alive).
  Future<void> bringAppToForeground() async {
    if (kIsWeb) return;
    try {
      await _overlayChannel.invokeMethod('bringToForeground');
    } catch (e) {
      debugPrint('Error bringing app to foreground: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Permissions: every permission is checked first and only requested when it
  // is NOT already granted. Runs at most once per app launch.
  // ---------------------------------------------------------------------------

  Future<void> requestPermissions() {
    if (kIsWeb) return Future.value();
    return _permissionFlow ??= _runPermissionFlow();
  }

  Future<void> _runPermissionFlow() async {
    try {
      // 1. Notifications (Android 13+ POST_NOTIFICATIONS / iOS)
      final android = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled() ?? false;
        if (!enabled) {
          final granted = await android.requestNotificationsPermission();
          debugPrint('Notification permission granted: $granted');
        }
      } else {
        final settings = await _fcm.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
          await _fcm.requestPermission(alert: true, badge: true, sound: true);
        }
      }

      // 2. Full-screen notifications (Android 14+) - settings page, so we
      //    wait for the user to come back before opening the next one.
      if (!await canUseFullScreenIntent()) {
        await _openSettingsAndWait(requestFullScreenIntentPermission);
      }

      // 3. "Display over other apps" - lets the app pop up from the background.
      if (!await checkOverlayPermission()) {
        await _openSettingsAndWait(requestOverlayPermission);
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _openSettingsAndWait(Future<bool> Function() open) async {
    final waiter = _ReturnWaiter();
    try {
      await open();
    } catch (_) {
      waiter.cancel();
      return;
    }
    await waiter.wait();
  }

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  /// Safe to call from both the main isolate and the FCM background isolate.
  Future<void> _setupLocal() async {
    if (_localReady) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/launcher_icon');
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped with payload: ${details.payload}');
      },
    );

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      try {
        await android.deleteNotificationChannel(channelId: _legacyChannelId);
      } catch (_) {}
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
    _localReady = true;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      try {
        await _fcm.requestPermission(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint('Web FCM notification setup skipped/failed: $e');
      }
      return;
    }

    // Permissions are requested from the splash screen (once the UI is up),
    // not here, so they are never asked twice per launch.
    await _setupLocal();

    // App is open: HomeShell's Firestore listener shows the in-app full-screen
    // alert and plays the looping sound, so no system notification is needed.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.data}');
    });

    try {
      await _fcm.subscribeToTopic('admin_orders');
    } catch (e) {
      debugPrint('Error subscribing to admin_orders topic: $e');
    }

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial message: ${initialMessage.data}');
    }
  }

  // ---------------------------------------------------------------------------
  // Showing / clearing the order notification
  // ---------------------------------------------------------------------------

  /// Called by the FCM background handler (separate isolate).
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final service = NotificationService();
    await service._setupLocal();
    await service._showOrderNotification(message);
  }

  Future<void> _showOrderNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    // Only 'placed' orders trigger the full-screen alert.
    if (message.data['status'] != null && message.data['status'] != 'placed') {
      return;
    }

    final title = message.notification?.title ??
        message.data['title'] ??
        'New Order Received!';
    final body = message.notification?.body ??
        message.data['body'] ??
        'A new order has been placed. Tap to view.';

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ticker: 'New order',
      styleInformation: BigTextStyleInformation(body),
      // FLAG_INSISTENT (4): the sound repeats until the notification is
      // opened / cancelled. It is cancelled when the app comes to the front.
      additionalFlags: Int32List.fromList(<int>[4]),
      // Safety net so it can never ring forever.
      timeoutAfter: 90000,
    );

    await _localNotifications.show(
      id: (message.messageId ?? '${message.hashCode}').hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  /// Removes the order notification (this also stops its repeating sound).
  Future<void> cancelOrderNotifications() async {
    if (kIsWeb) return;
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  Future<String?> getToken() => _fcm.getToken();
}

/// Completes when the user comes back to the app after leaving it (used to
/// open the system permission screens one after another).
class _ReturnWaiter {
  final Completer<void> _completer = Completer<void>();
  late final AppLifecycleListener _listener;
  bool _left = false;
  bool _disposed = false;

  _ReturnWaiter() {
    _listener = AppLifecycleListener(
      onInactive: () => _left = true,
      onPause: () => _left = true,
      onResume: () {
        if (_left && !_completer.isCompleted) _completer.complete();
      },
    );
  }

  Future<void> wait() => _completer.future
      .timeout(const Duration(minutes: 3), onTimeout: () {})
      .whenComplete(_dispose);

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
    _dispose();
  }

  void _dispose() {
    if (_disposed) return;
    _disposed = true;
    _listener.dispose();
  }
}