# Flutter Unified Messaging

Simple local notifications and navigation for Flutter apps.

## TL;DR

What happens when you tap a notification
- If the payload has `data.route: '/somewhere'` → we navigate to that route.
- Else if it has `data.type: 'something'` → we look it up in your `typeRouteMap` and navigate there.
- Else (no route/type) → we use your `fallbackRoute` if you set one.

How to make it work
1) Initialize Firebase → call `FlutterUnifiedMessaging.instance.initialize()`
2) After your app has a navigator, call `listen(...)` and pass a navigation handler
3) Get the device token with `getFCMToken()` and send it to your backend for FCM
4) Use `send(...)` to show local notifications

Important
- `send(...)` only shows a local notification. It does not send push.
- For FCM push, put your navigation info inside the FCM message `data` (not inside `notification`).

Examples
- Local (direct route): `send(title: 'Hi', body: '...', data: {'route': '/inbox'})`
- FCM JSON (direct route): `{ "message": { "token": "<device>", "notification": {"title":"Hi","body":"..."}, "data": { "route": "/inbox" } } }`
- FCM JSON (type mapping): `{ "message": { "token": "<device>", "notification": {"title":"Hi","body":"..."}, "data": { "type": "appointment" } } }`

What is `typeRouteMap`?
- It’s a simple dictionary you pass to `DefaultNotificationNavigationHandler` that translates a `data.type` into a route.
- Example:
  ```dart
  DefaultNotificationNavigationHandler(
    navigate: (route) => navigatorKey.currentState?.pushNamed(route),
    typeRouteMap: {
      'appointment': '/appointments',
      'alert': '/alerts',
    },
    fallbackRoute: '/inbox',
  )
  ```
- With this config, a payload like `data: { 'type': 'appointment' }` will navigate to `/appointments`.

Do this in order:
- 1) Initialize Firebase, then call `FlutterUnifiedMessaging.instance.initialize()`.
- 2) After your app has a navigator, call `listen(...)` with a `DefaultNotificationNavigationHandler`.
- 3) Call `getFCMToken()` and send it to your backend to receive server push.
- 4) Use `send(title, body, data, actions)` for local notifications.

Local vs FCM
- `send(...)` triggers a local notification only.
- FCM push requires `listen(...)` + a valid device token + your server sending to that token.

## 🚀 Quick Start

### Without Riverpod (Simple)

```dart
// 1. Initialize Firebase in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

// 2. Initialize notifications
await FlutterUnifiedMessaging.instance.initialize();

// 3. Send local notifications
await FlutterUnifiedMessaging.instance.send(
  title: 'Reminder',
  body: 'Time for your appointment!',
  data: {'route': '/appointments'},
);
```

Note about local vs FCM
- The snippet above only triggers a local notification on the device. It does not send or receive FCM by itself.
- To receive FCM push messages as well, you must call `listen(...)`, fetch the device token via `getFCMToken()`, and have your server send to that token.

Receive FCM push (minimal)
```dart
// After initialize(), wire listeners (do this when you have navigation context)
await FlutterUnifiedMessaging.instance.listen(
  navigationHandler: DefaultNotificationNavigationHandler(
    navigate: (route) => context.push(route),
  ),
  onTokenRefresh: (token) {
    // Upload refreshed token to your backend
  },
);

// Obtain the current FCM token and send it to your server
final token = await FlutterUnifiedMessaging.instance.getFCMToken();
// await api.registerPushToken(token);
```

What happens after listen()
- Foreground FCM: shown as a local notification; tap is routed by your navigation handler.
- Background/terminated FCM with notification payload: shown by the OS; tap opens the app and is routed.
- Data-only background messages: not shown by default; either include a notification payload from your server, or handle via a background message handler if you want to display one.
- Cold start (app not running): handled via FCM `getInitialMessage()` and local notifications launch details; taps still route.

## Tap-to-Navigate (FCM and Local)

Yes—tapping a notification (from FCM or a local notification) will navigate to the correct route if your payload contains either a `route` or a `type` that maps to a route.

Requirements
- You called `FlutterUnifiedMessaging.instance.listen(...)` after initialization.
- You passed a `DefaultNotificationNavigationHandler` with:
  - `navigate: (route) => /* perform your navigation */`
  - optional `typeRouteMap` and `fallbackRoute`.

