import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:math' as math;

class GoogleMapScreen extends StatefulWidget {
  @override
  _BraceletLocationScreenState createState() => _BraceletLocationScreenState();
}

class _BraceletLocationScreenState extends State<GoogleMapScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  LatLng? braceletLocation;
  bool isConnected = false;
  bool isLoading = true;
  GoogleMapController? mapController;
  String? braceletId;

  // Safe Zone as Polygon
  List<LatLng> safeZonePoints = [];
  Polygon? safeZonePolygon;
  bool isOutsideSafeZone = false;

  // Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadStoredBraceletId();
    _initFCM();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();
    print("FCM Token: $fcmToken");

    if (braceletId != null && fcmToken != null) {
      await dbRef.child("bracelets/$braceletId/user_info/fcm_token").set(fcmToken);
    }
  }

  Future<void> _loadStoredBraceletId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBraceletId = prefs.getString('bracelet_id');
    if (savedBraceletId != null) {
      setState(() {
        braceletId = savedBraceletId;
      });
      _checkConnectionAndLoadLocation();
      _loadSafeZone();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadSafeZone() async {
    if (braceletId == null) return;

    try {
      final safeZoneSnapshot = await dbRef
          .child("bracelets/$braceletId/safe_zone_polygon")
          .get();

      if (safeZoneSnapshot.exists) {
        final data = safeZoneSnapshot.value as Map;
        List<LatLng> points = [];
        
        // Load up to 4 points
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
            safeZonePoints = points;
            _updatePolygon();
          });
        }
      }
    } catch (e) {
      print('Error loading safe zone: $e');
    }
  }

  void _updatePolygon() {
    if (safeZonePoints.length < 3) {
      safeZonePolygon = null;
      return;
    }
    
    safeZonePolygon = Polygon(
      polygonId: PolygonId('safeZone'),
      points: List.from(safeZonePoints),
      fillColor: Colors.green.withOpacity(0.2),
      strokeColor: Colors.green,
      strokeWidth: 2,
    );
  }

  Future<void> _checkConnectionAndLoadLocation() async {
    if (braceletId == null) return;

    try {
      final connectedSnapshot = await dbRef
          .child("bracelets/$braceletId/user_info/connected")
          .get();

      if (connectedSnapshot.exists && connectedSnapshot.value == true) {
        setState(() {
          isConnected = true;
        });

        final locationSnapshot = await dbRef
            .child("bracelets/$braceletId/location")
            .get();

        if (locationSnapshot.exists) {
          final data = locationSnapshot.value as Map;
          final lat = double.tryParse(data['lat'].toString());
          final lng = double.tryParse(data['lng'].toString());

          if (lat != null && lng != null) {
            setState(() {
              braceletLocation = LatLng(lat, lng);

              // Check if the bracelet is inside the safe zone
              if (safeZonePoints.length >= 3 && braceletLocation != null) {
                isOutsideSafeZone = !_isPointInPolygon(braceletLocation!, safeZonePoints);
                
                dbRef
                    .child("bracelets/$braceletId/alerts/out_of_zone")
                    .set(isOutsideSafeZone);

                if (isOutsideSafeZone) {
                  _showOutOfZoneNotification();
                }
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  // Check if a point is inside a polygon using the ray casting algorithm
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    // Ray casting algorithm
    bool isInside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude < point.longitude && polygon[j].longitude >= point.longitude ||
          polygon[j].longitude < point.longitude && polygon[i].longitude >= point.longitude) &&
          (polygon[i].latitude + (point.longitude - polygon[i].longitude) / 
          (polygon[j].longitude - polygon[i].longitude) * 
          (polygon[j].latitude - polygon[i].latitude) < point.latitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    
    return isInside;
  }

  Future<void> _showOutOfZoneNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'safe_zone_channel',
      'Safe Zone Alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '⚠️ Alert',
      'Bracelet has exited the safe zone!',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bracelet Location"),
        backgroundColor: Color(0xff243561),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : !isConnected
              ? Center(
                  child: Text(
                    'No bracelet connected currently ⚠️',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Stack(
                  children: [
                    braceletLocation != null
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: braceletLocation!,
                              zoom: 16,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId('bracelet'),
                                position: braceletLocation!,
                                infoWindow: InfoWindow(title: "Bracelet Location"),
                              ),
                              ...safeZonePoints.asMap().entries.map((entry) {
                                int idx = entry.key;
                                LatLng point = entry.value;
                                return Marker(
                                  markerId: MarkerId("safe_point_$idx"),
                                  position: point,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueGreen),
                                  infoWindow: InfoWindow(title: "Safe Zone Point ${idx+1}"),
                                );
                              }).toList(),
                            },
                            polygons: safeZonePolygon != null
                                ? {safeZonePolygon!}
                                : {},
                            onMapCreated: (controller) {
                              mapController = controller;
                            },
                          )
                        : Center(
                            child: Text(
                              'Bracelet location not available yet',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                    if (isOutsideSafeZone && braceletLocation != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "⚠️ Alert: Bracelet is outside the safe zone!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}