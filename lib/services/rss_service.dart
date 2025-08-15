import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:html_unescape/html_unescape.dart';

class RssService {
  static String baseUrl = AuthService.apiBaseUrl;
  static final AuthService _authService = AuthService();
  static final HtmlUnescape _unescape = HtmlUnescape();
  static bool? lastGenerateIsExist;

  // HTML 엔티티 디코딩 함수 (문자열만 처리)
  static String _decodeHtmlString(String text) {
    return _unescape.convert(text);
  }

  // 추천 채널 가져오기
  static Future<List<RssChannel>> fetchRecommendedChannels() async {
    try {
      final response = await _authService.apiRequest(
        'GET',
        '/rss/recommend/channel',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 채널의 필드별로 처리
        return jsonResponse.map((channel) {
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
      final response = await _authService.apiRequest(
        'GET',
        '/rss/items?channel_id=$channelId',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 아이템의 필드별로 처리
        return jsonResponse.map((item) {
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
      final response = await _authService.apiRequest(
        'GET',
        '/rss/preview?rss_link=$rssLink',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 필드별로 처리
        if (jsonResponse['channel_title'] is String) {
          jsonResponse['channel_title'] = _decodeHtmlString(
            jsonResponse['channel_title'],
          );
        }
        if (jsonResponse['channel_description'] is String) {
          jsonResponse['channel_description'] = _decodeHtmlString(
            jsonResponse['channel_description'],
          );
        }
        if (jsonResponse['channel_link'] is String) {
          jsonResponse['channel_link'] = _decodeHtmlString(
            jsonResponse['channel_link'],
          );
        }

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
      final response = await _authService.apiRequest(
        'POST',
        '/rss/channel',
        body: {"rss_link": rssLink},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        final value = json.decode(decodedResponse);

        if (value is int) {
          debugPrint('Channel added with ID: $value');
          return value;
        }

        debugPrint('Channel added but no ID returned');
        return null;
      } else {
        debugPrint(
          'Failed to add RSS: ${response.statusCode}, ${response.body}',
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
      final response = await _authService.apiRequest(
        'POST',
        '/subscription/channel_sub',
        body: {"channel_id": channelId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to subscribe channel: ${response.statusCode}, ${response.body}',
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
      int? id = await getChannelId(channelRssLink);
      debugPrint('Channel ID: $id');

      final response = await _authService.apiRequest(
        'POST',
        '/subscription/channel',
        body: {"channel_id": id},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to subscribe channel: ${response.statusCode}, ${response.body}',
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
      final response = await _authService.apiRequest(
        'GET',
        '/rss/id?channel_rss_link=$channelRssLink',
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
      final response = await _authService.apiRequest(
        'DELETE',
        '/subscription/channel',
        body: {"channel_id": channelId},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to unsubscribe channel: ${response.statusCode}, ${response.body}',
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
      final String channelIdsString = channelIds.join(',');

      final response = await _authService.apiRequest(
        'GET',
        '/subscription/items?channel_ids=$channelIdsString',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 아이템의 필드별로 처리
        return jsonResponse.map((item) {
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
      } else {
        debugPrint(
          'Failed to fetch subscribed items: ${response.statusCode}, ${response.body}',
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
      final response = await _authService.apiRequest(
        'GET',
        '/subscription/channels',
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(decodedResponse);

        // HTML 엔티티 디코딩 - 각 채널의 필드별로 처리
        return jsonResponse.map((channel) {
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
      } else {
        debugPrint(
          'Failed to fetch subscribed channels: ${response.statusCode}, ${response.body}',
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
      final response = await _authService.apiRequest(
        'GET',
        '/subscription/status?channel_rss_link=$channelRssLink',
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedResponse);
        return jsonResponse == true;
      } else {
        debugPrint(
          'Failed to check subscription status: ${response.statusCode}, ${response.body}',
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
      final response = await _authService.apiRequest(
        'GET',
        '/rss/exist?rss_link=$rssLink',
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
      final response = await _authService.apiRequest(
        'PUT',
        '/rss/item/rank',
        body: {"rss_id": rssId, "num": 1},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to update RSS rank: ${response.statusCode}, ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating RSS rank: $e');
      return false;
    }
  }

  // RSS 생성 API

  static Future<RssChannel?> generateRss(String url, String kind) async {
    try {
      final response = await _authService.apiRequest(
        'POST',
        '/premium/rss/generate',
        body: {"channel_link": url, "kind": kind},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        // 새 형식: 래핑된 형태 처리
        Map<String, dynamic> channelJson;
        if (jsonResponse.containsKey('channel') &&
            jsonResponse['channel'] is Map<String, dynamic>) {
          // is_exist 플래그 저장
          lastGenerateIsExist = jsonResponse['is_exist'] == true;

          channelJson = Map<String, dynamic>.from(jsonResponse['channel']);
        } else {
          // 하위 호환: 기존 형식 (루트에 채널 필드가 직접 존재)
          lastGenerateIsExist = null;
          channelJson = Map<String, dynamic>.from(jsonResponse);
        }

        // HTML 엔티티 디코딩
        if (channelJson['channel_title'] is String) {
          channelJson['channel_title'] = _decodeHtmlString(
            channelJson['channel_title'],
          );
        }
        if (channelJson['channel_description'] is String) {
          channelJson['channel_description'] = _decodeHtmlString(
            channelJson['channel_description'],
          );
        }
        if (channelJson['channel_link'] is String) {
          channelJson['channel_link'] = _decodeHtmlString(
            channelJson['channel_link'],
          );
        }

        return RssChannel.fromJson(channelJson);
      } else {
        debugPrint('RSS 생성 실패: ${response.statusCode}, ${response.body}');
        lastGenerateIsExist = null;
        return null;
      }
    } catch (e) {
      debugPrint('RSS 생성 중 오류 발생: $e');
      lastGenerateIsExist = null;
      return null;
    }
  }

  static Future<RssChannel?> generateRssByCss(Map<String, String> body) async {
    try {
      final response = await _authService.apiRequest(
        'POST',
        '/premium/rss/generate_by_css',
        body: body,
      );
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse = json.decode(decodedResponse);

        // is_exist 플래그 저장
        lastGenerateIsExist = jsonResponse['is_exist'] == true;

        if (jsonResponse.containsKey('channel') &&
            jsonResponse['channel'] is Map<String, dynamic>) {
          final channelJson = Map<String, dynamic>.from(
            jsonResponse['channel'],
          );
          // HTML 엔티티 디코딩 필요시 기존처럼 추가
          return RssChannel.fromJson(channelJson);
        }
      }
      return null;
    } catch (e) {
      debugPrint('RSS CSS 방식 생성 오류: $e');
      lastGenerateIsExist = null;
      return null;
    }
  }
}
