import '../models/savings_entry.dart';

// Takwimu za akiba: michanganyiko ya historia kwa wiki/mwezi.
// Functions zote ni "pure" — hazibadilishi global state, hivyo rahisi kupima.

/// Historia ya sasa (map za 'amount', 'date', 'type').
typedef HistoryEntry = SavingsEntry;

/// Jumla ya deposits pamoja na withdrawals (netto) kwa kipindi.
double netSaved(List<HistoryEntry> history, DateTime from, DateTime to) {
  double total = 0;
  for (final entry in history) {
    final date = entry.date;
    if (date.isBefore(from) || date.isAfter(to)) continue;
    final amount = entry.amount;
    final type = entry.type;
    final isDeduction =
        type == 'withdraw' || type == 'withdrawal' || type == 'penalty';
    total += isDeduction ? -amount : amount;
  }
  return total;
}

/// Jumla ya deposits kwa kipindi (bila kutoa withdrawals/tozo).
double deposited(List<HistoryEntry> history, DateTime from, DateTime to) {
  double total = 0;
  for (final entry in history) {
    final date = entry.date;
    if (date.isBefore(from) || date.isAfter(to)) continue;
    final type = entry.type;
    if (type == 'deposit') {
      total += entry.amount;
    }
  }
  return total;
}

/// Jumla ya withdrawals na tozo kwa kipindi.
double withdrawn(List<HistoryEntry> history, DateTime from, DateTime to) {
  double total = 0;
  for (final entry in history) {
    final date = entry.date;
    if (date.isBefore(from) || date.isAfter(to)) continue;
    final type = entry.type;
    if (type == 'withdraw' || type == 'withdrawal' || type == 'penalty') {
      total += entry.amount;
    }
  }
  return total;
}

/// Kipindi cha wiki hii (Jumatatu hadi sasa).
DateTime weekStart(DateTime now) {
  final daysFromMonday = now.weekday - DateTime.monday;
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: daysFromMonday));
  return monday;
}

/// Kipindi cha mwezi huu (1 hadi sasa).
DateTime monthStart(DateTime now) => DateTime(now.year, now.month);

/// Muhtasari wa kipindi (jumla, deposits, withdrawals, siku zilizoweka).
class PeriodSummary {
  const PeriodSummary({
    required this.net,
    required this.deposits,
    required this.withdrawals,
    required this.daysSaved,
  });

  final double net;
  final double deposits;
  final double withdrawals;
  final int daysSaved;

  double get averagePerActiveDay => daysSaved == 0 ? 0 : deposits / daysSaved;
}

PeriodSummary summarize(
  List<HistoryEntry> history,
  DateTime from,
  DateTime to,
) {
  final depositsTotal = deposited(history, from, to);
  final withdrawalsTotal = withdrawn(history, from, to);
  final days = <String>{};
  for (final entry in history) {
    final date = entry.date;
    if (date.isBefore(from) || date.isAfter(to)) continue;
    final type = entry.type;
    if (type == 'deposit') {
      days.add('${date.year}-${date.month}-${date.day}');
    }
  }
  return PeriodSummary(
    net: depositsTotal - withdrawalsTotal,
    deposits: depositsTotal,
    withdrawals: withdrawalsTotal,
    daysSaved: days.length,
  );
}

/// Takwimu kwa siku (miadi 7 ya karibuni) kwa grafu ya weekly chart.
/// Inarudisha orodha ya (siku, jumla ya deposits).
List<({DateTime day, double total})> last7DaysTotals(
  List<HistoryEntry> history,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final result = <({DateTime day, double total})>[];
  for (var i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final next = day
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    result.add((day: day, total: deposited(history, day, next)));
  }
  return result;
}

/// Takwimu kwa miezi (miezi 6 ya karibuni) kwa grafu ya mwezi.
List<({DateTime month, double total})> last6MonthsTotals(
  List<HistoryEntry> history,
  DateTime now,
) {
  final result = <({DateTime month, double total})>[];
  for (var i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i);
    final next = DateTime(
      month.year,
      month.month + 1,
    ).subtract(const Duration(milliseconds: 1));
    result.add((month: month, total: deposited(history, month, next)));
  }
  return result;
}
