import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double maxTempC;
  final double avgHumidity;
  final List<double> hourlyTemps;
  final DateTime fetchedAt;
  final String city;

  WeatherData({
    required this.maxTempC,
    required this.avgHumidity,
    required this.hourlyTemps,
    required this.fetchedAt,
    required this.city,
  });
}

class WeatherService {
  static const _kCacheTime = 'weather_cache_time';
  static const _kCacheTemp = 'weather_cache_temp';
  static const _kCacheHumidity = 'weather_cache_humidity';
  static const _kCityName = 'weather_city_name';
  static const _kFetchDate = 'weather_fetch_date';

  Future<void> setCity(String city) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCityName, city);
    await p.remove(_kCacheTime);
  }

  Future<String> getCity() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kCityName) ?? 'London';
  }

  Future<WeatherData?> getWeather() async {
    final p = await SharedPreferences.getInstance();
    final city = await getCity();
    final cachedTimeStr = p.getString(_kCacheTime);
    final cachedDateStr = p.getString(_kFetchDate);
    final todayStr = _getTodayStr();
    final isNewDay = cachedDateStr != todayStr;

    if (cachedTimeStr != null && !isNewDay) {
      final cachedTime = DateTime.parse(cachedTimeStr);
      final diff = DateTime.now().difference(cachedTime).inHours;
      if (diff < 30) {
        return WeatherData(
          maxTempC: p.getDouble(_kCacheTemp) ?? 20.0,
          avgHumidity: p.getDouble(_kCacheHumidity) ?? 50.0,
          hourlyTemps: (p.getStringList('weather_hourly') ?? []).map(double.parse).toList(),
          fetchedAt: cachedTime,
          city: city,
        );
      }
    }

    try {
      final freshData = await _fetchFromApi(city);
      await p.setString(_kFetchDate, todayStr);
      return freshData;
    } catch (e) {
      if (cachedTimeStr != null) {
        return WeatherData(
          maxTempC: p.getDouble(_kCacheTemp) ?? 20.0,
          avgHumidity: p.getDouble(_kCacheHumidity) ?? 50.0,
          hourlyTemps: (p.getStringList('weather_hourly') ?? []).map(double.parse).toList(),
          fetchedAt: DateTime.parse(cachedTimeStr),
          city: city,
        );
      }
      return null;
    }
  }

  Future<WeatherData> _fetchFromApi(String city) async {
    // 1. Geocode the city
    final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=en&format=json');
    final geoRes = await http.get(geoUrl);
    if (geoRes.statusCode != 200) throw Exception('Geocoding failed');
    
    final geoData = json.decode(geoRes.body);
    if (geoData['results'] == null || geoData['results'].isEmpty) {
      throw Exception('City not found');
    }
    
    final lat = geoData['results'][0]['latitude'];
    final lon = geoData['results'][0]['longitude'];

    // 2. Fetch hourly weather
    final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m,relative_humidity_2m&forecast_days=2&timezone=auto');
    final weatherRes = await http.get(weatherUrl);
    if (weatherRes.statusCode != 200) throw Exception('Weather failed');

    final weatherData = json.decode(weatherRes.body);
    final temps = List<double>.from(
        weatherData['hourly']['temperature_2m'].map((x) => (x as num).toDouble()));
    final hums = List<double>.from(
        weatherData['hourly']['relative_humidity_2m'].map((x) => (x as num).toDouble()));
    
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final avgHumidity = hums.reduce((a, b) => a + b) / hums.length;

    // 3. Save to cache
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCacheTime, DateTime.now().toIso8601String());
    await p.setDouble(_kCacheTemp, maxTemp);
    await p.setDouble(_kCacheHumidity, avgHumidity);
    await p.setStringList('weather_hourly', temps.map((e) => e.toString()).toList());

    return WeatherData(
      maxTempC: maxTemp,
      avgHumidity: avgHumidity,
      hourlyTemps: temps,
      fetchedAt: DateTime.now(),
      city: city,
    );
  }

  String _getTodayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}