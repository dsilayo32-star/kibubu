import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../services/otp_service.dart';
import '../services/session_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_page.dart';

class GoalsPasswordPage extends StatefulWidget {
  const GoalsPasswordPage({super.key});

  @override
  State<GoalsPasswordPage> createState() => _GoalsPasswordPageState();
}

class _GoalsPasswordPageState extends State<GoalsPasswordPage> {
  final pinController = TextEditingController();
  bool obscure = true;

  void unlock() {
    if (verifyPin(pinController.text.trim())) {
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PIN ya malengo si sahihi.')));
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FUNGUA MALENGO 🔐')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientCard(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Weka PIN yako ili kuona malengo, mwenendo na kuweka hela.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: pinController,
              autofocus: true,
              obscureText: obscure,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => unlock(),
              decoration: InputDecoration(
                labelText: 'PIN / Neno la siri',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: obscure ? 'Onyesha PIN' : 'Ficha PIN',
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: unlock,
                icon: const Icon(Icons.lock_open),
                label: const Text('FUNGUA MALENGO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final controllers = List.generate(7, (_) => TextEditingController());
  final formKey = GlobalKey<FormState>();
  final labels = [
    'Jina kamili',
    'PIN / Namba ya siri',
    'Namba ya simu',
    'Tarehe ya kuzaliwa',
    'Mkoa',
    'Wilaya',
    'Kijiji / Mtaa',
  ];

  Future<void> saveAccount() async {
    if (!formKey.currentState!.validate()) return;
    if (fullName.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akaunti tayari ipo. Akaunti ya pili hairuhusiwi.'),
        ),
      );
      return;
    }
    fullName = controllers[0].text.trim();
    phone = controllers[2].text.trim();
    birthDate = controllers[3].text.trim();
    region = controllers[4].text.trim();
    district = controllers[5].text.trim();
    village = controllers[6].text.trim();
    await setPin(controllers[1].text.trim());
    await saveAccountData();
    SessionService.start();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  String? requiredValidator(String? value, int index) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Tafadhali jaza ${labels[index].toLowerCase()}.';
    if (index == 1 && !RegExp(r'^\d{4,}$').hasMatch(text)) {
      return 'PIN iwe na tarakimu 4 au zaidi.';
    }
    if (index == 2 && !RegExp(r'^0\d{9}$').hasMatch(text)) {
      return 'Weka namba sahihi, mfano 0712345678.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JISAJILI 👤')),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GradientCard(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Taarifa zote zinahifadhiwa kwenye simu yako.',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < labels.length; index++) ...[
                TextFormField(
                  controller: controllers[index],
                  obscureText: index == 1,
                  keyboardType: index == 1
                      ? TextInputType.number
                      : index == 2
                      ? TextInputType.phone
                      : TextInputType.text,
                  validator: (value) => requiredValidator(value, index),
                  decoration: InputDecoration(
                    labelText: labels[index],
                    hintText: index == 2 ? '0712345678' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: saveAccount,
                icon: const Icon(Icons.save),
                label: const Text('HIFADHI AKAUNTI 💾'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    if (phone.isNotEmpty) {
      phoneController.text = phone;
    }
  }

  void login() {
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hakuna akaunti iliyosajiliwa bado. Tafadhali jisajili kwanza.',
          ),
        ),
      );
      return;
    }
    final enteredPhone = phoneController.text.trim();
    if (enteredPhone == phone && verifyPin(pinController.text.trim())) {
      SessionService.start();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Namba ya simu au PIN si sahihi.')),
      );
    }
  }

