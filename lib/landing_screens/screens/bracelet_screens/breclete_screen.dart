import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/ProfilePictureWidget.dart';
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
  bool _isLoading = true;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserBracelets();
  }

  Future<void> _loadUserBracelets() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final QuerySnapshot braceletsSnapshot = await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .where("is_active", isEqualTo: true)
          .get();

      final List<BraceletModel> loadedBracelets = braceletsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return BraceletModel(
              id: data['bracelet_id'] ?? doc.id,
              name: data['name'] ?? 'Bracelet ${doc.id}',
            );
          })
          .toList();

      setState(() {
        _bracelets = loadedBracelets;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading bracelets: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

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

    await _saveBraceletToPreferences(bracelet.id);
    
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
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          await _firestore
              .collection("users")
              .doc(currentUser.uid)
              .collection("bracelets")
              .doc(bracelet.id)
              .update({
            "name": newName,
            "updated_at": FieldValue.serverTimestamp(),
          });

          setState(() {
            bracelet.name = newName;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating name')),
          );
        }
      }
    }
  }

  void _removeBracelet(BraceletModel bracelet) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore
            .collection("users")
            .doc(currentUser.uid)
            .collection("bracelets")
            .doc(bracelet.id)
            .update({
          "is_active": false,
          "disconnected_at": FieldValue.serverTimestamp(),
        });

        await _removeBraceletFromPreferences(bracelet.id);

        setState(() {
          _bracelets.remove(bracelet);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bracelet disconnected successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disconnecting bracelet')),
        );
      }
    }
  }

  Future<void> _saveBraceletToPreferences(String braceletId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bracelet_id', braceletId);
  }

  Future<void> _removeBraceletFromPreferences(String braceletId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedBraceletId = prefs.getString('bracelet_id');
    
    if (savedBraceletId == braceletId) {
      await prefs.remove('bracelet_id');
      
      if (_bracelets.isNotEmpty) {
        final remainingBracelets = _bracelets.where((b) => b.id != braceletId).toList();
        if (remainingBracelets.isNotEmpty) {
          await prefs.setString('bracelet_id', remainingBracelets.first.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BackgroundLanding(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading data...'),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      BraceletHeader(),
                      SizedBox(height: constraints.maxHeight * 0.095),
                      // Replace CircleAvatar with ProfilePictureWidget
                      ProfilePictureWidget(
                        size: MediaQuery.of(context).size.width * 0.32,
                        onImageChanged: () {
                          // Refresh UI when image changes
                          setState(() {});
                        },
                        showEditIcon: true,
                        defaultImagePath: 'assets/images/pro.png',
                      ),
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