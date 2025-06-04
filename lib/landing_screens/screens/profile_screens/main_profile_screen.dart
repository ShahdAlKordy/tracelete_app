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
import 'package:tracelet_app/landing_screens/screens/profile_screens/account_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/SafeZoneScreen_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/notifications_screen.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';

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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _profileImageUrl = "";
  bool _isLoading = false;

  // Default profile image asset path
  final String _defaultProfileImage = "assets/images/pro.png";

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
            _profileImageUrl = userData['profileImage'] ?? "";
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _profileImageUrl = ""; // Use default image in case of error
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload in progress, please wait...")),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Request photo permissions
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Permission to access photos was denied")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Reduce quality for faster upload
      );

      if (pickedFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is logged in")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Convert XFile to File
      final File imageFile = File(pickedFile.path);

      // Temporarily update UI with local image path
      setState(() {
        _profileImageUrl = pickedFile.path;
      });

      // Create a unique filename for storage
      final String uniqueFileName =
          'profile_images_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(uniqueFileName);

      print("⏳ Uploading to storage path: ${storageRef.fullPath}");

      // Start upload with metadata
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print("⏳ Upload progress: ${(progress * 100).toStringAsFixed(1)}%");
      }, onError: (error) {
        print("❌ Error monitoring upload: $error");
      });

      // Wait for upload to complete
      try {
        await uploadTask;
        print("✅ Upload completed successfully");
      } catch (e) {
        print("❌ Upload task failed: $e");
        throw e; // Re-throw to be caught by outer catch block
      }

      // Get download URL
      final String downloadUrl = await storageRef.getDownloadURL();
      print("✅ Download URL obtained: $downloadUrl");

      // Update user info in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
      });
      print("✅ Firestore updated with new image URL");

      // Update UI with new image URL
      setState(() {
        _profileImageUrl = downloadUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully")),
      );
    } catch (e) {
      print("❌ Error updating profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update image: ${e.toString()}")),
      );
      setState(() {
        _isLoading = false;
        // Reload data from Firestore on failure
        _fetchUserData();
      });
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
      // Add Bottom Navigation Bar
      
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
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Profile image with loading indicator
            Container(
              width: screenWidth * 0.32,
              height: screenWidth * 0.32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ClipOval(
                      child: _getProfileImageWidget(screenWidth),
                    ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: GestureDetector(
                onTap: _isLoading ? null : _pickAndUploadImage,
                child: CircleAvatar(
                  radius: screenWidth * 0.05,
                  backgroundColor: Colors.white,
                  child: _isLoading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
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

  // Improved method for profile image widget
  Widget _getProfileImageWidget(double screenWidth) {
    if (_profileImageUrl.isEmpty) {
      // Use default local image
      return Image.asset(
        _defaultProfileImage,
        width: screenWidth * 0.32,
        height: screenWidth * 0.32,
        fit: BoxFit.cover,
      );
    } else if (_profileImageUrl.startsWith('http')) {
      // Use network image with error handling
      return Image.network(
        _profileImageUrl,
        width: screenWidth * 0.32,
        height: screenWidth * 0.32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load network image: $error");
          return Image.asset(
            _defaultProfileImage,
            width: screenWidth * 0.32,
            height: screenWidth * 0.32,
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
        File(_profileImageUrl),
        width: screenWidth * 0.32,
        height: screenWidth * 0.32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Failed to load local image: $error");
          return Image.asset(
            _defaultProfileImage,
            width: screenWidth * 0.32,
            height: screenWidth * 0.32,
            fit: BoxFit.cover,
          );
        },
      );
    }
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
              onTap: () => Get.to(() =>  SafeZoneScreen()),
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

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:tracelet_app/controllers/navigation_controller.dart';
// import 'package:tracelet_app/landing_screens/screens/profile_screens/account_screen.dart';
// import 'package:tracelet_app/landing_screens/screens/profile_screens/language_screen.dart';
// import 'package:tracelet_app/landing_screens/screens/profile_screens/notifications_screen.dart';
// import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';
// import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';

// import '../services/image_service.dart';
// import '../providers/profile_provider.dart';
// import '../widgets/profile_ui_components.dart';

// class MainProfileScreen extends StatefulWidget {
//   const MainProfileScreen({super.key});

//   @override
//   _MainProfileScreenState createState() => _MainProfileScreenState();
// }

// class _MainProfileScreenState extends State<MainProfileScreen> {
//   final ImageService _imageService = ImageService();
//   late ProfileProvider _profileProvider;
  
//   int currentIndex = 3; // Set to 3 to highlight the Profile tab

//   @override
//   void initState() {
//     super.initState();
//     _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
//     _profileProvider.fetchUserData();
//   }

//   void _navigateTo(int index) {
//     // Use Get.to or Navigator to navigate to appropriate screen
//     if (index != 3) {
//       // 3 is the current Profile index
//       // Navigate to NavigationController with the selected index
//       Get.offAll(() => NavigationController(initialIndex: index));
//     }
//   }

//   Future<void> _pickAndUploadImage() async {
//     if (_profileProvider.isLoading) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Upload in progress, please wait...")),
//       );
//       return;
//     }

//     try {
//       _profileProvider.setLoading(true);

//       // Get the selected image file path first (temporary for preview)
//       final tempImagePath = await _imageService.pickAndUploadProfileImage(context);
      
//       if (tempImagePath != null) {
//         // Update user profile with the new image URL
//         _profileProvider.updateProfileImageUrl(tempImagePath);
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profile picture updated successfully")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to update image: ${e.toString()}")),
//       );
//     } finally {
//       _profileProvider.setLoading(false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       body: BackgroundLanding(
//         child: SafeArea(
//           child: Consumer<ProfileProvider>(
//             builder: (context, provider, child) {
//               final userProfile = provider.userProfile;
//               final isLoading = provider.isLoading;
              
//               return SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     ProfileUIComponents.buildHeader(screenWidth),
//                     SizedBox(height: screenHeight * 0.01),
//                     ProfileUIComponents.buildProfileSection(
//                       screenWidth: screenWidth,
//                       screenHeight: screenHeight,
//                       userName: userProfile.name,
//                       userEmail: userProfile.email,
//                       profileImageUrl: userProfile.profileImageUrl,
//                       isLoading: isLoading,
//                       onPickImage: _pickAndUploadImage,
//                     ),
//                     SizedBox(height: screenHeight * 0.05),
//                     ProfileUIComponents.buildOptionsCard(
//                       screenWidth: screenWidth,
//                       screenHeight: screenHeight,
//                       navigateToAccount: () => Get.to(() => const AccountScreen()),
//                       navigateToLanguage: () => Get.to(() => const LanguageScreen()),
//                       navigateToNotifications: () => Get.to(() => const NotificationsScreen()),
//                       onLogout: () => _profileProvider.logout(),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       // Add Bottom Navigation Bar
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: currentIndex,
//         onItemTapped: _navigateTo,
//       ),
//     );
//   }
// }