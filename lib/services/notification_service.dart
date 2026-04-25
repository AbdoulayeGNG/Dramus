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
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Stream controller for handling notification taps
  final _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  Future<void> initialize() async {
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
            _messageStreamController.add(details.payload!);
          }
        },
      );

      // 3. Get FCM Token
      try {
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await registerToken(token);
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
        debugPrint('Message data: \${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: \${message.notification}');
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
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
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
      payload: message.data['type'], // Example payload
    );
  }

  // --- API Calls ---

  Future<void> registerToken(String token) async {
    try {
      await _dio.post('/api/notifications/register-token',
          data: {'fcm_token': token});
      debugPrint('Token registered successfully');
    } catch (e) {
      debugPrint('Error registering token: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      // Typically we need the token to unregister, or the backend knows the user
      // Assuming backend handles it via auth token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _dio.post('/api/notifications/unregister-token',
            data: {'fcm_token': token});
      }
    } catch (e) {
      debugPrint('Error unregistering token: $e');
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Assuming GET /api/notifications returns list
      final response = await _dio.get('/api/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
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

  Future<void> markAsRead(int id) async {
    try {
      await _dio.put('/api/notifications/$id/read');
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
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
      await _dio.put(
          '/api/notifications/read-all'); // Assuming this endpoint based on convention
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      // If the endpoint was really /notifications/{id}/read-all, we'd need an ID.
      // But usually it's global for user.
    }
  }

  Future<void> deleteNotification(int id) async {
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
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
}
