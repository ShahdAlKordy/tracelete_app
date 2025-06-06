import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller; // ✅ Add Controller
  final Function(String)? onChanged;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;

  const CustomTextField({
    super.key,
    this.controller, // ✅ Pass Controller
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller, // ✅ Use Controller here
            onChanged: onChanged,
            obscureText: obscureText,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              hintText: hintText,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
