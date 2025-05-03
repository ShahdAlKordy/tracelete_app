import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'dart:async';

// ملاحظة: لا تستورد NavigationBar أو NavigationController هنا

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({Key? key}) : super(key: key);

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  // Initial map controller
  GoogleMapController? mapController;

  // Default center position for the map (will be updated from database)
  LatLng _centerPosition = const LatLng(30.0444, 31.2357); // Cairo as default

  // Set of markers to be displayed on the map
  final Set<Marker> _markers = {};

  // Reference to the database - use "location" as path
  final DatabaseReference _locationRef =
      FirebaseDatabase.instance.ref('location');

  // StreamSubscription for database updates
  late StreamSubscription<DatabaseEvent> _locationSubscription;

  // Tracks if we're currently loading data
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start listening to database updates
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _locationSubscription.cancel();
    mapController?.dispose();
    super.dispose();
  }

  void _subscribeToLocationUpdates() {
    _locationSubscription = _locationRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      setState(() {
        _isLoading = false;
        _markers.clear();

        if (data != null) {
          // Handle data directly as the "location" node
          if (data is Map) {
            try {
              // Extract lat and lng values
              double lat = double.parse(data['lat'].toString());
              double lng = double.parse(data['lng'].toString());

              // Create a new position
              LatLng position = LatLng(lat, lng);
              _centerPosition = position;

              // Add marker for this location
              _markers.add(
                Marker(
                  markerId: const MarkerId('device_location'),
                  position: position,
                  infoWindow: const InfoWindow(
                    title: 'Current Location',
                    snippet: 'Device is here',
                  ),
                ),
              );

              // Update camera position
              _updateCameraPosition();

              print('Location data found: Lat: $lat, Lng: $lng');
            } catch (e) {
              print('Error parsing location data: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error parsing location: $e')),
              );
            }
          } else {
            print('Unexpected data format: $data');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid location data format')),
            );
          }
        } else {
          print('No data found at location node');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No location data found')),
          );
        }
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      print('Database error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: ${error.toString()}')),
      );
    });
  }

  void _updateCameraPosition() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _centerPosition,
            zoom: 14.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // تمنع استخدام زر الرجوع في الجهاز
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Location Tracker',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          // منع زر الرجوع في الـ AppBar
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _centerPosition,
                zoom: 14.0,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                // Update camera position when map is created if we already have data
                if (_markers.isNotEmpty) {
                  _updateCameraPosition();
                }
              },
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "btn1",
              onPressed: () {
                if (_markers.isNotEmpty) {
                  _updateCameraPosition();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No location available')),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: "btn2",
              onPressed: () {
                // Refresh data from database
                setState(() {
                  _isLoading = true;
                });
                _locationRef.get().then((snapshot) {
                  if (snapshot.exists) {
                    // Data will be processed through the stream listener
                    print('Database snapshot exists: ${snapshot.value}');
                  } else {
                    setState(() {
                      _isLoading = false;
                    });
                    print('No location data found in database');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No location data found')),
                    );
                  }
                }).catchError((error) {
                  setState(() {
                    _isLoading = false;
                  });
                  print('Error fetching location: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${error.toString()}')),
                  );
                });
              },
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
        // لا تضيف شريط التنقل هنا أبداً - سيتم إضافته فقط من NavigationController
      ),
    );
  }
}