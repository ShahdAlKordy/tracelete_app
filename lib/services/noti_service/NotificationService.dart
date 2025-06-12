// lib/services/noti_service/NotificationService.dart

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tracelet_app/services/noti_service/RedZoneHandler.dart';
import 'package:tracelet_app/services/noti_service/SafeZoneHandler.dart';
import 'package:tracelet_app/services/noti_service/StationaryHandler.dart';

// ✅ دالة عامة مهمة جداً لمعالجة الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  // إنشاء instance من FlutterLocalNotificationsPlugin للخلفية
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // تهيئة بسيطة للإشعارات المحلية
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
  const InitializationSettings settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await localNotifications.initialize(settings);

  // إنشاء قناة إشعارات للخلفية
  final AndroidFlutterLocalNotificationsPlugin? android =
      localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'background_channel',
      'Background Notifications',
      description: 'Notifications received in background',
      importance: Importance.high,
    ),
  );

  // إظهار الإشعار المحلي
  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
    message.notification?.body ?? message.data['body'] ?? 'لديك إشعار جديد',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'background_channel',
        'Background Notifications',
        channelDescription: 'Notifications received in background',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.toString(),
  );
}

class NotificationService {
  // --- Singleton Setup ---
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // --- Plugins ---
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- Firebase Messaging ---
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // --- Handlers ---
  late final SafeZoneHandler _safeZoneHandler;
  late final RedZoneHandler _redZoneHandler;
  late final StationaryHandler _stationaryHandler;

  // --- State Tracking ---
  final Map<String, bool> _lastOutsideSafeZoneState = {};
  final Map<String, bool> _lastInRedZoneState = {};

  bool _isInitialized = false;
  String? _fcmToken;

  // ✅ إعدادات الإشعارات
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

  // ✅ أصوات الإشعارات
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

    try {
      await _initializeLocalNotifications();
      await _initializeFCM();
      await _setupHandlers();
      await _requestPermissions();

      _isInitialized = true;
      print('✅ NotificationService initialized successfully.');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      throw e;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings,
      // ✅ معالج النقر على الإشعار
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
  }

  // ✅ معالج النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    // يمكنك إضافة منطق للتنقل أو تنفيذ إجراءات معينة هنا
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    // قنوات الإشعارات الأساسية
    await android.createNotificationChannel(AndroidNotificationChannel(
      SafeZoneHandler.channelId,
      SafeZoneHandler.channelName,
      description: SafeZoneHandler.channelDescription,
      importance: Importance.high,
      playSound: true,
    ));

    await android.createNotificationChannel(AndroidNotificationChannel(
      RedZoneHandler.channelId,
      RedZoneHandler.channelName,
      description: RedZoneHandler.channelDescription,
      importance: Importance.max,
      playSound: true,
    ));

    await android.createNotificationChannel(AndroidNotificationChannel(
      StationaryHandler.channelId,
      StationaryHandler.channelName,
      description: StationaryHandler.channelDescription,
      importance: Importance.defaultImportance,
      playSound: true,
    ));

