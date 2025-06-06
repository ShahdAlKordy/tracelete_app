import 'package:flutter/material.dart';
import 'package:tracelet_app/landing_screens/screens/bracelet_screens/breclete_screen.dart';
import 'package:tracelet_app/landing_screens/screens/chatPot_screens/chat_logo.dart';
import 'package:tracelet_app/landing_screens/screens/home_screens/map_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/main_profile_screen.dart';
import 'package:tracelet_app/landing_screens/navigation_bar/navigationBar.dart';

class NavigationController extends StatefulWidget {
  final int initialIndex;
  const NavigationController({super.key, this.initialIndex = 0});

  @override
  _NavigationControllerState createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  late int currentIndex;

  final List<Widget> screens = [
    GoogleMapScreen(), 
    ChatLogo(),
    BraceletsScreen(),
    MainProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void navigateTo(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // منع زر الرجوع في الجهاز
      onWillPop: () async => false,
      child: Scaffold(
        // لا تحتاج إلى AppBar هنا إذا كانت كل شاشة تحتوي على AppBar خاص بها
        body: screens[currentIndex],
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: currentIndex,
          onItemTapped: navigateTo,
        ),
      ),
    );
  }
}