Payload contract
- Direct route (highest priority): `{ "route": "/appointments/123" }`
- Type mapping: `{ "type": "appointment" }` and you define `{ 'appointment': '/appointments' }` in `typeRouteMap`.
- Fallback route: used only if no route is provided and no mapping exists but there is some data; otherwise nothing happens.

Resolution order
1) Use `data['route']` if present.
2) Else, use `typeRouteMap[data['type']]` if provided.
3) Else, use `fallbackRoute` (when non-empty and payload has data).

Works for both sources
- Local notification taps: payload is the `data` you passed to `send(...)`.
- FCM taps: payload is `RemoteMessage.data` from your server’s FCM message.

Cold start behavior
- If the app was terminated, the package checks the initial FCM message and local notification launch details and routes accordingly after `listen()` is set up.

### Full example (Navigator + named routes)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_unified_messaging/flutter_unified_messaging.dart';

// A global navigator key so we can navigate without a BuildContext
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterUnifiedMessaging.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Wire listeners after the first frame so navigatorKey is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FlutterUnifiedMessaging.instance.listen(
        navigationHandler: DefaultNotificationNavigationHandler(
          // Route navigation priority: data['route'] > data['type'] mapping > fallback
          navigate: (route) => navigatorKey.currentState?.pushNamed(route),
          typeRouteMap: {
            'appointment': '/appointments',
            'alert': '/alerts',
          },
          fallbackRoute: '/inbox',
        ),
        onNotificationReceived: (title, body, data) {
          // Optional: foreground FCM received; already shown as local notification
        },
        onTokenRefresh: (token) {
          // Optional: upload refreshed token to your backend
        },
      );

      // Get the current token and register with your backend to receive FCM
      final token = await FlutterUnifiedMessaging.instance.getFCMToken();
      // await api.registerPushToken(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/appointments': (_) => const AppointmentsPage(),
        '/alerts': (_) => const AlertsPage(),
        '/inbox': (_) => const InboxPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await FlutterUnifiedMessaging.instance.send(
                  title: 'Reminder',
                  body: 'Time for your appointment! ',
                  // Route takes priority if provided
                  data: {'route': '/appointments'},
                );
              },
              child: const Text('Send local notification'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await FlutterUnifiedMessaging.instance.send(
                  title: 'New Alert',
                  body: 'Please review',
                  // If no route provided, type mapping will be used
                  data: {'type': 'alert'},
                );
              },
              child: const Text('Send local (type-based) notification'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Appointments')));
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Alerts')));
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Inbox')));
}
```

Example FCM payload (server → device)
- Include a notification block for background display, and data for routing:

```json
{
  "message": {
    "token": "<device-token>",
    "notification": { "title": "Your appointment", "body": "Starts soon" },
    "data": { "type": "appointment", "route": "/appointments" },
    "android": { "priority": "HIGH" },
    "apns": { "headers": { "apns-priority": "10" } }
  }
}
```

### With Riverpod (Recommended)

**1. Provider setup:**
```dart
/// Provides the notification service with auto-initialization and listener setup
@Riverpod(keepAlive: true)
Future<FlutterUnifiedMessaging> notificationService(Ref ref) async {
  final service = FlutterUnifiedMessaging.instance;

  // Initialize the notification service
  await service.initialize();
  await service.getFCMToken();

  // Set up listeners with navigation handling
  final context = NavigationService.navigatorKey.currentContext;
  if (context != null) {
    await service.listen(
      navigationHandler: DefaultNotificationNavigationHandler(
        navigate: (route) => context.push(route),
        typeRouteMap: {
          'appointment': '/appointments',
          'reminder': '/reminders',
          'alert': '/alerts',
          'test': '/onboarding',
        },
        fallbackRoute: '/notifications',
      ),
      onNotificationReceived: (title, body, data) {
        // FCM messages received while app is in foreground are automatically
        // shown as local notifications by the handler
      },
    );
  }

  return service;
}
```

**2. Usage in widgets:**
```dart
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _sendTestNotification(ref),
          child: const Text('Send Test Notification'),
        ),
      ),
    );
  }

  Future<void> _sendTestNotification(WidgetRef ref) async {
    final notificationService = await ref.read(notificationServiceProvider.future);
    
    await notificationService.send(
      title: 'Hello from SmartMum!',
      body: 'This is a test notification',
      data: {'type': 'test', 'route': '/onboarding'},
    );
  }
}
```

**That's it!**

## Installation & Setup

This package wraps Firebase Cloud Messaging (push) and flutter_local_notifications (local) with a simple API. Follow these steps to wire up both platforms correctly.

### 1) Add dependencies
```yaml
dependencies:
  flutter_unified_messaging: ^1.1.0 # or a local path during development
  firebase_core: ^3.0.0 # required to initialize Firebase
  # Your app may already have these as transitive; adding explicitly is OK
  firebase_messaging: ^15.2.9
  flutter_local_notifications: ^19.3.0
