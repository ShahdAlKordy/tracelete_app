// lib/services/noti_service/RedZoneHandler.dart

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RedZoneHandler {
  static const String channelId = 'red_zone_channel';
  static const String channelName = 'Red Zone Alerts';
  static const String channelDescription = 'Notifications for red zone entry.';

  final FlutterLocalNotificationsPlugin _localNotifications;

  // خريطة لتخزين Timer لكل bracelet
  final Map<String, Timer> _activeTimers = {};

  // خريطة لتخزين حالة كل bracelet (داخل المنطقة الحمراء أم لا)
  final Map<String, bool> _braceletStatuses = {};

  RedZoneHandler(this._localNotifications);

  void handleRedZoneStatus({
    required String braceletId,
    required String braceletName,
    required bool isInRedZone,
    String sound = 'default',
  }) async {
    // التحقق من الحالة السابقة للسوار
    bool? previousStatus = _braceletStatuses[braceletId];
    _braceletStatuses[braceletId] = isInRedZone;

    if (isInRedZone) {
      // إذا كان السوار داخل المنطقة الحمراء

      // إرسال إشعار فوري إذا كانت هذه أول مرة يدخل فيها
      if (previousStatus != true) {
        await _sendRedZoneAlert(braceletId, braceletName, sound);
        print('Red Zone Alert: Bracelet $braceletName is in red zone.');
      }

      // بدء Timer للتكرار كل 30 ثانية (إذا لم يكن موجود بالفعل)
      if (!_activeTimers.containsKey(braceletId)) {
        _activeTimers[braceletId] = Timer.periodic(
          const Duration(seconds: 30),
          (timer) async {
            // التحقق مرة أخرى من أن السوار لا يزال داخل المنطقة الحمراء
            if (_braceletStatuses[braceletId] == true) {
              await _sendRedZoneAlert(braceletId, braceletName, sound);
              print(
                  'Repeated Red Zone Alert: Bracelet $braceletName is still in red zone.');
            } else {
              // إذا خرج من المنطقة الحمراء، إلغاء Timer
              timer.cancel();
              _activeTimers.remove(braceletId);
            }
          },
        );
      }
    } else {
      // إذا خرج السوار من المنطقة الحمراء

      // إلغاء Timer إذا كان موجوداً
      if (_activeTimers.containsKey(braceletId)) {
        _activeTimers[braceletId]?.cancel();
        _activeTimers.remove(braceletId);
      }

      // إلغاء أي إشعارات نشطة
      await _localNotifications.cancel(braceletId.hashCode + 1);

      print('Bracelet $braceletName has left the red zone.');
    }
  }

  // دالة مساعدة لإرسال إشعار المنطقة الحمراء
  Future<void> _sendRedZoneAlert(
      String braceletId, String braceletName, String sound) async {
    // تحديد صوت Android
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

    await _localNotifications.show(
      braceletId.hashCode + 1, // معرف فريد مختلف عن Safe Zone
      'Bracelet $braceletName: Entered Red Zone',
      'Your bracelet has entered a designated red zone. Please check immediately!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max, // أهمية عالية جداً للمناطق الخطرة
          priority: Priority.max,
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
      payload: 'red_zone_entry_${braceletId}',
    );
  }

  void stopMonitoring(String braceletId) {
    // إلغاء Timer إذا كان موجوداً
    if (_activeTimers.containsKey(braceletId)) {
      _activeTimers[braceletId]?.cancel();
      _activeTimers.remove(braceletId);
    }

    // إزالة حالة السوار
    _braceletStatuses.remove(braceletId);

    // إلغاء أي إشعارات نشطة خاصة بالمنطقة الحمراء لهذا السوار
    _localNotifications.cancel(braceletId.hashCode + 1);

    print('Stopped red zone monitoring for bracelet $braceletId.');
  }

  // دالة لإيقاف جميع المراقبة والتنظيف
  void dispose() {
    // إلغاء جميع Timers النشطة
    for (Timer timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _braceletStatuses.clear();
  }
}
