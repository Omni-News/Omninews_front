import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_test_flutter/models/rss_channel.dart';
import 'package:omninews_test_flutter/models/rss_item.dart';
import 'package:omninews_test_flutter/utils/rss_manager.dart';

class RssService {
  static const String baseUrl =
      'http://61.253.113.42:1027'; // Replace with your actual API endpoint
  static Future<List<RssChannel>> fetchRecommendedChannels() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/rss/recommend/channel"), headers: {
        "Content-Type": "application/json; charset=UTF-8",
      });
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((news) => RssChannel.fromJson(news)).toList();
      } else {
        throw Exception('Failed to load recommended channels');
      }
    } catch (e) {
      // For demo purposes, return mock data
      return [];
    }
  }

  // 특정 채널의 아이템 가져오기
  static Future<List<RssItem>> fetchChannelItems(String channelRssLink) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/rss/items?channel_link=$channelRssLink'));

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((news) => RssItem.fromJson(news)).toList();
      } else {
        throw Exception('Failed to load channel items');
      }
    } catch (e) {
      throw Exception('Failed to load channel items');
    }
  }

  // RSS 링크로부터 채널 미리보기 (새 RSS 추가 시)
  static Future<RssChannel?> previewRssFromUrl(String rssLink) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/rss/preview?rss_link=$rssLink'));

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        dynamic jsonResponse = json.decode(decodedResponse);
        return RssChannel.fromJson(jsonResponse);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to load channel items');
    }
  }

  // RSS를 DB에 추가하기
  static Future<bool> addRssToDb(String rssLink) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rss'),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({"link": rssLink}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to add RSS: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error adding RSS to DB: $e');
      return false;
    }
  }

  // 채널 구독
  static Future<bool> subscribeChannel(String channelRssLink) async {
    try {
      bool res = await RssManager.subscribeChannel(channelRssLink);
      if (!res) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/rss/channel/rank'),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "rss_link": channelRssLink,
          "num": 1,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to update rss channel rank: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
      return false;
    }
  }

  // RSS 채널 구독 취소하기
  static Future<bool> unsubscribeChannel(String channelRssLink) async {
    try {
      bool res = await RssManager.unsubscribeChannel(channelRssLink);
      if (!res) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/rss/channel/rank'),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "rss_link": channelRssLink,
          "num": -1,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to update rss channel rank: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error unsubscribing from channel: $e');
      return false;
    }
  }

  static Future<bool> checkRssExists(String rssLink) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rss/exist?rss_link=$rssLink'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        dynamic jsonResponse = json.decode(decodedResponse);
        debugPrint('checkRssExists response: $jsonResponse');
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

  // 사용자 구독 RSS 채널 가져오기
  static Future<List<RssChannel>> fetchSubscribedChannels() async {
    try {
      List<String> subscribeList = await RssManager.getSubscribedChannelLinks();
      debugPrint('subscribeList: $subscribeList');

      List<RssChannel> subscribedChannels = [];

      for (String channelRssLink in subscribeList) {
        final response = await http.get(
          Uri.parse('$baseUrl/rss/channel?rss_link=$channelRssLink'),
          headers: {"Content-Type": "application/json; charset=UTF-8"},
        );

        if (response.statusCode == 200) {
          String decodedResponse = utf8.decode(response.bodyBytes);
          dynamic jsonResponse = json.decode(decodedResponse);
          subscribedChannels.add(RssChannel.fromJson(jsonResponse));
        }
      }

      return subscribedChannels;
    } catch (e) {
      debugPrint('Error fetching subscribed channels: $e');
      return [];
    }
  }

  // 채널이 이미 구독되어 있는지 확인하는 메서드 추가
  static Future<bool> isChannelAlreadySubscribed(String channelRssLink) async {
    try {
      bool res = await RssManager.isChannelSubscribed(channelRssLink);
      return res;
    } catch (e) {
      return false;
    }
  }
}
