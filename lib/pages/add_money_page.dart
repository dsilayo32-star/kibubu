import 'package:flutter/material.dart';

import '../models/savings_entry.dart';
import '../services/payment_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';

class AddMoneyPage extends StatefulWidget {
  const AddMoneyPage({super.key});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final moneyController = TextEditingController();
  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  late MobileNetwork selectedNetwork;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    phoneController.text = phone;
    selectedNetwork = PaymentService.detectNetwork(phone);
  }

  Future<void> addMoney() async {
    if (!formKey.currentState!.validate()) return;
    final amount = double.tryParse(moneyController.text.trim());
    if (amount == null) return;
    if (savedAmount + amount > targetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi kinazidi lengo lako.')),
      );
      return;
    }

    final targetPhone = phoneController.text.trim().isEmpty
        ? phone
        : phoneController.text.trim();

    // Thibitisha USSD Push prompt
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cell_tower, color: selectedNetwork.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedNetwork.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Je, unathibitisha kuweka akiba ya ${money(amount)} kupitia ${selectedNetwork.title}?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.sms, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Utapokea ujumbe wa USSD (PIN prompt) kwenye namba: $targetPhone',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedNetwork.color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('THIBITISHA MALIPO'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isProcessing = true);

    PaymentTransaction tx;
    try {
      tx = await PaymentService.processPayment(
        phone: targetPhone,
        network: selectedNetwork,
        amount: amount,
        type: 'DEPOSIT',
        goalName: goalName,
      );
    } on PaymentException catch (error) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Malipo hayakuanzishwa. Jaribu tena baadaye.'),
          ),
        );
      }
      return;
    }

    if (tx.status != 'SUCCESS') {
      paymentTransactions.insert(0, tx);
      await savePaymentTransactions();
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Malipo yako yako ${tx.status}. Salio litaongezwa baada ya uthibitisho.',
            ),
          ),
        );
      }
      return;
    }

    final savedAt = tx.date;
    setState(() {
      isProcessing = false;
      savedAmount += amount;
      savingsHistory.add(
        SavingsEntry(
          amount: amount,
          date: savedAt,
          type: 'deposit',
          reference: tx.reference,
          network: tx.network.title,
        ),
      );
      lastSavedAt = savedAt;
    });

    await saveSavingsData();

    if (!mounted) return;

    // Onyesha stakabadhi
    await PaymentService.showReceiptDialog(context, tx);

    if (!mounted) return;
    Navigator.pop(context, amount);
  }

  @override
  void dispose() {
    moneyController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WEKA AKIBA 💵')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LENGO LOTE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            money(targetAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'KILICHOBAKI',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            money(
                              (targetAmount - savedAmount).clamp(
                                0,
                                double.infinity,
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('CHAGUA MTANDAO WA MALIPO 📱'),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MobileNetwork.values.map((net) {
                    final isSelected = selectedNetwork == net;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(net.title),
                        selected: isSelected,
                        selectedColor: net.color.withValues(alpha: 0.2),
                        avatar: CircleAvatar(
                          backgroundColor: net.color,
                          radius: 6,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => selectedNetwork = net);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nambari ya Simu ya Malipo',
                  prefixIcon: Icon(
                    Icons.phone_android,
                    color: selectedNetwork.color,
                  ),
                  helperText: 'Mtandao: ${selectedNetwork.title}',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(
                    () => selectedNetwork = PaymentService.detectNetwork(val),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: moneyController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kiasi cha Akiba',
                  hintText: 'Mfano: 1000',
                  prefixText: 'TSh ',
                  prefixIcon: Icon(Icons.payments),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount < 1000) {
                    return 'Kiwango cha chini cha akiba ni TSh 1,000.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : addMoney,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_to_mobile),
                  label: Text(
                    isProcessing
                        ? 'INACHAKATA MALIPO...'
                        : 'LIPA NA ${selectedNetwork.title.toUpperCase()} 📲',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
