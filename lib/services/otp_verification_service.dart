import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

Future<String?> verifyOTP(String email, String enteredOTP) async {
  enteredOTP = enteredOTP.trim();

  if (enteredOTP.length != 6) {
    return "Please enter a valid 6-digit code.";
  }

  try {
    await Future.delayed(Duration(seconds: 1));

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('password_resets')
        .doc(email)
        .get();

    if (!snapshot.exists) {
      return "No OTP found. Please request a new code.";
    }

    var data = snapshot.data();
    if (data == null || data is! Map<String, dynamic>) {
      return "Invalid response from server. Please try again.";
    }

    String? correctOTP = data['otp']?.toString().trim();

    if (correctOTP == null || correctOTP.isEmpty) {
      return "OTP not found in database.";
    }

    if (enteredOTP == correctOTP) {
      return null; // Success, return null
    } else {
      return "Incorrect OTP. Please try again.";
    }
  } catch (e) {
    return "An error occurred: ${e.toString()}";
  }
}
