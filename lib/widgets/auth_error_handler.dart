class AuthErrorHandler {
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return "This email is already in use. Please try another one.";
      case 'weak-password':
        return "Your password is too weak. Try using a stronger password.";
      case 'invalid-email':
        return "Invalid email format. Please enter a valid email.";
      case 'operation-not-allowed':
        return "Signing up with this method is not allowed.";
      case 'network-request-failed':
        return "Network error. Please check your internet connection.";
      default:
        return "An unexpected error occurred. Please try again.";
    }
  }

  static String getSuccessMessage() {
    return "Account created successfully! You can now log in.";
  }
}
