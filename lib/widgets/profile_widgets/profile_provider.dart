import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/Log_In_Screen.dart';
import 'package:get/get.dart';
import 'package:tracelet_app/widgets/profile_widgets/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserProfile _userProfile = UserProfile.loading();
  bool _isLoading = false;

  UserProfile get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  // Constructor - Fetch user data on initialization
  ProfileProvider() {
    fetchUserData();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Update profile image URL (temporarily)
  void updateTempProfileImageUrl(String url) {
    _userProfile = UserProfile(
      name: _userProfile.name,
      email: _userProfile.email,
      profileImageUrl: url,
    );
    notifyListeners();
  }

  // Update profile with new data
  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Fetch user data from Firestore
  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          
          UserProfile profile = UserProfile.fromFirestore(
            userData, 
            user.email ?? 'No Email'
          );
          
          updateUserProfile(profile);
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      _userProfile = UserProfile(
        name: "Error loading data",
        email: "Please try again",
        profileImageUrl: "",
      );
      notifyListeners();
    }
  }

  // Logout function
  Future<void> logout() async {
    await _auth.signOut();
    Get.offAll(() => LoginScreen());
  }

  // Update profile image URL after successful upload
  void updateProfileImageUrl(String url) {
    _userProfile = UserProfile(
      name: _userProfile.name,
      email: _userProfile.email,
      profileImageUrl: url,
    );
    notifyListeners();
  }
}