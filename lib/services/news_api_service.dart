import 'package:omninews_flutter/models/news.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/services/auth_service.dart';

class NewsApiService {
  static String baseUrl = AuthService.apiBaseUrl;
  static final AuthService _authService = AuthService();
  static Future<List<NewsApi>> fetchNews(
    String query,
    int display,
    String sort,
  ) async {
    try {
      if (sort == 'pop') {
        sort = 'sim';
      }
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          "$baseUrl/search/news_api?query=$query&display=$display&sort=$sort",
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((news) => NewsApi.fromJson(news)).toList();
      } else {
        throw Exception('Failed to load News');
      }
    } catch (e) {
      throw Exception('Failed to load News $e');
    }
  }
}
