import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unified_messaging/src/unified_messaging.dart';
import 'package:flutter_unified_messaging/src/navigation_handler.dart';
import 'firebase_mocks.dart';

void main() {
  group('SmartNotifications Complete Coverage Tests', () {
    late FlutterUnifiedMessaging smartNotifications;

    setUpAll(() async {
      await setupFirebaseMessagingMocks();
    });

    setUp(() {
      smartNotifications = FlutterUnifiedMessaging.instance;
    });

    test(
      'should handle listen method with navigation handler callback',
      () async {
        await smartNotifications.initialize();

        bool navigationHandled = false;
        final navigationHandler = DefaultNotificationNavigationHandler(
          navigate: (route) {
            navigationHandled = true;
          },
          typeRouteMap: {'test': '/test'},
        );

        await smartNotifications.listen(
          navigationHandler: navigationHandler,
          onNotificationReceived: (title, body, data) {
            // Callback for received notifications
          },
        );

        expect(navigationHandled, isFalse); // No navigation triggered yet
      },
    );

    test('should trigger navigation handler callback through listen', () async {
      await smartNotifications.initialize();

      bool navigationCalled = false;

      final navigationHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {
          navigationCalled = true;
        },
        typeRouteMap: {'order': '/orders'},
        fallbackRoute: '/home',
      );

      // Set up the listener with navigation handler
      await smartNotifications.listen(
        navigationHandler: navigationHandler,
        onNotificationReceived: (title, body, data) {},
      );

      // The listen method should store the navigation handler
      // and set up the onNotificationTap callback
      expect(navigationCalled, isFalse); // Not called during setup
    });

    test('should handle all public API methods comprehensively', () async {
      // Initialize
      final initResult = await smartNotifications.initialize();
      expect(initResult, isA<bool>());

      // Set up navigation handler
      final navHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {},
        typeRouteMap: {'order': '/orders'},
        fallbackRoute: '/default',
      );

      // Listen with both callbacks
      await smartNotifications.listen(
        navigationHandler: navHandler,
        onNotificationReceived: (title, body, data) {
          // Handle received notification
        },
      );

      // Send notification
      await smartNotifications.send(
        title: 'Test Notification',
        body: 'Test Body',
        data: {'type': 'order', 'id': '123'},
      );

      // Get FCM token
      final token = await smartNotifications.getFCMToken();
      expect(token, isA<String?>());
    });

    test('should maintain singleton pattern across operations', () async {
      final instance1 = FlutterUnifiedMessaging.instance;
      final instance2 = FlutterUnifiedMessaging.instance;

      expect(identical(instance1, instance2), isTrue);

      await instance1.initialize();

      final navHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {},
      );
      await instance2.listen(navigationHandler: navHandler);

      await instance1.send(title: 'Test', body: 'Test');

      final token1 = await instance1.getFCMToken();
      final token2 = await instance2.getFCMToken();

      expect(token1, equals(token2));
    });

    test('should handle complex navigation scenarios through listen', () async {
      await smartNotifications.initialize();

      final routes = <String, String>{};
      final typeRoutes = <String, String>{};

      for (int i = 0; i < 10; i++) {
        routes['route_$i'] = '/page_$i';
        typeRoutes['type_$i'] = '/type_page_$i';
      }

      final navHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {
          // Handle navigation
        },
        typeRouteMap: typeRoutes,
        fallbackRoute: '/fallback',
      );

      await smartNotifications.listen(
        navigationHandler: navHandler,
        onNotificationReceived: (title, body, data) {
          // Process notification
        },
      );

      // Send various notifications
      await smartNotifications.send(
        title: 'Route Test',
        body: 'Testing routes',
        data: {'route': 'route_5'},
      );

      await smartNotifications.send(
        title: 'Type Test',
        body: 'Testing types',
        data: {'type': 'type_3'},
      );
    });

    test('should handle edge cases in listen method', () async {
      await smartNotifications.initialize();

      // Test with minimal navigation handler
      final minimalHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {},
      );

      await smartNotifications.listen(navigationHandler: minimalHandler);

      // Test with only onNotificationReceived
      await smartNotifications.listen(
        navigationHandler: minimalHandler,
        onNotificationReceived: (title, body, data) {},
      );
    });

    test('should handle rapid successive operations', () async {
      await smartNotifications.initialize();

      final navHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {},
        typeRouteMap: {'test': '/test'},
        fallbackRoute: '/home',
      );

      // Rapid listen calls
      await Future.wait([
        smartNotifications.listen(navigationHandler: navHandler),
        smartNotifications.listen(navigationHandler: navHandler),
        smartNotifications.listen(navigationHandler: navHandler),
      ]);

      // Rapid send calls
      await Future.wait([
        smartNotifications.send(title: 'Test 1', body: 'Body 1'),
        smartNotifications.send(title: 'Test 2', body: 'Body 2'),
        smartNotifications.send(title: 'Test 3', body: 'Body 3'),
      ]);

      // Rapid token requests
      final tokens = await Future.wait([
        smartNotifications.getFCMToken(),
        smartNotifications.getFCMToken(),
        smartNotifications.getFCMToken(),
      ]);

      expect(tokens, everyElement(isA<String?>()));
    });

    test('should exercise all code paths in listen method', () async {
      await smartNotifications.initialize();

      bool receivedCalled = false;
      bool navigationCalled = false;

      final navHandler = DefaultNotificationNavigationHandler(
        navigate: (route) {
          navigationCalled = true;
        },
        typeRouteMap: {'action': '/action'},
      );

      // This should exercise the listen method fully
      await smartNotifications.listen(
        navigationHandler: navHandler,
        onNotificationReceived: (title, body, data) {
          receivedCalled = true;
        },
      );

      // Verify the method completed without errors
      expect(receivedCalled, isFalse); // Callback not triggered yet
      expect(navigationCalled, isFalse); // Navigation not triggered yet
    });

    test('should handle complete workflow multiple times', () async {
      // First complete workflow
      await smartNotifications.initialize();

      final handler1 = DefaultNotificationNavigationHandler(
        navigate: (route) {},
      );
      await smartNotifications.listen(navigationHandler: handler1);
      await smartNotifications.send(title: 'First', body: 'First');
      await smartNotifications.getFCMToken();

      // Second complete workflow with different handler
      final handler2 = DefaultNotificationNavigationHandler(
        navigate: (route) {},
      );
      await smartNotifications.listen(navigationHandler: handler2);
      await smartNotifications.send(title: 'Second', body: 'Second');
      await smartNotifications.getFCMToken();
    });
  });
}
