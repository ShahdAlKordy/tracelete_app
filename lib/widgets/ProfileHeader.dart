import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Text(
            "Account",
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Center(
          child: CircleAvatar(
            radius: screenWidth * 0.16,
            backgroundImage: const AssetImage("assets/images/pro.png"),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: screenWidth * 0.25),
            Text(
              "User Name",
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(width: screenWidth * 0.38),
          ],
        ),
      ],
    );
  }
}
