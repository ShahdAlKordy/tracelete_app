import 'package:flutter/material.dart';

class BackgroundLanding extends StatelessWidget {
  final Widget child;

  const BackgroundLanding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/landing/bg bracelet2.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      ),
    );
  }
}
