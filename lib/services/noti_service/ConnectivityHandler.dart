import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';

class ConnectivityHandler {
  final FlutterLocalNotificationsPlugin _notifications;
  final DatabaseReference _dbRef;

  Timer? _timer;
  bool _isActive = false;
  String? _currentBraceletId;
  String _currentSound = 'chime';

  static const int NOTIFICATION_ID = 1005;
  static const int INTERVAL_SECONDS =
      60; // Less frequent - every minute for connectivity issues

  ConnectivityHandler(this._notifications, this._dbRef);

  Future<void> initialize() async {
    print('📶 ConnectivityHandler initialized');
  }

  bool get isActive => _timer?.isActive ?? false;

  void startNotifications({
    required String braceletId,
    required String sound,
  }) {
    // Stop any existing timer first
    stopNotifications();

    _currentBraceletId = braceletId;
    _currentSound = sound;
    _isActive = true;

    print(
        '📶 Starting CONNECTIVITY notifications (every ${INTERVAL_SECONDS}s)');

    // Send first notification immediately
    _sendNotification();

    // Start periodic notifications
    _timer = Timer.periodic(Duration(seconds: INTERVAL_SECONDS), (timer) {
      if (_isActive && _currentBraceletId != null) {
        _sendNotification();
      } else {
        print('📶 Connectivity timer stopped - conditions not met');
        timer.cancel();
      }
    });
  }

  void stopNotifications() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      print('📶 Connectivity notifications stopped');
    }

    _isActive = false;

    // Cancel any existing notification
    _notifications.cancel(NOTIFICATION_ID);
  }

  Future<void> _sendNotification() async {
    if (_currentBraceletId == null) {
      print('📶 Cannot send connectivity notification - no bracelet ID');
      return;
    }

    const String title = '📶 Connection Alert';
    const String body =
        'Bracelet connection is unstable. Please check the device.';

    print('📶 Sending CONNECTIVITY notification');

    // Create notification for connectivity issues
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'connectivity_channel',
      'Connection Alerts',
      channelDescription: 'Notifications for connection issues',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      ongoing: false,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF9C27B0), // Purple LED
      ledOnMs: 300,
      ledOffMs: 700,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound(_getSoundFile()),
      vibrationPattern:
          Int64List.fromList([0, 200, 100, 200]), // Short vibration
    );

    NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      NOTIFICATION_ID,
      title,
      body,
      platformDetails,
      payload: 'connectivity|${_currentBraceletId}',
    );

    // Save to database
    await _saveToDatabase(title, body);
  }

  // Method to send one-time connectivity alerts
  Future<void> sendConnectivityAlert({
    required String title,
    required String body,
    required String braceletId,
    required String sound,
  }) async {
    print('📶 Sending one-time connectivity alert');

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'connectivity_channel',
      'Connection Alerts',
      channelDescription: 'Notifications for connection issues',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      ongoing: false,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF9C27B0), // Purple LED
      sound: RawResourceAndroidNotificationSound(_getSoundFileForType(sound)),
      vibrationPattern: Int64List.fromList([0, 300, 150, 300]),
    );

    NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      NOTIFICATION_ID + 100, // Different ID for one-time alerts
      title,
      body,
      platformDetails,
      payload: 'connectivity_alert|$braceletId',
    );

    // Save to database
    try {
      await _dbRef.child("notifications/connectivity_alerts").push().set({
        'bracelet_id': braceletId,
        'type': 'connectivity_alert',
        'title': title,
        'body': body,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
        'sound': sound,
        'priority': 'low',
      });

      print('📶 Connectivity alert saved to database');
    } catch (e) {
      print('📶 Error saving connectivity alert to database: $e');
    }
  }

  Future<void> _saveToDatabase(String title, String body) async {
    try {
      await _dbRef.child("notifications/connectivity_alerts").push().set({
        'bracelet_id': _currentBraceletId,
        'type': 'connectivity',
        'title': title,
        'body': body,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
        'sound': _currentSound,
        'priority': 'low',
      });

      print('📶 Connectivity notification saved to database');
    } catch (e) {
      print('📶 Error saving to database: $e');
    }
  }

  String _getSoundFile() {
    return _getSoundFileForType(_currentSound);
  }

  String _getSoundFileForType(String soundType) {
    switch (soundType) {
      case 'urgent':
        return 'notification_urgent';
      case 'alert':
        return 'notification_alert';
      case 'chime':
        return 'notification_chime';
      case 'beep':
        return 'notification_beep';
      case 'gentle':
        return 'notification_gentle';
      default:
        return 'notification_gentle'; // Default to gentle for connectivity
    }
  }

  void dispose() {
    stopNotifications();
    _currentBraceletId = null;
    print('📶 ConnectivityHandler disposed');
  }

  Map<String, dynamic> getStatus() {
    return {
      'is_active': isActive,
      'bracelet_id': _currentBraceletId,
      'sound': _currentSound,
      'interval_seconds': INTERVAL_SECONDS,
      'priority': 'low',
    };
  }
}
