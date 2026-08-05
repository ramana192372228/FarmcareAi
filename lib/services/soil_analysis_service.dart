import 'package:flutter/material.dart';
import 'translation_service.dart';
import '../theme/app_theme.dart';

class NutrientStatus {
  final String label; // "LOW", "MEDIUM", "HIGH"
  final int percent; // 0 to 100 for progress indicator
  final Color color; // Red, Yellow, Green
  final String advice;

  NutrientStatus({
    required this.label,
    required this.percent,
    required this.color,
    required this.advice,
  });
}

class SoilAnalysisResult {
  final double score;
  final String scoreCategory; // "Excellent", "Good", "Fair", "Poor"
  final Color scoreColor;
  final String pHLabel;
  final String pHAdvisory;
  final String organicCarbonLabel;
  final String organicCarbonAdvisory;
  final String moistureLabel;
  final String moistureAdvisory;
  final Map<String, NutrientStatus> nutrients; // 'N', 'P', 'K'
  final List<String> cropSuggestions;
  final List<String> fertilizerSuggestions;
  final List<String> irrigationSuggestions;
  final List<String> advisories;

  SoilAnalysisResult({
    required this.score,
    required this.scoreCategory,
    required this.scoreColor,
    required this.pHLabel,
    required this.pHAdvisory,
    required this.organicCarbonLabel,
    required this.organicCarbonAdvisory,
    required this.moistureLabel,
    required this.moistureAdvisory,
    required this.nutrients,
    required this.cropSuggestions,
    required this.fertilizerSuggestions,
    required this.irrigationSuggestions,
    required this.advisories,
  });
}

