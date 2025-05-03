import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tracelet_app/auth_screens/log_in_screen.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_auth_widget.dart';
import 'package:tracelet_app/widgets/custom_buttom.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  ResetPasswordScreen({required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void _sendResetEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: widget.email);

      _showMessage("Password reset email sent! Check your inbox.",
          success: true);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AuthBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.06),
            Text(
              'Reset Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: screenWidth * 0.07,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.08),
                    Image.asset('assets/images/auth/Reset Password.png',
                        height: screenHeight * 0.2),
                    SizedBox(height: screenHeight * 0.04),
                    Text(
                      'Reset Your Password',
                      style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'We will send you an email with a link to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    _isLoading
                        ? CircularProgressIndicator()
                        : CustomButton(
                            text: "Send Reset Email",
                            onTap: _sendResetEmail, 
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
