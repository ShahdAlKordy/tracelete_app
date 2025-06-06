import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet_app/auth_service/NotificationService.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/NotificationSoundWidget.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/ProfilePictureWidget.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notification controls
  bool _geofencingEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _connectivityAlertsEnabled = true;
  bool _batteryAlertsEnabled = true;
  bool _networkAlertsEnabled = true;
  bool _appUpdateNotificationsEnabled = true;
  bool _betaUpdatesEnabled = false;
  bool _redZoneAlertsEnabled = true;

  // ✅ إضافة متغيرات للأصوات
  Map<String, String> _notificationSounds = {
    'geofencing': 'default',
    'red_zone': 'urgent',
    'emergency': 'alert',
    'connectivity': 'chime',
    'battery': 'beep',
    'network': 'gentle',
  };

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // ✅ تحميل إعدادات النوتيفيكيشن والأصوات
  Future<void> _loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _geofencingEnabled = prefs.getBool('geofencing_enabled') ?? true;
      _emergencyAlertsEnabled =
          prefs.getBool('emergency_alerts_enabled') ?? true;
      _connectivityAlertsEnabled =
          prefs.getBool('connectivity_alerts_enabled') ?? true;
      _batteryAlertsEnabled = prefs.getBool('battery_alerts_enabled') ?? true;
      _networkAlertsEnabled = prefs.getBool('network_alerts_enabled') ?? true;
      _appUpdateNotificationsEnabled =
          prefs.getBool('app_update_notifications_enabled') ?? true;
      _betaUpdatesEnabled = prefs.getBool('beta_updates_enabled') ?? false;
      _redZoneAlertsEnabled = prefs.getBool('red_zone_alerts_enabled') ?? true;

      // ✅ تحميل إعدادات الأصوات
      _notificationSounds['geofencing'] =
          prefs.getString('geofencing_sound') ?? 'default';
      _notificationSounds['red_zone'] =
          prefs.getString('red_zone_sound') ?? 'urgent';
      _notificationSounds['emergency'] =
          prefs.getString('emergency_sound') ?? 'alert';
      _notificationSounds['connectivity'] =
          prefs.getString('connectivity_sound') ?? 'chime';
      _notificationSounds['battery'] =
          prefs.getString('battery_sound') ?? 'beep';
      _notificationSounds['network'] =
          prefs.getString('network_sound') ?? 'gentle';
    });
  }

  // ✅ حفظ إعدادات النوتيفيكيشن
  Future<void> _saveNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('geofencing_enabled', _geofencingEnabled);
    await prefs.setBool('emergency_alerts_enabled', _emergencyAlertsEnabled);
    await prefs.setBool(
        'connectivity_alerts_enabled', _connectivityAlertsEnabled);
    await prefs.setBool('battery_alerts_enabled', _batteryAlertsEnabled);
    await prefs.setBool('network_alerts_enabled', _networkAlertsEnabled);
    await prefs.setBool(
        'app_update_notifications_enabled', _appUpdateNotificationsEnabled);
    await prefs.setBool('beta_updates_enabled', _betaUpdatesEnabled);
    await prefs.setBool('red_zone_alerts_enabled', _redZoneAlertsEnabled);
  }

  // ✅ دالة للتعامل مع تغيير الصوت
  void _handleSoundChange(String notificationType, String newSound) {
    setState(() {
      _notificationSounds[notificationType] = newSound;
    });
    print('🔊 Sound changed for $notificationType: $newSound');
  }

  // Control Geofencing (Safe Zone) notifications
  void _handleGeofencingToggle(bool value) {
    setState(() {
      _geofencingEnabled = value;
    });
    _saveNotificationSettings();

    if (!value) {
      _notificationService.reset();
      print('🔴 Geofencing notifications disabled');
      _showSnackBar('Safe zone notifications disabled', Colors.red);
    } else {
      print('🟢 Geofencing notifications enabled');
      _showSnackBar('Safe zone notifications enabled', Colors.green);
    }
  }

  // ✅ Control Red Zone notifications
  void _handleRedZoneToggle(bool value) {
    setState(() {
      _redZoneAlertsEnabled = value;
    });
    _saveNotificationSettings();

    if (!value) {
      _notificationService.reset();
      print('🔥 Red Zone notifications disabled');
      _showSnackBar('Red Zone notifications disabled', Colors.red);
    } else {
      print('🔥 Red Zone notifications enabled');
      _showSnackBar('Red Zone notifications enabled', Colors.orange);
    }
  }

  // Control emergency notifications
  void _handleEmergencyAlertsToggle(bool value) {
    setState(() {
      _emergencyAlertsEnabled = value;
    });
    _saveNotificationSettings();

    if (!value) {
      print('🔴 Emergency alerts disabled');
      _showSnackBar('Emergency alerts disabled', Colors.red);
    } else {
      print('🟢 Emergency alerts enabled');
      _showSnackBar('Emergency alerts enabled', Colors.green);
    }
  }

  // Control connectivity notifications
  void _handleConnectivityAlertsToggle(bool value) {
    setState(() {
      _connectivityAlertsEnabled = value;
    });
    _saveNotificationSettings();

    if (!value) {
      print('🔴 Connectivity alerts disabled');
      _showSnackBar('Connectivity alerts disabled', Colors.red);
    } else {
      print('🟢 Connectivity alerts enabled');
      _showSnackBar('Connectivity alerts enabled', Colors.green);
    }
  }

  // Show confirmation message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ Updated reset function to include Red Zone and sounds
  void _resetAllNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Notifications'),
          content: const Text(
              'Are you sure you want to disable all notifications and reset settings?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _notificationService.reset();
                setState(() {
                  _geofencingEnabled = false;
                  _emergencyAlertsEnabled = false;
                  _connectivityAlertsEnabled = false;
                  _batteryAlertsEnabled = false;
                  _networkAlertsEnabled = false;
                  _appUpdateNotificationsEnabled = false;
                  _betaUpdatesEnabled = false;
                  _redZoneAlertsEnabled = false;

                  // ✅ إعادة تعيين الأصوات للافتراضية
                  _notificationSounds = {
                    'geofencing': 'default',
                    'red_zone': 'default',
                    'emergency': 'default',
                    'connectivity': 'default',
                    'battery': 'default',
                    'network': 'default',
                  };
                });
                _saveNotificationSettings();
                Navigator.of(context).pop();
                _showSnackBar('All notifications reset', Colors.orange);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: BackgroundLanding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _resetAllNotifications,
                        tooltip: 'Reset All',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.115),

            // Replace CircleAvatar with ProfilePictureWidget
            Center(
              child: ProfilePictureWidget(
                size: screenWidth * 0.32,
                onImageChanged: () {
                  setState(() {});
                },
                showEditIcon: true,
                defaultImagePath: 'assets/images/pro.png',
              ),
            ),
            SizedBox(height: screenHeight * 0.000001),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: ListView(
                    children: [
                      // ✅ Location Alerts section with sound controls
                      _buildSection(
                        title: 'Location Alerts',
                        children: [
                          _buildSwitchOptionWithSound(
                            'Geofencing',
                            _geofencingEnabled,
                            _handleGeofencingToggle,
                            'geofencing',
                            subtitle: 'Safe zone entry/exit alerts',
                          ),
                          _buildSwitchOptionWithSound(
                            'Red Zone Alerts',
                            _redZoneAlertsEnabled,
                            _handleRedZoneToggle,
                            'red_zone',
                            subtitle: 'Dangerous area alerts',
                          ),
                          _buildSwitchOptionWithSound(
                            'Emergency Alerts',
                            _emergencyAlertsEnabled,
                            _handleEmergencyAlertsToggle,
                            'emergency',
                            subtitle: 'Critical location alerts',
                          ),
                          _buildSwitchOptionWithSound(
                            'Connectivity Alerts',
                            _connectivityAlertsEnabled,
                            _handleConnectivityAlertsToggle,
                            'connectivity',
                            subtitle: 'Device connection status',
                          ),
                        ],
                      ),

                      // ✅ Device Alerts section with sound controls
                      _buildSection(
                        title: 'Device Alerts',
                        children: [
                          _buildSwitchOptionWithSound(
                            'Battery Alerts',
                            _batteryAlertsEnabled,
                            (value) {
                              setState(() => _batteryAlertsEnabled = value);
                              _saveNotificationSettings();
                            },
                            'battery',
                            subtitle: 'Low battery warnings',
                          ),
                          _buildSwitchOptionWithSound(
                            'Network Alerts',
                            _networkAlertsEnabled,
                            (value) {
                              setState(() => _networkAlertsEnabled = value);
                              _saveNotificationSettings();
                            },
                            'network',
                            subtitle: 'Network connectivity issues',
                          ),
                        ],
                      ),

                      // ✅ App Updates section (without sound controls)
                      _buildSection(
                        title: 'App Updates',
                        children: [
                          _buildSwitchOption(
                            'App Update Notifications',
                            _appUpdateNotificationsEnabled,
                            (value) {
                              setState(
                                  () => _appUpdateNotificationsEnabled = value);
                              _saveNotificationSettings();
                            },
                            subtitle: 'New version available',
                          ),
                          _buildSwitchOption(
                            'Beta Updates',
                            _betaUpdatesEnabled,
                            (value) {
                              setState(() => _betaUpdatesEnabled = value);
                              _saveNotificationSettings();
                            },
                            subtitle: 'Early access features',
                          ),
                        ],
                      ),

                      // ✅ Add status section
                      SizedBox(height: screenHeight * 0.02),
                      _buildStatusSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Show current status
  Widget _buildStatusSection() {
    Map<String, dynamic> status = _notificationService.getCurrentStatus();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Current Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
              'Bracelet ID', status['bracelet_id'] ?? 'Not connected'),
          _buildStatusRow(
              'Connected', status['is_connected'] == true ? '✅ Yes' : '❌ No'),
          _buildStatusRow(
              'Safe Zone Timer',
              status['safe_zone_timer_active'] == true
                  ? '🔴 Active'
                  : '⚫ Inactive'),
          _buildStatusRow(
              'Red Zone Timer',
              status['red_zone_timer_active'] == true
                  ? '🔥 Active'
                  : '⚫ Inactive'),
          _buildStatusRow(
              'Stationary Timer',
              status['stationary_timer_active'] == true
                  ? '🟠 Active'
                  : '⚫ Inactive'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  // ✅ Switch option with sound control
  Widget _buildSwitchOptionWithSound(String label, bool value,
      Function(bool) onChanged, String notificationType,
      {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: value ? Colors.green[50] : Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Main switch row
            Row(
              children: [
                Icon(
                  value ? Icons.notifications_active : Icons.notifications_off,
                  color: value ? AppColors.primaryColor : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primaryColor,
                  activeColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),

            // ✅ Sound picker row (shown only when enabled)
            if (value) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 36), // Same width as icon + spacing
                  const Text(
                    'sound:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  NotificationSoundWidget(
                    notificationType: notificationType,
                    onSoundChanged: (newSound) =>
                        _handleSoundChange(notificationType, newSound),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Regular switch option without sound (for app updates)
  Widget _buildSwitchOption(String label, bool value, Function(bool) onChanged,
      {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: value ? Colors.green[50] : Colors.grey[50],
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primaryColor,
        activeColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
        secondary: Icon(
          value ? Icons.notifications_active : Icons.notifications_off,
          color: value ? AppColors.primaryColor : Colors.grey,
        ),
      ),
    );
  }

  // ✅ Check notification settings before sending
  bool shouldSendNotification(String notificationType) {
    switch (notificationType) {
      case 'geofencing':
        return _geofencingEnabled;
      case 'red_zone':
        return _redZoneAlertsEnabled;
      case 'emergency':
        return _emergencyAlertsEnabled;
      case 'connectivity':
        return _connectivityAlertsEnabled;
      case 'battery':
        return _batteryAlertsEnabled;
      case 'network':
        return _networkAlertsEnabled;
      default:
        return false;
    }
  }

  // ✅ Get selected sound for notification type
  String getNotificationSound(String notificationType) {
    return _notificationSounds[notificationType] ?? 'default';
  }
}
