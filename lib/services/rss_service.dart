import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RssService {
  static const String baseUrl =
      'http://127.0.0.1:8080'; // Replace with your actual API endpoint
  static Future<List<RssChannel>> fetchRecommendedChannels() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/rss/recommend/channel"), headers: {
        "Content-Type": "application/json; charset=UTF-8",
      });
      // 이어지는 코드...
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

  // 사용자 구독 RSS 채널 가져오기
  static Future<List<RssChannel>> fetchSubscribedChannels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? subscribedJson = prefs.getString('subscribed_channels');

      if (subscribedJson == null || subscribedJson.isEmpty) {
        return [];
      }

      List<dynamic> subscribedList = json.decode(subscribedJson);
      return subscribedList.map((model) => RssChannel.fromJson(model)).toList();
    } catch (e) {
      debugPrint('Error fetching subscribed channels: $e');
      return [];
    }
  }

  // 특정 채널의 아이템 가져오기
  static Future<List<RssItem>> fetchChannelItems(String channelTitle) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/rss/items?channel_title=$channelTitle'));

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

  // 채널이 이미 구독되어 있는지 확인하는 메서드 추가
  static Future<bool> isChannelAlreadySubscribed(RssChannel channel) async {
    try {
      final subscribedChannels = await fetchSubscribedChannels();

      // "channelLink"로 비교 (채널 웹사이트 URL)
      bool isSubscribed = false;
      for (var c in subscribedChannels) {
        if (c.channelRssLink == channel.channelRssLink) {
          isSubscribed = true;
          break;
        }
      }

      return isSubscribed;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> subscribeChannel(RssChannel channel) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 현재 구독 중인 채널 목록 가져오기
      List<RssChannel> subscribedChannels = await fetchSubscribedChannels();

      // 이미 구독 중인지 확인 - 올바른 필드로 비교
      bool alreadySubscribed = false;
      for (var c in subscribedChannels) {
        if (c.channelLink == channel.channelLink) {
          alreadySubscribed = true;
          break;
        }
      }

      if (alreadySubscribed) {
        return false;
      }

      // 채널 추가
      subscribedChannels.add(channel);

      // 저장
      await prefs.setString('subscribed_channels',
          json.encode(subscribedChannels.map((c) => c.toJson()).toList()));

      return true;
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
      return false;
    }
  }

  // RSS 채널 구독 취소하기
  static Future<bool> unsubscribeChannel(String channelRssLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 현재 구독 중인 채널 목록 가져오기
      List<RssChannel> subscribedChannels = await fetchSubscribedChannels();

      // 채널 제거
      subscribedChannels.removeWhere((c) => c.channelRssLink == channelRssLink);

      // 저장
      await prefs.setString('subscribed_channels',
          json.encode(subscribedChannels.map((c) => c.toJson()).toList()));

      return true;
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
}
