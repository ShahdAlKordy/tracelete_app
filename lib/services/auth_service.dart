import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/auth_error_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Default profile image asset path
  final String _defaultProfileImage = "assets/images/pro.png";

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
    String? profileImagePath, // Optional parameter for profile image path
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter name, email, and password")),
      );
      return;
    }

    try {
      // Create account in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if account creation was successful
      if (userCredential.user == null) {
        throw FirebaseAuthException(
            code: 'user-creation-failed',
            message: 'Failed to create user account');
      }

      // Variable to store image URL
      String profileImageUrl = '';

      // If image path is provided, upload to Firebase Storage
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        try {
          // Create a unique filename with timestamp - FIXED: simplify path
          String uniqueFileName =
              'profile_images_${userCredential.user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          // Create reference to the specific path
          final storageRef = _storage.ref().child(uniqueFileName);

          print("⏳ Uploading to storage path: ${storageRef.fullPath}");

          // Upload file with metadata
          final uploadTask = await storageRef.putFile(
            File(profileImagePath),
            SettableMetadata(contentType: 'image/jpeg'),
          );

          // Get download URL
          profileImageUrl = await storageRef.getDownloadURL();
          print("✅ Image uploaded, URL: $profileImageUrl");
        } catch (e) {
          print("Error uploading profile image: $e");
          // In case of upload failure, leave the URL empty
          profileImageUrl = '';
        }
      }

      // Create user document in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "name": name,
        "email": email,
        "uid": userCredential.user!.uid,
        "profileImage": profileImageUrl, // Use the obtained URL
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Account created successfully: ${userCredential.user!.email}")),
      );

      // Navigate to home page
      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseAuthException catch (e) {
      String errorMessage = AuthErrorHandler.getErrorMessage(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return null;
    }

    try {
      // Sign in to Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time in Firestore (optional)
      if (userCredential.user != null) {
        await _firestore
            .collection("users")
            .doc(userCredential.user!.uid)
            .update({
          "lastLogin": FieldValue.serverTimestamp(),
        }).catchError((error) {
          // Ignore errors updating last login as they are non-critical
          print("Warning: Could not update last login timestamp: $error");
        });
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = AuthErrorHandler.getErrorMessage(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return null;
    } catch (e) {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user profile is complete
  Future<bool> isUserProfileComplete() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      return userDoc.exists && userDoc.data() != null;
    } catch (e) {
      print("Error checking user profile: $e");
      return false;
    }
  }

  // Method to update profile image
  Future<String?> updateProfileImage(String imagePath) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      // Create a unique filename with timestamp - FIXED: simplify path
      String uniqueFileName =
          'profile_images_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create reference to the specific path
      final storageRef = _storage.ref().child(uniqueFileName);

      print("⏳ Uploading to storage path: ${storageRef.fullPath}");

      // Upload file with metadata
      final uploadTask = storageRef.putFile(
        File(imagePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print("⏳ Upload progress: ${(progress * 100).toStringAsFixed(1)}%");
      }, onError: (error) {
        print("❌ Error monitoring upload: $error");
      });

      // Wait for upload task to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      print("✅ Download URL obtained: $downloadUrl");

      // Update image URL in Firestore
      await _firestore.collection("users").doc(currentUser.uid).update({
        "profileImage": downloadUrl,
      });
      print("✅ Firestore updated with new image URL");

      return downloadUrl;
    } catch (e) {
      print("Error updating profile image: $e");
      return null;
    }
  }
}
