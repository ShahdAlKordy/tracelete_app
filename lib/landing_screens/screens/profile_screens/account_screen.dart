import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/ProfilePictureWidget.dart';
import 'package:tracelet_app/widgets/EditFieldDialog.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String username = 'Loading...';
  String name = 'Loading...';
  String email = 'Loading...';
  String phone = 'Loading...';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
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
            username = userData['username'] ?? "No Username";
            name = userData['name'] ?? "No Name";
            email = user.email ?? "No Email";
            phone = userData['phone'] ?? "No Phone";
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _editField(String field, String currentValue, Function(String) onSave) {
    showDialog(
      context: context,
      builder: (context) => EditFieldDialog(
        field: field,
        currentValue: currentValue,
        onSave: (newValue) async {
          onSave(newValue);
          await _updateUserData(field, newValue);
        },
      ),
    );
  }

  Future<void> _updateUserData(String field, String newValue) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          field.toLowerCase(): newValue,
        });
      }
    } catch (e) {
      print("Error updating user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BackgroundLanding(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.11),

              // Replace CircleAvatar with ProfilePictureWidget
              Center(
                child: Container(
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.003),
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
              ),

              SizedBox(height: screenHeight * 0.01),
              Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Expanded(
                child: Padding(
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildField(
                            label: 'Name',
                            value: name,
                            isEditable: true,
                            onTap: () => _editField('Name', name, (newValue) {
                              setState(() => name = newValue);
                            }),
                          ),
                          Divider(color: Colors.grey[300]),
                          _buildField(label: 'Email', value: email),
                          Divider(color: Colors.grey[300]),
                          _buildField(
                            label: 'Phone',
                            value: phone,
                            isEditable: true,
                            onTap: () => _editField('Phone', phone, (newValue) {
                              setState(() => phone = newValue);
                            }),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Center(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.015,
                                  horizontal: screenWidth * 0.25,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.03),
                                ),
                              ),
                              onPressed: () {
                                Get.snackbar(
                                  "Success",
                                  "Profile updated successfully!",
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    bool isEditable = false,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
            fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black54),
      ),
      trailing: isEditable
          ? Icon(Icons.edit, size: screenWidth * 0.05, color: Colors.black87)
          : null,
      onTap: isEditable ? onTap : null,
    );
  }
}
