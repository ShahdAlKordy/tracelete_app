import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';

class BatteryHandler {
  final FlutterLocalNotificationsPlugin _notifications;
  final DatabaseReference _dbRef;
  
  Timer? _timer;
  bool _isActive = false;
  String? _currentBraceletId;
  String _currentSound = 'beep';
  int _lastBatteryLevel = 100;
  
  static const int NOTIFICATION_ID = 1004;
  static const int LOW_BATTERY_THRESHOLD = 20;
  static const int CRITICAL_BATTERY_THRESHOLD = 10;
  static const int INTERVAL_SECONDS = 300; // Check every 5 minutes for battery

  BatteryHandler(this._notifications, this._dbRef);

  Future<void> initialize() async {
    print('🔋 BatteryHandler initialized');
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
    
    print('🔋 Starting BATTERY monitoring (every ${INTERVAL_SECONDS}s)');
    
    // Start periodic battery check
    _timer = Timer.periodic(Duration(seconds: INTERVAL_SECONDS), (timer) {
      if (_isActive && _currentBraceletId != null) {
        _checkBatteryStatus();
      } else {
        print('🔋 Battery timer stopped - conditions not met');
        timer.cancel();
      }
    });
  }

  void stopNotifications() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      print('🔋 Battery notifications stopped');
    }
    
    _isActive = false;
    
    // Cancel any existing notification
    _notifications.cancel(NOTIFICATION_ID);
  }

  Future<void> _checkBatteryStatus() async {
    if (_currentBraceletId == null) {
      print('🔋 Cannot check battery - no bracelet ID');
      return;
    }

    try {
      // Get battery level from database
      DataSnapshot snapshot = await _dbRef
          .child("bracelets/${_currentBraceletId}/battery_level")
          .get();

      if (snapshot.exists) {
        int batteryLevel = snapshot.value as int? ?? 100;
        _lastBatteryLevel = batteryLevel;

        print('🔋 Current battery level: $batteryLevel%');

        // Send notification based on battery level
        if (batteryLevel <= CRITICAL_BATTERY_THRESHOLD) {
          await _sendCriticalBatteryNotification(batteryLevel);
        } else if (batteryLevel <= LOW_BATTERY_THRESHOLD) {
          await _sendLowBatteryNotification(batteryLevel);
        }
      }
    } catch (e) {
      print('🔋 Error checking battery status: $e');
    }
  }

  // Method to send battery alerts from external calls
  Future<void> sendBatteryAlert({
    required int batteryLevel,
    required String braceletId,
    required String sound,
  }) async {
    _lastBatteryLevel = batteryLevel;
    _currentBraceletId = braceletId;
    _currentSound = sound;

    print('🔋 Sending battery alert for level: $batteryLevel%');

    if (batteryLevel <= CRITICAL_BATTERY_THRESHOLD) {
      await _sendCriticalBatteryNotification(batteryLevel);
    } else if (batteryLevel <= LOW_BATTERY_THRESHOLD) {
      await _sendLowBatteryNotification(batteryLevel);
    }
  }

  Future<void> _sendLowBatteryNotification(int batteryLevel) async {
    final String title = '🔋 Low Battery Warning';
    final String body = 'Bracelet battery is low ($batteryLevel%). Please charge soon.';

    print('🔋 Sending LOW BATTERY notification ($batteryLevel%)');

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'battery_channel',
      'Battery Alerts',
      channelDescription: 'Notifications for battery status',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      ongoing: false,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF9800), // Orange LED for low battery
      ledOnMs: 500,
      ledOffMs: 1000,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound(_getSoundFile()),
      vibrationPattern: Int64List.fromList([0, 300, 200, 300, 200, 300]),
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      NOTIFICATION_ID,
      title,
      body,
      platformDetails,
      payload: 'low_battery|${_currentBraceletId}|$batteryLevel',
    );

    await _saveToDatabase(title, body, batteryLevel, 'low');
  }

  Future<void> _sendCriticalBatteryNotification(int batteryLevel) async {
    final String title = '🔋 Critical Battery Alert!';
    final String body = 'Bracelet battery is critically low ($batteryLevel%)! Charge immediately!';

    print('🔋 Sending CRITICAL BATTERY notification ($batteryLevel%)');

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'battery_channel',
      'Battery Alerts',
      channelDescription: 'Notifications for battery status',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      ongoing: true, // Make critical battery persistent
      autoCancel: false,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000), // Red LED for critical battery
      ledOnMs: 200,
      ledOffMs: 200,
      fullScreenIntent: true, // Show as full screen for critical
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('notification_urgent'),
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500]),
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      NOTIFICATION_ID,
      title,
      body,
      platformDetails,
      payload: 'critical_battery|${_currentBraceletId}|$batteryLevel',
    );

    await _saveToDatabase(title, body, batteryLevel, 'critical');
  }

  Future<void> _saveToDatabase(String title, String body, int batteryLevel, String severity) async {
    try {
      await _dbRef.child("notifications/battery_alerts").push().set({
        'bracelet_id': _currentBraceletId,
        'type': 'battery',
        'title': title,
        'body': body,
        'battery_level': batteryLevel,
        'severity': severity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
        'sound': _currentSound,
        'priority': severity == 'critical' ? 'high' : 'medium',
      });
      
      print('🔋 Battery notification saved to database');
    } catch (e) {
      print('🔋 Error saving to database: $e');
    }
  }

  String _getSoundFile() {
    switch (_currentSound) {
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
        return 'notification_beep'; // Default to beep for battery
    }
  }

  void dispose() {
    stopNotifications();
    _currentBraceletId = null;
    print('🔋 BatteryHandler disposed');
  }

  Map<String, dynamic> getStatus() {
    return {
      'is_active': isActive,
      'bracelet_id': _currentBraceletId,
      'sound': _currentSound,
      'interval_seconds': INTERVAL_SECONDS,
      'last_battery_level': _lastBatteryLevel,
      'low_threshold': LOW_BATTERY_THRESHOLD,
      'critical_threshold': CRITICAL_BATTERY_THRESHOLD,
      'priority': 'medium',
    };
  }

  // Get current battery level
  int get currentBatteryLevel => _lastBatteryLevel;

  // Check if battery is low
  bool get isBatteryLow => _lastBatteryLevel <= LOW_BATTERY_THRESHOLD;

  // Check if battery is critical
  bool get isBatteryCritical => _lastBatteryLevel <= CRITICAL_BATTERY_THRESHOLD;
}