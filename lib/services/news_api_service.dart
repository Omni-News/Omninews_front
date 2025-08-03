import 'package:omninews_flutter/models/news.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

class NewsApiService {
  static String baseUrl = AuthService.apiBaseUrl;
  static final AuthService _authService = AuthService();
  static final HtmlUnescape _unescape = HtmlUnescape();

  // HTML 엔티티 디코딩 함수 (문자열만 처리)
  static String _decodeHtmlString(String text) {
    return _unescape.convert(text);
  }

  static Future<List<NewsApi>> fetchNews(
    String query,
    int display,
    String sort,
  ) async {
    try {
      if (sort == 'pop') {
        sort = 'sim';
      }

      final response = await _authService.apiRequest(
        'GET',
        '/search/news_api?query=$query&display=$display&sort=$sort',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 아이템의 필드별로 처리
        return jsonResponse.map((newsItem) {
          // 문자열 필드들만 디코딩
          if (newsItem['title'] is String) {
            newsItem['title'] = _decodeHtmlString(newsItem['title']);
          }
          if (newsItem['description'] is String) {
            newsItem['description'] = _decodeHtmlString(
              newsItem['description'],
            );
          }
          if (newsItem['originallink'] is String) {
            newsItem['originallink'] = _decodeHtmlString(
              newsItem['originallink'],
            );
          }
          if (newsItem['link'] is String) {
            newsItem['link'] = _decodeHtmlString(newsItem['link']);
          }

          return NewsApi.fromJson(newsItem);
        }).toList();
      } else {
        debugPrint('뉴스 API 로드 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load News API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('뉴스 API 요청 중 오류 발생: $e');
      throw Exception('Failed to load News API: $e');
    }
  }
}
