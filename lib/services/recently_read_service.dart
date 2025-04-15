import 'dart:convert';
import 'package:omninews_flutter/models/custom_news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omninews_flutter/models/recently_read_item.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/news.dart';

class RecentlyReadService {
  static const String _storageKey = 'recently_read_items';
  static const int _maxItems = 50; // 최대 저장 개수

  // 최근 읽은 글 목록 가져오기
  static Future<List<RecentlyReadItem>> getRecentlyReadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => RecentlyReadItem.fromJson(item)).toList();
    } catch (e) {
      print('Error loading recently read items: $e');
      return [];
    }
  }

  // RSS 아이템을 최근 읽은 글로 저장
  static Future<bool> addRssItem(RssItem item) async {
    final recentlyReadItem = RecentlyReadItem.fromRssItem(item);
    return await _addItem(recentlyReadItem);
  }

  // News 아이템을 최근 읽은 글로 저장
  static Future<bool> addNews(News news) async {
    final recentlyReadItem = RecentlyReadItem.fromNews(news);
    return await _addItem(recentlyReadItem);
  }

  static Future<bool> addCustomNews(CustomNews news) async {
    final recentlyReadItem = RecentlyReadItem.fromCustomNews(news);
    return await _addItem(recentlyReadItem);
  }

  static Future<bool> addApiNews(NewsApi news) async {
    final recentlyReadItem = RecentlyReadItem.fromApiNews(news);
    return await _addItem(recentlyReadItem);
  }

  // 아이템 추가 (내부 사용)
  static Future<bool> _addItem(RecentlyReadItem newItem) async {
    try {
      final items = await getRecentlyReadItems();

      // 이미 존재하는 항목 제거 (중복 방지)
      items.removeWhere((item) => item.link == newItem.link);

      // 새 아이템 추가 (최신 항목이 맨 앞에 오도록)
      items.insert(0, newItem);

      // 최대 개수 유지
      if (items.length > _maxItems) {
        items.removeRange(_maxItems, items.length);
      }

      return await _saveItems(items);
    } catch (e) {
      print('Error adding recently read item: $e');
      return false;
    }
  }

  // 목록 저장 (내부 사용)
  static Future<bool> _saveItems(List<RecentlyReadItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving recently read items: $e');
      return false;
    }
  }

  // 아이템 삭제
  static Future<bool> removeItem(String id) async {
    try {
      final items = await getRecentlyReadItems();
      items.removeWhere((item) => item.id == id);
      return await _saveItems(items);
    } catch (e) {
      print('Error removing recently read item: $e');
      return false;
    }
  }

  // 모든 아이템 삭제
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing recently read items: $e');
      return false;
    }
  }
}
