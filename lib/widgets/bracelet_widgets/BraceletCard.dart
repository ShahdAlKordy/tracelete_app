import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/ChildImageWidget.dart';

class BraceletCard extends StatelessWidget {
  final BraceletModel bracelet;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const BraceletCard({
    Key? key,
    required this.bracelet,
    required this.onEdit,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final imageSize = maxWidth * 0.15;

        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bracelet.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 1),
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(
                            Icons.edit,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.battery_full,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onRemove,
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // استخدام الـ widget الجديد لصورة الطفل
                  ChildImageWidget(
                    braceletId: bracelet.id ?? bracelet.name, // استخدم ID الـ bracelet أو الاسم كمعرف فريد
                    size: imageSize.clamp(40, 60),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}