import 'package:flutter/material.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletList.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/EmptyBraceletView.dart';

class BraceletsContent extends StatelessWidget {
  final List<BraceletModel> bracelets;
  final VoidCallback onAddBracelet;
  final Function(BraceletModel) onEditBracelet;
  final Function(BraceletModel) onRemoveBracelet;

  const BraceletsContent({
    Key? key,
    required this.bracelets,
    required this.onAddBracelet,
    required this.onEditBracelet,
    required this.onRemoveBracelet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: double.infinity,
          color: const Color.fromRGBO(255, 255, 255, 255),
          padding: EdgeInsets.all(16),
          child: bracelets.isEmpty
              ? EmptyBraceletView(onAddBracelet: onAddBracelet)
              : BraceletList(
                  bracelets: bracelets,
                  onAddBracelet: onAddBracelet,
                  onEditBracelet: onEditBracelet,
                  onRemoveBracelet: onRemoveBracelet,
                ),
        ),
      ),
    );
  }
}
