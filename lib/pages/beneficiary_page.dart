import 'package:flutter/material.dart';

import '../models/beneficiary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';

class BeneficiaryPage extends StatefulWidget {
  const BeneficiaryPage({super.key});

  @override
  State<BeneficiaryPage> createState() => _BeneficiaryPageState();
}

class _BeneficiaryPageState extends State<BeneficiaryPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nidaController = TextEditingController();
  final notesController = TextEditingController();

  String selectedRelationship = 'Mke / Mume';
  double allocationPercent = 100;
  bool isEditing = false;

  final relationships = [
    'Mke / Mume',
    'Mtoto',
    'Mzazi',
    'Ndugu',
    'Mlezi',
    'Rafiki',
    'Mwingine',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingBeneficiary();
  }

  void _loadExistingBeneficiary() {
    if (accountBeneficiary != null) {
      nameController.text = accountBeneficiary!.name;
      phoneController.text = accountBeneficiary!.phone;
      nidaController.text = accountBeneficiary!.nida;
      notesController.text = accountBeneficiary!.notes;
      selectedRelationship = relationships.contains(accountBeneficiary!.relationship)
          ? accountBeneficiary!.relationship
          : relationships.first;
      allocationPercent = accountBeneficiary!.allocationPercentage.toDouble();
      isEditing = false;
    } else {
      isEditing = true;
    }
  }

  Future<void> _saveBeneficiary() async {
    if (!formKey.currentState!.validate()) return;

    final beneficiary = Beneficiary(
      name: nameController.text.trim(),
      relationship: selectedRelationship,
      phone: phoneController.text.trim(),
      nida: nidaController.text.trim(),
      allocationPercentage: allocationPercent.round(),
      notes: notesController.text.trim(),
    );

    await saveBeneficiary(beneficiary);
    setState(() {
      isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taarifa za mrithi zimehifadhiwa kikamilifu! ✅'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _deleteBeneficiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FUTA MRITHI 🗑️'),
        content: const Text(
          'Je, una uhakika unataka kuondoa taarifa za mrithi huyu kwenye akaunti yako?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('GHAIRI'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ONDOA'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await removeBeneficiary();
      nameController.clear();
      phoneController.clear();
      nidaController.clear();
      notesController.clear();
      setState(() {
        isEditing = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Taarifa za mrithi zimefutwa.')),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    nidaController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRITHI WA AKAUNTI 👥'),
        actions: [
          if (accountBeneficiary != null && !isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Hariri',
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientCard(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.family_restroom, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ulinzi wa Akiba Yako',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kuweka mrithi (Next of Kin) kunasaidia kuhakikisha akiba yako inafikia familia yako kwa usalama endapo lolote litatokea.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (accountBeneficiary != null && !isEditing)
              _buildBeneficiaryCard()
            else
              _buildBeneficiaryForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiaryCard() {
    final b = accountBeneficiary!;
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.lightGreen,
                      child: const Icon(Icons.person, size: 32, color: AppColors.green),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              b.relationship,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                _infoRow(Icons.phone, 'Namba ya Simu', b.phone),
                if (b.nida.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.badge, 'Namba ya NIDA', b.nida),
                ],
                const SizedBox(height: 12),
                _infoRow(
                  Icons.pie_chart,
                  'Asilimia ya Akiba',
                  '${b.allocationPercentage}% ya Akiba',
                ),
                if (b.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _infoRow(Icons.description, 'Maelezo ya Ziada', b.notes),
                ],
                const SizedBox(height: 12),
                _infoRow(
                  Icons.calendar_today,
                  'Imesasishwa',
                  formatDateTime(b.updatedAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _deleteBeneficiary,
                icon: const Icon(Icons.delete_outline),
                label: const Text('ONDOA MRITHI'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => setState(() => isEditing = true),
                icon: const Icon(Icons.edit),
                label: const Text('BADILISHA'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.green),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildBeneficiaryForm() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('TAARIFA ZA MRITHI'),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Jina Kamili la Mrithi *',
              hintText: 'Mfano: Juma Shabani Hamisi',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Tafadhali weka jina kamili la mrithi.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedRelationship,
            decoration: const InputDecoration(
              labelText: 'Uhusiano wako na Mrithi *',
              prefixIcon: Icon(Icons.people),
              border: OutlineInputBorder(),
            ),
            items: relationships
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedRelationship = val);
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Namba ya Simu ya Mrithi *',
              hintText: 'Mfano: 0712345678',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Tafadhali weka namba ya simu ya mrithi.';
              }
              if (!RegExp(r'^0\d{9}$').hasMatch(val.trim())) {
                return 'Weka namba sahihi ya simu (k.m. 0712345678).';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: nidaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Namba ya NIDA (Si lazima)',
              hintText: 'Mfano: 19901234123450000123',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Asilimia ya Urithi wa Akiba:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${allocationPercent.round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              Slider(
                value: allocationPercent,
                min: 10,
                max: 100,
                divisions: 18,
                label: '${allocationPercent.round()}%',
                activeColor: AppColors.green,
                onChanged: (val) => setState(() => allocationPercent = val),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Maelezo ya Ziada (Si lazima)',
              hintText: 'Mfano: Makazi: Mbezi Beach, Dar es Salaam',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveBeneficiary,
              icon: const Icon(Icons.save),
              label: const Text('HIFADHI TAARIFA ZA MRITHI 💾'),
            ),
          ),
          if (accountBeneficiary != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(() => isEditing = false),
                child: const Text('GHAIRI MABADILIKO'),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
