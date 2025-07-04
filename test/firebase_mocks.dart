// ignore_for_file: require_trailing_commas

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

typedef Callback = Function(MethodCall call);

const String kTestToken = 'test_fcm_token_12345';

final MockFirebaseMessaging kMockMessagingPlatform = MockFirebaseMessaging();

Future<T> neverEndingFuture<T>() async {
  // ignore: literal_only_boolean_expressions
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}

Future<void> setupFirebaseMessagingMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase Core mock
  FirebasePlatform.instance = MockFirebasePlatform();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'testApiKey',
      appId: 'testAppId',
      messagingSenderId: 'testSenderId',
      projectId: 'testProjectId',
    ),
  );

  // Set the platform instance to our mock
  FirebaseMessagingPlatform.instance = kMockMessagingPlatform;

  // Mock Platform Interface Methods
  // ignore: invalid_use_of_protected_member
  when(
    kMockMessagingPlatform.delegateFor(app: anyNamed('app')),
  ).thenReturn(kMockMessagingPlatform);
  // ignore: invalid_use_of_protected_member
  when(
    kMockMessagingPlatform.setInitialValues(
      isAutoInitEnabled: anyNamed('isAutoInitEnabled'),
    ),
  ).thenReturn(kMockMessagingPlatform);
}

class MockFirebasePlatform extends FirebasePlatform {
  MockFirebasePlatform() : super();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp(name: name, options: options);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp(
      name: name,
      options: const FirebaseOptions(
        apiKey: 'testApiKey',
        appId: 'testAppId',
        messagingSenderId: 'testSenderId',
        projectId: 'testProjectId',
      ),
    );
  }

  Future<void> resetApp(String name) async {
    // Mock the reset behavior for tests
    return;
  }
}

/// Mock implementation of Firebase App
class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp({String? name, FirebaseOptions? options})
    : super(
        name ?? defaultFirebaseAppName,
        options ??
            const FirebaseOptions(
              apiKey: 'testApiKey',
              appId: 'testAppId',
              messagingSenderId: 'testSenderId',
              projectId: 'testProjectId',
            ),
      );
}

// Platform Interface Mock Classes

// FirebaseMessagingPlatform Mock
class MockFirebaseMessaging extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseMessagingPlatform {
  MockFirebaseMessaging() {
    TestFirebaseMessagingPlatform();
  }

  @override
  bool get isAutoInitEnabled {
    return super.noSuchMethod(
          Invocation.getter(#isAutoInitEnabled),
          returnValue: true,
          returnValueForMissingStub: true,
        )
        as bool;
  }

  @override
  FirebaseMessagingPlatform delegateFor({FirebaseApp? app}) {
    return super.noSuchMethod(
          Invocation.method(#delegateFor, [], {#app: app}),
          returnValue: TestFirebaseMessagingPlatform(),
          returnValueForMissingStub: TestFirebaseMessagingPlatform(),
        )
        as FirebaseMessagingPlatform;
  }

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) {
    return super.noSuchMethod(
          Invocation.method(#setInitialValues, [], {
            #isAutoInitEnabled: isAutoInitEnabled,
          }),
          returnValue: TestFirebaseMessagingPlatform(),
          returnValueForMissingStub: TestFirebaseMessagingPlatform(),
        )
        as FirebaseMessagingPlatform;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() {
    return super.noSuchMethod(
          Invocation.method(#getInitialMessage, []),
          returnValue: Future<RemoteMessage?>.value(null),
          returnValueForMissingStub: Future<RemoteMessage?>.value(null),
        )
        as Future<RemoteMessage?>;
  }

  @override
  Future<void> deleteToken() {
    return super.noSuchMethod(
          Invocation.method(#deleteToken, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<String?> getAPNSToken() {
    return super.noSuchMethod(
          Invocation.method(#getAPNSToken, []),
          returnValue: Future<String?>.value('apns_token'),
          returnValueForMissingStub: Future<String?>.value('apns_token'),
        )
        as Future<String?>;
  }

  @override
  Future<String> getToken({String? vapidKey}) {
    return super.noSuchMethod(
          Invocation.method(#getToken, [], {#vapidKey: vapidKey}),
          returnValue: Future<String>.value(kTestToken),
          returnValueForMissingStub: Future<String>.value(kTestToken),
        )
        as Future<String>;
  }

  @override
  Future<void> setAutoInitEnabled(bool? enabled) {
    return super.noSuchMethod(
          Invocation.method(#setAutoInitEnabled, [enabled]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) {
    return super.noSuchMethod(
          Invocation.method(#setForegroundNotificationPresentationOptions, [], {
            #alert: alert,
            #badge: badge,
            #sound: sound,
          }),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Stream<String> get onTokenRefresh {
    return super.noSuchMethod(
          Invocation.getter(#onTokenRefresh),
          returnValue: Stream<String>.fromIterable([kTestToken]),
          returnValueForMissingStub: Stream<String>.fromIterable([kTestToken]),
        )
        as Stream<String>;
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool providesAppNotificationSettings = false,
    bool provisional = false,
    bool sound = true,
  }) {
    return super.noSuchMethod(
          Invocation.method(#requestPermission, [], {
            #alert: alert,
            #announcement: announcement,
            #badge: badge,
            #carPlay: carPlay,
            #criticalAlert: criticalAlert,
            #providesAppNotificationSettings: providesAppNotificationSettings,
            #provisional: provisional,
            #sound: sound,
          }),
          returnValue: Future<NotificationSettings>.value(
            const NotificationSettings(
              alert: AppleNotificationSetting.enabled,
              announcement: AppleNotificationSetting.enabled,
              authorizationStatus: AuthorizationStatus.authorized,
              badge: AppleNotificationSetting.enabled,
              carPlay: AppleNotificationSetting.enabled,
              lockScreen: AppleNotificationSetting.enabled,
              notificationCenter: AppleNotificationSetting.enabled,
              showPreviews: AppleShowPreviewSetting.always,
              timeSensitive: AppleNotificationSetting.enabled,
              criticalAlert: AppleNotificationSetting.enabled,
              sound: AppleNotificationSetting.enabled,
              providesAppNotificationSettings:
                  AppleNotificationSetting.disabled,
            ),
          ),
          returnValueForMissingStub: Future<NotificationSettings>.value(
            const NotificationSettings(
              alert: AppleNotificationSetting.enabled,
              announcement: AppleNotificationSetting.enabled,
              authorizationStatus: AuthorizationStatus.authorized,
              badge: AppleNotificationSetting.enabled,
              carPlay: AppleNotificationSetting.enabled,
              lockScreen: AppleNotificationSetting.enabled,
              notificationCenter: AppleNotificationSetting.enabled,
              showPreviews: AppleShowPreviewSetting.always,
              timeSensitive: AppleNotificationSetting.enabled,
              criticalAlert: AppleNotificationSetting.enabled,
              sound: AppleNotificationSetting.enabled,
              providesAppNotificationSettings:
                  AppleNotificationSetting.disabled,
            ),
          ),
        )
        as Future<NotificationSettings>;
  }

  @override
  Future<void> subscribeToTopic(String? topic) {
    return super.noSuchMethod(
          Invocation.method(#subscribeToTopic, [topic]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> unsubscribeFromTopic(String? topic) {
    return super.noSuchMethod(
          Invocation.method(#unsubscribeFromTopic, [topic]),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

class TestFirebaseMessagingPlatform extends FirebaseMessagingPlatform {
  TestFirebaseMessagingPlatform() : super();
}
