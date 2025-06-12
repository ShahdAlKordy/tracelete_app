import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildImageWidget extends StatefulWidget {
  final String braceletId;
  final double size;

  const ChildImageWidget({
    Key? key,
    required this.braceletId,
    this.size = 50.0,
  }) : super(key: key);

  @override
  _ChildImageWidgetState createState() => _ChildImageWidgetState();
}

class _ChildImageWidgetState extends State<ChildImageWidget> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  // Load saved image
  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('child_image_${widget.braceletId}');
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        _imagePath = savedPath;
      });
    }
  }

  // Save image path
  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_image_${widget.braceletId}', path);
  }

  // Choose image from gallery or camera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Image'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Get image
  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
        await _saveImagePath(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete image
  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('child_image_${widget.braceletId}');
    setState(() {
      _imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          border: Border.all(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: _imagePath != null
            ? Stack(
                children: [
                  // Image
                  ClipOval(
                    child: Image.file(
                      File(_imagePath!),
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // In case of image loading error, show default circle
                        return _buildDefaultCircle();
                      },
                    ),
                  ),
                  // أيقونة التعديل
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              )
            : _buildDefaultCircle(),
      ),
    );
  }

  // بناء الدائرة الافتراضية
  Widget _buildDefaultCircle() {
    return Icon(
      Icons.edit,
      size: widget.size * 0.4,
      color: Colors.grey[600],
    );
  }
}
