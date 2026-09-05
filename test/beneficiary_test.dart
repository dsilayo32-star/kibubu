import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/beneficiary.dart';
import 'package:kibubu/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Beneficiary Model & AppState Tests', () {
    test('Beneficiary model creation and toMap / fromMap serialization', () {
      final now = DateTime(2025, 5, 10, 14, 30);
      final beneficiary = Beneficiary(
        name: 'Amina Ali Hassan',
        relationship: 'Mke / Mume',
        phone: '0712345678',
        nida: '19950101123450000123',
        allocationPercentage: 100,
        notes: 'Makazi: Dar es Salaam',
        updatedAt: now,
      );

      expect(beneficiary.isValid, isTrue);
      expect(beneficiary.name, 'Amina Ali Hassan');
      expect(beneficiary.relationship, 'Mke / Mume');
      expect(beneficiary.allocationPercentage, 100);

      final map = beneficiary.toMap();
      final reconstructed = Beneficiary.fromMap(map);

      expect(reconstructed.name, beneficiary.name);
      expect(reconstructed.relationship, beneficiary.relationship);
      expect(reconstructed.phone, beneficiary.phone);
      expect(reconstructed.nida, beneficiary.nida);
      expect(
        reconstructed.allocationPercentage,
        beneficiary.allocationPercentage,
      );
      expect(reconstructed.notes, beneficiary.notes);
    });

    test('Beneficiary validation: jina na simu vikiwa tupu isValid inarudisha false', () {
      final invalid = Beneficiary(name: '', relationship: 'Mtoto', phone: '');
      expect(invalid.isValid, isFalse);
    });

    test('Beneficiary validation inakataa simu na allocation zisizo sahihi', () {
      expect(
        Beneficiary(
          name: 'Rashid',
          relationship: 'Mtoto',
          phone: 'abc',
          allocationPercentage: 100,
        ).isValid,
        isFalse,
      );
      expect(
        Beneficiary(
          name: 'Rashid',
          relationship: 'Mtoto',
          phone: '0754112233',
          allocationPercentage: 101,
        ).isValid,
        isFalse,
      );
    });

    test('saveBeneficiary na removeBeneficiary zinahifadhi na kufuta taarifa kwenye state na SharedPreferences', () async {
      final b = Beneficiary(
        name: 'Rashid Juma',
        relationship: 'Mtoto',
        phone: '0754112233',
        allocationPercentage: 50,
      );

      await saveBeneficiary(b);
      expect(accountBeneficiary, isNotNull);
      expect(accountBeneficiary!.name, 'Rashid Juma');
      expect(accountBeneficiary!.relationship, 'Mtoto');

      // Thibitisha kwamba imehifadhiwa kwenye SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('accountBeneficiary'), isNotNull);

      // Futa mrithi
      await removeBeneficiary();
      expect(accountBeneficiary, isNull);
      expect(prefs.getString('accountBeneficiary'), isNull);
    });

    test('loadData inapakia accountBeneficiary iliyohifadhiwa awali', () async {
      final b = Beneficiary(
        name: 'Salma Hamisi',
        relationship: 'Mzazi',
        phone: '0688990011',
      );
      SharedPreferences.setMockInitialValues({
        'accountBeneficiary': b.toJson(),
        'fullName': 'Mtumiaji Jaribio',
      });

      await loadData();
      expect(accountBeneficiary, isNotNull);
      expect(accountBeneficiary!.name, 'Salma Hamisi');
      expect(accountBeneficiary!.relationship, 'Mzazi');
    });
  });
}
