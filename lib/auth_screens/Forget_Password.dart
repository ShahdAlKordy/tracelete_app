import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/Email_Verification.dart';
import 'package:tracelet_app/auth_service/mail_service.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_auth_widget.dart';
import 'package:tracelet_app/widgets/custom_buttom.dart';
import 'package:tracelet_app/widgets/custom_text_filed.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AuthBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05),
              Text(
                'Recover Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: screenWidth * 0.07,
                ),
              ),
              SizedBox(height: screenHeight * 0.15),
              Image.asset(
                'assets/images/auth/Forget password.png',
                height: screenHeight * 0.2,
              ),
              SizedBox(height: screenHeight * 0.05),
              Text(
                'Mail Address Here',
                style: TextStyle(
                    fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Enter the email address associated with your account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.03),

              CustomTextField(
                label: "Email",
                hintText: "Enter your email",
                icon: Icons.email,
                controller: emailController,
              ),

              SizedBox(height: screenHeight * 0.03),
              CustomButton(
                text: "Send OTP",
                onTap: () async {
                  String email = emailController.text.trim();
                  try {
                    await MailService.sendOTP(email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('OTP sent successfully to $email')),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailVerificationScreen(email: email),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send OTP')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
