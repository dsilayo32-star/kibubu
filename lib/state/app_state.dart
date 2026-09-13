import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/beneficiary.dart';
import '../models/goal.dart';
import '../models/loan_repayment.dart';
import '../models/savings_entry.dart';
import '../services/firebase_service.dart';
import '../services/loan_service.dart';
import '../services/payment_service.dart';
import '../services/security_service.dart';

/// === GLOBAL STATE (logiki ileile iliyokuwa main.dart, imepangwa hapa) ===

String fullName = '';
String profileAvatar = '👤'; // Icon emoji au kitambulisho cha picha
bool notificationsEnabled = false;
bool biometricsEnabled = false;
bool darkMode = false;
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);
String _pinSalt = '';
String _pinHash = '';
String phone = '';
String birthDate = '';
String region = '';
String district = '';
String village = '';
String goalName = '';
String goalImage = '🎯'; // Icon emoji au picha ya lengo
double targetAmount = 0;
double savedAmount = 0;
List<SavingsEntry> savingsHistory = [];
DateTime? startDate;
DateTime? endDate;
DateTime? lastSavedAt;
DateTime? lastPenaltyAt;
bool goalCompleted = false;
List<Goal> goals = [];
int activeGoalIndex = -1;

/// Mfumo wa Mrithi (Beneficiary / Next of Kin)
Beneficiary? accountBeneficiary;

/// Mfumo wa Mikopo yenye Dhamana ya Akiba
List<LoanRecord> userLoans = [];
List<PaymentTransaction> paymentTransactions = [];

/// Jumla ya akiba katika malengo yote
double get totalSavingsAcrossAllGoals {
  if (goals.isEmpty) return savedAmount;
  return goals.fold<double>(0.0, (sum, goal) => sum + goal.saved);
}

/// Angalia kama kuna mkopo ambao bado haujalipwa.
LoanRecord? get activeLoan {
  try {
    return userLoans.firstWhere(
      (l) => l.status == 'ACTIVE' || l.status == 'OVERDUE',
    );
  } catch (_) {
    return null;
  }
}

/// Kiasi cha dhamana kilichofungwa kwa ajili ya mkopo (Colllateral Lock)
double get lockedCollateralAmount {
  final current = activeLoan;
  if (current == null) return 0.0;
  // Mkopo unachukua 100% ya thamani ya mkopo au principal kama dhamana
  return current.remainingBalance;
}

/// Kanuni ya Tozo ya Kutoweka Akiba (Inactivity Fee):
/// Kuanzia wiki tatu (siku 21) bila kuweka akiba, akaunti/lengo hutozwa riba ya 6%.
const double inactivityFeeRate = 0.06; // 6%
const int inactivityDaysLimit = 21; // Wiki 3 = siku 21

Goal goalRecord() => Goal(
  name: goalName,
  target: targetAmount,
  saved: savedAmount,
  image: goalImage,
  start: startDate,
  end: endDate,
  lastSavedAt: lastSavedAt,
  lastPenaltyAt: lastPenaltyAt,
  completed: goalCompleted,
  history: List<SavingsEntry>.from(savingsHistory),
);

void loadGoalRecord(Goal goal) {
  goalName = goal.name;
  targetAmount = goal.target;
  savedAmount = goal.saved;
  goalImage = goal.image;
  startDate = goal.start;
  endDate = goal.end;
  lastSavedAt = goal.lastSavedAt;
  lastPenaltyAt = goal.lastPenaltyAt;
  goalCompleted = goal.completed;
  savingsHistory = List<SavingsEntry>.from(goal.history);
}

void syncActiveGoal() {
  if (activeGoalIndex >= 0 && activeGoalIndex < goals.length) {
    goals[activeGoalIndex] = goalRecord();
  }
}

bool get goalPastDeadline {
  if (endDate == null) return false;
  final deadline = DateTime(
    endDate!.year,
    endDate!.month,
    endDate!.day,
    23,
    59,
    59,
  );
  return !DateTime.now().isBefore(deadline);
}

bool get goalReachedTarget => targetAmount > 0 && savedAmount >= targetAmount;

double get progressValue =>
    targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

