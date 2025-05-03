import 'package:flutter/material.dart';

class OptionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const OptionItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black87),
      onTap: onTap,
    );
  }
}