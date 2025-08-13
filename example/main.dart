import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// FLUTTER UNIFIED MESSAGING EXAMPLE
// ============================================================================
// This example demonstrates two implementation approaches:
//
// 1. STANDARD FLUTTER (Without Riverpod):
//    - Simple StatefulWidget approach
//    - Manual initialization and setup
//    - Direct service usage
//
// 2. RIVERPOD PATTERN (With Riverpod):
//    - Provider-based architecture
//    - Automatic service initialization via providers
//    - Proper dependency injection and state management
//    - Advanced error handling and loading states
//
// To switch between implementations, uncomment the desired approach in main()
// ============================================================================

// Note: In a real implementation, you would use:
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// part 'main.g.dart';
// And run: dart run build_runner build

// ============================================================================
// FIREBASE OPTIONS (Replace with your actual firebase_options.dart)
// ============================================================================
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    // Add iOS/Android specific configurations as needed
  );
}

// ============================================================================
// MAIN FUNCTION - Choose your implementation
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Choose your state management approach:

  // Option 1: Without Riverpod (Standard Flutter)
  // await FlutterUnifiedMessaging.instance.initialize();
  // runApp(const MyAppWithoutRiverpod());

  // Option 2: With Riverpod (Advanced pattern with providers)
  final container = ProviderContainer();
  await CoreInit.init(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyAppWithRiverpod(),
    ),
  );
}

// ============================================================================
// IMPLEMENTATION WITHOUT RIVERPOD
// ============================================================================

