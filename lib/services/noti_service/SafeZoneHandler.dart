// lib/services/noti_service/SafeZoneHandler.dart

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SafeZoneHandler {
  static const String channelId = 'safe_zone_channel';
  static const String channelName = 'Safe Zone Alerts';
  static const String channelDescription =
      'Notifications for safe zone entry and exit.';

  final FlutterLocalNotificationsPlugin _localNotifications;

  final Map<String, Timer> _activeTimers = {};

  final Map<String, bool> _braceletStatuses = {};

  SafeZoneHandler(this._localNotifications);

  void handleSafeZoneStatus({
    required String braceletId,
    required String braceletName,
    required bool isOutsideSafeZone,
    String sound = 'default',
  }) async {
    bool? previousStatus = _braceletStatuses[braceletId];
    _braceletStatuses[braceletId] = isOutsideSafeZone;

    if (isOutsideSafeZone) {

      if (previousStatus != true) {
        await _sendSafeZoneAlert(braceletId, braceletName, sound);
        print(
            'Safe Zone Alert: Bracelet $braceletName is outside the safe zone.');
      }

      if (!_activeTimers.containsKey(braceletId)) {
        _activeTimers[braceletId] = Timer.periodic(
          const Duration(seconds: 30),
          (timer) async {
            if (_braceletStatuses[braceletId] == true) {
              await _sendSafeZoneAlert(braceletId, braceletName, sound);
              print(
                  'Repeated Safe Zone Alert: Bracelet $braceletName is still outside the safe zone.');
            } else {
              timer.cancel();
              _activeTimers.remove(braceletId);
            }
          },
        );
      }
    } else {

      if (_activeTimers.containsKey(braceletId)) {
        _activeTimers[braceletId]?.cancel();
        _activeTimers.remove(braceletId);
      }

      await _localNotifications.cancel(braceletId.hashCode);

      print('Bracelet $braceletName has returned to the safe zone.');
    }
  }

  Future<void> _sendSafeZoneAlert(
      String braceletId, String braceletName, String sound) async {
    // تحديد صوت Android
    RawResourceAndroidNotificationSound? androidSound;
    if (sound != 'default') {
      androidSound = RawResourceAndroidNotificationSound(sound);
    }

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
          sound: androidSound,
        ),
        iOS: DarwinNotificationDetails(
          sound: sound == 'default' ? null : '$sound.aiff',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'safe_zone_exit_${braceletId}',
    );
  }

  void stopMonitoring(String braceletId) {
    if (_activeTimers.containsKey(braceletId)) {
      _activeTimers[braceletId]?.cancel();
      _activeTimers.remove(braceletId);
    }

    _braceletStatuses.remove(braceletId);

    _localNotifications.cancel(braceletId.hashCode);

    print('Stopped safe zone monitoring for bracelet $braceletId.');
  }

  void dispose() {
    for (Timer timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _braceletStatuses.clear();
  }
}
