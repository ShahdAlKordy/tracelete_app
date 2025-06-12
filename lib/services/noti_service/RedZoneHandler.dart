// lib/services/noti_service/RedZoneHandler.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RedZoneHandler {
  static const String channelId = 'red_zone_channel';
  static const String channelName = 'Red Zone Alerts';
  static const String channelDescription = 'Notifications for red zone entry.';

  final FlutterLocalNotificationsPlugin _localNotifications;

  RedZoneHandler(this._localNotifications);

  void handleRedZoneStatus({
    required String braceletId,
    required String braceletName,
    required bool isInRedZone,
    String sound = 'default', // <--- Make sure this line exists
  }) async {
    // Specify Android sound path, checking if sound is "default"
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

    if (isInRedZone) {
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
        payload: 'red_zone_entry_${braceletId}',
      );
      print('Red Zone Alert: Bracelet $braceletName is in red zone.');
    } else {
      // يمكنك هنا إلغاء الإشعار إذا خرج السوار من المنطقة الحمراء
      // _localNotifications.cancel(braceletId.hashCode + 1);
      print('Bracelet $braceletName has left the red zone.');
    }
  }

  void stopMonitoring(String braceletId) {
    // إلغاء أي إشعارات نشطة خاصة بالمنطقة الحمراء لهذا السوار
    _localNotifications.cancel(braceletId.hashCode + 1);
    print('Stopped red zone monitoring for bracelet $braceletId.');
  }
}
