import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/payment_service.dart';
import '../state/app_state.dart';
import '../state/group_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common_widgets.dart';

/// Ukurasa Mkuu wa Vikundi vya Akiba (VICOBA / Chama).
class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  @override
  void initState() {
    super.initState();
    loadGroupsData().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    ).then((_) => setState(() {}));
  }

  Future<void> _openJoinGroup() async {
    final codeController = TextEditingController();
    final joined = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: AppColors.green),
            SizedBox(width: 8),
            Text('JIUNGE NA KIKUNDI 🔑', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingiza msimbo wa mwaliko uliotumiwa na kiongozi wa kikundi:'),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Msimbo wa Kikundi',
                hintText: 'Mfano: VICOBA-882',
                border: OutlineInputBorder(),
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
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              await joinGroupByCode(code);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
            },
            child: const Text('JIUNGE'),
          ),
        ],
      ),
    );

    codeController.dispose();
    if (joined == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Umefanikiwa kujiunga na kikundi! 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIKUNDI VYA AKIBA (VICOBA) 👥'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Jiunge kwa Msimbo',
            onPressed: _openJoinGroup,
          ),
        ],
      ),
      body: savingsGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups, size: 70, color: AppColors.green),
                  const SizedBox(height: 12),
                  const Text('Bado hujaunganishwa na kikundi.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openCreateGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('UNDA KIKUNDI KIPYA'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: savingsGroups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final group = savingsGroups[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
                      ).then((_) => setState(() {}));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.lightGreen,
                                child: const Icon(Icons.diversity_3, color: AppColors.green),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Msimbo: ${group.code} • ${group.members.length} Wanachama',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: group.progress,
                              minHeight: 8,
                              backgroundColor: AppColors.lightGreen,
                              valueColor: const AlwaysStoppedAnimation(AppColors.green),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jumla: ${money(group.totalSaved)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkGreen),
                              ),
                              Text(
                                '${(group.progress * 100).toStringAsFixed(0)}% ya ${money(group.totalTarget)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroup,
        icon: const Icon(Icons.add),
        label: const Text('UNDA KIKUNDI'),
      ),
    );
  }
}

