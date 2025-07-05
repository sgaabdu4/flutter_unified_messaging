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

**iOS:** Add to `ios/Runner/AppDelegate.swift`:
```swift
import firebase_messaging

// In application didFinishLaunchingWithOptions:
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

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
