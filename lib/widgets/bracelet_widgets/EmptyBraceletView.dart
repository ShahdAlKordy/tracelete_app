import 'package:flutter/material.dart';

class EmptyBraceletView extends StatelessWidget {
  final VoidCallback onAddBracelet;

  const EmptyBraceletView({Key? key, required this.onAddBracelet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final iconSize = maxWidth * 0.5;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.not_interested, 
              size: iconSize.clamp(80, 210).toDouble(), 
              color: Colors.grey
            ),
            SizedBox(height: 16),
            Text(
              'No Bracelet Connected',
              style: TextStyle(
                fontSize: 18, 
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: onAddBracelet,
              child: Text(
                '+ Add New Bracelet',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff243561),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      }
    );
  }
}