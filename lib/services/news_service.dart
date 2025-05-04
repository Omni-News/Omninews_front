import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/models/news.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/services/auth_service.dart';

class NewsService {
  static const String baseUrl = 'http://61.253.113.42:1027';
  static final AuthService _authService = AuthService();

  static Future<List<News>> fetchNews(String category) async {
    final headers = _authService.getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/news?category=$category"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((news) => News.fromJson(news)).toList();
      } else {
        throw Exception('Failed to load News');
      }
    } catch (e) {
      throw Exception('Failed to load News $e');
    }
  }

  // 사용자 추가 카테고리용 API
  static Future<List<CustomNews>> fetchCustomNews(
    String category,
    int display,
    String sort,
  ) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/news/api?query=$category&display=$display&sort=$sort',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((news) => CustomNews.fromJson(news)).toList();
      } else {
        throw Exception('Failed to load custom news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching custom news: $e');
    }
  }
}
