import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/onboarding_buttons.dart';
import 'package:tracelet_app/widgets/onboarding_page_widget.dart';

class OnboardingPage1 extends StatelessWidget {
  final PageController controller;

  const OnboardingPage1({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWidget(
      imagePath: "assets/images/on_boarding/onboarding1.png",
      title: "For Your Loved Ones",
      description:
          "Keep your loved ones safe and connected. Tracelet helps you monitor the location of children and elderly family members anytime, anywhere",
      indecator: 'assets/images/on_boarding/indecatour1.png',
      actionButton: OnboardingButtons(
        controller: controller,
        currentIndex: 0,
        totalPages: 3,
      ),
    );
  }
}
