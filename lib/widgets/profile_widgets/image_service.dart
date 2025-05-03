import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Default profile image asset path
  static const String defaultProfileImage = "assets/images/pro.png";

  // Pick and upload profile image
  Future<String?> pickAndUploadProfileImage(BuildContext context) async {
    try {
      // Request photo permissions
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission to access photos was denied")),
        );
        return null;
      }

      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Reduce quality for faster upload
      );

      if (pickedFile == null) {
        return null;
      }

      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is logged in")),
        );
        return null;
      }

      // Convert XFile to File
      final File imageFile = File(pickedFile.path);

      // Create a unique filename for storage
      final String uniqueFileName =
          'profile_images_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(uniqueFileName);

      // Start upload with metadata
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final String downloadUrl = await storageRef.getDownloadURL();

      // Update user info in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print("Error updating profile picture: $e");
      return null;
    }
  }

  // Widget to display profile image
  Widget getProfileImageWidget(String profileImageUrl, double size) {
    if (profileImageUrl.isEmpty) {
      // Use default local image
      return Image.asset(
        defaultProfileImage,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (profileImageUrl.startsWith('http')) {
      // Use network image with error handling
      return Image.network(
        profileImageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load network image: $error");
          return Image.asset(
            defaultProfileImage,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      // Use local file image with error handling
      return Image.file(
        File(profileImageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load local image: $error");
          return Image.asset(
            defaultProfileImage,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }
}