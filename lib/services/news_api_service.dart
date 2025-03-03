import 'package:omninews_flutter/models/news.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsApiService {
  static Future<List<NewsApi>> fetchNews(
      String query, int display, String sort) async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://127.0.0.1:8080/news/api?query=$query&display=$display&sort=$sort"),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
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