Future<void> loadData() async {
  final prefs = await SharedPreferences.getInstance();
  fullName = prefs.getString('fullName') ?? '';
  profileAvatar = prefs.getString('profileAvatar') ?? '👤';
  notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
  biometricsEnabled = prefs.getBool('biometricsEnabled') ?? false;
  darkMode = prefs.getBool('darkMode') ?? false;
  themeModeNotifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;

  // PIN: tunasoma salt + hash. Kama bado ipo kama maandishi wazi (toleo la
  // zamani), tunaihash mara moja na kufuta maandishi wazi.
  _pinSalt = prefs.getString('pinSalt') ?? '';
  _pinHash = prefs.getString('pinHash') ?? '';
  final legacyPin = prefs.getString('pin');
  if (legacyPin != null && legacyPin.isNotEmpty) {
    if (_pinHash.isEmpty) {
      _pinSalt = _pinSalt.isEmpty
          ? SecurityService.generateSalt()
          : _pinSalt;
      _pinHash = SecurityService.hashWith(_pinSalt, legacyPin);
      await _writePinCredentials(prefs);
    }
    await prefs.remove('pin');
  }
  SecurityService.load(_pinSalt);

  phone = prefs.getString('phone') ?? '';
  birthDate = prefs.getString('birthDate') ?? '';
  region = prefs.getString('region') ?? '';
  district = prefs.getString('district') ?? '';
  village = prefs.getString('village') ?? '';
  goalName = prefs.getString('goalName') ?? '';
  goalImage = prefs.getString('goalImage') ?? '🎯';
  targetAmount = prefs.getDouble('targetAmount') ?? 0;
  savedAmount = prefs.getDouble('savedAmount') ?? 0;
  startDate = parseDate(prefs.getString('startDate'));
  endDate = parseDate(prefs.getString('endDate'));
  lastSavedAt = parseDate(prefs.getString('lastSavedAt'));
  lastPenaltyAt = parseDate(prefs.getString('lastPenaltyAt'));
  goalCompleted = prefs.getBool('goalCompleted') ?? false;

  // Pakia taarifa za Mrithi
  final beneficiaryString = prefs.getString('accountBeneficiary');
  if (beneficiaryString != null && beneficiaryString.isNotEmpty) {
    try {
      accountBeneficiary = Beneficiary.fromJson(beneficiaryString);
    } catch (_) {
      accountBeneficiary = null;
    }
  } else {
    accountBeneficiary = null;
  }

  // Pakia taarifa za Mikopo
  final savedLoans = prefs.getStringList('userLoans') ?? [];
  userLoans = [];
  for (final l in savedLoans) {
    try {
      final decoded = jsonDecode(l) as Map<String, dynamic>;
      userLoans.add(LoanRecord.fromMap(decoded));
    } catch (_) {}
  }

  final savedTransactions = prefs.getStringList('paymentTransactions') ?? [];
  paymentTransactions = [];
  for (final transaction in savedTransactions) {
    try {
      paymentTransactions.add(
        PaymentTransaction.fromMap(
          jsonDecode(transaction) as Map<String, dynamic>,
        ),
      );
    } catch (_) {}
  }

  final history = prefs.getStringList('savingsHistory') ?? [];
  savingsHistory = [];
  for (final entry in history) {
    try {
      final decoded = jsonDecode(entry) as Map<String, dynamic>;
      final amount = decoded['amount'];
      final date = decoded['date'];
      if (amount is num && date is String) {
        savingsHistory.add(SavingsEntry.fromMap(decoded));
      }
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }

  final savedGoals = prefs.getStringList('goals') ?? [];
  goals = savedGoals
      .map((entry) => Goal.fromMap(jsonDecode(entry) as Map<String, dynamic>))
      .toList();
  if (goals.isEmpty && goalName.isNotEmpty) goals = [goalRecord()];
  if (goalName.isNotEmpty) {
    activeGoalIndex = goals.indexWhere((goal) => goal.name == goalName);
    if (activeGoalIndex < 0) activeGoalIndex = 0;
  }
}

/// Weka PIN mpya (inahifadhiwa kama hash pekee).
Future<void> setPin(String plainPin) async {
  if (_pinSalt.isEmpty) {
    _pinSalt = SecurityService.generateSalt();
  }
  _pinHash = SecurityService.hashWith(_pinSalt, plainPin);
  final prefs = await SharedPreferences.getInstance();
  await _writePinCredentials(prefs);
}

Future<void> _writePinCredentials(SharedPreferences prefs) async {
  await prefs.setString('pinSalt', _pinSalt);
  await prefs.setString('pinHash', _pinHash);
}

/// Thibitisha PIN iliyowekwa na mtumiaji.
bool verifyPin(String plainPin) =>
    _pinHash.isNotEmpty &&
    SecurityService.hashWith(_pinSalt, plainPin) == _pinHash;

bool get hasPin => _pinHash.isNotEmpty;

DateTime? parseDate(String? value) =>
    value == null ? null : DateTime.tryParse(value);

Future<void> saveAccountData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fullName', fullName);
  await prefs.setString('profileAvatar', profileAvatar);
  await prefs.setString('phone', phone);
  await prefs.setString('birthDate', birthDate);
  await prefs.setString('region', region);
  await prefs.setString('district', district);
  await prefs.setString('village', village);
}

