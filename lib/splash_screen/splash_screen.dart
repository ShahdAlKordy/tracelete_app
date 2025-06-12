import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/Log_In_Screen.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:tracelet_app/onboarding_screens/onboarding_screen.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  void _checkAppState() async {
    // انتظار 3 ثواني لإظهار الـ splash screen
    await Future.delayed(const Duration(seconds: 3));
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (isLoggedIn) {
      // إذا كان المستخدم مسجل دخول، اذهب للصفحة الرئيسية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavigationController(initialIndex: 0)),
      );
    } else if (hasSeenOnboarding) {
      // إذا شاف الـ onboarding من قبل لكن مش مسجل دخول، اذهب لصفحة تسجيل الدخول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      // إذا أول مرة يفتح التطبيق، اذهب للـ onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/splash_screen/logo.png',
                width: 146, height: 156),
          ],
        ),
      ),
    );
  }
}