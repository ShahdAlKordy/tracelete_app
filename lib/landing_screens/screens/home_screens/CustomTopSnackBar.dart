import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomTopSnackBar extends StatefulWidget {
  final bool isLoading;
  final bool isConnected;
  final bool isOutsideSafeZone;
  final bool isStationary;
  final bool isInRedZone;
  final LatLng? braceletLocation;
  final VoidCallback onRefresh;
  final VoidCallback onCenterLocation;

  const CustomTopSnackBar({
    Key? key,
    required this.isLoading,
    required this.isConnected,
    required this.isOutsideSafeZone,
    required this.isStationary,
    required this.isInRedZone,
    required this.braceletLocation,
    required this.onRefresh,
    required this.onCenterLocation,
  }) : super(key: key);

  @override
  _CustomTopSnackBarState createState() => _CustomTopSnackBarState();
}

class _CustomTopSnackBarState extends State<CustomTopSnackBar> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('profile_image_path');

      if (savedPath != null && File(savedPath).existsSync()) {
        setState(() {
          _profileImagePath = savedPath;
        });
      }
    } catch (e) {
      print("Error loading profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Profile Picture Circle
          _buildProfileCircle(),

          SizedBox(width: 12),

          // Location Details Rectangle
          Expanded(
            child: _buildLocationDetails(),
          ),

          SizedBox(width: 16),

          // Refresh Button
          _buildCircularButton(
            icon: Icons.refresh,
            onTap: widget.onRefresh,
            isLoading: widget.isLoading,
          ),

          SizedBox(width: 12),

          // Center Location Button
          _buildCircularButton(
            icon: Icons.my_location,
            onTap: widget.braceletLocation != null
                ? widget.onCenterLocation
                : null,
            isEnabled: widget.braceletLocation != null,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCircle() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getButtonColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getButtonColor().withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child:
            _profileImagePath != null && File(_profileImagePath!).existsSync()
                ? Image.file(
                    File(_profileImagePath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultProfileIcon();
                    },
                  )
                : _buildDefaultProfileIcon(),
      ),
    );
  }

  Widget _buildDefaultProfileIcon() {
    return Icon(
      Icons.person,
      color: Colors.white,
      size: 24,
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled && !isLoading ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isEnabled ? _getButtonColor() : Colors.grey[300],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isEnabled ? _getButtonColor() : Colors.grey)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.grey[600],
                size: 24,
              ),
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Connection Status Row
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getConnectionDotColor(),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                _getConnectionStatusText(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_shouldShowAlertIcon())
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    _getAlertIcon(),
                    color: Colors.white,
                    size: 12,
                  ),
                ),
            ],
          ),

          SizedBox(height: 2),

          // Status Text
          Text(
            _getLocationStatusText(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!widget.isConnected) return Colors.grey[600]!;
    if (widget.isInRedZone) return Colors.red[700]!;
    if (widget.isOutsideSafeZone) return Colors.orange[700]!;
    if (widget.isStationary) return Colors.amber[700]!;
    return Color(0xff243561);
  }

  Color _getButtonColor() {
    if (!widget.isConnected) return Colors.grey[600]!;
    if (widget.isInRedZone) return Colors.red[700]!;
    if (widget.isOutsideSafeZone) return Colors.orange[700]!;
    if (widget.isStationary) return Colors.amber[700]!;
    return Color(0xff243561);
  }

  Color _getConnectionDotColor() {
    if (!widget.isConnected) return Colors.red;
    if (widget.isInRedZone) return Colors.yellow;
    return Colors.green;
  }

  String _getConnectionStatusText() {
    if (!widget.isConnected) return 'Disconnected';
    if (widget.isInRedZone) return '🚨 RED ZONE';
    if (widget.isOutsideSafeZone) return '⚠️ Out of Zone';
    return 'Connected';
  }

  bool _shouldShowAlertIcon() {
    return widget.isConnected &&
        (widget.isInRedZone || widget.isOutsideSafeZone || widget.isStationary);
  }

  IconData _getAlertIcon() {
    if (widget.isInRedZone) return Icons.dangerous;
    if (widget.isOutsideSafeZone) return Icons.warning;
    if (widget.isStationary) return Icons.pause_circle_filled;
    return Icons.info;
  }

  String _getLocationStatusText() {
    if (!widget.isConnected) return 'No connection';
    if (widget.braceletLocation == null) return 'Searching for location...';

    if (widget.isInRedZone && widget.isStationary)
      return 'DANGER: Still in red zone';
    if (widget.isInRedZone) return 'DANGER: In restricted area';
    if (widget.isOutsideSafeZone && widget.isStationary)
      return 'Out of zone & stationary';
    if (widget.isOutsideSafeZone) return 'Outside safe zone';
    if (widget.isStationary) return 'Stationary for 5+ minutes';

    return 'Location active • Safe';
  }
}
