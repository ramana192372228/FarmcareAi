import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'translation_service.dart';

class WeatherData {
  final String temperature;
  final String condition;
  final String humidity;
  final String windSpeed;
  final String soilMoisture; // Replaced internally by Rainfall (e.g. "2.5 mm")
  final List<Map<String, String>> hourlyForecast;
  final List<Map<String, String>> weeklyForecast;
  final String lastUpdated;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.soilMoisture,
    required this.hourlyForecast,
    required this.weeklyForecast,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'condition': condition,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'soilMoisture': soilMoisture,
    'hourlyForecast': hourlyForecast,
    'weeklyForecast': weeklyForecast,
    'lastUpdated': lastUpdated,
  };

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature'] as String? ?? '32°C',
      condition: json['condition'] as String? ?? 'Sunny',
      humidity: json['humidity'] as String? ?? '65%',
      windSpeed: json['windSpeed'] as String? ?? '12 km/h',
      soilMoisture: json['soilMoisture'] as String? ?? '0.0 mm',
      hourlyForecast: (json['hourlyForecast'] as List?)
          ?.map((item) => Map<String, String>.from(item as Map))
          .toList() ?? [],
      weeklyForecast: (json['weeklyForecast'] as List?)
          ?.map((item) => Map<String, String>.from(item as Map))
          .toList() ?? [],
      lastUpdated: json['lastUpdated'] as String? ?? 'Just now',
    );
  }
}

class WeatherService extends ChangeNotifier {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const String _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

  WeatherData getMockWeatherData() {
    final now = DateTime.now();
    return WeatherData(
      temperature: '32°C',
      condition: 'Mostly Sunny',
      humidity: '65%',
      windSpeed: '12 km/h',
      soilMoisture: '0.0 mm',
      lastUpdated: '${now.day} ${_getMonthAbbr(now.month)}, ${_formatTime(now)}',
      hourlyForecast: [
        {'time': '02:00 PM', 'temp': '32°C', 'icon': 'wb_sunny_rounded'},
        {'time': '04:00 PM', 'temp': '31°C', 'icon': 'wb_cloudy_rounded'},
        {'time': '06:00 PM', 'temp': '29°C', 'icon': 'cloud_rounded'},
        {'time': '08:00 PM', 'temp': '27°C', 'icon': 'nights_stay_rounded'},
        {'time': '10:00 PM', 'temp': '26°C', 'icon': 'nights_stay_rounded'},
      ],
      weeklyForecast: [
        {'day': 'Monday', 'temp': '32°C / 24°C', 'condition': 'Sunny'},
        {'day': 'Tuesday', 'temp': '33°C / 25°C', 'condition': 'Sunny'},
        {'day': 'Wednesday', 'temp': '30°C / 23°C', 'condition': 'Rainy'},
        {'day': 'Thursday', 'temp': '28°C / 22°C', 'condition': 'Thunderstorms'},
        {'day': 'Friday', 'temp': '31°C / 23°C', 'condition': 'Mostly Cloudy'},
      ],
    );
  }

