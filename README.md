# Flutter Unified Messaging

A **project-agnostic** Flutter package that provides unified FCM (Firebase Cloud Messaging) and local notifications with customizable smart navigation handling. This package combines Firebase messaging and local notifications into a single, easy-to-use API with flexible navigation support that adapts to any Flutter app.

## Features

- 🚀 **Simple API** - Initialize, listen, and send notifications with just 3 methods
- 🔔 **Unified Notifications** - Handles both FCM and local notifications seamlessly
- 🧭 **Flexible Navigation** - Customizable navigation handlers for any app structure
- 🏗️ **Project-Agnostic** - No hardcoded routes - you define all navigation logic
- 📱 **Cross-platform** - Works on both iOS and Android
- 🔧 **Configurable** - Flexible notification settings and routing options
- 🎯 **Type-safe** - Clear data structures and error handling
- 🔄 **Token Management** - Automatic FCM token refresh handling
- ⚡ **Interactive Notifications** - Support for notification action buttons
- 📡 **Background Processing** - Handles notifications when app is closed

## Prerequisites

Before using this package, ensure you have:

1. **Flutter SDK** installed (>=3.8.1)
2. **Firebase project** set up with your app registered
3. **Firebase configuration files** in your project:
   - `android/app/google-services.json` (Android)
   - `ios/Runner/GoogleService-Info.plist` (iOS)
4. **Platform-specific setup** completed (see Platform Setup section)

## Installation

### 1. Add Dependency

Add this to your app's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_unified_messaging:
    git:
      url: https://github.com/yourusername/flutter_unified_messaging.git
    # OR if using locally:
    # path: ../flutter_unified_messaging
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

If you haven't already set up Firebase in your project:

#### Add Firebase to your Flutter app:
```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

#### Add Firebase Core dependency:
```yaml
dependencies:
  firebase_core: ^3.10.0
  # ... other dependencies
```

## Platform Setup

### Android Setup

#### 1. Update AndroidManifest.xml

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <!-- For Android 13+ (API level 33+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application
        android:label="your_app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- ... existing activities ... -->
        
    </application>
</manifest>
```

#### 2. Add Notification Icon

Create a notification icon and place it at:
```
android/app/src/main/res/drawable/ic_notification.png
```

**Important**: The icon should be:
- White/transparent PNG
- 24x24dp size
- Simple design (avoid gradients or complex details)

#### 3. Update build.gradle (if needed)

Ensure your `android/app/build.gradle` has:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Minimum for this package
        targetSdkVersion 34
    }
}
```

### iOS Setup

#### 1. Update AppDelegate.swift

Replace your `ios/Runner/AppDelegate.swift` with:

```swift
import UIKit
import Flutter
import firebase_messaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle notification tap when app is terminated
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}
```

#### 2. Enable Push Notifications Capability

In Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select your target → "Signing & Capabilities"
3. Click "+ Capability" and add "Push Notifications"
4. Ensure your Apple Developer account and provisioning profile support push notifications

#### 3. Update Info.plist (Optional)

For custom notification sounds, add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## Quick Start

### 1. Initialize Firebase and Notifications

Update your `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';
import 'firebase_options.dart'; // Generated by flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await FlutterUnifiedMessaging.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. Set Up Navigation (Choose Your Approach)

#### Option A: Simple Direct Route Navigation

```dart
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';
import 'package:go_router/go_router.dart'; // or your preferred routing solution

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set up notification listeners when navigation is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications(context);
    });
    
    return MaterialApp.router(
      routerConfig: _router,
      title: 'My App',
    );
  }

  void _setupNotifications(BuildContext context) {
    FlutterUnifiedMessaging.instance.listen(
      navigationHandler: DefaultNotificationNavigationHandler(
        navigate: (route) => context.push(route),
        // Simple setup - only handles direct routes
      ),
      onNotificationReceived: (title, body, data) {
        // Optional: Handle foreground notifications
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification: $title')),
        );
      },
    );
  }
}
```