/// Ukurasa wa Maelezo na Michango ya Kikundi.
class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.group});
  final SavingsGroup group;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  Future<void> _contribute() async {
    final amountCtrl = TextEditingController();
    MobileNetwork selectedNet = PaymentService.detectNetwork(phone);

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('WEKA MCHANGO WA KIKUNDI 💰'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kikundi: ${widget.group.name}'),
              const SizedBox(height: 12),
              const Text('Chagua mtandao wa malipo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MobileNetwork.values.map((net) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(net.title.split(' ')[0]),
                        selected: selectedNet == net,
                        selectedColor: net.color.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedNet = net);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Kiasi cha Mchango',
                  prefixText: 'TSh ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('GHAIRI'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: selectedNet.color, foregroundColor: Colors.white),
              onPressed: () {
                final val = double.tryParse(amountCtrl.text.trim());
                if (val == null || val <= 0) return;
                Navigator.pop(dialogCtx, val);
              },
              child: const Text('LIPA NA USSD'),
            ),
          ],
        ),
      ),
    );

    amountCtrl.dispose();
    if (amount != null) {
      await contributeToGroup(groupId: widget.group.id, amount: amount);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mchango wa ${money(amount)} umepokelewa kikamilifu! ✅')),
      );
    }
  }

  void _shareGroupCode() {
    Clipboard.setData(ClipboardData(text: widget.group.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Msimbo wa kikundi "${widget.group.code}" umenakiliwa! Tuma kwa wanakikundi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Shiriki Msimbo',
            onPressed: _shareGroupCode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.group.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: Text(widget.group.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.group.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    children: [
                      ProgressRing(progress: widget.group.progress, size: 70),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jumla Iliyokusanywa:', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                            Text(money(widget.group.totalSaved), style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Lengo la Kikundi: ${money(widget.group.totalTarget)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _contribute,
                    icon: const Icon(Icons.payments),
                    label: const Text('WEKA MCHANGO'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareGroupCode,
                    icon: const Icon(Icons.person_add),
                    label: const Text('ALIKA MTU'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionTitle('WANACHAMA (${widget.group.members.length}) 👥'),
            const SizedBox(height: 10),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.group.members.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, idx) {
                  final m = widget.group.members[idx];
                  final isLeader = m.role.contains('Mwenyekiti') ||
                      m.role.contains('Katibu') ||
                      m.role.contains('Mweka Hazina') ||
                      m.role.contains('Mwakilishi');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLeader ? AppColors.gold.withValues(alpha: 0.2) : AppColors.lightGreen,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLeader ? Colors.orange.shade900 : AppColors.green,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLeader ? AppColors.gold.withValues(alpha: 0.2) : AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLeader ? Colors.orange.shade900 : AppColors.darkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(m.phone.isNotEmpty ? m.phone : 'Bila namba'),
                    trailing: Text(
                      money(m.contributed),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('KANUNI NA MAKUBALIANO YA KIKUNDI 📜'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.group.rules,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// Ukurasa wa Kuunda Kikundi Kipya.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final targetCtrl = TextEditingController();

  // Viongozi Watatu (3 Leaders)
  final chairNameCtrl = TextEditingController();
  final chairPhoneCtrl = TextEditingController();
  final secNameCtrl = TextEditingController();
  final secPhoneCtrl = TextEditingController();
  final treasNameCtrl = TextEditingController();
  final treasPhoneCtrl = TextEditingController();

  // Wawakilishi Wawili (2 Representatives)
  final rep1NameCtrl = TextEditingController();
  final rep1PhoneCtrl = TextEditingController();
  final rep2NameCtrl = TextEditingController();
  final rep2PhoneCtrl = TextEditingController();

  final rulesCtrl = TextEditingController(
    text: '1. Michango itolewe kwa wakati kulingana na ratiba.\n'
        '2. Tozo ya kuchelewa ni TSh 2,000 kila wiki.\n'
        '3. Hakuna kutoa fedha kabla ya mzunguko kukamilika.',
  );
  String frequency = 'Kila Mwezi';

  @override
  void initState() {
    super.initState();
    chairNameCtrl.text = fullName;
    chairPhoneCtrl.text = phone;
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    final target = double.tryParse(targetCtrl.text.trim());
    if (name.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali jaza jina la kikundi na kiasi cha mchango kwa mwanachama.')),
      );
      return;
    }

    await createNewGroup(
      name: name,
      description: descCtrl.text.trim(),
      targetPerMember: target,
      contributionFrequency: frequency,
      rules: rulesCtrl.text.trim(),
      chairpersonName: chairNameCtrl.text.trim(),
      chairpersonPhone: chairPhoneCtrl.text.trim(),
      secretaryName: secNameCtrl.text.trim(),
      secretaryPhone: secPhoneCtrl.text.trim(),
      treasurerName: treasNameCtrl.text.trim(),
      treasurerPhone: treasPhoneCtrl.text.trim(),
      rep1Name: rep1NameCtrl.text.trim(),
      rep1Phone: rep1PhoneCtrl.text.trim(),
      rep2Name: rep2NameCtrl.text.trim(),
      rep2Phone: rep2PhoneCtrl.text.trim(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    targetCtrl.dispose();
    chairNameCtrl.dispose();
    chairPhoneCtrl.dispose();
    secNameCtrl.dispose();
    secPhoneCtrl.dispose();
    treasNameCtrl.dispose();
    treasPhoneCtrl.dispose();
    rep1NameCtrl.dispose();
    rep1PhoneCtrl.dispose();
    rep2NameCtrl.dispose();
    rep2PhoneCtrl.dispose();
    rulesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UNDA KIKUNDI CHA AKIBA 👥')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('1. TAARIFA ZA MSINGI ZA KIKUNDI 🏛️'),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Jina la Kikundi', hintText: 'Mfano: Vicoba ya Umoja', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Maelezo ya Kikundi', hintText: 'Mfano: Kikundi cha akiba ya biashara', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Lengo la Mchango kwa Kila Mwanachama', prefixText: 'TSh ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: frequency,
              decoration: const InputDecoration(labelText: 'Ratiba ya Michango', border: OutlineInputBorder()),
              items: ['Kila Wiki', 'Kila Mwezi']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => frequency = val);
              },
            ),
            const SizedBox(height: 24),
            const SectionTitle('2. VIONGOZI WATATU WA KIKUNDI (3 LEADERS) 👔'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👑 1. Mwenyekiti (Kiongozi Mkuu):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: chairNameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Mwenyekiti', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: chairPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Namba ya Simu ya Mwenyekiti', border: OutlineInputBorder()),
                    ),
                    const Divider(height: 24),
                    const Text('✍️ 2. Katibu wa Kikundi:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: secNameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Katibu', hintText: 'Mfano: Juma Rashid', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: secPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Namba ya Simu ya Katibu', hintText: '0754...', border: OutlineInputBorder()),
                    ),
                    const Divider(height: 24),
                    const Text('💰 3. Mweka Hazina:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: treasNameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Mweka Hazina', hintText: 'Mfano: Mariam Said', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: treasPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Namba ya Simu ya Mweka Hazina', hintText: '0712...', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('3. WAWAKILISHI WAWILI (2 REPRESENTATIVES) 🛡️'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛡️ 1. Mwakilishi wa Kwanza:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rep1NameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Mwakilishi wa 1', hintText: 'Mfano: Asha Salum', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rep1PhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Namba ya Simu ya Mwakilishi wa 1', hintText: '0688...', border: OutlineInputBorder()),
                    ),
                    const Divider(height: 24),
                    const Text('🛡️ 2. Mwakilishi wa Pili:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rep2NameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Mwakilishi wa 2', hintText: 'Mfano: Daudi Emanuel', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rep2PhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Namba ya Simu ya Mwakilishi wa 2', hintText: '0622...', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('4. KANUNI ZA KIKUNDI 📜'),
            const SizedBox(height: 12),
            TextField(
              controller: rulesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Kanuni na Makubaliano ya Kikundi', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle),
                label: const Text('UNDA KIKUNDI SASA 🎯'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
