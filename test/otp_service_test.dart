import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/services/otp_service.dart';

void main() {
  group('OtpService', () {
    test('verifyOtp() inakataa OTP kabla ya Firebase kutuma challenge', () async {
      expect(await OtpService.verifyOtp('123456'), isFalse);
    });

    test('sendOtp() inakataa namba isiyo sahihi kabla ya provider', () async {
      expect(
        () => OtpService.sendOtp('123', onCodeSent: () {}),
        throwsA(isA<OtpException>()),
      );
    });

    test('OTP yenye tarakimu zisizo 6 inakataliwa', () async {
      expect(await OtpService.verifyOtp('12'), isFalse);
    });
  });
}
