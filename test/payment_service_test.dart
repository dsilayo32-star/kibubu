import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/services/payment_service.dart';

void main() {
  setUp(() {
    PaymentService.activeBaseUrl = '';
  });

  group('PaymentService', () {
    test('detectNetwork() inatambua mitandao yote 4 kwa usahihi', () {
      expect(PaymentService.detectNetwork('0754123456'), MobileNetwork.mpesa);
      expect(PaymentService.detectNetwork('0742123456'), MobileNetwork.mpesa);
      expect(
        PaymentService.detectNetwork('0655123456'),
        MobileNetwork.tigoPesa,
      );
      expect(
        PaymentService.detectNetwork('0712123456'),
        MobileNetwork.tigoPesa,
      );
      expect(
        PaymentService.detectNetwork('0688123456'),
        MobileNetwork.airtelMoney,
      );
      expect(
        PaymentService.detectNetwork('0784123456'),
        MobileNetwork.airtelMoney,
      );
      expect(
        PaymentService.detectNetwork('0622123456'),
        MobileNetwork.haloPesa,
      );
      expect(
        PaymentService.detectNetwork('+255754123456'),
        MobileNetwork.mpesa,
      );
    });

    test('calculateFee() inatoa tozo sahihi kulingana na kiasi', () {
      expect(PaymentService.calculateFee(3000), 0.0);
      expect(PaymentService.calculateFee(20000), 150.0);
      expect(PaymentService.calculateFee(100000), 350.0);
      expect(PaymentService.calculateFee(500000), 500.0);
    });

    test('isSupportedPhone() inakataa namba batili', () {
      expect(PaymentService.isSupportedPhone('0754123456'), isTrue);
      expect(PaymentService.isSupportedPhone('+255754123456'), isTrue);
      expect(PaymentService.isSupportedPhone('123'), isFalse);
    });

    test('processPayment() inakataa kiasi kisicho halali', () async {
      expect(
        () => PaymentService.processPayment(
          phone: '0754123456',
          network: MobileNetwork.mpesa,
          amount: 0,
          type: 'DEPOSIT',
        ),
        throwsA(isA<PaymentException>()),
      );
    });

    test(
      'processPayment() haiongezi salio bila uthibitisho wa backend',
      () async {
        final tx = await PaymentService.processPayment(
          phone: '0754123456',
          network: MobileNetwork.mpesa,
          amount: 50000,
          type: 'DEPOSIT',
          goalName: 'Ada ya Shule',
        );

        expect(tx.status, 'PENDING');
        expect(tx.amount, 50000);
        expect(tx.fee, 150.0);
        expect(tx.total, 50150.0);
        expect(tx.reference, startsWith('KB-'));
        expect(tx.goalName, 'Ada ya Shule');
      },
    );
  });
}
