import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tracelet_app/auth_service/NotificationService.dart';

class LiveLocationTrackingService {
  static final LiveLocationTrackingService _instance =
      LiveLocationTrackingService._internal();
  factory LiveLocationTrackingService() => _instance;
  LiveLocationTrackingService._internal();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final NotificationService _notificationService = NotificationService();

  // Location data
  LatLng? _currentBraceletLocation;
  LatLng? _lastKnownLocation;
  DateTime? _lastLocationUpdateTime;
  DateTime? _lastMovementTime;

  // Zone data
  List<LatLng> _safeZonePoints = [];
  List<LatLng> _redZonePoints = [];

  // Status tracking
  bool _isConnected = false;
  bool _isOutsideSafeZone = false;
  bool _isInRedZone = false;
  bool _isStationary = false;
  String? _currentBraceletId;

  // Movement tracking - تم تقليل الحد الأدنى للحركة إلى 1 متر
  static const double _movementThreshold = 1.0; // متر واحد بدلاً من 5
  static const int _stationaryThresholdMinutes = 5;

  // Stream subscriptions and timers
  StreamSubscription<DatabaseEvent>? _locationSubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  Timer? _motionCheckTimer;

  // Stream controllers for real-time updates
  final StreamController<LatLng?> _locationController =
      StreamController<LatLng?>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _safeZoneController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _redZoneController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _stationaryController =
      StreamController<bool>.broadcast();
  final StreamController<List<LatLng>> _safeZonePointsController =
      StreamController<List<LatLng>>.broadcast();
  final StreamController<List<LatLng>> _redZonePointsController =
      StreamController<List<LatLng>>.broadcast();

  // Public getters for streams
  Stream<LatLng?> get locationStream => _locationController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get safeZoneStream => _safeZoneController.stream;
  Stream<bool> get redZoneStream => _redZoneController.stream;
  Stream<bool> get stationaryStream => _stationaryController.stream;
  Stream<List<LatLng>> get safeZonePointsStream =>
      _safeZonePointsController.stream;
  Stream<List<LatLng>> get redZonePointsStream =>
      _redZonePointsController.stream;

  // Public getters for current values
  LatLng? get currentLocation => _currentBraceletLocation;
  bool get isConnected => _isConnected;
  bool get isOutsideSafeZone => _isOutsideSafeZone;
  bool get isInRedZone => _isInRedZone;
  bool get isStationary => _isStationary;
  List<LatLng> get safeZonePoints => List.from(_safeZonePoints);
  List<LatLng> get redZonePoints => List.from(_redZonePoints);

  // Initialize the service
  Future<void> initialize(String braceletId) async {
    _currentBraceletId = braceletId;

    await _notificationService.initialize();
    await _notificationService.saveFCMToken(braceletId);

    await _loadSafeZone(braceletId);
    await _loadRedZone(braceletId);
    await _startRealTimeTracking(braceletId);
    _startPeriodicChecks();

    print('LiveLocationTrackingService initialized for bracelet: $braceletId');
  }

