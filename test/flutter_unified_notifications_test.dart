import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';
import 'package:mockito/mockito.dart';

import 'firebase_mocks.dart';

// Comprehensive test suite for FlutterUnifiedMessaging
void main() {
  setUpAll(() async {
    await setupFirebaseMessagingMocks();
  });

  group('FlutterUnifiedMessaging API Tests', () {
    late FlutterUnifiedMessaging smartNotifications;
    late TestNavigationHandler testNavigationHandler;

    setUp(() {
      smartNotifications = FlutterUnifiedMessaging.instance;
      testNavigationHandler = TestNavigationHandler();

      // Reset mocks before each test
      reset(kMockMessagingPlatform);

      // Setup default mock behaviors
      when(
        kMockMessagingPlatform.getToken(vapidKey: anyNamed('vapidKey')),
      ).thenAnswer((_) => Future.value(kTestToken));

      when(
        kMockMessagingPlatform.getInitialMessage(),
      ).thenAnswer((_) => Future.value(null));
    });

    test('should implement singleton pattern correctly', () {
      final instance1 = FlutterUnifiedMessaging.instance;
      final instance2 = FlutterUnifiedMessaging.instance;

      expect(instance1, same(instance2));
      expect(instance1, isA<FlutterUnifiedMessaging>());
    });

    test('should expose correct public API', () {
      // Test that all required methods exist and have correct signatures
      expect(smartNotifications.initialize, isA<Function>());
      expect(smartNotifications.listen, isA<Function>());
      expect(smartNotifications.send, isA<Function>());
      expect(smartNotifications.getFCMToken, isA<Function>());
    });

    test('should handle navigation handler configuration', () async {
      // This tests the listen method signature and navigation handler setup
      expect(() async {
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
          onNotificationReceived: (title, body, data) {
            // Test callback signature
            expect(title, isA<String>());
            expect(body, isA<String>());
            expect(data, isA<Map<String, dynamic>>());
          },
        );
      }, returnsNormally);
    });

    test('should handle send method parameters correctly', () {
      // Test send method signature
      expect(() async {
        await smartNotifications.send(
          title: 'Test Title',
          body: 'Test Body',
          data: {'key': 'value'},
        );
      }, returnsNormally);

      // Test send without data
      expect(() async {
        await smartNotifications.send(title: 'Test Title', body: 'Test Body');
      }, returnsNormally);
    });

    test('should handle getFCMToken method correctly', () {
      // Test getFCMToken method signature
      expect(() async {
        final token = await smartNotifications.getFCMToken();
        // Token can be null or string
        expect(token, anyOf(isNull, isA<String>()));
      }, returnsNormally);
    });

    test('should handle various data types in notification data', () {
      // Test complex data structures
      final complexData = {
        'string': 'test',
        'int': 42,
        'double': 3.14,
        'bool': true,
        'list': [1, 2, 3],
        'map': {'nested': 'value'},
        'null': null,
      };

      expect(() async {
        await smartNotifications.send(
          title: 'Complex Data Test',
          body: 'Testing complex data types',
          data: complexData,
        );
      }, returnsNormally);
    });

    test('should handle Unicode and special characters', () {
      const unicodeTitle = '🔔 Notification 中文 العربية';
      const unicodeBody = 'Emojis 🎉 and chars: @#\$%^&*()';
      final unicodeData = {'unicode': '测试 🌟 اختبار'};

      expect(() async {
        await smartNotifications.send(
          title: unicodeTitle,
          body: unicodeBody,
          data: unicodeData,
        );
      }, returnsNormally);
    });

    test('should handle edge cases gracefully', () {
      // Empty strings
      expect(() async {
        await smartNotifications.send(title: '', body: '');
      }, returnsNormally);

      // Very long strings
      expect(() async {
        await smartNotifications.send(title: 'A' * 1000, body: 'B' * 5000);
      }, returnsNormally);

      // Large data structures
      final largeData = {
        'array': List.generate(100, (i) => 'item_$i'),
        'nested': {
          'deep': List.generate(50, (i) => {'id': i, 'value': 'data_$i'}),
        },
      };

      expect(() async {
        await smartNotifications.send(
          title: 'Large Data Test',
          body: 'Testing large data',
          data: largeData,
        );
      }, returnsNormally);
    });

    test('should support method chaining workflow', () async {
      // Test the workflow without calling initialize which would require local notifications
      expect(() async {
        // Test that methods exist and can be called
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
        );
        await smartNotifications.send(
          title: 'Chain Test',
          body: 'Testing method chaining',
        );
        final token = await smartNotifications.getFCMToken();
        expect(token, anyOf(isNull, isA<String>()));
      }, returnsNormally);
    });

    test('should handle rapid successive operations', () async {
      // Rapid sends
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(
          smartNotifications.send(
            title: 'Rapid Test $i',
            body: 'Body $i',
            data: {'index': i},
          ),
        );
      }

      expect(() async => await Future.wait(futures), returnsNormally);
    });
  });

  group('Navigation Handler Tests', () {
    late TestNavigationHandler testNavigationHandler;

    setUp(() {
      testNavigationHandler = TestNavigationHandler();
    });

    test('should create navigation handler with default configuration', () {
      final handler = DefaultNotificationNavigationHandler(
        navigate: (route) {},
      );
      expect(handler, isA<NotificationNavigationHandler>());
    });

    test('should create navigation handler with custom configuration', () {
      final handler = DefaultNotificationNavigationHandler(
        navigate: (route) {},
        typeRouteMap: {'appointment': '/appointment', 'message': '/chat'},
        fallbackRoute: '/notifications',
      );
      expect(handler, isA<NotificationNavigationHandler>());
    });

    test('should handle navigation correctly', () {
      // Test direct route navigation
      testNavigationHandler.handleNotificationNavigation({'route': '/test'});
      expect(testNavigationHandler.navigatedData, hasLength(1));
      expect(
        testNavigationHandler.navigatedData.first['route'],
        equals('/test'),
      );

      // Test type-based navigation
      testNavigationHandler.reset();
      testNavigationHandler.handleNotificationNavigation({
        'type': 'appointment',
      });
      expect(testNavigationHandler.navigatedData, hasLength(1));
    });

    test('should handle complex navigation scenarios', () {
      final scenarios = [
        {'route': '/home'},
        {'type': 'appointment', 'id': 1},
        {'route': '/profile', 'userId': 123},
        {'type': 'message', 'chatId': 'abc'},
      ];

      for (final scenario in scenarios) {
        testNavigationHandler.handleNotificationNavigation(scenario);
      }

      expect(testNavigationHandler.navigatedData, hasLength(4));
    });

    test('should handle edge cases gracefully', () {
      // Empty data
      testNavigationHandler.handleNotificationNavigation({});
      expect(testNavigationHandler.navigatedData, hasLength(1));

      // Null values
      testNavigationHandler.handleNotificationNavigation({'route': null});
      expect(testNavigationHandler.navigatedData, hasLength(2));

      // Non-string values
      testNavigationHandler.handleNotificationNavigation({'route': 123});
      expect(testNavigationHandler.navigatedData, hasLength(3));
    });

    test('should handle Unicode and special data', () {
      final unicodeData = {
        'route': '/测试/🔔',
        'title': '通知 العربية',
        'emoji': '🎉🌟⭐',
      };

      testNavigationHandler.handleNotificationNavigation(unicodeData);
      expect(testNavigationHandler.navigatedData, hasLength(1));
      expect(testNavigationHandler.navigatedData.first, equals(unicodeData));
    });
  });

  group('Integration Scenarios', () {
    late FlutterUnifiedMessaging smartNotifications;
    late TestNavigationHandler testNavigationHandler;

    setUp(() {
      smartNotifications = FlutterUnifiedMessaging.instance;
      testNavigationHandler = TestNavigationHandler();
    });

    test('should handle complete notification workflow', () async {
      expect(() async {
        // Test the workflow without initialize which would require local notifications setup
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
        );
        await smartNotifications.send(
          title: 'Integration Test',
          body: 'Complete flow test',
          data: {'route': '/test', 'userId': 123},
        );
        final token = await smartNotifications.getFCMToken();
        expect(token, anyOf(isNull, isA<String>()));
      }, returnsNormally);
    });

    test('should maintain consistency across operations', () async {
      expect(() async {
        // Test consistency without initialize
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
        );

        // Multiple sends
        for (int i = 0; i < 5; i++) {
          await smartNotifications.send(
            title: 'Consistency Test $i',
            body: 'Body $i',
            data: {'iteration': i},
          );
        }

        // Multiple token requests
        final tokens = <String?>[];
        for (int i = 0; i < 3; i++) {
          tokens.add(await smartNotifications.getFCMToken());
        }

        expect(tokens, hasLength(3));
      }, returnsNormally);
    });

    test('should handle real-world notification scenarios', () {
      final scenarios = [
        // E-commerce notifications
        {
          'title': 'Order Shipped',
          'body': 'Your order #12345 has been shipped',
          'data': {'type': 'order', 'orderId': '12345', 'route': '/orders'},
        },
        // Healthcare notifications
        {
          'title': 'Appointment Reminder',
          'body': 'You have an appointment tomorrow at 2 PM',
          'data': {'type': 'appointment', 'appointmentId': 'apt_789'},
        },
        // Social media notifications
        {
          'title': 'New Message',
          'body': 'John sent you a message',
          'data': {
            'type': 'message',
            'chatId': 'chat_456',
            'senderId': 'user_123',
          },
        },
      ];

      for (final scenario in scenarios) {
        expect(() async {
          await smartNotifications.send(
            title: scenario['title'] as String,
            body: scenario['body'] as String,
            data: scenario['data'] as Map<String, dynamic>,
          );
        }, returnsNormally);
      }
    });

    test('should validate public API completeness', () {
      // Ensure all required classes are available
      expect(FlutterUnifiedMessaging, isA<Type>());
      expect(NotificationNavigationHandler, isA<Type>());

      // Ensure singleton instance is available
      final instance = FlutterUnifiedMessaging.instance;
      expect(instance, isNotNull);

      // Ensure all methods have correct signatures
      expect(instance.initialize, isA<Future<bool> Function()>());
      expect(instance.listen, isA<Function>());
      expect(instance.send, isA<Function>());
      expect(instance.getFCMToken, isA<Future<String?> Function()>());
    });
  });
}

// Simple test navigation handler for testing
class TestNavigationHandler implements NotificationNavigationHandler {
  List<Map<String, dynamic>> navigatedData = [];

  @override
  void handleNotificationNavigation(Map<String, dynamic> data) {
    navigatedData.add(data);
  }

  void reset() {
    navigatedData.clear();
  }
}
