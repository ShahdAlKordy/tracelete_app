import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/RedZoneService.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/SafeZoneService.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneData.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneUIComponents.dart';
import 'dart:math' as math;



class ZoneManagementScreen extends StatefulWidget {
  @override
  _ZoneManagementScreenState createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SafeZoneService _safeZoneService = SafeZoneService();
  final RedZoneService _redZoneService = RedZoneService();

  GoogleMapController? _mapController;
  bool _isLoading = true;

  // Bracelets data
  List<BraceletModel> _activeBracelets = [];
  String? _braceletId;
  BraceletModel? get _selectedBracelet =>
      _activeBracelets.firstWhere((b) => b.id == _braceletId,
          orElse: () => BraceletModel(id: '', name: 'Unknown'));

  // Zone configuration
  ZoneType _currentZoneType = ZoneType.safe;
  RedZoneMode _currentRedZoneMode = RedZoneMode.custom;
  List<LatLng> _currentZonePoints = [];
  static const int _maxPoints = 4;

  // All zones for current bracelet
  Map<String, ZoneData> _allZones = {};

  // For bracelet location
  LatLng? _braceletLocation;
  static const LatLng _defaultLocation = LatLng(30.033333, 31.233334);

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBraceletId = prefs.getString('bracelet_id');

      await _loadActiveBracelets();

