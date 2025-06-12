import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/Reset_Password.dart';
import 'package:tracelet_app/services/otp_verification_service.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_auth_widget.dart';
import 'package:tracelet_app/widgets/custom_buttom.dart';
import 'package:tracelet_app/widgets/otp_input.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  EmailVerificationScreen({required this.email});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  String enteredOTP = "";
  bool isLoading = false;
  String? errorMessage;

  void handleOTPVerification() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? result = await verifyOTP(widget.email, enteredOTP);

    if (result == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      setState(() {
        errorMessage = result;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AuthBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.06),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.025),
              child: Center(
                child: Text(
                  'Email Verification',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: screenWidth * 0.07),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.09),
                    Image.asset('assets/images/auth/Email Verification.png',
                        height: screenHeight * 0.2),
                    SizedBox(height: screenHeight * 0.05),
                    Text('Code sent to ${widget.email}'),
                    SizedBox(height: screenHeight * 0.05),
                    OTPInput(
                      length: 6,
                      onChanged: (value) {
                        setState(() {
                          enteredOTP = value.trim();
                        });
                      },
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    CustomButton(
                      text: isLoading ? "Verifying..." : "Verify Code",
                      onTap: isLoading ? null : handleOTPVerification,
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
