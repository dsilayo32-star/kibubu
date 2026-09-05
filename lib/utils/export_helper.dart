import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/goal.dart';
import '../models/savings_entry.dart';
import '../theme/app_theme.dart';
import 'helpers.dart';

/// Huduma ya kutoa na kusafirisha ripoti (CSV au Muhtasari wa Maandishi).
class ExportHelper {
  /// Kusanya historia ya malengo yote na kupanga kwa tarehe (mpya juu).
  static List<SavingsEntry> collectAllEntries({
    required List<Goal> goalsList,
    required String currentGoalName,
    required List<SavingsEntry> currentHistory,
  }) {
    final entries = <SavingsEntry>[];

    void addEntries(String goalName, List<dynamic> history) {
      for (final raw in history) {
        if (raw is! Map) continue;
        entries.add(
          SavingsEntry.fromMap(Map<String, dynamic>.from(raw))
              .copyWith(goalName: goalName),
        );
      }
    }

    if (currentGoalName.isNotEmpty) {
      entries.addAll(
        currentHistory.map(
          (entry) => entry.copyWith(goalName: currentGoalName),
        ),
      );
    }
    for (final goal in goalsList) {
      final name = goal.name;
      if (name == currentGoalName) continue;
      addEntries(name, goal.history.map((entry) => entry.toMap()).toList());
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Tengeneza data ya CSV kutoka kwenye miamala yote.
  static String generateCsv(List<SavingsEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Tarehe,Lengo,Aina,Kiasi (TSh)');

    for (final entry in entries) {
      final goal = entry.goalName ?? 'Lengo';
      final type = entry.type == 'penalty'
          ? 'Tozo (6%)'
          : (entry.isWithdrawal ? 'Kutoa' : 'Kuweka');
      final amount = entry.amount;
      final dateStr = formatDateTime(entry.date);

      // Safisha jina la lengo endapo lina alama za mkato
      final cleanGoal = goal.contains(',') ? '"$goal"' : goal;
      buffer.writeln('$dateStr,$cleanGoal,$type,$amount');
    }

    return buffer.toString();
  }

  /// Tengeneza muhtasari wa maandishi unaosomeka vizuri.
  static String generateTextSummary({
    required String userName,
    required List<Goal> goalsList,
    required List<SavingsEntry> entries,
    required DateTime now,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=================================');
    buffer.writeln('📊 TAARIFA YA AKIBA - KIBUBU APP');
    buffer.writeln('=================================');
    buffer.writeln('👤 Mtumiaji: ${userName.isEmpty ? 'Mtumiaji' : userName}');
    buffer.writeln('📅 Tarehe ya Ripoti: ${formatDateTime(now)}');
    buffer.writeln('');

    buffer.writeln('🎯 MALENGO YAKO (${goalsList.length}):');
    if (goalsList.isEmpty) {
      buffer.writeln('  Hakuna malengo yaliyosajiliwa.');
    } else {
      for (var i = 0; i < goalsList.length; i++) {
        final g = goalsList[i];
        final name = g.name;
        final target = g.target;
        final saved = g.saved;
        final pct = target > 0
            ? (saved / target * 100).toStringAsFixed(0)
            : '0';
        final done = g.completed ? ' [Imekamilika ✅]' : '';
        buffer.writeln(
          '  ${i + 1}. $name: ${money(saved)} / ${money(target)} ($pct%)$done',
        );
      }
    }
    buffer.writeln('');

    final deposits = entries
        .where((e) => e.type == 'deposit')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final withdrawals = entries
        .where((e) => e.isWithdrawal)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final penalties = entries
        .where((e) => e.isPenalty)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final net = deposits - withdrawals - penalties;

    buffer.writeln('💰 MUHTASARI WA FEDHA:');
    buffer.writeln('  • Jumla ya Amana (Deposits): ${money(deposits)}');
    buffer.writeln(
      '  • Jumla ya Matumizi (Withdrawals): ${money(withdrawals)}',
    );
    if (penalties > 0) {
      buffer.writeln('  • Tozo za Kutoweka Akiba (6%): ${money(penalties)}');
    }
    buffer.writeln('  • Salio Halisi (Net Savings): ${money(net)}');
    buffer.writeln('  • Jumla ya Miamala: ${entries.length}');
    buffer.writeln('');
    buffer.writeln('✨ "Weka akiba leo, fika malengo yako kesho."');
    buffer.writeln('=================================');

    return buffer.toString();
  }

  /// Onyesha dialog ya kusafirisha / kunakili ripoti.
  static Future<void> showExportDialog(
    BuildContext context, {
    required String title,
    required String csvData,
    required String textSummary,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.share, color: AppColors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chagua mfumo wa ripoti unaotaka kuutumia au kunakili:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFDCE5E0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    textSummary,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: textSummary),
                        );
                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '📋 Muhtasari wa ripoti umenakiliwa!',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text(
                        'Nakili Muhtasari',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: csvData));
                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📑 Data ya CSV imenakiliwa!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.table_chart, size: 18),
                      label: const Text(
                        'Nakili CSV',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('FUNGA'),
          ),
        ],
      ),
    );
  }
}
