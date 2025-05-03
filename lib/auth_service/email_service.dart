import 'package:tracelet_app/auth_service/mail_service.dart';

class EmailService {
  static Future<void> sendOTP(String email) async {
    await MailService.sendOTP(email);
  }
}
