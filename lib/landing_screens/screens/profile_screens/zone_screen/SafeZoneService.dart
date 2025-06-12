import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/SafeZoneScreen_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneData.dart';

class SafeZoneService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const int maxPoints = 4;

  Future<ZoneData?> loadSafeZone(String braceletId) async {
    try {
      final snapshot = await _dbRef.child("bracelets/$braceletId/safe_zone_polygon").get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return ZoneData.fromMap(data, ZoneType.safe, maxPoints: maxPoints);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to load safe zone: $e');
    }
  }

  Future<void> saveSafeZone(String braceletId, List<LatLng> points) async {
    if (points.length < 3) {
      throw Exception('Please set at least 3 points to create a safe zone');
    }

    try {
      final zoneData = ZoneData(
        points: points,
        type: ZoneType.safe,
        name: 'Safe Zone',
      );

      await _dbRef.child("bracelets/$braceletId/safe_zone_polygon").set(zoneData.toMap());
    } catch (e) {
      throw Exception('Failed to save safe zone: $e');
    }
  }

  Future<void> deleteSafeZone(String braceletId) async {
    try {
      await _dbRef.child("bracelets/$braceletId/safe_zone_polygon").remove();
      await _dbRef.child("bracelets/$braceletId/safe_zone").remove(); // Legacy cleanup
    } catch (e) {
      throw Exception('Failed to delete safe zone: $e');
    }
  }

  bool validateSafeZone(List<LatLng> points) {
    return points.length >= 3;
  }

  String getSafeZoneStatusMessage(List<LatLng> points) {
    if (points.isEmpty) {
      return 'Tap on the map to add points for the safe zone';
    }
    
    if (points.length < 3) {
      return 'Add ${3 - points.length} more point(s) to complete the safe zone';
    }
    
    return 'Safe zone ready with ${points.length} points';
  }
}