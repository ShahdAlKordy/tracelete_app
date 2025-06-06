import 'dart:ui';
import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Timers for periodic notifications
  Timer? _safeZoneExitTimer;
  Timer? _stationaryTimer;
  Timer? _redZoneTimer; // ✅ Added Red Zone timer

  // Status tracking
  bool _isOutsideSafeZone = false;
  bool _isStationary = false;
  bool _isConnected = false;
  bool _isInRedZone = false; // ✅ Added Red Zone status
  DateTime? _lastMovementTime;
  String? _currentBraceletId;

  // Previous states to detect changes
  bool _previousOutsideSafeZone = false;
  bool _previousStationary = false;
  bool _previousConnected = false;
  bool _previousInRedZone = false; // ✅ Added previous Red Zone status

  // Initialize notifications
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFCM();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _initializeFCM() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> saveFCMToken(String braceletId) async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      print("FCM Token: $fcmToken");

      if (fcmToken != null) {
        await _dbRef
            .child("bracelets/$braceletId/user_info/fcm_token")
            .set(fcmToken);
        print("FCM Token saved successfully");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  // ✅ Updated with Red Zone status
  void updateLocationStatus({
    required String braceletId,
    required bool isInsideSafeZone,
    required bool isStationary,
    required bool isConnected,
    required bool isInRedZone, // ✅ Added Red Zone parameter
  }) {
    _currentBraceletId = braceletId;

    // Save previous states
    _previousOutsideSafeZone = _isOutsideSafeZone;
    _previousStationary = _isStationary;
    _previousConnected = _isConnected;
    _previousInRedZone = _isInRedZone; // ✅ Save previous Red Zone status

    // Update current states
    _isOutsideSafeZone = !isInsideSafeZone;
    _isStationary = isStationary;
    _isConnected = isConnected;
    _isInRedZone = isInRedZone; // ✅ Update Red Zone status

    print('=== Notification Status Update ===');
    print('Bracelet ID: $braceletId');
    print('Is Connected: $isConnected');
    print('Inside Safe Zone: $isInsideSafeZone');
    print('Is Stationary: $isStationary');
    print('Is In Red Zone: $isInRedZone'); // ✅ Print Red Zone status
    print('Previous Connected: $_previousConnected');
    print('Current Connected: $_isConnected');
    print('Previous Outside: $_previousOutsideSafeZone');
    print('Current Outside: $_isOutsideSafeZone');
    print('Previous Stationary: $_previousStationary');
    print('Current Stationary: $_isStationary');
    print('Previous In Red Zone: $_previousInRedZone'); // ✅ Print previous Red Zone status
    print('Current In Red Zone: $_isInRedZone');

    // Apply new logic
    _applyNotificationLogic();
  }

  // ✅ Updated notification logic with Red Zone handling
  void _applyNotificationLogic() {
    // Stop all notifications first
    _stopAllNotifications();

    // Check connection first
    if (!_isConnected) {
      print('🔴 Bracelet is NOT CONNECTED - No notifications will be sent');
      return;
    }

    print('✅ Bracelet is CONNECTED - Checking other conditions...');

    // ✅ Priority 1: Red Zone (Most Critical)
    if (_isInRedZone) {
      print('🔥 IN RED ZONE - Starting RED ZONE notifications (every 15 seconds)');
      _startRedZoneNotifications();
      return; // Exit early - Red Zone has highest priority
    }

    // Priority 2: Safe Zone violations
    if (_isOutsideSafeZone) {
      print('🔴 Outside Safe Zone - Starting safe zone exit notifications');
      _startSafeZoneExitNotifications();

      if (_isStationary) {
        print('🟠 Also Stationary - Starting stationary notifications');
        _startStationaryNotifications();
      }
    } else {
      // Inside safe zone
      if (_isStationary) {
        print('🟠 Inside Safe Zone but Stationary - Starting stationary notifications only');
        _startStationaryNotifications();
      } else {
        print('🟢 Inside Safe Zone and Moving - No notifications needed');
      }
    }

    print('=== Notification Logic Applied ===');
  }

  // Stop all notifications
  void _stopAllNotifications() {
    _stopSafeZoneExitNotifications();
    _stopStationaryNotifications();
    _stopRedZoneNotifications(); // ✅ Stop Red Zone notifications
  }

  // ✅ Start Red Zone notifications (every 15 seconds)
  void _startRedZoneNotifications() {
    _stopRedZoneNotifications();

    if (!_isConnected) {
      print('🔥 Cannot start Red Zone notifications - bracelet not connected');
      return;
    }

    // Send first notification immediately
    _sendRedZoneNotification();

    // Start timer for periodic notifications (every 15 seconds)
    _redZoneTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (!_isConnected) {
        print('🔥 Red Zone timer stopped - bracelet disconnected');
        timer.cancel();
        return;
      }

      if (_isInRedZone) {
        _sendRedZoneNotification();
      } else {
        print('🔥 Red Zone timer stopped - left red zone');
        timer.cancel();
      }
    });

    print("🔥 Started Red Zone notifications (every 15 seconds)");
  }

  // ✅ Stop Red Zone notifications
  void _stopRedZoneNotifications() {
    _redZoneTimer?.cancel();
    _redZoneTimer = null;
    _flutterLocalNotificationsPlugin.cancel(1003); // Clear Red Zone notification
    print("🔥 Stopped Red Zone notifications");
  }

  // ✅ Send Red Zone notification
  Future<void> _sendRedZoneNotification() async {
    if (_currentBraceletId == null || !_isConnected) {
      print('🔥 Cannot send Red Zone notification - bracelet not connected');
      return;
    }

    const String title = '🔥 DANGER: Red Zone Alert!';
    const String body = 'You are in a dangerous area! Please move to safety immediately!';

    print('🔥 Sending Red Zone notification');

    await sendRedZoneAlert(
      title: title,
      body: body,
      data: {'type': 'red_zone', 'bracelet_id': _currentBraceletId!},
    );

    await sendPushNotification(
      braceletId: _currentBraceletId!,
      title: title,
      body: body,
      data: {'type': 'red_zone'},
    );

    // Save to database for history
    await _dbRef.child("notifications/red_zone_alerts").push().set({
      'bracelet_id': _currentBraceletId,
      'type': 'red_zone',
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  // ✅ Send Red Zone alert notification
  Future<void> sendRedZoneAlert({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'red_zone_channel',
      'Red Zone Alerts',
      channelDescription: 'Critical alerts for dangerous red zones',
      importance: Importance.max, // Maximum importance
      priority: Priority.max, // Maximum priority
      showWhen: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000), // Red LED
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true, // Show as full screen
      category: AndroidNotificationCategory.alarm, // Alarm category
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      1003, // Fixed ID for Red Zone notifications
      title,
      body,
      platformChannelSpecifics,
      payload: data.toString(),
    );
  }

  // Start safe zone exit notifications (every 30 seconds)
  void _startSafeZoneExitNotifications() {
    _stopSafeZoneExitNotifications();

    if (!_isConnected) {
      print('🔴 Cannot start safe zone notifications - bracelet not connected');
      return;
    }

    // Send first notification immediately
    _sendSafeZoneExitNotification();

    // Start timer for periodic notifications
    _safeZoneExitTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isConnected) {
        print('🔴 Safe zone timer stopped - bracelet disconnected');
        timer.cancel();
        return;
      }

      if (_isOutsideSafeZone) {
        _sendSafeZoneExitNotification();
      } else {
        print('🔴 Safe zone timer stopped - back inside safe zone');
        timer.cancel();
      }
    });

    print("🔴 Started safe zone exit notifications (every 30 seconds)");
  }

  // Stop safe zone exit notifications
  void _stopSafeZoneExitNotifications() {
    _safeZoneExitTimer?.cancel();
    _safeZoneExitTimer = null;
    _flutterLocalNotificationsPlugin.cancel(1001);
    print("🔴 Stopped safe zone exit notifications");
  }

  // Start stationary notifications (every 30 seconds)
  void _startStationaryNotifications() {
    _stopStationaryNotifications();

    if (!_isConnected) {
      print('🟠 Cannot start stationary notifications - bracelet not connected');
      return;
    }

    // Send first notification immediately
    _sendStationaryNotification();

    // Start timer for periodic notifications
    _stationaryTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isConnected) {
        print('🟠 Stationary timer stopped - bracelet disconnected');
        timer.cancel();
        return;
      }

      if (_isStationary) {
        _sendStationaryNotification();
      } else {
        print('🟠 Stationary timer stopped - movement detected');
        timer.cancel();
      }
    });

    print("🟠 Started stationary notifications (every 30 seconds)");
  }

  // Stop stationary notifications
  void _stopStationaryNotifications() {
    _stationaryTimer?.cancel();
    _stationaryTimer = null;
    _flutterLocalNotificationsPlugin.cancel(1002);
    print("🟠 Stopped stationary notifications");
  }

  // Send safe zone exit notification
  Future<void> _sendSafeZoneExitNotification() async {
    if (_currentBraceletId == null || !_isConnected) {
      print('🔴 Cannot send safe zone notification - bracelet not connected');
      return;
    }

    const String title = '⚠️ Safe Zone Alert';
    const String body = 'Your bracelet is outside the safe zone!';

    print('🔴 Sending safe zone exit notification');

    await sendSafeZoneAlert(
      title: title,
      body: body,
      data: {'type': 'safe_zone_exit', 'bracelet_id': _currentBraceletId!},
    );

    await sendPushNotification(
      braceletId: _currentBraceletId!,
      title: title,
      body: body,
      data: {'type': 'safe_zone_exit'},
    );
  }

  // Send stationary notification
  Future<void> _sendStationaryNotification() async {
    if (_currentBraceletId == null || !_isConnected) {
      print('🟠 Cannot send stationary notification - bracelet not connected');
      return;
    }

    String title = '⏸️ Stationary Alert';
    String body = 'Bracelet has been stationary for more than 5 minutes. Please check if everything is okay.';

    print('🟠 Sending stationary notification');

    await sendStationaryAlert(
      title: title,
      body: body,
      data: {'type': 'stationary', 'bracelet_id': _currentBraceletId!},
    );

    await _dbRef.child("notifications/pending").push().set({
      'bracelet_id': _currentBraceletId,
      'type': 'stationary',
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  // Send safe zone notification
  Future<void> sendSafeZoneAlert({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'safe_zone_channel',
      'Safe Zone Alerts',
      channelDescription: 'Notifications for safe zone violations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      1001,
      title,
      body,
      platformChannelSpecifics,
      payload: data.toString(),
    );
  }

  // Send stationary notification
  Future<void> sendStationaryAlert({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'stationary_channel',
      'Stationary Alerts',
      channelDescription: 'Notifications for stationary bracelet',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      1002,
      title,
      body,
      platformChannelSpecifics,
      payload: data.toString(),
    );
  }

  // Send push notification via Firebase
  Future<void> sendPushNotification({
    required String braceletId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _dbRef.child("push_notifications/pending").push().set({
        'bracelet_id': braceletId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sent': false,
      });

      print("Push notification queued successfully");
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    if (message.data['type'] == 'safe_zone_exit') {
      _handleSafeZoneMessage(message);
    } else if (message.data['type'] == 'stationary') {
      _handleStationaryMessage(message);
    } else if (message.data['type'] == 'red_zone') { // ✅ Handle Red Zone messages
      _handleRedZoneMessage(message);
    }
  }

  // Handle safe zone messages
  void _handleSafeZoneMessage(RemoteMessage message) {
    print('Handling safe zone message');
  }

  // Handle stationary messages
  void _handleStationaryMessage(RemoteMessage message) {
    print('Handling stationary message');
  }

  // ✅ Handle Red Zone messages
  void _handleRedZoneMessage(RemoteMessage message) {
    print('Handling Red Zone message');
  }

  // Handle app opening from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.notification?.title}');

    if (message.data['type'] == 'safe_zone_exit') {
      // Navigate to map screen
    } else if (message.data['type'] == 'stationary') {
      // Navigate to status screen
    } else if (message.data['type'] == 'red_zone') { // ✅ Handle Red Zone navigation
      // Navigate to emergency screen or map
    }
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    print('Notification tapped with payload: $payload');
  }

  // Clean up resources
  void dispose() {
    _stopAllNotifications();
    _currentBraceletId = null;
  }

  // Reset all states
  void reset() {
    _stopAllNotifications();
    _isOutsideSafeZone = false;
    _isStationary = false;
    _isConnected = false;
    _isInRedZone = false; // ✅ Reset Red Zone status
    _previousOutsideSafeZone = false;
    _previousStationary = false;
    _previousConnected = false;
    _previousInRedZone = false; // ✅ Reset previous Red Zone status
    _currentBraceletId = null;
    _lastMovementTime = null;
  }

  // ✅ Updated status with Red Zone
  Map<String, dynamic> getCurrentStatus() {
    return {
      'bracelet_id': _currentBraceletId,
      'is_connected': _isConnected,
      'is_outside_safe_zone': _isOutsideSafeZone,
      'is_stationary': _isStationary,
      'is_in_red_zone': _isInRedZone, // ✅ Added Red Zone status
      'safe_zone_timer_active': _safeZoneExitTimer?.isActive ?? false,
      'stationary_timer_active': _stationaryTimer?.isActive ?? false,
      'red_zone_timer_active': _redZoneTimer?.isActive ?? false, // ✅ Added Red Zone timer status
    };
  }
}

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');

  if (message.data['type'] == 'safe_zone_exit') {
    print('Background: Safe zone exit detected');
  } else if (message.data['type'] == 'stationary') {
    print('Background: Stationary status detected');
  } else if (message.data['type'] == 'red_zone') { // ✅ Handle Red Zone in background
    print('Background: Red Zone detected');
  }
}