import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/beneficiary.dart';
import '../models/goal.dart';
import '../models/savings_entry.dart';
import 'loan_service.dart';
import 'payment_service.dart';
import '../state/app_state.dart';

/// Huduma ya Firebase: cloud backup ya akaunti na malengo.
///
/// App inafanya kazi hata bila Firebase kuwa configured — kila kitu
/// kimefungwa ndani ya try/catch na `isReady` inaonyesha hali.
class FirebaseService {
  static bool _isReady = false;
  static bool get isReady => _isReady;

  static User? get currentUser {
    if (!_isReady) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Hakikisha kuna mtumiaji (kama hajalogin, anaingia anonymously).
  static Future<User?> ensureAuthenticated() async {
    if (!_isReady) return null;
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        return FirebaseAuth.instance.currentUser;
      }
      final cred = await FirebaseAuth.instance.signInAnonymously();
      return cred.user;
    } catch (_) {
      return null;
    }
  }

  /// Anzisha Firebase. Hairudishi kosa — inarudisha bool tu.
  static Future<bool> init() async {
    if (_isReady) return true;
    try {
      await Firebase.initializeApp();
      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
    return _isReady;
  }

  /// Hamisha data yote ya mtumiaji kwenda Firestore (backup).
  Future<bool> syncToCloud() async {
    if (!isReady) return false;
    try {
      final user = await ensureAuthenticated();
      if (user == null) return false;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'phone': phone,
        'birthDate': birthDate,
        'region': region,
        'district': district,
        'village': village,
        'goals': goals.map((goal) => goal.toMap()).toList(),
        'activeGoalIndex': activeGoalIndex,
        'profileAvatar': profileAvatar,
        'notificationsEnabled': notificationsEnabled,
        'biometricsEnabled': biometricsEnabled,
        'darkMode': darkMode,
        'savingsHistory': savingsHistory.map((entry) => entry.toMap()).toList(),
        'accountBeneficiary': accountBeneficiary?.toMap(),
        'userLoans': userLoans.map((loan) => loan.toMap()).toList(),
        'paymentTransactions': paymentTransactions
            .map((transaction) => transaction.toMap())
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      // Kiwango cha chini: app ya local inaendelea kama kawaida.
      return false;
    }
  }

  /// Buruta data kutoka cloud (restore) — inarudisha true kama kulikuwa na data.
  Future<bool> restoreFromCloud() async {
    if (!isReady) return false;
    try {
      final user = await ensureAuthenticated();
      if (user == null) return false;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) return false;
      fullName = data['fullName'] as String? ?? fullName;
      phone = data['phone'] as String? ?? phone;
      birthDate = data['birthDate'] as String? ?? birthDate;
      region = data['region'] as String? ?? region;
      district = data['district'] as String? ?? district;
      village = data['village'] as String? ?? village;
      profileAvatar = data['profileAvatar'] as String? ?? profileAvatar;
      notificationsEnabled =
          data['notificationsEnabled'] as bool? ?? notificationsEnabled;
      biometricsEnabled =
          data['biometricsEnabled'] as bool? ?? biometricsEnabled;
      darkMode = data['darkMode'] as bool? ?? darkMode;
      themeModeNotifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
      final cloudHistory = data['savingsHistory'] as List<dynamic>?;
      if (cloudHistory != null) {
        savingsHistory = cloudHistory
            .map(
              (entry) =>
                  SavingsEntry.fromMap(Map<String, dynamic>.from(entry as Map)),
            )
            .toList();
      }
      final cloudBeneficiary =
          data['accountBeneficiary'] as Map<dynamic, dynamic>?;
      if (cloudBeneficiary != null) {
        accountBeneficiary = Beneficiary.fromMap(
          Map<String, dynamic>.from(cloudBeneficiary),
        );
      }
      final cloudLoans = data['userLoans'] as List<dynamic>?;
      if (cloudLoans != null) {
        userLoans = cloudLoans
            .map(
              (loan) =>
                  LoanRecord.fromMap(Map<String, dynamic>.from(loan as Map)),
            )
            .toList();
      }
      final cloudTransactions = data['paymentTransactions'] as List<dynamic>?;
      if (cloudTransactions != null) {
        paymentTransactions = cloudTransactions
            .map(
              (transaction) => PaymentTransaction.fromMap(
                Map<String, dynamic>.from(transaction as Map),
              ),
            )
            .toList();
      }
      final cloudGoals = data['goals'] as List<dynamic>?;
      if (cloudGoals != null && cloudGoals.isNotEmpty) {
        goals = cloudGoals
            .map((goal) => Goal.fromMap(Map<String, dynamic>.from(goal as Map)))
            .toList();
        activeGoalIndex = data['activeGoalIndex'] as int? ?? 0;
        if (activeGoalIndex >= 0 && activeGoalIndex < goals.length) {
          loadGoalRecord(goals[activeGoalIndex]);
        }
      }
      await saveAccountData();
      if (goals.isNotEmpty) {
        await saveGoalData();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileAvatar', profileAvatar);
      await prefs.setBool('notificationsEnabled', notificationsEnabled);
      await prefs.setBool('biometricsEnabled', biometricsEnabled);
      await prefs.setBool('darkMode', darkMode);
      await prefs.setStringList(
        'savingsHistory',
        savingsHistory.map((entry) => jsonEncode(entry.toMap())).toList(),
      );
      if (accountBeneficiary != null) {
        await prefs.setString(
          'accountBeneficiary',
          accountBeneficiary!.toJson(),
        );
      }
      await prefs.setStringList(
        'userLoans',
        userLoans.map((loan) => jsonEncode(loan.toMap())).toList(),
      );
      await prefs.setStringList(
        'paymentTransactions',
        paymentTransactions
            .map((transaction) => jsonEncode(transaction.toMap()))
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    if (!isReady) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
