import 'dart:math';

class OTPService {
  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
