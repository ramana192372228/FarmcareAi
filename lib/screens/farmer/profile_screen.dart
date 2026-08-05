import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/auth_service.dart';
import '../role_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final Map<AppLanguage, Map<String, String>> _localizedProfile = {
    AppLanguage.english: {
      'acc_info': 'Account Credentials',
      'name': 'Name: Nayak Kumar',
      'phone': 'Mobile: +91 9876543210',
      'role': 'Active Profile: Farmer',
      'joined': 'Member Since: May 2026',
      'lang_setting': 'App Language Preference',
      'switch_role_btn': 'Switch Portal Profile',
      'signout_btn': 'Log Out',
    },
    AppLanguage.telugu: {
      'acc_info': 'ఖాతా వివరాలు',
      'name': 'పేరు: నాయక్ కుమార్',
      'phone': 'మొబైల్: +91 9876543210',
      'role': 'కార్యాచరణ పాత్ర: రైతు',
      'joined': 'సభ్యత్వం పొందిన తేది: మే 2026',
      'lang_setting': 'యాప్ భాషా ఎంపిక',
      'switch_role_btn': 'వేరే పాత్రకు మారండి',
      'signout_btn': 'లాగ్ అవుట్',
    },
    AppLanguage.tamil: {
      'acc_info': 'கணக்கு விவரங்கள்',
      'name': 'பெயர்: நாயக் குமார்',
      'phone': 'மொபைல்: +91 9876543210',
      'role': 'செயலில் உள்ள சுயவிவரம்: விவசாயி',
      'joined': 'உறுப்பினர் சேர்க்கை: மே 2026',
      'lang_setting': 'செயலி மொழி விருப்பம்',
      'switch_role_btn': 'சுயவிவரப் பாத்திரத்தை மாற்று',
      'signout_btn': 'வெளியேறு',
    },
    AppLanguage.hindi: {
      'acc_info': 'खाता विवरण',
      'name': 'नाम: नायक कुमार',
      'phone': 'मोबाइल: +91 9876543210',
      'role': 'सक्रिय प्रोफ़ाइल: किसान',
      'joined': 'सदस्यता तिथि: मई 2026',
      'lang_setting': 'ऐप भाषा वरीयता',
      'switch_role_btn': 'प्रोफ़ाइल बदलें',
      'signout_btn': 'लॉग आउट',
    },
    AppLanguage.kannada: {
      'acc_info': 'ಖಾತೆ ವಿವರಗಳು',
      'name': 'ಹೆಸರು: ನಾಯಕ್ ಕುಮಾರ್',
      'phone': 'ಮೊಬೈಲ್: +91 9876543210',
      'role': 'ಸಕ್ರಿಯ ಪ್ರೊಫೈಲ್: ರೈತ',
      'joined': 'ಸದಸ್ಯತ್ವದ ದಿನಾಂಕ: ಮೇ 2026',
      'lang_setting': 'ಆ್ಯಪ್ ಭಾಷಾ ಆದ್ಯತೆ',
      'switch_role_btn': 'ಪಾತ್ರವನ್ನು ಬದಲಾಯಿಸಿ',
      'signout_btn': 'ಲಾಗ್ ಔಟ್',
    },
    AppLanguage.malayalam: {
      'acc_info': 'അക്കൗണ്ട് വിവരങ്ങൾ',
      'name': 'പേര്: നായക് കുമാർ',
      'phone': 'മൊബൈൽ: +91 9876543210',
      'role': 'സജീവ പ്രൊഫൈൽ: കർഷകൻ',
      'joined': 'അംഗത്വം നേടിയത്: മെയ് 2026',
      'lang_setting': 'ഭാഷ തിരഞ്ഞെടുക്കൽ',
      'switch_role_btn': 'പ്രൊഫൈൽ മാറ്റുക',
      'signout_btn': 'ലോഗ് ഔട്ട്',
    },
  };

  String _getText(String key) {
    final lang = TranslationService().currentLanguage;
    final map = _localizedProfile[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedProfile[AppLanguage.english]![key]!;
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();

    final List<Map<String, dynamic>> languagesDropdown = [
      {'name': 'English', 'value': AppLanguage.english},
      {'name': 'తెలుగు (Telugu)', 'value': AppLanguage.telugu},
      {'name': 'தமிழ் (Tamil)', 'value': AppLanguage.tamil},
      {'name': 'हिन्दी (Hindi)', 'value': AppLanguage.hindi},
      {'name': 'ಕನ್ನಡ (Kannada)', 'value': AppLanguage.kannada},
      {'name': 'മലയാളം (Malayalam)', 'value': AppLanguage.malayalam},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('profile')),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Account Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getText('acc_info'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      const Divider(height: 24),
                      _buildProfileRow(Icons.person_rounded, _getText('name')),
                      _buildProfileRow(Icons.phone_iphone_rounded, _getText('phone')),
                      _buildProfileRow(Icons.verified_user_rounded, _getText('role')),
                      _buildProfileRow(Icons.date_range_rounded, _getText('joined')),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Language Preference Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getText('lang_setting'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      const Divider(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AppLanguage>(
                            value: trans.currentLanguage,
                            isExpanded: true,
                            icon: const Icon(Icons.translate_rounded, color: AppTheme.primaryGreen),
                            onChanged: (AppLanguage? newLang) {
                              if (newLang != null) {
                                setState(() {
                                  trans.setLanguage(newLang);
                                });
                                debugPrint('[USER_PROFILE] Dynamic Language synced globally: ${newLang.name}');
                              }
                            },
                            items: languagesDropdown.map<DropdownMenuItem<AppLanguage>>((Map<String, dynamic> entry) {
                              return DropdownMenuItem<AppLanguage>(
                                value: entry['value'],
                                child: Text(entry['name']),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 3. Actions Panel (Switch Role, Switch Google Account, Logout)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await AuthService().logout();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const RoleScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.swap_horizontal_circle_rounded, color: Colors.white),
                    label: Text(_getText('switch_role_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await AuthService().switchGoogleAccount();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const RoleScreen()),
                        (route) => false,
                      );
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Switched Google account session.')),
                      );
                    },
                    icon: const Icon(Icons.account_circle_outlined, color: Colors.blueAccent),
                    label: const Text('Switch Google Account', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await AuthService().logout();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const RoleScreen()),
                        (route) => false,
                      );
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Logged out successfully.')),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: Text(_getText('signout_btn'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
