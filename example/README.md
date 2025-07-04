# Flutter Unified Messaging Example

This example demonstrates two different implementation approaches for Flutter Unified Messaging:

## 🚀 Standard Flutter Implementation (Without Riverpod)

Simple and straightforward approach using StatefulWidget:

```dart
// In main()
await FlutterUnifiedMessaging.instance.initialize();
runApp(const MyAppWithoutRiverpod());
```

**Features:**
- Direct service initialization
- Manual setup in `initState()`
- Simple error handling
- Perfect for basic apps or when not using state management

## 🔧 Advanced Riverpod Implementation

Provider-based architecture with automatic initialization:

```dart
// In main()
final container = ProviderContainer();
await CoreInit.init(container);
runApp(UncontrolledProviderScope(
  container: container,
  child: const MyAppWithRiverpod(),
));
```

**Features:**
- Automatic service initialization via providers
- Advanced error handling and loading states
- Proper dependency injection
- Global navigation service
- Perfect for complex apps with state management

## 📋 How to Switch Between Examples

1. **For Standard Flutter**: Uncomment the standard implementation in `main()`
2. **For Riverpod**: Uncomment the Riverpod implementation in `main()`

## 🛠 Setup

1. Replace `DefaultFirebaseOptions.currentPlatform` with your Firebase configuration
2. Add platform-specific setup (see main README.md)
3. Run `flutter pub get`
4. Run the example

## 📱 What This Example Shows

- **Notification Types**: Simple, Route-based, Type-based, Custom data
- **Navigation Patterns**: Direct routes, type mapping, fallback handling
- **State Management**: Both approaches side by side
- **Error Handling**: Comprehensive error states
- **UI Examples**: Multiple screens with navigation

## 🎯 Real-world Usage Patterns

The Riverpod implementation demonstrates production-ready patterns used in real apps, including:

- Service initialization during app startup
- Global navigation handling
- Provider-based dependency injection
- Comprehensive error boundaries
- Loading states and user feedback
