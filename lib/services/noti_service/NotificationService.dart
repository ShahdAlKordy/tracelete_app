// lib/services/noti_service/NotificationService.dart

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tracelet_app/services/noti_service/RedZoneHandler.dart';
import 'package:tracelet_app/services/noti_service/SafeZoneHandler.dart';
import 'package:tracelet_app/services/noti_service/StationaryHandler.dart'; // Make sure to import the correct file

// Very Important: This function must be top-level (outside any class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  // Here you should handle notifications coming directly from the server if you're using them
  // But in our case, we rely on Listeners, so this function's main role
  // is to "fix" the app so the Service can work.
}

class NotificationService {
  // --- Singleton Setup ---
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // --- Plugins ---
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- Handlers ---
  late final SafeZoneHandler _safeZoneHandler;
  late final RedZoneHandler _redZoneHandler;
  late final StationaryHandler _stationaryHandler;

  // --- State Tracking ---
  final Map<String, bool> _lastOutsideSafeZoneState = {};
  final Map<String, bool> _lastInRedZoneState = {};

  bool _isInitialized = false;

  // ✅ New: Notification settings managed by the service
  Map<String, bool> _notificationSettings = {
    'safe_zone_enabled': true,
    'red_zone_enabled': true,
    'stationary_enabled': true,
    'connectivity_enabled': true,
    'battery_enabled': true,
    'network_enabled': true,
    'app_update_enabled': true,
    'beta_updates_enabled': false,
  };

