import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoldPriceService {
  static DateTime? get lastFetchDate => _lastFetchDate;
  static const _baseUrl =
      'https://api.metals.dev/v1/latest?api_key=MCIE0SR3LDWJ1MLKQD1Z220LKQD1Z&currency=INR&unit=g';

  static const _headers = {
    'Accept': 'application/json',
  };

  static Map<String, double>? _cachedMetals;
  static DateTime? _lastFetchDate;

  static Future<Map<String, double>> fetchMetals() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastFetchString = prefs.getString('metals_last_fetch');
    final metalsJson = prefs.getString('metals_data');
    if (lastFetchString != null && metalsJson != null) {
      final lastFetch = DateTime.tryParse(lastFetchString);
      if (lastFetch != null &&
          lastFetch.year == today.year &&
          lastFetch.month == today.month &&
          lastFetch.day == today.day) {
        final metalsMap = (jsonDecode(metalsJson) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        _cachedMetals = metalsMap;
        _lastFetchDate = lastFetch;
        return metalsMap;
      }
    }
    // Fetch from API if not cached for today
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final metals = json['metals'] as Map<String, dynamic>;
      final metalsMap =
          metals.map((k, v) => MapEntry(k, (v as num).toDouble()));
      _cachedMetals = metalsMap;
      _lastFetchDate = today;
      await prefs.setString('metals_last_fetch', today.toIso8601String());
      await prefs.setString('metals_data', jsonEncode(metalsMap));
      return metalsMap;
    } else {
      print('❌ Status Code: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');
      throw Exception('Failed to load metals prices');
    }
  }
}
