import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/onboarding_buttons.dart';
import 'package:tracelet_app/widgets/onboarding_page_widget.dart';


class OnboardingPage3 extends StatelessWidget {
  final PageController controller;

  const OnboardingPage3({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWidget(
      imagePath: "assets/images/on_boarding/onboarding3.png",
      title: "Monitor Your Pet!",
      description:
          "Keep an eye on your pet’s health and whereabouts. With our bracelet, you’ll always know where they are and how they’re feeling.",
       indecator: 'assets/images/on_boarding/indecatour3.png',
      actionButton: OnboardingButtons(
        controller: controller,
        currentIndex: 2,
        totalPages: 3,
      ),
    );
  }
}
