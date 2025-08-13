import 'notification_handler.dart';
import 'navigation_handler.dart';

/// Smart notification service that handles FCM and local notifications
/// with automatic navigation support
class FlutterUnifiedMessaging {
  static FlutterUnifiedMessaging? _instance;
  static FlutterUnifiedMessaging get instance =>
      _instance ??= FlutterUnifiedMessaging._internal();

  FlutterUnifiedMessaging._internal();

  final NotificationHandler _handler = NotificationHandler.instance;
  NotificationNavigationHandler? _navigationHandler;

  /// Initialize the notification service
  ///
  /// This should be called during app startup, ideally in your main() function
  /// after Firebase.initializeApp()
  Future<bool> initialize() async {
    return await _handler.initialize();
  }

  /// Set up notification listeners with navigation handling
  ///
  /// [navigationHandler] defines how notifications should navigate your app
  /// [onNotificationReceived] optional callback for foreground notifications
  /// [onTokenRefresh] optional callback when FCM token is refreshed
  ///
  /// This should be called when your app builds and navigation context is available
  Future<void> listen({
    required NotificationNavigationHandler navigationHandler,
    void Function(String title, String body, Map<String, dynamic> data)?
    onNotificationReceived,
    void Function(String newToken)? onTokenRefresh,
  }) async {
    _navigationHandler = navigationHandler;

    await _handler.listen(
      onNotificationReceived: onNotificationReceived,
      onTokenRefresh: onTokenRefresh,
      onNotificationTap: (data) {
        _navigationHandler?.handleNotificationNavigation(data);
      },
    );
  }

  /// Update the navigation handler at runtime.
  /// Useful if your app's navigation wiring changes after listen().
  void setNavigationHandler(NotificationNavigationHandler navigationHandler) {
    _navigationHandler = navigationHandler;
  }

  /// Send a local notification
  ///
  /// [title] notification title
  /// [body] notification body text
  /// [data] optional payload data for navigation
  /// [actions] optional list of action button labels
  Future<void> send({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    List<String>? actions,
  }) async {
    await _handler.send(title: title, body: body, data: data, actions: actions);
  }

  /// Get FCM token for server-side push notifications
  Future<String?> getFCMToken() async {
    return await _handler.getFCMToken();
  }
}