```

Notes
- This package calls requestPermission() for FCM and local notifications during `initialize()`.
- You may pin newer versions (e.g., firebase_messaging 16.x, flutter_local_notifications 19.4.x) if your project supports them.

### 2) Configure Firebase (Android + iOS)
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Install FlutterFire CLI  
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates and wires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) into your app projects.

### 3) Android setup

Add permissions and receivers to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Required on Android 13+ to show notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application
    android:label="@string/app_name"
    android:name="io.flutter.app.FlutterApplication"
    android:icon="@mipmap/ic_launcher">

    <!-- For notification action buttons (flutter_local_notifications) -->
    <receiver
        android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />

    <!-- Other existing entries -->
  </application>
```

Set a notification icon used by local notifications. Our code references `@drawable/ic_notification`.
- In Android Studio, use Image Asset Studio to create a white, transparent PNG named `ic_notification` under `app/src/main/res/drawable/`.
- Alternatively, add your own monochrome icon at `android/app/src/main/res/drawable/ic_notification.png`.

Gradle and SDK notes
- Ensure `compileSdk` is at least 35 (required by flutter_local_notifications ≥19).
- If you schedule notifications or use advanced features, follow flutter_local_notifications README for desugaring and additional manifest entries.

Notification channel
- This package programmatically creates the `unified_messaging_channel` with Importance.max; you don’t need to add it manually.

### 4) iOS setup

Enable capabilities in Xcode (Runner target → Signing & Capabilities):
- Add “Push Notifications”.
- Add “Background Modes” → enable “Background fetch” and “Remote notifications”.

Update `AppDelegate.swift` to allow local notifications to display while the app is foregrounded:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Allow foreground notifications to display
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

FCM via APNs
- Link APNs to FCM (Apple Developer → Keys/Identifiers/Profiles; upload the key to Firebase Console).
- Use a real device for iOS testing; simulators do not receive push notifications.
- Do not disable Firebase method swizzling. Ensure `FirebaseAppDelegateProxyEnabled` is not set to `NO` in your Info.plist.

Optional: Notification images on iOS
- If you want to display images from FCM payloads, add a Notification Service Extension and add `pod 'Firebase/Messaging'` to that target. See FlutterFire “Allowing Notification Images”.

### 5) Background messaging

This package registers a background handler internally. If you create your own, it must be a top-level function annotated with `@pragma('vm:entry-point')` and registered via `FirebaseMessaging.onBackgroundMessage(...)`.

Example:
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // handle background message
}

void main() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // ...initialize Firebase & runApp
}
```

References
- Firebase Messaging overview: https://firebase.flutter.dev/docs/messaging/overview
- iOS/APNs integration: https://firebase.flutter.dev/docs/messaging/apple-integration
- flutter_local_notifications setup: https://pub.dev/packages/flutter_local_notifications

**Android:** Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**iOS:** Follow these steps for proper push notification setup:

1. **Enable Push Notifications in Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your project → Target → "Signing & Capabilities"
   - Click "+ Capability" → Search for "Push Notifications"
   - Add the capability

2. **Enable Background Modes (iOS only):**
   - In the same "Signing & Capabilities" tab
   - Click "+ Capability" → Search for "Background Modes"
   - Enable both "Background fetch" and "Remote notifications"

3. **Update AppDelegate.swift:**
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
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

4. **Apple Developer Account Setup** (for production):
   - Create APNs Key in Apple Developer Console
   - Register your App Identifier with Push Notifications enabled
   - Create Provisioning Profile
   - Upload APNs Key to Firebase Console

   *For detailed steps, see: https://firebase.flutter.dev/docs/messaging/apple-integration/*

## API

### FlutterUnifiedMessaging
- `initialize()` - Initialize the service
- `listen({navigationHandler})` - Set up navigation
- `send({title, body, data})` - Send local notification

### DefaultNotificationNavigationHandler
- `navigate` - Your navigation function (required)
- `typeRouteMap` - Map types to routes (optional)
- `fallbackRoute` - Default route (optional)

---

*Need server push notifications? Check the full documentation.*
