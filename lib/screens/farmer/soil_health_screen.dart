import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/soil_analysis_service.dart';
import 'soil_input_screen.dart';

class SoilHealthScreen extends StatefulWidget {
  const SoilHealthScreen({super.key});

  @override
  State<SoilHealthScreen> createState() => _SoilHealthScreenState();
}

class _SoilHealthScreenState extends State<SoilHealthScreen> {
  String _userId = 'FAR1234';
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _selectedReport; // Set when viewing a historical report

  final Map<AppLanguage, Map<String, String>> _localizedSoil = {
    AppLanguage.english: {
      'title': 'Soil Health Report',
      'history_title': 'Soil Test History',
      'view_history': 'View History',
      'add_report': 'New Soil Test',
      'score_label': 'Soil Health Score',
      'npk_title': 'Macronutrient Levels',
      'properties_title': 'Soil Properties',
      'advisory_title': 'Soil Health Advisory',
      'crops_title': 'Suitable Crop Recommendations',
      'fertilizer_title': 'Suggested Fertilizer Inputs',
      'irrigation_title': 'Irrigation Suggestions',
      'export_pdf': 'Export PDF Report',
      'empty_title': 'No Soil Records Yet',
      'empty_desc': 'Analyze your soil parameters (NPK, pH, carbon, moisture) to get dynamic crop recommendations and fertilizer inputs.',
      'empty_btn': 'Create Soil Health Card',
      'ph_label': 'Soil pH',
      'oc_label': 'Organic Carbon',
      'moist_label': 'Soil Moisture',
      'nitrogen': 'Nitrogen (N)',
      'phosphorus': 'Phosphorus (P)',
      'potassium': 'Potassium (K)',
      'delete_title': 'Delete Report',
      'delete_confirm': 'Are you sure you want to delete this soil report?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'viewing_historical': 'Viewing Historical Report',
      'reset_latest': 'Show Latest',
      'history_empty': 'No historical reports found.',
    },
    AppLanguage.telugu: {
      'title': 'నేల ఆరోగ్య నివేదిక',
      'history_title': 'నేల పరీక్షల చరిత్ర',
      'view_history': 'చరిత్ర చూడండి',
      'add_report': 'కొత్త నేల పరీక్ష',
      'score_label': 'నేల ఆరోగ్య స్కోర్',
      'npk_title': 'స్థూల పోషకాల స్థాయిలు',
      'properties_title': 'నేల లక్షణాలు',
      'advisory_title': 'నేల ఆరోగ్య సలహాలు',
      'crops_title': 'అనుకూలమైన పంటల సిఫార్సులు',
      'fertilizer_title': 'సూచించిన ఎరువుల మోతాదు',
      'irrigation_title': 'నీటి యాజమాన్య పద్ధతులు',
      'export_pdf': 'PDF నివేదికను డౌన్‌లోడ్ చేయి',
      'empty_title': 'నేల పరీక్షల వివరాలు లేవు',
      'empty_desc': 'మీ పొలం నేల నమూనా పరీక్షల వివరాలను నమోదు చేసి, తగిన పంటలు మరియు ఎరువుల సిఫార్సులను పొందండి.',
      'empty_btn': 'నేల ఆరోగ్య కార్డు సృష్టించండి',
      'ph_label': 'నేల పిహెచ్ (pH)',
      'oc_label': 'సేంద్రీయ కర్బనం',
      'moist_label': 'నేల తేమ',
      'nitrogen': 'నత్రజని (N)',
      'phosphorus': 'భాస్వరం (P)',
      'potassium': 'పొటాషియం (K)',
      'delete_title': 'నివేదిక తొలగింపు',
      'delete_confirm': 'ఈ నేల పరీక్ష నివేదికను తొలగించాలనుకుంటున్నారా?',
      'cancel': 'రద్దు చేయి',
      'delete': 'తొలగించు',
      'viewing_historical': 'పాత నివేదికను చూస్తున్నారు',
      'reset_latest': 'తాజాది చూపించు',
      'history_empty': 'నేల పరీక్షల చరిత్ర లేదు.',
    },
    AppLanguage.tamil: {
      'title': 'மண் வள அட்டை',
      'history_title': 'மண் பரிசோதனை வரலாறு',
      'view_history': 'வரலாறு பார்க்க',
      'add_report': 'புதிய மண் பரிசோதனை',
      'score_label': 'மண் வளம் மதிப்பெண்',
      'npk_title': 'பேரூட்டச்சத்து அளவுகள்',
      'properties_title': 'மண்ணின் பண்புகள்',
      'advisory_title': 'மண் வள ஆலோசனைகள்',
      'crops_title': 'பரிந்துரைக்கப்படும் பயிர்கள்',
      'fertilizer_title': 'பரிந்துரைக்கப்படும் உரங்கள்',
      'irrigation_title': 'நீர் பாசன ஆலோசனைகள்',
      'export_pdf': 'PDF அறிக்கையை பதிவிறக்கு',
      'empty_title': 'மண் பரிசோதனை பதிவுகள் இல்லை',
      'empty_desc': 'தகுந்த பயிர்கள் மற்றும் உரப் பரிந்துரைகளைப் பெற உங்கள் மண் பரிசோதனை அளவுகளை உள்ளிடவும்.',
      'empty_btn': 'மண் வள அட்டை உருவாக்கு',
      'ph_label': 'மண் பிஹெச் (pH)',
      'oc_label': 'கரிம கார்பன்',
      'moist_label': 'மண் ஈரப்பதம்',
      'nitrogen': 'தழைச்சத்து (N)',
      'phosphorus': 'மணிச்சத்து (P)',
      'potassium': 'சாம்பல்சத்து (K)',
      'delete_title': 'அறிக்கையை நீக்கு',
      'delete_confirm': 'இந்த மண் பரிசோதனை அறிக்கையை நீக்க வேண்டுமா?',
      'cancel': 'ரத்து செய்',
      'delete': 'நீக்கு',
      'viewing_historical': 'பழைய அறிக்கை காட்டப்படுகிறது',
      'reset_latest': 'புதியதை காட்டு',
      'history_empty': 'வரலாற்று பதிவுகள் இல்லை.',
    },
    AppLanguage.hindi: {
      'title': 'मृदा स्वास्थ्य कार्ड',
      'history_title': 'मिट्टी परीक्षण इतिहास',
      'view_history': 'इतिहास देखें',
      'add_report': 'नया परीक्षण',
      'score_label': 'मिट्टी स्वास्थ्य स्कोर',
      'npk_title': 'मुख्य पोषक तत्व स्तर',
      'properties_title': 'मिट्टी के भौतिक गुण',
      'advisory_title': 'मृदा स्वास्थ्य परामर्श',
      'crops_title': 'उपयुक्त फसल सुझाव',
      'fertilizer_title': 'अनुशंसित उर्वरक मात्रा',
      'irrigation_title': 'सिंचाई और नमी सुझाव',
      'export_pdf': 'पीडीएफ रिपोर्ट साझा करें',
      'empty_title': 'कोई मृदा रिकॉर्ड नहीं है',
      'empty_desc': 'अनुकूल फसल और उर्वरक सुझाव प्राप्त करने के लिए अपनी मिट्टी के परीक्षण पैरामीटर (NPK, पीएच, नमी) दर्ज करें।',
      'empty_btn': 'मृदा स्वास्थ्य कार्ड बनाएं',
      'ph_label': 'मिट्टी पीएच',
      'oc_label': 'जैविक कार्बन',
      'moist_label': 'मिट्टी की नमी',
      'nitrogen': 'नाइट्रोजन (N)',
      'phosphorus': 'फॉस्फोरस (P)',
      'potassium': 'पोटैशियम (K)',
      'delete_title': 'रिपोर्ट हटाएं',
      'delete_confirm': 'क्या आप वाकई इस मृदा रिपोर्ट को हटाना चाहते हैं?',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'viewing_historical': 'ऐतिहासिक रिपोर्ट देख रहे हैं',
      'reset_latest': 'नवीनतम दिखाएं',
      'history_empty': 'कोई पुराना इतिहास नहीं मिला।',
    },
    AppLanguage.kannada: {
      'title': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ವರದಿ',
      'history_title': 'ಮಣ್ಣಿನ ಪರೀಕ್ಷೆ ಇತಿಹಾಸ',
      'view_history': 'ಇತಿಹಾಸ ವೀಕ್ಷಿಸಿ',
      'add_report': 'ಹೊಸ ಮಣ್ಣಿನ ಪರೀಕ್ಷೆ',
      'score_label': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಸ್ಕೋರ್',
      'npk_title': 'ಮುಖ್ಯ ಪೋಷಕಾಂಶ ಮಟ್ಟಗಳು',
      'properties_title': 'ಮಣ್ಣಿನ ಗುಣಲಕ್ಷಣಗಳು',
      'advisory_title': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಸಲಹೆಗಳು',
      'crops_title': 'ಸೂಕ್ತ ಬೆಳೆಗಳ ಶಿಫಾರಸುಗಳು',
      'fertilizer_title': 'ಶಿಫಾರಸು ಮಾಡಿದ ರಸಗೊಬ್ಬರಗಳು',
      'irrigation_title': 'ನೀರಾವರಿ ಸಲಹೆಗಳು',
      'export_pdf': 'PDF ವರದಿ ಡೌನ್\u200cಲೋಡ್ ಮಾಡಿ',
      'empty_title': 'ಯಾವುದೇ ಮಣ್ಣಿನ ಪರೀಕ್ಷೆ ದಾಖಲೆಗಳಿಲ್ಲ',
      'empty_desc': 'ಸೂಕ್ತ ಬೆಳೆಗಳು ಮತ್ತು ರಸಗೊಬ್ಬರಗಳ ಶಿಫಾರಸುಗಳನ್ನು ಪಡೆಯಲು ನಿಮ್ಮ ಮಣ್ಣಿನ ಪರೀಕ್ಷೆ ವಿವರಗಳನ್ನು ನಮೂದಿಸಿ.',
      'empty_btn': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಕಾರ್ಡ್ ರಚಿಸಿ',
      'ph_label': 'ಮಣ್ಣಿನ ಪಿಎಚ್ (pH)',
      'oc_label': 'ಕರಿಬನ (OC)',
      'moist_label': 'ಮಣ್ಣಿನ ತೇವಾಂಶ',
      'nitrogen': 'ಸಾರಜನಕ (N)',
      'phosphorus': 'ರಂಜಕ (P)',
      'potassium': 'ಪೊಟ್ಯಾಶಿಯಂ (K)',
      'delete_title': 'ದಾಖಲೆ ಅಳಿಸಿ',
      'delete_confirm': 'ಈ ಮಣ್ಣಿನ ಪರೀಕ್ಷೆ ದಾಖಲೆಯನ್ನು ಅಳಿಸಲು ನೀವು ಖಚಿತವಾಗಿದ್ದೀರಾ?',
      'cancel': 'ರದ್ದುಗೊಳಿಸು',
      'delete': 'ಅಳಿಸು',
      'viewing_historical': 'ಹಳೆಯ ದಾಖಲೆ ವೀಕ್ಷಿಸಲಾಗುತ್ತಿದೆ',
      'reset_latest': 'ತಾಜಾ ದಾಖಲೆ ತೋರಿಸು',
      'history_empty': 'ಯಾವುದೇ ಇತಿಹಾಸ ಕಂಡುಬಂದಿಲ್ಲ.',
    },
    AppLanguage.malayalam: {
      'title': 'മണ്ണ് ആരോഗ്യ കാർഡ്',
      'history_title': 'പരിശോധനാ ചരിത്രം',
      'view_history': 'ചരിത്രം പരിശോധിക്കുക',
      'add_report': 'പുതിയ പരിശോധന',
      'score_label': 'മണ്ണ് ആരോഗ്യ സ്കോർ',
      'npk_title': 'പ്രധാന പോഷകങ്ങളുടെ അളവ്',
      'properties_title': 'മണ്ണിന്റെ ഗുണവിശേഷങ്ങൾ',
      'advisory_title': 'മണ്ണാരോഗ്യ നിർദ്ദേശങ്ങൾ',
      'crops_title': 'അനുയോജ്യമായ വിളകൾ',
      'fertilizer_title': 'വളപ്രയോഗ നിർദ്ദേശങ്ങൾ',
      'irrigation_title': 'നനയ്ക്കൽ നിർദ്ദേശങ്ങൾ',
      'export_pdf': 'PDF റിപ്പോർട്ട് ഡൗൺലോഡ് ചെയ്യുക',
      'empty_title': 'പരിശോധനാ വിവരങ്ങൾ ലഭ്യമല്ല',
      'empty_desc': 'അനുയോജ്യമായ വിളകളും വളപ്രയോഗ രീതികളും അറിയാൻ നിങ്ങളുടെ മണ്ണ് പരിശോധനാ ഫലങ്ങൾ രേഖപ്പെടുത്തുക.',
      'empty_btn': 'മണ്ണ് ആരോഗ്യ കാർഡ് തയ്യാറാക്കുക',
      'ph_label': 'മണ്ണിന്റെ പി.എച്ച് (pH)',
      'oc_label': 'ജൈവ കാർബൺ (OC)',
      'moist_label': 'മണ്ണിലെ ഈർപ്പം',
      'nitrogen': 'നൈട്രജൻ (N)',
      'phosphorus': 'ഫോസ്ഫറസ് (P)',
      'potassium': 'പൊട്ടാസ്യം (K)',
      'delete_title': 'വിവരം ഇല്ലാതാക്കുക',
      'delete_confirm': 'ഈ മണ്ണ് പരിശോധനാ വിവരം ഇല്ലാതാക്കാൻ ഉറപ്പാണോ?',
      'cancel': 'റദ്ദാക്കുക',
      'delete': 'ഒഴിവാക്കുക',
      'viewing_historical': 'പഴയ പരിശോധനാ വിവരം കാണുന്നു',
      'reset_latest': 'പുതിയത് കാണിക്കുക',
      'history_empty': 'പഴയ വിവരങ്ങൾ ഒന്നും കണ്ടെത്തിയില്ല.',
    },
  };