/// Hifadhi taarifa za Mrithi
Future<void> saveBeneficiary(Beneficiary beneficiary) async {
  accountBeneficiary = beneficiary;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('accountBeneficiary', beneficiary.toJson());
}

/// Futa taarifa za Mrithi
Future<void> removeBeneficiary() async {
  accountBeneficiary = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('accountBeneficiary');
}

/// Hifadhi orodha ya Mikopo
Future<void> saveLoansData() async {
  final prefs = await SharedPreferences.getInstance();
  final encodedList = userLoans.map((l) => jsonEncode(l.toMap())).toList();
  await prefs.setStringList('userLoans', encodedList);
}

Future<void> refreshLoanStatuses() async {
  var changed = false;
  for (final loan in userLoans) {
    if (loan.status == 'ACTIVE' && loan.isOverdue) {
      loan.status = 'OVERDUE';
      changed = true;
    }
  }
  if (changed) await saveLoansData();
}

Future<void> savePaymentTransactions() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'paymentTransactions',
    paymentTransactions
        .map((transaction) => jsonEncode(transaction.toMap()))
        .toList(),
  );
  // ignore: discarded_futures
  FirebaseService().syncToCloud();
}

Future<bool> updatePaymentTransactionStatus(
  String reference,
  String status,
) async {
  const allowedStatuses = {'PENDING', 'SUCCESS', 'FAILED'};
  if (!allowedStatuses.contains(status)) return false;
  final index = paymentTransactions.indexWhere(
    (item) => item.reference == reference,
  );
  if (index == -1) return false;
  final transaction = paymentTransactions[index];
  paymentTransactions[index] = PaymentTransaction(
    reference: transaction.reference,
    phone: transaction.phone,
    network: transaction.network,
    amount: transaction.amount,
    fee: transaction.fee,
    date: transaction.date,
    status: status,
    type: transaction.type,
    goalName: transaction.goalName,
  );
  await savePaymentTransactions();
  return true;
}

/// Omba Mkopo mpya (Kibubu Savings Loan)
Future<String?> applyForLoan({
  required double requestedAmount,
  required String purpose,
  int durationDays = 30,
}) async {
  if (durationDays < 1 || durationDays > 365) {
    return 'Muda wa mkopo lazima uwe kati ya siku 1 na 365.';
  }
  final totalSavings = totalSavingsAcrossAllGoals;
  final validationError = LoanService.validateLoanRequest(
    requestedAmount: requestedAmount,
    totalSavings: totalSavings,
    hasActiveLoan: activeLoan != null,
  );
  if (validationError != null) return validationError;

  final interest = LoanService.calculateInterest(requestedAmount);
  final totalRepayable = LoanService.calculateTotalRepayable(requestedAmount);
  final now = DateTime.now();
  final loan = LoanRecord(
    id: LoanService.generateLoanId(),
    principal: requestedAmount,
    interestRate: LoanService.interestRate,
    interestAmount: interest,
    totalRepayable: totalRepayable,
    amountPaid: 0,
    borrowedDate: now,
    dueDate: now.add(Duration(days: durationDays)),
    status: 'ACTIVE',
    purpose: purpose,
  );

  userLoans.insert(0, loan);
  await saveLoansData();
  return null; // Hakuna kosa, imefanikiwa
}

