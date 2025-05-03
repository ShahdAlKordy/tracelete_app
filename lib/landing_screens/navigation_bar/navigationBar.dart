import 'package:flutter/material.dart';
import 'package:tracelet_app/constans/constans.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemTapped, 
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[400],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.watch),
          label: 'Bracelet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}