import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/utils/rss_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscribeService {
  static const String baseUrl = 'http://127.0.0.1:8080'; // API 서버 주소로 변경

  // 북마크된 모든 아이템 가져오기
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
        debugPrint('Error fetching bookmarks');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching bookmarks: $e');

      return [];
    }
  }

  // 채널별로 북마크된 아이템 가져오기
  static Future<Map<RssChannel, List<RssItem>>> getItemsByChannel() async {
    try {
      // 먼저 구독 중인 채널 목록 가져오기
      final subscribedChannels = await RssService.fetchSubscribedChannels();
      final Map<RssChannel, List<RssItem>> result = {};

      // 채널별로 북마크된 아이템 가져오기
      for (var channel in subscribedChannels) {
        final response = await http.get(
          Uri.parse(
              '$baseUrl/rss/items?channel_link=${channel.channelRssLink}'),
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

  // 북마크 항목 검색
  static Future<List<RssItem>> searchBookmarkedItems(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookmarks/search?q=$query'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((item) => RssItem.fromJson(item)).toList();
      } else {
        // API 호출 실패 시 로컬 검색
        final items = await _getLocalBookmarks();
        return _filterItemsByQuery(items, query);
      }
    } catch (e) {
      debugPrint('Error searching bookmarks: $e');

      // API 오류 시 로컬 검색
      final items = await _getLocalBookmarks();
      return _filterItemsByQuery(items, query);
    }
  }

  // 채널별 북마크 항목 검색
  static Future<Map<RssChannel, List<RssItem>>> searchItemsByChannel(
      String query) async {
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

  // 아이템을 북마크에 추가
  static Future<bool> addBookmark(RssItem item) async {
    try {
      // API 호출로 북마크 추가
      final response = await http.post(
        Uri.parse('$baseUrl/bookmarks'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API 성공 시 로컬에도 저장
        await _addLocalBookmark(item);
        return true;
      } else {
        // API 실패 시 로컬만 저장
        await _addLocalBookmark(item);
        return true;
      }
    } catch (e) {
      debugPrint('Error adding bookmark: $e');

      // API 오류 시 로컬에만 저장
      await _addLocalBookmark(item);
      return true;
    }
  }

  // 북마크에서 아이템 제거
  static Future<bool> removeBookmark(String itemLink) async {
    try {
      // API 호출로 북마크 제거
      final response = await http.delete(
        Uri.parse('$baseUrl/bookmarks?link=$itemLink'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
      );

      if (response.statusCode == 200) {
        // API 성공 시 로컬에서도 제거
        await _removeLocalBookmark(itemLink);
        return true;
      } else {
        // API 실패 시 로컬에서만 제거
        await _removeLocalBookmark(itemLink);
        return true;
      }
    } catch (e) {
      debugPrint('Error removing bookmark: $e');

      // API 오류 시 로컬에서만 제거
      await _removeLocalBookmark(itemLink);
      return true;
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
  static Future<List<RssItem>> _getLocalBookmarks() async {
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
  static Future<void> _addLocalBookmark(RssItem item) async {
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
    } catch (e) {
      debugPrint('Error adding local bookmark: $e');
    }
  }

  // 로컬에서 북마크 제거
  static Future<void> _removeLocalBookmark(String itemLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

      bookmarksJson.removeWhere((json) {
        final item = RssItem.fromJson(jsonDecode(json));
        return item.rssLink == itemLink;
      });

      await prefs.setStringList('bookmarks', bookmarksJson);
    } catch (e) {
      debugPrint('Error removing local bookmark: $e');
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
}
