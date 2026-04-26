import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dramus/core/api/api_client.dart';
import 'package:dramus/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'dart:async';

class NotificationService extends ChangeNotifier {
  // Use the singleton instance's dio
  final Dio _dio = ApiClient.instance.dio;
  late final FirebaseMessaging? _messaging;
  late final FlutterLocalNotificationsPlugin? _localNotifications;

  NotificationService() {
    // Tentative d'initialisation sécurisée pour éviter les crashs sur plateformes non supportées (ex: Linux Desktop)
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      _messaging = null;
      debugPrint(
          'NotificationService: Firebase Messaging non supporté sur cette plateforme: $e');
    }

    try {
      _localNotifications = FlutterLocalNotificationsPlugin();
    } catch (e) {
      _localNotifications = null;
      debugPrint(
          'NotificationService: FlutterLocalNotifications non supporté: $e');
    }
  }

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  int _sessionId = 0; // Pour éviter les race conditions lors de la déconnexion

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Stream controller for handling notification taps
  final _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  Future<void> initialize() async {
    if (_messaging == null || _localNotifications == null) {
      debugPrint(
          'NotificationService: Initialisation avortée car les plugins ne sont pas disponibles');
      return;
    }

    try {
      // 1. Request permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');

        // 2. Setup local notifications for foreground display
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings();
        const InitializationSettings initializationSettings =
            InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            if (details.payload != null) {
              final payload = details.payload!;
              // Si le payload ressemble à un ID (String long), on marque comme livré
              if (payload.length > 10) {
                _markDeliveredViaApi(payload);
              }
              _messageStreamController.add(payload);
            }
          },
        );

        // 3. Get FCM Token
        try {
          String? token = await _messaging.getToken();
          if (token != null) {
            debugPrint('FCM Token: $token');
            await _messaging.subscribeToTopic('all_users');
          }
        } catch (e) {
          debugPrint('Error getting FCM token: $e');
        }

        // 4. Handle token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          registerToken(newToken);
        });

        // 5. Foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.data['type'] == 'message' &&
              message.data['messageId'] != null) {
            _markDeliveredViaApi(message.data['messageId']);
          }

          if (message.notification != null) {
            debugPrint(
                'Message also contained a notification: ${message.notification}');
            _showLocalNotification(message);
          }

          // Refresh notifications list if payload suggests it
          fetchNotifications();
        });

        // 6. Background message tap
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('A new onMessageOpenedApp event was published!');
          // Navigator logic can be handled by listening to messageStream in UI
        });
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error during NotificationService initialization: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dramus_channel_id',
      'Dramus Notifications',
      channelDescription: 'Notifications from Dramus App',
      importance: Importance.max,
      priority: Priority.high,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: message.data['messageId'] ?? message.data['type'],
    );
  }

  // --- API Calls ---

  Future<void> registerToken(String token) async {
    try {
      await _dio.post('/api/notifications/register-token',
          data: {'token': token, 'platform': 'android'}); // Default platform
      debugPrint('Token registered successfully');
    } catch (e) {
      debugPrint('Error registering token: $e');
    }
  }

  Future<void> unregisterToken() async {
    if (_messaging == null) return;
    try {
      // Typically we need the token to unregister, or the backend knows the user
      // Assuming backend handles it via auth token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _dio.delete('/api/notifications/unregister-token',
            data: {'token': token});
      }
    } catch (e) {
      debugPrint('Error unregistering token: $e');
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    final capturedSessionId = _sessionId;

    try {
      // Assuming GET /api/notifications returns list
      final response = await _dio.get('/api/notifications');

      if (capturedSessionId != _sessionId) {
        debugPrint(
            'NotificationService: Aborting fetchNotifications - session changed');
        return;
      }
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _notifications =
            data.map((json) => NotificationModel.fromJson(json)).toList();
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/api/notifications/$id/read');
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/api/notifications/read-all');
      _notifications =
          _notifications.map((n) => n.copyWith(read: true)).toList();
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/api/notifications/$id');
      _notifications.removeWhere((n) => n.id == id);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  // Admin only
  Future<void> sendNotification(String title, String body,
      {String? targetUserIds}) async {
    try {
      await _dio.post('/api/notifications/send', data: {
        'title': title,
        'body': body,
        // Add other fields as per backend requirement (e.g., specific users, topics)
        if (targetUserIds != null) 'user_ids': targetUserIds,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.read).length;
  }

  Future<void> _markDeliveredViaApi(String messageId) async {
    try {
      await ApiClient.instance.dio.patch('/api/messages/$messageId/delivered');
      debugPrint('NotificationService: marked $messageId as delivered via API');
    } catch (e) {
      debugPrint('NotificationService: Error marking as delivered: $e');
    }
  }

  void reset() {
    _sessionId++;
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    debugPrint('NotificationService: State reset');
    notifyListeners();
  }
}
