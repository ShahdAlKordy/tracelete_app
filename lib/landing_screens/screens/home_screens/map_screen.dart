import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tracelet_app/services/noti_service/NotificationService.dart';
import 'package:tracelet_app/landing_screens/screens/home_screens/ChildLocationMarker.dart';
import 'package:tracelet_app/landing_screens/screens/home_screens/CustomTopSnackBar.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';
import 'dart:math' as math;

class GoogleMapScreen extends StatefulWidget {
  @override
  _BraceletLocationScreenState createState() => _BraceletLocationScreenState();
}

class _BraceletLocationScreenState extends State<GoogleMapScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService = NotificationService();

  List<BraceletModel> _activeBracelets = [];
  Map<String, LatLng> _braceletLocations = {};
  Map<String, bool> _braceletConnections = {};
  Map<String, bool> _braceletStationaryStatus = {};
  Map<String, bool> _braceletOutsideSafeZone = {};
  Map<String, bool> _braceletInRedZone = {};

  bool isLoading = true;
  GoogleMapController? mapController;

  Map<String, List<LatLng>> _safeZonePoints = {};
  Map<String, List<LatLng>> _redZonePoints = {};

  Map<String, StreamSubscription<DatabaseEvent>> _locationListeners = {};
  Map<String, StreamSubscription<DatabaseEvent>> _connectionListeners = {};
  Map<String, StreamSubscription<DatabaseEvent>> _stationaryListeners = {};

  Map<String, Marker> _braceletMarkers = {};

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _notificationService.initialize();
    await _loadActiveBracelets();
    await _initFCM();

    if (_activeBracelets.isNotEmpty) {
      await _setupAllBracelets();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadActiveBracelets() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final QuerySnapshot braceletsSnapshot = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .where("is_active", isEqualTo: true)
          .get();

      final List<BraceletModel> loadedBracelets =
          braceletsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BraceletModel(
          id: data['bracelet_id'] ?? doc.id,
          name: data['name'] ?? 'Bracelet ${doc.id}',
        );
      }).toList();

      setState(() {
        _activeBracelets = loadedBracelets;
      });
    } catch (e) {
      print("Error loading bracelets: $e");
    }
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();

    if (fcmToken != null) {
      for (BraceletModel bracelet in _activeBracelets) {
        await dbRef
            .child("bracelets/${bracelet.id}/user_info/fcm_token")
            .set(fcmToken);
      }
    }
  }

  Future<void> _setupAllBracelets() async {
    for (BraceletModel bracelet in _activeBracelets) {
      _setupBraceletListeners(bracelet.id);
      await _loadBraceletZones(bracelet.id);
      await _checkBraceletConnectionAndLoadLocation(bracelet.id);
    }
  }

  void _setupBraceletListeners(String braceletId) {
    _locationListeners[braceletId] =
        dbRef.child("bracelets/$braceletId/location").onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map;
        final lat = double.tryParse(data['lat'].toString());
        final lng = double.tryParse(data['lng'].toString());

        if (lat != null && lng != null) {
          setState(() {
            _braceletLocations[braceletId] = LatLng(lat, lng);
          });
          _checkBraceletLocationStatus(braceletId);
          _updateBraceletMarker(braceletId);
        }
      }
    });

    _connectionListeners[braceletId] = dbRef
        .child("bracelets/$braceletId/user_info/connected")
        .onValue
        .listen((event) {
      bool connected = false;
      if (event.snapshot.exists) {
        connected = event.snapshot.value == true;
      }

      setState(() {
        _braceletConnections[braceletId] = connected;
      });

      _updateBraceletNotificationService(braceletId);
      if (connected) {
        _updateBraceletMarker(braceletId);
      }
    });

    _stationaryListeners[braceletId] = dbRef
        .child("bracelets/$braceletId/status/stationary")
        .onValue
        .listen((event) {
      bool stationaryStatus = false;
      if (event.snapshot.exists) {
        stationaryStatus = event.snapshot.value == true;
      }

      setState(() {
        _braceletStationaryStatus[braceletId] = stationaryStatus;
      });

      _updateBraceletNotificationService(braceletId);
    });
  }

  Future<void> _updateBraceletMarker(String braceletId) async {
    final location = _braceletLocations[braceletId];
    if (location == null) return;

    final isInRedZone = _braceletInRedZone[braceletId] ?? false;
    final isOutsideSafeZone = _braceletOutsideSafeZone[braceletId] ?? false;
    final isStationary = _braceletStationaryStatus[braceletId] ?? false;
    final isConnected = _braceletConnections[braceletId] ?? false;

    final braceletName = _activeBracelets
        .firstWhere((b) => b.id == braceletId,
            orElse: () => BraceletModel(id: braceletId, name: 'Unknown'))
        .name;

    try {
      final marker = await ChildLocationMarker.createBraceletMarker(
        braceletId: braceletId,
        position: location,
        isInRedZone: isInRedZone,
        isOutsideSafeZone: isOutsideSafeZone,
      );

      final updatedMarker = marker.copyWith(
        infoWindowParam: InfoWindow(
          title: braceletName,
          snippet: !isConnected
              ? "❌ Disconnected"
              : isInRedZone
                  ? "🚨 In Red Zone!"
                  : isOutsideSafeZone
                      ? "⚠️ Outside Safe Zone"
                      : isStationary
                          ? "⏸️ Stationary"
                          : "✅ Safe",
        ),
      );

      setState(() {
        _braceletMarkers[braceletId] = updatedMarker;
      });
    } catch (e) {
      setState(() {
        _braceletMarkers[braceletId] = Marker(
          markerId: MarkerId(braceletId),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            !isConnected
                ? BitmapDescriptor.hueViolet
                : isInRedZone
                    ? BitmapDescriptor.hueRed
                    : isOutsideSafeZone
                        ? BitmapDescriptor.hueOrange
                        : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: braceletName,
            snippet: !isConnected
                ? "❌ Disconnected"
                : isInRedZone
                    ? "🚨 In Red Zone!"
                    : isOutsideSafeZone
                        ? "⚠️ Outside Safe Zone"
                        : isStationary
                            ? "⏸️ Stationary"
                            : "✅ Safe",
          ),
        );
      });
    }
  }

  void _checkBraceletLocationStatus(String braceletId) {
    final location = _braceletLocations[braceletId];
    if (location == null) return;

    bool outsideSafe = false;
    bool insideRed = false;

    final safeZonePoints = _safeZonePoints[braceletId];
    if (safeZonePoints != null && safeZonePoints.length >= 3) {
      outsideSafe = !_isPointInPolygon(location, safeZonePoints);
    }

    final redZonePoints = _redZonePoints[braceletId];
    if (redZonePoints != null && redZonePoints.length >= 3) {
      insideRed = _isPointInPolygon(location, redZonePoints);
    }

    setState(() {
      _braceletOutsideSafeZone[braceletId] = outsideSafe;
      _braceletInRedZone[braceletId] = insideRed;
    });

    dbRef.child("bracelets/$braceletId/alerts/out_of_zone").set(outsideSafe);
    dbRef.child("bracelets/$braceletId/alerts/in_red_zone").set(insideRed);

    _updateBraceletNotificationService(braceletId);
  }

  void _updateBraceletNotificationService(String braceletId) {
    final braceletName = _activeBracelets
        .firstWhere((b) => b.id == braceletId,
            orElse: () => BraceletModel(id: braceletId, name: 'Unknown'))
        .name;

    _notificationService.updateBraceletStatus(
      braceletId: braceletId,
      braceletName: braceletName,
      isConnected: _braceletConnections[braceletId] ?? false,
      isOutsideSafeZone: _braceletOutsideSafeZone[braceletId] ?? false,
      isInRedZone: _braceletInRedZone[braceletId] ?? false, isStationary: true,
    );
  }

  Future<void> _loadBraceletZones(String braceletId) async {
    await _loadBraceletSafeZone(braceletId);
    await _loadBraceletRedZone(braceletId);
  }

  Future<void> _loadBraceletSafeZone(String braceletId) async {
    try {
      final safeZoneSnapshot =
          await dbRef.child("bracelets/$braceletId/safe_zone_polygon").get();

      if (safeZoneSnapshot.exists) {
        final data = safeZoneSnapshot.value as Map;
        List<LatLng> points = [];

        for (int i = 0; i < 4; i++) {
          if (data.containsKey('point$i')) {
            Map pointData = data['point$i'] as Map;
            double? lat = double.tryParse(pointData['lat'].toString());
            double? lng = double.tryParse(pointData['lng'].toString());

            if (lat != null && lng != null) {
              points.add(LatLng(lat, lng));
            }
          }
        }

        if (points.length >= 3) {
          setState(() {
            _safeZonePoints[braceletId] = points;
          });
        }
      }
    } catch (e) {
      print("Error loading safe zone for $braceletId: $e");
    }
  }

  Future<void> _loadBraceletRedZone(String braceletId) async {
    try {
      final redZoneSnapshot =
          await dbRef.child("bracelets/$braceletId/red_zone_polygon").get();

      if (redZoneSnapshot.exists) {
        final data = redZoneSnapshot.value as Map;
        List<LatLng> points = [];

        for (int i = 0; i < 4; i++) {
          if (data.containsKey('point$i')) {
            Map pointData = data['point$i'] as Map;
            double? lat = double.tryParse(pointData['lat'].toString());
            double? lng = double.tryParse(pointData['lng'].toString());

            if (lat != null && lng != null) {
              points.add(LatLng(lat, lng));
            }
          }
        }

        if (points.length >= 3) {
          setState(() {
            _redZonePoints[braceletId] = points;
          });
        }
      }
    } catch (e) {
      print("Error loading red zone for $braceletId: $e");
    }
  }

  Future<void> _checkBraceletConnectionAndLoadLocation(
      String braceletId) async {
    try {
      final connectedSnapshot =
          await dbRef.child("bracelets/$braceletId/user_info/connected").get();

      bool isConnected = false;
      if (connectedSnapshot.exists && connectedSnapshot.value == true) {
        isConnected = true;

        final locationSnapshot =
            await dbRef.child("bracelets/$braceletId/location").get();

        if (locationSnapshot.exists) {
          final data = locationSnapshot.value as Map;
          final lat = double.tryParse(data['lat'].toString());
          final lng = double.tryParse(data['lng'].toString());

          if (lat != null && lng != null) {
            setState(() {
              _braceletLocations[braceletId] = LatLng(lat, lng);
            });
            _checkBraceletLocationStatus(braceletId);
            await _updateBraceletMarker(braceletId);
          }
        }

        final stationarySnapshot =
            await dbRef.child("bracelets/$braceletId/status/stationary").get();

        if (stationarySnapshot.exists) {
          setState(() {
            _braceletStationaryStatus[braceletId] =
                stationarySnapshot.value == true;
          });
        }
      }

      setState(() {
        _braceletConnections[braceletId] = isConnected;
      });
    } catch (e) {
      setState(() {
        _braceletConnections[braceletId] = false;
      });
    }

    _updateBraceletNotificationService(braceletId);
  }

  void _centerOnAllBracelets() {
    if (_braceletLocations.isEmpty || mapController == null) return;

    if (_braceletLocations.length == 1) {
      final location = _braceletLocations.values.first;
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16),
        ),
      );
    } else {
      final locations = _braceletLocations.values.toList();
      double minLat = locations.first.latitude;
      double maxLat = locations.first.latitude;
      double minLng = locations.first.longitude;
      double maxLng = locations.first.longitude;

      for (LatLng location in locations) {
        minLat = math.min(minLat, location.latitude);
        maxLat = math.max(maxLat, location.latitude);
        minLng = math.min(minLng, location.longitude);
        maxLng = math.max(maxLng, location.longitude);
      }

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0,
        ),
      );
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude < point.longitude &&
                  polygon[j].longitude >= point.longitude ||
              polygon[j].longitude < point.longitude &&
                  polygon[i].longitude >= point.longitude) &&
          (polygon[i].latitude +
                  (point.longitude - polygon[i].longitude) /
                      (polygon[j].longitude - polygon[i].longitude) *
                      (polygon[j].latitude - polygon[i].latitude) <
              point.latitude)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    await _loadActiveBracelets();

    _braceletLocations.clear();
    _braceletConnections.clear();
    _braceletStationaryStatus.clear();
    _braceletOutsideSafeZone.clear();
    _braceletInRedZone.clear();
    _braceletMarkers.clear();
    _safeZonePoints.clear();
    _redZonePoints.clear();

    _locationListeners.values.forEach((listener) => listener.cancel());
    _connectionListeners.values.forEach((listener) => listener.cancel());
    _stationaryListeners.values.forEach((listener) => listener.cancel());

    _locationListeners.clear();
    _connectionListeners.clear();
    _stationaryListeners.clear();

    if (_activeBracelets.isNotEmpty) {
      await _setupAllBracelets();
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _locationListeners.values.forEach((listener) => listener.cancel());
    _connectionListeners.values.forEach((listener) => listener.cancel());
    _stationaryListeners.values.forEach((listener) => listener.cancel());
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasConnectedBracelets =
        _braceletConnections.values.any((connected) => connected);
    bool hasOutsideSafeZone =
        _braceletOutsideSafeZone.values.any((outside) => outside);
    bool hasInRedZone = _braceletInRedZone.values.any((inRed) => inRed);
    bool hasStationary =
        _braceletStationaryStatus.values.any((stationary) => stationary);

    return Scaffold(
      body: Stack(
        children: [
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (_activeBracelets.isEmpty)
            Center(
              child: Text(
                'No bracelets configured',
                style: TextStyle(fontSize: 18),
              ),
            )
          else if (!hasConnectedBracelets)
            Center(
              child: Text(
                'No bracelets connected currently',
                style: TextStyle(fontSize: 18),
              ),
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _braceletLocations.isNotEmpty
                    ? _braceletLocations.values.first
                    : LatLng(0, 0),
                zoom: 16,
              ),
              markers: Set<Marker>.from(_braceletMarkers.values),
              onMapCreated: (controller) {
                mapController = controller;
              },
            ),
          CustomTopSnackBar(
            isLoading: isLoading,
            isConnected: hasConnectedBracelets,
            isOutsideSafeZone: hasOutsideSafeZone,
            isStationary: hasStationary,
            isInRedZone: hasInRedZone,
            braceletLocation: _braceletLocations.isNotEmpty
                ? _braceletLocations.values.first
                : null,
            onRefresh: _refreshData,
            onCenterLocation: _centerOnAllBracelets,
          ),
        ],
      ),
    );
  }
}
