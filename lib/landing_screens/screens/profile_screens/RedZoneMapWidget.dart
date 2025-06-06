import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  // Method to update map style if needed
  void updateMapStyle(String? style) {
    if (_controller != null) {
      _controller!.setMapStyle(style);
    }
  }

  // Method to reset to default style
  void resetToDefaultStyle() {
    if (_controller != null) {
      _controller!.setMapStyle(null);
    }
  }

  // Method to apply red zone style
  void applyRedZoneStyle() {
    if (_controller != null) {
      _controller!.setMapStyle(_redZoneMapStyle);
    }
  }
}