#### Option B: Advanced Navigation with Type Mapping

```dart
void _setupNotifications(BuildContext context) {
  FlutterUnifiedMessaging.instance.listen(
    navigationHandler: DefaultNotificationNavigationHandler(
      navigate: (route) => context.push(route),
      // Define your app-specific route mappings
      typeRouteMap: {
        'appointment': '/appointments',
        'reminder': '/reminders',
        'message': '/messages',
        'alert': '/alerts',
        'order': '/orders',
        'promotion': '/offers',
      },
      fallbackRoute: '/notifications', // Where to go if no specific route
    ),
    onNotificationReceived: (title, body, data) {
      print('Received notification: $title - $body');
      // Handle foreground notifications as needed
    },
    onTokenRefresh: (newToken) {
      print('FCM Token refreshed: $newToken');
      // Send the new token to your server
      _sendTokenToServer(newToken);
    },
  );
}
```

#### Option C: Custom Navigation Handler

```dart
class MyCustomNavigationHandler implements NotificationNavigationHandler {
  final GoRouter router;
  
  MyCustomNavigationHandler(this.router);
  
  @override
  void handleNotificationNavigation(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    final userId = data['userId'] as String?;
    final productId = data['productId'] as String?;
    final type = data['type'] as String?;
    
    if (route != null) {
      // Direct route navigation
      router.push(route);
    } else if (userId != null) {
      // User-specific navigation
      router.push('/profile/$userId');
    } else if (productId != null) {
      // Product-specific navigation
      router.push('/products/$productId');
    } else if (type == 'chat') {
      // Type-based navigation
      router.push('/chat');
    } else {
      // Fallback
      router.push('/home');
    }
  }
}

// Use the custom handler
void _setupNotifications(BuildContext context) {
  FlutterUnifiedMessaging.instance.listen(
    navigationHandler: MyCustomNavigationHandler(_router),
  );
}
```

### 3. Send Notifications

```dart
class NotificationExamples {
  static final _messaging = FlutterUnifiedMessaging.instance;
  
  // Simple local notification
  static Future<void> sendSimple() async {
    await _messaging.send(
      title: 'Hello!',
      body: 'This is a test notification',
    );
  }
  
  // Notification with direct route
  static Future<void> sendWithRoute() async {
    await _messaging.send(
      title: 'Appointment Reminder',
      body: 'You have an appointment in 30 minutes',
      data: {'route': '/appointments/123'},
    );
  }
  
  // Notification with type-based navigation
  static Future<void> sendWithType() async {
    await _messaging.send(
      title: 'New Message',
      body: 'You have a new message from John',
      data: {'type': 'message'},
    );
  }
  
  // Notification with custom data
  static Future<void> sendWithCustomData() async {
    await _messaging.send(
      title: 'Order Update',
      body: 'Your order #12345 has been shipped',
      data: {
        'orderId': '12345',
        'userId': 'user_789',
        'action': 'view_order',
      },
    );
  }
  
  // Interactive notification with action buttons
  static Future<void> sendWithActions() async {
    await _messaging.send(
      title: 'New Message',
      body: 'John sent you a message',
      data: {'type': 'message', 'userId': 'john_123'},
      actions: ['Reply', 'Mark as Read', 'Archive'],
    );
  }
}
```

### 4. Get FCM Token (For Server Push Notifications)

```dart
class FCMTokenService {
  static Future<String?> getAndSendTokenToServer() async {
    try {
      final token = await FlutterUnifiedMessaging.instance.getFCMToken();
      
      if (token != null) {
        // Send token to your server
        await _sendTokenToServer(token);
        print('FCM Token: $token');
        return token;
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
    return null;
  }
  
  static Future<void> _sendTokenToServer(String token) async {
    // Implement your server API call here
    // Example:
    // await http.post(
    //   Uri.parse('https://your-server.com/api/fcm-tokens'),
    //   body: {'token': token, 'userId': currentUserId},
    // );
  }
}
```

## Advanced Usage

### Server Push Notifications

To send push notifications from your server, use the FCM token:

