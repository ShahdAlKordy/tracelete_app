import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FloatingBraceletBar extends StatefulWidget {
  final List<BraceletModel> connectedBracelets;
  final Map<String, LatLng> braceletLocations;
  final Function(String braceletId) onBraceletTap;

  const FloatingBraceletBar({
    Key? key,
    required this.connectedBracelets,
    required this.braceletLocations,
    required this.onBraceletTap,
  }) : super(key: key);

  @override
  _FloatingBraceletBarState createState() => _FloatingBraceletBarState();
}

class _FloatingBraceletBarState extends State<FloatingBraceletBar> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  Map<String, String> braceletLocalImages = {}; 
  Map<String, String> braceletNetworkImages = {}; 

  @override
  void initState() {
    super.initState();
    _loadBraceletImages();
  }

  @override
  void didUpdateWidget(FloatingBraceletBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectedBracelets != widget.connectedBracelets) {
      _loadBraceletImages();
    }
  }

  Future<void> _loadBraceletImages() async {
    final prefs = await SharedPreferences.getInstance();

    for (BraceletModel bracelet in widget.connectedBracelets) {
      try {
        final savedPath = prefs.getString('child_image_${bracelet.id}');

        if (savedPath != null && File(savedPath).existsSync()) {
          setState(() {
            braceletLocalImages[bracelet.id] = savedPath;
            braceletNetworkImages
                .remove(bracelet.id);
          });
        } else {
          final imageSnapshot =
              await dbRef.child("bracelets/${bracelet.id}/image_url").get();

          if (imageSnapshot.exists && imageSnapshot.value != null) {
            final imageUrl = imageSnapshot.value.toString();
            if (imageUrl.isNotEmpty) {
              setState(() {
                braceletNetworkImages[bracelet.id] = imageUrl;
                braceletLocalImages
                    .remove(bracelet.id); 
              });
            }
          }
        }
      } catch (e) {
        print("Error loading image for bracelet ${bracelet.id}: $e");
      }
    }
  }

  Widget _buildBraceletImage(String braceletId, bool hasLocation) {
    if (braceletLocalImages.containsKey(braceletId)) {
      final localImagePath = braceletLocalImages[braceletId]!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(localImagePath),
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (context, error, stackTrace) {
            return _buildLocationIcon(hasLocation);
          },
        ),
      );
    }

    if (braceletNetworkImages.containsKey(braceletId)) {
      final networkImageUrl = braceletNetworkImages[braceletId]!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          networkImageUrl,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (context, error, stackTrace) {
            return _buildLocationIcon(hasLocation);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildLocationIcon(hasLocation);
  }

  Widget _buildLocationIcon(bool hasLocation) {
    return Icon(
      hasLocation ? Icons.location_on : Icons.location_off,
      size: 20,
      color: hasLocation ? Colors.green : Colors.grey[600],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.connectedBracelets.isEmpty) {
      return SizedBox.shrink();
    }

    return Positioned(
      bottom: 6, 
      left: 4,
      right: 60,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xff243561),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: widget.connectedBracelets.length,
          itemBuilder: (context, index) {
            final bracelet = widget.connectedBracelets[index];
            final hasLocation =
                widget.braceletLocations.containsKey(bracelet.id);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: hasLocation
                    ? () => widget.onBraceletTap(bracelet.id)
                    : null,
                child: Container(
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasLocation ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: _buildBraceletImage(bracelet.id, hasLocation),
                      ),
                      SizedBox(height: 4),
                      // اسم البريسليت
                      Text(
                        bracelet.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
