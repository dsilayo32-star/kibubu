import 'package:flutter/material.dart';

import '../services/loan_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  final amountController = TextEditingController();
  final purposeController = TextEditingController();
  String selectedPurpose = 'Dharura ya Kibinafsi';
  int loanDurationDays = 30;

  final purposes = [
    'Dharura ya Kibinafsi',
    'Ada ya Shule au Chuo',
    'Kuongeza Mtaji wa Biashara',
    'Matibabu / Afya',
    'Kilimo na Ufugaji',
    'Mahitaji ya Nyumbani',
    'Nyinginezo',
  ];

  @override
  void dispose() {
    amountController.dispose();
    purposeController.dispose();
    super.dispose();
  }

  Future<void> _applyForLoan() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka kiasi halali cha mkopo.')),
      );
      return;
    }

    final purpose = purposeController.text.trim().isNotEmpty
        ? purposeController.text.trim()
        : selectedPurpose;

    final error = await applyForLoan(
      requestedAmount: amount,
      purpose: purpose,
      durationDays: loanDurationDays,
    );

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    amountController.clear();
    purposeController.clear();
    setState(() {});
    if (notificationsEnabled && activeLoan != null) {
      await NotificationService().scheduleLoanReminder(activeLoan!.dueDate);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hongera! Mkopo wako wa ${money(amount)} umeidhinishwa na akiba yako imetumika kama dhamana. ✅',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _showRepayDialog(LoanRecord loan) async {
    final repayController = TextEditingController(
      text: loan.remainingBalance.toStringAsFixed(0),
    );
    MobileNetwork selectedNetwork = MobileNetwork.mpesa;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('REJESHA MKOPO 💳'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deni lililobaki: ${money(loan.remainingBalance)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repayController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Kiasi cha Kulipa',
                      prefixText: 'TSh ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chagua Mtandao wa Malipo:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MobileNetwork>(
                    initialValue: selectedNetwork,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: MobileNetwork.values.map((net) {
                      return DropdownMenuItem(
                        value: net,
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: net.color, radius: 6),
                            const SizedBox(width: 8),
                            Text(net.title),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedNetwork = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('GHAIRI'),
              ),
              ElevatedButton(
                onPressed: () {
                  final payAmount = double.tryParse(repayController.text.trim());
                  if (payAmount == null || payAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Weka kiasi halali cha kurejesha.')),
                    );
                    return;
                  }
                  if (payAmount > loan.remainingBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kiasi kinazidi deni lililopo.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('LIPA SASA'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final payAmount = double.tryParse(repayController.text.trim()) ?? 0;
      final error = await repayLoan(loanId: loan.id, amount: payAmount);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.red),
        );
      } else {
        setState(() {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Malipo ya ${money(payAmount)} yamefanikiwa! Dhamana ya akiba imefunguliwa. 🎉',
            ),
            backgroundColor: AppColors.green,
          ),
        );
      }
    }
    repayController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSavings = totalSavingsAcrossAllGoals;
    final isEligible = LoanService.isEligibleForLoan(totalSavings);
    final maxLoan = LoanService.calculateMaxLoan(totalSavings);
    final currentActiveLoan = activeLoan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIKOPO YA KIBUBU 💰'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(totalSavings, isEligible, maxLoan),
            const SizedBox(height: 20),
            if (currentActiveLoan != null) ...[
              const SectionTitle('MKOPO WAKO WA SASA (ULIO HAI)'),
              const SizedBox(height: 10),
              _buildActiveLoanCard(currentActiveLoan),
              const SizedBox(height: 24),
            ] else if (isEligible) ...[
              const SectionTitle('OMBA MKOPO MPYA'),
              const SizedBox(height: 10),
              _buildLoanApplicationForm(maxLoan),
              const SizedBox(height: 24),
            ] else ...[
              _buildLockedInfoCard(totalSavings),
              const SizedBox(height: 24),
            ],
            const SectionTitle('KANUNI NA VIGEZO VYA MKOPO'),
            const SizedBox(height: 10),
            _buildTermsCard(),
            const SizedBox(height: 24),
            if (userLoans.isNotEmpty) ...[
              SectionTitle('HISTORIA YA MIKOPO (${userLoans.length})'),
              const SizedBox(height: 10),
              _buildLoansHistoryList(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(double totalSavings, bool isEligible, double maxLoan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEligible ? Icons.lock_open : Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEligible ? 'HUDUMA IMEFUNGULIWA' : 'HUDUMA IMEFUNGWA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Riba 10%',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Jumla ya Akiba Yako (Dhamana):',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            money(totalSavings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kiwango cha Juu cha Mkopo (20%):',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    money(maxLoan),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Akiba ya Kuanzia:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    money(LoanService.minSavingsRequired),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedInfoCard(double totalSavings) {
    final needed = LoanService.minSavingsRequired - totalSavings;
    final progress = (totalSavings / LoanService.minSavingsRequired).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 48, color: AppColors.gold),
            const SizedBox(height: 12),
            const Text(
              'Fungua Mkopo kwa Kufikisha TSh 50,000',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ili uweze kukopa, unahitaji kuwa na angalau TSh 50,000 kwenye akiba yako. Bado unahitaji kuweka ${money(needed)}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.lightGreen,
                valueColor: const AlwaysStoppedAnimation(AppColors.green),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Maendeleo: ${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLoanCard(LoanRecord loan) {
    final progress = loan.totalRepayable > 0
        ? (loan.amountPaid / loan.totalRepayable).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.id,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      loan.purpose,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: const Text(
                    'ULIO HAI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _loanStat('Kiasi Ulichokopa', money(loan.principal)),
                _loanStat('Riba (10%)', money(loan.interestAmount)),
                _loanStat('Jumla ya Deni', money(loan.totalRepayable)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Umelipa: ${money(loan.amountPaid)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Bado: ${money(loan.remainingBalance)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.green),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.alarm, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Mwisho wa Kulipa: ${formatDate(loan.dueDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showRepayDialog(loan),
                icon: const Icon(Icons.payment),
                label: const Text('REJESHA MKOPO (LIPA) 💸'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loanStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoanApplicationForm(double maxLoan) {
    final requested = double.tryParse(amountController.text.trim()) ?? 0;
    final interest = LoanService.calculateInterest(requested);
    final total = LoanService.calculateTotalRepayable(requested);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Kiasi Unachoomba',
                hintText: 'Hadi ${money(maxLoan)}',
                prefixText: 'TSh ',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _percentChip('25%', maxLoan * 0.25),
                _percentChip('50%', maxLoan * 0.50),
                _percentChip('75%', maxLoan * 0.75),
                _percentChip('100%', maxLoan),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedPurpose,
              decoration: const InputDecoration(
                labelText: 'Sababu ya Mkopo',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: purposes
                  .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedPurpose = val);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _summaryRow('Kiasi cha Mkopo:', money(requested)),
                  const SizedBox(height: 6),
                  _summaryRow('Riba (10%):', '+ ${money(interest)}'),
                  const Divider(height: 16),
                  _summaryRow('Jumla ya Kurejesha:', money(total), isBold: true),
                  const SizedBox(height: 6),
                  _summaryRow('Muda wa Mkopo:', '$loanDurationDays Siku'),
                  const SizedBox(height: 6),
                  _summaryRow('Dhamana:', 'Akiba yako (${money(requested)})'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: requested > 0 && requested <= maxLoan ? _applyForLoan : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('OMBA MKOPO SASA 🚀'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _percentChip(String label, double value) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.lightGreen,
      onPressed: () {
        amountController.text = value.round().toString();
        setState(() {});
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.darkGreen : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _TermItem('🎯 Akiba ya Kuanzia:', 'Lazima uwe na angalau TSh 50,000 kwenye akiba yako ili kufungua mikopo.'),
            SizedBox(height: 10),
            _TermItem('📊 Kiwango cha Mkopo:', 'Unaruhusiwa kukopa hadi 20% ya jumla ya akiba yako yote.'),
            SizedBox(height: 10),
            _TermItem('📈 Kiwango cha Riba:', 'Riba ya mkopo ni asilimia 10% ya kiasi ulichokopa.'),
            SizedBox(height: 10),
            _TermItem('🔒 Dhamana ya Akiba:', 'Akiba yako inatumika kama dhamana na inalindwa hadi mkopo ukamilike kurejeshwa.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansHistoryList() {
    return Column(
      children: userLoans.map((l) {
        final isRepaid = l.status == 'REPAID';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isRepaid ? AppColors.lightGreen : Colors.orange.withValues(alpha: 0.15),
              child: Icon(
                isRepaid ? Icons.check : Icons.hourglass_top,
                color: isRepaid ? AppColors.green : Colors.orange.shade800,
              ),
            ),
            title: Text('${l.purpose} • ${money(l.principal)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Tarehe: ${formatDate(l.borrowedDate)} | Riba: ${money(l.interestAmount)}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRepaid ? AppColors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isRepaid ? 'IMELIPWA' : 'INAREJESHWA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isRepaid ? AppColors.darkGreen : Colors.orange.shade900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TermItem extends StatelessWidget {
  const _TermItem(this.title, this.desc);
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
              children: [
                TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
