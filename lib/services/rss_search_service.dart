import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:html_unescape/html_unescape.dart';

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
  static final HtmlUnescape _unescape = HtmlUnescape();

  // HTML 엔티티 디코딩 함수 (문자열만 처리)
  static String _decodeHtmlString(String text) {
    return _unescape.convert(text);
  }

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

      debugPrint(
        'RSS 아이템 검색 API 요청: search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
      );

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'GET',
        '/search/item?search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
      );

      debugPrint('RSS 아이템 검색 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        debugPrint(
          'RSS 아이템 검색 응답 받음: ${jsonResponse.toString().substring(0, min(100, jsonResponse.toString().length))}...',
        );

        List<RssItem> items = [];
        if (jsonResponse.containsKey('items') &&
            jsonResponse['items'] is List) {
          items =
              (jsonResponse['items'] as List).map((item) {
                // 문자열 필드들만 디코딩
                if (item['rss_title'] is String) {
                  item['rss_title'] = _decodeHtmlString(item['rss_title']);
                }
                if (item['rss_description'] is String) {
                  item['rss_description'] = _decodeHtmlString(
                    item['rss_description'],
                  );
                }
                if (item['rss_author'] is String) {
                  item['rss_author'] = _decodeHtmlString(item['rss_author']);
                }
                if (item['rss_source'] is String) {
                  item['rss_source'] = _decodeHtmlString(item['rss_source']);
                }

                return RssItem.fromJson(item);
              }).toList();
        }

        List<RssChannel> channels = [];
        if (jsonResponse.containsKey('channels') &&
            jsonResponse['channels'] is List) {
          channels =
              (jsonResponse['channels'] as List).map((channel) {
                // 문자열 필드들만 디코딩
                if (channel['channel_title'] is String) {
                  channel['channel_title'] = _decodeHtmlString(
                    channel['channel_title'],
                  );
                }
                if (channel['channel_description'] is String) {
                  channel['channel_description'] = _decodeHtmlString(
                    channel['channel_description'],
                  );
                }
                if (channel['channel_link'] is String) {
                  channel['channel_link'] = _decodeHtmlString(
                    channel['channel_link'],
                  );
                }

                return RssChannel.fromJson(channel);
              }).toList();
        }

        debugPrint(
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
        debugPrint('RSS 아이템 검색 실패: ${response.statusCode} - ${response.body}');
        return SearchResponse(
          items: [],
          channels: [],
          total: 0,
          page: 1,
          hasNext: false,
        );
      }
    } catch (e) {
      debugPrint('RSS 아이템 검색 중 오류: $e');
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

      debugPrint(
        '채널 검색 API 요청: search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
      );

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'GET',
        '/search/channels?search_value=$encodedQuery&search_type=$searchType&search_page_size=$page',
      );

      debugPrint('채널 검색 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        debugPrint(
          '채널 검색 응답 받음: ${jsonResponse.toString().substring(0, min(100, jsonResponse.toString().length))}...',
        );

        List<RssChannel> channels = [];
        if (jsonResponse.containsKey('channels') &&
            jsonResponse['channels'] is List) {
          channels =
              (jsonResponse['channels'] as List).map((channel) {
                // 문자열 필드들만 디코딩
                if (channel['channel_title'] is String) {
                  channel['channel_title'] = _decodeHtmlString(
                    channel['channel_title'],
                  );
                }
                if (channel['channel_description'] is String) {
                  channel['channel_description'] = _decodeHtmlString(
                    channel['channel_description'],
                  );
                }
                if (channel['channel_link'] is String) {
                  channel['channel_link'] = _decodeHtmlString(
                    channel['channel_link'],
                  );
                }

                return RssChannel.fromJson(channel);
              }).toList();
        }

        List<RssItem> items = [];
        if (jsonResponse.containsKey('items') &&
            jsonResponse['items'] is List) {
          items =
              (jsonResponse['items'] as List).map((item) {
                // 문자열 필드들만 디코딩
                if (item['rss_title'] is String) {
                  item['rss_title'] = _decodeHtmlString(item['rss_title']);
                }
                if (item['rss_description'] is String) {
                  item['rss_description'] = _decodeHtmlString(
                    item['rss_description'],
                  );
                }
                if (item['rss_author'] is String) {
                  item['rss_author'] = _decodeHtmlString(item['rss_author']);
                }
                if (item['rss_source'] is String) {
                  item['rss_source'] = _decodeHtmlString(item['rss_source']);
                }

                return RssItem.fromJson(item);
              }).toList();
        }

        debugPrint(
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
        debugPrint('채널 검색 실패: ${response.statusCode} - ${response.body}');
        return SearchResponse(
          channels: [],
          items: [],
          total: 0,
          page: 1,
          hasNext: false,
        );
      }
    } catch (e) {
      debugPrint('채널 검색 중 오류: $e');
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
