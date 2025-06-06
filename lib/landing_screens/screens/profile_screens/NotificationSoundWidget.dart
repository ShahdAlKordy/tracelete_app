import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSoundWidget extends StatefulWidget {
  final String notificationType;
  final Function(String)? onSoundChanged;

  const NotificationSoundWidget({
    Key? key,
    required this.notificationType,
    this.onSoundChanged,
  }) : super(key: key);

  @override
  _NotificationSoundWidgetState createState() =>
      _NotificationSoundWidgetState();
}

class _NotificationSoundWidgetState extends State<NotificationSoundWidget> {
  String _selectedSound = 'default';

  // List of available sounds
  final List<Map<String, String>> _availableSounds = [
    {'name': 'Default', 'value': 'default', 'icon': '🔔'},
    {'name': 'Beep', 'value': 'beep', 'icon': '📢'},
    {'name': 'Chime', 'value': 'chime', 'icon': '🎵'},
    {'name': 'Alert', 'value': 'alert', 'icon': '🚨'},
    {'name': 'Gentle', 'value': 'gentle', 'icon': '🔕'},
    {'name': 'Urgent', 'value': 'urgent', 'icon': '⚠️'},
    {'name': 'Silent', 'value': 'silent', 'icon': '🔇'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSoundSetting();
  }

  // Load saved sound setting
  Future<void> _loadSoundSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedSound =
        prefs.getString('${widget.notificationType}_sound') ?? 'default';
    setState(() {
      _selectedSound = savedSound;
    });
  }

  // Save selected sound
  Future<void> _saveSoundSetting(String sound) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${widget.notificationType}_sound', sound);
    setState(() {
      _selectedSound = sound;
    });

    // Notify parent of the change
    if (widget.onSoundChanged != null) {
      widget.onSoundChanged!(sound);
    }
  }

  // Show sound picker modal
  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Notification Sound',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Sound list
              Expanded(
                child: ListView.builder(
                  itemCount: _availableSounds.length,
                  itemBuilder: (context, index) {
                    final sound = _availableSounds[index];
                    final isSelected = _selectedSound == sound['value'];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Text(
                          sound['icon']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          sound['name']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.grey),
                                onPressed: () {
                                  // Play sound for preview
                                  _previewSound(sound['value']!);
                                },
                              ),
                        onTap: () {
                          _saveSoundSetting(sound['value']!);
                          Navigator.pop(context);
                          _showConfirmation(sound['name']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Preview sound
  void _previewSound(String soundValue) {
    // Here you can add code to play the actual sound
    print('🔊 Playing sound preview: $soundValue');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing preview: ${_getSoundName(soundValue)}'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Get sound name by value
  String _getSoundName(String value) {
    return _availableSounds.firstWhere(
      (sound) => sound['value'] == value,
      orElse: () => {'name': 'Default'},
    )['name']!;
  }

  // Show confirmation message
  void _showConfirmation(String soundName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sound changed to: $soundName'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentSoundName = _getSoundName(_selectedSound);
    String currentSoundIcon = _availableSounds.firstWhere(
      (sound) => sound['value'] == _selectedSound,
      orElse: () => {'icon': '🔔'},
    )['icon']!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _showSoundPicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentSoundIcon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  currentSoundName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
