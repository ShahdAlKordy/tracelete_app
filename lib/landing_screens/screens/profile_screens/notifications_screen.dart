import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                        onPressed: () => Navigator.pop(
                            context), // ⬅️ يرجع إلى الشاشة السابقة
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Notifications',
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
            SizedBox(height: screenHeight * 0.000001),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: ListView(
                    children: [
                      _buildSection(
                        title: 'Location Alerts',
                        children: [
                          _buildSwitchOption('Geofencing'),
                          _buildSwitchOption('Emergency Alerts'),
                          _buildSwitchOption('Connectivity Alerts'),
                        ],
                      ),
                      _buildSection(
                        title: 'Device Alerts',
                        children: [
                          _buildSwitchOption('Battery Alerts'),
                          _buildSwitchOption('Network Alerts'),
                        ],
                      ),
                      _buildSection(
                        title: 'App Updates',
                        children: [
                          _buildSwitchOption('App Update Notifications'),
                          _buildSwitchOption('Beta Updates'),
                        ],
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

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildSwitchOption(String label) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      value: true,
      onChanged: (bool value) {},
      activeTrackColor: AppColors.primaryColor,
      activeColor: Colors.white,
    );
  }
}