  /// Retrieve GPS Coordinates with fallback to Guntur, Andhra Pradesh (16.3067, 80.4365)
  Future<Map<String, double>> determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[WEATHER_SERVICE] Location services are disabled. Using fallback Guntur.');
        return {'lat': 16.3067, 'lon': 80.4365};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[WEATHER_SERVICE] Location permissions are denied. Using fallback Guntur.');
          return {'lat': 16.3067, 'lon': 80.4365};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[WEATHER_SERVICE] Location permissions are permanently denied. Using fallback Guntur.');
        return {'lat': 16.3067, 'lon': 80.4365};
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      return {'lat': position.latitude, 'lon': position.longitude};
    } catch (e) {
      debugPrint('[WEATHER_SERVICE] Error obtaining GPS position: $e. Using fallback Guntur.');
      return {'lat': 16.3067, 'lon': 80.4365};
    }
  }

  /// Fetch live weather using OpenWeather API or Open-Meteo fallback
  Future<WeatherData> fetchLiveWeather(double latitude, double longitude) async {
    if (_apiKey.isNotEmpty) {
      try {
        final String currentUrl = 'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
        final String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';

        debugPrint('[WEATHER_SERVICE] Querying OpenWeather: lat=$latitude, lon=$longitude');

        final http.Response currentResponse = await http.get(Uri.parse(currentUrl)).timeout(const Duration(seconds: 8));
        final http.Response forecastResponse = await http.get(Uri.parse(forecastUrl)).timeout(const Duration(seconds: 8));

        if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
          final Map<String, dynamic> currentData = jsonDecode(currentResponse.body);
          final Map<String, dynamic> forecastData = jsonDecode(forecastResponse.body);
          final lang = TranslationService().currentLanguage;

          final double temp = (currentData['main']['temp'] as num).toDouble();
          final String tempString = '${temp.toStringAsFixed(0)}°C';
          final String rawCondition = currentData['weather'][0]['main'] as String;
          final String localizedCondition = _getLocalizedCondition(rawCondition, lang);

          final int humidity = currentData['main']['humidity'] as int;
          final String humidityString = '$humidity%';

          final double windSpeedMps = (currentData['wind']['speed'] as num).toDouble();
          final double windSpeedKmh = windSpeedMps * 3.6;
          final String windString = '${windSpeedKmh.toStringAsFixed(0)} km/h';

          double rainAmount = 0.0;
          if (currentData.containsKey('rain')) {
            final rainMap = currentData['rain'] as Map<String, dynamic>;
            rainAmount = (rainMap['1h'] ?? rainMap['3h'] ?? 0.0).toDouble();
          }
          final String rainString = '${rainAmount.toStringAsFixed(1)} mm';

          final List<Map<String, String>> hourlyForecast = [];
          final List<dynamic> forecastList = forecastData['list'] as List;
          for (int i = 0; i < 5 && i < forecastList.length; i++) {
            final item = forecastList[i] as Map<String, dynamic>;
            final int dt = item['dt'] as int;
            final double hourTemp = (item['main']['temp'] as num).toDouble();
            final String hourIconCode = item['weather'][0]['icon'] as String;

            final DateTime dtTime = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
            hourlyForecast.add({
              'time': _formatTime(dtTime),
              'temp': '${hourTemp.toStringAsFixed(0)}°C',
              'icon': _mapOpenWeatherIcon(hourIconCode),
            });
          }

          final Map<String, List<Map<String, dynamic>>> groupedForecasts = {};
          for (final item in forecastList) {
            final int dt = item['dt'] as int;
            final DateTime dtTime = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
            final String dateKey = '${dtTime.year}-${dtTime.month}-${dtTime.day}';
            if (!groupedForecasts.containsKey(dateKey)) {
              groupedForecasts[dateKey] = [];
            }
            groupedForecasts[dateKey]!.add(item as Map<String, dynamic>);
          }

          final List<Map<String, String>> weeklyForecast = [];
          final List<String> sortedKeys = groupedForecasts.keys.toList()..sort();

          for (final dateKey in sortedKeys) {
            final dayForecasts = groupedForecasts[dateKey]!;
            final DateTime representativeDate = DateTime.fromMillisecondsSinceEpoch((dayForecasts[0]['dt'] as int) * 1000);

            double maxTemp = -999.0;
            double minTemp = 999.0;
            for (final hourItem in dayForecasts) {
              final double t = (hourItem['main']['temp'] as num).toDouble();
              if (t > maxTemp) maxTemp = t;
              if (t < minTemp) minTemp = t;
            }
            final int midIdx = dayForecasts.length ~/ 2;
            final String dayCondition = dayForecasts[midIdx]['weather'][0]['main'] as String;

            weeklyForecast.add({
              'day': _getLocalizedDayName(representativeDate, lang),
              'temp': '${maxTemp.toStringAsFixed(0)}°C / ${minTemp.toStringAsFixed(0)}°C',
              'condition': _getLocalizedCondition(dayCondition, lang),
            });
          }

          final now = DateTime.now();
          final String lastUpdatedStr = '${now.day} ${_getMonthAbbr(now.month)}, ${_formatTime(now)}';

          final WeatherData weather = WeatherData(
            temperature: tempString,
            condition: localizedCondition,
            humidity: humidityString,
            windSpeed: windString,
            soilMoisture: rainString,
            hourlyForecast: hourlyForecast,
            weeklyForecast: weeklyForecast,
            lastUpdated: lastUpdatedStr,
          );

          await _saveCachedWeather(weather);
          return weather;
        }
      } catch (e) {
        debugPrint('[WEATHER_SERVICE] OpenWeather query failed: $e. Trying Open-Meteo fallback.');
      }
    }

    // Fallback: Open-Meteo Public API (Requires 0 API key)
    return await _fetchFromOpenMeteo(latitude, longitude);
  }

  /// Open-Meteo API Fetch Helper
  Future<WeatherData> _fetchFromOpenMeteo(double latitude, double longitude) async {
    final String url = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto';
    debugPrint('[WEATHER_SERVICE] Querying Open-Meteo Fallback API: lat=$latitude, lon=$longitude');

    final http.Response response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to load live weather data (Status ${response.statusCode})');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final lang = TranslationService().currentLanguage;

    final current = data['current'] as Map<String, dynamic>;
    final double temp = (current['temperature_2m'] as num).toDouble();
    final int humidity = (current['relative_humidity_2m'] as num).toInt();
    final double wind = (current['wind_speed_10m'] as num).toDouble();
    final double precip = (current['precipitation'] as num).toDouble();
    final int wmoCode = (current['weather_code'] as num).toInt();

    final String rawCondition = _mapWmoCodeToCondition(wmoCode);
    final String localizedCondition = _getLocalizedCondition(rawCondition, lang);

    final hourlyData = data['hourly'] as Map<String, dynamic>?;
    final List<Map<String, String>> hourlyForecast = [];
    if (hourlyData != null) {
      final List times = hourlyData['time'] as List;
      final List temps = hourlyData['temperature_2m'] as List;
      final List codes = hourlyData['weather_code'] as List;
      final DateTime now = DateTime.now();

      int count = 0;
      for (int i = 0; i < times.length && count < 5; i++) {
        final DateTime dt = DateTime.tryParse(times[i].toString()) ?? now;
        if (dt.isAfter(now)) {
          final double hTemp = (temps[i] as num).toDouble();
          final int hCode = (codes[i] as num).toInt();
          hourlyForecast.add({
            'time': _formatTime(dt),
            'temp': '${hTemp.toStringAsFixed(0)}°C',
            'icon': _mapWmoCodeToIcon(hCode),
          });
          count++;
        }
      }
    }

    final dailyData = data['daily'] as Map<String, dynamic>?;
    final List<Map<String, String>> weeklyForecast = [];
    if (dailyData != null) {
      final List times = dailyData['time'] as List;
      final List maxTemps = dailyData['temperature_2m_max'] as List;
      final List minTemps = dailyData['temperature_2m_min'] as List;
      final List codes = dailyData['weather_code'] as List;

      for (int i = 0; i < times.length && i < 5; i++) {
        final DateTime dt = DateTime.tryParse(times[i].toString()) ?? DateTime.now();
        final double maxT = (maxTemps[i] as num).toDouble();
        final double minT = (minTemps[i] as num).toDouble();
        final int dCode = (codes[i] as num).toInt();
        weeklyForecast.add({
          'day': _getLocalizedDayName(dt, lang),
          'temp': '${maxT.toStringAsFixed(0)}°C / ${minT.toStringAsFixed(0)}°C',
          'condition': _getLocalizedCondition(_mapWmoCodeToCondition(dCode), lang),
        });
      }
    }

    final now = DateTime.now();
    final String lastUpdatedStr = '${now.day} ${_getMonthAbbr(now.month)}, ${_formatTime(now)}';

    final WeatherData weather = WeatherData(
      temperature: '${temp.toStringAsFixed(0)}°C',
      condition: localizedCondition,
      humidity: '$humidity%',
      windSpeed: '${wind.toStringAsFixed(0)} km/h',
      soilMoisture: '${precip.toStringAsFixed(1)} mm',
      hourlyForecast: hourlyForecast,
      weeklyForecast: weeklyForecast,
      lastUpdated: lastUpdatedStr,
    );

    await _saveCachedWeather(weather);
    return weather;
  }

  String _mapWmoCodeToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return 'Rain';
    if (code >= 95) return 'Thunderstorm';
    return 'Clear';
  }

  String _mapWmoCodeToIcon(int code) {
    if (code == 0) return 'wb_sunny_rounded';
    if (code <= 3) return 'wb_cloudy_rounded';
    if (code >= 51 && code <= 82) return 'cloud_rounded';
    return 'wb_sunny_rounded';
  }

  String _getMonthAbbr(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }

  /// Load cached weather data from SharedPreferences
  Future<WeatherData?> loadCachedWeather() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('cached_weather_data');
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        return WeatherData.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[WEATHER_SERVICE] Error loading local weather cache: $e');
    }
    return null;
  }

  /// Helper: Save serialized WeatherData to local SharedPreferences cache
  Future<void> _saveCachedWeather(WeatherData data) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_weather_data', jsonEncode(data.toJson()));
      await prefs.setInt('cached_weather_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[WEATHER_SERVICE] Error saving local weather cache: $e');
    }
  }

  /// Format DateTime to standard 12-hour clock format (e.g. 02:00 PM)
  String _formatTime(DateTime dt) {
    final int hour = dt.hour;
    final int minute = dt.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String minStr = minute < 10 ? '0$minute' : '$minute';
    final String hrStr = hour12 < 10 ? '0$hour12' : '$hour12';
    return '$hrStr:$minStr $period';
  }

  /// Map OpenWeather icon code to the app's internal icons list
  String _mapOpenWeatherIcon(String code) {
    if (code.startsWith('01d')) return 'wb_sunny_rounded';
    if (code.startsWith('01n')) return 'nights_stay_rounded';
    if (code.startsWith('02')) return 'wb_cloudy_rounded';
    return 'cloud_rounded';
  }

  /// Map raw weather condition words to target regional translations
  String _getLocalizedCondition(String raw, AppLanguage lang) {
    final String cond = raw.toLowerCase();
    switch (lang) {
      case AppLanguage.telugu:
        if (cond.contains('clear')) return 'ఎండగా ఉంది';
        if (cond.contains('cloud')) return 'మబ్బులతో కూడిన వాతావరణం';
        if (cond.contains('rain')) return 'వర్షం';
        if (cond.contains('drizzle')) return 'చినుకులు';
        if (cond.contains('thunderstorm')) return 'ఉరుములతో కూడిన వర్షం';
        return 'పొగమంచు / సాధారణం';
      case AppLanguage.tamil:
        if (cond.contains('clear')) return 'வெயில் காலம்';
        if (cond.contains('cloud')) return 'மேகமூட்டம்';
        if (cond.contains('rain')) return 'மழை';
        if (cond.contains('drizzle')) return 'தூறல்';
        if (cond.contains('thunderstorm')) return 'இடியுடன் கூடிய மழை';
        return 'மூடுபனி';
      case AppLanguage.hindi:
        if (cond.contains('clear')) return 'धूप खिली है';
        if (cond.contains('cloud')) return 'बादल छाए हैं';
        if (cond.contains('rain')) return 'बारिश';
        if (cond.contains('drizzle')) return 'बूंदाबांदी';
        if (cond.contains('thunderstorm')) return 'आंधी-तूफान';
        return 'धुंध / कोहरा';
      case AppLanguage.kannada:
        if (cond.contains('clear')) return 'ಬಿಸಿಲು';
        if (cond.contains('cloud')) return 'ಮೋಡ ಕವಿದ ವಾತಾವರಣ';
        if (cond.contains('rain')) return 'ಮಳೆ';
        if (cond.contains('drizzle')) return 'ತುಂತುರು ಮಳೆ';
        if (cond.contains('thunderstorm')) return 'ಗುಡುಗು ಸಹಿತ ಮಳೆ';
        return 'ಮಂಜು ಕವಿದ ಹವಾಮಾನ';
      case AppLanguage.malayalam:
        if (cond.contains('clear')) return 'വെയിൽ';
        if (cond.contains('cloud')) return 'മേഘാവൃതം';
        if (cond.contains('rain')) return 'മഴ';
        if (cond.contains('drizzle')) return 'ചാറ്റൽ മഴ';
        if (cond.contains('thunderstorm')) return 'ഇടിമിന്നൽ';
        return 'മഞ്ഞ് മൂടിയത്';
      default: // English
        if (cond.contains('clear')) return 'Sunny / Clear';
        if (cond.contains('cloud')) return 'Mostly Cloudy';
        if (cond.contains('rain')) return 'Rainy';
        if (cond.contains('drizzle')) return 'Drizzle';
        if (cond.contains('thunderstorm')) return 'Thunderstorm';
        return 'Misty / Fog';
    }
  }

  /// Get localized day of the week
  String _getLocalizedDayName(DateTime dt, AppLanguage lang) {
    final int index = dt.weekday - 1;
    switch (lang) {
      case AppLanguage.telugu:
        const days = ['సోమవారం', 'మంగళవారం', 'బుధవారం', 'గురువారం', 'శుక్రవారం', 'శనివారం', 'ఆదివారం'];
        return days[index];
      case AppLanguage.tamil:
        const days = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];
        return days[index];
      case AppLanguage.hindi:
        const days = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
        return days[index];
      case AppLanguage.kannada:
        const days = ['ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ', 'ಭಾನುವಾರ'];
        return days[index];
      case AppLanguage.malayalam:
        const days = ['തിങ്കൾ', 'ചൊവ്വ', 'ബുധൻ', 'വ്യാഴം', 'വെള്ളി', 'ശനി', 'ഞായർ'];
        return days[index];
      default:
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return days[index];
    }
  }
}
