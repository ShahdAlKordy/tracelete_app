import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:tracelet_app/controllers/email_verification_controller.dart';
import 'package:tracelet_app/services/AuthWrapper.dart';
import 'package:tracelet_app/splash_screen/splash_screen.dart';
import 'package:tracelet_app/auth_screens/Log_In_Screen.dart';
import 'package:tracelet_app/services/noti_service/NotificationService.dart'; // Make sure the path to NotificationService.dart is correct

// --- Very Important: This function must be top-level (outside any class) ---
// It will receive FCM messages when the app is in the background or completely closed.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized in this isolate (this happens automatically in the background handler)
  await Firebase.initializeApp();
  print("Background message received in main.dart: ${message.messageId}");

  // Call the function responsible for displaying the local notification from NotificationService.dart
  // The firebaseMessagingBackgroundHandler function we defined in NotificationService.dart will handle displaying the notification
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp();

  // تسجيل الـBackground Message Handler
  // ده بيخلي Firebase يعرف الدالة اللي هيستدعيها لما يجيله إشعار والتطبيق في الخلفية أو مقفول
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تهيئة خدمة الإشعارات الخاصة بك
  // يجب أن يتم ذلك بعد تهيئة Firebase
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmailVerificationLogic()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

      // تعريف الـ routes للتنقل السليم
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginScreen(),
        ),
        GetPage(
          name: '/auth',
          page: () => const AuthWrapper(),
        ),
        GetPage(
          name: '/',
          page: () => const SplashScreen(),
        ),
      ],

      // الصفحة الافتراضية
      initialRoute: '/',

      // إعدادات إضافية للتطبيق
      title: 'Tracelet App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),

      // إعدادات اللغة والاتجاه - إزالة الإعدادات العربية
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // إعدادات الانتقال بين الصفحات
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // إجبار الاتجاه من اليسار لليمين
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
