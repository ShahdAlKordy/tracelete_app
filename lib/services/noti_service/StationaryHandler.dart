// lib/services/noti_service/StationaryHandler.dart

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StationaryHandler {
  static const String channelId = 'stationary_channel';
  static const String channelName = 'Stationary Alerts';
  static const String channelDescription =
      'Notifications for prolonged stationary periods.';

  final FlutterLocalNotificationsPlugin _localNotifications;

  // خريطة لتخزين Timer الانتظار الأولي (5 دقائق) لكل bracelet
  final Map<String, Timer> _initialTimers = {};

  // خريطة لتخزين Timer التكرار (كل دقيقة) لكل bracelet
  final Map<String, Timer> _repeatTimers = {};

  // خريطة لتخزين حالة كل bracelet (ثابت أم متحرك)
  final Map<String, bool> _braceletStatuses = {};

  StationaryHandler(this._localNotifications);

  void handleStationaryHandler({
    required String braceletId,
    required String braceletName,
    required bool isStationary,
    String sound = 'default',
  }) async {
    // التحقق من الحالة السابقة للسوار
    bool? previousStatus = _braceletStatuses[braceletId];
    _braceletStatuses[braceletId] = isStationary;

    if (isStationary) {
      // إذا كان السوار ثابت

      // بدء المراقبة فقط إذا لم يكن ثابتاً من قبل
      if (previousStatus != true) {
        _startStationaryMonitoring(braceletId, braceletName, sound);
        print('Started stationary monitoring for Bracelet $braceletName.');
      }
    } else {
      // إذا بدأ السوار بالتحرك مرة أخرى
      _stopStationaryMonitoring(braceletId);
      print('Bracelet $braceletName is no longer stationary.');
    }
  }

  // بدء مراقبة الثبات
  void _startStationaryMonitoring(
      String braceletId, String braceletName, String sound) {
    // إلغاء أي timers سابقة لهذا السوار
    _cancelTimersForBracelet(braceletId);

    // بدء timer الانتظار الأولي (5 دقائق)
    _initialTimers[braceletId] = Timer(
      const Duration(minutes: 5),
      () async {
        // التحقق من أن السوار لا يزال ثابتاً بعد 5 دقائق
        if (_braceletStatuses[braceletId] == true) {
          // إرسال أول إشعار بعد 5 دقائق
          await _sendStationaryAlert(braceletId, braceletName, sound);
          print(
              'Initial Stationary Alert: Bracelet $braceletName has been stationary for 5 minutes.');

          // بدء timer التكرار (كل دقيقة)
          _startRepeatTimer(braceletId, braceletName, sound);
        }

        // إزالة initial timer من الخريطة
        _initialTimers.remove(braceletId);
      },
    );
  }

  // بدء timer التكرار (كل دقيقة)
  void _startRepeatTimer(String braceletId, String braceletName, String sound) {
    _repeatTimers[braceletId] = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        // التحقق من أن السوار لا يزال ثابتاً
        if (_braceletStatuses[braceletId] == true) {
          await _sendStationaryAlert(braceletId, braceletName, sound);
          print(
              'Repeated Stationary Alert: Bracelet $braceletName is still stationary.');
        } else {
          // إذا بدأ بالتحرك، إلغاء timer التكرار
          timer.cancel();
          _repeatTimers.remove(braceletId);
        }
      },
    );
  }

  // إيقاف مراقبة الثبات
  void _stopStationaryMonitoring(String braceletId) {
    // إلغاء جميع timers لهذا السوار
    _cancelTimersForBracelet(braceletId);

    // إلغاء أي إشعارات نشطة
    _localNotifications.cancel(braceletId.hashCode + 2);
  }

  // إلغاء جميع timers لسوار معين
  void _cancelTimersForBracelet(String braceletId) {
    // إلغاء initial timer
    if (_initialTimers.containsKey(braceletId)) {
      _initialTimers[braceletId]?.cancel();
      _initialTimers.remove(braceletId);
    }

    // إلغاء repeat timer
    if (_repeatTimers.containsKey(braceletId)) {
      _repeatTimers[braceletId]?.cancel();
      _repeatTimers.remove(braceletId);
    }
  }

  // دالة مساعدة لإرسال إشعار الثبات
  Future<void> _sendStationaryAlert(
      String braceletId, String braceletName, String sound) async {
    // تحديد صوت Android
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

    await _localNotifications.show(
      braceletId.hashCode + 2, // معرف فريد مختلف عن الاثنين السابقين
      'Bracelet $braceletName: Stationary Alert',
      'Your bracelet has been stationary for too long. Please check on the wearer.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: androidSound,
        ),
        iOS: DarwinNotificationDetails(
          sound: sound == 'default' ? null : '$sound.aiff',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'stationary_alert_${braceletId}',
    );
  }

  void stopMonitoring(String braceletId) {
    // إيقاف مراقبة الثبات
    _stopStationaryMonitoring(braceletId);

    // إزالة حالة السوار
    _braceletStatuses.remove(braceletId);

    print('Stopped stationary monitoring for bracelet $braceletId.');
  }

  // دالة لإيقاف جميع المراقبة والتنظيف
  void dispose() {
    // إلغاء جميع Initial Timers
    for (Timer timer in _initialTimers.values) {
      timer.cancel();
    }
    _initialTimers.clear();

    // إلغاء جميع Repeat Timers
    for (Timer timer in _repeatTimers.values) {
      timer.cancel();
    }
    _repeatTimers.clear();

    // مسح حالات الأساور
    _braceletStatuses.clear();
  }
}
