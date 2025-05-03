import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/log_in_screen.dart';
import 'package:tracelet_app/auth_service/auth_service.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_auth_widget.dart';
import 'package:tracelet_app/widgets/custom_buttom.dart';
import 'package:tracelet_app/widgets/custom_text_filed.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? name, email, password;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.08),
                  Image.asset(
                    'assets/images/auth/logo auth.png',
                    height: screenHeight * 0.1,
                  ),
                  SizedBox(height: screenHeight * 0.08),
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    onChanged: (data) => setState(() => name = data),
                    label: "Name",
                    hintText: "Enter your name",
                    icon: Icons.person,
                  ),
                  CustomTextField(
                    onChanged: (data) => setState(() => email = data),
                    label: "Email",
                    hintText: "Enter your email",
                    icon: Icons.email,
                  ),
                  CustomTextField(
                    onChanged: (data) => setState(() => password = data),
                    label: "Password",
                    hintText: "Enter your password",
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomButton(
                    onTap: () {
                      if (email != null && password != null && name != null) {
                        AuthService().signUp(
                          email: email!,
                          password: password!,
                          name: name!,
                          context: context,
                        );
                      }
                    },
                    text: "Sign Up",
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
