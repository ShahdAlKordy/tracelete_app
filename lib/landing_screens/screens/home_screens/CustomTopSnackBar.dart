import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomTopSnackBar extends StatelessWidget {
  final bool isLoading;
  final bool isConnected;
  final bool isOutsideSafeZone;
  final bool isStationary;
  final LatLng? braceletLocation;
  final VoidCallback onRefresh;
  final VoidCallback onCenterLocation;

  const CustomTopSnackBar({
    Key? key,
    required this.isLoading,
    required this.isConnected,
    required this.isOutsideSafeZone,
    required this.isStationary,
    required this.braceletLocation,
    required this.onRefresh,
    required this.onCenterLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Refresh Button
          _buildCircularButton(
            icon: Icons.refresh,
            onTap: onRefresh,
            isLoading: isLoading,
          ),

          SizedBox(width: 12),

          // Center Location Button
          _buildCircularButton(
            icon: Icons.my_location,
            onTap: braceletLocation != null ? onCenterLocation : null,
            isEnabled: braceletLocation != null,
          ),

          SizedBox(width: 16),

          // Location Details Rectangle
          Expanded(
            child: _buildLocationDetails(),
          ),
        ],
      ),
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
          color: isEnabled ? Color(0xff243561) : Colors.grey[300],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isEnabled ? Color(0xff243561) : Colors.grey)
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
      height: 48, // نفس ارتفاع الدواير
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xff243561),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xff243561).withOpacity(0.3),
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
                  color: isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 2),

          // Status Text
          Text(
            _getLocationStatusText(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getLocationStatusText() {
    if (!isConnected) return 'No connection';
    if (braceletLocation == null) return 'Searching for location...';
    if (isStationary) return 'Stationary for 5+ minutes';
    return 'Location active';
  }
}
