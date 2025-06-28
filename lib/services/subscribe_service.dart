import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscribeService {
  static const String baseUrl = 'http://61.253.113.42:1027';
  static final AuthService _authService = AuthService();

  // 구독한 채널의 아이템 가져오기
  static Future<List<RssItem>> getSubscribedItems() async {
    try {
      // 구독 중인 채널 ID 목록 가져오기
      final subscribedChannels = await RssService.fetchSubscribedChannels();
      final List<int> channelIds =
          subscribedChannels.map((channel) => channel.channelId).toList();

      if (channelIds.isEmpty) {
        return [];
      }

      // 서버에 요청하여 구독 아이템 가져오기
      return await RssService.fetchSubscribedItems(channelIds);
    } catch (e) {
      debugPrint('Error getting subscribed items: $e');
      return [];
    }
  }

  // 채널별로 아이템 가져오기
  static Future<Map<RssChannel, List<RssItem>>> getItemsByChannel() async {
    try {
      // 구독 중인 채널 목록 가져오기
      final subscribedChannels = await RssService.fetchSubscribedChannels();
      final Map<RssChannel, List<RssItem>> result = {};

      for (var channel in subscribedChannels) {
        try {
          // 해당 채널의 아이템 가져오기
          final items = await RssService.fetchChannelItems(channel.channelId);

          if (items.isNotEmpty) {
            result[channel] = items;
          }
        } catch (e) {
          debugPrint(
            'Error fetching items for channel ${channel.channelTitle}: $e',
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching items by channel: $e');
      return {};
    }
  }

  // 북마크된 아이템에서 검색
  static Future<List<RssItem>> searchBookmarkedItems(String query) async {
    try {
      final bookmarkedItems = await getLocalBookmarks();
      return _filterItemsByQuery(bookmarkedItems, query);
    } catch (e) {
      debugPrint('Error searching bookmarked items: $e');
      return [];
    }
  }

  // 채널별 아이템 검색
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
      // 북마크 API가 구현되기 전까지는 로컬 저장소 사용
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

  // 북마크 추가
  static Future<bool> addLocalBookmark(RssItem item) async {
    try {
      // 북마크 API가 구현되기 전까지는 로컬 저장소 사용
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

  // 북마크 제거
  static Future<bool> removeLocalBookmark(String itemLink) async {
    try {
      // 북마크 API가 구현되기 전까지는 로컬 저장소 사용
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

  // 채널 구독 여부 확인
  static Future<bool> isSubscribed(String channelRssLink) async {
    try {
      return await RssService.isChannelAlreadySubscribed(channelRssLink);
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  // 채널 구독
  static Future<bool> subscribe(int channelId) async {
    try {
      return await RssService.subscribeChannel(channelId);
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
      return false;
    }
  }

  // 채널 구독 취소
  static Future<bool> unsubscribe(int channelId) async {
    try {
      return await RssService.unsubscribeChannel(channelId);
    } catch (e) {
      debugPrint('Error unsubscribing from channel: $e');
      return false;
    }
  }

  // SubscribeService 클래스에 추가할 메서드
  static Future<List<RssItem>> getSubscribedItemsByChannelIds(
    List<int> channelIds,
  ) async {
    try {
      if (channelIds.isEmpty) {
        return [];
      }

      // 서버에 요청하여 구독 아이템 가져오기
      return await RssService.fetchSubscribedItems(channelIds);
    } catch (e) {
      debugPrint('Error getting items by channel IDs: $e');
      return [];
    }
  }
}
