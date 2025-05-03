import 'package:flutter/material.dart';

class BgOnboardingWidget extends StatelessWidget {
  final Widget child;

  const BgOnboardingWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/on_boarding/bg_on_boarding.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
      ),
    );
  }
}
