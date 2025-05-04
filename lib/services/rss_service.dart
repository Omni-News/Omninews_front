import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/auth_service.dart'; // 인증 서비스 임포트

class RssService {
  static const String baseUrl = 'http://61.253.113.42:1027';

  // 인증 서비스 인스턴스
  static final AuthService _authService = AuthService();

  // 추천 채널 가져오기
  static Future<List<RssChannel>> fetchRecommendedChannels() async {
    try {
      final headers = _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse("$baseUrl/rss/recommend/channel"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((news) => RssChannel.fromJson(news)).toList();
      } else {
        throw Exception('Failed to load recommended channels');
      }
    } catch (e) {
      debugPrint('Error fetching recommended channels: $e');
      return [];
    }
  }

  // 특정 채널의 아이템 가져오기
  static Future<List<RssItem>> fetchChannelItems(int channelId) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rss/items?channel_id=$channelId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((item) => RssItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load channel items');
      }
    } catch (e) {
      debugPrint('Error fetching channel items: $e');
      throw Exception('Failed to load channel items');
    }
  }

  // RSS 링크로부터 채널 미리보기 (새 RSS 추가 시)
  static Future<RssChannel?> previewRssFromUrl(String rssLink) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rss/preview?rss_link=$rssLink'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        dynamic jsonResponse = json.decode(decodedResponse);
        return RssChannel.fromJson(jsonResponse);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error previewing RSS from URL: $e');
      return null;
    }
  }

  // RSS를 DB에 추가하기
  static Future<int?> addRssToDb(String rssLink) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rss'),
        headers: headers,
        body: json.encode({"link": rssLink}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 서버 응답에서 채널 ID 추출
        String decodedResponse = utf8.decode(response.bodyBytes);

        // 응답에서 id 필드 추출
        final value = json.decode(decodedResponse);

        if (value is int) {
          debugPrint('Channel added with ID: $value');
          return value;
        }

        debugPrint('Channel added but no ID returned');
        return null;
      } else {
        debugPrint(
          'Failed to add RSS: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error adding RSS to DB: $e');
      return null;
    }
  }

  // 채널 구독 - 새 API 스펙 사용
  static Future<bool> subscribeChannel(int channelId) async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/subscription/channel'),
        headers: headers,
        body: json.encode({"channel_id": channelId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to subscribe channel: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
      return false;
    }
  }

  static Future<bool> subscribeChannelByRssLink(String channelRssLink) async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      int? id = await getChannelId(channelRssLink);
      debugPrint('Channel ID: $id');

      final response = await http.post(
        Uri.parse('$baseUrl/subscription/channel'),
        headers: headers,
        body: json.encode({"channel_id": id}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to subscribe channel: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
      return false;
    }
  }

  // rss link로 channel id 가져오기
  static Future<int> getChannelId(String channelRssLink) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rss/id?channel_rss_link=$channelRssLink'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        dynamic jsonResponse = json.decode(decodedResponse);
        return jsonResponse;
      } else {
        debugPrint('Failed to get channel ID: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('Error getting channel ID: $e');
      return 0;
    }
  }

  // 채널 구독 취소 - 새 API 스펙 사용
  static Future<bool> unsubscribeChannel(int channelId) async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/subscription/channel'),
        headers: headers,
        body: json.encode({"channel_id": channelId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to unsubscribe channel: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error unsubscribing from channel: $e');
      return false;
    }
  }

  // 사용자 구독 채널 아이템 가져오기 - 새 API 스펙 사용
  static Future<List<RssItem>> fetchSubscribedItems(
    List<int> channelIds,
  ) async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      // 채널 ID 배열을 ChannelId 객체 배열로 변환
      final List<Map<String, int>> channelIdObjects =
          channelIds.map((id) => {"channel_id": id}).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/subscription/items'),
        headers: headers,
        body: json.encode(channelIdObjects),
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((item) => RssItem.fromJson(item)).toList();
      } else {
        debugPrint(
          'Failed to fetch subscribed items: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching subscribed items: $e');
      return [];
    }
  }

  // 사용자 구독 채널 목록 가져오기
  static Future<List<RssChannel>> fetchSubscribedChannels() async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/subscription/channels'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse
            .map((channel) => RssChannel.fromJson(channel))
            .toList();
      } else {
        debugPrint(
          'Failed to fetch subscribed channels: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching subscribed channels: $e');
      return [];
    }
  }

  // 채널이 이미 구독되어 있는지 확인
  static Future<bool> isChannelAlreadySubscribed(String channelRssLink) async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/subscription/status?channel_rss_link=$channelRssLink',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedResponse);
        bool subscribed = jsonResponse == true;
        return subscribed;
      } else {
        debugPrint(
          'Failed to check subscription status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if channel is subscribed: $e');
      return false;
    }
  }

  static Future<bool> isChannelAlreadySubscribedByLink(
    String channelRssLink,
  ) async {
    try {
      // 인증 헤더 가져오기
      final headers = _authService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/subscription/status?channel_rss_link=$channelRssLink',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedResponse);
        return jsonResponse == true;
      } else {
        debugPrint(
          'Failed to check subscription status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if channel is subscribed: $e');
      return false;
    }
  }

  static Future<bool> checkRssExists(String rssLink) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rss/exist?rss_link=$rssLink'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        dynamic jsonResponse = json.decode(decodedResponse);
        return jsonResponse == true;
      } else {
        debugPrint('checkRssExists failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if RSS exists: $e');
      return false;
    }
  }

  static Future<bool> updateRssRank(int rssId) async {
    try {
      final headers = _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/rss/item/rank'),
        headers: headers,
        body: json.encode({"rss_id": rssId, "num": 1}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to update RSS rank: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating RSS rank: $e');
      return false;
    }
  }
}