    // ✅ قنوات إضافية للإشعارات العامة
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'background_channel',
      'Background Notifications',
      description: 'Notifications received in background',
      importance: Importance.high,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'connectivity_channel',
      'Connectivity Alerts',
      description: 'Alerts for device connectivity status',
      importance: Importance.defaultImportance,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'battery_channel',
      'Battery Alerts',
      description: 'Alerts for low battery',
      importance: Importance.defaultImportance,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'network_channel',
      'Network Alerts',
      description: 'Alerts for network issues',
      importance: Importance.defaultImportance,
    ));
  }

  Future<void> _initializeFCM() async {
    try {
      // ✅ طلب الصلاحيات أولاً
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM permissions granted');
      } else {
        print('❌ FCM permissions denied');
      }

      // ✅ الحصول على FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      // ✅ معالج الرسائل في المقدمة (foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 FCM message received in foreground: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      // ✅ معالج الرسائل في الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // ✅ معالج النقر على الإشعار عندما يكون التطبيق مغلق
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 App opened from notification: ${message.messageId}');
        _handleNotificationTap(message);
      });

      // ✅ فحص إذا كان التطبيق فُتح من خلال إشعار
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 App launched from notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }

      // ✅ الاشتراك في الموضوعات العامة
      await _firebaseMessaging.subscribeToTopic('general_alerts');
      await _firebaseMessaging.subscribeToTopic('emergency_alerts');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  // ✅ معالج الرسائل في المقدمة
  void _handleForegroundMessage(RemoteMessage message) {
    // إظهار إشعار محلي حتى لو كان التطبيق في المقدمة
    _showLocalNotificationFromFCM(message);
  }

  // ✅ معالج النقر على الإشعار
  void _handleNotificationTap(RemoteMessage message) {
    // يمكنك إضافة منطق للتنقل هنا
    print('Handling notification tap: ${message.data}');
  }

  // ✅ إظهار إشعار محلي من رسالة FCM
  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
      message.notification?.body ?? message.data['body'] ?? 'لديك إشعار جديد',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'background_channel',
          'Background Notifications',
          channelDescription: 'Notifications from server',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  Future<void> _setupHandlers() async {
    _safeZoneHandler = SafeZoneHandler(_localNotifications);
    _redZoneHandler = RedZoneHandler(_localNotifications);
    _stationaryHandler = StationaryHandler(_localNotifications);
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
  }

  // ✅ الحصول على FCM Token
  String? get fcmToken => _fcmToken;

  // ✅ تحديث إعدادات الإشعارات
  void updateNotificationSettings(Map<String, bool> settings) {
    _notificationSettings.addAll(settings);
    print('NotificationService settings updated: $_notificationSettings');
  }

  // ✅ تحديث صوت إشعار معين
  void updateNotificationSound(String type, String sound) {
    _notificationSounds[type] = sound;
    print('NotificationService sound for $type updated to $sound');
  }

  // ✅ الدالة الرئيسية لتحديث حالة السوار
  void updateBraceletStatus({
    required String braceletId,
    required String braceletName,
    required bool isConnected,
    required bool isOutsideSafeZone,
    required bool isInRedZone,
    required bool isStationary,
  }) {
    if (!_isInitialized) {
      print("❌ NotificationService not initialized yet!");
      return;
    }

    if (!isConnected) {
      print("📱 Bracelet $braceletName is disconnected. Stopping monitoring.");
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
        sound: _notificationSounds['geofencing']!,
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
        sound: _notificationSounds['red_zone']!,
      );
      _lastInRedZoneState[braceletId] = isInRedZone;
    }

    // 3. Stationary
    if (_notificationSettings['stationary_enabled'] == true) {
      _stationaryHandler.handleStationaryHandler(
        braceletId: braceletId,
        braceletName: braceletName,
        isStationary: isStationary,
        sound: _notificationSounds['emergency']!,
      );
    }
  }

  // ✅ إرسال إشعار تجريبي
  Future<void> sendTestNotification(String type, String braceletName) async {
    if (!_isInitialized) {
      print(
          "❌ NotificationService not initialized, cannot send test notification.");
      return;
    }

    bool isEnabled = _notificationSettings['${type}_enabled'] ?? false;

    if (!isEnabled) {
      print('⚠️ Notification type "$type" is disabled.');
      return;
    }

    String channelId = '';
    String channelName = '';
    String title = '';
    String body = '';
    Importance importance = Importance.defaultImportance;

    switch (type) {
      case 'safe_zone':
        channelId = SafeZoneHandler.channelId;
        channelName = SafeZoneHandler.channelName;
        title = 'تجربة تنبيه المنطقة الآمنة - $braceletName';
        body = 'هذا إشعار تجريبي للمنطقة الآمنة';
        importance = Importance.high;
        break;
      case 'red_zone':
        channelId = RedZoneHandler.channelId;
        channelName = RedZoneHandler.channelName;
        title = '⚠️ تجربة تنبيه المنطقة الخطرة - $braceletName';
        body = 'هذا إشعار تجريبي للمنطقة الخطرة!';
        importance = Importance.max;
        break;
      case 'stationary':
        channelId = StationaryHandler.channelId;
        channelName = StationaryHandler.channelName;
        title = 'تجربة تنبيه عدم الحركة - $braceletName';
        body = 'هذا إشعار تجريبي لعدم الحركة';
        importance = Importance.defaultImportance;
        break;
      case 'connectivity':
        channelId = 'connectivity_channel';
        channelName = 'تنبيهات الاتصال';
        title = 'تجربة تنبيه الاتصال - $braceletName';
        body = 'هذا إشعار تجريبي لحالة الاتصال';
        break;
      default:
        print('❌ Unknown notification type: $type');
        return;
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: importance,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    print('✅ Test notification sent for type: $type');
  }

  // ✅ إعادة تعيين الإعدادات
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
    _notificationSounds.updateAll((key, value) => 'default');
    print('✅ NotificationService settings reset.');
  }

  // ✅ الحصول على حالة الخدمة الحالية
  Map<String, dynamic> getCurrentStatus() {
    return {
      'initialized': _isInitialized,
      'fcm_token': _fcmToken,
      'notification_settings': _notificationSettings,
      'connected_bracelets': _lastOutsideSafeZoneState.keys.toList(),
      'notification_sounds': _notificationSounds,
    };
  }

  void dispose() {
    print("NotificationService disposed.");
  }
}