/// Fanya Marejesho ya Mkopo (Loan Repayment)
Future<String?> repayLoan({
  required String loanId,
  required double amount,
}) async {
  final index = userLoans.indexWhere((l) => l.id == loanId);
  if (index == -1) return 'Mkopo haukupatikana.';
  final loan = userLoans[index];
  if (loan.status == 'REPAID') return 'Mkopo huu umeshakamilika kulipwa.';

  final remaining = loan.remainingBalance;
  if (amount <= 0) return 'Tafadhali weka kiasi halali cha kurejesha.';
  if (amount > remaining) {
    return 'Kiasi kinachozidi deni lililobaki (TSh ${remaining.toStringAsFixed(0)}).';
  }

  loan.amountPaid += amount;
  loan.repayments.add(LoanRepayment(amount: amount, date: DateTime.now()));

  if (loan.amountPaid >= loan.totalRepayable) {
    loan.status = 'REPAID';
  }

  userLoans[index] = loan;
  await saveLoansData();
  return null;
}

Future<void> saveGoalData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('goalName', goalName);
  await prefs.setDouble('targetAmount', targetAmount);
  await prefs.setDouble('savedAmount', savedAmount);
  await prefs.setBool('goalCompleted', goalCompleted);
  await _saveDates(prefs);
  await _saveSavingsHistory(prefs);
  syncActiveGoal();
  await _saveGoals(prefs);
  // Cloud backup (inafanya kazi tu kama Firebase imewekwa na mtumiaji ameingia).
  // ignore: discarded_futures
  FirebaseService().syncToCloud();
}

Future<void> saveSavingsData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('savedAmount', savedAmount);
  await prefs.setBool('goalCompleted', goalCompleted);
  await _saveDates(prefs);
  await _saveSavingsHistory(prefs);
  syncActiveGoal();
  await _saveGoals(prefs);
  // ignore: discarded_futures
  FirebaseService().syncToCloud();
}

Future<void> _saveGoals(SharedPreferences prefs) async {
  await prefs.setStringList(
    'goals',
    goals.map((goal) => jsonEncode(goal.toMap())).toList(),
  );
}

Future<void> _saveDates(SharedPreferences prefs) async {
  if (startDate != null) {
    await prefs.setString('startDate', startDate!.toIso8601String());
  } else {
    await prefs.remove('startDate');
  }
  if (endDate != null) {
    await prefs.setString('endDate', endDate!.toIso8601String());
  } else {
    await prefs.remove('endDate');
  }
  if (lastSavedAt != null) {
    await prefs.setString('lastSavedAt', lastSavedAt!.toIso8601String());
  } else {
    await prefs.remove('lastSavedAt');
  }
  if (lastPenaltyAt != null) {
    await prefs.setString('lastPenaltyAt', lastPenaltyAt!.toIso8601String());
  } else {
    await prefs.remove('lastPenaltyAt');
  }
}

Future<void> _saveSavingsHistory(SharedPreferences prefs) async {
  await prefs.setStringList(
    'savingsHistory',
    savingsHistory.map((saving) => jsonEncode(saving.toMap())).toList(),
  );
}

/// Futa lengo kwenye orodha ya malengo.
Future<void> deleteGoal(int index) async {
  if (index < 0 || index >= goals.length) return;
  goals.removeAt(index);
  if (goals.isEmpty) {
    goalName = '';
    targetAmount = 0;
    savedAmount = 0;
    startDate = null;
    endDate = null;
    lastSavedAt = null;
    goalCompleted = false;
    savingsHistory = [];
    activeGoalIndex = -1;
  } else {
    if (activeGoalIndex >= goals.length) {
      activeGoalIndex = goals.length - 1;
    } else if (activeGoalIndex == index) {
      activeGoalIndex = index.clamp(0, goals.length - 1);
    } else if (activeGoalIndex > index) {
      activeGoalIndex--;
    }
    loadGoalRecord(goals[activeGoalIndex]);
  }
  await saveGoalData();
}

/// Hariri taarifa za lengo lililopo.
Future<void> updateGoal({
  required int index,
  required String name,
  required double target,
  required DateTime start,
  required DateTime end,
  String? image,
}) async {
  if (index < 0 || index >= goals.length) return;
  final current = goals[index];
  goals[index] = Goal(
    name: name,
    target: target,
    saved: current.saved,
    image: image ?? current.image,
    start: start,
    end: end,
    lastSavedAt: current.lastSavedAt,
    lastPenaltyAt: current.lastPenaltyAt,
    completed: current.completed,
    history: current.history,
  );
  if (activeGoalIndex == index) {
    goalName = name;
    targetAmount = target;
    startDate = start;
    endDate = end;
  }
  await saveGoalData();
}

