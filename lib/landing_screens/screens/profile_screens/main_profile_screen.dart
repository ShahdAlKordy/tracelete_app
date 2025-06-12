import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet_app/auth_screens/Log_In_Screen.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/ProfilePictureWidget.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/account_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/zone_screen/ZoneScreen_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/notifications_screen.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';

class MainProfileScreen extends StatefulWidget {
  const MainProfileScreen({super.key});

  @override
  _MainProfileScreenState createState() => _MainProfileScreenState();
}

Widget _buildOptionItem({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.black87),
    title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black87),
    onTap: onTap,
  );
}

class _MainProfileScreenState extends State<MainProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = "Loading...";
  String _userEmail = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          setState(() {
            _userName = userData['name'] ?? "No Name";
            _userEmail = user.email ?? "No Email";
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: BackgroundLanding(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(screenWidth),
                SizedBox(height: screenHeight * 0.01),
                _buildProfileSection(screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.05),
                _buildOptionsCard(screenWidth, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: const Row(
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Container(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.03),
              ProfilePictureWidget(
                size: screenWidth * 0.32,
                onImageChanged: () {
                  setState(() {});
                },
                showEditIcon: true,
                defaultImagePath: 'assets/images/pro.png',
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          _userName,
          style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          _userEmail,
          style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildOptionsCard(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: screenWidth * 0.02,
              offset: Offset(0, screenWidth * 0.01),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionItem(
              icon: Icons.person,
              text: 'Account',
              onTap: () => Get.to(() => const AccountScreen()),
            ),
            _buildOptionItem(
              icon: Icons.safety_check,
              text: 'SafeZone',
              onTap: () => Get.to(() => ZoneManagementScreen()),
            ),
            _buildOptionItem(
              icon: Icons.notifications,
              text: 'Notifications',
              onTap: () => Get.to(() => const NotificationsScreen()),
            ),
            SizedBox(height: screenHeight * 0.05),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                ),
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Enhanced logout method
  void _logout() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Clear SharedPreferences data first
      await _clearLocalData();
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Hide loading indicator
      Get.back();
      
      // Navigate to login screen and clear all routes
      Get.offAll(() => LoginScreen());
      
      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      // Hide loading indicator in case of error
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
      // Show error message
      Get.snackbar(
        'Error',
        'Error during logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Method to clear local data
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userEmail');
      // Clear any other user-related data you might have stored
      // You can add specific keys here instead of clearing everything
      // await prefs.clear(); // Use this only if you want to clear ALL preferences
      print("Local data cleared successfully");
    } catch (e) {
      print("Error clearing local data: $e");
    }
  }
}