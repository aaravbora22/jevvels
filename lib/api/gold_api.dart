import 'dart:convert';
import 'package:http/http.dart' as http;

class GoldPriceService {
  static const _baseUrl = 'https://www.goldapi.io/api/XAU/USD';

  static const _headers = {
    'x-access-token': 'goldapi-ef4crlqotxdxa-io',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, double>> fetchGoldPrices() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        '24k': json['price_gram_24k'],
        '22k': json['price_gram_22k'],
        '18k': json['price_gram_18k'],
      };
    } else {
      print('❌ Status Code: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');
      throw Exception('Failed to load gold prices');
    }
  }
}
