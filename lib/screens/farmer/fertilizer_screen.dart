import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'fertilizer_history_screen.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _acresController = TextEditingController();

  String _selectedCrop = 'Cotton';
  String _selectedSoilType = 'Black Cotton Soil';
  bool _isGenerated = false;

  List<FertRec> _recommendations = [];

  static const List<String> _crops = ['Cotton', 'Rice', 'Wheat', 'Tomato', 'Maize', 'Groundnut', 'Soybean', 'Beetroot'];
  static const List<String> _soilTypes = [
    'Black Cotton Soil',
    'Red Sandy Loam',
    'Alluvial Soil',
    'Laterite Soil',
    'Sandy Soil',
    'Clay Soil',
  ];

  @override
  void dispose() {
    _acresController.dispose();
    super.dispose();
  }

  void _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final double acres = double.tryParse(_acresController.text) ?? 1.0;
    final recs = _buildRecs(_selectedCrop, _selectedSoilType, acres);
    setState(() {
      _recommendations = recs;
      _isGenerated = true;
    });

    // Auto-save recommendation to Firestore
    try {
      final userId = await AuthService().getLoggedUserPhone() ?? 'anonymous';
      final Map<String, dynamic> recData = {
        'crop': _selectedCrop,
        'soilData': {
          'soilType': _selectedSoilType,
          'acreage': acres,
        },
        'recommendation': recs.map((e) => e.toJson()).toList(),
      };
      await FirestoreService().saveFertilizerRecommendation(userId, recData);
    } catch (e) {
      debugPrint('[FERTILIZER_SCREEN] Error auto-saving recommendation: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fertilizer recommendations generated & saved to history!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<FertRec> _buildRecs(String crop, String soil, double acres) {
    // Soil modifier factor
    double factor = 1.0;
    if (soil == 'Sandy Soil') factor = 1.25;
    if (soil == 'Clay Soil') factor = 0.85;
    if (soil == 'Laterite Soil') factor = 1.15;
    if (soil == 'Alluvial Soil') factor = 0.95;

    switch (crop) {
      case 'Cotton':
        return [
          FertRec('DAP (Di-Ammonium Phosphate)', 'N: 18% P: 46%', '${(50 * factor * acres).toStringAsFixed(1)} kg', 'Basal dose at sowing', Icons.science_rounded, AppTheme.primaryGreen),
          FertRec('Urea', 'N: 46%', '${(40 * factor * acres).toStringAsFixed(1)} kg', '30 days after sowing (vegetative stage)', Icons.eco_rounded, Colors.green),
          FertRec('Muriate of Potash (MOP)', 'K: 60%', '${(30 * factor * acres).toStringAsFixed(1)} kg', '60 days — boll development stage', Icons.star_rounded, AppTheme.accentGold),
          FertRec('Zinc Sulphate', 'Zn: 21%', '${(8 * acres).toStringAsFixed(1)} kg', 'Basal or first irrigation (prevents micronutrient deficiency)', Icons.bubble_chart_rounded, Colors.teal),
        ];
      case 'Rice':
        return [
          FertRec('DAP', 'N: 18% P: 46%', '${(40 * factor * acres).toStringAsFixed(1)} kg', 'Basal at transplanting', Icons.science_rounded, AppTheme.primaryGreen),
          FertRec('Urea (Split 1)', 'N: 46%', '${(30 * factor * acres).toStringAsFixed(1)} kg', '21 DAT — tillering stage', Icons.eco_rounded, Colors.green),
          FertRec('Urea (Split 2)', 'N: 46%', '${(25 * factor * acres).toStringAsFixed(1)} kg', '50 DAT — panicle initiation', Icons.eco_rounded, Colors.lightGreen),
          FertRec('Potash (MOP)', 'K: 60%', '${(20 * factor * acres).toStringAsFixed(1)} kg', 'Basal application', Icons.star_rounded, AppTheme.accentGold),
        ];
      case 'Tomato':
        return [
          FertRec('FYM (Farm Yard Manure)', 'Organic', '${(2000 * acres).toStringAsFixed(0)} kg', 'Apply 15 days before transplanting', Icons.compost_rounded, Colors.brown),
          FertRec('SSP (Single Super Phosphate)', 'P: 16% S: 11%', '${(35 * factor * acres).toStringAsFixed(1)} kg', 'Basal at transplanting', Icons.science_rounded, AppTheme.primaryGreen),
          FertRec('Urea', 'N: 46%', '${(25 * factor * acres).toStringAsFixed(1)} kg', '20 days after transplanting', Icons.eco_rounded, Colors.green),
          FertRec('Potassium Nitrate', 'N: 13% K: 44%', '${(15 * factor * acres).toStringAsFixed(1)} kg', 'Fruit setting stage — enhances fruit quality', Icons.star_rounded, Colors.orange),
        ];
      case 'Wheat':
        return [
          FertRec('DAP', 'N: 18% P: 46%', '${(45 * factor * acres).toStringAsFixed(1)} kg', 'Basal at sowing', Icons.science_rounded, AppTheme.primaryGreen),
          FertRec('Urea (Split 1)', 'N: 46%', '${(35 * factor * acres).toStringAsFixed(1)} kg', 'First irrigation (CRI stage)', Icons.eco_rounded, Colors.green),
          FertRec('Urea (Split 2)', 'N: 46%', '${(20 * factor * acres).toStringAsFixed(1)} kg', 'Jointing stage', Icons.eco_rounded, Colors.lightGreen),
          FertRec('Potash (MOP)', 'K: 60%', '${(20 * factor * acres).toStringAsFixed(1)} kg', 'Basal application', Icons.star_rounded, AppTheme.accentGold),
        ];
      case 'Maize':
        return [
          FertRec('DAP', 'N: 18% P: 46%', '${(50 * factor * acres).toStringAsFixed(1)} kg', 'Basal at sowing', Icons.science_rounded, AppTheme.primaryGreen),
          FertRec('Urea (Split 1)', 'N: 46%', '${(30 * factor * acres).toStringAsFixed(1)} kg', '25 DAS — knee-high stage', Icons.eco_rounded, Colors.green),
          FertRec('Urea (Split 2)', 'N: 46%', '${(25 * factor * acres).toStringAsFixed(1)} kg', '45 DAS — tasseling stage', Icons.eco_rounded, Colors.lightGreen),
          FertRec('MOP', 'K: 60%', '${(20 * factor * acres).toStringAsFixed(1)} kg', 'Basal application', Icons.star_rounded, AppTheme.accentGold),
        ];
      default:
        return [
          FertRec('DAP', 'N: 18% P: 46%', '${(40 * factor * acres).toStringAsFixed(1)} kg', 'Basal at sowing', Icons.science_rounded, AppTheme.primaryGreen),
          FertRec('Urea', 'N: 46%', '${(30 * factor * acres).toStringAsFixed(1)} kg', '25–30 days after sowing', Icons.eco_rounded, Colors.green),
          FertRec('MOP', 'K: 60%', '${(15 * factor * acres).toStringAsFixed(1)} kg', 'Basal application', Icons.star_rounded, AppTheme.accentGold),
          FertRec('Organic Compost', 'N-P-K balanced', '${(500 * acres).toStringAsFixed(0)} kg', 'Mix into soil before sowing', Icons.compost_rounded, Colors.brown),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Fertilizer Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Fertilizer History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FertilizerHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.science_rounded, color: AppTheme.primaryGreen, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Crop-Specific Fertilizer Advisor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          SizedBox(height: 4),
                          Text('Enter crop type, soil type, and acreage to get precise NPK recommendations with application timing.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formLabel('Crop Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCrop,
                        decoration: _dropDecor(Icons.grass_rounded),
                        items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() { _selectedCrop = v!; _isGenerated = false; }),
                      ),
                      const SizedBox(height: 16),

                      _formLabel('Soil Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSoilType,
                        decoration: _dropDecor(Icons.terrain_rounded),
                        items: _soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() { _selectedSoilType = v!; _isGenerated = false; }),
                      ),
                      const SizedBox(height: 16),

                      _formLabel('Farm Acreage'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _acresController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 4.0',
                          prefixIcon: const Icon(Icons.filter_hdr_rounded, color: AppTheme.primaryGreen),
                          filled: true, fillColor: AppTheme.backgroundLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter acreage';
                          if ((double.tryParse(v) ?? 0) <= 0) return 'Enter positive number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.calculate_rounded, color: Colors.white),
                          label: const Text('GENERATE RECOMMENDATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isGenerated) ...[
                const SizedBox(height: 28),
                const Text('RECOMMENDED FERTILIZER PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.4)),
                const SizedBox(height: 14),
                ...(_recommendations.map((rec) => _recCard(rec))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('Quantities adjusted for soil type. Consult local KVK for site-specific corrections.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54));

  InputDecoration _dropDecor(IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
    filled: true, fillColor: AppTheme.backgroundLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
  );

  Widget _recCard(FertRec rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rec.color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: rec.color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(rec.icon, color: rec.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(rec.npk, style: TextStyle(fontSize: 11, color: rec.color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: rec.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(rec.quantity, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rec.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(rec.timing, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FertRec {
  final String name, npk, quantity, timing;
  final IconData icon;
  final Color color;
  FertRec(this.name, this.npk, this.quantity, this.timing, this.icon, this.color);

  Map<String, dynamic> toJson() => {
    'name': name,
    'npk': npk,
    'quantity': quantity,
    'timing': timing,
    'iconCode': icon.codePoint,
    'colorValue': color.toARGB32(),
  };

  factory FertRec.fromJson(Map<String, dynamic> json) {
    return FertRec(
      json['name'] ?? '',
      json['npk'] ?? '',
      json['quantity'] ?? '',
      json['timing'] ?? '',
      Icons.eco_rounded,
      json['colorValue'] != null ? Color(json['colorValue']) : AppTheme.primaryGreen,
    );
  }
}
