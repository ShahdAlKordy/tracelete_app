import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/landing_screens/screens/chatPot_screens/trace_caht.dart';

class ChatLogo extends StatelessWidget {
  const ChatLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                'Tracelet Chat',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tracelet Chat is designed to assist users with predefined questions. It provides quick guidance, sends notifications, and delivers alerts as messages for a seamless user experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              const SizedBox(height: 1),
              Image.asset('assets/images/landing/chat.png',
                  width: 146, height: 300),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // Make the button wide
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SupportScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Button background color
                    foregroundColor:
                        AppColors.primaryColor, // Button text color
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0), // Add vertical padding
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(40.0), // Rounded corners
                    ),
                  ),
                  child: const Text(
                    'Continue to Chat',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
