import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../state/app_state.dart';

/// Huendesha session ya mtumiaji na lock baada ya muda wa kutotumia.
class SessionService {
  static const sessionTimeout = Duration(minutes: 15);
  static DateTime? _lastActivity;

  static bool get isActive =>
      _lastActivity != null && DateTime.now().difference(_lastActivity!) < sessionTimeout;

  static void start() => _lastActivity = DateTime.now();

  static void touch() {
    if (_lastActivity != null) _lastActivity = DateTime.now();
  }

  static void clear() => _lastActivity = null;

  static Future<bool> unlock(BuildContext context) async {
    if (biometricsEnabled && await BiometricService.isAvailable()) {
      if (await BiometricService.authenticate()) {
        start();
        return true;
      }
    }

    if (!context.mounted) return false;
    final controller = TextEditingController();
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('FUNGUA KIBUBU'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'PIN / Namba ya siri',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final ok = verifyPin(controller.text.trim());
              Navigator.pop(dialogContext, ok);
            },
            child: const Text('FUNGUA'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (unlocked == true) start();
    return unlocked == true;
  }
}
