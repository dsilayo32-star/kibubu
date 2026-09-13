import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/helpers.dart';

/// Mtandao wa simu wa malipo.
enum MobileNetwork {
  mpesa('M-Pesa (Vodacom)', Color(0xFFE60000), '074, 075, 076'),
  tigoPesa('Tigo Pesa', Color(0xFF00377B), '065, 067, 071'),
  airtelMoney('Airtel Money', Color(0xFFED1C24), '068, 069, 078'),
  haloPesa('HaloPesa (Halotel)', Color(0xFFFF6600), '061, 062');

  const MobileNetwork(this.title, this.color, this.prefixes);
  final String title;
  final Color color;
  final String prefixes;
}

/// Rekodi ya Stakabadhi ya Muamala.
class PaymentTransaction {
  PaymentTransaction({
    required this.reference,
    required this.phone,
    required this.network,
    required this.amount,
    required this.fee,
    required this.date,
    required this.status,
    required this.type,
    this.goalName = '',
  });

  final String reference;
  final String phone;
  final MobileNetwork network;
  final double amount;
  final double fee;
  final DateTime date;
  final String status; // 'SUCCESS', 'FAILED', 'PENDING'
  final String type; // 'DEPOSIT' au 'WITHDRAWAL'
  final String goalName;

  double get total => amount + fee;

  Map<String, dynamic> toMap() => {
    'reference': reference,
    'phone': phone,
    'network': network.name,
    'amount': amount,
    'fee': fee,
    'date': date.toIso8601String(),
    'status': status,
    'type': type,
    'goalName': goalName,
  };

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    final networkName = map['network'] as String?;
    final network = MobileNetwork.values.firstWhere(
      (item) => item.name == networkName,
      orElse: () => MobileNetwork.mpesa,
    );
    return PaymentTransaction(
      reference: map['reference'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      network: network,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      fee: (map['fee'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      status: map['status'] as String? ?? 'PENDING',
      type: map['type'] as String? ?? 'DEPOSIT',
      goalName: map['goalName'] as String? ?? '',
    );
  }
}

/// Huduma ya Malipo ya Mtandao wa Simu (Mobile Money Gateway).
class PaymentService {
  static const String _configuredUrl =
      String.fromEnvironment('MPESA_API_BASE_URL');

  static String activeBaseUrl = _configuredUrl.isNotEmpty
      ? _configuredUrl
      : 'https://kibubu-backend.onrender.com';

  static String _safeAccountReference(String goalName) {
    final normalized = (goalName.isEmpty ? 'KIBUBU' : goalName).replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    final end = normalized.length > 40 ? 40 : normalized.length;
    return normalized.substring(0, end);
  }

  /// Tambua mtandao kulingana na nambari ya simu.
  static MobileNetwork detectNetwork(String rawPhone) {
    final clean = rawPhone.replaceAll(RegExp(r'\s+|-'), '');
    String prefix = '';
    if (clean.startsWith('+255') && clean.length >= 6) {
      prefix = '0${clean.substring(4, 6)}';
    } else if (clean.startsWith('255') && clean.length >= 5) {
      prefix = '0${clean.substring(3, 5)}';
    } else if (clean.startsWith('0') && clean.length >= 3) {
      prefix = clean.substring(0, 3);
    }

    if (['074', '075', '076'].contains(prefix)) {
      return MobileNetwork.mpesa;
    }
    if (['065', '067', '071'].contains(prefix)) {
      return MobileNetwork.tigoPesa;
    }
    if (['068', '069', '078'].contains(prefix)) {
      return MobileNetwork.airtelMoney;
    }
    if (['061', '062'].contains(prefix)) {
      return MobileNetwork.haloPesa;
    }

    return MobileNetwork.mpesa; // Default
  }

  static bool isSupportedPhone(String rawPhone) {
    final clean = rawPhone.replaceAll(RegExp(r'\s+|-'), '');
    // Namba za Tanzania pekee: 0XXXXXXXXX / 255XXXXXXXXX / +255XXXXXXXXX.
    return RegExp(r'^(0\d{9}|255\d{9}|\+255\d{9})$').hasMatch(clean);
  }

  /// Hesabu tozo ya mtandao kwa kiasi.
  static double calculateFee(double amount) {
    if (amount <= 5000) {
      return 0;
    }
    if (amount <= 50000) {
      return 150;
    }
    if (amount <= 200000) {
      return 350;
    }
    return 500;
  }

  /// Tengeneza nambari ya kumbukumbu ya muamala.
  static String generateReference() {
    final rnd = Random();
    final num = 100000 + rnd.nextInt(900000);
    return 'KB-${DateTime.now().year}-$num';
  }

  /// Mchakato wa USSD Push na uthibitishaji wa malipo.
  static Future<PaymentTransaction> processPayment({
    required String phone,
    required MobileNetwork network,
    required double amount,
    required String type, // 'DEPOSIT' au 'WITHDRAWAL'
    String goalName = '',
  }) async {
    if (!isSupportedPhone(phone)) {
      throw const PaymentException('Namba ya simu si sahihi.');
    }
    if (amount <= 0 || !amount.isFinite) {
      throw const PaymentException('Kiasi cha malipo si sahihi.');
    }
    if (type != 'DEPOSIT' && type != 'WITHDRAWAL') {
      throw const PaymentException('Aina ya muamala si sahihi.');
    }
    final fee = calculateFee(amount);

    if (activeBaseUrl.isNotEmpty) {
      String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '255${cleanPhone.substring(1)}';
      }

      try {
        final response = await http
            .post(
              Uri.parse('$activeBaseUrl/api/v1/stkpush'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'phoneNumber': cleanPhone,
                'amount': amount.round(),
                'accountReference': _safeAccountReference(goalName),
              }),
            )
            .timeout(const Duration(seconds: 60));

        // 1. Angalia kama Server imerudisha Majibu Sahihi (200 OK / 201 Created)
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return PaymentTransaction(
            reference:
                data['CheckoutRequestID'] as String? ?? generateReference(),
            phone: phone,
            network: network,
            amount: amount,
            fee: fee,
            date: DateTime.now(),
            status: 'PENDING',
            type: type,
            goalName: goalName,
          );
        } else {
          // Majibu yasiyo ya 200 (kama 502, 503, 400, 404)
          String errorMsg =
              'Server error (${response.statusCode}): Server haipatikani kwa sasa.';
          try {
            final errData = jsonDecode(response.body);
            if (errData is Map && errData['error'] != null) {
              errorMsg = errData['error'].toString();
            }
          } catch (_) {}
          throw PaymentException(errorMsg);
        }
      } on PaymentException {
        rethrow;
      } on FormatException {
        // 2. Inakamata HTML error pages kutoka Render badala ya ku-crash
        throw const PaymentException(
          'Majibu kutoka kwenye server siyo JSON halali. Server inawezekana iko chini.',
        );
      } on TimeoutException {
        throw const PaymentException(
          'Muda wa mawasiliano na server umepita (Timeout). Tafadhali jaribu tena.',
        );
      } catch (e) {
        throw PaymentException('Imefeli kuunganisha: $e');
      }
    }

