import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../services/auth_service.dart';
import 'scanner_screen.dart';
import 'farmer/weather_screen.dart';
import 'farmer/marketplace_screen.dart';
import 'farmer/community_screen.dart';
import 'farmer/profile_screen.dart';
import 'farmer/crop_planning_screen.dart';
import 'farmer/my_farm_screen.dart';
import 'farmer/fertilizer_screen.dart';
import 'farmer/soil_health_screen.dart';
import 'farmer/schemes_screen.dart';
import 'farmer/machinery_screen.dart';
import 'farmer/key_contacts_screen.dart';
import 'farmer/notifications_screen.dart';
import 'farmer/ai_agronomist_screen.dart';

import '../widgets/web_layout_shell.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  // My Farm inline summary data
  String? _myFarmCrop;
  String? _myFarmAcres;
  String? _myFarmHarvest;
  String? _userName;
  int _unreadNotifs = 3;

  // Market prices (static demo data – inline band)
  final List<Map<String, dynamic>> _marketPrices = [
    {'crop': 'Cotton', 'price': '₹6,560', 'unit': '/q', 'trend': 1, 'change': '+₹320'},
    {'crop': 'Rice', 'price': '₹2,183', 'unit': '/q', 'trend': 0, 'change': 'Stable'},
    {'crop': 'Tomato', 'price': '₹18', 'unit': '/kg', 'trend': 1, 'change': '+₹2.5'},
    {'crop': 'Maize', 'price': '₹1,890', 'unit': '/q', 'trend': -1, 'change': '-₹42'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFarmSummary();
  }

  Future<void> _loadFarmSummary() async {
    final auth = AuthService();
    final userId = await auth.getLoggedUserPhone();
    final profile = userId != null ? await auth.getUserProfile(userId) : null;
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'my_farm_$userId';
      final crop = prefs.getString('${key}_crop');
      final acres = prefs.getString('${key}_acres');
      final sowingMs = prefs.getInt('${key}_sowing');
      String? harvestEst;
      if (crop != null && sowingMs != null) {
        final sow = DateTime.fromMillisecondsSinceEpoch(sowingMs);
        final days = _harvestDays(crop);
        final hDate = sow.add(Duration(days: days));
        harvestEst = 'Est. Harvest: ${_fmt(hDate)}';
      }
      if (mounted) {
        setState(() {
          _myFarmCrop = crop;
          _myFarmAcres = acres;
          _myFarmHarvest = harvestEst;
          _userName = profile?.name;
        });
      }
    }
  }

  int _harvestDays(String crop) {
    switch (crop) {
      case 'Rice': return 120;
      case 'Wheat': return 125;
      case 'Tomato': return 90;
      case 'Maize': return 100;
      default: return 135;
    }
  }

  String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  void _navigate(Widget screen) {
    TtsService.stop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _navigateWithReload(Widget screen) {
    TtsService.stop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _loadFarmSummary());
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();
    final greeting = _userName != null ? 'Welcome, $_userName!' : 'Welcome, Farmer!';
    const tagline = 'Your complete agricultural companion';

    final content = Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: _loadFarmSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 3),
                          Text(tagline, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded, size: 28, color: AppTheme.primaryGreen),
                          onPressed: () {
                            setState(() => _unreadNotifs = 0);
                            _navigate(const NotificationsScreen());
                          },
                        ),
                        if (_unreadNotifs > 0)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                              child: Center(child: Text('$_unreadNotifs', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle_rounded, size: 32, color: AppTheme.primaryGreen),
                      onPressed: () => _navigate(const FarmerProfileScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── WEATHER MINI CARD ───────────────────────────────
                GestureDetector(
                  onTap: () => _navigate(const WeatherScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 38),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('32°C · Mostly Sunny', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 3),
                              Text('Humidity 65% · Wind 12 km/h · Soil Moisture 42%', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                              const SizedBox(height: 3),
                              const Text('⚠️ Rain expected Wednesday. Avoid spraying.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── MARKET PRICES BAND ──────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Live APMC Rates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                          GestureDetector(
                            onTap: () => _navigate(const MarketplaceScreen()),
                            child: const Text('View All →', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('Updated: today 9:00 AM', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      const SizedBox(height: 12),
                      Row(
                        children: _marketPrices.map((m) => Expanded(child: _priceChip(m))).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── MY FARM SUMMARY CARD ────────────────────────────
                GestureDetector(
                  onTap: () => _navigateWithReload(const MyFarmScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.agriculture_rounded, color: Colors.white, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _myFarmCrop != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('My Farm', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                                    Text(_myFarmCrop!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 3),
                                    Text('${_myFarmAcres ?? '?'} Acres  ·  ${_myFarmHarvest ?? ''}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('My Farm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text('Set up your farm to get personalized schedules and harvest estimates.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                  ],
                                ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── SERVICES GRID TITLE ─────────────────────────────
                const Text('FARMING SERVICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.5)),
                const SizedBox(height: 14),

                // ── 12-TILE SERVICES GRID ───────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.12,
                  children: [
                    _serviceCard(
                      icon: Icons.camera_enhance_rounded,
                      title: trans.translate('scanner') != 'scanner' ? trans.translate('scanner') : 'Pest & Disease\nDetection',
                      color: AppTheme.primaryGreen,
                      label: 'AI Powered',
                      onTap: () => _navigate(const ScannerScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.wb_sunny_rounded,
                      title: 'Weather\nForecast',
                      color: Colors.blue,
                      label: '7-Day',
                      onTap: () => _navigate(const WeatherScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Crop\nPlanning',
                      color: Colors.blueAccent,
                      label: 'Schedules',
                      onTap: () => _navigate(const CropPlanningScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.storefront_rounded,
                      title: 'Market\nPrices',
                      color: AppTheme.accentGold,
                      label: 'Buy & Sell',
                      onTap: () => _navigate(const MarketplaceScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.science_rounded,
                      title: 'Fertilizer\nRecommendation',
                      color: Colors.green,
                      label: 'NPK Guide',
                      onTap: () => _navigate(const FertilizerScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.landscape_rounded,
                      title: 'Soil Health\nInformation',
                      color: Colors.brown,
                      label: 'pH & NPK',
                      onTap: () => _navigate(const SoilHealthScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.account_balance_rounded,
                      title: 'Schemes &\nBenefits',
                      color: Colors.purple,
                      label: '8 Schemes',
                      onTap: () => _navigate(const SchemesScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.agriculture_rounded,
                      title: 'Farm Machinery\nBooking',
                      color: Colors.orange,
                      label: 'Rent & Book',
                      onTap: () => _navigate(const MachineryScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.contact_phone_rounded,
                      title: 'Key\nContacts',
                      color: Colors.teal,
                      label: 'Helplines',
                      onTap: () => _navigate(const KeyContactsScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.home_rounded,
                      title: 'My\nFarm',
                      color: AppTheme.primaryGreen,
                      label: 'Farm Profile',
                      onTap: () => _navigateWithReload(const MyFarmScreen()),
                    ),
                    _serviceCard(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      color: Colors.redAccent,
                      label: _unreadNotifs > 0 ? '$_unreadNotifs New' : 'All clear',
                      onTap: () {
                        setState(() => _unreadNotifs = 0);
                        _navigate(const NotificationsScreen());
                      },
                    ),
                    _serviceCard(
                      icon: Icons.smart_toy_rounded,
                      title: 'AI\nAgronomist',
                      color: Colors.indigo,
                      label: 'Chat & Voice',
                      onTap: () => _navigate(const AiAgronomistScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── COMMUNITY SHORTCUT ──────────────────────────────
                GestureDetector(
                  onTap: () => _navigate(const CommunityScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.groups_rounded, color: Colors.blueAccent, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Farmer Advisory Forum', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                              SizedBox(height: 3),
                              Text('Ask experts, share knowledge, connect with farmers', style: TextStyle(fontSize: 12, color: Colors.black45)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.blueAccent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );

    return WebLayoutShell(
      currentTab: WebTab.dashboard,
      role: 'farmer',
      child: content,
    );
  }

  Widget _priceChip(Map<String, dynamic> m) {
    final trend = m['trend'] as int;
    final trendColor = trend == 1 ? Colors.green : (trend == -1 ? Colors.redAccent : Colors.grey);
    final trendIcon = trend == 1 ? Icons.trending_up_rounded : (trend == -1 ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    return Column(
      children: [
        Text(m['crop'] as String, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${m['price']}${m['unit']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(trendIcon, size: 11, color: trendColor),
            const SizedBox(width: 2),
            Text(m['change'] as String, style: TextStyle(fontSize: 9, color: trendColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 22, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