class SoilAnalysisService {
  static final Map<AppLanguage, Map<String, String>> _localizedEngine = {
    AppLanguage.english: {
      'excellent': 'Excellent Health',
      'good': 'Good Health',
      'fair': 'Fair Health',
      'poor': 'Poor Health',
      'low': 'LOW',
      'medium': 'MEDIUM',
      'high': 'HIGH',
      'ph_strongly_acidic': 'Strongly Acidic',
      'ph_slightly_acidic': 'Slightly Acidic',
      'ph_neutral': 'Neutral',
      'ph_slightly_alkaline': 'Slightly Alkaline',
      'ph_strongly_alkaline': 'Strongly Alkaline',
      'oc_deficient': 'Deficient',
      'oc_moderate': 'Moderate',
      'oc_healthy': 'Healthy/High',
      'moist_dry': 'Dry',
      'moist_optimal': 'Optimal',
      'moist_wet': 'Wet/High Drainage',
      'n_low_advice': 'Apply Urea (50kg/acre) in split doses or sow legumes.',
      'n_med_advice': 'Nitrogen is optimal. Maintain with farmyard manure.',
      'n_high_advice': 'Nitrogen is rich. Avoid additional Nitrogen inputs.',
      'p_low_advice': 'Apply Single Super Phosphate (SSP) or DAP as basal dose.',
      'p_med_advice': 'Phosphorus is optimal. Maintain current basal dosage.',
      'p_high_advice': 'Phosphorus is sufficient. Skip phosphate inputs to save cost.',
      'k_low_advice': 'Apply Muriate of Potash (MOP) to boost potash content.',
      'k_med_advice': 'Potash levels are adequate. Maintain standard practices.',
      'k_high_advice': 'Rich potash levels. Avoid additional MOP this cycle.',
      'ph_sa_advice': 'Apply agricultural lime/dolomite (200kg/acre) to raise pH.',
      'ph_sia_advice': 'Slightly acidic – Ideal for Cotton, Potato, Groundnut.',
      'ph_neu_advice': 'Neutral soil – Ideal for Paddy, Wheat, Vegetables.',
      'ph_salk_advice': 'Slightly alkaline – Apply gypsum (100kg/acre) or compost.',
      'ph_salk_strong_advice': 'Strongly alkaline – Apply Gypsum (200kg/acre) and organic manure.',
      'oc_low_advice': 'Add FYM/vermicompost (2.5 tons/acre) to raise organic carbon.',
      'oc_med_advice': 'Moderate carbon. Rotate with green manure crops.',
      'oc_high_advice': 'Excellent carbon. Maintain crop residue recycling.',
      'moist_low_advice': 'Sandy texture, drains quickly. Apply mulching and drip water.',
      'moist_med_advice': 'Moisture levels are optimal. Standard irrigation.',
      'moist_high_advice': 'High moisture. Ensure proper drainage to avoid root rot.',
    },
    AppLanguage.telugu: {
      'excellent': 'అద్భుతమైన ఆరోగ్యం',
      'good': 'మంచి ఆరోగ్యం',
      'fair': 'సాధారణ ఆరోగ్యం',
      'poor': 'బలహీనమైన ఆరోగ్యం',
      'low': 'తక్కువ',
      'medium': 'మధ్యమం',
      'high': 'ఎక్కువ',
      'ph_strongly_acidic': 'అధిక ఆమ్లత్వం',
      'ph_slightly_acidic': 'స్వల్ప ఆమ్లత్వం',
      'ph_neutral': 'తటస్థం',
      'ph_slightly_alkaline': 'స్వల్ప క్షారత్వం',
      'ph_strongly_alkaline': 'అధిక క్షారత్వం',
      'oc_deficient': 'లోపం',
      'oc_moderate': 'మధ్యమం',
      'oc_healthy': 'ఆరోగ్యకరం',
      'moist_dry': 'పొడి నేల',
      'moist_optimal': 'అనుకూలం',
      'moist_wet': 'అధిక తేమ',
      'n_low_advice': 'యూరియా (ఎకరానికి 50 కిలోలు) విడతలుగా వేయండి లేదా పప్పుదినుసులు సాగు చేయండి.',
      'n_med_advice': 'నత్రజని సమృద్ధిగా ఉంది. సేంద్రీయ ఎరువులతో కొనసాగించండి.',
      'n_high_advice': 'నత్రజని చాలా ఎక్కువగా ఉంది. అదనపు నత్రజని ఎరువులు వేయకండి.',
      'p_low_advice': 'సింగిల్ సూపర్ ఫాస్ఫేట్ (SSP) లేదా DAP ని బేసల్ డోస్‌గా వేయండి.',
      'p_med_advice': 'భాస్వరం సరిపడా ఉంది. ప్రస్తుత మోతాదును కొనసాగించండి.',
      'p_high_advice': 'భాస్వరం ఎక్కువగా ఉంది. ఖర్చు తగ్గించుకోవడానికి ఫాస్ఫేట్ ఎరువులు ఆపండి.',
      'k_low_advice': 'పొటాష్ శాతాన్ని పెంచడానికి మ్యూరియేట్ ఆఫ్ పొటాష్ (MOP) వేయండి.',
      'k_med_advice': 'పొటాషియం స్థాయిలు అనుకూలంగా ఉన్నాయి.',
      'k_high_advice': 'పొటాషియం సమృద్ధిగా ఉంది. ఈ పంట కాలంలో MOP వేయకండి.',
      'ph_sa_advice': 'నేల ఆమ్లత్వాన్ని తగ్గించడానికి వ్యవసాయ సున్నం (ఎకరానికి 200 కిలోలు) చల్లండి.',
      'ph_sia_advice': 'స్వల్ప ఆమ్లత్వం – పత్తి, బంగాళాదుంప, వేరుశనగ పంటలకు అనుకూలం.',
      'ph_neu_advice': 'తటస్థ నేల – వరి, గోధుమలు, కూరగాయల సాగుకు అనుకూలం.',
      'ph_salk_advice': 'స్వల్ప క్షారత్వం – జిప్సం (ఎకరానికి 100 కిలోలు) లేదా కంపోస్ట్ వేయండి.',
      'ph_salk_strong_advice': 'అధిక క్షారత్వం – జిప్సం (200 కిలోలు) మరియు సేంద్రీయ ఎరువులు వేయండి.',
      'oc_low_advice': 'సేంద్రీయ కర్బనాన్ని పెంచడానికి పశువుల ఎరువు/వర్మీకంపోస్ట్ (2.5 టన్నులు) వేయండి.',
      'oc_med_advice': 'మధ్యమ కర్బనం. పచ్చిరొట్ట ఎరువుల పంటలను సాగు చేయండి.',
      'oc_high_advice': 'అద్భుతమైన కర్బనం ఉంది. పంట అవశేషాలను తిరిగి నేలలో కలపండి.',
      'moist_low_advice': 'తేమ తక్కువగా ఉంది. డ్రిప్ ఇరిగేషన్ మరియు మల్చింగ్ ఉపయోగించండి.',
      'moist_med_advice': 'తేమ అనుకూలంగా ఉంది. అవసరమైనప్పుడు నీరు పెట్టండి.',
      'moist_high_advice': 'అధిక తేమ. వేరుకుళ్లు నివారించడానికి నీటి నిల్వ లేకుండా చూసుకోండి.',
    },
    AppLanguage.tamil: {
      'excellent': 'சிறந்த மண் வளம்',
      'good': 'நல்ல மண் வளம்',
      'fair': 'மிதமான மண் வளம்',
      'poor': 'குறைந்த மண் வளம்',
      'low': 'குறைவு',
      'medium': 'மிதமான',
      'high': 'அதிகம்',
      'ph_strongly_acidic': 'அதிக அமிலத்தன்மை',
      'ph_slightly_acidic': 'குறைந்த அமிலத்தன்மை',
      'ph_neutral': 'சீரானது (நடுநிலை)',
      'ph_slightly_alkaline': 'குறைந்த காரத்தன்மை',
      'ph_strongly_alkaline': 'அதிக காரத்தன்மை',
      'oc_deficient': 'குறைபாடு',
      'oc_moderate': 'மிதமானது',
      'oc_healthy': 'ஆரோக்கியமானது',
      'moist_dry': 'வறண்டது',
      'moist_optimal': 'உகந்தது',
      'moist_wet': 'அதிக ஈரப்பதம்',
      'n_low_advice': 'யூரியா (ஏக்கருக்கு 50 கிலோ) பிரித்து இடவும் அல்லது பருப்பு வகை பயிரிடவும்.',
      'n_med_advice': 'தழைச்சத்து உகந்த அளவில் உள்ளது. இயற்கை உரங்களை இடவும்.',
      'n_high_advice': 'தழைச்சத்து அதிகமாக உள்ளது. தழைச்சத்து உரங்களை தவிர்க்கவும்.',
      'p_low_advice': 'அடி உரமாக சிங்கிள் சூப்பர் பாஸ்பேட் (SSP) அல்லது DAP இடவும்.',
      'p_med_advice': 'மணிச்சத்து உகந்த அளவில் உள்ளது. தற்போதைய அளவை தொடரவும்.',
      'p_high_advice': 'மணிச்சத்து போதுமானதாக உள்ளது. உரச் செலவை குறைக்க பாஸ்பேட் உரங்களை தவிர்க்கவும்.',
      'k_low_advice': 'சாம்பல் சத்தை அதிகரிக்க பொட்டாஷ் (MOP) உரத்தை இடவும்.',
      'k_med_advice': 'சாம்பல் சத்து உகந்த அளவில் உள்ளது. சாதாரண பராமரிப்பு போதுமானது.',
      'k_high_advice': 'சாம்பல் சத்து அதிகமாக உள்ளது. இந்த பயிர் சுழற்சிக்கு பொட்டாஷ் தேவையில்லை.',
      'ph_sa_advice': 'அமிலத்தன்மையை குறைக்க விவசாய சுண்ணாம்பு (ஏக்கருக்கு 200 கிலோ) இடவும்.',
      'ph_sia_advice': 'குறைந்த அமிலத்தன்மை – பருத்தி, உருளை, நிலக்கடலைக்கு உகந்தது.',
      'ph_neu_advice': 'நடுநிலை மண் – நெல், கோதுமை, காய்கறிகளுக்கு உகந்தது.',
      'ph_salk_advice': 'குறைந்த காரத்தன்மை – ஜிப்சம் (ஏக்கருக்கு 100 கிலோ) அல்லது உரம் இடவும்.',
      'ph_salk_strong_advice': 'அதிக காரத்தன்மை – ஜிப்சம் (200 கிலோ) மற்றும் தொழு உரம் இடவும்.',
      'oc_low_advice': 'கரிம கார்பனை அதிகரிக்க தொழு உரம்/மண்புழு உரம் (2.5 டன்) இடவும்.',
      'oc_med_advice': 'மிதமான கரிம வளம். பசுந்தாள் உரப்பயிர்களை பயிரிடவும்.',
      'oc_high_advice': 'சிறந்த கரிம வளம். பயிர் கழிவு சுழற்சியை தொடரவும்.',
      'moist_low_advice': 'ஈரப்பதம் குறைவு. சொட்டு நீர் பாசனம் மற்றும் மூடாக்கு பயன்படுத்தவும்.',
      'moist_med_advice': 'ஈரப்பதம் உகந்த அளவில் உள்ளது. சீரான பாசனம் செய்யவும்.',
      'moist_high_advice': 'அதிக ஈரப்பதம். வேர் அழுகலை தடுக்க வடிகால் வசதி செய்யவும்.',
    },
    AppLanguage.hindi: {
      'excellent': 'उत्कृष्ट स्वास्थ्य',
      'good': 'अच्छा स्वास्थ्य',
      'fair': 'सामान्य स्वास्थ्य',
      'poor': 'कमजोर स्वास्थ्य',
      'low': 'निम्न',
      'medium': 'मध्यम',
      'high': 'उच्च',
      'ph_strongly_acidic': 'अत्यधिक अम्लीय',
      'ph_slightly_acidic': 'हल्का अम्लीय',
      'ph_neutral': 'उदासीन',
      'ph_slightly_alkaline': 'हल्का क्षारीय',
      'ph_strongly_alkaline': 'अत्यधिक क्षारीय',
      'oc_deficient': 'न्यून',
      'oc_moderate': 'मध्यम',
      'oc_healthy': 'स्वस्थ/उच्च',
      'moist_dry': 'सूखा',
      'moist_optimal': 'अनुकूल',
      'moist_wet': 'अधिक गीला',
      'n_low_advice': 'यूरिया (50 किलो/एकड़) विभाजित मात्रा में डालें या दलहन बोएं।',
      'n_med_advice': 'नाइट्रोजन अनुकूल है। गोबर की खाद से स्तर बनाए रखें।',
      'n_high_advice': 'नाइट्रोजन प्रचुर है। अतिरिक्त नाइट्रोजन उर्वरक न डालें।',
      'p_low_advice': 'सिंगल सुपर फॉस्फेट (SSP) या डीएपी बुनियादी खुराक के रूप में डालें।',
      'p_med_advice': 'फॉस्फोरस अनुकूल है। सामान्य बुनियादी खुराक जारी रखें।',
      'p_high_advice': 'फॉस्फोरस पर्याप्त है। लागत बचाने के लिए अतिरिक्त फॉस्फेट न डालें।',
      'k_low_advice': 'पोटैशियम बढ़ाने के लिए म्यूटिएट ऑफ पोटाश (MOP) डालें।',
      'k_med_advice': 'पोटाश स्तर पर्याप्त है। सामान्य कृषि पद्धतियां जारी रखें।',
      'k_high_advice': 'पोटाश प्रचुर मात्रा में है। इस चक्र में अतिरिक्त MOP न डालें।',
      'ph_sa_advice': 'पीएच बढ़ाने के लिए कृषि चूना/डोलोमाइट (200 किलो/एकड़) डालें।',
      'ph_sia_advice': 'हल्का अम्लीय – कपास, आलू, मूंगफली के लिए आदर्श।',
      'ph_neu_advice': 'उदासीन मिट्टी – धान, गेहूं, सब्जियों के लिए सर्वोत्तम।',
      'ph_salk_advice': 'हल्का क्षारीय – जिप्सम (100 किलो/एकड़) या कंपोस्ट डालें।',
      'ph_salk_strong_advice': 'अत्यधिक क्षारीय – जिप्सम (200 किलो/एकड़) और जैविक खाद डालें।',
      'oc_low_advice': 'जैविक कार्बन बढ़ाने के लिए गोबर की खाद/वर्मीकंपोस्ट (2.5 टन/एकड़) डालें।',
      'oc_med_advice': 'मध्यम कार्बन। हरी खाद वाली फसलों के साथ चक्र अपनाएं।',
      'oc_high_advice': 'उत्कृष्ट जैविक कार्बन। फसल अवशेषों को मिट्टी में मिलाएं।',
      'moist_low_advice': 'नमी कम है। ड्रिप सिंचाई और मल्चिंग (पल्वराइजेशन) का उपयोग करें।',
      'moist_med_advice': 'नमी अनुकूल है। सामान्य सिंचाई जारी रखें।',
      'moist_high_advice': 'अत्यधिक नमी। जड़ सड़न से बचने के लिए जल निकासी सुनिश्चित करें।',
    },
    AppLanguage.kannada: {
      'excellent': 'ಉತ್ತಮ ಮಣ್ಣಿನ ಆರೋಗ್ಯ',
      'good': 'ಒಳ್ಳೆಯ ಮಣ್ಣಿನ ಆರೋಗ್ಯ',
      'fair': 'ಸಾಧಾರಣ ಮಣ್ಣಿನ ಆರೋಗ್ಯ',
      'poor': 'ಕಡಿಮೆ ಮಣ್ಣಿನ ಆರೋಗ್ಯ',
      'low': 'ಕಡಿಮೆ',
      'medium': 'ಮಧ್ಯಮ',
      'high': 'ಹೆಚ್ಚು',
      'ph_strongly_acidic': 'ತೀವ್ರ ಆಮ್ಲೀಯ',
      'ph_slightly_acidic': 'ಸ್ವಲ್ಪ ಆಮ್ಲೀಯ',
      'ph_neutral': 'ತಟಸ್ಥ',
      'ph_slightly_alkaline': 'ಸ್ವಲ್ಪ ಕ್ಷಾರೀಯ',
      'ph_strongly_alkaline': 'ತೀವ್ರ ಕ್ಷಾರೀಯ',
      'oc_deficient': 'ಕೊರತೆ',
      'oc_moderate': 'ಮಧ್ಯಮ',
      'oc_healthy': 'ಆರೋಗ್ಯಕರ',
      'moist_dry': 'ಒಣ ಮಣ್ಣು',
      'moist_optimal': 'ಸೂಕ್ತ',
      'moist_wet': 'ಹೆಚ್ಚು ತೇವಾಂಶ',
      'n_low_advice': 'ಯೂರಿಯಾ (ಎಕರೆಗೆ 50 ಕೆಜಿ) ಹಂತ ಹಂತವಾಗಿ ಹಾಕಿ ಅಥವಾ ದ್ವಿದಳ ಧಾನ್ಯ ಬೆಳೆಯಿರಿ.',
      'n_med_advice': 'ಸಾರಜನಕ ಸೂಕ್ತವಾಗಿದೆ. ಕೊಟ್ಟಿಗೆ ಗೊಬ್ಬರದೊಂದಿಗೆ ನಿರ್ವಹಣೆ ಮಾಡಿ.',
      'n_high_advice': 'ಸಾರಜನಕ ಹೇರಳವಾಗಿದೆ. ಹೆಚ್ಚಿನ ಸಾರಜನಕ ಗೊಬ್ಬರ ಬೇಡ.',
      'p_low_advice': 'ಸಿಂಗಲ್ ಸೂಪರ್ ಫಾಸ್ಫೇಟ್ (SSP) ಅಥವಾ DAP ಯನ್ನು ತಳ ಗೊಬ್ಬರವಾಗಿ ಹಾಕಿ.',
      'p_med_advice': 'ರಂಜಕ ಸೂಕ್ತವಾಗಿದೆ. ಪ್ರಸ್ತುತ ಪ್ರಮಾಣ ಮುಂದುವರಿಸಿ.',
      'p_high_advice': 'ರಂಜಕ ಸಾಕಷ್ಟಿದೆ. ವೆಚ್ಚ ಉಳಿಸಲು ಫಾಸ್ಫೇಟ್ ಗೊಬ್ಬರ ನಿಲ್ಲಿಸಿ.',
      'k_low_advice': 'ಪೊಟ್ಯಾಶ್ ಹೆಚ್ಚಿಸಲು ಮ್ಯೂರಿಯೇಟ್ ಆಫ್ ಪೊಟ್ಯಾಶ್ (MOP) ಬಳಸಿ.',
      'k_med_advice': 'ಪೊಟ್ಯಾಶಿಯಂ ಮಟ್ಟ ತೃಪ್ತಿಕರವಾಗಿದೆ.',
      'k_high_advice': 'ಪೊಟ್ಯಾಶಿಯಂ ಹೇರಳವಾಗಿದೆ. ಈ ಅವಧಿಗೆ ಹೆಚ್ಚಿನ MOP ಬೇಡ.',
      'ph_sa_advice': 'ಆಮ್ಲೀಯತೆ ಕಡಿಮೆ ಮಾಡಲು ಕೃಷಿ ಸುಣ್ಣ (ಎಕರೆಗೆ 200 ಕೆಜಿ) ಹಾಕಿ.',
      'ph_sia_advice': 'ಸ್ವಲ್ಪ ಆಮ್ಲೀಯ – ಹತ್ತಿ, ಆಲೂಗಡ್ಡೆ, ಶೇಂಗಾ ಬೆಳೆಗೆ ಸೂಕ್ತ.',
      'ph_neu_advice': 'ತಟಸ್ಥ ಮಣ್ಣು – ಭತ್ತ, ಗೋಧಿ, ತರಕಾರಿಗಳಿಗೆ ಉತ್ತಮ.',
      'ph_salk_advice': 'ಸ್ವಲ್ಪ ಕ್ಷಾರೀಯ – ಜಿಪ್ಸಮ್ (ಎಕರೆಗೆ 100 ಕೆಜಿ) ಅಥವಾ ಕಾಂಪೋಸ್ಟ್ ಹಾಕಿ.',
      'ph_salk_strong_advice': 'ತೀವ್ರ ಕ್ಷಾರೀಯ – ಜಿಪ್ಸಮ್ (200 ಕೆಜಿ) ಮತ್ತು ಕೊಟ್ಟಿಗೆ ಗೊಬ್ಬರ ಬಳಸಿ.',
      'oc_low_advice': 'ಕರಿಬನ ಹೆಚ್ಚಿಸಲು ಕೊಟ್ಟಿಗೆ ಗೊಬ್ಬರ/ವರ್ಮಿಕಾಂಪೋಸ್ಟ್ (2.5 ಟನ್) ಹಾಕಿ.',
      'oc_med_advice': 'ಮಧ್ಯಮ ಕರಿಬನ. ಹಸಿರು ಗೊಬ್ಬರದ ಬೆಳೆಗಳನ್ನು ಬೆಳೆಯಿರಿ.',
      'oc_high_advice': 'ಉತ್ತಮ ಕರಿಬನವಿದೆ. ಬೆಳೆ ತ್ಯಾಜ್ಯಗಳನ್ನು ಮಣ್ಣಿನಲ್ಲಿಯೇ ಕೊಳೆಸಿ.',
      'moist_low_advice': 'ತೇವಾಂಶ ಕಡಿಮೆ ಇದೆ. ಹನಿ ನೀರಾವರಿ ಮತ್ತು ಹೊದಿಕೆ (ಮಲ್ಚಿಂಗ್) ಬಳಸಿ.',
      'moist_med_advice': 'ತೇವಾಂಶ ಸೂಕ್ತವಾಗಿದೆ. ಅಗತ್ಯವಿದ್ದಾಗ ನೀರುಣಿಸಿ.',
      'moist_high_advice': 'ಹೆಚ್ಚಿನ ತೇವಾಂಶ. ಬೇರು ಕೊಳೆತ ತಡೆಯಲು ಬಸಿಕಾಲುವೆ ವ್ಯವಸ್ಥೆ ಮಾಡಿ.',
    },
    AppLanguage.malayalam: {
      'excellent': 'മികച്ച മണ്ണു വായു',
      'good': 'നല്ല മണ്ണു വായു',
      'fair': 'മിതമായ മണ്ണു വായു',
      'poor': 'കുറഞ്ഞ മണ്ണു വായു',
      'low': 'കുറവ്',
      'medium': 'മിതമായത്',
      'high': 'കൂടുതൽ',
      'ph_strongly_acidic': 'അതിശക്തമായ അമ്ലഗുണം',
      'ph_slightly_acidic': 'മിതമായ അമ്ലഗുണം',
      'ph_neutral': 'നിഷ്പക്ഷത (ന്യൂട്രൽ)',
      'ph_slightly_alkaline': 'മിതമായ ക്ഷാരഗുണം',
      'ph_strongly_alkaline': 'അതിശക്തമായ ക്ഷാരഗുണം',
      'oc_deficient': 'കുറവ്',
      'oc_moderate': 'മിതമായത്',
      'oc_healthy': 'ആരോഗ്യകരം',
      'moist_dry': 'വരണ്ടത്',
      'moist_optimal': 'അനുയോജ്യം',
      'moist_wet': 'കൂടിയ ഈർപ്പം',
      'n_low_advice': 'യൂറിയ (ഏക്കറിന് 50 കിലോ) തവണകളായി നൽകുക അല്ലെങ്കിൽ പയറുവർഗ്ഗങ്ങൾ കൃഷിചെയ്യുക.',
      'n_med_advice': 'നൈട്രജൻ അനുയോജ്യമായ അളവിലാണ്. ജൈവവളം ചേർക്കുക.',
      'n_high_advice': 'നൈട്രജൻ വളരെ കൂടുതലാണ്. നൈട്രജൻ വളങ്ങൾ ഒഴിവാക്കുക.',
      'p_low_advice': 'അടിവളമായി സിംഗിൾ സൂപ്പർ ഫോസ്ഫേറ്റ് (SSP) അല്ലെങ്കിൽ ഡി.എ.പി നൽകുക.',
      'p_med_advice': 'ഫോസ്ഫറസ് ആവശ്യത്തിന് ഉണ്ട്. നിലവിലെ അളവ് തുടരുക.',
      'p_high_advice': 'ഫോസ്ഫറസ് കൂടുതലാണ്. ഫോസ്ഫേറ്റ് വളങ്ങൾ നൽകേണ്ടതില്ല.',
      'k_low_advice': 'പൊട്ടാഷ് അളവ് കൂട്ടാൻ മ്യൂറിയേറ്റ് ഓഫ് പൊട്ടാഷ് (MOP) ചേർക്കുക.',
      'k_med_advice': 'പൊട്ടാസ്യം അളവ് അനുയോജ്യമാണ്. സാധാരണ പരിചരണം മതി.',
      'k_high_advice': 'പൊട്ടാസ്യം കൂടുതലായതിനാൽ ഈ കൃഷിയിൽ MOP ഒഴിവാക്കുക.',
      'ph_sa_advice': 'അമ്ലത കുറയ്ക്കാൻ കൃഷിചുണ്ണാമ്പ് (ഏക്കറിന് 200 കിലോ) ചേർക്കുക.',
      'ph_sia_advice': 'മിതമായ അമ്ലത – പരുത്തി, ഉരുളക്കിഴങ്ങ്, നിലക്കടല എന്നിവയ്ക്ക് അനുയോജ്യം.',
      'ph_neu_advice': 'ന്യൂട്രൽ മണ്ണ് – നെല്ല്, ഗോതമ്പ്, പച്ചക്കറികൾ എന്നിവയ്ക്ക് ഉത്തമം.',
      'ph_salk_advice': 'മിതമായ ക്ഷാരത – ജിപ്സം (ഏക്കറിന് 100 കിലോ) അല്ലെങ്കിൽ കമ്പോസ്റ്റ് ചേർക്കുക.',
      'ph_salk_strong_advice': 'അതിശക്തമായ ക്ഷാരത – ജിപ്സം (200 കിലോ) ജൈവവളത്തോടൊപ്പം ചേർക്കുക.',
      'oc_low_advice': 'കരിമണ്ണ് കൂട്ടാൻ ജൈവവളം/കമ്പോസ്റ്റ് (2.5 ടൺ) ചേർക്കുക.',
      'oc_med_advice': 'മിതമായ ജൈവവളം. പച്ചില വളവിളകൾ കൃഷി ചെയ്യുക.',
      'oc_high_advice': 'മികച്ച ജൈവവളം. കൃഷി അവശിഷ്ടങ്ങൾ മണ്ണിൽ ചേർക്കുന്നത് തുടരുക.',
      'moist_low_advice': 'ഈർപ്പം കുറവാണ്. തുള്ളിനനയും പുതയിടലും ഉപയോഗിക്കുക.',
      'moist_med_advice': 'ഈർപ്പം ആവശ്യത്തിന് ഉണ്ട്. ക്രമമായി നനയ്ക്കുക.',
      'moist_high_advice': 'കൂടിയ ഈർപ്പം. വേരഴുകൽ തടയാൻ കൃത്യമായ ഓടകൾ നിർമ്മിക്കുക.',
    },
  };

