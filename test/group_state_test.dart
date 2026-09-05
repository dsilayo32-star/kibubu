import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/state/app_state.dart' as state;
import 'package:kibubu/state/group_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    savingsGroups = [];
    state.fullName = 'Mtumiaji Mtihani';
    state.phone = '0754000111';
  });

  group('Group Savings (VICOBA)', () {
    test('createNewGroup() inaunda kikundi chenye viongozi 3 na wawakilishi 2', () async {
      final group = await createNewGroup(
        name: 'Vicoba ya Umoja',
        description: 'Uwekezaji',
        targetPerMember: 150000.0,
        contributionFrequency: 'Kila Mwezi',
        rules: 'Kanuni za kikundi.',
        chairpersonName: 'Hamisi Ally',
        chairpersonPhone: '0754111222',
        secretaryName: 'Zainab Juma',
        secretaryPhone: '0712333444',
        treasurerName: 'Saidi Omary',
        treasurerPhone: '0688555666',
        rep1Name: 'Asha Bakari',
        rep1Phone: '0622777888',
        rep2Name: 'Kelvin Peter',
        rep2Phone: '0742999000',
      );

      expect(group.members.length, 5);
      expect(group.members[0].role, contains('Mwenyekiti'));
      expect(group.members[0].name, 'Hamisi Ally');
      expect(group.members[1].role, contains('Katibu'));
      expect(group.members[1].name, 'Zainab Juma');
      expect(group.members[2].role, contains('Mweka Hazina'));
      expect(group.members[2].name, 'Saidi Omary');
      expect(group.members[3].role, contains('Mwakilishi 1'));
      expect(group.members[3].name, 'Asha Bakari');
      expect(group.members[4].role, contains('Mwakilishi 2'));
      expect(group.members[4].name, 'Kelvin Peter');
    });

    test('contributeToGroup() inaongeza mchango na kuweka kwenye historia', () async {
      final group = await createNewGroup(
        name: 'Kikundi cha Familia',
        description: 'Akiba',
        targetPerMember: 50000.0,
        contributionFrequency: 'Kila Wiki',
        rules: 'Hakuna kutoa.',
      );

      await contributeToGroup(
        groupId: group.id,
        amount: 25000.0,
        memberName: 'Mtumiaji Mtihani',
      );

      expect(group.totalSaved, 25000.0);
      expect(group.progress, 0.5); // 25,000 / 50,000
      expect(group.history.length, 1);
      expect(group.history[0]['amount'], 25000.0);
    });

    test('joinGroupByCode() inamruhusu mwanachama kujiunga', () async {
      final group = await createNewGroup(
        name: 'Vicoba ya Biashara',
        description: 'Uwekezaji',
        targetPerMember: 200000.0,
        contributionFrequency: 'Kila Mwezi',
        rules: 'Tozo 5,000.',
      );

      state.fullName = 'Mwanachama Mpya';
      state.phone = '0655222333';

      final joined = await joinGroupByCode(group.code);
      expect(joined, isNotNull);
      expect(joined!.members.length, 2);
      expect(joined.members.any((m) => m.name == 'Mwanachama Mpya'), isTrue);
    });

    test('createNewGroup() inakataa taarifa zisizo sahihi', () async {
      expect(
        () => createNewGroup(
          name: '',
          description: 'Akiba',
          targetPerMember: 0,
          contributionFrequency: 'Kila Wiki',
          rules: '',
        ),
        throwsArgumentError,
      );
    });
  });
}
