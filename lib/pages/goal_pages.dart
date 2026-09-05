import 'dart:async';

import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/savings_entry.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';
import 'add_money_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  Future<void> addGoal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalPage()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MALENGO YANGU 🎯')),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flag_circle,
                    size: 70,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bado hujatengeneza lengo.',
                    style: TextStyle(fontSize: 17),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final target = goal.target;
                final saved = goal.saved;
                final progress = goal.progress;
                final done = goal.completed;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      activeGoalIndex = index;
                      loadGoalRecord(goal);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedGoalPage(),
                        ),
                      ).then((_) => setState(() {}));
                    },
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
                                ),
                              ),
                              if (done)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.green,
                                  ),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    activeGoalIndex = index;
                                    loadGoalRecord(goal);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SavedGoalPage(),
                                      ),
                                    ).then((_) => setState(() {}));
                                  } else if (value == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('FUTA LENGO 🗑️'),
                                        content: Text(
                                          'Una uhakika unataka kufuta lengo "${goal.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, false),
                                            child: const Text('GHAIRI'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, true),
                                            child: const Text('FUTA'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await deleteGoal(index);
                                      if (mounted) setState(() {});
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: AppColors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Fungua / Hariri'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: AppColors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Futa',
                                          style: TextStyle(
                                            color: AppColors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppColors.lightGreen,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${money(saved)} / ${money(target)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 13,
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
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addGoal,
        icon: const Icon(Icons.add),
        label: const Text('ONGEZA LENGO'),
      ),
    );
  }
}

/// Screen ya maelezo kamili ya lengo lililochaguliwa (inatumika kutoka Dashboard).
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => const SavedGoalPage();
}

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final goalController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String selectedIcon = '🎯';

  static const List<String> iconOptions = [
    '🎯',
    '🏠',
    '🚗',
    '🎓',
    '💍',
    '🏬',
    '📱',
    '🏥',
    '🌾',
    '✈️',
    '👶',
    '💰',
    '🛋️',
    '🛵',
    '💻',
  ];

  Future<void> chooseStartDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
    );
    if (selected != null) {
      setState(() {
        selectedStartDate = selected;
        selectedEndDate = null;
      });
    }
  }

  Future<void> chooseEndDate() async {
    if (selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kwanza chagua tarehe ya kuanza.')),
      );
      return;
    }
    final minimumEndDate = selectedStartDate!.add(const Duration(days: 7));
    final selected = await showDatePicker(
      context: context,
      initialDate: minimumEndDate,
      firstDate: minimumEndDate,
      lastDate: DateTime(selectedStartDate!.year + 10),
    );
    if (selected != null) setState(() => selectedEndDate = selected);
  }

  Future<void> saveGoal() async {
    final amount = double.tryParse(amountController.text.trim());
    if (goalController.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        selectedStartDate == null ||
        selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jaza taarifa zote na weka kiasi sahihi cha lengo.'),
        ),
      );
      return;
    }
    syncActiveGoal();
    goalName = goalController.text.trim();
    goalImage = selectedIcon;
    targetAmount = amount;
    savedAmount = 0;
    savingsHistory = [];
    lastSavedAt = null;
    goalCompleted = false;
    startDate = selectedStartDate;
    endDate = selectedEndDate;
    activeGoalIndex = goals.length;
    goals.add(goalRecord());
    await saveGoalData();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SavedGoalPage()),
    );
  }

  @override
  void dispose() {
    goalController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dateText(DateTime? date, String emptyText) =>
        date == null ? emptyText : formatDate(date);
    return Scaffold(
      appBar: AppBar(title: const Text('TENGENEZA LENGO 🎯')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientCard(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lengo limefungwa mpaka tarehe ya mwisho — hii hukuzuia kutumia akiba kabla ya wakati. 🔒',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(
                labelText: 'Jina la Lengo',
                hintText: 'Mfano: Ada ya shule',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chagua Picha / Nembo ya Lengo:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: iconOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final icon = iconOptions[idx];
                  final isSel = selectedIcon == icon;
                  return InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => setState(() => selectedIcon = icon),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.lightGreen
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? AppColors.green : Colors.grey.shade300,
                          width: isSel ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kiasi cha Lengo',
                hintText: 'Mfano: 1000000',
                prefixText: 'TSh ',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _DateButton(
              label: selectedStartDate == null
                  ? 'CHAGUA TAREHE YA KUANZA 📅'
                  : 'Kuanza: ${dateText(selectedStartDate, '')}',
              icon: Icons.event,
              selected: selectedStartDate != null,
              onTap: chooseStartDate,
            ),
            const SizedBox(height: 12),
            _DateButton(
              label: selectedEndDate == null
                  ? 'CHAGUA TAREHE YA MWISHO 📅'
                  : 'Mwisho: ${dateText(selectedEndDate, '')}',
              icon: Icons.event_available,
              selected: selectedEndDate != null,
              onTap: chooseEndDate,
            ),
            const SizedBox(height: 10),
            Text(
              'ℹ️ Tarehe ya mwisho lazima iwe angalau siku 7 baada ya tarehe ya kuanza.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: saveGoal,
              icon: const Icon(Icons.save),
              label: const Text('SAVE LENGO 💾'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightGreen : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.green : const Color(0xFFDCE5E0),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.green : Colors.grey),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.darkGreen : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedGoalPage extends StatefulWidget {
  const SavedGoalPage({super.key});

  @override
  State<SavedGoalPage> createState() => _SavedGoalPageState();
}

class _SavedGoalPageState extends State<SavedGoalPage> {
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> openAddMoneyPage() async {
    final amount = await Navigator.push<double>(
      context,
      MaterialPageRoute(builder: (_) => const AddMoneyPage()),
    );
    if (amount != null && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Umeweka ${money(amount)} kwenye lengo.')),
      );
    }
  }

  Future<void> completeGoal() async {
    if (savedAmount < targetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengo bado halijafikiwa. Ongeza akiba au muda.'),
        ),
      );
      return;
    }
    goalCompleted = true;
    await saveGoalData();
    if (mounted) setState(() {});
  }

  Future<void> extendGoalDeadline() async {
    final today = DateTime.now();
    final newEndDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(today.year + 10),
    );
    if (newEndDate == null || !mounted) return;

    setState(() {
      endDate = newEndDate;
      goalCompleted = false;
    });
    await saveGoalData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Muda wa lengo umeongezwa. ✅')),
    );
  }

  Future<void> increaseGoalTarget() async {
    final amountController = TextEditingController();
    final newTarget = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ONGEZA KIWANGO 💰'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Kiasi kipya cha lengo',
            prefixText: 'TSh ',
            hintText: 'Zaidi ya ${money(targetAmount)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(amountController.text.trim());
              if (value == null || value <= targetAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kiasi kipya lazima kizidi target ya sasa.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('HIFADHI'),
          ),
        ],
      ),
    );
    amountController.dispose();
    if (newTarget == null || !mounted) return;
    setState(() {
      targetAmount = newTarget;
      goalCompleted = false;
    });
    await saveGoalData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kiwango cha lengo kimeongezwa. ✅')),
    );
  }

  Future<void> withdrawSavings() async {
    if (!goalPastDeadline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Huwezi kutoa akiba kabla ya deadline. 🔒'),
        ),
      );
      return;
    }

    final maxAvailableToWithdraw = (savedAmount - lockedCollateralAmount).clamp(
      0.0,
      savedAmount,
    );
    if (lockedCollateralAmount > 0 && maxAvailableToWithdraw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Huwezi kutoa akiba kwa sasa. Kiasi cha ${money(lockedCollateralAmount)} kimefungwa kama dhamana ya mkopo wako ulio hai. 🔒',
          ),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('TOA AKIBA 💸'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lockedCollateralAmount > 0) ...[
              Text(
                'Kumbuka: ${money(lockedCollateralAmount)} imefungwa kama dhamana ya mkopo.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Kiasi cha kutoa',
                hintText: 'Hadi ${money(maxAvailableToWithdraw)}',
                prefixText: 'TSh ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(amountController.text.trim());
              if (value == null ||
                  value <= 0 ||
                  value > maxAvailableToWithdraw) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Weka kiasi sahihi (Kisichozidi ${money(maxAvailableToWithdraw)} inayopatikana).',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('TOA'),
          ),
        ],
      ),
    );
    amountController.dispose();
    if (amount == null || !mounted) return;
    setState(() {
      savedAmount -= amount;
      savingsHistory.add(
        SavingsEntry(amount: amount, date: DateTime.now(), type: 'withdrawal'),
      );
    });
    await saveSavingsData();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Umetoa ${money(amount)}.')));
    }
  }

  Future<void> editGoalDialog() async {
    final nameCtrl = TextEditingController(text: goalName);
    final targetCtrl = TextEditingController(
      text: targetAmount > 0
          ? (targetAmount == targetAmount.roundToDouble()
                ? targetAmount.toStringAsFixed(0)
                : targetAmount.toString())
          : '',
    );
    DateTime? editStart = startDate;
    DateTime? editEnd = endDate;
    String editIcon = goalImage;
    const icons = [
      '🎯',
      '🏠',
      '🚗',
      '🎓',
      '💍',
      '🏬',
      '📱',
      '🏥',
      '🌾',
      '✈️',
      '👶',
      '💰',
      '🛋️',
      '🛵',
      '💻',
    ];

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('HARIRI LENGO ✏️'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Jina la Lengo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Picha / Nembo ya Lengo:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final ic = icons[i];
                        final isSel = editIcon == ic;
                        return InkWell(
                          onTap: () => setDialogState(() => editIcon = ic),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.lightGreen
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? AppColors.green
                                    : Colors.grey.shade300,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              ic,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Kiasi cha Lengo',
                      prefixText: 'TSh ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.event,
                            color: AppColors.green,
                          ),
                          title: const Text('Tarehe ya Kuanza'),
                          subtitle: Text(
                            editStart != null
                                ? formatDate(editStart)
                                : 'Haijachaguliwa',
                          ),
                          trailing: const Icon(Icons.edit_calendar, size: 20),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editStart ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(DateTime.now().year + 10),
                            );
                            if (picked != null) {
                              setDialogState(() => editStart = picked);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.event_available,
                            color: AppColors.green,
                          ),
                          title: const Text('Tarehe ya Mwisho'),
                          subtitle: Text(
                            editEnd != null
                                ? formatDate(editEnd)
                                : 'Haijachaguliwa',
                          ),
                          trailing: const Icon(Icons.edit_calendar, size: 20),
                          onTap: () async {
                            final minDate = (editStart ?? DateTime.now()).add(
                              const Duration(days: 1),
                            );
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  editEnd != null && editEnd!.isAfter(minDate)
                                  ? editEnd!
                                  : minDate.add(const Duration(days: 6)),
                              firstDate: minDate,
                              lastDate: DateTime(DateTime.now().year + 10),
                            );
                            if (picked != null) {
                              setDialogState(() => editEnd = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('GHAIRI'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = nameCtrl.text.trim();
                  final newTarget = double.tryParse(targetCtrl.text.trim());
                  if (newName.isEmpty ||
                      newTarget == null ||
                      newTarget <= 0 ||
                      editStart == null ||
                      editEnd == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tafadhali jaza taarifa zote kwa usahihi.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogCtx, true);
                },
                child: const Text('HIFADHI'),
              ),
            ],
          );
        },
      ),
    );

    final updatedName = nameCtrl.text.trim();
    final updatedTarget = double.tryParse(targetCtrl.text.trim());
    nameCtrl.dispose();
    targetCtrl.dispose();

    if (saved == true &&
        updatedName.isNotEmpty &&
        updatedTarget != null &&
        editStart != null &&
        editEnd != null) {
      goalImage = editIcon;
      await updateGoal(
        index: activeGoalIndex,
        name: updatedName,
        target: updatedTarget,
        start: editStart!,
        end: editEnd!,
        image: editIcon,
      );
      if (activeGoalIndex >= 0 && activeGoalIndex < goals.length) {
        await saveGoalData();
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengo limesasishwa vizuri. ✅')),
        );
      }
    }
  }

  Future<void> confirmDeleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('FUTA LENGO 🗑️'),
        content: Text(
          'Una uhakika unataka kufuta lengo "$goalName"?\n'
          '${savedAmount > 0 ? "\n⚠️ Akiba iliyopo ya ${money(savedAmount)} itafutwa pia." : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('FUTA'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deletedName = goalName;
      await deleteGoal(activeGoalIndex);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lengo "$deletedName" limefutwa.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = progressValue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LENGO LIMEHIFADHIWA 💰'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chaguzi za lengo',
            onSelected: (value) {
              if (value == 'edit') {
                editGoalDialog();
              } else if (value == 'delete') {
                confirmDeleteGoal();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppColors.green),
                    SizedBox(width: 10),
                    Text('Hariri Lengo'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.red),
                    SizedBox(width: 10),
                    Text('Futa Lengo', style: TextStyle(color: AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GradientCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      goalImage,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    goalName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Row(
                      children: [
                        ProgressRing(progress: value, size: 74),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lengo: ${money(targetAmount)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Umeweka: ${money(savedAmount)}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kuanza ${formatDate(startDate)} • Mwisho ${formatDate(endDate)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (endDate != null) ...[
                    const Divider(color: Colors.white24, height: 28),
                    Text(
                      '⏰ ${countdownText()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (lastSavedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Akiba ya mwisho: ${formatDateTime(lastSavedAt!)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (savedAmount > 0 && !goalCompleted) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: daysSinceLastDeposit >= 21
                      ? Colors.red.withValues(alpha: 0.12)
                      : (daysSinceLastDeposit >= 14
                            ? Colors.orange.withValues(alpha: 0.12)
                            : AppColors.lightGreen),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: daysSinceLastDeposit >= 21
                        ? Colors.red.withValues(alpha: 0.4)
                        : (daysSinceLastDeposit >= 14
                              ? Colors.orange.withValues(alpha: 0.4)
                              : AppColors.green.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      daysSinceLastDeposit >= 14
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: daysSinceLastDeposit >= 21
                          ? Colors.red
                          : (daysSinceLastDeposit >= 14
                                ? Colors.orange.shade800
                                : AppColors.darkGreen),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        daysSinceLastDeposit >= 21
                            ? 'Lengo halijawekwa akiba kwa siku $daysSinceLastDeposit (wiki 3+). Tozo ya 6% inatozwa kwa kutoweka akiba.'
                            : (daysSinceLastDeposit >= 14
                                  ? 'Hujaweka akiba kwa siku $daysSinceLastDeposit. Zimebaki siku $daysUntilInactivityFee kabla ya tozo ya 6% ya kutoweka akiba.'
                                  : 'Siku $daysSinceLastDeposit tangu akiba ya mwisho. Weka akiba mara kwa mara kuepuka tozo ya 6% baada ya wiki 3.'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: daysSinceLastDeposit >= 21
                              ? Colors.red.shade900
                              : (daysSinceLastDeposit >= 14
                                    ? Colors.orange.shade900
                                    : AppColors.darkGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openAddMoneyPage,
                icon: const Icon(Icons.savings),
                label: const Text('WEKA AKIBA 💵'),
              ),
            ),
            if (savedAmount > 0 &&
                savedAmount < targetAmount &&
                !goalCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: goalPastDeadline
                      ? withdrawSavings
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Huwezi kutoa akiba kabla ya deadline. 🔒',
                            ),
                          ),
                        ),
                  icon: Icon(
                    goalPastDeadline ? Icons.payments_outlined : Icons.lock,
                  ),
                  label: Text(
                    goalPastDeadline ? 'TOA AKIBA 💸' : 'TOA AKIBA 🔒',
                  ),
                ),
              ),
            ],
            if (goalPastDeadline &&
                !goalCompleted &&
                savedAmount < targetAmount) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: extendGoalDeadline,
                  icon: const Icon(Icons.update),
                  label: const Text('ONGEZA MUDA 📅'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: increaseGoalTarget,
                  icon: const Icon(Icons.trending_up),
                  label: const Text('ONGEZA KIWANGO 💰'),
                ),
              ),
            ],
            if (goalPastDeadline &&
                !goalCompleted &&
                savedAmount >= targetAmount) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: completeGoal,
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('KAMILISHA LENGO ✅'),
                ),
              ),
            ],
            if (goalCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: AppColors.green),
                      SizedBox(width: 8),
                      Text(
                        'Hongera! Lengo limekamilika. 🎉',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('RUDI NYUMA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
