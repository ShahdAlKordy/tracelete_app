import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/log_in_screen.dart';
import 'package:tracelet_app/constans/constans.dart';

class OnboardingButtons extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final int totalPages;

  const OnboardingButtons({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: currentIndex == totalPages - 1
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) =>  LoginScreen()),
                  );
                },
                child: const Text(
                  "Start!",
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    controller.jumpToPage(totalPages - 1);
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  },
                  child: const Text(
                    "Next",
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
    );
  }
}
