import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tracelet_app/auth_screens/Log_In_Screen.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/ProfilePictureWidget.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/account_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/SafeZoneScreen_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/notifications_screen.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';
// استيراد الويدجت الجديد

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
        // استخدام الويدجت الجديد للصورة الشخصية
        ProfilePictureWidget(
          size: screenWidth * 0.32,
          showEditIcon: true,
          defaultImagePath: "assets/images/pro.png",
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
              onTap: () => Get.to(() => SafeZoneScreen()),
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
                onPressed: _logout,
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

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => LoginScreen());
  }
}
