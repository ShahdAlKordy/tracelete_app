import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

// Import the Red Zone Widget (assuming it's in a separate file)
// import 'red_zone_map_widget.dart';

class RedZoneMapWidget extends StatefulWidget {
  final LatLng initialLocation;
  final double initialZoom;
  final Function(GoogleMapController)? onMapCreated;
  final Function(LatLng)? onTap;
  final Set<Marker>? markers;
  final Set<Polygon>? polygons;

  const RedZoneMapWidget({
    Key? key,
    required this.initialLocation,
    this.initialZoom = 15.0,
    this.onMapCreated,
    this.onTap,
    this.markers,
    this.polygons,
  }) : super(key: key);

  @override
  _RedZoneMapWidgetState createState() => _RedZoneMapWidgetState();
}

class _RedZoneMapWidgetState extends State<RedZoneMapWidget> {
  // Google Maps Style JSON to make water bodies and roads red
  static const String _redZoneMapStyle = '''
[
  {
    "featureType": "water",
    "stylers": [
      {
        "color": "#ff0000"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "road",
    "stylers": [
      {
        "color": "#ff0000"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "stylers": [
      {
        "color": "#cc0000"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "stylers": [
      {
        "color": "#ff0000"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "road.local",
    "stylers": [
      {
        "color": "#ff3333"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ff0000"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#90EE90"
      }
    ]
  },
  {
    "featureType": "landscape",
    "stylers": [
      {
        "color": "#f5f5dc"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#c7c7c7"
      },
      {
        "visibility": "on"
      }
    ]
  }
]
''';

  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialLocation,
        zoom: widget.initialZoom,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        // Apply the red zone style
        _controller!.setMapStyle(_redZoneMapStyle);

        // Call the parent callback if provided
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
      onTap: widget.onTap,
      markers: widget.markers ?? {},
      polygons: widget.polygons ?? {},
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}

class SafeZoneScreen extends StatefulWidget {
  @override
  _SafeZoneScreenState createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  GoogleMapController? mapController;
  String? braceletId;
  bool isLoading = true;

  // For polygon-based safe zone
  List<LatLng> safeZonePoints = [];
  final int maxPoints = 4; // Maximum of 4 points
  Polygon? safeZonePolygon;

  // For bracelet location
  LatLng? braceletLocation;
  LatLng defaultLocation = LatLng(30.033333, 31.233334); // Default: Cairo

  @override
  void initState() {
    super.initState();
    _loadBraceletId();
  }

  Future<void> _loadBraceletId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('bracelet_id');
    setState(() {
      braceletId = id;
    });

