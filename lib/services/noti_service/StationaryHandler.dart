// lib/services/noti_service/StationaryHandler.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StationaryHandler {
  static const String channelId = 'stationary_channel';
  static const String channelName = 'Stationary Alerts';
  static const String channelDescription =
      'Notifications for prolonged stationary periods.';

  final FlutterLocalNotificationsPlugin _localNotifications;

  StationaryHandler(this._localNotifications);

  void handleStationaryHandler({
    // You can name it handleStationaryStatus to be consistent
    required String braceletId,
    required String braceletName,
    required bool isStationary,
    String sound = 'default', // <--- Make sure this line exists
  }) async {
    // Specify Android sound path, checking if sound is "default"
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

    if (isStationary) {
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
        payload: 'stationary_alert_${braceletId}',
      );
      print('Stationary Alert: Bracelet $braceletName is stationary.');
    } else {
      // يمكنك هنا إلغاء الإشعار إذا بدأ السوار بالتحرك مرة أخرى
      // _localNotifications.cancel(braceletId.hashCode + 2);
      print('Bracelet $braceletName is no longer stationary.');
    }
  }

  void stopMonitoring(String braceletId) {
    // إلغاء أي إشعارات نشطة خاصة بالثبات لهذا السوار
    _localNotifications.cancel(braceletId.hashCode + 2);
    print('Stopped stationary monitoring for bracelet $braceletId.');
  }
}
