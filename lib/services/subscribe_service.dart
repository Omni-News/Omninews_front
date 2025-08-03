import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html_unescape/html_unescape.dart';

class SubscribeService {
  static final HtmlUnescape _unescape = HtmlUnescape();

  // HTML 엔티티 디코딩 함수 (문자열만 처리)
  static String _decodeHtmlString(String text) {
    return _unescape.convert(text);
  }

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
      // 검색어도 HTML 엔티티 디코딩
      final decodedQuery = _decodeHtmlString(query);
      return _filterItemsByQuery(bookmarkedItems, decodedQuery);
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

      // 검색어도 HTML 엔티티 디코딩
      final decodedQuery = _decodeHtmlString(query);

      for (var entry in allItems.entries) {
        final filteredItems = _filterItemsByQuery(entry.value, decodedQuery);
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

      return bookmarksJson.map((json) {
          Map<String, dynamic> data = jsonDecode(json);

          // 문자열 필드들만 디코딩
          if (data['rss_title'] is String) {
            data['rss_title'] = _decodeHtmlString(data['rss_title']);
          }
          if (data['rss_description'] is String) {
            data['rss_description'] = _decodeHtmlString(
              data['rss_description'],
            );
          }
          if (data['rss_author'] is String) {
            data['rss_author'] = _decodeHtmlString(data['rss_author']);
          }
          if (data['rss_source'] is String) {
            data['rss_source'] = _decodeHtmlString(data['rss_source']);
          }

          return RssItem.fromJson(data);
        }).toList()
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

      // 저장할 아이템 데이터 준비
      Map<String, dynamic> itemJson = item.toJson();

      // 이미 있는지 확인
      final exists = bookmarksJson.any((json) {
        final existingItem = RssItem.fromJson(jsonDecode(json));
        return existingItem.rssLink == item.rssLink;
      });

      if (!exists) {
        bookmarksJson.add(jsonEncode(itemJson));
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
      // 검색 시 디코딩된 텍스트로 비교
      String title = _decodeHtmlString(item.rssTitle.toLowerCase());
      String description = _decodeHtmlString(item.rssDescription.toLowerCase());

      return title.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery);
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

  // TODO 심하게 많이 반복됨, 채널 구독 여부 확인
  // 서버에 배열로다가 채널 구독여부 받아오는 API 만들어서 요청하기
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
