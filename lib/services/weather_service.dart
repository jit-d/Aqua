import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double maxTempC;
  final double avgHumidity;
  final DateTime fetchedAt;
  final String city;

  WeatherData({
    required this.maxTempC,
    required this.avgHumidity,
    required this.fetchedAt,
    required this.city,
  });
}

class WeatherService {
  static const _kCacheTime = 'weather_cache_time';
  static const _kCacheTemp = 'weather_cache_temp';
  static const _kCacheHumidity = 'weather_cache_humidity';
  static const _kCityName = 'weather_city_name';
  
  // 30 hours in milliseconds
  static const int _maxOfflineHours = 30 * 60 * 60 * 1000;

  Future<void> setCity(String city) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCityName, city);
    // Clear cache to force a new fetch for the new city
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
    
    if (cachedTimeStr != null) {
      final cachedTime = DateTime.parse(cachedTimeStr);
      final diff = DateTime.now().difference(cachedTime).inMilliseconds;
      
      if (diff < _maxOfflineHours) {
        // Use valid cache (within 30 hours)
        return WeatherData(
          maxTempC: p.getDouble(_kCacheTemp) ?? 20.0,
          avgHumidity: p.getDouble(_kCacheHumidity) ?? 50.0,
          fetchedAt: cachedTime,
          city: city,
        );
      }
    }

    // Cache expired or missing — fetch new data
    try {
      return await _fetchFromApi(city);
    } catch (e) {
      // If offline, fallback to cache if it exists (even if expired)
      // or return null to use default goal.
      if (cachedTimeStr != null) {
        return WeatherData(
          maxTempC: p.getDouble(_kCacheTemp) ?? 20.0,
          avgHumidity: p.getDouble(_kCacheHumidity) ?? 50.0,
          fetchedAt: DateTime.parse(cachedTimeStr),
          city: city,
        );
      }
      return null;
    }
  }

  Future<WeatherData> _fetchFromApi(String city) async {
    // 1. Geocode the city to Lat/Lon
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
    if (weatherRes.statusCode != 200) throw Exception('Weather API failed');

    final weatherData = json.decode(weatherRes.body);
    final hourly = weatherData['hourly'];
    
    // Get the max temp for today
    final temps = List<double>.from(hourly['temperature_2m'].map((x) => (x as num).toDouble()));
    final hums = List<double>.from(hourly['relative_humidity_2m'].map((x) => (x as num).toDouble()));
    
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final avgHumidity = hums.reduce((a, b) => a + b) / hums.length;

    // 3. Save to cache
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCacheTime, DateTime.now().toIso8601String());
    await p.setDouble(_kCacheTemp, maxTemp);
    await p.setDouble(_kCacheHumidity, avgHumidity);

    return WeatherData(
      maxTempC: maxTemp,
      avgHumidity: avgHumidity,
      fetchedAt: DateTime.now(),
      city: city,
    );
  }
}