      if (_activeBracelets.isNotEmpty) {
        if (savedBraceletId != null &&
            _activeBracelets.any((b) => b.id == savedBraceletId)) {
          _braceletId = savedBraceletId;
        } else {
          _braceletId = _activeBracelets.first.id;
        }

        await _loadBraceletLocation();
        await _loadAllZones();
      }
    } catch (e) {
      _showSnackBar('Error initializing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

      final List<BraceletModel> loadedBracelets = braceletsSnapshot.docs
          .map((doc) => BraceletModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        _activeBracelets = loadedBracelets;
      });
    } catch (e) {
      _showSnackBar('Error loading bracelets: $e');
    }
  }

  Future<void> _switchBracelet(String newBraceletId) async {
    if (_braceletId == newBraceletId) return;

    setState(() {
      _braceletId = newBraceletId;
      _isLoading = true;
      _currentZonePoints.clear();
      _allZones.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bracelet_id', newBraceletId);

      await _loadBraceletLocation();
      await _loadAllZones();
    } catch (e) {
      _showSnackBar('Error switching bracelet: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBraceletLocation() async {
    if (_braceletId == null) return;

    try {
      final locationSnapshot =
          await _dbRef.child("bracelets/$_braceletId/location").get();

      if (locationSnapshot.exists) {
        final data = locationSnapshot.value as Map;
        final lat = double.tryParse(data['lat'].toString());
        final lng = double.tryParse(data['lng'].toString());

        if (lat != null && lng != null) {
          setState(() {
            _braceletLocation = LatLng(lat, lng);
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error loading location: $e');
    }
  }

  Future<void> _loadAllZones() async {
    if (_braceletId == null) return;

    try {
      // Load Safe Zone
      final safeZone = await _safeZoneService.loadSafeZone(_braceletId!);
      if (safeZone != null) {
        _allZones['safe_zone'] = safeZone;
      }

      // Load Red Zone
      final redZone = await _redZoneService.loadRedZone(_braceletId!);
      if (redZone != null) {
        _allZones['red_zone'] = redZone;
        
        if (_currentZoneType == ZoneType.red) {
          setState(() {
            _currentRedZoneMode = redZone.redZoneMode ?? RedZoneMode.custom;
          });
        }
      }

      setState(() {});
    } catch (e) {
      _showSnackBar('Error loading zones: $e');
    }
  }

  void _onMapTap(LatLng position) {
    if (_currentZoneType == ZoneType.red &&
        _currentRedZoneMode == RedZoneMode.auto) {
      return;
    }

    if (_currentZonePoints.length < _maxPoints) {
      setState(() {
        _currentZonePoints.add(position);
      });
    } else {
      int closestPointIndex = _findClosestPointIndex(position);
      setState(() {
        _currentZonePoints[closestPointIndex] = position;
      });
    }
  }

  int _findClosestPointIndex(LatLng tap) {
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _currentZonePoints.length; i++) {
      double distance = _calculateDistance(tap, _currentZonePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) * c(point2.latitude * p) *
        (1 - c((point2.longitude - point1.longitude) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void _onZoneTypeChanged(ZoneType newType) {
    setState(() {
      _currentZoneType = newType;
      _currentZonePoints.clear();
      
      // Load existing zone if available
      String zoneKey = newType == ZoneType.safe ? 'safe_zone' : 'red_zone';
      if (_allZones.containsKey(zoneKey)) {
        _currentZonePoints = List.from(_allZones[zoneKey]!.points);
        if (newType == ZoneType.red) {
          _currentRedZoneMode = _allZones[zoneKey]!.redZoneMode ?? RedZoneMode.custom;
        }
      }
    });
  }

  void _onRedZoneModeChanged(RedZoneMode newMode) {
    setState(() {
      _currentRedZoneMode = newMode;
      if (newMode == RedZoneMode.auto) {
        _currentZonePoints.clear();
      }
    });
  }

  Future<void> _saveCurrentZone() async {
    if (_braceletId == null) {
      _showSnackBar('No bracelet selected');
      return;
    }

    try {
      if (_currentZoneType == ZoneType.safe) {
        await _safeZoneService.saveSafeZone(_braceletId!, _currentZonePoints);
        _showSnackBar('Safe Zone Saved Successfully ✅');
      } else {
        await _redZoneService.saveRedZone(_braceletId!, _currentZonePoints, _currentRedZoneMode);
        _showSnackBar(_redZoneService.getSuccessMessage(_currentRedZoneMode));
      }

      await _loadAllZones();
    } catch (e) {
      _showSnackBar('Error saving zone: $e');
    }
  }

  Future<void> _deleteCurrentZone() async {
    if (_braceletId == null) {
      _showSnackBar('No bracelet selected');
      return;
    }

    try {
      if (_currentZoneType == ZoneType.safe) {
        await _safeZoneService.deleteSafeZone(_braceletId!);
        _showSnackBar('Safe Zone Deleted ✅');
      } else {
        await _redZoneService.deleteRedZone(_braceletId!);
        _showSnackBar('Red Zone Deleted ✅');
      }

      setState(() {
        _currentZonePoints.clear();
        String zoneKey = _currentZoneType == ZoneType.safe ? 'safe_zone' : 'red_zone';
        _allZones.remove(zoneKey);
      });
    } catch (e) {
      _showSnackBar('Error deleting zone: $e');
    }
  }

  void _resetPoints() {
    setState(() {
      _currentZonePoints.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Set<Polygon> _buildPolygons() {
    Set<Polygon> polygons = {};

    // Add existing zones
    _allZones.forEach((key, zone) {
      if (zone.points.isNotEmpty && zone.points.length >= 3) {
        Color color;
        String polygonId;
        
        if (zone.type == ZoneType.safe) {
          color = Colors.green.withOpacity(0.3);
          polygonId = 'safe_zone_existing';
        } else {
          color = Colors.red.withOpacity(0.3);
          polygonId = 'red_zone_existing';
        }

        polygons.add(Polygon(
          polygonId: PolygonId(polygonId),
          points: zone.points,
          fillColor: color,
          strokeColor: color.withOpacity(0.8),
          strokeWidth: 2,
        ));
      }
    });

    // Add current editing zone
    if (_currentZonePoints.length >= 3) {
      Color color = _currentZoneType == ZoneType.safe 
          ? Colors.green.withOpacity(0.5) 
          : Colors.red.withOpacity(0.5);

      polygons.add(Polygon(
        polygonId: PolygonId('current_zone'),
        points: _currentZonePoints,
        fillColor: color,
        strokeColor: color.withOpacity(1.0),
        strokeWidth: 3,
      ));
    }

    return polygons;
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // Add bracelet location marker
    if (_braceletLocation != null) {
      markers.add(Marker(
        markerId: MarkerId('bracelet_location'),
        position: _braceletLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Bracelet Location',
          snippet: _selectedBracelet?.name ?? 'Unknown Bracelet',
        ),
      ));
    }

    // Add current zone points
    for (int i = 0; i < _currentZonePoints.length; i++) {
      BitmapDescriptor icon = _currentZoneType == ZoneType.safe
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      markers.add(Marker(
        markerId: MarkerId('current_point_$i'),
        position: _currentZonePoints[i],
        icon: icon,
        infoWindow: InfoWindow(
          title: 'Point ${i + 1}',
          snippet: 'Tap to move this point',
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Zone Management'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activeBracelets.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Zone Management'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.watch_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Active Bracelets Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Please add and activate a bracelet first',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    bool hasExistingZone = _allZones.containsKey(
        _currentZoneType == ZoneType.safe ? 'safe_zone' : 'red_zone');

    return Scaffold(
      appBar: AppBar(
        title: Text('Zone Management'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Bracelet Selector
          ZoneUIComponents.buildBraceletSelector(
            bracelets: _activeBracelets,
            selectedBraceletId: _braceletId,
            onBraceletChanged: _switchBracelet,
          ),

          // Zone Type Selector
          ZoneUIComponents.buildZoneTypeSelector(
            currentZoneType: _currentZoneType,
            onZoneTypeChanged: _onZoneTypeChanged,
          ),

          // Red Zone Mode Selector (only for red zones)
          if (_currentZoneType == ZoneType.red)
            ZoneUIComponents.buildRedZoneModeSelector(
              currentMode: _currentRedZoneMode,
              onModeChanged: _onRedZoneModeChanged,
            ),

          // Instructions
          ZoneUIComponents.buildInstructions(
            zoneType: _currentZoneType,
            redZoneMode: _currentZoneType == ZoneType.red ? _currentRedZoneMode : null,
            currentPoints: _currentZonePoints.length,
            maxPoints: _maxPoints,
            braceletName: _selectedBracelet?.name,
          ),

          // Map
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                
                // Apply red zone style if in auto red zone mode
                if (_currentZoneType == ZoneType.red && _currentRedZoneMode == RedZoneMode.auto) {
                  controller.setMapStyle(RedZoneService.redZoneMapStyle);
                } else {
                  controller.setMapStyle(null);
                }
              },
              initialCameraPosition: CameraPosition(
                target: _braceletLocation ?? _defaultLocation,
                zoom: 15.0,
              ),
              onTap: _onMapTap,
              polygons: _buildPolygons(),
              markers: _buildMarkers(),
              mapType: MapType.normal,
            ),
          ),

          // Action Buttons
          ZoneUIComponents.buildActionButtons(
            zoneType: _currentZoneType,
            redZoneMode: _currentZoneType == ZoneType.red ? _currentRedZoneMode : null,
            currentPoints: _currentZonePoints.length,
            hasExistingZone: hasExistingZone,
            onSave: _saveCurrentZone,
            onDelete: _deleteCurrentZone,
            onReset: _currentZonePoints.isNotEmpty ? _resetPoints : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}