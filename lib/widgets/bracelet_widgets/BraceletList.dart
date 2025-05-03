import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletCard.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';

class BraceletList extends StatelessWidget {
  final List<BraceletModel> bracelets;
  final VoidCallback onAddBracelet;
  final Function(BraceletModel) onEditBracelet;
  final Function(BraceletModel) onRemoveBracelet;

  const BraceletList({
    Key? key,
    required this.bracelets,
    required this.onAddBracelet,
    required this.onEditBracelet,
    required this.onRemoveBracelet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: bracelets.length,
          itemBuilder: (context, index) {
            return BraceletCard(
              bracelet: bracelets[index],
              onEdit: () => onEditBracelet(bracelets[index]),
              onRemove: () => onRemoveBracelet(bracelets[index]),
            );
          },
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
}