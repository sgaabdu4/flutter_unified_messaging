import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unified_messaging/src/navigation_handler.dart';

void main() {
  group('NotificationNavigationHandler', () {
    group('DefaultNotificationNavigationHandler', () {
      test('should create with default values', () {
        final handler = DefaultNotificationNavigationHandler(
          navigate: (route) {},
        );

        expect(handler.typeRouteMap, isEmpty);
        expect(handler.fallbackRoute, '/');
      });

      test('should create with custom configuration', () {
        final customTypeMap = {'test': '/test', 'order': '/orders'};
        const customFallback = '/home';

        final handler = DefaultNotificationNavigationHandler(
          navigate: (route) {},
          typeRouteMap: customTypeMap,
          fallbackRoute: customFallback,
        );

        expect(handler.typeRouteMap, customTypeMap);
        expect(handler.fallbackRoute, customFallback);
      });

      group('handleNotificationNavigation', () {
        late List<String> navigatedRoutes;
        late DefaultNotificationNavigationHandler handler;

        setUp(() {
          navigatedRoutes = [];
          handler = DefaultNotificationNavigationHandler(
            navigate: (route) => navigatedRoutes.add(route),
            typeRouteMap: {
              'appointment': '/appointments',
              'order': '/orders',
              'message': '/messages',
            },
            fallbackRoute: '/home',
          );
        });

        test('should navigate to direct route when provided', () {
          handler.handleNotificationNavigation({'route': '/specific/path'});

          expect(navigatedRoutes, ['/specific/path']);
        });

        test('should prioritize direct route over type', () {
          handler.handleNotificationNavigation({
            'route': '/direct/path',
            'type': 'appointment',
          });

          expect(navigatedRoutes, ['/direct/path']);
        });

        test('should navigate to mapped route for known type', () {
          handler.handleNotificationNavigation({'type': 'appointment'});

          expect(navigatedRoutes, ['/appointments']);
        });

        test('should navigate to mapped route for different types', () {
          handler.handleNotificationNavigation({'type': 'order'});
          handler.handleNotificationNavigation({'type': 'message'});

          expect(navigatedRoutes, ['/orders', '/messages']);
        });

        test('should navigate to fallback for unknown type with data', () {
          handler.handleNotificationNavigation({'type': 'unknown'});

          expect(navigatedRoutes, ['/home']);
        });

        test('should navigate to fallback for non-type data', () {
          handler.handleNotificationNavigation({'userId': '123'});

          expect(navigatedRoutes, ['/home']);
        });

        test('should not navigate for empty data', () {
          handler.handleNotificationNavigation({});

          expect(navigatedRoutes, isEmpty);
        });

        test(
          'should not navigate when fallback is empty and no route/type match',
          () {
            final handlerWithoutFallback = DefaultNotificationNavigationHandler(
              navigate: (route) => navigatedRoutes.add(route),
              typeRouteMap: {'known': '/known'},
              fallbackRoute: '',
            );

            handlerWithoutFallback.handleNotificationNavigation({
              'type': 'unknown',
            });

            expect(navigatedRoutes, isEmpty);
          },
        );

        test('should handle null values gracefully', () {
          handler.handleNotificationNavigation({
            'route': null,
            'type': null,
            'other': 'data',
          });

          expect(navigatedRoutes, ['/home']);
        });

        test('should handle non-string route values', () {
          handler.handleNotificationNavigation({'route': 123});

          expect(navigatedRoutes, ['/home']);
        });

        test('should handle non-string type values', () {
          handler.handleNotificationNavigation({'type': 123});

          expect(navigatedRoutes, ['/home']);
        });

        test('should handle complex data structures', () {
          handler.handleNotificationNavigation({
            'user': {'id': '123', 'name': 'John'},
            'metadata': ['tag1', 'tag2'],
            'count': 42,
          });

          expect(navigatedRoutes, ['/home']);
        });
      });

      group('edge cases', () {
        test('should work with empty type route map', () {
          final navigatedRoutes = <String>[];
          final handler = DefaultNotificationNavigationHandler(
            navigate: (route) => navigatedRoutes.add(route),
            typeRouteMap: {},
            fallbackRoute: '/fallback',
          );

          handler.handleNotificationNavigation({'type': 'anything'});

          expect(navigatedRoutes, ['/fallback']);
        });

        test('should work with no fallback route', () {
          final navigatedRoutes = <String>[];
          final handler = DefaultNotificationNavigationHandler(
            navigate: (route) => navigatedRoutes.add(route),
            typeRouteMap: {'known': '/known'},
            fallbackRoute: '',
          );

          // Known type should work
          handler.handleNotificationNavigation({'type': 'known'});
          expect(navigatedRoutes, ['/known']);

          // Unknown type should not navigate
          handler.handleNotificationNavigation({'type': 'unknown'});
          expect(navigatedRoutes, ['/known']); // No additional navigation
        });
      });
    });

    group('Custom NotificationNavigationHandler', () {
      test('should support custom implementation', () {
        final navigatedRoutes = <String>[];

        final customHandler = _TestCustomNavigationHandler(
          onNavigate: (route) => navigatedRoutes.add(route),
        );

        customHandler.handleNotificationNavigation({'userId': '123'});

        expect(navigatedRoutes, ['/user/123']);
      });
    });
  });
}

// Test implementation of custom navigation handler
class _TestCustomNavigationHandler implements NotificationNavigationHandler {
  final void Function(String route) onNavigate;

  _TestCustomNavigationHandler({required this.onNavigate});

  @override
  void handleNotificationNavigation(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final productId = data['productId'] as String?;

    if (userId != null) {
      onNavigate('/user/$userId');
    } else if (productId != null) {
      onNavigate('/product/$productId');
    } else {
      onNavigate('/home');
    }
  }
}