Duration get remainingDuration {
  if (endDate == null) return Duration.zero;
  final deadline = DateTime(
    endDate!.year,
    endDate!.month,
    endDate!.day,
    23,
    59,
    59,
  );
  final difference = deadline.difference(DateTime.now());
  return difference.isNegative ? Duration.zero : difference;
}

String countdownText() {
  final remaining = remainingDuration;
  final hours = remaining.inHours.remainder(24).toString().padLeft(2, '0');
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  return 'Siku ${remaining.inDays}  •  $hours:$minutes:$seconds';
}

/// Siku zilizopita tangu mara ya mwisho kuweka akiba (au kuanzisha lengo).
int get daysSinceLastDeposit {
  final reference = lastSavedAt ?? startDate;
  if (reference == null) return 0;
  final now = DateTime.now();
  final diff = now.difference(reference).inDays;
  return diff > 0 ? diff : 0;
}

/// Siku zilizobaki kabla ya kukatwa tozo ya 6% ya kutoweka akiba (wiki 3 = siku 21).
int get daysUntilInactivityFee {
  final remaining = inactivityDaysLimit - daysSinceLastDeposit;
  return remaining > 0 ? remaining : 0;
}

/// Je lengo linastahili kukatwa tozo ya 6% (wiki 3 zimepita bila kuweka akiba)?
bool get isInactivityFeeApplicable {
  if (savedAmount <= 0 || goalCompleted) return false;
  if (daysSinceLastDeposit < inactivityDaysLimit) return false;
  if (lastPenaltyAt != null) {
    final daysSincePenalty = DateTime.now().difference(lastPenaltyAt!).inDays;
    if (daysSincePenalty < inactivityDaysLimit) return false;
  }
  return true;
}

/// Kiasi cha tozo ya 6% ya akiba iliyopo.
double get inactivityFeeAmount => savedAmount * inactivityFeeRate;

/// Tekeleza tozo ya 6% kwenye lengo lililo hai kama limekosa akiba kwa wiki 3+.
Future<bool> applyInactivityFeeIfNeeded() async {
  if (!isInactivityFeeApplicable) return false;
  final fee = inactivityFeeAmount;
  if (fee <= 0) return false;

  final now = DateTime.now();
  savedAmount = (savedAmount - fee).clamp(0.0, double.infinity);
  lastPenaltyAt = now;
  savingsHistory.add(
    SavingsEntry(
      amount: fee,
      date: now,
      type: 'penalty',
      description: 'Tozo ya kutoweka akiba (wiki 3 - 6%)',
    ),
  );
  await saveSavingsData();
  return true;
}

/// Kagua malengo yote na tumia tozo ya 6% kwa malengo yote yasiyo na akiba kwa wiki 3+.
Future<int> checkAndApplyAllInactivityFees() async {
  int appliedCount = 0;
  final now = DateTime.now();

  for (var i = 0; i < goals.length; i++) {
    final goal = goals[i];
    final saved = goal.saved;
    final completed = goal.completed;
    if (saved <= 0 || completed) continue;

    final lastSaved = goal.lastSavedAt;
    final start = goal.start;
    final ref = lastSaved ?? start;
    if (ref == null) continue;

    final days = now.difference(ref).inDays;
    if (days < inactivityDaysLimit) continue;

    final lastPen = goal.lastPenaltyAt;
    if (lastPen != null &&
        now.difference(lastPen).inDays < inactivityDaysLimit) {
      continue;
    }

    final fee = saved * inactivityFeeRate;
    final newSaved = (saved - fee).clamp(0.0, double.infinity);
    goal.saved = newSaved;
    goal.lastPenaltyAt = now;
    goal.history.add(
      SavingsEntry(
        amount: fee,
        date: now,
        type: 'penalty',
        description: 'Tozo ya kutoweka akiba (wiki 3 - 6%)',
      ),
    );
    appliedCount++;
  }

  if (appliedCount > 0) {
    if (activeGoalIndex >= 0 && activeGoalIndex < goals.length) {
      loadGoalRecord(goals[activeGoalIndex]);
    }
    final prefs = await SharedPreferences.getInstance();
    await _saveGoals(prefs);
    await saveSavingsData();
  }
  return appliedCount;
}
