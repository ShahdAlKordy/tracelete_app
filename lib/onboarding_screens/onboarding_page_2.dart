import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/onboarding_buttons.dart';
import 'package:tracelet_app/widgets/onboarding_page_widget.dart';

class OnboardingPage2 extends StatelessWidget {
  final PageController controller;

  const OnboardingPage2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWidget(
      imagePath: "assets/images/on_boarding/onboarding2.png",
      title: "Locate the Lost",
      description:
          "Never lose track of those who matter. With Tracelet, you can easily find their location when it matters most",
      indecator: 'assets/images/on_boarding/indecatour2.png',
      actionButton: OnboardingButtons(
        controller: controller,
        currentIndex: 1,
        totalPages: 3,
      ),
    );
  }
}
