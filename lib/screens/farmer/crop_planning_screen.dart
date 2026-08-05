import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'crop_planning_history_screen.dart';

class CropPlanningScreen extends StatefulWidget {
  const CropPlanningScreen({super.key});

  @override
  State<CropPlanningScreen> createState() => _CropPlanningScreenState();
}

class _CropPlanningScreenState extends State<CropPlanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _acresController = TextEditingController();
  
  String _selectedCrop = 'Cotton';
  DateTime _sowingDate = DateTime.now();
  
  bool _isScheduleGenerated = false;

  // Schedules state structures
  List<PlanItem> _fertilizerSchedule = [];
  List<PlanItem> _pesticideSchedule = [];
  List<PlanItem> _inspectionReminders = [];
  String _harvestEstimateText = '';

  @override
  void dispose() {
    _acresController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _sowingDate) {
      setState(() {
        _sowingDate = picked;
        _isScheduleGenerated = false; // Reset output when inputs change
      });
    }
  }

  void _generateSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    final double acres = double.tryParse(_acresController.text) ?? 1.0;
    
    final fert = _buildFertilizerSchedule(_selectedCrop, _sowingDate, acres);
    final pest = _buildPesticideSchedule(_selectedCrop, _sowingDate);
    final insp = _buildInspectionReminders(_selectedCrop, _sowingDate);
    final harvest = _calculateHarvestEstimate(_selectedCrop, _sowingDate, acres);

    setState(() {
      _fertilizerSchedule = fert;
      _pesticideSchedule = pest;
      _inspectionReminders = insp;
      _harvestEstimateText = harvest;
      _isScheduleGenerated = true;
    });

    // Auto-save generated crop plan to Firestore
    try {
      final userId = await AuthService().getLoggedUserPhone() ?? 'anonymous';
      final Map<String, dynamic> planData = {
        'cropName': _selectedCrop,
        'acreage': acres,
        'plantingDate': _sowingDate.toIso8601String(),
        'generatedPlan': {
          'harvestEstimateText': harvest,
          'fertilizerSchedule': fert.map((e) => e.toJson()).toList(),
          'pesticideSchedule': pest.map((e) => e.toJson()).toList(),
          'inspectionReminders': insp.map((e) => e.toJson()).toList(),
        },
      };
      await FirestoreService().saveCropPlan(userId, planData);
    } catch (e) {
      debugPrint('[CROP_PLANNING] Error auto-saving plan: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dynamic Crop Calendar generated & saved to history!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<PlanItem> _buildFertilizerSchedule(String crop, DateTime sowingDate, double acres) {
    switch (crop) {
      case 'Cotton':
        return [
          PlanItem(
            date: sowingDate,
            title: 'Basal Application (Sowing)',
            description: 'Apply NPK 12:32:16 (${(50 * acres).toStringAsFixed(1)} kg) to provide essential primary nutrients.',
            icon: Icons.grass_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 30)),
            title: 'Top Dressing (Vegetative)',
            description: 'Apply Urea (${(45 * acres).toStringAsFixed(1)} kg) + Micronutrient spray to boost nitrogen assimilation.',
            icon: Icons.eco_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 60)),
            title: 'Boll Development (Flowering)',
            description: 'Apply Muriate of Potash (${(30 * acres).toStringAsFixed(1)} kg) to support fiber quality and weight.',
            icon: Icons.monetization_on_rounded,
          ),
        ];
      case 'Rice':
        return [
          PlanItem(
            date: sowingDate,
            title: 'Basal Dose (Transplanting)',
            description: 'Apply DAP (${(40 * acres).toStringAsFixed(1)} kg) + Zinc Sulphate (${(10 * acres).toStringAsFixed(1)} kg) for robust root development.',
            icon: Icons.layers_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 21)),
            title: 'Tillering Stage Dressing',
            description: 'Apply Urea (${(35 * acres).toStringAsFixed(1)} kg) to promote maximum panicle tillers.',
            icon: Icons.grain_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 50)),
            title: 'Panicle Initiation Dose',
            description: 'Apply Urea (${(25 * acres).toStringAsFixed(1)} kg) + Potash (${(20 * acres).toStringAsFixed(1)} kg) to sustain high grain formation.',
            icon: Icons.wb_sunny_rounded,
          ),
        ];
      default:
        // Fallback for general crops (Tomato, Beetroot, Wheat)
        return [
          PlanItem(
            date: sowingDate,
            title: 'Basal Application',
            description: 'Apply Organic compost / NPK mix (${(40 * acres).toStringAsFixed(1)} kg) into the soil bed.',
            icon: Icons.grass_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 25)),
            title: 'First Foliar Feed',
            description: 'Apply water soluble Nitrogen-rich spray (${(10 * acres).toStringAsFixed(1)} kg NPK 19-19-19) for leaf expansion.',
            icon: Icons.wb_cloudy_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 55)),
            title: 'Fruit / Seed Initiation Dressing',
            description: 'Apply Potassium nitrate / Sulphate of Potash (${(15 * acres).toStringAsFixed(1)} kg) to enlarge harvests.',
            icon: Icons.stars_rounded,
          ),
        ];
    }
  }

  List<PlanItem> _buildPesticideSchedule(String crop, DateTime sowingDate) {
    switch (crop) {
      case 'Cotton':
        return [
          PlanItem(
            date: sowingDate.add(const Duration(days: 15)),
            title: 'Prophylactic Sucking Pest Spray',
            description: 'Spray Neem Oil (5ml/L) or Imidacloprid to repel whiteflies, jassids, and aphids early on.',
            icon: Icons.bug_report_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 45)),
            title: 'Bollworm Management',
            description: 'Spray Bacillus thuringiensis (Bt) or Spinosad to protect early squares from Helicoverpa bollworms.',
            icon: Icons.shield_rounded,
          ),
        ];
      case 'Tomato':
        return [
          PlanItem(
            date: sowingDate.add(const Duration(days: 10)),
            title: 'Damping-Off & Early Blight Spray',
            description: 'Spray Trichoderma viride or Copper Oxychloride to prevent root rotting and early foliar fungal blights.',
            icon: Icons.coronavirus_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 35)),
            title: 'Fruit Borer Prophylactic',
            description: 'Apply Neem-based insect sprays or Pheromone traps to deter moth egg laying.',
            icon: Icons.lock_clock_rounded,
          ),
        ];
      default:
        return [
          PlanItem(
            date: sowingDate.add(const Duration(days: 20)),
            title: 'Early Broad-Spectrum Protection',
            description: 'Apply Organic Neem spray (1500 ppm) or systemic fungicide for general pathogen safety.',
            icon: Icons.bug_report_rounded,
          ),
          PlanItem(
            date: sowingDate.add(const Duration(days: 50)),
            title: 'Late Foliar Blight Shield',
            description: 'Spray Mancozeb or Organic bio-fungicides to ensure clean disease-free foliage.',
            icon: Icons.security_rounded,
          ),
        ];
    }
  }

  List<PlanItem> _buildInspectionReminders(String crop, DateTime sowingDate) {
    return [
      PlanItem(
        date: sowingDate.add(const Duration(days: 10)),
        title: 'Germination & Stand Audit',
        description: 'Verify seed emergence rate. Manually fill any gaps in rows to maximize crop canopy density.',
        icon: Icons.visibility_rounded,
      ),
      PlanItem(
        date: sowingDate.add(const Duration(days: 35)),
        title: 'Weed Suppression check',
        description: 'Check weed growth levels. Execute manual weeding or apply targeted organic mulches to stop nutrient drainage.',
        icon: Icons.cleaning_services_rounded,
      ),
      PlanItem(
        date: sowingDate.add(const Duration(days: 75)),
        title: 'Moisture Stress Audit',
        description: 'Check field corners for wilting. Verify soil moisture remains damp but never waterlogged during fruiting.',
        icon: Icons.water_drop_rounded,
      ),
    ];
  }

  String _calculateHarvestEstimate(String crop, DateTime sowingDate, double acres) {
    int durationDaysMin = 120;
    int durationDaysMax = 150;
    double yieldMinPerAcre = 6.0; // In Quintals
    double yieldMaxPerAcre = 10.0;
    String unit = 'Quintals';

    if (crop == 'Rice') {
      durationDaysMin = 115;
      durationDaysMax = 135;
      yieldMinPerAcre = 15.0;
      yieldMaxPerAcre = 22.0;
    } else if (crop == 'Wheat') {
      durationDaysMin = 110;
      durationDaysMax = 140;
      yieldMinPerAcre = 12.0;
      yieldMaxPerAcre = 18.0;
    } else if (crop == 'Tomato') {
      durationDaysMin = 85;
      durationDaysMax = 105;
      yieldMinPerAcre = 80.0;
      yieldMaxPerAcre = 120.0;
      unit = 'Kgs';
    } else if (crop == 'Beetroot') {
      durationDaysMin = 75;
      durationDaysMax = 95;
      yieldMinPerAcre = 60.0;
      yieldMaxPerAcre = 90.0;
      unit = 'Kgs';
    }

    final harvestMinDate = sowingDate.add(Duration(days: durationDaysMin));
    final harvestMaxDate = sowingDate.add(Duration(days: durationDaysMax));
    
    final double totalYieldMin = yieldMinPerAcre * acres;
    final double totalYieldMax = yieldMaxPerAcre * acres;

    final String dateString = '${_formatDate(harvestMinDate)} to ${_formatDate(harvestMaxDate)}';
    return 'Expected harvest period: $dateString ($durationDaysMin-$durationDaysMax days from sowing).\n'
        'Estimated crop yield: ${totalYieldMin.toStringAsFixed(1)} - ${totalYieldMax.toStringAsFixed(1)} $unit.';
  }

  String _formatDate(DateTime date) {
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Crop Planning Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Plan History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CropPlanningHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header card instruction
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryGreen, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Agronomic Calendar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Input your crop details to dynamically schedule fertilizer doses, pest sprays, and harvest dates.',
                              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Section
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crop Type',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCrop,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.grass_rounded, color: AppTheme.primaryGreen),
                            filled: true,
                            fillColor: AppTheme.backgroundLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                            ),
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCrop = newValue;
                                _isScheduleGenerated = false;
                              });
                            }
                          },
                          items: <String>['Cotton', 'Rice', 'Wheat', 'Tomato', 'Beetroot'].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Total Farm Acres',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _acresController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. 5.0',
                            prefixIcon: const Icon(Icons.filter_hdr_rounded, color: AppTheme.primaryGreen),
                            filled: true,
                            fillColor: AppTheme.backgroundLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Farm acres is required';
                            final double? parsed = double.tryParse(value);
                            if (parsed == null || parsed <= 0) return 'Enter a positive numeric acreage';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Sowing / Transplanting Date',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range_rounded, color: AppTheme.primaryGreen),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(_sowingDate),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryGreen),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _generateSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white),
                            label: const Text('GENERATE ADVISORY CALENDAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Output generated modules
                if (_isScheduleGenerated) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'GENERATED ADVISORY CALENDAR',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // 1. Harvest & Yield estimates
                  _buildAdvisorySectionHeader(Icons.stars_rounded, 'Harvest & Yield Estimate', AppTheme.accentGold),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _harvestEstimateText,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Fertilizer Schedule
                  _buildAdvisorySectionHeader(Icons.science_rounded, 'Fertilizer Application Schedule', AppTheme.primaryGreen),
                  _buildTimelineList(_fertilizerSchedule, AppTheme.primaryGreen),
                  const SizedBox(height: 24),

                  // 3. Pesticide Schedule
                  _buildAdvisorySectionHeader(Icons.bug_report_rounded, 'Prophylactic Pesticide Spray', Colors.redAccent),
                  _buildTimelineList(_pesticideSchedule, Colors.redAccent),
                  const SizedBox(height: 24),

                  // 4. Inspection Reminders
                  _buildAdvisorySectionHeader(Icons.assignment_rounded, 'Key Field Inspections', Colors.blueAccent),
                  _buildTimelineList(_inspectionReminders, Colors.blueAccent),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorySectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(List<PlanItem> items, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline left graphics
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 16, color: accentColor),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: accentColor.withValues(alpha: 0.2),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Timeline texts details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            Text(
                              _formatDate(item.date),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey[650], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class PlanItem {
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;

  PlanItem({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'title': title,
    'description': description,
    'iconCode': icon.codePoint,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: Icons.event_note_rounded,
    );
  }
}
