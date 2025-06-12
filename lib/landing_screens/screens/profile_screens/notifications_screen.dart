import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/NotificationSoundWidget.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/ProfilePictureWidget.dart';
import 'package:tracelet_app/services/noti_service/NotificationService.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notification controls
  bool _geofencingEnabled = true;
  bool _emergencyAlertsEnabled = true; // Mapped to Stationary
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
    'emergency': 'alert', // Used for stationary
    'connectivity': 'chime',
    'battery': 'beep',
    'network': 'gentle',
  };

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadNotificationSettings();
  }

  // ✅ Initialize notification service
  Future<void> _initializeService() async {
    try {
      await _notificationService.initialize();
      print('NotificationService initialized in NotificationsScreen');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
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
    // Immediately update the service with loaded settings
    _updateNotificationServiceSettings();
  }

  // ✅ حفظ إعدادات النوتيفيكيشن وتحديث السيرفيس
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

    // ✅ حفظ إعدادات الأصوات
    for (String type in _notificationSounds.keys) {
      await prefs.setString('${type}_sound', _notificationSounds[type]!);
    }

    // ✅ تحديث إعدادات السيرفيس للنوتيفيكيشن
    _updateNotificationServiceSettings();

    print('Notification settings saved and service updated');
  }

  // ✅ New: Centralized function to update NotificationService settings
  void _updateNotificationServiceSettings() {
    _notificationService.updateNotificationSettings({
      'safe_zone_enabled': _geofencingEnabled,
      'red_zone_enabled': _redZoneAlertsEnabled,
      'stationary_enabled': _emergencyAlertsEnabled, // using emergency for stationary
      'connectivity_enabled': _connectivityAlertsEnabled,
      'battery_enabled': _batteryAlertsEnabled,
      'network_enabled': _networkAlertsEnabled,
      'app_update_enabled': _appUpdateNotificationsEnabled,
      'beta_updates_enabled': _betaUpdatesEnabled,
    });

    _notificationSounds.forEach((type, sound) {
      _notificationService.updateNotificationSound(type, sound);
    });
  }

  // ✅ دالة للتعامل مع تغيير الصوت
  void _handleSoundChange(String notificationType, String newSound) async {
    setState(() {
      _notificationSounds[notificationType] = newSound;
    });

    // حفظ الصوت الجديد
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${notificationType}_sound', newSound);

    // Update the service with the new sound
    _notificationService.updateNotificationSound(notificationType, newSound);

    print('🔊 Sound changed for $notificationType: $newSound');
  }

  // ✅ Control Geofencing (Safe Zone) notifications
  void _handleGeofencingToggle(bool value) async {
    setState(() {
      _geofencingEnabled = value;
    });
    await _saveNotificationSettings();

    if (!value) {
      print('🔴 Geofencing notifications disabled');
      _showSnackBar('Safe zone notifications disabled', Colors.red);
    } else {
      print('🟢 Geofencing notifications enabled');
      _showSnackBar('Safe zone notifications enabled', Colors.green);
    }
  }

  // ✅ Control Red Zone notifications
  void _handleRedZoneToggle(bool value) async {
    setState(() {
      _redZoneAlertsEnabled = value;
    });
    await _saveNotificationSettings();

    if (!value) {
      print('🔥 Red Zone notifications disabled');
      _showSnackBar('Red Zone notifications disabled', Colors.red);
    } else {
      print('🔥 Red Zone notifications enabled');
      _showSnackBar('Red Zone notifications enabled', Colors.orange);
    }
  }

  // ✅ Control emergency notifications (mapped to stationary)
  void _handleEmergencyAlertsToggle(bool value) async {
    setState(() {
      _emergencyAlertsEnabled = value;
    });
    await _saveNotificationSettings();

    if (!value) {
      print('🔴 Stationary alerts disabled');
      _showSnackBar('Movement alerts disabled', Colors.red);
    } else {
      print('🟢 Stationary alerts enabled');
      _showSnackBar('Movement alerts enabled', Colors.green);
    }
  }

  // ✅ Control connectivity notifications (UI only - not connected to service for actual events, but for test)
  void _handleConnectivityAlertsToggle(bool value) async {
    setState(() {
      _connectivityAlertsEnabled = value;
    });
    await _saveNotificationSettings();

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
              onPressed: () async {
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
                // ✅ Reset service after updating local state
                _notificationService.reset();
                await _saveNotificationSettings(); // Save the disabled state to SharedPreferences
                Navigator.of(context).pop();
                _showSnackBar('All notifications reset', Colors.orange);
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ Test notification function
  void _testNotification(String type) async {
    try {
      String braceletName = 'Test Bracelet';
      // The service will now check its internal settings before sending
      await _notificationService.sendTestNotification(type, braceletName);
      _showSnackBar('Test notification sent for $type (if enabled)', Colors.blue);
    } catch (e) {
      print('Error sending test notification: $e');
      _showSnackBar('Failed to send test notification', Colors.red);
    }
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
                            testFunction: () => _testNotification('safe_zone'),
                          ),
                          _buildSwitchOptionWithSound(
                            'Red Zone Alerts',
                            _redZoneAlertsEnabled,
                            _handleRedZoneToggle,
                            'red_zone',
                            subtitle: 'Dangerous area alerts',
                            testFunction: () => _testNotification('red_zone'),
                          ),
                          _buildSwitchOptionWithSound(
                            'Emergency Alerts',
                            _emergencyAlertsEnabled,
                            _handleEmergencyAlertsToggle,
                            'emergency',
                            subtitle: 'Movement detection alerts',
                            testFunction: () => _testNotification('stationary'),
                          ),
                          _buildSwitchOptionWithSound(
                            'Connectivity Alerts',
                            _connectivityAlertsEnabled,
                            _handleConnectivityAlertsToggle,
                            'connectivity',
                            subtitle: 'Device connection status',
                            testFunction: () => _testNotification('connectivity'), // Test connectivity
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
                            (value) async {
                              setState(() => _batteryAlertsEnabled = value);
                              await _saveNotificationSettings();
                            },
                            'battery',
                            subtitle: 'Low battery warnings',
                            testFunction: () => _testNotification('battery'), // Test battery
                          ),
                          _buildSwitchOptionWithSound(
                            'Network Alerts',
                            _networkAlertsEnabled,
                            (value) async {
                              setState(() => _networkAlertsEnabled = value);
                              await _saveNotificationSettings();
                            },
                            'network',
                            subtitle: 'Network connectivity issues',
                            testFunction: () => _testNotification('network'), // Test network
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
                            (value) async {
                              setState(
                                  () => _appUpdateNotificationsEnabled = value);
                              await _saveNotificationSettings();
                            },
                            subtitle: 'New version available',
                          ),
                          _buildSwitchOption(
                            'Beta Updates',
                            _betaUpdatesEnabled,
                            (value) async {
                              setState(() => _betaUpdatesEnabled = value);
                              await _saveNotificationSettings();
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

  // ✅ Show current status from notification service
  Widget _buildStatusSection() {
    // Get status from NotificationService
    Map<String, dynamic> status = _notificationService.getCurrentStatus();

    // Extract notification settings for display
    Map<String, bool> notificationSettings = status['notification_settings'] ?? {};

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
          _buildStatusRow('Service Initialized',
              status['initialized'] == true ? '✅ Yes' : '❌ No'),
          _buildStatusRow('Safe Zone Enabled',
              notificationSettings['safe_zone_enabled'] == true ? '✅ On' : '❌ Off'),
          _buildStatusRow('Red Zone Enabled',
              notificationSettings['red_zone_enabled'] == true ? '🔥 On' : '❌ Off'),
          _buildStatusRow('Stationary Enabled',
              notificationSettings['stationary_enabled'] == true ? '🟠 On' : '❌ Off'),
          _buildStatusRow('Connectivity Enabled',
              notificationSettings['connectivity_enabled'] == true ? '🔗 On' : '❌ Off'),
          _buildStatusRow('Battery Alerts Enabled',
              notificationSettings['battery_enabled'] == true ? '🔋 On' : '❌ Off'),
          _buildStatusRow('Network Alerts Enabled',
              notificationSettings['network_enabled'] == true ? '📡 On' : '❌ Off'),
          _buildStatusRow('App Updates Enabled',
              notificationSettings['app_update_enabled'] == true ? '⬆️ On' : '❌ Off'),
          _buildStatusRow('Beta Updates Enabled',
              notificationSettings['beta_updates_enabled'] == true ? '🧪 On' : '❌ Off'),
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

  // ✅ Switch option with sound control and optional test button
  Widget _buildSwitchOptionWithSound(String label, bool value,
      Function(bool) onChanged, String notificationType,
      {String? subtitle, VoidCallback? testFunction}) {
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
                // ✅ Test button for service-connected notifications
                if (testFunction != null && value)
                  IconButton(
                    icon: const Icon(Icons.texture_sharp, size: 20),
                    onPressed: testFunction,
                    tooltip: 'Test',
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

  // ✅ Check notification settings before sending (This is now redundant as service handles it)
  // bool shouldSendNotification(String notificationType) {
  //   switch (notificationType) {
  //     case 'geofencing':
  //       return _geofencingEnabled;
  //     case 'red_zone':
  //       return _redZoneAlertsEnabled;
  //     case 'emergency':
  //       return _emergencyAlertsEnabled;
  //     case 'connectivity':
  //       return _connectivityAlertsEnabled;
  //     case 'battery':
  //       return _batteryAlertsEnabled;
  //     case 'network':
  //       return _networkAlertsEnabled;
  //     default:
  //       return false;
  //   }
  // }

  // ✅ Get selected sound for notification type (This is now used to initialize NotificationSoundWidget)
  String getNotificationSound(String notificationType) {
    return _notificationSounds[notificationType] ?? 'default';
  }

  @override
  void dispose() {
    // Don't dispose the service here as it might be used elsewhere
    super.dispose();
  }
}