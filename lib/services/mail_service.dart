import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MailService {
  static const String senderEmail = "shahdmkordy6@gmail.com"; 
  static const String appPassword = "hsybzjdpbbljwjuj"; 

  static String generateOTP() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString(); 
  }

  static Future<void> sendOTP(String recipientEmail) async {
    final smtpServer = gmail(senderEmail, appPassword); 
    String otpCode = generateOTP(); 

    final message = Message()
      ..from = Address(senderEmail, 'Tracelet App')
      ..recipients.add(recipientEmail) 
      ..subject = 'Your OTP Code'
      ..text =
          'Your OTP code is: $otpCode\nUse this code to verify your email.';

    try {
      await send(message, smtpServer);

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(recipientEmail)
          .set({'otp': otpCode, 'timestamp': DateTime.now()});

      print('OTP sent successfully to $recipientEmail');
    } catch (e) {
      print('Failed to send OTP: $e');
      throw Exception('Failed to send OTP');
    }
  }
}
