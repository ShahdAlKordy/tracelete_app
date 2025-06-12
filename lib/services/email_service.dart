import 'package:tracelet_app/services/mail_service.dart';

class EmailService {
  static Future<void> sendOTP(String email) async {
    await MailService.sendOTP(email);
  }
}