  // ✅ New: Map to hold notification sound preferences
  final Map<String, String> _notificationSounds = {
    'geofencing': 'default',
    'red_zone': 'urgent',
    'emergency': 'alert',
    'connectivity': 'chime',
    'battery': 'beep',
    'network': 'gentle',
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeLocalNotifications();
    await _initializeFCM();

    // Pass notification settings and sound preferences to handlers
    _safeZoneHandler = SafeZoneHandler(_localNotifications);
    _redZoneHandler = RedZoneHandler(_localNotifications);
    _stationaryHandler = StationaryHandler(_localNotifications);

    await _requestPermissions();

    _isInitialized = true;
    print('NotificationService initialized successfully.');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission:
          true, // Important for dangerous zone notifications
    );

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings);
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(AndroidNotificationChannel(
        SafeZoneHandler.channelId, SafeZoneHandler.channelName,
        description: SafeZoneHandler.channelDescription,
        importance: Importance.high,
        playSound: true));

    await android?.createNotificationChannel(AndroidNotificationChannel(
        RedZoneHandler.channelId, RedZoneHandler.channelName,
        description: RedZoneHandler.channelDescription,
        importance: Importance.max,
        playSound: true));

    await android?.createNotificationChannel(AndroidNotificationChannel(
        StationaryHandler.channelId, StationaryHandler.channelName,
        description: StationaryHandler.channelDescription,
        importance: Importance.defaultImportance,
        playSound: true));
  }

  Future<void> _initializeFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCM message received while app is in foreground.');
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // ✅ New: Update notification settings from the UI
  void updateNotificationSettings(Map<String, bool> settings) {
    _notificationSettings.addAll(settings);
    print(
        'NotificationService received updated settings: $_notificationSettings');
  }

  // ✅ New: Update notification sound for a specific type
  void updateNotificationSound(String type, String sound) {
    _notificationSounds[type] = sound;
    print('NotificationService sound for $type updated to $sound');
  }

  // --- The pivotal function ---
  void updateBraceletStatus({
    required String braceletId,
    required String braceletName,
    required bool isConnected,
    required bool isOutsideSafeZone,
    required bool isInRedZone,
    required bool isStationary,
  }) {
    if (!_isInitialized) {
      print("NotificationService not initialized yet!");
      return;
    }

    if (!isConnected) {
      print("Bracelet $braceletName is disconnected. Stopping all monitoring.");
      _safeZoneHandler.stopMonitoring(braceletId);
      _redZoneHandler.stopMonitoring(braceletId);
      _stationaryHandler.stopMonitoring(braceletId);
      _lastOutsideSafeZoneState.remove(braceletId);
      _lastInRedZoneState.remove(braceletId);
      return;
    }

    // 1. Safe Zone
    if (_notificationSettings['safe_zone_enabled'] == true &&
        _lastOutsideSafeZoneState[braceletId] != isOutsideSafeZone) {
      _safeZoneHandler.handleSafeZoneStatus(
        braceletId: braceletId,
        braceletName: braceletName,
        isOutsideSafeZone: isOutsideSafeZone,
        sound: _notificationSounds['geofencing']!, // Pass sound preference
      );
      _lastOutsideSafeZoneState[braceletId] = isOutsideSafeZone;
    }

    // 2. Red Zone
    if (_notificationSettings['red_zone_enabled'] == true &&
        _lastInRedZoneState[braceletId] != isInRedZone) {
      _redZoneHandler.handleRedZoneStatus(
        braceletId: braceletId,
        braceletName: braceletName,
        isInRedZone: isInRedZone,
        sound: _notificationSounds['red_zone']!, // Pass sound preference
      );
      _lastInRedZoneState[braceletId] = isInRedZone;
    }

    // 3. Stationary (mapped to emergency alerts in UI)
    if (_notificationSettings['stationary_enabled'] == true) {
      _stationaryHandler.handleStationaryHandler(
        // <--- تم التصحيح هنا
        braceletId: braceletId,
        braceletName: braceletName,
        isStationary: isStationary,
        sound: _notificationSounds['emergency']!, // Pass sound preference
      );
    }
    // No 'else' block for stationary as it's not a state change trigger for notification, but a continuous check.
  }

  // ✅ New: Method to send test notifications based on current settings
  Future<void> sendTestNotification(String type, String braceletName) async {
    if (!_isInitialized) {
      print(
          "NotificationService not initialized, cannot send test notification.");
      return;
    }

    // Check if the specific notification type is enabled in settings
    bool isEnabled = false;
    String channelId = '';
    String channelName = '';
    String description = '';
    Importance importance = Importance.defaultImportance;
    String title = '';
    String body = '';
    String sound = 'default';

    switch (type) {
      case 'safe_zone':
        isEnabled = _notificationSettings['safe_zone_enabled'] ?? false;
        channelId = SafeZoneHandler.channelId;
        channelName = SafeZoneHandler.channelName;
        description = SafeZoneHandler.channelDescription;
        importance = Importance.high;
        title = 'Test Safe Zone Alert for $braceletName';
        body = 'This is a test notification for safe zone entry/exit.';
        sound = _notificationSounds['geofencing'] ?? 'default';
        break;
      case 'red_zone':
        isEnabled = _notificationSettings['red_zone_enabled'] ?? false;
        channelId = RedZoneHandler.channelId;
        channelName = RedZoneHandler.channelName;
        description = RedZoneHandler.channelDescription;
        importance = Importance.max;
        title = 'Test Red Zone Alert for $braceletName';
        body = 'This is a test notification for red zone entry!';
        sound = _notificationSounds['red_zone'] ?? 'urgent';
        break;
      case 'stationary':
        isEnabled = _notificationSettings['stationary_enabled'] ?? false;
        channelId = StationaryHandler.channelId;
        channelName = StationaryHandler.channelName;
        description = StationaryHandler.channelDescription;
        importance = Importance.defaultImportance;
        title = 'Test Stationary Alert for $braceletName';
        body = 'This is a test notification for stationary detection.';
        sound = _notificationSounds['emergency'] ?? 'alert';
        break;
      case 'connectivity':
        // Currently, connectivity is not handled by a specific handler,
        // so we can show a generic local notification.
        isEnabled = _notificationSettings['connectivity_enabled'] ?? false;
        channelId =
            'connectivity_channel'; // Use a generic channel or define a new one
        channelName = 'Connectivity Alerts';
        description = 'Alerts for device connectivity status.';
        importance = Importance.defaultImportance;
        title = 'Test Connectivity Alert for $braceletName';
        body = 'This is a test notification for device connectivity.';
        sound = _notificationSounds['connectivity'] ?? 'chime';
        break;
      case 'battery':
        isEnabled = _notificationSettings['battery_enabled'] ?? false;
        channelId =
            'battery_channel'; // Use a generic channel or define a new one
        channelName = 'Battery Alerts';
        description = 'Alerts for low battery.';
        importance = Importance.defaultImportance;
        title = 'Test Battery Alert for $braceletName';
        body = 'This is a test notification for low battery.';
        sound = _notificationSounds['battery'] ?? 'beep';
        break;
      case 'network':
        isEnabled = _notificationSettings['network_enabled'] ?? false;
        channelId =
            'network_channel'; // Use a generic channel or define a new one
        channelName = 'Network Alerts';
        description = 'Alerts for network issues.';
        importance = Importance.defaultImportance;
        title = 'Test Network Alert for $braceletName';
        body = 'This is a test notification for network issues.';
        sound = _notificationSounds['network'] ?? 'gentle';
        break;
      default:
        print('Unknown notification type: $type');
        return;
    }

    if (!isEnabled) {
      print(
          'Notification type "$type" is disabled. Not sending test notification.');
      return;
    }

    // Ensure the channel exists for generic notifications
    final AndroidFlutterLocalNotificationsPlugin? android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(AndroidNotificationChannel(
        channelId, channelName,
        description: description, importance: importance, playSound: true));

    // Convert sound string to RawResourceAndroidNotificationSound
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

    await _localNotifications.show(
      0, // Notification ID (can be unique for each test notification)
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: description,
          importance: importance,
          priority: Priority.high,
          sound: androidSound,
        ),
        iOS: DarwinNotificationDetails(
          sound: sound == 'default'
              ? null
              : '$sound.aiff', // iOS expects .aiff extension or default
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_notification_payload',
    );
    print('Test notification of type $type sent.');
  }

  // ✅ New: Reset notification service settings to default (all off)
  void reset() {
    _notificationSettings = {
      'safe_zone_enabled': false,
      'red_zone_enabled': false,
      'stationary_enabled': false,
      'connectivity_enabled': false,
      'battery_enabled': false,
      'network_enabled': false,
      'app_update_enabled': false,
      'beta_updates_enabled': false,
    };
    // Also reset sounds to default if desired
    _notificationSounds.updateAll((key, value) => 'default');
    print('NotificationService settings reset.');
  }

  // ✅ New: Get current status of the service
  Map<String, dynamic> getCurrentStatus() {
    return {
      'initialized': _isInitialized,
      'notification_settings': _notificationSettings,
      'connected_bracelets': _lastOutsideSafeZoneState.keys
          .toList(), // Example of connected bracelets
      'notification_sounds': _notificationSounds,
    };
  }

  void dispose() {
    print("NotificationService disposed.");
  }
}
