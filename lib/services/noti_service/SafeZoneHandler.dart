// lib/services/noti_service/SafeZoneHandler.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SafeZoneHandler {
  static const String channelId = 'safe_zone_channel';
  static const String channelName = 'Safe Zone Alerts';
  static const String channelDescription =
      'Notifications for safe zone entry and exit.';

  final FlutterLocalNotificationsPlugin _localNotifications;

  SafeZoneHandler(this._localNotifications);

  void handleSafeZoneStatus({
    required String braceletId,
    required String braceletName,
    required bool isOutsideSafeZone,
    String sound = 'default', // <--- Make sure this line exists
  }) async {
    // Specify Android sound path, checking if sound is "default"
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

    if (isOutsideSafeZone) {
      await _localNotifications.show(
        braceletId.hashCode, // معرف فريد لكل إشعار سوار
        'Bracelet $braceletName: Left Safe Zone',
        'Your bracelet has moved outside the designated safe zone.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: androidSound, // <--- Use selected sound for Android
          ),
          iOS: DarwinNotificationDetails(
            sound: sound == 'default'
                ? null
                : '$sound.aiff', // <--- Use selected sound for iOS
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'safe_zone_exit_${braceletId}',
      );
      print(
          'Safe Zone Alert: Bracelet $braceletName is outside the safe zone.');
    } else {
      // يمكنك هنا إضافة منطق لإلغاء الإشعار إذا عاد السوار إلى المنطقة الآمنة
      // _localNotifications.cancel(braceletId.hashCode);
      print('Bracelet $braceletName has returned to the safe zone.');
    }
  }

  void stopMonitoring(String braceletId) {
    // إلغاء أي إشعارات نشطة خاصة بالمنطقة الآمنة لهذا السوار
    _localNotifications.cancel(braceletId.hashCode);
    print('Stopped safe zone monitoring for bracelet $braceletId.');
  }
}
