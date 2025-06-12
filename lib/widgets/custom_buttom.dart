import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap; // Make it final

  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
