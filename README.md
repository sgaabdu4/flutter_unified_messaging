# Flutter Unified Messaging

Simple local notifications and navigation for Flutter apps.

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

### With Riverpod (Recommended)

**1. Provider setup:**
```dart
/// Provides the notification service with auto-initialization and listener setup
@Riverpod(keepAlive: true)
Future<FlutterUnifiedMessaging> notificationService(Ref ref) async {
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

### 1. Add to pubspec.yaml
```yaml
dependencies:
  flutter_unified_messaging:
    path: ../path/to/flutter_unified_messaging
```

### 2. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Install FlutterFire CLI  
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. Platform Setup

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
