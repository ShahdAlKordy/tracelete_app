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

  // تحميل الصورة المحفوظة محلياً
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

  // حفظ مسار الصورة محلياً
  Future<void> _saveImagePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', path);
    } catch (e) {
      print("Error saving image path: $e");
    }
  }

  // اختيار وحفظ الصورة محلياً
  Future<void> _pickAndSaveImage() async {
    if (_isLoading) {
      _showSnackBar("جاري التحميل، يرجى الانتظار...");
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // طلب إذن الوصول للصور
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        _showSnackBar("تم رفض إذن الوصول للصور");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // اختيار الصورة من المعرض
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

      // حفظ مسار الصورة محلياً
      await _saveImagePath(pickedFile.path);
      
      setState(() {
        _localImagePath = pickedFile.path;
        _isLoading = false;
      });

      // استدعاء callback إذا كان موجود
      if (widget.onImageChanged != null) {
        widget.onImageChanged!();
      }

      _showSnackBar("تم تحديث الصورة الشخصية بنجاح");

    } catch (e) {
      print("Error picking image: $e");
      _showSnackBar("فشل في تحديث الصورة: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // عرض رسالة
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // حذف الصورة والعودة للصورة الافتراضية
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

      _showSnackBar("تم حذف الصورة الشخصية");
    } catch (e) {
      print("Error removing image: $e");
    }
  }

  // عرض خيارات الصورة
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
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSaveImage();
              },
            ),
            if (_localImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف الصورة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('إلغاء'),
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
        // الصورة الشخصية
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
        
        // أيقونة التعديل
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

  // بناء ويدجت الصورة
  Widget _buildProfileImage() {
    if (_localImagePath != null && File(_localImagePath!).existsSync()) {
      // عرض الصورة المحفوظة محلياً
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
      // عرض الصورة الافتراضية
      return _buildDefaultImage();
    }
  }

  // بناء الصورة الافتراضية
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

  // دالة للحصول على مسار الصورة الحالية
  String? get currentImagePath => _localImagePath;
  
  // دالة للتحقق من وجود صورة مخصصة
  bool get hasCustomImage => _localImagePath != null && File(_localImagePath!).existsSync();
}