  Future<void> loginWithBiometrics() async {
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hakuna account. Tafadhali jisajili kwanza.'),
        ),
      );
      return;
    }
    final ok = await BiometricService.authenticate();
    if (!mounted) return;
    if (ok) {
      SessionService.start();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uthibitisho wa biometrics umeshindikana.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INGIA 🔐')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientCard(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.lock_person, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Weka namba ya simu na PIN yako kuendelea.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (fullName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.green,
                      radius: 20,
                      child: Text(
                        profileAvatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Simu: ${phone.isNotEmpty ? phone : "Bila namba"}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.verified,
                      color: AppColors.green,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Namba ya simu',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: pinController,
              obscureText: obscure,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => login(),
              decoration: InputDecoration(
                labelText: 'PIN / Namba ya siri',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordOtpPage(),
                  ),
                ),
                icon: const Icon(Icons.lock_reset, size: 18),
                label: const Text('Umesahau PIN? Rejesha kwa SMS OTP'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: login,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('INGIA'),
            ),
            FutureBuilder<bool>(
              future: BiometricService.isAvailable(),
              builder: (context, snapshot) {
                if (snapshot.data != true || !biometricsEnabled) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: loginWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('INGIA KWA FINGERPRINT'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Ukurasa wa Kurejesha PIN iliyosahaulika kwa kutumia SMS OTP.
class ForgotPasswordOtpPage extends StatefulWidget {
  const ForgotPasswordOtpPage({super.key});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final newPinCtrl = TextEditingController();
  final confirmPinCtrl = TextEditingController();

  int currentStep = 1; // 1: Weka namba, 2: Weka OTP, 3: Weka PIN mpya
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    if (phone.isNotEmpty) phoneCtrl.text = phone;
  }

  Future<void> _sendOtp() async {
    final targetPhone = phoneCtrl.text.trim();
    if (targetPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka namba sahihi ya simu.')),
      );
      return;
    }

    setState(() => isSending = true);
    try {
      await OtpService.sendOtp(
        targetPhone,
        onCodeSent: () {
          if (mounted) setState(() => currentStep = 2);
        },
      );
    } on OtpException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS OTP haikupatikana. Jaribu tena baadaye.'),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => isSending = false);
  }

  Future<void> _verifyOtp() async {
    final inputOtp = otpCtrl.text.trim();

    if (await OtpService.verifyOtp(inputOtp)) {
      if (!mounted) return;
      setState(() => currentStep = 3);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nambari ya OTP si sahihi au imeisha muda.'),
        ),
      );
    }
  }

  Future<void> _resetPin() async {
    final newPin = newPinCtrl.text.trim();
    final confirmPin = confirmPinCtrl.text.trim();

    if (newPin.length < 4 || newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN mpya lazima iwe na tarakimu 4 na zilingane.'),
        ),
      );
      return;
    }

    await setPin(newPin);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN imesasishwa kikamilifu! Karibu ndani.'),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    otpCtrl.dispose();
    newPinCtrl.dispose();
    confirmPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REJESHA PIN 📲')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kurejesha Namba ya Siri',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStep == 1
                              ? 'Hatua 1: Ingiza namba yako ya simu kupokea OTP.'
                              : (currentStep == 2
                                    ? 'Hatua 2: Ingiza OTP ya tarakimu 6 uliyotumiwa.'
                                    : 'Hatua 3: Weka PIN yako mpya.'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (currentStep == 1) ...[
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Namba ya Simu',
                  hintText: '0712345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSending ? null : _sendOtp,
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('TUMA SMS YA OTP 📩'),
                ),
              ),
            ] else if (currentStep == 2) ...[
              Text(
                'Ujumbe wenye tarakimu 6 umetumwa kwa: ${phoneCtrl.text}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 8,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ingiza Nambari ya OTP',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _verifyOtp,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('THIBITISHA OTP ✅'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _sendOtp,
                  child: const Text('Hujapata ujumbe? Tuma Tena OTP'),
                ),
              ),
            ] else if (currentStep == 3) ...[
              TextField(
                controller: newPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN Mpya (Tarakimu 4)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Rudia PIN Mpya',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetPin,
                  icon: const Icon(Icons.save),
                  label: const Text('HIFADHI PIN MPYA 🔐'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