  // Load safe zone from Firebase
  Future<void> _loadSafeZone(String braceletId) async {
    try {
      final safeZoneSnapshot =
          await _dbRef.child("bracelets/$braceletId/safe_zone_polygon").get();

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
          _safeZonePoints = points;
          _safeZonePointsController.add(_safeZonePoints);
          print('Safe zone loaded with ${points.length} points');
        }
      }
    } catch (e) {
      print('Error loading safe zone: $e');
    }
  }

  // Load Red Zone from Firebase
  Future<void> _loadRedZone(String braceletId) async {
    try {
      final redZoneSnapshot =
          await _dbRef.child("bracelets/$braceletId/red_zone_polygon").get();

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
          _redZonePoints = points;
          _redZonePointsController.add(_redZonePoints);
          print('Red zone loaded with ${points.length} points');
        }
      }
    } catch (e) {
      print('Error loading red zone: $e');
    }
  }

  // Start real-time tracking for location and connection status
  Future<void> _startRealTimeTracking(String braceletId) async {
    // Track connection status in real-time
    _connectionSubscription = _dbRef
        .child("bracelets/$braceletId/user_info/connected")
        .onValue
        .listen((event) {
      bool newConnectionStatus =
          event.snapshot.exists && event.snapshot.value == true;

      if (_isConnected != newConnectionStatus) {
        _isConnected = newConnectionStatus;
        _connectionController.add(_isConnected);

        print(
            'Connection status changed: ${_isConnected ? 'Connected' : 'Disconnected'}');

        if (!_isConnected) {
          _handleDisconnection();
        } else {
          _updateNotificationService();
        }
      }
    });

    // Track location in real-time - مع حساسية عالية للحركة
    _locationSubscription =
        _dbRef.child("bracelets/$braceletId/location").onValue.listen((event) {
      if (event.snapshot.exists && _isConnected) {
        _handleLocationUpdate(event.snapshot.value as Map, braceletId);
      }
    });
  }

  // Handle location updates - محسن للحساسية العالية
  void _handleLocationUpdate(Map locationData, String braceletId) {
    final lat = double.tryParse(locationData['lat'].toString());
    final lng = double.tryParse(locationData['lng'].toString());

    if (lat != null && lng != null) {
      LatLng newLocation = LatLng(lat, lng);

      // تم تقليل الحد الأدنى للحركة إلى 1 متر لتتبع أكثر دقة
      bool locationChanged = _lastKnownLocation == null ||
          _calculateDistance(
                  _lastKnownLocation!.latitude,
                  _lastKnownLocation!.longitude,
                  newLocation.latitude,
                  newLocation.longitude) >=
              _movementThreshold; // 1 متر

      if (locationChanged) {
        _lastKnownLocation = _currentBraceletLocation;
        _currentBraceletLocation = newLocation;
        _lastLocationUpdateTime = DateTime.now();
        _lastMovementTime = DateTime.now();

        // Reset stationary status when movement is detected
        if (_isStationary) {
          _isStationary = false;
          _stationaryController.add(_isStationary);
          print('Movement detected - no longer stationary');
        }

        // إرسال تحديث الموقع فوراً
        _locationController.add(_currentBraceletLocation);

        // Check zone status with every location update
        _checkZoneStatus(braceletId);

        print(
            'Location updated: ${newLocation.latitude}, ${newLocation.longitude}');
      } else {
        // حتى لو لم تتغير الحركة بما فيه الكفاية، ما زلنا نحدث الموقع الحالي
        _currentBraceletLocation = newLocation;
        _lastLocationUpdateTime = DateTime.now();
        
        // إرسال التحديث حتى لو كانت الحركة أقل من المتر
        _locationController.add(_currentBraceletLocation);
      }
    }
  }

  // Handle disconnection
  void _handleDisconnection() {
    _currentBraceletLocation = null;
    _locationController.add(null);

    // Reset all status when disconnected
    _isOutsideSafeZone = false;
    _isInRedZone = false;
    _isStationary = false;

    if (_currentBraceletId != null) {
      _notificationService.updateLocationStatus(
        braceletId: _currentBraceletId!,
        isInsideSafeZone: true,
        isStationary: false,
        isConnected: false,
        isInRedZone: false,
      );
    }

    print('Bracelet disconnected - all alerts stopped');
  }

  // Start periodic checks
  void _startPeriodicChecks() {
    // Check for stationary bracelet every minute
    _motionCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkIfStationary();
    });
  }

  // Check if bracelet is stationary
  void _checkIfStationary() {
    if (_currentBraceletLocation == null ||
        _lastMovementTime == null ||
        !_isConnected ||
        _currentBraceletId == null) return;

    Duration stationaryDuration = DateTime.now().difference(_lastMovementTime!);

    if (stationaryDuration.inMinutes >= _stationaryThresholdMinutes) {
      if (!_isStationary) {
        _isStationary = true;
        _stationaryController.add(_isStationary);
        _updateNotificationService();

        print(
            'Bracelet is stationary for ${stationaryDuration.inMinutes} minutes');
      }
    }
  }

  // Check zone status
  void _checkZoneStatus(String braceletId) {
    if (_currentBraceletLocation == null) return;

    // Check Safe Zone
    if (_safeZonePoints.length >= 3) {
      bool currentlyInsideSafeZone =
          _isPointInPolygon(_currentBraceletLocation!, _safeZonePoints);
      bool currentlyOutsideSafeZone = !currentlyInsideSafeZone;

      _dbRef
          .child("bracelets/$braceletId/alerts/out_of_safe_zone")
          .set(currentlyOutsideSafeZone);

      if (currentlyOutsideSafeZone != _isOutsideSafeZone) {
        _isOutsideSafeZone = currentlyOutsideSafeZone;
        _safeZoneController.add(_isOutsideSafeZone);

        print(
            'Safe zone status changed: ${currentlyOutsideSafeZone ? 'Outside' : 'Inside'}');
      }
    }

    // Check Red Zone
    if (_redZonePoints.length >= 3) {
      bool currentlyInRedZone =
          _isPointInPolygon(_currentBraceletLocation!, _redZonePoints);

      _dbRef
          .child("bracelets/$braceletId/alerts/in_red_zone")
          .set(currentlyInRedZone);

      if (currentlyInRedZone != _isInRedZone) {
        _isInRedZone = currentlyInRedZone;
        _redZoneController.add(_isInRedZone);

        print(
            'Red zone status changed: ${currentlyInRedZone ? 'Inside Red Zone' : 'Outside Red Zone'}');
      }
    }

    _updateNotificationService();
  }

  void _updateNotificationService() {
    if (_currentBraceletId == null) return;

    _notificationService.updateLocationStatus(
      braceletId: _currentBraceletId!,
      isInsideSafeZone: !_isOutsideSafeZone,
      isStationary: _isStationary,
      isConnected: _isConnected,
      isInRedZone: _isInRedZone,
    );
  }

  // Check if point is inside polygon using ray casting algorithm
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

  // Calculate distance between two points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters

    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLon = (lon2 - lon1) * (math.pi / 180);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Public methods for external control
  Future<void> refreshData(String braceletId) async {
    print('Refreshing data for bracelet: $braceletId');
    await _loadSafeZone(braceletId);
    await _loadRedZone(braceletId);
  }

  void dispose() {
    print('Disposing LiveLocationTrackingService');
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _motionCheckTimer?.cancel();

    _locationController.close();
    _connectionController.close();
    _safeZoneController.close();
    _redZoneController.close();
    _stationaryController.close();
    _safeZonePointsController.close();
    _redZonePointsController.close();

    _notificationService.dispose();
  }

  void stopTracking() {
    print('Stopping location tracking');
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _motionCheckTimer?.cancel();

    _isConnected = false;
    _currentBraceletLocation = null;
    _isOutsideSafeZone = false;
    _isInRedZone = false;
    _isStationary = false;
    _currentBraceletId = null;

    _notificationService.reset();
  }

  // Get current status
  Map<String, dynamic> getDetailedStatus() {
    return {
      'location': {
        'current': _currentBraceletLocation != null
            ? {
                'lat': _currentBraceletLocation!.latitude,
                'lng': _currentBraceletLocation!.longitude,
              }
            : null,
        'lastUpdateTime': _lastLocationUpdateTime?.toIso8601String(),
      },
      'status': {
        'isConnected': _isConnected,
        'isOutsideSafeZone': _isOutsideSafeZone,
        'isInRedZone': _isInRedZone,
        'isStationary': _isStationary,
        'braceletId': _currentBraceletId,
      },
      'zones': {
        'safeZone': {
          'pointsCount': _safeZonePoints.length,
          'points': _safeZonePoints
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        },
        'redZone': {
          'pointsCount': _redZonePoints.length,
          'points': _redZonePoints
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        },
      },
    };
  }
}