    if (id != null) {
      await _loadBraceletLocation(id);
      await _loadExistingSafeZone(id);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadBraceletLocation(String id) async {
    try {
      final locationSnapshot =
          await dbRef.child("bracelets/$id/location").get();

      if (locationSnapshot.exists) {
        final data = locationSnapshot.value as Map;
        final lat = double.tryParse(data['lat'].toString());
        final lng = double.tryParse(data['lng'].toString());

        if (lat != null && lng != null) {
          setState(() {
            braceletLocation = LatLng(lat, lng);
          });
        }
      }
    } catch (e) {
      print('Error loading bracelet location: $e');
    }
  }

  Future<void> _loadExistingSafeZone(String id) async {
    try {
      final safeZoneSnapshot =
          await dbRef.child("bracelets/$id/safe_zone_polygon").get();

      if (safeZoneSnapshot.exists) {
        final data = safeZoneSnapshot.value as Map;
        List<LatLng> points = [];

        // Load up to 4 points
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

        if (points.isNotEmpty) {
          setState(() {
            safeZonePoints = points;
            _updatePolygon();
          });
        }
      }
    } catch (e) {
      print('Error loading safe zone: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading safe zone: $e")),
      );
    }
  }

  LatLng _getCenterOfPoints(List<LatLng> points) {
    double sumLat = 0;
    double sumLng = 0;

    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  void _onMapTap(LatLng position) {
    if (safeZonePoints.length < maxPoints) {
      setState(() {
        safeZonePoints.add(position);
        _updatePolygon();
      });
    } else {
      // If we already have max points, replace the closest point
      int closestPointIndex = _findClosestPointIndex(position);
      setState(() {
        safeZonePoints[closestPointIndex] = position;
        _updatePolygon();
      });
    }
  }

  int _findClosestPointIndex(LatLng tap) {
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < safeZonePoints.length; i++) {
      double distance = _calculateDistance(tap, safeZonePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    // Simple Euclidean distance calculation (not actual geodesic distance)
    var dx = p1.latitude - p2.latitude;
    var dy = p1.longitude - p2.longitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _updatePolygon() {
    if (safeZonePoints.length < 3) {
      // Need at least 3 points for a polygon
      safeZonePolygon = null;
      return;
    }

    safeZonePolygon = Polygon(
      polygonId: PolygonId('safeZone'),
      points: List.from(safeZonePoints), // Create a copy of the list
      fillColor: Colors.green.withOpacity(0.2),
      strokeColor: Colors.green,
      strokeWidth: 2,
    );
  }

  Future<void> _saveSafeZone() async {
    if (braceletId == null || safeZonePoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please set at least 3 points to create a safe zone")),
      );
      return;
    }

    try {
      Map<String, dynamic> safeZoneData = {};

      // Save each point
      for (int i = 0; i < safeZonePoints.length; i++) {
        safeZoneData['point$i'] = {
          'lat': safeZonePoints[i].latitude,
          'lng': safeZonePoints[i].longitude,
        };
      }

      await dbRef
          .child("bracelets/$braceletId/safe_zone_polygon")
          .set(safeZoneData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Safe Zone Saved ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving safe zone: $e")),
      );
    }
  }

  Future<void> _deleteSafeZone() async {
    if (braceletId == null || safeZonePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No safe zone to delete")),
      );
      return;
    }

    try {
      await dbRef.child("bracelets/$braceletId/safe_zone_polygon").remove();
      // Also remove old safe zone format if it exists
      await dbRef.child("bracelets/$braceletId/safe_zone").remove();

      setState(() {
        safeZonePoints.clear();
        safeZonePolygon = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Safe Zone Deleted ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting safe zone: $e")),
      );
    }
  }

  Future<void> _resetPoints() async {
    setState(() {
      safeZonePoints.clear();
      safeZonePolygon = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Points cleared. Tap to add new points.")),
    );
  }

  void _moveToCurrentLocation() {
    if (mapController != null && braceletLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: braceletLocation!,
            zoom: 16,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Set Safe Zone"),
        backgroundColor: Color(0xff243561),
        actions: [
          if (braceletLocation != null)
            IconButton(
              icon: Icon(Icons.my_location),
              onPressed: _moveToCurrentLocation,
              tooltip: "Go to bracelet location",
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Tap to set up to 4 points to create a safe zone area",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Points set: ${safeZonePoints.length} of $maxPoints",
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "🔴 Red areas show dangerous zones (roads & water)",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (braceletLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "🔵 Blue marker shows bracelet location",
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: RedZoneMapWidget(
                    initialLocation: braceletLocation ?? defaultLocation,
                    initialZoom: braceletLocation != null ? 16 : 15,
                    onMapCreated: (controller) {
                      setState(() {
                        mapController = controller;
                      });
                    },
                    onTap: _onMapTap,
                    markers: {
                      // Bracelet location marker
                      if (braceletLocation != null)
                        Marker(
                          markerId: MarkerId("bracelet_location"),
                          position: braceletLocation!,
                          infoWindow: InfoWindow(
                              title: "Bracelet Location",
                              snippet: "Current location of the bracelet"),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue),
                        ),
                      // Safe zone points markers
                      ...safeZonePoints.asMap().entries.map((entry) {
                        int idx = entry.key;
                        LatLng point = entry.value;
                        return Marker(
                          markerId: MarkerId("point_$idx"),
                          position: point,
                          infoWindow:
                              InfoWindow(title: "Safe Zone Point ${idx + 1}"),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen),
                        );
                      }).toSet(),
                    },
                    polygons: safeZonePolygon != null ? {safeZonePolygon!} : {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveSafeZone,
                              child: Text("Save Safe Zone"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff243561),
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 45),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: safeZonePoints.isNotEmpty
                                  ? _deleteSafeZone
                                  : null,
                              child: Text("Delete Safe Zone"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 45),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            safeZonePoints.isNotEmpty ? _resetPoints : null,
                        child: Text("Reset Points"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