```javascript
// Node.js example using Firebase Admin SDK
const admin = require('firebase-admin');

async function sendPushNotification(fcmToken, title, body, data) {
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: data, // Custom data for navigation
    android: {
      notification: {
        icon: 'ic_notification',
        color: '#0066CC',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.error('Error sending message:', error);
  }
}

// Usage
await sendPushNotification(
  userFcmToken,
  'New Appointment',
  'You have an appointment tomorrow at 2 PM',
  {
    route: '/appointments/456',
    appointmentId: '456',
  }
);
```

### Integration with State Management

#### Riverpod Integration

```dart
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_provider.g.dart';

@Riverpod(keepAlive: true)
Future<FlutterUnifiedMessaging> notificationService(Ref ref) async {
  final service = FlutterUnifiedMessaging.instance;
  await service.initialize();
  return service;
}

// Usage in widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(notificationServiceProvider);
    
    return notificationService.when(
      data: (service) => ElevatedButton(
        onPressed: () => _sendNotification(service),
        child: Text('Send Notification'),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Future<void> _sendNotification(FlutterUnifiedMessaging service) async {
    await service.send(
      title: 'Test',
      body: 'Riverpod integration works!',
    );
  }
}
```

#### BLoC Integration

```dart
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterUnifiedMessaging _notificationService;

  NotificationBloc(this._notificationService) : super(NotificationInitial()) {
    on<SendNotificationEvent>(_onSendNotification);
    on<InitializeNotificationsEvent>(_onInitializeNotifications);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.initialize();
      emit(NotificationReady());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onSendNotification(
    SendNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.send(
        title: event.title,
        body: event.body,
        data: event.data,
      );
      emit(NotificationSent());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
```

### Testing

#### Unit Testing Notifications

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';

class MockNotificationService extends Mock implements FlutterUnifiedMessaging {}

void main() {
  group('Notification Tests', () {
    late MockNotificationService mockService;

    setUp(() {
      mockService = MockNotificationService();
    });

    test('should send notification successfully', () async {
      // Arrange
      when(mockService.send(
        title: 'Test',
        body: 'Test Body',
        data: {},
      )).thenAnswer((_) async => {});

      // Act
      await mockService.send(
        title: 'Test',
        body: 'Test Body',
        data: {},
      );

      // Assert
      verify(mockService.send(
        title: 'Test',
        body: 'Test Body',
        data: {},
      )).called(1);
    });
  });
}
```

### Performance Optimization

#### Lazy Initialization

```dart
class NotificationManager {
  static FlutterUnifiedMessaging? _instance;
  
  static Future<FlutterUnifiedMessaging> get instance async {
    if (_instance == null) {
      _instance = FlutterUnifiedMessaging.instance;
      await _instance!.initialize();
    }
    return _instance!;
  }
}
```

#### Memory Management

```dart
class NotificationLifecycleManager extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background - notifications will be handled by system
        break;
      case AppLifecycleState.resumed:
        // App is in foreground - refresh notification listeners if needed
        _refreshNotificationListeners();
        break;
      case AppLifecycleState.detached:
        // App is being terminated - cleanup if needed
        break;
      default:
        break;
    }
  }
  
  void _refreshNotificationListeners() {
    // Re-establish listeners if needed
  }
}
```

## API Reference

### FlutterUnifiedMessaging

Main singleton class for handling notifications.

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `instance` | `FlutterUnifiedMessaging` | Get singleton instance |
| `initialize()` | `Future<bool>` | Initialize the notification service |
| `listen({navigationHandler, onNotificationReceived, onTokenRefresh})` | `Future<void>` | Set up notification listeners |
| `send({title, body, data, actions})` | `Future<void>` | Send a local notification |
| `getFCMToken()` | `Future<String?>` | Get FCM token for server push |

#### Example Usage

```dart
final notifications = FlutterUnifiedMessaging.instance;

// Initialize
await notifications.initialize();

