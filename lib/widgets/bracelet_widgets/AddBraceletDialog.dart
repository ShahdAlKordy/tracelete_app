import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tracelet_app/widgets/bracelet_widgets/BraceletModel.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ استيراد shared_preferences

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
        SnackBar(content: Text('من فضلك ادخل السيريال')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // ✅ التحقق من وجود السوار في قاعدة البيانات
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

    // ✅ تسجيل البيانات على Firebase
    await dbRef.child("bracelets/$braceletId/user_info").set({
      "connected": true,
      "owner_number": ownerNumber,
    });

    // ✅ تخزين السيريال محلياً
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bracelet_id', braceletId); // 💾 التخزين المحلي

    final bracelet = BraceletModel(
      id: braceletId,
      name: 'Bracelet $braceletId',
    );

    if (!mounted) return;

    Navigator.of(context).pop(bracelet); // ✅ الرجوع بالبيانات
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
                    Text('جاري الاتصال...'),
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
                        isRequestSent ? 'تم الإرسال' : 'Send Request',
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
