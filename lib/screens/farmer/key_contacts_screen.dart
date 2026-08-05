import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KeyContactsScreen extends StatelessWidget {
  const KeyContactsScreen({super.key});

  static const List<Map<String, dynamic>> _contacts = [
    {
      'category': 'Agricultural Extension',
      'items': [
        {'name': 'District Agriculture Officer', 'phone': '1800-180-1551', 'role': 'Crop advisory, scheme guidance, subsidy applications', 'icon': Icons.person_rounded, 'color': Color(0xFF2E7D32)},
        {'name': 'Krishi Vigyan Kendra (KVK)', 'phone': '1800-425-1556', 'role': 'On-farm trials, technology demonstrations, training programs', 'icon': Icons.science_rounded, 'color': Colors.teal},
        {'name': 'Block Agriculture Officer', 'phone': '1800-180-2117', 'role': 'Field-level crop problems, local scheme registration', 'icon': Icons.supervisor_account_rounded, 'color': Colors.blueAccent},
      ],
    },
    {
      'category': 'Market & Prices',
      'items': [
        {'name': 'APMC Market Committee', 'phone': '1800-103-3465', 'role': 'Local mandi rates, trade disputes, license queries', 'icon': Icons.storefront_rounded, 'color': Color(0xFFF9A826)},
        {'name': 'e-NAM Helpdesk', 'phone': '1800-270-0224', 'role': 'Online crop selling, APMC registration, payment issues', 'icon': Icons.computer_rounded, 'color': Colors.purple},
      ],
    },
    {
      'category': 'Emergency & Disaster',
      'items': [
        {'name': 'National Disaster Relief (NDRF)', 'phone': '011-24363260', 'role': 'Flood, cyclone, hailstorm crop damage relief', 'icon': Icons.emergency_rounded, 'color': Colors.redAccent},
        {'name': 'Crop Insurance Helpline (PMFBY)', 'phone': '1800-200-7710', 'role': 'Claim filing, survey coordination after crop damage', 'icon': Icons.shield_rounded, 'color': Colors.red},
      ],
    },
    {
      'category': 'Credit & Financial',
      'items': [
        {'name': 'NABARD Helpline', 'phone': '1800-22-0498', 'role': 'Agriculture loans, KCC, RIDF projects, SHG support', 'icon': Icons.account_balance_rounded, 'color': Colors.indigo},
        {'name': 'PM-KISAN Helpline', 'phone': '155261', 'role': 'PM-KISAN payment status, beneficiary registration', 'icon': Icons.currency_rupee_rounded, 'color': Color(0xFF2E7D32)},
      ],
    },
    {
      'category': 'Soil & Water',
      'items': [
        {'name': 'Soil Health Card Helpline', 'phone': '1800-180-4500', 'role': 'Soil testing services, recommendations, card status', 'icon': Icons.landscape_rounded, 'color': Colors.brown},
        {'name': 'State Irrigation Dept.', 'phone': '1916', 'role': 'Canal water release schedule, irrigation complaints', 'icon': Icons.water_rounded, 'color': Colors.blue},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Key Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Helpline highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kisan Call Centre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('1800-180-1551  •  Free Helpline  •  Mon–Sat 6AM–10PM', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        SizedBox(height: 3),
                        Text('Agricultural advice in your language from expert agronomists.', style: TextStyle(fontSize: 11, color: Colors.white60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ..._contacts.map((category) => _categorySection(category)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(Map<String, dynamic> category) {
    final items = category['items'] as List<Map<String, dynamic>>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(category['category'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.2)),
        ),
        ...items.map((c) => _contactCard(c)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _contactCard(Map<String, dynamic> c) {
    final color = c['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(c['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 3),
                Text(c['role'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.call_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(c['phone'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