// Set up listeners
await notifications.listen(
  navigationHandler: myHandler,
  onNotificationReceived: (title, body, data) => print('Received: $title'),
  onTokenRefresh: (newToken) => print('Token refreshed: $newToken'),
);

// Send notification
await notifications.send(
  title: 'Hello',
  body: 'World',
  data: {'route': '/home'},
  actions: ['Reply', 'Dismiss'],
);

// Get FCM token
final token = await notifications.getFCMToken();
```

### DefaultNotificationNavigationHandler

Default implementation of navigation handling.

#### Constructor Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `navigate` | `Function(String)` | ✅ | Navigation function (e.g., `context.push`) |
| `typeRouteMap` | `Map<String, String>?` | ❌ | Map notification types to routes |
| `fallbackRoute` | `String?` | ❌ | Default route when no specific route found |

#### Example

```dart
final handler = DefaultNotificationNavigationHandler(
  navigate: (route) => GoRouter.of(context).push(route),
  typeRouteMap: {
    'message': '/chat',
    'order': '/orders',
  },
  fallbackRoute: '/home',
);
```

### NotificationNavigationHandler (Interface)

Interface for custom navigation handlers.

```dart
abstract class NotificationNavigationHandler {
  void handleNotificationNavigation(Map<String, dynamic> data);
}
```

#### Implementation Example

```dart
class MyCustomHandler implements NotificationNavigationHandler {
  @override
  void handleNotificationNavigation(Map<String, dynamic> data) {
    // Your custom navigation logic
    final route = data['route'] as String?;
    if (route != null) {
      // Navigate to route
    }
  }
}
```

### Notification Data Structure

```dart
// Data passed to notifications
Map<String, dynamic> notificationData = {
  'route': '/specific/route',           // Direct route (highest priority)
  'type': 'message',                   // Type for mapping (medium priority)
  'userId': '123',                     // Custom data (lowest priority)
  'productId': '456',                  // Custom data
  'action': 'view',                    // Custom data
  'metadata': {                        // Nested custom data
    'source': 'push',
    'campaign': 'summer_sale',
  },
};
```

### Callback Functions

#### onNotificationReceived

Called when a notification is received while the app is in the foreground.

```dart
typedef NotificationReceivedCallback = void Function(
  String title,
  String body,
  Map<String, dynamic> data,
);
```

#### navigate Function

Function passed to navigation handlers for routing.

```dart
typedef NavigateFunction = void Function(String route);
```

## Configuration Options

### Notification Channels (Android)

The package automatically creates a default notification channel. For custom channels:

```dart
// This is handled internally, but you can customize by extending the package
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);
```

### Notification Settings (iOS)

iOS notification settings are configured automatically:

- **Alert**: Enabled
- **Badge**: Enabled  
- **Sound**: Enabled
- **Provisional**: Disabled (requires explicit permission)

## Troubleshooting

### Common Issues and Solutions

#### Firebase Issues

**Problem**: `Firebase not initialized` error
```
Solution: Ensure Firebase.initializeApp() is called before using notifications
```

**Problem**: FCM token is null
```
Solutions:
1. Check internet connection
2. Verify Firebase configuration files are properly added
3. Ensure app is registered in Firebase console
4. Test on physical device (tokens don't work on simulators)
```

**Problem**: Firebase configuration file missing
```
Solutions:
1. Run: flutterfire configure
2. Manually add google-services.json (Android) and GoogleService-Info.plist (iOS)
3. Verify files are in correct locations and added to build
```

#### iOS-Specific Issues

**Problem**: Notifications not appearing on iOS
```
Solutions:
1. Test on physical device (not simulator)
2. Check notification permissions in iOS Settings
3. Verify AppDelegate.swift setup is correct
4. Ensure "Push Notifications" capability is enabled in Xcode
5. Check provisioning profile supports push notifications
```

**Problem**: App crashes on iOS when handling notifications
```
Solutions:
1. Update AppDelegate.swift with provided code
2. Ensure firebase_messaging import is present
3. Check iOS deployment target is >= 11.0
```

**Problem**: Background notification handling not working
```
Solutions:
1. Add "remote-notification" to UIBackgroundModes in Info.plist
2. Implement proper AppDelegate methods
3. Test with device in background/terminated state
```

#### Android-Specific Issues

**Problem**: Notifications not showing on Android
```
Solutions:
1. Check notification permissions (especially Android 13+)
2. Verify AndroidManifest.xml permissions are added
3. Ensure notification icon exists and is properly formatted
4. Test with different Android versions
```

**Problem**: Notification icon not displaying correctly
```
Solutions:
1. Create white/transparent PNG icon
2. Place in android/app/src/main/res/drawable/
3. Name it ic_notification.png
4. Ensure size is 24x24dp
5. Avoid gradients or complex designs
```

**Problem**: Permission denied on Android 13+
```
Solutions:
1. Add POST_NOTIFICATIONS permission to AndroidManifest.xml
2. Request permission at runtime if needed
```

#### Navigation Issues

**Problem**: Navigation not working when tapping notifications
```
Solutions:
1. Ensure navigation context is available when setting up listeners
2. Check that routes exist in your router configuration
3. Verify notification data format matches expected structure
4. Test navigation handler separately
```

**Problem**: App opens but doesn't navigate to correct screen
```
Solutions:
1. Check notification data structure
2. Verify route mapping in typeRouteMap
3. Test with direct route navigation first
4. Add fallbackRoute for debugging
```

**Problem**: Navigation working in foreground but not background
```
Solutions:
1. Ensure proper platform setup (AppDelegate.swift, AndroidManifest.xml)
2. Test notification data persistence
3. Verify navigation handler is set up correctly
```

#### Development and Testing Issues

**Problem**: Notifications work in debug but not release mode
```
Solutions:
1. Verify Firebase configuration for release builds
2. Check ProGuard rules (Android)
3. Test with release build signing
4. Verify release Firebase configuration
```

**Problem**: Local notifications work but FCM doesn't
```
Solutions:
1. Check server implementation
2. Verify FCM token is being sent to server
3. Test with Firebase Console message composer
4. Check server authentication and project configuration
```

### Testing Checklist

Before deploying to production:

#### ✅ Development Testing
- [ ] Local notifications work in debug mode
- [ ] FCM notifications work in debug mode  
- [ ] Navigation works from foreground notifications
- [ ] Navigation works from background notifications
- [ ] Navigation works when app is terminated

#### ✅ Platform Testing
- [ ] Test on physical iOS device
- [ ] Test on physical Android device
- [ ] Test on different OS versions
- [ ] Test permission flows on both platforms

#### ✅ Production Testing
- [ ] Test with release builds
- [ ] Test with production Firebase project
- [ ] Test server integration
- [ ] Test token refresh scenarios

### Debug Tips

#### Enable Debug Logging

```dart
// Add this for debugging
FlutterUnifiedMessaging.instance.listen(
  navigationHandler: DefaultNotificationNavigationHandler(
    navigate: (route) {
      print('Navigating to: $route'); // Debug navigation
      context.push(route);
    },
    typeRouteMap: yourRouteMap,
  ),
  onNotificationReceived: (title, body, data) {
    print('Notification received:');
    print('Title: $title');
    print('Body: $body');
    print('Data: $data'); // Debug notification data
  },
);
```

#### Test Navigation Separately

```dart
// Test your navigation handler separately
void testNavigation() {
  final handler = DefaultNotificationNavigationHandler(
    navigate: (route) => print('Would navigate to: $route'),
    typeRouteMap: {'test': '/test'},
    fallbackRoute: '/home',
  );
  
  // Test different data formats
  handler.handleNotificationNavigation({'route': '/direct'});
  handler.handleNotificationNavigation({'type': 'test'});
  handler.handleNotificationNavigation({'unknown': 'data'});
}
```

## Migration Guide

### From firebase_messaging + flutter_local_notifications

If you're currently using the individual packages:

```dart
// OLD: Separate setup
await FirebaseMessaging.instance.requestPermission();
FirebaseMessaging.onMessage.listen((message) {
  // Handle foreground messages
});
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Handle navigation
});

