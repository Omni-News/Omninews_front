import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/auth_service.dart';

class SearchResponse {
  final List<RssChannel> channels;
  final List<RssItem> items;
  final int total;
  final int page;
  final bool hasNext;

  SearchResponse({
    required this.channels,
    required this.items,
    required this.total,
    required this.page,
    required this.hasNext,
  });
}

class RssSearchService {
  static String baseUrl = AuthService.apiBaseUrl;
  static final AuthService _authService = AuthService();

  // 검색 타입 변환 헬퍼 함수
  static String _convertSortToSearchType(String sort) {
    switch (sort) {
      case 'sim':
        return 'Accuracy';
      case 'pop':
        return 'Popularity';
      case 'date':
        return 'Latest';
      default:
        return 'Accuracy';
    }
  }

  // RSS 아이템 검색
  static Future<SearchResponse> searchRssItems(
    String query,
    String sort, [
    int page = 1,
  ]) async {
    try {
      // 검색어 인코딩
      final encodedQuery = Uri.encodeComponent(query);
      final searchType = _convertSortToSearchType(sort);

      final headers = _authService.getAuthHeaders();
      print(
        'RSS 아이템 검색 API 요청: $baseUrl/search/item?search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/search/item?search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
        ),
        headers: headers,
      );

      print('RSS 아이템 검색 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        print(
          'RSS 아이템 검색 응답 받음: ${decodedResponse.substring(0, min(100, decodedResponse.length))}...',
        );

        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        List<RssItem> items = [];
        if (jsonResponse.containsKey('items') &&
            jsonResponse['items'] is List) {
          items =
              (jsonResponse['items'] as List)
                  .map((item) => RssItem.fromJson(item))
                  .toList();
        }

        List<RssChannel> channels = [];
        if (jsonResponse.containsKey('channels') &&
            jsonResponse['channels'] is List) {
          channels =
              (jsonResponse['channels'] as List)
                  .map((channel) => RssChannel.fromJson(channel))
                  .toList();
        }

        print(
          'RSS 아이템 검색 결과: 아이템 ${items.length}개, 채널 ${channels.length}개, 총 ${jsonResponse['total'] ?? 0}개, 더 있음: ${jsonResponse['has_next'] ?? false}',
        );

        return SearchResponse(
          items: items,
          channels: channels,
          total: jsonResponse['total'] ?? 0,
          page: jsonResponse['page'] ?? 1,
          hasNext: jsonResponse['has_next'] ?? false,
        );
      } else {
        print('RSS 아이템 검색 실패: ${response.statusCode} - ${response.body}');
        return SearchResponse(
          items: [],
          channels: [],
          total: 0,
          page: 1,
          hasNext: false,
        );
      }
    } catch (e) {
      print('RSS 아이템 검색 중 오류: $e');
      return SearchResponse(
        items: [],
        channels: [],
        total: 0,
        page: 1,
        hasNext: false,
      );
    }
  }

  // 채널 검색
  static Future<SearchResponse> searchChannels(
    String query,
    String sort, [
    int page = 1,
  ]) async {
    try {
      // 검색어 인코딩
      final encodedQuery = Uri.encodeComponent(query);
      final searchType = _convertSortToSearchType(sort);

      final headers = _authService.getAuthHeaders();
      print(
        '채널 검색 API 요청: $baseUrl/search/channels?search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/search/channels?search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
        ),
        headers: headers,
      );

      print('채널 검색 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        print(
          '채널 검색 응답 받음: ${decodedResponse.substring(0, min(100, decodedResponse.length))}...',
        );

        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        List<RssChannel> channels = [];
        if (jsonResponse.containsKey('channels') &&
            jsonResponse['channels'] is List) {
          channels =
              (jsonResponse['channels'] as List)
                  .map((channel) => RssChannel.fromJson(channel))
                  .toList();
        }

        List<RssItem> items = [];
        if (jsonResponse.containsKey('items') &&
            jsonResponse['items'] is List) {
          items =
              (jsonResponse['items'] as List)
                  .map((item) => RssItem.fromJson(item))
                  .toList();
        }

        print(
          '채널 검색 결과: 채널 ${channels.length}개, 아이템 ${items.length}개, 총 ${jsonResponse['total'] ?? 0}개, 더 있음: ${jsonResponse['has_next'] ?? false}',
        );

        return SearchResponse(
          channels: channels,
          items: items,
          total: jsonResponse['total'] ?? 0,
          page: jsonResponse['page'] ?? 1,
          hasNext: jsonResponse['has_next'] ?? false,
        );
      } else {
        print('채널 검색 실패: ${response.statusCode} - ${response.body}');
        return SearchResponse(
          channels: [],
          items: [],
          total: 0,
          page: 1,
          hasNext: false,
        );
      }
    } catch (e) {
      print('채널 검색 중 오류: $e');
      return SearchResponse(
        channels: [],
        items: [],
        total: 0,
        page: 1,
        hasNext: false,
      );
    }
  }

  // min 함수 추가
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
