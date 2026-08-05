import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  static const List<Map<String, dynamic>> _schemes = [
    {
      'name': 'PM-KISAN',
      'fullName': 'Pradhan Mantri Kisan Samman Nidhi',
      'benefit': '₹6,000/year direct income support (3 equal installments of ₹2,000)',
      'eligibility': 'All land-holding farmers\' families with cultivable land',
      'howToApply': 'Visit nearest CSC center or apply at pmkisan.gov.in',
      'icon': Icons.currency_rupee_rounded,
      'color': Color(0xFF2E7D32),
      'status': 'ACTIVE',
    },
    {
      'name': 'PM Fasal Bima Yojana',
      'fullName': 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      'benefit': 'Crop insurance against natural calamities, pests & diseases at subsidized premium rates',
      'eligibility': 'All farmers growing notified crops in notified areas',
      'howToApply': 'Apply via bank, insurance company portal, or Common Service Centre',
      'icon': Icons.shield_rounded,
      'color': Colors.blueAccent,
      'status': 'ACTIVE',
    },
    {
      'name': 'Kisan Credit Card',
      'fullName': 'Kisan Credit Card (KCC)',
      'benefit': 'Short-term credit for agricultural needs at subsidized interest rate (4% p.a.)',
      'eligibility': 'Farmers, tenant farmers, share croppers and self-help groups',
      'howToApply': 'Apply at nearest bank branch or PM-KISAN portal',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFFF9A826),
      'status': 'ACTIVE',
    },
    {
      'name': 'Soil Health Card',
      'fullName': 'National Soil Health Card Scheme',
      'benefit': 'Free soil testing, printed report with NPK levels & fertilizer recommendations every 2 years',
      'eligibility': 'All farmers across India',
      'howToApply': 'Apply through nearest KVK, agriculture department office or soilhealth.dac.gov.in',
      'icon': Icons.science_rounded,
      'color': Colors.brown,
      'status': 'ACTIVE',
    },
    {
      'name': 'PM-KUSUM',
      'fullName': 'Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan',
      'benefit': '90% subsidy on solar pump installation. Sell surplus solar power to DISCOM.',
      'eligibility': 'Individual farmers with irrigated land',
      'howToApply': 'Apply through state nodal agency or state agriculture department',
      'icon': Icons.solar_power_rounded,
      'color': Colors.orange,
      'status': 'ACTIVE',
    },
    {
      'name': 'RKVY',
      'fullName': 'Rashtriya Krishi Vikas Yojana',
      'benefit': 'Funds for crop diversification, horticulture, livestock, fisheries & agri-infrastructure development',
      'eligibility': 'Implemented through state government\'s agriculture department',
      'howToApply': 'Contact District Agriculture Officer or state agriculture department',
      'icon': Icons.account_balance_rounded,
      'color': Colors.teal,
      'status': 'ACTIVE',
    },
    {
      'name': 'e-NAM',
      'fullName': 'National Agriculture Market (e-NAM)',
      'benefit': 'Sell crops online at pan-India APMC mandis. Better price discovery through transparent auction.',
      'eligibility': 'All farmers with Aadhaar card and bank account',
      'howToApply': 'Register at enam.gov.in or nearest e-NAM enabled mandi',
      'icon': Icons.storefront_rounded,
      'color': Colors.purple,
      'status': 'ACTIVE',
    },
    {
      'name': 'National Horticulture Mission',
      'fullName': 'Mission for Integrated Development of Horticulture (MIDH)',
      'benefit': 'Subsidies for horticulture development: 40%–50% cost on planting material, drip irrigation, poly-houses',
      'eligibility': 'Farmers growing fruits, vegetables, spices & flowers',
      'howToApply': 'Apply through state horticulture department',
      'icon': Icons.local_florist_rounded,
      'color': Colors.pinkAccent,
      'status': 'ACTIVE',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Schemes & Benefits', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Government Agricultural Schemes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('8 active schemes available for farmers', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ..._schemes.map((scheme) => _schemeCard(context, scheme)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _schemeCard(BuildContext context, Map<String, dynamic> scheme) {
    final color = scheme['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(scheme['icon'] as IconData, color: color, size: 22),
        ),
        title: Text(scheme['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(scheme['fullName'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(scheme['status'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        ),
        children: [
          _detailRow(Icons.star_rounded, 'Benefit', scheme['benefit'] as String, color),
          const SizedBox(height: 8),
          _detailRow(Icons.person_rounded, 'Eligibility', scheme['eligibility'] as String, Colors.blueAccent),
          const SizedBox(height: 8),
          _detailRow(Icons.assignment_rounded, 'How to Apply', scheme['howToApply'] as String, Colors.orange),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
