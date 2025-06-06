import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';

class AddBraceletDialog extends StatefulWidget {
  @override
  _AddBraceletDialogState createState() => _AddBraceletDialogState();
}

class _AddBraceletDialogState extends State<AddBraceletDialog> {
  final TextEditingController braceletIdController = TextEditingController();
  final TextEditingController ownerNumberController = TextEditingController();
  bool isLoading = false;
  bool isRequestSent = false;

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    braceletIdController.dispose();
    ownerNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSendRequest() async {
    final braceletId = braceletIdController.text.trim();
    final ownerNumber = ownerNumberController.text.trim();

    if (braceletId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the serial number')),
      );
      return;
    }

    // Check login status
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must log in first')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // التحقق من وجود السوار في قاعدة البيانات
      final snapshot = await dbRef.child("bracelets/$braceletId").get();

      if (!snapshot.exists) {
        setState(() {
          isLoading = false;
          isRequestSent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('السيريال غير مسجل')),
        );
        return;
      }

      // التحقق من أن البريسليت غير مربوط بمستخدم آخر
      final braceletData = snapshot.value as Map<dynamic, dynamic>?;
      if (braceletData != null &&
          braceletData['user_info'] != null &&
          braceletData['user_info']['connected'] == true &&
          braceletData['user_info']['user_id'] != currentUser.uid) {
        setState(() {
          isLoading = false;
          isRequestSent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هذا البريسليت مربوط بمستخدم آخر')),
        );
        return;
      }

      // تسجيل البيانات على Firebase Realtime Database
      await dbRef.child("bracelets/$braceletId/user_info").set({
        "connected": true,
        "owner_number": ownerNumber,
        "user_id": currentUser.uid, // ربط البريسليت بالمستخدم
        "connected_at": ServerValue.timestamp,
      });

      // حفظ البريسليت في Firestore مع بيانات المستخدم
      await _firestore
          .collection("users")
          .doc(currentUser.uid)
          .collection("bracelets")
          .doc(braceletId)
          .set({
        "bracelet_id": braceletId,
        "name": 'Bracelet $braceletId',
        "owner_number": ownerNumber,
        "connected_at": FieldValue.serverTimestamp(),
        "is_active": true,
      });

      final bracelet = BraceletModel(
        id: braceletId,
        name: 'Bracelet $braceletId',
      );

      if (!mounted) return;

      Navigator.of(context).pop(bracelet);
    } catch (e) {
      setState(() {
        isLoading = false;
        isRequestSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connect New Bracelet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              if (isLoading)
                Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting...'),
                  ],
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: braceletIdController,
                      decoration: InputDecoration(
                        labelText: 'Bracelet ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: ownerNumberController,
                      decoration: InputDecoration(
                        labelText: 'Owner number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLoading)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                  SizedBox(width: 8),
                  if (!isLoading)
                    ElevatedButton(
                      onPressed: isRequestSent ? null : _handleSendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff243561),
                      ),
                      child: Text(
                        isRequestSent ? 'Sent' : 'Send Request',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