    // Local fallback: backend ya payment provider ikikosekana, app inaendelea
    // kuonyesha PENDING bila kuongeza salio bila uthibitisho.
    await Future.delayed(const Duration(milliseconds: 1200));

    final ref = generateReference();

    return PaymentTransaction(
      reference: ref,
      phone: phone,
      network: network,
      amount: amount,
      fee: fee,
      date: DateTime.now(),
      status: 'PENDING',
      type: type,
      goalName: goalName,
    );
  }

  /// Onyesha stakabadhi (Receipt Dialog) baada ya malipo kukamilika.
  static Future<void> showReceiptDialog(
    BuildContext context,
    PaymentTransaction tx,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.green,
                size: 44,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'STAKABADHI YA MALIPO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF6F8F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFDCE5E0),
                  ),
                ),
                child: Column(
                  children: [
                    _receiptRow('Kumbukumbu:', tx.reference, isBold: true),
                    const Divider(height: 16),
                    _receiptRow(
                      'Aina:',
                      tx.type == 'DEPOSIT' ? 'Weka Akiba 💵' : 'Toa Akiba 💸',
                    ),
                    const Divider(height: 16),
                    _receiptRow('Mtandao:', tx.network.title),
                    const Divider(height: 16),
                    _receiptRow('Nambari:', tx.phone),
                    if (tx.goalName.isNotEmpty) ...[
                      const Divider(height: 16),
                      _receiptRow('Lengo:', tx.goalName),
                    ],
                    const Divider(height: 16),
                    _receiptRow(
                      'Kiasi:',
                      money(tx.amount),
                      color: AppColors.green,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _receiptRow('Tozo ya Mtandao:', money(tx.fee)),
                    const Divider(height: 16),
                    _receiptRow('Tarehe:', formatDateTime(tx.date)),
                    const Divider(height: 16),
                    _receiptRow(
                      'Hali:',
                      'IMETHIBITISHWA ✅',
                      color: AppColors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('SAWA / FUNGA'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;
}
