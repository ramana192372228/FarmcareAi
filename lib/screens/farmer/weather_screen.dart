import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;

  // Localized weather alerts/advisories
  final Map<AppLanguage, Map<String, String>> _localizedWeather = {
    AppLanguage.english: {
      'title': 'Precision Weather Advisor',
      'current': 'Current Weather',
      'forecast': 'Hourly Forecast',
      'temp': '32°C',
      'condition': 'Mostly Sunny',
      'humidity': 'Humidity: 65%',
      'wind': 'Wind: 12 km/h',
      'soil_moisture': 'Rainfall: 0.0 mm',
      'alert_title': 'Agricultural Weather Alert',
      'alert_desc': 'High humidity forecast for tomorrow evening. Excellent time to apply organic fertilizers, but delay pesticide spraying to avoid washouts.',
      'week_forecast': '5-Day Outlook',
      'humidity_label': 'Humidity',
      'wind_label': 'Wind Speed',
      'moisture_label': 'Rainfall',
    },
    AppLanguage.telugu: {
      'title': 'వ్యవసాయ వాతావరణ సలహాదారు',
      'current': 'ప్రస్తుత వాతావరణం',
      'forecast': 'గంటల వారీ సూచన',
      'temp': '32°C',
      'condition': 'ఎండగా ఉంది',
      'humidity': 'తేమ: 65%',
      'wind': 'గాలి వేగం: 12 కిమీ/గం',
      'soil_moisture': 'వర్షపాతం: 0.0 mm',
      'alert_title': 'వ్యవసాయ వాతావరణ హెచ్చరిక',
      'alert_desc': 'రేపు సాయంత్రం అధిక తేమ ఉండవచ్చు. సేంద్రీయ ఎరువులు వేయడానికి ఇది సరైన సమయం, కానీ పురుగుమందుల పిచికారీని వాయిదా వేయండి.',
      'week_forecast': '5 రోజుల వాతావరణం',
      'humidity_label': 'తేమ',
      'wind_label': 'గాలి వేగం',
      'moisture_label': 'వర్షపాతం',
    },
    AppLanguage.tamil: {
      'title': 'துல்லிய வானிலை வழிகாட்டி',
      'current': 'தற்போதைய வானிலை',
      'forecast': 'மணிநேர முன்னறிவிப்பு',
      'temp': '32°C',
      'condition': 'வெயில் காலம்',
      'humidity': 'ஈரப்பதம்: 65%',
      'wind': 'காற்று: 12 கி.மீ/மணி',
      'soil_moisture': 'மழைப்பொழிவு: 0.0 mm',
      'alert_title': 'விவசாய வானிலை எச்சரிக்கை',
      'alert_desc': 'நாளை மாலை அதிக ஈரப்பதம் இருக்கும் என கணிக்கப்பட்டுள்ளது. இயற்கை உரமிட சிறந்த தருணம், ஆனால் பூச்சிக்கொல்லி தெளிப்பதை தள்ளிப்போடுங்கள்.',
      'week_forecast': '5 நாள் வானிலை',
      'humidity_label': 'ஈரப்பதம்',
      'wind_label': 'காற்றின் வேகம்',
      'moisture_label': 'மழைப்பொழிவு',
    },
    AppLanguage.hindi: {
      'title': 'सटीक मौसम सलाहकार',
      'current': 'वर्तमान मौसम',
      'forecast': 'प्रति घंटा पूर्वानुमान',
      'temp': '32°C',
      'condition': 'धूप खिली है',
      'humidity': 'नमी: 65%',
      'wind': 'हवा: 12 किमी/घंटा',
      'soil_moisture': 'वर्षा: 0.0 mm',
      'alert_title': 'कृषि मौसम अलर्ट',
      'alert_desc': 'कल शाम को अधिक नमी का अनुमान है। जैविक खाद डालने का यह सही समय है, लेकिन कीटनाशकों के छिड़काव में देरी करें।',
      'week_forecast': '5-दिवसीय पूर्वानुमान',
      'humidity_label': 'नमी',
      'wind_label': 'हवा की गति',
      'moisture_label': 'वर्षा / बारिश',
    },
    AppLanguage.kannada: {
      'title': 'ನಿಖರ ಹವಾಮಾನ ಸಲಹೆಗಾರ',
      'current': 'ಪ್ರಸ್ತುತ ಹವಾಮಾನ',
      'forecast': 'ಗಂಟೆಯ ಮುನ್ಸೂಚನೆ',
      'temp': '32°C',
      'condition': 'ಬಿಸಿಲು',
      'humidity': 'ತೇವಾಂಶ: 65%',
      'wind': 'ಗಾಳಿ: 12 ಕಿಮೀ/ಗಂ',
      'soil_moisture': 'ಮಳೆ ಪ್ರಮಾಣ: 0.0 mm',
      'alert_title': 'ಕೃಷಿ ಹವಾಮಾನ ಎಚ್ಚರಿಕೆ',
      'alert_desc': 'ನಾಳೆ ಸಂಜೆ ಹೆಚ್ಚಿನ ತೇವಾಂಶ ಇರಬಹುದು. ಸಾವಯವ ಗೊಬ್ಬರವನ್ನು ಹಾಕಲು ಇದು ಸೂಕ್ತ ಸಮಯ, ಆದರೆ ಕೀಟನಾಶಕ ಸಿಂಪಡಣೆಯನ್ನು ಮುಂದೂಡಿ.',
      'week_forecast': '5 ದಿನಗಳ ದೃಷ್ಟಿಕೋನ',
      'humidity_label': 'ತೇವಾಂಶ',
      'wind_label': 'ಗಾಳಿಯ ವೇಗ',
      'moisture_label': 'ಮಳೆ ಪ್ರಮಾಣ',
    },
    AppLanguage.malayalam: {
      'title': 'പ്രാദേശിക കാലാവസ്ഥാ ഉപദേശകൻ',
      'current': 'ഇപ്പോഴത്തെ കാലാവസ്ഥ',
      'forecast': 'മണിക്കൂർ പ്രവചനം',
      'temp': '32°C',
      'condition': 'വെയിൽ',
      'humidity': 'ഈർപ്പം: 65%',
      'wind': 'കാറ്റ്: 12 കി.മീ/മണിക്കൂർ',
      'soil_moisture': 'മഴപെയ്യൽ: 0.0 mm',
      'alert_title': 'കാർഷിക കാലാവസ്ഥാ മുന്നറിയിപ്പ്',
      'alert_desc': 'നാളെ വൈകുന്നേരം അന്തരീക്ഷത്തിൽ ഈർപ്പം കൂടാൻ സാധ്യതയുണ്ട്. ജൈവവളം ചേർക്കാൻ മികച്ച സമയം, എന്നാൽ കീടനാശിനി പ്രയോഗം തൽക്കാലം ഒഴിവാക്കുക.',
      'week_forecast': '5 ദിവസത്തെ കാലാവസ്ഥ',
      'humidity_label': 'ഈർപ്പം',
      'wind_label': 'കാറ്റിന്റെ വേഗം',
      'moisture_label': 'മഴപെയ്യൽ',
    },
  };

  String _getText(String key) {
    final lang = TranslationService().currentLanguage;
    final map = _localizedWeather[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedWeather[AppLanguage.english]![key]!;
  }

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = WeatherService();

    try {
      final Map<String, double> coords = await service.determinePosition();
      final double lat = coords['lat']!;
      final double lon = coords['lon']!;

      final WeatherData liveData = await service.fetchLiveWeather(lat, lon);
      if (mounted) {
        setState(() {
          _weatherData = liveData;
          _isLoading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      debugPrint('[WEATHER_SCREEN] Live load failed: $e');
      if (mounted) {
        final cached = await service.loadCachedWeather();
        final fallbackData = cached ?? service.getMockWeatherData();
        setState(() {
          _weatherData = fallbackData;
          _isLoading = false;
          _isOffline = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device is offline. Displaying cached weather data.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();

    if (_isLoading && _weatherData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(trans.translate('weather')),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_errorMessage != null && _weatherData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(trans.translate('weather')),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Weather Service Offline',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loadWeatherData,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text('RETRY LOADING', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final weatherData = _weatherData!;
    final hourlyData = weatherData.hourlyForecast;
    final weeklyData = weatherData.weeklyForecast;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('weather')),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Weather',
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeatherData,
          color: AppTheme.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Localized Offline / Cached Alerts banner if we failed to fetch fresh
                  if (_isOffline)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_queue_rounded, color: AppTheme.accentGold, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cached Weather Data',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Currently running in offline cache mode. Tap refresh to check connectivity.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Current Weather Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getText('current').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last Updated: ${weatherData.lastUpdated}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getWeatherHeroIcon(weatherData.condition),
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weatherData.temperature,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  weatherData.condition,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherStat(Icons.water_drop_rounded, _getText('humidity_label'), weatherData.humidity),
                            _buildWeatherStat(Icons.air_rounded, _getText('wind_label'), weatherData.windSpeed),
                            _buildWeatherStat(Icons.umbrella_rounded, _getText('moisture_label'), weatherData.soilMoisture),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Warning Advisory Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.accentGold, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getText('alert_title'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getText('alert_desc'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[750],
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Hourly Forecast
                  if (hourlyData.isNotEmpty) ...[
                    Text(
                      _getText('forecast'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: hourlyData.length,
                        itemBuilder: (context, index) {
                          final hour = hourlyData[index];
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  hour['time']!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                _getIcon(hour['icon']!),
                                const SizedBox(height: 8),
                                Text(
                                  hour['temp']!,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Weekly Outlook (using actual sorted days)
                  if (weeklyData.isNotEmpty) ...[
                    Text(
                      _getText('week_forecast'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: weeklyData.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                        itemBuilder: (context, index) {
                          final week = weeklyData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    week['day']!,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    week['condition']!,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ),
                                Text(
                                  week['temp']!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _getIcon(String iconName) {
    IconData data = Icons.wb_sunny_rounded;
    Color color = AppTheme.accentGold;
    if (iconName == 'wb_cloudy_rounded') {
      data = Icons.wb_cloudy_rounded;
      color = Colors.blueGrey;
    } else if (iconName == 'cloud_rounded') {
      data = Icons.cloud_rounded;
      color = Colors.blue;
    } else if (iconName == 'nights_stay_rounded') {
      data = Icons.nights_stay_rounded;
      color = Colors.indigo;
    }
    return Icon(data, color: color, size: 28);
  }

  IconData _getWeatherHeroIcon(String condition) {
    final String cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('drizzle')) {
      return Icons.umbrella_rounded;
    }
    if (cond.contains('cloud')) {
      return Icons.cloud_rounded;
    }
    if (cond.contains('thunderstorm')) {
      return Icons.thunderstorm_rounded;
    }
    if (cond.contains('mist') || cond.contains('fog') || cond.contains('haze')) {
      return Icons.grain_rounded;
    }
    return Icons.wb_sunny_rounded;
  }
}
