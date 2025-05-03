import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/widgets/profile_widgets/image_service.dart';
import 'package:tracelet_app/widgets/profile_widgets/option_item_widget.dart';


class ProfileUIComponents {
  static Widget buildHeader(double screenWidth) {
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

  static Widget buildProfileSection({
    required double screenWidth,
    required double screenHeight,
    required String userName,
    required String userEmail,
    required String profileImageUrl,
    required bool isLoading,
    required Function onPickImage,
  }) {
    final ImageService imageService = ImageService();
    
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ClipOval(
                      child: imageService.getProfileImageWidget(
                        profileImageUrl, 
                        screenWidth * 0.32
                      ),
                    ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: GestureDetector(
                onTap: isLoading ? null : () => onPickImage(),
                child: CircleAvatar(
                  radius: screenWidth * 0.05,
                  backgroundColor: Colors.white,
                  child: isLoading
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
          userName,
          style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          userEmail,
          style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black),
        ),
      ],
    );
  }

  static Widget buildOptionsCard({
    required double screenWidth,
    required double screenHeight,
    required Function navigateToAccount,
    required Function navigateToLanguage,
    required Function navigateToNotifications,
    required Function onLogout,
  }) {
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
            OptionItem(
              icon: Icons.person,
              text: 'Account',
              onTap: () => navigateToAccount(),
            ),
            OptionItem(
              icon: Icons.language,
              text: 'Language',
              onTap: () => navigateToLanguage(),
            ),
            OptionItem(
              icon: Icons.notifications,
              text: 'Notifications',
              onTap: () => navigateToNotifications(),
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
                onPressed: () => onLogout(),
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
}