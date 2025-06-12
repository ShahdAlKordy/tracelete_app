import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePictureWidget extends StatefulWidget {
  final double size;
  final VoidCallback? onImageChanged;
  final bool showEditIcon;
  final String defaultImagePath;

  const ProfilePictureWidget({
    Key? key,
    this.size = 120,
    this.onImageChanged,
    this.showEditIcon = true,
    this.defaultImagePath = "assets/images/pro.png",
  }) : super(key: key);

  @override
  _ProfilePictureWidgetState createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _localImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  // Load saved image locally
  Future<void> _loadSavedImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('profile_image_path');

      if (savedPath != null && File(savedPath).existsSync()) {
        setState(() {
          _localImagePath = savedPath;
        });
      }
    } catch (e) {
      print("Error loading saved image: $e");
    }
  }

  // Save image path locally
  Future<void> _saveImagePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', path);
    } catch (e) {
      print("Error saving image path: $e");
    }
  }

  // Choose and save image locally
  Future<void> _pickAndSaveImage() async {
    if (_isLoading) {
      _showSnackBar("Loading, please wait...");
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Request permission to access photos
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        _showSnackBar("Photo access permission denied");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Choose image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Save image path locally
      await _saveImagePath(pickedFile.path);

      setState(() {
        _localImagePath = pickedFile.path;
        _isLoading = false;
      });

      // Call callback if exists
      if (widget.onImageChanged != null) {
        widget.onImageChanged!();
      }

      _showSnackBar("Profile picture updated successfully");
    } catch (e) {
      print("Error picking image: $e");
      _showSnackBar("Failed to update image: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Remove image and return to default image
  Future<void> _removeImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');

      setState(() {
        _localImagePath = null;
      });

      if (widget.onImageChanged != null) {
        widget.onImageChanged!();
      }

      _showSnackBar("Profile picture removed");
    } catch (e) {
      print("Error removing image: $e");
    }
  }

  // Show image options
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSaveImage();
              },
            ),
            if (_localImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove image',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Profile picture
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ClipOval(child: _buildProfileImage()),
        ),

        // Edit icon
        if (widget.showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isLoading ? null : _showImageOptions,
              child: Container(
                width: widget.size * 0.25,
                height: widget.size * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.black54,
                        size: 16,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  // Build profile image widget
  Widget _buildProfileImage() {
    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      // Show saved image locally
      return Image.file(
        File(_localImagePath!),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading local image: $error");
          return _buildDefaultImage();
        },
      );
    } else {
      // Show default image
      return _buildDefaultImage();
    }
  }

  // Build default image
  Widget _buildDefaultImage() {
    return Image.asset(
      widget.defaultImagePath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Icon(
            Icons.person,
            size: widget.size * 0.5,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  // Get current image path
  String? get currentImagePath => _localImagePath;

  // Check if custom image exists
  bool get hasCustomImage =>
      _localImagePath != null && File(_localImagePath!).existsSync();
}
