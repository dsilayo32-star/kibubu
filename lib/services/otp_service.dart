import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Huduma ya SMS OTP ya Firebase Phone Authentication.
class OtpService {
  static String? _verificationId;
  static int? _resendToken;

  /// Hutuma OTP na kukamilika pindi Firebase inapothibitisha ombi.
  ///
  /// `verifyPhoneNumber()` haina Future inayosubiriwa — matokeo huja kupitia
  /// callbacks. Hivyo kosa la `verificationFailed` linakamatwa hapa na
  /// kurudishwa kama kosa la Future, badala ya kutupwa ndani ya callback
  /// (ambako linafichwa na UI kubaki kwenye "Inatuma...").
  static Future<void> sendOtp(
    String phone, {
    required void Function() onCodeSent,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final completer = Completer<void>();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(
              OtpException(
                error.message ??
                    'SMS OTP imeshindikana. Hakikisha namba ni sahihi.',
              ),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) completer.complete();
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on OtpException {
      rethrow;
    } catch (_) {
      if (!completer.isCompleted) {
        completer.completeError(
          const OtpException('SMS OTP haikupatikana. Jaribu tena baadaye.'),
        );
      }
    }

    return completer.future.then((_) => null);
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
