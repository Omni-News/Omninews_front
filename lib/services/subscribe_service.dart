import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/utils/rss_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscribeService {
  static const String baseUrl = 'http://61.253.113.42:1027 '; // API 서버 주소로 변경

  static Future<List<RssItem>> getSubscribedItems() async {
    try {
      List<String> subscribedLinks =
          await RssManager.getSubscribedChannelLinks();

      final List<Map<String, String>> formattedLinks =
          subscribedLinks.map((link) => {"link": link}).toList();

      // API 호출
      final response = await http.post(
        Uri.parse('$baseUrl/subscribe/items'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: json.encode(formattedLinks), // 배열 형태로 인코딩
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((item) => RssItem.fromJson(item)).toList();
      } else {
        // API 호출 실패 시 로컬 저장소 사용
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<RssChannel, List<RssItem>>> getItemsByChannel() async {
    try {
      // 먼저 구독 중인 채널 목록 가져오기
      final subscribedChannels = await RssService.fetchSubscribedChannels();
      final Map<RssChannel, List<RssItem>> result = {};

      for (var channel in subscribedChannels) {
        final response = await http.get(
          Uri.parse(
            '$baseUrl/rss/items?channel_link=${channel.channelRssLink}',
          ),
          headers: {"Content-Type": "application/json; charset=UTF-8"},
        );

        if (response.statusCode == 200) {
          String decodedResponse = utf8.decode(response.bodyBytes);
          List jsonResponse = json.decode(decodedResponse);
          final items =
              jsonResponse.map((item) => RssItem.fromJson(item)).toList();

          if (items.isNotEmpty) {
            result[channel] = items;
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching items by channel: $e');

      // API 오류 시 로컬 데이터 사용
      return {};
    }
  }

  static Future<List<RssItem>> searchBookmarkedItems(String query) async {
    try {
      final allItems = await getItemsByChannel();
      List<RssItem> result = [];

      for (var entry in allItems.entries) {
        final filteredItems = _filterItemsByQuery(entry.value, query);
        if (filteredItems.isNotEmpty) {
          result = filteredItems;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error searching items by channel: $e');
      return [];
    }
  }

  static Future<Map<RssChannel, List<RssItem>>> searchItemsByChannel(
    String query,
  ) async {
    try {
      final allItems = await getItemsByChannel();
      final Map<RssChannel, List<RssItem>> result = {};

      for (var entry in allItems.entries) {
        final filteredItems = _filterItemsByQuery(entry.value, query);
        if (filteredItems.isNotEmpty) {
          result[entry.key] = filteredItems;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error searching items by channel: $e');
      return {};
    }
  }

  // 아이템이 북마크되어 있는지 확인
  static Future<bool> isBookmarked(String itemLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

      for (var json in bookmarksJson) {
        final item = RssItem.fromJson(jsonDecode(json));
        if (item.rssLink == itemLink) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking bookmark status: $e');
      return false;
    }
  }

  // 로컬 저장소에서 북마크 가져오기
  static Future<List<RssItem>> getLocalBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

      return bookmarksJson
          .map((json) => RssItem.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) {
          try {
            final dateA = DateTime.parse(a.rssPubDate);
            final dateB = DateTime.parse(b.rssPubDate);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
    } catch (e) {
      debugPrint('Error getting local bookmarks: $e');
      return [];
    }
  }

  // 로컬에 북마크 추가
  static Future<bool> addLocalBookmark(RssItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

      // 이미 있는지 확인
      final exists = bookmarksJson.any((json) {
        final existingItem = RssItem.fromJson(jsonDecode(json));
        return existingItem.rssLink == item.rssLink;
      });

      if (!exists) {
        bookmarksJson.add(jsonEncode(item.toJson()));
        await prefs.setStringList('bookmarks', bookmarksJson);
      }
      return true;
    } catch (e) {
      debugPrint('Error adding local bookmark: $e');
      return false;
    }
  }

  // 로컬에서 북마크 제거
  static Future<bool> removeLocalBookmark(String itemLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

      bookmarksJson.removeWhere((json) {
        final item = RssItem.fromJson(jsonDecode(json));
        return item.rssLink == itemLink;
      });

      await prefs.setStringList('bookmarks', bookmarksJson);
      return true;
    } catch (e) {
      debugPrint('Error removing local bookmark: $e');
      return false;
    }
  }

  // 검색어로 아이템 필터링
  static List<RssItem> _filterItemsByQuery(List<RssItem> items, String query) {
    if (query.isEmpty) {
      return items;
    }

    final lowercaseQuery = query.toLowerCase();
    return items.where((item) {
      return item.rssTitle.toLowerCase().contains(lowercaseQuery) ||
          item.rssDescription.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // 북마크 추가 (SearchRssItemCard에서 호출하는 메서드)
  static Future<bool> addBookmark(RssItem item) async {
    return addLocalBookmark(item);
  }

  // 북마크 제거 (SearchRssItemCard에서 호출하는 메서드)
  static Future<bool> removeBookmark(String itemLink) async {
    return removeLocalBookmark(itemLink);
  }

  // RSS 채널 구독 여부 확인
  static Future<bool> isSubscribed(String channelUrl) async {
    try {
      final subscribedLinks = await RssManager.getSubscribedChannelLinks();
      return subscribedLinks.contains(channelUrl);
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  // RSS 채널 구독
  static Future<bool> subscribe(RssChannel channel) async {
    try {
      // API 호출 (필요한 경우)
      // ...

      // 로컬에 저장
      return await RssService.subscribeChannel(channel.channelRssLink);
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
      return false;
    }
  }

  // RSS 채널 구독 취소
  static Future<bool> unsubscribe(String channelUrl) async {
    try {
      // API 호출 (필요한 경우)
      // ...

      // 로컬에서 제거
      return await RssService.unsubscribeChannel(channelUrl);
    } catch (e) {
      debugPrint('Error unsubscribing from channel: $e');
      return false;
    }
  }
}