class MyAppWithoutRiverpod extends StatelessWidget {
  const MyAppWithoutRiverpod({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Unified Messaging Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: _createRouter(),
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return OrderDetailScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: '/appointments/:appointmentId',
          builder: (context, state) {
            final appointmentId = state.pathParameters['appointmentId'] ?? '';
            return AppointmentDetailScreen(appointmentId: appointmentId);
          },
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fcmToken;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // Get FCM token
    fcmToken = await FlutterUnifiedMessaging.instance.getFCMToken();

    // Set up notification listeners with navigation
    await FlutterUnifiedMessaging.instance.listen(
      navigationHandler: DefaultNotificationNavigationHandler(
        navigate: (route) => context.push(route),
        typeRouteMap: {
          'order': '/orders',
          'appointment': '/appointments',
          'profile': '/profile',
          'notification': '/notifications',
        },
        fallbackRoute: '/',
      ),
      onNotificationReceived: (title, body, data) {
        // Handle foreground notifications
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 $title: $body'),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      onTokenRefresh: (newToken) {
        // Handle FCM token refresh
        setState(() {
          fcmToken = newToken;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 FCM Token refreshed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );

    setState(() {
      isListening = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Unified Messaging'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isListening ? Icons.check_circle : Icons.pending,
                          color: isListening ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isListening
                              ? 'Notifications Active'
                              : 'Setting up notifications...',
                        ),
                      ],
                    ),
                    if (fcmToken != null) ...[
                      const SizedBox(height: 8),
                      const Text('FCM Token:'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fcmToken!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Test Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _sendTestNotification('Simple'),
              icon: const Icon(Icons.notifications),
              label: const Text('Send Simple Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _sendTestNotification('Route'),
              icon: const Icon(Icons.navigation),
              label: const Text('Send Notification with Route'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _sendTestNotification('Type'),
              icon: const Icon(Icons.category),
              label: const Text('Send Notification with Type'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _sendTestNotification('Data'),
              icon: const Icon(Icons.data_object),
              label: const Text('Send Notification with Custom Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _sendTestNotification('Actions'),
              icon: const Icon(Icons.touch_app),
              label: const Text('Send Notification with Actions'),
            ),
            const Spacer(),
            const Text(
              'Navigation Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => context.push('/notifications'),
                  child: const Text('Notifications'),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/profile'),
                  child: const Text('Profile'),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/orders'),
                  child: const Text('Orders'),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/appointments'),
                  child: const Text('Appointments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification(String type) async {
    switch (type) {
      case 'Simple':
        await FlutterUnifiedMessaging.instance.send(
          title: '🔔 Simple Notification',
          body: 'This is a basic notification without navigation data.',
        );
        break;
      case 'Route':
        await FlutterUnifiedMessaging.instance.send(
          title: '🧭 Direct Route Navigation',
          body:
              'This notification will navigate directly to notifications page.',
          data: {'route': '/notifications'},
        );
        break;
      case 'Type':
        await FlutterUnifiedMessaging.instance.send(
          title: '📋 Type-based Navigation',
          body: 'This notification uses type mapping to navigate.',
          data: {'type': 'order'},
        );
        break;
      case 'Data':
        await FlutterUnifiedMessaging.instance.send(
          title: '📊 Custom Data Navigation',
          body: 'This notification includes custom order data.',
          data: {
            'type': 'order',
            'orderId': '12345',
            'priority': 'high',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        break;
      case 'Actions':
        await FlutterUnifiedMessaging.instance.send(
          title: '⚡ Interactive Notification',
          body: 'This notification has action buttons.',
          data: {'type': 'order', 'orderId': '67890'},
          actions: ['Reply', 'Mark as Read', 'Archive'],
        );
        break;
    }
  }
}

// ============================================================================
// IMPLEMENTATION WITH RIVERPOD
// ============================================================================

// Navigation service for global navigation context
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}

// Utils for showing messages
class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Provides the notification service with auto-initialization and listener setup
final notificationServiceProvider = FutureProvider<FlutterUnifiedMessaging>((
  ref,
) async {
  final service = FlutterUnifiedMessaging.instance;

  // Initialize the notification service
  await service.initialize();

  // Set up listeners with navigation handling
  final context = NavigationService.navigatorKey.currentContext;
  if (context != null) {
    await service.listen(
      navigationHandler: DefaultNotificationNavigationHandler(
        navigate: (route) => context.push(route),
        typeRouteMap: {
          'order': '/orders',
          'appointment': '/appointments',
          'profile': '/profile',
          'notification': '/notifications',
          'test': '/notifications',
        },
        fallbackRoute: '/notifications',
      ),
      onNotificationReceived: (title, body, data) {
        // FCM messages received while app is in foreground are automatically
        // shown as local notifications by the handler
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 $title: $body'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  return service;
});

/// Provides FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = await ref.watch(notificationServiceProvider.future);
  return await service.getFCMToken();
});

final isListeningProvider = Provider<bool>((ref) => false);

/// Core initialization class for the app
class CoreInit {
  static Future<void> init(ProviderContainer container) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize the notification service (this will set up listeners automatically)
    await container.read(notificationServiceProvider.future);
  }
}

class MyAppWithRiverpod extends ConsumerWidget {
  const MyAppWithRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Flutter Unified Messaging Example (Riverpod)',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: _createRouterWithRiverpod(ref),
    );
  }

  GoRouter _createRouterWithRiverpod(WidgetRef ref) {
    return GoRouter(
      navigatorKey:
          NavigationService.navigatorKey, // Important for navigation service
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreenRiverpod(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return OrderDetailScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: '/appointments/:appointmentId',
          builder: (context, state) {
            final appointmentId = state.pathParameters['appointmentId'] ?? '';
            return AppointmentDetailScreen(appointmentId: appointmentId);
          },
        ),
      ],
    );
  }
}

class HomeScreenRiverpod extends ConsumerStatefulWidget {
  const HomeScreenRiverpod({super.key});

  @override
  ConsumerState<HomeScreenRiverpod> createState() => _HomeScreenRiverpodState();
}

class _HomeScreenRiverpodState extends ConsumerState<HomeScreenRiverpod> {
  @override
  void initState() {
    super.initState();
    // Initialization is handled by the provider
  }

  @override
  Widget build(BuildContext context) {
    final notificationServiceAsync = ref.watch(notificationServiceProvider);
    final fcmTokenAsync = ref.watch(fcmTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Unified Messaging (Riverpod)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status (Riverpod)',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    notificationServiceAsync.when(
                      data: (service) => const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Notifications Active'),
                        ],
                      ),
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Setting up notifications...'),
                        ],
                      ),
                      error: (error, stack) => Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Error: $error'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    fcmTokenAsync.when(
                      data: (token) => token != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FCM Token:'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    token,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Text('No FCM token available'),
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading FCM token...'),
                        ],
                      ),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Test Notifications (Riverpod)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            notificationServiceAsync.when(
              data: (service) => Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _sendTestNotification(context, ref, 'Simple'),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Send Simple Notification'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _sendTestNotification(context, ref, 'Route'),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Send Notification with Route'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _sendTestNotification(context, ref, 'Type'),
                    icon: const Icon(Icons.category),
                    label: const Text('Send Notification with Type'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _sendTestNotification(context, ref, 'Data'),
                    icon: const Icon(Icons.data_object),
                    label: const Text('Send Notification with Custom Data'),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading service: $error')),
            ),
            const Spacer(),
            const Text(
              'Navigation Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => context.push('/notifications'),
                  child: const Text('Notifications'),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/profile'),
                  child: const Text('Profile'),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/orders'),
                  child: const Text('Orders'),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/appointments'),
                  child: const Text('Appointments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Advanced Riverpod pattern for sending test notifications
  Future<void> _sendTestNotification(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    try {
      final notificationService = await ref.read(
        notificationServiceProvider.future,
      );

      switch (type) {
        case 'Simple':
          await notificationService.send(
            title: '🔔 Simple Notification (Riverpod)',
            body: 'This is a basic notification without navigation data.',
          );
          break;
        case 'Route':
          await notificationService.send(
            title: '🧭 Direct Route Navigation (Riverpod)',
            body:
                'This notification will navigate directly to notifications page.',
            data: {'route': '/notifications'},
          );
          break;
        case 'Type':
          await notificationService.send(
            title: '📋 Type-based Navigation (Riverpod)',
            body: 'This notification uses type mapping to navigate.',
            data: {'type': 'order'},
          );
          break;
        case 'Data':
          await notificationService.send(
            title: '📊 Custom Data Navigation (Riverpod)',
            body: 'This notification includes custom order data.',
            data: {
              'type': 'order',
              'orderId': '67890',
              'priority': 'high',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          break;
      }

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, 'Test notification sent!');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Failed to send notification: $e');
      }
    }
  }
}

// ============================================================================
// EXAMPLE SCREENS
// ============================================================================

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications Page')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: const Center(child: Text('Orders Page')),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: Center(child: Text('Order Details for #$orderId')),
    );
  }
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: const Center(child: Text('Appointments Page')),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appointment #$appointmentId')),
      body: Center(child: Text('Appointment Details for #$appointmentId')),
    );
  }
}
