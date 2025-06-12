import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tracelet_app/auth_screens/Log_In_Screen.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If connection is waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Checking authentication...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Return your main navigation controller
          return NavigationController(initialIndex: 0);
        }
        
        // If user is not logged in
        return LoginScreen();
      },
    );
  }
}