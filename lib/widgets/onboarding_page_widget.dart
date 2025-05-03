import 'package:flutter/material.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final Widget actionButton;
  final String indecator;

  const OnboardingPageWidget({super.key, 
    required this.imagePath,
    required this.title,
    required this.description,
    required this.actionButton,
    required this.indecator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 40),
        Image.asset(imagePath, height: 250),
        const SizedBox(height: 150),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                description,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Image.asset(indecator, height: 7),
        const SizedBox(height: 1),
        actionButton,
      ],
    );
  }
}
