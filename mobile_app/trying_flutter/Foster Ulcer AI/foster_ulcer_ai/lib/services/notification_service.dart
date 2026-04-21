import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef DeviceTokenSyncCallback = Future<void> Function(String token);

const AndroidNotificationChannel _foregroundChannel = AndroidNotificationChannel(
  'foster_ulcer_push',
  'Foster Ulcer Alerts',
  description: 'Urgent wound care and workflow notifications.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may already be initialized in the background isolate.
  }
}

class AppPushNotification {
  const AppPushNotification({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;

  String? get type => _readValue('type');
  String? get caseId => _readValue('case_id');
  String? get taskId => _readValue('task_id');
  String? get patientId => _readValue('patient_id');

  String? _readValue(String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String encode() => jsonEncode({
        'title': title,
        'body': body,
        'data': data,
      });

  static AppPushNotification fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    return AppPushNotification(
      title: notification?.title ?? data['title']?.toString() ?? 'Notification',
      body: notification?.body ?? data['body']?.toString() ?? '',
      data: data,
    );
  }

  static AppPushNotification? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      return AppPushNotification(
        title: map['title']?.toString() ?? 'Notification',
        body: map['body']?.toString() ?? '',
        data: map['data'] is Map ? Map<String, dynamic>.from(map['data']) : <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StreamController<AppPushNotification> _foregroundMessages = StreamController<AppPushNotification>.broadcast();
  final StreamController<AppPushNotification> _openedMessages = StreamController<AppPushNotification>.broadcast();

  FirebaseMessaging? _messaging;
  DeviceTokenSyncCallback? _tokenSyncCallback;
  bool _initialized = false;
  String? _currentToken;
  AppPushNotification? _pendingOpenedMessage;

  Stream<AppPushNotification> get foregroundMessages => _foregroundMessages.stream;
  Stream<AppPushNotification> get openedMessages => _openedMessages.stream;
  String? get currentToken => _currentToken;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Push notifications disabled: Firebase initialization failed: $error');
      return;
    }

    _messaging = FirebaseMessaging.instance;
    final messaging = _messaging;
    if (messaging == null) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermissions();
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _publishOpened(AppPushNotification.fromRemoteMessage(initialMessage));
    }

    await _captureToken();
    messaging.onTokenRefresh.listen((token) async {
      await _storeAndSyncToken(token);
    });

    _initialized = true;
  }

  Future<void> attachTokenSync(DeviceTokenSyncCallback callback) async {
    _tokenSyncCallback = callback;
    final token = _currentToken;
    if (token != null) {
      await callback(token);
    }
  }

  AppPushNotification? takePendingOpenedMessage() {
    final message = _pendingOpenedMessage;
    _pendingOpenedMessage = null;
    return message;
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final message = AppPushNotification.fromPayload(response.payload);
        if (message != null) {
          _publishOpened(message);
        }
      },
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_foregroundChannel);
  }

  Future<void> _requestPermissions() async {
    final messaging = _messaging;
    if (messaging == null) return;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('Push permission status: ${settings.authorizationStatus}');

    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _captureToken() async {
    final messaging = _messaging;
    if (messaging == null) return;

    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _storeAndSyncToken(token);
      }
    } catch (error) {
      debugPrint('Failed to read FCM token: $error');
    }
  }

  Future<void> _storeAndSyncToken(String token) async {
    _currentToken = token;
    final callback = _tokenSyncCallback;
    if (callback == null) return;
    try {
      await callback(token);
    } catch (error) {
      debugPrint('Failed to sync FCM token: $error');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage remoteMessage) async {
    final message = AppPushNotification.fromRemoteMessage(remoteMessage);
    _foregroundMessages.add(message);

    final android = remoteMessage.notification?.android;
    final apple = remoteMessage.notification?.apple;
    if (remoteMessage.notification == null && remoteMessage.data.isEmpty) {
      return;
    }

    await _localNotifications.show(
      id: remoteMessage.hashCode,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _foregroundChannel.id,
          _foregroundChannel.name,
          channelDescription: _foregroundChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: apple?.subtitle,
        ),
      ),
      payload: message.encode(),
    );
  }

  void _handleOpenedMessage(RemoteMessage remoteMessage) {
    _publishOpened(AppPushNotification.fromRemoteMessage(remoteMessage));
  }

  void _publishOpened(AppPushNotification message) {
    _pendingOpenedMessage = message;
    _openedMessages.add(message);
  }
}
