import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/models/news.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static Future<List<News>> fetchNews(String category) async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8080/news?category=$category"),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
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
      String category, int display, String sort) async {
    try {
      final response = await http.get(
          Uri.parse(
              'http://127.0.0.1:8080/news/api?query=$category&display=$display&sort=$sort'),
          headers: {
            "Content-Type": "application/json; charset=UTF-8",
          });

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
