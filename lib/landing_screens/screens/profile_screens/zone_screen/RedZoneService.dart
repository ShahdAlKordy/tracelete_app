import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/SafeZoneScreen_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneData.dart';

class RedZoneService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const int maxPoints = 4;

  static const String redZoneMapStyle = '''
[
  {
    "featureType": "water",
    "stylers": [{"color": "#ffcccc"}, {"visibility": "on"}]
  },
  {
    "featureType": "road",
    "stylers": [{"color": "#ff4444"}, {"visibility": "on"}]
  },
  {
    "featureType": "road.highway",
    "stylers": [{"color": "#cc0000"}, {"visibility": "on"}]
  },
  {
    "featureType": "road.arterial",
    "stylers": [{"color": "#ff0000"}, {"visibility": "on"}]
  },
  {
    "featureType": "road.local",
    "stylers": [{"color": "#ff3333"}, {"visibility": "on"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#ff6666"}, {"visibility": "on"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#ffaaaa"}]
  },
  {
    "featureType": "landscape",
    "stylers": [{"color": "#ffe0e0"}]
  },
  {
    "featureType": "administrative",
    "stylers": [{"color": "#ff8888"}]
  }
]
  ''';

  Future<ZoneData?> loadRedZone(String braceletId) async {
    try {
      final snapshot = await _dbRef.child("bracelets/$braceletId/red_zone_polygon").get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return ZoneData.fromMap(data, ZoneType.red, maxPoints: maxPoints);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to load red zone: $e');
    }
  }

  Future<void> saveRedZone(String braceletId, List<LatLng> points, RedZoneMode mode) async {
    if (mode == RedZoneMode.custom && points.length < 3) {
      throw Exception('Please set at least 3 points to create a custom red zone');
    }

    try {
      final zoneData = ZoneData(
        points: mode == RedZoneMode.custom ? points : [],
        type: ZoneType.red,
        name: mode == RedZoneMode.auto 
            ? 'Auto Red Zone (Roads & Water)' 
            : 'Custom Red Zone',
        redZoneMode: mode,
      );

      await _dbRef.child("bracelets/$braceletId/red_zone_polygon").set(zoneData.toMap());
    } catch (e) {
      throw Exception('Failed to save red zone: $e');
    }
  }

  Future<void> deleteRedZone(String braceletId) async {
    try {
      await _dbRef.child("bracelets/$braceletId/red_zone_polygon").remove();
      await _dbRef.child("bracelets/$braceletId/red_zone").remove(); // Legacy cleanup
    } catch (e) {
      throw Exception('Failed to delete red zone: $e');
    }
  }

  bool validateRedZone(List<LatLng> points, RedZoneMode mode) {
    if (mode == RedZoneMode.auto) return true;
    return points.length >= 3;
  }

  String getRedZoneStatusMessage(List<LatLng> points, RedZoneMode mode) {
    if (mode == RedZoneMode.auto) {
      return 'Auto red zone active - all roads and water bodies are danger zones';
    }
    
    if (points.isEmpty) {
      return 'Tap on the map to add points for the custom red zone';
    }
    
    if (points.length < 3) {
      return 'Add ${3 - points.length} more point(s) to complete the red zone';
    }
    
    return 'Custom red zone ready with ${points.length} points';
  }

  String getSaveButtonText(RedZoneMode mode) {
    return mode == RedZoneMode.auto 
        ? 'Activate Auto Red Zone' 
        : 'Save Custom Red Zone';
  }

  String getSuccessMessage(RedZoneMode mode) {
    return mode == RedZoneMode.auto
        ? 'Auto Red Zone (Roads & Water) Activated ✅'
        : 'Custom Red Zone Saved Successfully ✅';
  }
}