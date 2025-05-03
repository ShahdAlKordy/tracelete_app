import 'package:flutter/material.dart';
import 'package:tracelet_app/auth_screens/Forget_Password.dart';
import 'package:tracelet_app/auth_screens/Sign_In_Screen.dart';
import 'package:tracelet_app/auth_service/auth_service.dart';
import 'package:tracelet_app/constans/constans.dart';
import 'package:tracelet_app/controllers/navigation_controller.dart';
import 'package:tracelet_app/landing_screens/screens/home_screens/map_screen.dart';
import 'package:tracelet_app/landing_screens/screens/profile_screens/main_profile_screen.dart';
import 'package:tracelet_app/widgets/bg_widgets/bg_auth_widget.dart';
import 'package:tracelet_app/widgets/custom_buttom.dart';
import 'package:tracelet_app/widgets/custom_text_filed.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      var user = await _authService.signIn(
          email: email, password: password, context: context);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationController(initialIndex: 0)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed. Check credentials!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter email and password")),
      );
    }
  }

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
                  SizedBox(height: screenHeight * 0.15),
                  const Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    controller: _emailController,
                    label: "Email",
                    hintText: "Enter your email",
                    icon: Icons.email,
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    label: "Password",
                    hintText: "Enter your password",
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgetPasswordScreen()),
                        );
                      },
                      child: const Text("Forget password?",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomButton(
                    text: "Login",
                    onTap: _login,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupScreen()),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
