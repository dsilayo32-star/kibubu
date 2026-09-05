import 'package:firebase_auth/firebase_auth.dart';

/// Huduma ya SMS OTP ya Firebase Phone Authentication.
class OtpService {
  static String? _verificationId;
  static int? _resendToken;

  static Future<void> sendOtp(
    String phone, {
    required void Function() onCodeSent,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        throw OtpException(error.message ?? 'SMS OTP imeshindikana.');
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  static Future<bool> verifyOtp(String inputOtp) async {
    final verificationId = _verificationId;
    if (verificationId == null || inputOtp.trim().length != 6) return false;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: inputOtp.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _verificationId = null;
      _resendToken = null;
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  static String _normalizePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      return '+255${clean.substring(1)}';
    }
    if (clean.startsWith('255') && clean.length == 12) {
      return '+$clean';
    }
    if (clean.startsWith('+255') && clean.length == 13) {
      return clean;
    }
    throw const OtpException('Weka namba ya Tanzania yenye tarakimu 10.');
  }
}

class OtpException implements Exception {
  const OtpException(this.message);
  final String message;
}
