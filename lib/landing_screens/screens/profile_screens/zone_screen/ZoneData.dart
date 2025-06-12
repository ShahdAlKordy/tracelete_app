import 'package:google_maps_flutter/google_maps_flutter.dart';

// Zone Types Enum
enum ZoneType { safe, red }

// Red Zone Mode Enum
enum RedZoneMode { auto, custom }

// Bracelet Model
class BraceletModel {
  final String id;
  final String name;

  BraceletModel({required this.id, required this.name});

  factory BraceletModel.fromMap(Map<String, dynamic> data, String docId) {
    return BraceletModel(
      id: data['bracelet_id'] ?? docId,
      name: data['name'] ?? 'Bracelet $docId',
    );
  }
}

// Zone Data Model
class ZoneData {
  final List<LatLng> points;
  final ZoneType type;
  final String name;
  final RedZoneMode? redZoneMode;

  ZoneData({
    required this.points,
    required this.type,
    required this.name,
    this.redZoneMode,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {};
    
    if (type == ZoneType.red) {
      data['mode'] = redZoneMode == RedZoneMode.auto ? 'auto' : 'custom';
      
      if (redZoneMode == RedZoneMode.custom) {
        for (int i = 0; i < points.length; i++) {
          data['point$i'] = {
            'lat': points[i].latitude,
            'lng': points[i].longitude,
          };
        }
      }
    } else {
      for (int i = 0; i < points.length; i++) {
        data['point$i'] = {
          'lat': points[i].latitude,
          'lng': points[i].longitude,
        };
      }
    }
    
    return data;
  }

  factory ZoneData.fromMap(Map data, ZoneType type, {int maxPoints = 4}) {
    List<LatLng> points = [];
    RedZoneMode? mode;
    
    if (type == ZoneType.red && data.containsKey('mode')) {
      mode = data['mode'] == 'auto' ? RedZoneMode.auto : RedZoneMode.custom;
    }
    
    if (type == ZoneType.safe || (type == ZoneType.red && mode == RedZoneMode.custom)) {
      for (int i = 0; i < maxPoints; i++) {
        if (data.containsKey('point$i')) {
          Map pointData = data['point$i'] as Map;
          double? lat = double.tryParse(pointData['lat'].toString());
          double? lng = double.tryParse(pointData['lng'].toString());

          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    }
    
    String zoneName = type == ZoneType.safe
        ? 'Safe Zone'
        : (mode == RedZoneMode.auto
            ? 'Auto Red Zone (Roads & Water)'
            : 'Custom Red Zone');
    
    return ZoneData(
      points: points,
      type: type,
      name: zoneName,
      redZoneMode: mode,
    );
  }
}