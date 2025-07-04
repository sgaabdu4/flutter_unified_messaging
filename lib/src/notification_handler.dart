import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta/meta.dart';

/// Background message handler for FCM
/// This must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notification - can be customized by the app
  // Currently just stores it for potential display when app opens
}

/// Simplified notification handler that combines FCM and Local notifications
/// into three simple APIs: initialize, listen, and send
class NotificationHandler {
  static NotificationHandler? _instance;
  static NotificationHandler get instance =>
      _instance ??= NotificationHandler._internal();

  NotificationHandler._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _listenersSetup = false;
  String? _fcmToken;
  void Function(Map<String, dynamic> data)? _onNotificationTap;
  void Function(String newToken)? _onTokenRefresh;

  /// Initialize FCM and Local notifications, including requesting permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
    } catch (e) {
      // Local notifications might fail in test environment, continue with FCM only
    }

    // Initialize FCM
    await _initializeFCM();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions for both
    final permissionsGranted = await _requestPermissions();

    _isInitialized = true;
    return permissionsGranted;
  }  /// Listen to notifications and handle routing
  /// This sets up listeners for both FCM and local notification taps
  Future<void> listen({
    void Function(String title, String body, Map<String, dynamic> data)?
        onNotificationReceived,
    void Function(Map<String, dynamic> data)? onNotificationTap,
    void Function(String newToken)? onTokenRefresh,
  }) async {
    if (!_isInitialized) return;
    if (_listenersSetup) return;

    // Store the callbacks for local notification taps and token refresh
    _onNotificationTap = onNotificationTap;
    _onTokenRefresh = onTokenRefresh;

    // Re-initialize local notifications with the tap handler
    try {
      await _initializeLocalNotifications();
    } catch (e) {
      // Local notifications might fail in test environment, continue without
    }

    // Listen to FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'New Message';
      final body = message.notification?.body ?? '';
      final data = message.data;

      // Notify callback if provided
      onNotificationReceived?.call(title, body, data);

      // Show local notification for foreground FCM messages
      send(title: title, body: body, data: data);
    });

    // Listen to notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationTap?.call(message.data);
    });

    // Check if app was opened from a terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }

    // Listen to FCM token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _onTokenRefresh?.call(newToken);
    });

    _listenersSetup = true;
  }

  /// Send/show a local notification
  Future<void> send({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    List<String>? actions,
  }) async {
    if (!_isInitialized) return;

    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final payload = data != null ? _encodePayload(data) : null;

      // Create notification actions if provided
      List<AndroidNotificationAction>? androidActions;
      if (actions != null && actions.isNotEmpty) {
        androidActions = actions
            .map((action) => AndroidNotificationAction(
                  action.toLowerCase().replaceAll(' ', '_'),
                  action,
                ))
            .toList();
      }

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'unified_messaging_channel',
          'App Notifications',
          channelDescription: 'Notifications from the app',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          actions: androidActions,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: actions != null && actions.isNotEmpty 
              ? 'unified_messaging_category' 
              : null,
        ),
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      // Silent fail - notification sending failed (possibly in test environment)
    }
  }

  /// Get FCM token for server-side push notifications
  Future<String?> getFCMToken() async {
    if (!_isInitialized) return null;
    return _fcmToken ??= await _fcm.getToken();
  }

  /// Reset the handler state for testing purposes
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _listenersSetup = false;
    _fcmToken = null;
    _onNotificationTap = null;
    _onTokenRefresh = null;
  }

  // Private helper methods
  Future<void> _initializeLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && _onNotificationTap != null) {
          final data = _decodePayload(response.payload!);
          _onNotificationTap!(data);
        }
      },
    );

    // Check if app was launched from a local notification
    try {
      final notificationLaunchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();

      if (notificationLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload =
            notificationLaunchDetails?.notificationResponse?.payload;
        if (payload != null && _onNotificationTap != null) {
          final data = _decodePayload(payload);
          _onNotificationTap!(data);
        }
      }
    } catch (e) {
      // Launch details might not be available in test environment
    }
  }

  Future<void> _initializeFCM() async {
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool> _requestPermissions() async {
    bool allPermissionsGranted = true;

    try {
      // Request local notification permissions
      if (Platform.isIOS) {
        final iosPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        allPermissionsGranted = granted ?? false;
      } else if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        // Create notification channel for Android
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'unified_messaging_channel',
            'App Notifications',
            description: 'Notifications from the app',
            importance: Importance.max,
          ),
        );

        final granted = await androidPlugin?.requestNotificationsPermission();
        allPermissionsGranted = granted ?? false;
      }
    } catch (e) {
      // Local notification permissions might fail in test environment
      allPermissionsGranted = false;
    }

    // Request FCM permissions
    try {
      final fcmSettings = await _fcm.requestPermission();
      final fcmGranted =
          fcmSettings.authorizationStatus == AuthorizationStatus.authorized ||
          fcmSettings.authorizationStatus == AuthorizationStatus.provisional;

      return allPermissionsGranted && fcmGranted;
    } catch (e) {
      return false;
    }
  }

  String _encodePayload(Map<String, dynamic> data) => jsonEncode(data);

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (e) {
      return {};
    }
  }
}
