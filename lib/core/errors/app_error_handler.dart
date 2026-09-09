/// User-friendly error message translator.
/// Catches raw network, Firebase, and AI exceptions and maps them to clean, understandable text.
class AppErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final str = error.toString().toLowerCase();

    if (str.contains('permission-denied')) {
      return 'Unable to save your data. Please check your account permissions and try again.';
    }
    if (str.contains('network-request-failed') ||
        str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('failed host lookup')) {
      return 'Network connection issue. Changes will be saved locally and synchronized once reconnected.';
    }
    if (str.contains('incorrect password') ||
        str.contains('user-not-found') ||
        str.contains('wrong-password') ||
        str.contains('invalid-credential') ||
        str.contains('invalid credential')) {
      return 'Invalid email or password. Please verify your credentials.';
    }
    if (str.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    }
    if (str.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (str.contains('insufficient') || str.contains('not enough information')) {
      return 'The selected study materials do not contain enough information to complete this request.';
    }
    if (str.contains('unable to extract article text') ||
        str.contains('invalid url') ||
        str.contains('manual text entry')) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    if (str.contains('url')) {
      return 'Unable to access this URL directly. Please copy-paste the content using the Manual Text Entry section.';
    }
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '').trim();
      if (msg.isNotEmpty) return msg;
    }

    return 'Something went wrong. Please check your connection and try again.';
  }
}

