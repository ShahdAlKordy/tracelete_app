import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_onboarding_widget.dart';
import 'onboarding_page_1.dart';
import 'onboarding_page_2.dart';
import 'onboarding_page_3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return BgOnboardingWidget(
      child: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          OnboardingPage1(controller: _controller),
          OnboardingPage2(controller: _controller),
          OnboardingPage3(controller: _controller),
        ],
      ),
    );
  }
}