// NEW: Unified setup
await FlutterUnifiedMessaging.instance.initialize();
await FlutterUnifiedMessaging.instance.listen(
  navigationHandler: yourHandler,
  onNotificationReceived: (title, body, data) {
    // Handle foreground messages
  },
);
```

### From Custom Notification Solutions

1. **Replace initialization code** with `FlutterUnifiedMessaging.instance.initialize()`
2. **Replace message listeners** with the unified `listen()` method
3. **Update navigation logic** to use the provided handlers
4. **Migrate notification data** to the standard format

## Best Practices

### 1. Navigation Design

```dart
// ✅ Good: Clear, predictable routes
await service.send(
  title: 'Order Update',
  body: 'Your order has shipped',
  data: {'route': '/orders/123'},
);

// ❌ Avoid: Complex nested navigation logic
await service.send(
  data: {
    'type': 'order',
    'subtype': 'shipped', 
    'action': 'navigate',
    'nested': {'complex': 'data'}
  },
);
```

### 2. Error Handling

```dart
// ✅ Good: Comprehensive error handling
try {
  await FlutterUnifiedMessaging.instance.send(
    title: title,
    body: body,
    data: data,
  );
} catch (e) {
  // Log error
  print('Notification error: $e');
  // Fallback action
  _showInAppMessage(title, body);
}
```

### 3. Performance

```dart
// ✅ Good: Initialize once, use everywhere
class NotificationService {
  static FlutterUnifiedMessaging get _instance => 
      FlutterUnifiedMessaging.instance;
  
