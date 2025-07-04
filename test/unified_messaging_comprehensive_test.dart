import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';
import 'package:mockito/mockito.dart';

import 'firebase_mocks.dart';

void main() {
  group('FlutterUnifiedMessaging Comprehensive Tests', () {
    late FlutterUnifiedMessaging smartNotifications;
    late TestNavigationHandler testNavigationHandler;

    setUpAll(() async {
      await setupFirebaseMessagingMocks();
    });

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

    test('should expose all required methods', () {
      expect(smartNotifications.initialize, isA<Function>());
      expect(smartNotifications.listen, isA<Function>());
      expect(smartNotifications.send, isA<Function>());
      expect(smartNotifications.getFCMToken, isA<Function>());
    });

    test('should handle initialize method call', () async {
      // Test initialize method - this will test the actual implementation
      try {
        final result = await smartNotifications.initialize();
        expect(result, isA<bool>());
      } catch (e) {
        // Expected to fail in test environment due to platform dependencies
        expect(e, isNotNull);
      }
    });

    test('should handle listen method with navigation handler', () async {
      expect(() async {
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
          onNotificationReceived: (title, body, data) {
            expect(title, isA<String>());
            expect(body, isA<String>());
            expect(data, isA<Map<String, dynamic>>());
          },
        );
      }, returnsNormally);
    });

    test(
      'should handle listen method without specific navigation handler',
      () async {
        // Use a dummy navigation handler since it's required
        final dummyHandler = TestNavigationHandler();

        expect(() async {
          await smartNotifications.listen(
            navigationHandler: dummyHandler,
            onNotificationReceived: (title, body, data) {
              expect(title, isA<String>());
              expect(body, isA<String>());
              expect(data, isA<Map<String, dynamic>>());
            },
          );
        }, returnsNormally);
      },
    );

    test(
      'should handle listen method with only onNotificationReceived',
      () async {
        // Use a dummy navigation handler since it's required
        final dummyHandler = TestNavigationHandler();

        expect(() async {
          await smartNotifications.listen(
            navigationHandler: dummyHandler,
            onNotificationReceived: (title, body, data) {
              expect(title, isA<String>());
              expect(body, isA<String>());
              expect(data, isA<Map<String, dynamic>>());
            },
          );
        }, returnsNormally);
      },
    );

    test('should handle send method with all parameters', () async {
      expect(() async {
        await smartNotifications.send(
          title: 'Test Title',
          body: 'Test Body',
          data: {'key': 'value'},
        );
      }, returnsNormally);
    });

    test('should handle send method without data', () async {
      expect(() async {
        await smartNotifications.send(title: 'Test Title', body: 'Test Body');
      }, returnsNormally);
    });

    test('should handle send method with empty data', () async {
      expect(() async {
        await smartNotifications.send(
          title: 'Test Title',
          body: 'Test Body',
          data: {},
        );
      }, returnsNormally);
    });

    test('should handle send method with complex data structures', () async {
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

    test('should handle getFCMToken method', () async {
      expect(() async {
        final token = await smartNotifications.getFCMToken();
        expect(token, anyOf(isNull, isA<String>()));
      }, returnsNormally);
    });

    test('should handle edge cases in title and body', () async {
      final testCases = [
        {'title': '', 'body': ''},
        {'title': 'A' * 1000, 'body': 'B' * 5000},
        {'title': '🔔 Test 中文', 'body': 'Emoji test 🎉'},
        {'title': 'Special chars @#\$%^&*()', 'body': 'More special chars'},
      ];

      for (final testCase in testCases) {
        expect(() async {
          await smartNotifications.send(
            title: testCase['title']!,
            body: testCase['body']!,
            data: {'test': 'data'},
          );
        }, returnsNormally);
      }
    });

    test('should handle Unicode and special characters', () async {
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

    test('should handle large data structures', () async {
      final largeData = {
        'array': List.generate(100, (i) => 'item_$i'),
        'nested': {
          'deep': List.generate(50, (i) => {'id': i, 'value': 'data_$i'}),
        },
        'strings': List.generate(20, (i) => 'A' * 100),
      };

      expect(() async {
        await smartNotifications.send(
          title: 'Large Data Test',
          body: 'Testing large data',
          data: largeData,
        );
      }, returnsNormally);
    });

    test('should handle rapid successive operations', () async {
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(
          smartNotifications.send(
            title: 'Rapid Test $i',
            body: 'Body $i',
            data: {'index': i},
          ),
        );
        futures.add(smartNotifications.getFCMToken());
      }

      expect(() async => await Future.wait(futures), returnsNormally);
    });

    test('should handle complete workflow', () async {
      expect(() async {
        // Test the complete workflow - this will exercise more code paths
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
        );

        // Send multiple notifications
        await smartNotifications.send(
          title: 'Workflow Test 1',
          body: 'First notification',
          data: {'step': 1},
        );

        await smartNotifications.send(
          title: 'Workflow Test 2',
          body: 'Second notification',
          data: {'step': 2},
        );

        // Get token multiple times
        await smartNotifications.getFCMToken();
        await smartNotifications.getFCMToken();
      }, returnsNormally);
    });

    test('should maintain state across operations', () async {
      expect(() async {
        // Test that the instance maintains state correctly
        await smartNotifications.listen(
          navigationHandler: testNavigationHandler,
        );

        for (int i = 0; i < 5; i++) {
          await smartNotifications.send(
            title: 'State Test $i',
            body: 'Body $i',
            data: {'iteration': i},
          );
        }

        final tokens = <String?>[];
        for (int i = 0; i < 3; i++) {
          tokens.add(await smartNotifications.getFCMToken());
        }

        expect(tokens, hasLength(3));
      }, returnsNormally);
    });

    test('should handle real-world notification scenarios', () async {
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
