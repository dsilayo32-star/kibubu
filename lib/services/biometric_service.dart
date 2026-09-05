import 'package:local_auth/local_auth.dart';

/// Huduma ya biometrics (fingerprint / Face ID) kwa login.
class BiometricService {
  static final _auth = LocalAuthentication();

  /// Je, kifaa kina fingerprint/Face ID na imewashwa?
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Onyesha dirisha la uthibitisho. Inarudi true kama ikafanikiwa.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Thibitisha utambulisho wako kuingia Kibubu.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
