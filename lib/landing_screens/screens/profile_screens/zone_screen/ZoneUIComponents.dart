import 'package:flutter/material.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneScreen_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneData.dart';
// Remove the old import and use the BraceletModel from ZoneData.dart instead

class ZoneUIComponents {
  static Widget buildBraceletSelector({
    required List<BraceletModel> bracelets, // Now uses BraceletModel from ZoneData.dart
    required String? selectedBraceletId,
    required Function(String) onBraceletChanged,
  }) {
    if (bracelets.length <= 1) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Bracelet:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          DropdownButton<String>(
            value: selectedBraceletId,
            isExpanded: true,
            items: bracelets.map((bracelet) {
              return DropdownMenuItem<String>(
                value: bracelet.id,
                child: Text(bracelet.name, style: TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onBraceletChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  static Widget buildZoneTypeSelector({
    required ZoneType currentZoneType,
    required Function(ZoneType) onZoneTypeChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Zone Type:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onZoneTypeChanged(ZoneType.safe),
                  icon: Icon(Icons.shield, size: 16),
                  label: Text("Safe Zone", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentZoneType == ZoneType.safe
                        ? Colors.green
                        : Colors.grey[300],
                    foregroundColor: currentZoneType == ZoneType.safe
                        ? Colors.white
                        : Colors.black,
                    minimumSize: Size(0, 36),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onZoneTypeChanged(ZoneType.red),
                  icon: Icon(Icons.warning, size: 16),
                  label: Text("Red Zone", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentZoneType == ZoneType.red
                        ? Colors.red
                        : Colors.grey[300],
                    foregroundColor: currentZoneType == ZoneType.red
                        ? Colors.white
                        : Colors.black,
                    minimumSize: Size(0, 36),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildRedZoneModeSelector({
    required RedZoneMode currentMode,
    required Function(RedZoneMode) onModeChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Red Zone Mode:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onModeChanged(RedZoneMode.auto),
                  icon: Icon(Icons.auto_mode, size: 14),
                  label: Text(
                    "Auto\n(Roads & Water)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentMode == RedZoneMode.auto
                        ? Colors.red[600]
                        : Colors.grey[300],
                    foregroundColor: currentMode == RedZoneMode.auto
                        ? Colors.white
                        : Colors.black,
                    minimumSize: Size(0, 42),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onModeChanged(RedZoneMode.custom),
                  icon: Icon(Icons.edit_location, size: 14),
                  label: Text(
                    "Custom\n(Select Points)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentMode == RedZoneMode.custom
                        ? Colors.red[600]
                        : Colors.grey[300],
                    foregroundColor: currentMode == RedZoneMode.custom
                        ? Colors.white
                        : Colors.black,
                    minimumSize: Size(0, 42),
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildInstructions({
    required ZoneType zoneType,
    required RedZoneMode? redZoneMode,
    required int currentPoints,
    required int maxPoints,
    required String? braceletName,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          if (zoneType == ZoneType.red && redZoneMode == RedZoneMode.auto)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.info, color: Colors.red, size: 18),
                  SizedBox(height: 4),
                  Text(
                    "Auto Red Zone Active",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "All roads and water bodies are marked as danger zones",
                    style: TextStyle(fontSize: 11, color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Text(
                  zoneType == ZoneType.safe
                      ? "Tap on the map to set up to $maxPoints safe zone points"
                      : "Tap on the map to set up to $maxPoints custom red zone points",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: zoneType == ZoneType.safe ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Points set: $currentPoints of $maxPoints",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          if (braceletName != null)
            Text(
              "Managing zones for: $braceletName",
              style: TextStyle(fontSize: 11, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  static Widget buildActionButtons({
    required ZoneType zoneType,
    required RedZoneMode? redZoneMode,
    required int currentPoints,
    required bool hasExistingZone,
    required VoidCallback onSave,
    required VoidCallback onDelete,
    required VoidCallback? onReset,
  }) {
    String zoneName = _getZoneTypeName(zoneType, redZoneMode);
    String saveButtonText = zoneType == ZoneType.red && redZoneMode == RedZoneMode.auto
        ? "Activate Auto Red Zone"
        : "Save $zoneName";

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  child: Text(saveButtonText, style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zoneType == ZoneType.safe ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 38),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: (currentPoints > 0 || hasExistingZone) ? onDelete : null,
                  child: Text("Delete $zoneName", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 38),
                  ),
                ),
              ),
            ],
          ),
          if (onReset != null) ...[
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: currentPoints > 0 ? onReset : null,
                child: Text("Reset Points", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(0, 38),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _getZoneTypeName(ZoneType type, RedZoneMode? mode) {
    if (type == ZoneType.safe) {
      return 'Safe Zone';
    } else {
      return mode == RedZoneMode.auto
          ? 'Auto Red Zone'
          : 'Custom Red Zone';
    }
  }
}