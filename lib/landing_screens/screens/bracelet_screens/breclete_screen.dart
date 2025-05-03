import 'package:flutter/material.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_landing_widget.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/AddBraceletDialog.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletHeader.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletsContent.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/EditBraceletDialog.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/ProfileSection.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/SuccessDialog.dart';

class BraceletsScreen extends StatefulWidget {
  @override
  _BraceletsScreenState createState() => _BraceletsScreenState();
}

class _BraceletsScreenState extends State<BraceletsScreen> {
  List<BraceletModel> _bracelets = [];

  void _showAddBraceletDialog() async {
    final BraceletModel? result = await showDialog<BraceletModel>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AddBraceletDialog(),
    );

    if (result != null) {
      _showSuccessDialog(result);
    }
  }

  void _showSuccessDialog(BraceletModel bracelet) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => SuccessDialog(),
    );

    setState(() {
      _bracelets.add(bracelet);
    });
  }

  void _editBraceletName(BraceletModel bracelet) async {
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          EditBraceletDialog(currentName: bracelet.name),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        bracelet.name = newName;
      });
    }
  }

  void _removeBracelet(BraceletModel bracelet) {
    setState(() {
      _bracelets.remove(bracelet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BackgroundLanding(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      BraceletHeader(),
                      SizedBox(height: constraints.maxHeight * 0.095),
                      ProfileSection(),
                      SizedBox(height: constraints.maxHeight * 0.05),
                      BraceletsContent(
                        bracelets: _bracelets,
                        onAddBracelet: _showAddBraceletDialog,
                        onEditBracelet: _editBraceletName,
                        onRemoveBracelet: _removeBracelet,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
