import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildLocationMarker {
  static const double _markerSize = 150.0; // زيادة الحجم من 120 إلى 150

  /// Create custom marker for bracelet location
  static Future<BitmapDescriptor> createChildMarker({
    required String braceletId,
    required bool isInRedZone,
    required bool isOutsideSafeZone,
  }) async {
    // Load saved image
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('child_image_$braceletId');

    if (savedPath != null && File(savedPath).existsSync()) {
      // Create marker with child image
      return await _createCustomMarkerWithImage(
        imagePath: savedPath,
        isInRedZone: isInRedZone,
        isOutsideSafeZone: isOutsideSafeZone,
      );
    } else {
      // Return default marker
      return _getDefaultMarker(isInRedZone, isOutsideSafeZone);
    }
  }

  /// Create custom marker with image
  static Future<BitmapDescriptor> _createCustomMarkerWithImage({
    required String imagePath,
    required bool isInRedZone,
    required bool isOutsideSafeZone,
  }) async {
    try {
      // Determine border color based on status
      Color borderColor = Colors.green;
      if (isInRedZone) {
        borderColor = Colors.red;
      } else if (isOutsideSafeZone) {
        borderColor = Colors.orange;
      }

      // Load and decode the image
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image first to check orientation
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      // Create Canvas to draw the image
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      const double radius = _markerSize / 2;
      const Offset center = Offset(radius, radius);

      // Draw circular background
      final Paint backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 4, backgroundPaint);

      // Save canvas state and apply clipping
      canvas.save();
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius - 8));
      canvas.clipPath(clipPath);

      // التحقق من اتجاه الصورة وتطبيق التدوير والعكس المناسب
      canvas.save();
      canvas.translate(center.dx, center.dy);

      // عكس الصورة من اليمين إلى الشمال (horizontal flip)
      canvas.scale(-1.0, 1.0);

      // تجربة تدوير مختلف حسب نسبة العرض والارتفاع
      if (originalImage.width > originalImage.height) {
        // الصورة عريضة - تدوير 90 درجة عكس عقارب الساعة
        canvas.rotate(-3.14159 / 2);
      } else if (originalImage.height > originalImage.width * 1.5) {
        // الصورة طويلة جداً - قد تحتاج تدوير 180 درجة
        canvas.rotate(3.14159);
      }

      canvas.translate(-center.dx, -center.dy);

      // رسم الصورة
      final double imageSize = (radius - 8) * 2;
      final Rect imageRect = Rect.fromCenter(
        center: center,
        width: imageSize,
        height: imageSize,
      );

      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
            originalImage.height.toDouble()),
        imageRect,
        Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true,
      );

      // استعادة حالة الكانفاس
      canvas.restore();
      canvas.restore();

      // رسم البوردر
      final Paint borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..isAntiAlias = true;
      canvas.drawCircle(center, radius - 4, borderPaint);

      // إضافة النقطة السفلية
      final Paint pointPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(
        Offset(radius, _markerSize - 10),
        5,
        pointPaint,
      );

      // تحويل إلى صورة
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(
        _markerSize.round(),
        (_markerSize + 10).round(),
      );

      // تحويل إلى bytes
      final ByteData? byteData = await markerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating custom marker: $e');
    }

    // في حالة الخطأ، إرجاع المارker الافتراضي
    return _getDefaultMarker(isInRedZone, isOutsideSafeZone);
  }

  /// Alternative method with better rotation handling and horizontal flip
  static Future<BitmapDescriptor> _createCustomMarkerWithImageV2({
    required String imagePath,
    required bool isInRedZone,
    required bool isOutsideSafeZone,
  }) async {
    try {
      // Determine border color based on status
      Color borderColor = Colors.green;
      if (isInRedZone) {
        borderColor = Colors.red;
      } else if (isOutsideSafeZone) {
        borderColor = Colors.orange;
      }

      // Read image file
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      // Create Canvas
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      const double radius = _markerSize / 2;
      const Offset center = Offset(radius, radius);

      // Background
      final Paint backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 4, backgroundPaint);

      // Clip to circle
      canvas.save();
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius - 8));
      canvas.clipPath(clipPath);

      // Calculate image dimensions for proper scaling
      double imageSize = radius * 2 - 16;
      Rect destRect = Rect.fromCenter(
        center: center,
        width: imageSize,
        height: imageSize,
      );

      // Draw image with proper orientation and horizontal flip
      canvas.save();
      canvas.translate(center.dx, center.dy);

      // عكس الصورة من اليمين إلى الشمال (horizontal flip)
      canvas.scale(-1.0, 1.0);

      // Apply rotation based on image orientation
      if (originalImage.width > originalImage.height) {
        canvas.rotate(3.14159 / 2); // 90 degrees clockwise
      }

      canvas.translate(-center.dx, -center.dy);

      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
            originalImage.height.toDouble()),
        destRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      canvas.restore();
      canvas.restore();

      // Border
      final Paint borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0;
      canvas.drawCircle(center, radius - 4, borderPaint);

      // Location point
      final Paint pointPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(radius, _markerSize - 10), 5, pointPaint);

      // Convert to bitmap
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(
        _markerSize.round(),
        (_markerSize + 10).round(),
      );

      final ByteData? byteData = await markerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating custom marker V2: $e');
    }

    return _getDefaultMarker(isInRedZone, isOutsideSafeZone);
  }

  /// Get default location marker (normal Google Maps marker)
  static BitmapDescriptor _getDefaultMarker(
      bool isInRedZone, bool isOutsideSafeZone) {
    if (isInRedZone) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (isOutsideSafeZone) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  /// Create marker for display on map
  static Future<Marker> createBraceletMarker({
    required String braceletId,
    required LatLng position,
    required bool isInRedZone,
    required bool isOutsideSafeZone,
  }) async {
    final BitmapDescriptor icon = await createChildMarker(
      braceletId: braceletId,
      isInRedZone: isInRedZone,
      isOutsideSafeZone: isOutsideSafeZone,
    );

    return Marker(
      markerId: MarkerId('bracelet_$braceletId'),
      position: position,
      icon: icon,
      anchor: const Offset(0.5, 0.9), // تعديل موقع المارker على الخريطة
      infoWindow: InfoWindow(
        title: "Child Location",
        snippet: isInRedZone
            ? "🚨 In Red Zone!"
            : isOutsideSafeZone
                ? "⚠️ Outside Safe Zone"
                : "✅ Safe",
      ),
    );
  }
}
