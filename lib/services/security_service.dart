import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Huduma ya usalama: PIN haitahifadhiwa kama maandishi wazi tena.
/// Tunaweka hash ya PIN pamoja na salt ya kipekee.
class SecurityService {
  static String _salt = '';
  /// Anzisha salt — itengenezwe mara moja tu na kuhifadhiwa.
  static Future<void> load(String storedSalt) async {
    _salt = storedSalt;
  }

  static String get salt => _salt;

  static String hash(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Hash kwa salt fulani (hutumika wakati wa migration na verify).
  static String hashWith(String salt, String pin) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Tengeneza salt mpya ya kipekee kwa kila akaunti.
  static String generateSalt() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}