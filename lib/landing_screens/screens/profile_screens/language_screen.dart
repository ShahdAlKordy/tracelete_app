import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: BackgroundLanding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    children: [
                      // 🟢 زر الرجوع إلى الشاشة السابقة
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context), 
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Language',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.115),

            // 🟢 صورة البروفايل هنا
            Center(
              child: CircleAvatar(
                radius: screenWidth * 0.16,
                backgroundImage: const AssetImage('assets/images/pro.png'),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLanguageOption('العربية', screenWidth),
                      _buildLanguageOption('English', screenWidth),
                      _buildLanguageOption('Deutsch', screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
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
                          onPressed: () {},
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
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3, // ✅ تحديد العنصر النشط ليكون على "Profile"
        onItemTapped: (index) {
          // هنا يجب أن تتعامل مع التنقل بشكل صحيح عبر `NavigationController`
        },
      ),
    );
  }

  Widget _buildLanguageOption(String language, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language,
            style:
                TextStyle(fontSize: screenWidth * 0.045, color: Colors.black),
          ),
          Container(
            width: double.infinity,
            height: 2,
            color: Colors.black12,
          ),
        ],
      ),
    );
  }
}