  String _getText(String key) {
    final lang = TranslationService().currentLanguage;
    final map = _localizedSoil[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedSoil[AppLanguage.english]![key]!;
  }

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      _userId = phone;
      final profile = await FirestoreService().getUserProfile(phone);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  Future<void> _exportPdfReport(Map<String, dynamic> report) async {
    final pdf = pw.Document();
    
    final int rawDate = report['reportDate'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    final String name = _userProfile?['name'] ?? 'Farmer';
    final String phone = _userProfile?['phone'] ?? _userId;
    final String village = _userProfile?['village'] ?? 'N/A';
    final String district = _userProfile?['district'] ?? 'N/A';

    final double score = (report['overallScore'] as num? ?? 0.0).toDouble();
    final String category = report['scoreCategory'] ?? 'Fair Health';

    final double nitrogen = (report['nitrogen'] as num? ?? 0.0).toDouble();
    final double phosphorus = (report['phosphorus'] as num? ?? 0.0).toDouble();
    final double potassium = (report['potassium'] as num? ?? 0.0).toDouble();
    final double pH = (report['pH'] as num? ?? 0.0).toDouble();
    final double oc = (report['organicCarbon'] as num? ?? 0.0).toDouble();
    final double moisture = (report['moisture'] as num? ?? 0.0).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('FarmCare AI - Soil Health Card', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2, color: PdfColor.fromHex('#2E7D32')),
                pw.SizedBox(height: 20),

                pw.Text('Farmer Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                pw.SizedBox(height: 6),
                pw.Text('Farmer Name: $name'),
                pw.Text('Phone Number: $phone'),
                pw.Text('Location: Village $village, District $district'),
                pw.Text('Analysis Date: $dateStr'),
                pw.SizedBox(height: 20),

                pw.Text('Soil Parameter Readings & Analysis', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                pw.SizedBox(height: 8),
                pw.Text('Overall Soil Score: ${score.toStringAsFixed(1)} / 100 ($category)'),
                pw.Text('Soil pH: ${pH.toStringAsFixed(1)} (${report['soilCondition'] ?? "Neutral"})'),
                pw.Text('Nitrogen (N): ${nitrogen.toStringAsFixed(1)} kg/acre'),
                pw.Text('Phosphorus (P): ${phosphorus.toStringAsFixed(1)} kg/acre'),
                pw.Text('Potassium (K): ${potassium.toStringAsFixed(1)} kg/acre'),
                pw.Text('Organic Carbon (OC): ${oc.toStringAsFixed(2)}%'),
                pw.Text('Soil Moisture: ${moisture.toStringAsFixed(1)}%'),
                pw.SizedBox(height: 20),

                pw.Text('Suitable Crop Recommendations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                pw.SizedBox(height: 6),
                pw.Text((report['cropSuggestions'] as List? ?? []).join(', ')),
                pw.SizedBox(height: 20),

                pw.Text('Recommended Remedial Advisory', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                pw.SizedBox(height: 6),
                ...(report['deficiencies'] as List? ?? []).map((def) => pw.Bullet(text: def.toString())),
                pw.SizedBox(height: 16),

                pw.Text('Suggested Fertilizer Dosage', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                pw.SizedBox(height: 6),
                ...(report['fertilizerSuggestions'] as List? ?? []).map((fert) => pw.Bullet(text: fert.toString())),
                pw.SizedBox(height: 16),

                pw.Text('Irrigation Guidelines', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
                pw.SizedBox(height: 6),
                ...(report['irrigationSuggestions'] as List? ?? []).map((irrig) => pw.Bullet(text: irrig.toString())),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Soil_Health_Card_${phone}_${date.millisecondsSinceEpoch}.pdf',
    );
  }

  void _showHistorySheet(List<Map<String, dynamic>> reports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getText('history_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  if (reports.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(_getText('history_empty'), style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final r = reports[index];
                          final int rDate = r['reportDate'] as int? ?? 0;
                          final date = DateTime.fromMillisecondsSinceEpoch(rDate);
                          final dateStr = '${date.day}/${date.month}/${date.year}';
                          
                          final double score = (r['overallScore'] as num? ?? 0.0).toDouble();
                          final String category = r['scoreCategory'] ?? 'Fair';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                '${_getText('score_label')}: ${score.toStringAsFixed(1)} ($category)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _confirmDeleteReport(r['reportId']),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryGreen),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedReport = r;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(_getText('delete_title')),
        content: Text(_getText('delete_confirm')),
        actions: [
          TextButton(
            child: Text(_getText('cancel')),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              await FirestoreService().deleteSoilReport(reportId);
              if (_selectedReport?['reportId'] == reportId) {
                setState(() {
                  _selectedReport = null;
                });
              }
            },
            child: Text(_getText('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getSoilReportsStream(_userId),
      builder: (context, snapshot) {
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        final List<Map<String, dynamic>> reports = snapshot.data ?? [];
        
        // Determine which report we show
        Map<String, dynamic>? activeReport;
        if (_selectedReport != null) {
          // Check if selected report still exists in the snapshot list
          final stillExists = reports.any((r) => r['reportId'] == _selectedReport!['reportId']);
          if (stillExists) {
            activeReport = reports.firstWhere((r) => r['reportId'] == _selectedReport!['reportId']);
          } else {
            activeReport = null;
          }
        } else if (reports.isNotEmpty) {
          activeReport = reports.first;
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(_getText('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (reports.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: _getText('view_history'),
                  onPressed: () => _showHistorySheet(reports),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: _getText('add_report'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SoilInputScreen()),
                  ),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : activeReport == null
                    ? _buildEmptyState()
                    : _buildReportDetails(activeReport, reports),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.science_outlined,
                color: AppTheme.primaryGreen,
                size: 80,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _getText('empty_title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 12),
            Text(
              _getText('empty_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.45),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(_getText('empty_btn')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SoilInputScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportDetails(Map<String, dynamic> report, List<Map<String, dynamic>> allReports) {
    final lang = TranslationService().currentLanguage;
    final double nitrogen = (report['nitrogen'] as num? ?? 0.0).toDouble();
    final double phosphorus = (report['phosphorus'] as num? ?? 0.0).toDouble();
    final double potassium = (report['potassium'] as num? ?? 0.0).toDouble();
    final double pH = (report['pH'] as num? ?? 0.0).toDouble();
    final double oc = (report['organicCarbon'] as num? ?? 0.0).toDouble();
    final double moisture = (report['moisture'] as num? ?? 0.0).toDouble();

    final analysis = SoilAnalysisService.analyze(
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      pH: pH,
      organicCarbon: oc,
      moisture: moisture,
      language: lang,
    );

    final isViewingHistory = _selectedReport != null && allReports.isNotEmpty && allReports.first['reportId'] != _selectedReport!['reportId'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isViewingHistory) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getText('viewing_historical'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedReport = null;
                      });
                    },
                    child: Text(_getText('reset_latest'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ),
                ],
              ),
            ),
          ],

          // Overall Score Card
          _overallScoreCard(analysis),
          const SizedBox(height: 24),

          // Nutrient levels
          _sectionTitle(_getText('npk_title')),
          const SizedBox(height: 12),
          _nutrientCard(_getText('nitrogen'), analysis.nutrients['N']!),
          _nutrientCard(_getText('phosphorus'), analysis.nutrients['P']!),
          _nutrientCard(_getText('potassium'), analysis.nutrients['K']!),
          const SizedBox(height: 24),

          // Soil Properties
          _sectionTitle(_getText('properties_title')),
          const SizedBox(height: 12),
          _propertyCard(_getText('ph_label'), pH.toStringAsFixed(1), analysis.pHLabel, AppTheme.primaryGreen, Icons.science_rounded),
          _propertyCard(_getText('oc_label'), '${oc.toStringAsFixed(2)}%', analysis.organicCarbonLabel, AppTheme.accentGold, Icons.eco_rounded),
          _propertyCard(_getText('moist_label'), '${moisture.toStringAsFixed(1)}%', analysis.moistureLabel, Colors.blueAccent, Icons.water_drop_rounded),
          const SizedBox(height: 24),

          // Crop suggestions
          _sectionTitle(_getText('crops_title')),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.cropSuggestions.map((crop) {
                  return Chip(
                    label: Text(crop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Advisories
          _sectionTitle(_getText('advisory_title')),
          const SizedBox(height: 12),
          ...analysis.advisories.map((adv) => _advisoryCard(Icons.lightbulb_rounded, adv, AppTheme.primaryGreen)),
          const SizedBox(height: 24),

          // Fertilizers suggestions
          _sectionTitle(_getText('fertilizer_title')),
          const SizedBox(height: 12),
          ...analysis.fertilizerSuggestions.map((fert) => _advisoryCard(Icons.add_task_rounded, fert, AppTheme.accentGold)),
          const SizedBox(height: 24),

          // Irrigation suggestions
          _sectionTitle(_getText('irrigation_title')),
          const SizedBox(height: 12),
          ...analysis.irrigationSuggestions.map((irrig) => _advisoryCard(Icons.water_drop_rounded, irrig, Colors.blueAccent)),
          const SizedBox(height: 32),

          // PDF Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(_getText('export_pdf')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: () => _exportPdfReport(report),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _overallScoreCard(SoilAnalysisResult analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: analysis.scoreColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: analysis.scoreColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(
              child: Text(
                analysis.score.toStringAsFixed(0),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getText('score_label'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.scoreCategory,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                if (analysis.advisories.isNotEmpty)
                  Text(
                    analysis.advisories.first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5));

  Widget _nutrientCard(String name, NutrientStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: status.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  status.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: status.percent / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.12),
              color: status.color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(status.advice, style: TextStyle(fontSize: 12, color: Colors.grey[650], height: 1.35)),
        ],
      ),
    );
  }

  Widget _propertyCard(String name, String value, String note, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(note, style: TextStyle(fontSize: 11, color: Colors.grey[650], height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _advisoryCard(IconData icon, String body, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
