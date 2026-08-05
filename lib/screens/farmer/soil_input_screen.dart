import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/soil_analysis_service.dart';

class SoilInputScreen extends StatefulWidget {
  const SoilInputScreen({super.key});

  @override
  State<SoilInputScreen> createState() => _SoilInputScreenState();
}

class _SoilInputScreenState extends State<SoilInputScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _phController = TextEditingController();
  final _ocController = TextEditingController();
  final _moistController = TextEditingController();

  bool _isSaving = false;
  String _userId = 'FAR1234';

  final Map<AppLanguage, Map<String, String>> _localizedInput = {
    AppLanguage.english: {
      'title': 'New Soil Test Entry',
      'n_label': 'Nitrogen (N) (kg/acre)',
      'p_label': 'Phosphorus (P) (kg/acre)',
      'k_label': 'Potassium (K) (kg/acre)',
      'ph_label': 'Soil pH (0.0 to 14.0)',
      'oc_label': 'Organic Carbon (OC) (%)',
      'moist_label': 'Soil Moisture (%)',
      'submit_btn': 'Analyze Soil Health',
      'saving': 'Saving Report...',
      'validation_empty': 'Please enter a value',
      'validation_number': 'Please enter a valid number',
      'validation_ph_range': 'pH must be between 0.0 and 14.0',
      'validation_moist_range': 'Moisture must be between 0.0 and 100.0',
      'validation_oc_range': 'Organic carbon must be between 0.0 and 10.0%',
      'validation_positive': 'Value must be positive',
    },
    AppLanguage.telugu: {
      'title': 'కొత్త నేల పరీక్ష నమోదు',
      'n_label': 'నత్రజని (N) (కిలోలు/ఎకరం)',
      'p_label': 'భాస్వరం (P) (కిలోలు/ఎకరం)',
      'k_label': 'పొటాషియం (K) (కిలోలు/ఎకరం)',
      'ph_label': 'నేల పిహెచ్ (pH) (0.0 నుండి 14.0)',
      'oc_label': 'సేంద్రీయ కర్బనం (OC) (%)',
      'moist_label': 'నేల తేమ (%)',
      'submit_btn': 'నేల ఆరోగ్యాన్ని విశ్లేషించండి',
      'saving': 'నివేదిక భద్రపరచబడుతోంది...',
      'validation_empty': 'దయచేసి ఒక విలువను నమోదు చేయండి',
      'validation_number': 'సరైన సంఖ్యను నమోదు చేయండి',
      'validation_ph_range': 'పిహెచ్ విలువ 0.0 నుండి 14.0 మధ్య ఉండాలి',
      'validation_moist_range': 'తేమ విలువ 0.0 నుండి 100.0 మధ్య ఉండాలి',
      'validation_oc_range': 'సేంద్రీయ కర్బనం 0.0 నుండి 10.0% మధ్య ఉండాలి',
      'validation_positive': 'విలువ ధనాత్మకంగా ఉండాలి',
    },
    AppLanguage.tamil: {
      'title': 'புதிய மண் பரிசோதனை பதிவு',
      'n_label': 'தழைச்சத்து (N) (கிலோ/ஏக்கர்)',
      'p_label': 'மணிச்சத்து (P) (கிலோ/ஏக்கர்)',
      'k_label': 'சாம்பல்சத்து (K) (கிலோ/ஏக்கர்)',
      'ph_label': 'மண் பிஹெச் (pH) (0.0 முதல் 14.0)',
      'oc_label': 'கரிம கார்பன் (OC) (%)',
      'moist_label': 'மண் ஈரப்பதம் (%)',
      'submit_btn': 'மண் வளத்தை பகுப்பாய்வு செய்க',
      'saving': 'அறிக்கை சேமிக்கப்படுகிறது...',
      'validation_empty': 'தயவுசெய்து மதிப்பை உள்ளிடவும்',
      'validation_number': 'சரியான எண்ணை உள்ளிடவும்',
      'validation_ph_range': 'பிஹெச் 0.0 முதல் 14.0 வரை இருக்க வேண்டும்',
      'validation_moist_range': 'ஈரப்பதம் 0.0 முதல் 100.0 வரை இருக்க வேண்டும்',
      'validation_oc_range': 'கரிம கார்பன் 0.0 முதல் 10.0% வரை இருக்க வேண்டும்',
      'validation_positive': 'மதிப்பு நேர்மறையாக இருக்க வேண்டும்',
    },
    AppLanguage.hindi: {
      'title': 'नया मिट्टी परीक्षण प्रविष्टि',
      'n_label': 'नाइट्रोजन (N) (किग्रा/एकड़)',
      'p_label': 'फॉस्फोरस (P) (किग्रा/एकड़)',
      'k_label': 'पोटैशियम (K) (किग्रा/एकड़)',
      'ph_label': 'मिट्टी पीएच (pH) (0.0 से 14.0)',
      'oc_label': 'जैविक कार्बन (OC) (%)',
      'moist_label': 'मिट्टी की नमी (%)',
      'submit_btn': 'मिट्टी स्वास्थ्य विश्लेषण करें',
      'saving': 'रिपोर्ट सहेजी जा रही है...',
      'validation_empty': 'कृपया मान दर्ज करें',
      'validation_number': 'कृपया एक वैध संख्या दर्ज करें',
      'validation_ph_range': 'पीएच 0.0 और 14.0 के बीच होना चाहिए',
      'validation_moist_range': 'नमी 0.0 और 100.0 के बीच होनी चाहिए',
      'validation_oc_range': 'जैविक कार्बन 0.0 और 10.0% के बीच होना चाहिए',
      'validation_positive': 'मान सकारात्मक होना चाहिए',
    },
    AppLanguage.kannada: {
      'title': 'ಹೊಸ ಮಣ್ಣಿನ ಪರೀಕ್ಷೆ ದಾಖಲೆ',
      'n_label': 'ಸಾರಜನಕ (N) (ಕೆಜಿ/ಎಕರೆ)',
      'p_label': 'ರಂಜಕ (P) (ಕೆಜಿ/ಎಕರೆ)',
      'k_label': 'ಪೊಟ್ಯಾಶಿಯಂ (K) (ಕೆಜಿ/ಎಕರೆ)',
      'ph_label': 'ಮಣ್ಣಿನ ಪಿಎಚ್ (pH) (0.0 ರಿಂದ 14.0)',
      'oc_label': 'ಕರಿಬನ (OC) (%)',
      'moist_label': 'ಮಣ್ಣಿನ ತೇವಾಂಶ (%)',
      'submit_btn': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ವಿಶ್ಲೇಷಿಸಿ',
      'saving': 'ವರದಿ ಉಳಿಸಲಾಗುತ್ತಿದೆ...',
      'validation_empty': 'ದಯವಿಟ್ಟು ಮೌಲ್ಯವನ್ನು ನಮೂದಿಸಿ',
      'validation_number': 'ದಯವಿಟ್ಟು ಮಾನ್ಯ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ',
      'validation_ph_range': 'ಪಿಎಚ್ 0.0 ಮತ್ತು 14.0 ರ ನಡುವೆ ಇರಬೇಕು',
      'validation_moist_range': 'ತೇವಾಂಶ 0.0 ಮತ್ತು 100.0 ರ ನಡುವೆ ಇರಬೇಕು',
      'validation_oc_range': 'ಕರಿಬನ 0.0 ಮತ್ತು 10.0% ರ ನಡುವೆ ಇರಬೇಕು',
      'validation_positive': 'ಮೌಲ್ಯವು ಧನಾತ್ಮಕವಾಗಿರಬೇಕು',
    },
    AppLanguage.malayalam: {
      'title': 'പുതിയ മണ്ണ് പരിശോധന വിവരം',
      'n_label': 'നൈട്രജൻ (N) (കിലോ/ഏക്കർ)',
      'p_label': 'ഫോസ്ഫറസ് (P) (കിലോ/ഏക്കർ)',
      'k_label': 'പൊട്ടാസ്യം (K) (കിലോ/ഏക്കർ)',
      'ph_label': 'മണ്ണിന്റെ പി.എച്ച് (pH) (0.0 മുതൽ 14.0)',
      'oc_label': 'ജൈവ കാർബൺ (OC) (%)',
      'moist_label': 'മണ്ണിലെ ഈർപ്പം (%)',
      'submit_btn': 'മണ്ണ് പരിശോധന പൂർത്തിയാക്കുക',
      'saving': 'വിവരങ്ങൾ സൂക്ഷിക്കുന്നു...',
      'validation_empty': 'ദയവായി ഒരു മൂല്യം നൽകുക',
      'validation_number': 'ദയവായി ശരിയായ സംഖ്യ നൽകുക',
      'validation_ph_range': 'പി.എച്ച് 0.0-നും 14.0-നും ഇടയിലായിരിക്കണം',
      'validation_moist_range': 'ഈർപ്പം 0.0-നും 100.0-നും ഇടയിലായിരിക്കണം',
      'validation_oc_range': 'ജൈവ കാർബൺ 0.0-നും 10.0%-നും ഇടയിലായിരിക്കണം',
      'validation_positive': 'മൂല്യം പോസിറ്റീവ് ആയിരിക്കണം',
    },
  };

  String _getText(String key) {
    final lang = TranslationService().currentLanguage;
    final map = _localizedInput[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedInput[AppLanguage.english]![key]!;
  }

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      setState(() {
        _userId = phone;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final double nitrogen = double.parse(_nController.text.trim());
      final double phosphorus = double.parse(_pController.text.trim());
      final double potassium = double.parse(_kController.text.trim());
      final double pH = double.parse(_phController.text.trim());
      final double organicCarbon = double.parse(_ocController.text.trim());
      final double moisture = double.parse(_moistController.text.trim());

      final lang = TranslationService().currentLanguage;
      final analysis = SoilAnalysisService.analyze(
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        pH: pH,
        organicCarbon: organicCarbon,
        moisture: moisture,
        language: lang,
      );

      final Map<String, dynamic> reportData = {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'pH': pH,
        'organicCarbon': organicCarbon,
        'moisture': moisture,
        'overallScore': analysis.score,
        'scoreCategory': analysis.scoreCategory,
        'soilCondition': analysis.pHLabel,
        'deficiencies': analysis.advisories,
        'cropSuggestions': analysis.cropSuggestions,
        'fertilizerSuggestions': analysis.fertilizerSuggestions,
        'irrigationSuggestions': analysis.irrigationSuggestions,
        'reportDate': DateTime.now().millisecondsSinceEpoch,
      };

      await FirestoreService().saveSoilReport(_userId, reportData);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[SOIL_INPUT_SCREEN] Error submitting soil report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving soil report: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(_getText('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(_nController, _getText('n_label'), false, false, false),
                const SizedBox(height: 16),
                _buildInputField(_pController, _getText('p_label'), false, false, false),
                const SizedBox(height: 16),
                _buildInputField(_kController, _getText('k_label'), false, false, false),
                const SizedBox(height: 16),
                _buildInputField(_phController, _getText('ph_label'), true, false, false),
                const SizedBox(height: 16),
                _buildInputField(_ocController, _getText('oc_label'), false, true, false),
                const SizedBox(height: 16),
                _buildInputField(_moistController, _getText('moist_label'), false, false, true),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_getText('saving'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(
                          _getText('submit_btn'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    bool isPh,
    bool isOc,
    bool isMoist,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return _getText('validation_empty');
        }
        final double? numVal = double.tryParse(value.trim());
        if (numVal == null) {
          return _getText('validation_number');
        }
        if (numVal < 0) {
          return _getText('validation_positive');
        }
        if (isPh && (numVal < 0.0 || numVal > 14.0)) {
          return _getText('validation_ph_range');
        }
        if (isMoist && (numVal < 0.0 || numVal > 100.0)) {
          return _getText('validation_moist_range');
        }
        if (isOc && (numVal < 0.0 || numVal > 10.0)) {
          return _getText('validation_oc_range');
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _phController.dispose();
    _ocController.dispose();
    _moistController.dispose();
    super.dispose();
  }
}