  static String _getText(String key, AppLanguage lang) {
    final map = _localizedEngine[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedEngine[AppLanguage.english]![key]!;
  }

  static SoilAnalysisResult analyze({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double pH,
    required double organicCarbon,
    required double moisture,
    required AppLanguage language,
  }) {
    // 1. Evaluate pH
    int phScore = 50;
    String phLabel = '';
    String phAdvisory = '';

    if (pH < 5.5) {
      phScore = 50;
      phLabel = _getText('ph_strongly_acidic', language);
      phAdvisory = _getText('ph_sa_advice', language);
    } else if (pH >= 5.5 && pH < 6.5) {
      phScore = 85;
      phLabel = _getText('ph_slightly_acidic', language);
      phAdvisory = _getText('ph_sia_advice', language);
    } else if (pH >= 6.5 && pH <= 7.5) {
      phScore = 100;
      phLabel = _getText('ph_neutral', language);
      phAdvisory = _getText('ph_neu_advice', language);
    } else if (pH > 7.5 && pH <= 8.5) {
      phScore = 85;
      phLabel = _getText('ph_slightly_alkaline', language);
      phAdvisory = _getText('ph_salk_advice', language);
    } else {
      phScore = 50;
      phLabel = _getText('ph_strongly_alkaline', language);
      phAdvisory = _getText('ph_salk_strong_advice', language);
    }

    // 2. Evaluate Nutrients
    int nScore = 40;
    String nLabel = '';
    String nAdvice = '';
    Color nColor = Colors.redAccent;
    if (nitrogen < 280) {
      nScore = 40;
      nLabel = _getText('low', language);
      nAdvice = _getText('n_low_advice', language);
      nColor = Colors.redAccent; // Deficient = Red
    } else if (nitrogen >= 280 && nitrogen <= 560) {
      nScore = 85;
      nLabel = _getText('medium', language);
      nAdvice = _getText('n_med_advice', language);
      nColor = AppTheme.accentGold; // Medium = Yellow/Amber
    } else {
      nScore = 100;
      nLabel = _getText('high', language);
      nAdvice = _getText('n_high_advice', language);
      nColor = AppTheme.primaryGreen; // Good = Green
    }

    int pScore = 40;
    String pLabel = '';
    String pAdvice = '';
    Color pColor = Colors.redAccent;
    if (phosphorus < 10) {
      pScore = 40;
      pLabel = _getText('low', language);
      pAdvice = _getText('p_low_advice', language);
      pColor = Colors.redAccent;
    } else if (phosphorus >= 10 && phosphorus <= 25) {
      pScore = 85;
      pLabel = _getText('medium', language);
      pAdvice = _getText('p_med_advice', language);
      pColor = AppTheme.accentGold;
    } else {
      pScore = 100;
      pLabel = _getText('high', language);
      pAdvice = _getText('p_high_advice', language);
      pColor = AppTheme.primaryGreen;
    }

    int kScore = 40;
    String kLabel = '';
    String kAdvice = '';
    Color kColor = Colors.redAccent;
    if (potassium < 120) {
      kScore = 40;
      kLabel = _getText('low', language);
      kAdvice = _getText('k_low_advice', language);
      kColor = Colors.redAccent;
    } else if (potassium >= 120 && potassium <= 280) {
      kScore = 85;
      kLabel = _getText('medium', language);
      kAdvice = _getText('k_med_advice', language);
      kColor = AppTheme.accentGold;
    } else {
      kScore = 100;
      kLabel = _getText('high', language);
      kAdvice = _getText('k_high_advice', language);
      kColor = AppTheme.primaryGreen;
    }

    // 3. Evaluate Organic Carbon
    int ocScore = 40;
    String ocLabel = '';
    String ocAdvisory = '';
    if (organicCarbon < 0.5) {
      ocScore = 40;
      ocLabel = _getText('oc_deficient', language);
      ocAdvisory = _getText('oc_low_advice', language);
    } else if (organicCarbon >= 0.5 && organicCarbon <= 0.75) {
      ocScore = 85;
      ocLabel = _getText('oc_moderate', language);
      ocAdvisory = _getText('oc_med_advice', language);
    } else {
      ocScore = 100;
      ocLabel = _getText('oc_healthy', language);
      ocAdvisory = _getText('oc_high_advice', language);
    }

    // 4. Evaluate Moisture
    int moistScore = 50;
    String moistLabel = '';
    String moistAdvisory = '';
    if (moisture < 20) {
      moistScore = 50;
      moistLabel = _getText('moist_dry', language);
      moistAdvisory = _getText('moist_low_advice', language);
    } else if (moisture >= 20 && moisture <= 40) {
      moistScore = 100;
      moistLabel = _getText('moist_optimal', language);
      moistAdvisory = _getText('moist_med_advice', language);
    } else {
      moistScore = 70;
      moistLabel = _getText('moist_wet', language);
      moistAdvisory = _getText('moist_high_advice', language);
    }

    // Calculate score
    final double calculatedScore = (phScore * 0.15) +
        (nScore * 0.20) +
        (pScore * 0.20) +
        (kScore * 0.20) +
        (ocScore * 0.15) +
        (moistScore * 0.10);

    // Score Categories
    String scoreCategory = '';
    Color scoreColor = Colors.redAccent;
    if (calculatedScore >= 90) {
      scoreCategory = _getText('excellent', language);
      scoreColor = AppTheme.primaryGreen;
    } else if (calculatedScore >= 75) {
      scoreCategory = _getText('good', language);
      scoreColor = Colors.green[600]!;
    } else if (calculatedScore >= 60) {
      scoreCategory = _getText('fair', language);
      scoreColor = AppTheme.accentGold;
    } else {
      scoreCategory = _getText('poor', language);
      scoreColor = Colors.redAccent;
    }

    // Dynamic Advisories
    final List<String> advisories = [];
    final List<String> fertilizerSuggestions = [];
    final List<String> irrigationSuggestions = [];

    // Add advisories based on deficiencies
    if (nitrogen < 280) {
      advisories.add(nAdvice);
      fertilizerSuggestions.add('Urea: 50 kg/acre');
    }
    if (phosphorus < 10) {
      advisories.add(pAdvice);
      fertilizerSuggestions.add('DAP/SSP: 40 kg/acre');
    }
    if (potassium < 120) {
      advisories.add(kAdvice);
      fertilizerSuggestions.add('MOP (Potash): 25 kg/acre');
    }
    if (organicCarbon < 0.5) {
      advisories.add(ocAdvisory);
      fertilizerSuggestions.add('Compost/FYM: 2.5 tons/acre');
    }
    if (moisture < 20) {
      advisories.add(moistAdvisory);
      irrigationSuggestions.add('Drip Irrigation scheduling (alternate days)');
      irrigationSuggestions.add('Mulch with crop straw (2 tons/acre)');
    } else if (moisture > 40) {
      advisories.add(moistAdvisory);
      irrigationSuggestions.add('Create deep drainage channels to prevent water logging');
    } else {
      irrigationSuggestions.add('Standard irrigation (once in 4-6 days)');
    }

    // Default general advice if clean
    if (advisories.isEmpty) {
      advisories.add('Maintain soil structure with organic manuring.');
    }
    if (fertilizerSuggestions.isEmpty) {
      fertilizerSuggestions.add('No chemical corrections needed. Maintain organic mulch.');
    }

    // Dynamic Crops Suggestions
    final List<String> cropSuggestions = [];
    if (pH < 6.0) {
      cropSuggestions.addAll(['Potato', 'Oats', 'Groundnut', 'Sweet Potato']);
    } else if (pH >= 6.0 && pH <= 7.5) {
      cropSuggestions.addAll(['Paddy (Rice)', 'Cotton', 'Wheat', 'Maize', 'Soybean', 'Tomato']);
    } else {
      cropSuggestions.addAll(['Barley', 'Mustard', 'Sorghum', 'Garlic']);
    }

    // Nitrogen fixers suggestions if soil N is low
    if (nitrogen < 280 && !cropSuggestions.contains('Soybean')) {
      cropSuggestions.add('Pulses/Soybean (nitrogen fixers)');
    }

    return SoilAnalysisResult(
      score: calculatedScore,
      scoreCategory: scoreCategory,
      scoreColor: scoreColor,
      pHLabel: phLabel,
      pHAdvisory: phAdvisory,
      organicCarbonLabel: ocLabel,
      organicCarbonAdvisory: ocAdvisory,
      moistureLabel: moistLabel,
      moistureAdvisory: moistAdvisory,
      cropSuggestions: cropSuggestions,
      fertilizerSuggestions: fertilizerSuggestions,
      irrigationSuggestions: irrigationSuggestions,
      advisories: advisories,
      nutrients: {
        'N': NutrientStatus(
          label: nLabel,
          percent: ((nitrogen / 700.0) * 100).clamp(10, 100).toInt(),
          color: nColor,
          advice: nAdvice,
        ),
        'P': NutrientStatus(
          label: pLabel,
          percent: ((phosphorus / 35.0) * 100).clamp(10, 100).toInt(),
          color: pColor,
          advice: pAdvice,
        ),
        'K': NutrientStatus(
          label: kLabel,
          percent: ((potassium / 350.0) * 100).clamp(10, 100).toInt(),
          color: kColor,
          advice: kAdvice,
        ),
      },
    );
  }
}