  static Future<void> init() async {
    await _instance.initialize();
  }
  
  static Future<void> send(String title, String body) async {
    await _instance.send(title: title, body: body);
  }
}
```

### 4. Testing

```dart
// ✅ Good: Test with mock data
void testNotificationNavigation() {
  final handler = MyNavigationHandler();
  
  // Test various scenarios
  handler.handleNotificationNavigation({'route': '/test'});
  handler.handleNotificationNavigation({'type': 'message'});
  handler.handleNotificationNavigation({});
}
```

## FAQ

### Q: Can I use this with other navigation solutions besides GoRouter?

**A**: Yes! The package is router-agnostic. You can use it with any navigation solution by providing the appropriate `navigate` function.

```dart
// With Navigator 2.0
navigate: (route) => Navigator.of(context).pushNamed(route),

// With GetX
navigate: (route) => Get.toNamed(route),

// With Auto Route
navigate: (route) => context.router.pushPath(route),
```

### Q: How do I handle deep linking with notifications?

**A**: Use the route data to construct proper deep links:

```dart
// Send notification with deep link data
await service.send(
  title: 'New Message',
  body: 'You have a message from John',
  data: {'route': '/chat/user123/conversation456'},
);
```

### Q: Can I customize notification appearance?

**A**: The package handles the underlying notification infrastructure. For custom UI:
- Use the `onNotificationReceived` callback for in-app notifications
- Customize server-side FCM payload for push notifications
- Handle local notification styling through the platform APIs

### Q: Is this package production-ready?

**A**: Yes, the package is designed for production use with:
- Comprehensive error handling
- Memory-efficient singleton pattern
- Extensive testing support
- Platform-specific optimizations

### Q: How do I send notifications from my server?

**A**: Use the FCM token with your server implementation:

```dart
// Get token in your app
final token = await FlutterUnifiedMessaging.instance.getFCMToken();
// Send token to your server

// Server sends FCM message with your notification data
```

## Contributing

We welcome contributions! Please read our contributing guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** with proper tests
4. **Submit a pull request** with clear description

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/flutter_unified_messaging.git

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example app
cd example && flutter run
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 **Documentation**: This README and example code
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_unified_messaging/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/flutter_unified_messaging/discussions)
- 📧 **Email**: support@yourproject.com

---

Made with ❤️ for the Flutter community
