/// Abstract interface for handling notification navigation
///
/// Implement this interface in your app to define custom navigation logic
/// based on notification data.
abstract class NotificationNavigationHandler {
  /// Handle navigation when a notification is tapped
  ///
  /// [data] contains the notification payload data
  void handleNotificationNavigation(Map<String, dynamic> data);
}

/// Default implementation using GoRouter context.push()
///
/// This implementation expects either:
/// - `route` key for direct navigation: `{'route': '/appointments'}`
/// - `type` key for mapped navigation: `{'type': 'appointment'}`
class DefaultNotificationNavigationHandler
    implements NotificationNavigationHandler {
  final Map<String, String> typeRouteMap;
  final String fallbackRoute;
  final void Function(String route) navigate;

  /// Create a default navigation handler
  ///
  /// [navigate] should be a function that takes a route and navigates to it,
  /// e.g., `(route) => context.push(route)`
  ///
  /// [typeRouteMap] optional map of notification types to routes
  /// If not provided, only direct route navigation will work
  ///
  /// [fallbackRoute] is used when no route or type is specified
  /// If not provided, notifications without routes will be ignored
  DefaultNotificationNavigationHandler({
    required this.navigate,
    this.typeRouteMap = const {},
    this.fallbackRoute = '/',
  });

  @override
  void handleNotificationNavigation(Map<String, dynamic> data) {
    final route = data['route'] is String ? data['route'] as String : null;
    final type = data['type'] is String ? data['type'] as String : null;

    if (route != null) {
      // Direct route navigation always takes priority
      navigate(route);
    } else if (type != null && typeRouteMap.containsKey(type)) {
      // Use mapped route if type mapping is provided
      navigate(typeRouteMap[type]!);
    } else if (fallbackRoute.isNotEmpty && (type != null || data.isNotEmpty)) {
      // Use fallback route only if provided and notification has some data
      navigate(fallbackRoute);
    }
    // Do nothing for notifications without meaningful data or fallback
  }
}
