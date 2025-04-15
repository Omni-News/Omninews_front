import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_test_flutter/models/rss_item.dart';
import 'package:omninews_test_flutter/models/rss_channel.dart';
import 'package:omninews_test_flutter/services/subscribe_service.dart';

class RssSearchService {
  // baseUrl 사용
  static final String baseUrl = SubscribeService.baseUrl;

  // RSS 피드 검색
  static Future<List<RssItem>> searchRssItems(
      String query, String sortType) async {
    try {
      // API 정렬 방식으로 변환
      final searchType = _convertSortOption(sortType);

      // RSS 검색 API 호출
      final response = await http.get(
        Uri.parse(
            '$baseUrl/search/rss?search_value=$query&search_type=$searchType'),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        // 응답이 직접 리스트로 반환됨
        final List<dynamic> jsonResponse = json.decode(decodedResponse);

        // 리스트를 RssItem 객체로 변환
        final List<RssItem> rssItems =
            jsonResponse.map((item) => RssItem.fromJson(item)).toList();

        return rssItems;
      } else {
        debugPrint('RSS 검색 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('RSS 검색 오류: $e');
      return [];
    }
  }

  // RSS 채널 검색
  static Future<List<RssChannel>> searchChannels(
      String query, String sortType) async {
    try {
      // API 정렬 방식으로 변환
      final searchType = _convertSortOption(sortType);

      // 채널 검색 API 호출
      final response = await http.get(
        Uri.parse(
            '$baseUrl/search/channel?search_value=$query&search_type=$searchType'),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final String decodedResponse = utf8.decode(response.bodyBytes);
        // 응답이 직접 리스트로 반환됨
        final List<dynamic> jsonResponse = json.decode(decodedResponse);

        // 리스트를 RssChannel 객체로 변환
        final List<RssChannel> channels = jsonResponse
            .map((channel) => RssChannel.fromJson(channel))
            .toList();

        return channels;
      } else {
        debugPrint('채널 검색 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('채널 검색 오류: $e');
      return [];
    }
  }

  // 정렬 옵션 변환 (클라이언트 -> API)
  static String _convertSortOption(String clientSortOption) {
    switch (clientSortOption) {
      case 'sim':
        return 'Accuracy';
      case 'date':
        return 'Latest';
      case 'pop':
        return 'Popularity';
      default:
        return 'Accuracy';
    }
  }
}
