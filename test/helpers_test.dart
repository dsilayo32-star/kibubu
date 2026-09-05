import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/services/security_service.dart';
import 'package:kibubu/utils/helpers.dart';

void main() {
  group('money()', () {
    test('inaongeza koma za maelfu', () {
      expect(money(1000000), 'TSh 1,000,000');
      expect(money(1000), 'TSh 1,000');
      expect(money(999), 'TSh 999');
      expect(money(0), 'TSh 0');
      expect(money(123456789), 'TSh 123,456,789');
    });

    test('inapunguza sehemu za desimali (inazungusha kwa karibu)', () {
      expect(money(1500.75), 'TSh 1,501'); // toStringAsFixed inazungusha
    });
  });

  group('formatDate()', () {
    test('inaonyesha tarehe kwa mpangilio siku/mwezi/mwaka', () {
      expect(formatDate(DateTime(2026, 3, 5)), '5/3/2026');
    });

    test('inarudisha -- kama tarehe hakuna', () {
      expect(formatDate(null), '--');
    });
  });

  group('formatDateTime()', () {
    test('inaongeza saa na dakika zenye zero', () {
      expect(formatDateTime(DateTime(2026, 1, 2, 9, 5)), '2/1/2026 saa 09:05');
    });
  });

  group('SecurityService', () {
    test('hash ya PIN ileile na salt ileile inalingana', () {
      expect(SecurityService.hashWith('salt1', '1234'),
          SecurityService.hashWith('salt1', '1234'));
    });

    test('salt tofauti inatoa hash tofauti', () {
      expect(SecurityService.hashWith('salt1', '1234'),
          isNot(SecurityService.hashWith('salt2', '1234')));
    });

    test('hash haiwezi kugeuzwa kurudi PIN', () {
      final hash = SecurityService.hashWith('salt1', '1234');
      expect(hash.contains('1234'), isFalse);
      expect(hash, isNot('1234'));
    });

    test('hash ni sha256 (hexter 64)', () {
      expect(SecurityService.hashWith('salt1', '1234'), matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });
}
