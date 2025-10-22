import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/models/news.dart';
import 'dart:convert';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

class NewsService {
  static String baseUrl = AuthService.apiBaseUrl;
  static final AuthService _authService = AuthService();
  static final HtmlUnescape _unescape = HtmlUnescape();

  // HTML 엔티티 디코딩 함수 (문자열만 처리)
  static String _decodeHtmlString(String text) {
    return _unescape.convert(text);
  }

  //  static Future<List<News>> fetchNews(String category) async {
  //    try {
  //      // AuthService.apiRequest 사용하여 토큰 갱신 기능 활용
  //      final response = await _authService.apiRequest(
  //        'GET',
  //        '/news?category=$category',
  //      );
  //
  //      if (response.statusCode == 200) {
  //        String decodedResponse = utf8.decode(response.bodyBytes);
  //        List<dynamic> jsonResponse = json.decode(decodedResponse);
  //
  //        // HTML 엔티티 디코딩 - 각 항목의 필드별로 처리
  //        return jsonResponse.map((newsItem) {
  //          // 문자열 필드들만 디코딩
  //          if (newsItem['title'] is String) {
  //            newsItem['title'] = _decodeHtmlString(newsItem['title']);
  //          }
  //          if (newsItem['content'] is String) {
  //            newsItem['content'] = _decodeHtmlString(newsItem['content']);
  //          }
  //          if (newsItem['description'] is String) {
  //            newsItem['description'] = _decodeHtmlString(
  //              newsItem['description'],
  //            );
  //          }
  //
  //          return News.fromJson(newsItem);
  //        }).toList();
  //      } else {
  //        debugPrint('뉴스 로드 실패: ${response.statusCode}, ${response.body}');
  //        throw Exception('Failed to load News');
  //      }
  //    } catch (e) {
  //      debugPrint('뉴스 로드 중 오류 발생: $e');
  //      throw Exception('Failed to load News $e');
  //    }
  //  }

  static Future<List<News>> fetchNewsPaginated(
    String category,
    int page,
  ) async {
    try {
      // AuthService.apiRequest 사용하여 토큰 갱신 기능 활용
      final response = await _authService.apiRequest(
        'GET',
        '/news?category=$category&page=$page',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 항목의 필드별로 처리
        return jsonResponse.map((newsItem) {
          // 문자열 필드들만 디코딩
          if (newsItem['title'] is String) {
            newsItem['title'] = _decodeHtmlString(newsItem['title']);
          }
          if (newsItem['content'] is String) {
            newsItem['content'] = _decodeHtmlString(newsItem['content']);
          }
          if (newsItem['description'] is String) {
            newsItem['description'] = _decodeHtmlString(
              newsItem['description'],
            );
          }

          return News.fromJson(newsItem);
        }).toList();
      } else {
        debugPrint('뉴스 로드 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load News');
      }
    } catch (e) {
      debugPrint('뉴스 로드 중 오류 발생: $e');
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
      // AuthService.apiRequest 사용하여 토큰 갱신 기능 활용
      final response = await _authService.apiRequest(
        'GET',
        '/search/news_api?query=$category&display=$display&sort=$sort',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 항목의 필드별로 처리
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

          return CustomNews.fromJson(newsItem);
        }).toList();
      } else {
        debugPrint('커스텀 뉴스 로드 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load custom news: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('커스텀 뉴스 로드 중 오류 발생: $e');
      throw Exception('Error fetching custom news: $e');
    }
  }
}
