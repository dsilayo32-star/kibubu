import 'dart:async';

import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../state/app_state.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';
import 'add_money_page.dart';
import 'beneficiary_page.dart';
import 'goal_pages.dart';
import 'groups_page.dart';
import 'loans_page.dart';
import 'profile_page.dart';
import 'report_page.dart';
import 'auth_pages.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  Timer? countdownTimer;
  bool goalsUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!SessionService.isActive) SessionService.start();
    checkAndApplyAllInactivityFees().then((_) {
      if (mounted) setState(() {});
    });
    refreshLoanStatuses();
    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => goalsUnlocked = false);
    }
    if (state == AppLifecycleState.resumed && !SessionService.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SessionService.unlock(context);
      });
    } else if (state == AppLifecycleState.resumed) {
      SessionService.touch();
    }
  }

  void _refresh() {
    SessionService.touch();
    if (mounted) setState(() {});
  }

  Future<void> openAddMoneyPage() async {
    if (goalName.isEmpty) return;
    if (!await _unlockGoals()) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMoneyPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> openGoalsPage() async {
    if (!await _unlockGoals()) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalsPage()),
    );
    if (mounted) setState(() {});
  }

  void openHistory() {
    _openProtectedPage(const SavingsHistoryPage());
  }

  Future<bool> _unlockGoals() async {
    if (!hasPin) return false;
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GoalsPasswordPage()),
    );
    if (unlocked == true && mounted) {
      setState(() => goalsUnlocked = true);
    }
    return unlocked == true;
  }

  Future<void> _openProtectedPage(Widget page) async {
    if (!await _unlockGoals()) return;
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> openGoalDetail(int index) async {
    if (!await _unlockGoals()) return;
    if (!mounted) return;
    setState(() => activeGoalIndex = index);
    loadGoalRecord(goals[index]);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalDetailScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasGoal = goals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KIBUBU 💰'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Malengo yangu',
            onPressed: openGoalsPage,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Wasifu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) => _refresh()),
                  borderRadius: BorderRadius.circular(25),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      profileAvatar,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Karibu, $fullName! 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Simu: $phone',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activeLoan != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mkopo Ulio Hai (Akiba ni Dhamana)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Deni lililobaki: ${money(activeLoan!.remainingBalance)} (Dhamana: ${money(lockedCollateralAmount)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoansPage()),
                      ).then((_) => _refresh()),
                      child: const Text(
                        'LIPA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SectionTitle(
              goalsUnlocked && goals.isNotEmpty
                  ? 'MALENGO YAKO (${goals.length})'
                  : 'MALENGO',
            ),
            const SizedBox(height: 12),
            goalsUnlocked ? _goalsList() : _lockedGoalsPreview(),
            const SizedBox(height: 24),
            const SectionTitle('MENYU KUU'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MenuTile(
                    icon: Icons.flag,
                    label: 'MALENGO',
                    onTap: openGoalsPage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MenuTile(
                    icon: Icons.savings,
                    label: 'WEKA AKIBA',
                    enabled: hasGoal,
                    onTap: openAddMoneyPage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MenuTile(
                    icon: Icons.history,
                    label: 'HISTORIA',
                    enabled: hasGoal,
                    onTap: openHistory,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MenuTile(
                    icon: Icons.bar_chart,
                    label: 'MUHTASARI',
                    enabled: hasGoal,
                    onTap: () => _openProtectedPage(const ReportPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MenuTile(
                    icon: Icons.groups,
                    label: 'VICOBA',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GroupsListPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MenuTile(
                    icon: Icons.payments_outlined,
                    label: 'MIKOPO',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoansPage()),
                    ).then((_) => _refresh()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MenuTile(
                    icon: Icons.family_restroom,
                    label: 'MRITHI',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BeneficiaryPage(),
                      ),
                    ).then((_) => _refresh()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MenuTile(
                    icon: Icons.person,
                    label: 'AKAUNTI',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ).then((_) => _refresh()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!await _unlockGoals()) return;
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalPage()),
                  );
                  if (mounted) _refresh();
                },
                icon: Icon(hasGoal ? Icons.add : Icons.flag),
                label: Text(
                  hasGoal ? 'TENGENEZA LENGO JIPYA 🎯' : 'TENGENEZA LENGO 🎯',
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Orodha ya malengo yote ya mtumiaji (hadhi kila moja kama kadi ya muhtasari).
  Widget _goalsList() {
    if (goals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.flag_circle, size: 60, color: AppColors.green),
              const SizedBox(height: 12),
              const Text(
                'Bado hujatengeneza lengo.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Anza kwa kubofya "TENGENEZA LENGO" hapa chini. 🎯',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: goals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _goalSummaryCard(goals[index], index),
    );
  }

  Widget _lockedGoalsPreview() {
    final message = goals.isEmpty
        ? 'Bado hujatengeneza lengo.'
        : 'Malengo na mwenendo wako vimefungwa. Fungua kwa PIN ili kuendelea.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.green, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Fungua malengo',
              icon: const Icon(Icons.arrow_forward, color: AppColors.green),
              onPressed: openGoalsPage,
            ),
          ],
        ),
      ),
    );
  }

  /// Kadi ya muhtasari wa lengo moja: jina, % na kiasi kilichobaki.
  Widget _goalSummaryCard(Goal goal, int index) {
    final target = goal.target;
    final saved = goal.saved;
    final remaining = goal.remaining;
    final progress = goal.progress;
    final done = goal.completed;
    final end = goal.end;
    final lastSaved = goal.lastSavedAt;
    final start = goal.start;
    final ref = lastSaved ?? start;
    final inactiveDays = ref != null
        ? DateTime.now().difference(ref).inDays
        : 0;
    final pastDeadline =
        end != null &&
        !DateTime.now().isBefore(
          DateTime(end.year, end.month, end.day, 23, 59, 59),
        );
    final status = done
        ? 'Imekamilika ✅'
        : pastDeadline
        ? 'Deadline imefika ⏰'
        : 'Inaendelea 🔒';
    final statusColor = done
        ? AppColors.green
        : pastDeadline
        ? AppColors.red
        : AppColors.gold;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openGoalDetail(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      goal.image,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: AppColors.lightGreen,
                    valueColor: const AlwaysStoppedAnimation(AppColors.green),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${money(saved)} / ${money(target)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Kilichobaki: ${money(remaining)} • ${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
              if (saved > 0 && !done && inactiveDays >= 14) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: inactiveDays >= 21
                          ? AppColors.red
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        inactiveDays >= 21
                            ? 'Tozo ya 6% inatumika (wiki 3+ bila akiba)'
                            : 'Baki siku ${21 - inactiveDays} kabla ya tozo ya 6%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: inactiveDays >= 21
                              ? AppColors.red
                              : Colors.orange.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
