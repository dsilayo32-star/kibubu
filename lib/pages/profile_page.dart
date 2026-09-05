import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/savings_entry.dart';
import '../services/firebase_service.dart';
import '../services/settings_service.dart';
import '../services/session_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/export_helper.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';
import 'beneficiary_page.dart';
import 'goal_pages.dart';
import 'home_page.dart';
import 'loans_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const List<String> avatarOptions = [
    '👤',
    '👨‍💼',
    '👩‍💼',
    '👨‍🌾',
    '👩‍🎓',
    '👨‍💻',
    '🧕',
    '🧔',
    '👵',
    '🧓',
    '👸',
    '🤴',
    '🦁',
    '💼',
    '⭐',
  ];

  Future<void> _changeAvatar() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CHAGUA PICHA YA WASIFU 👤'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: avatarOptions.map((av) {
              final isSel = profileAvatar == av;
              return InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => Navigator.pop(ctx, av),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.lightGreen : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? AppColors.green : Colors.grey.shade300,
                      width: isSel ? 2.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(av, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GHAIRI'),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() => profileAvatar = selected);
      await saveAccountData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picha ya wasifu imesasishwa! ✅')),
        );
      }
    }
  }

  Future<void> changePin(BuildContext context) async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmedPinController = TextEditingController();

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('BADILISHA PIN 🔐'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN ya zamani'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN mpya'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmedPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rudia PIN mpya'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPin = oldPinController.text.trim();
              final newPin = newPinController.text.trim();
              final confirmedPin = confirmedPinController.text.trim();
              if (!verifyPin(oldPin)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN ya zamani si sahihi.')),
                );
                return;
              }
              if (newPin.length < 4 || newPin != confirmedPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'PIN mpya lazima iwe na tarakimu 4 na zilingane.',
                    ),
                  ),
                );
                return;
              }
              await setPin(newPin);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('HIFADHI'),
          ),
        ],
      ),
    );

    oldPinController.dispose();
    newPinController.dispose();
    confirmedPinController.dispose();

    if (changed == true) {
      await saveAccountData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN imebadilishwa vizuri. ✅')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AKAUNTI YANGU 👤')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                InkWell(
                  onTap: _changeAvatar,
                  borderRadius: BorderRadius.circular(52),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      profileAvatar,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _changeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '$village, $district, $region',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 22),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: AppColors.green),
                    title: const Text('Jina kamili'),
                    subtitle: Text(fullName),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.green),
                    title: const Text('Namba ya simu'),
                    subtitle: Text(phone),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: const Icon(Icons.cake, color: AppColors.green),
                    title: const Text('Tarehe ya kuzaliwa'),
                    subtitle: Text(birthDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.family_restroom,
                      color: AppColors.green,
                    ),
                    title: const Text('Mrithi wa Akaunti (Next of Kin)'),
                    subtitle: Text(
                      accountBeneficiary != null
                          ? '${accountBeneficiary!.name} (${accountBeneficiary!.relationship})'
                          : 'Bado hujaweka mrithi wa akaunti',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (accountBeneficiary != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Yupo',
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BeneficiaryPage(),
                      ),
                    ).then((_) => setState(() {})),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.green,
                    ),
                    title: const Text('Mikopo yenye Dhamana ya Akiba'),
                    subtitle: Text(
                      activeLoan != null
                          ? 'Deni lililopo: ${money(activeLoan!.remainingBalance)}'
                          : (totalSavingsAcrossAllGoals >= 50000
                                ? 'Huduma imefunguliwa (hadi 20%)'
                                : 'Imefungwa (akiba < 50,000)'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoansPage()),
                    ).then((_) => setState(() {})),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => changePin(context),
                icon: const Icon(Icons.lock),
                label: const Text('BADILISHA PIN'),
              ),
            ),
            const SizedBox(height: 16),
            const _SettingsSection(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  SessionService.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('TOKA'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Malengo yaliyowekwa: ${goals.length}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class SavingsHistoryPage extends StatelessWidget {
  const SavingsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final allEntries = _allGoalEntries();
    final deposits = allEntries
        .where((e) => !e.isWithdrawal)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final withdrawals = allEntries
        .where((e) => e.isWithdrawal)
        .fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORIA YA AKIBA 📊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Kusafirisha / Shiriki Ripoti',
            onPressed: () {
              final csv = ExportHelper.generateCsv(allEntries);
              final text = ExportHelper.generateTextSummary(
                userName: fullName,
                goalsList: goals,
                entries: allEntries,
                now: DateTime.now(),
              );
              ExportHelper.showExportDialog(
                context,
                title: 'Historia ya Akiba 📑',
                csvData: csv,
                textSummary: text,
              );
            },
          ),
        ],
      ),
      body: allEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 70,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 12),
                  const Text('Hakuna rekodi za akiba bado. 💵'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: allEntries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('MALENGO YAKO (${goals.length})'),
                      const SizedBox(height: 10),
                      _allGoalsOverview(context),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              label: 'Jumla uliyoweka',
                              amount: deposits,
                              icon: Icons.south_west,
                              highlight: true,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatTile(
                              label: 'Jumla uliyotoa',
                              amount: withdrawals,
                              icon: Icons.north_east,
                              highlight: true,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _WeeklyChart(),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                final saving = allEntries[index - 1];
                final amount = saving.amount;
                final date = saving.date;
                final goalLabel = saving.goalName ?? '';
                final isWithdrawal = saving.isWithdrawal;
                final isPenalty = saving.isPenalty;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPenalty
                          ? Colors.orange.withValues(alpha: 0.15)
                          : (isWithdrawal
                                ? AppColors.red.withValues(alpha: 0.12)
                                : AppColors.lightGreen),
                      child: Icon(
                        isPenalty
                            ? Icons.warning_amber_rounded
                            : (isWithdrawal
                                  ? Icons.north_east
                                  : Icons.south_west),
                        color: isPenalty
                            ? Colors.orange.shade800
                            : (isWithdrawal ? AppColors.red : AppColors.green),
                      ),
                    ),
                    title: Text(
                      isPenalty
                          ? 'TOZO YA KUTOWEKA AKIBA (6%): ${money(amount)}'
                          : '${isWithdrawal ? 'ULITOA' : 'ULIWEKA'}: ${money(amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPenalty
                            ? Colors.orange.shade800
                            : (isWithdrawal
                                  ? AppColors.red
                                  : AppColors.darkGreen),
                      ),
                    ),
                    subtitle: goalLabel.isEmpty
                        ? Text(formatDateTime(date))
                        : Text('$goalLabel • ${formatDateTime(date)}'),
                    trailing: Text(
                      isWithdrawal || isPenalty ? '−' : '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isWithdrawal || isPenalty
                            ? AppColors.red
                            : AppColors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Kadi za muhtasari wa malengo yote: jina, maendeleo na kilichobaki.
  Widget _allGoalsOverview(BuildContext context) {
    if (goals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Hakuna malengo yaliyosajiriwa bado.'),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < goals.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _goalOverviewCard(context, goals[i], i),
          ),
      ],
    );
  }

  Widget _goalOverviewCard(BuildContext context, Goal goal, int index) {
    final target = goal.target;
    final saved = goal.saved;
    final progress = goal.progress;
    final remaining = goal.remaining;
    final done = goal.completed;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          activeGoalIndex = index;
          loadGoalRecord(goal);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalDetailScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.flag, color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (done)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.lightGreen,
                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${money(saved)} / ${money(target)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    done ? 'Imekamilika ✅' : 'Kilichobaki: ${money(remaining)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kusanya historia ya malengo YOTE + ile ya lengo lililo active,
  /// panga kwa tarehe (mpya juu).
  List<SavingsEntry> _allGoalEntries() => ExportHelper.collectAllEntries(
    goalsList: goals,
    currentGoalName: goalName,
    currentHistory: savingsHistory,
  );
}

class _SettingsSection extends StatefulWidget {
  const _SettingsSection();

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  final _firebase = FirebaseService();
  bool _syncing = false;
  bool _restoring = false;

  Future<void> _handleCloudBackup() async {
    if (!FirebaseService.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase haijaunganishwa bado kwenye mradi huu (angalia FIREBASE_SETUP.md).',
          ),
        ),
      );
      return;
    }
    setState(() => _syncing = true);
    final ok = await _firebase.syncToCloud();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ Data zote zimehifadhiwa Cloud kikamilifu!'
              : '❌ Hitilafu ya mtandao au Firebase wakati wa kuhifadhi.',
        ),
      ),
    );
  }

  Future<void> _handleCloudRestore() async {
    if (!FirebaseService.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase haijaunganishwa bado kwenye mradi huu (angalia FIREBASE_SETUP.md).',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('REJESHA KUTOKA CLOUD ☁️'),
        content: const Text(
          'Hii itaburuta data yako iliyopo Firebase na kusasisha taarifa na malengo kwenye simu hii. Je, unataka kuendelea?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('REJESHA'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _restoring = true);
    final ok = await _firebase.restoreFromCloud();
    if (!mounted) return;
    setState(() => _restoring = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Data imerejeshwa kutoka Cloud!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Hakuna data ya kurejesha au kuna hitilafu ya mtandao.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MIPANGILIO ⚙️',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.dark_mode,
              color: isDark ? AppColors.lightGreen : AppColors.green,
            ),
            title: const Text('Mandhari ya Giza (Dark Mode)'),
            subtitle: Text(darkMode ? 'Imewashwa 🌙' : 'Imezimwa ☀️'),
            value: darkMode,
            onChanged: (value) async {
              await SettingsService.setDarkMode(value);
              if (mounted) setState(() {});
            },
          ),
          const Divider(height: 1, indent: 16),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_active,
              color: AppColors.green,
            ),
            title: const Text('Kikumbusho cha kila siku'),
            subtitle: const Text('Saa mbili usiku (20:00)'),
            value: notificationsEnabled,
            onChanged: (value) async {
              await SettingsService.setNotificationsEnabled(value);
              if (mounted) setState(() {});
            },
          ),
          const Divider(height: 1, indent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: AppColors.green),
            title: const Text('Fingerprint'),
            subtitle: const Text('Tumia alama ya kidole badala ya PIN'),
            value: biometricsEnabled,
            onChanged: (value) async {
              await SettingsService.setBiometricsEnabled(value);
              if (mounted) setState(() {});
            },
          ),
          const Divider(height: 1, indent: 16),
          ListTile(
            leading: Icon(
              FirebaseService.isReady ? Icons.cloud_done : Icons.cloud_queue,
              color: FirebaseService.isReady ? AppColors.green : Colors.grey,
            ),
            title: const Text('Cloud Backup & Restore'),
            subtitle: Text(
              FirebaseService.isReady
                  ? 'Firebase iko tayari — hifadhi au rejesha data.'
                  : 'Firebase haijawekwa (local mode inafanya kazi).',
            ),
            trailing: _syncing || _restoring
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Hifadhi Cloud',
                        icon: const Icon(
                          Icons.cloud_upload,
                          color: AppColors.green,
                        ),
                        onPressed: _handleCloudBackup,
                      ),
                      IconButton(
                        tooltip: 'Rejesha kutoka Cloud',
                        icon: const Icon(
                          Icons.cloud_download,
                          color: AppColors.darkGreen,
                        ),
                        onPressed: _handleCloudRestore,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart ya akiba iliyowekwa kwa siku katika siku 7 zilizopita.
class _WeeklyChart extends StatelessWidget {
  static const _dayLabels = ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Iju', 'Jmo', 'Jpi'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daily = List.generate(7, (i) => 0.0);
    for (final saving in savingsHistory) {
      if (saving.isWithdrawal) continue;
      final date = saving.date;
      final day = DateTime(date.year, date.month, date.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) {
        daily[6 - diff] += saving.amount;
      }
    }
    final maxAmount = daily.fold<double>(0, (max, v) => v > max ? v : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AKIBA LA SIKU 7 📈',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  maxY: maxAmount == 0 ? 100 : maxAmount * 1.2,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i > 6) return const SizedBox.shrink();
                          return Text(
                            _dayLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: daily[i],
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          color: daily[i] > 0
                              ? AppColors.green
                              : Colors.grey.shade300,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
