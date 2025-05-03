import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.32,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/images/breclete_logo.png'),
          ),
        ),
      ),
    );
  }
}