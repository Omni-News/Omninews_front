import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html_unescape/html_unescape.dart';

class NewsBookmarkService {
  static const String newsBookmarksKey = 'news_bookmarks';
  static const String newsApiBookmarksKey = 'news_api_bookmarks';
  static final HtmlUnescape _unescape = HtmlUnescape();

  // HTML 엔티티 디코딩 함수 (문자열만 처리)
  static String _decodeHtmlString(String text) {
    return _unescape.convert(text);
  }

  // 북마크된 뉴스 가져오기 (News)
  static Future<List<News>> getBookmarkedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsBookmarksKey) ?? [];

      return bookmarksJson.map((json) {
          Map<String, dynamic> data = jsonDecode(json);

          // 문자열 필드만 디코딩
          if (data['title'] is String) {
            data['title'] = _decodeHtmlString(data['title']);
          }
          if (data['description'] is String) {
            data['description'] = _decodeHtmlString(data['description']);
          }
          if (data['content'] is String) {
            data['content'] = _decodeHtmlString(data['content']);
          }
          if (data['summary'] is String) {
            data['summary'] = _decodeHtmlString(data['summary']);
          }
          if (data['source'] is String) {
            data['source'] = _decodeHtmlString(data['source']);
          }

          return News.fromJson(data);
        }).toList()
        ..sort((a, b) {
          try {
            final dateA = DateTime.parse(a.newsPubDate);
            final dateB = DateTime.parse(b.newsPubDate);
            return dateB.compareTo(dateA); // 최신순 정렬
          } catch (e) {
            return 0;
          }
        });
    } catch (e) {
      debugPrint('Error getting bookmarked news: $e');
      return [];
    }
  }

  // 북마크된 뉴스 API 가져오기 (NewsApi)
  static Future<List<NewsApi>> getBookmarkedNewsApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsApiBookmarksKey) ?? [];

      return bookmarksJson.map((json) {
          Map<String, dynamic> data = jsonDecode(json);

          // 문자열 필드만 디코딩
          if (data['title'] is String) {
            data['title'] = _decodeHtmlString(data['title']);
          }
          if (data['description'] is String) {
            data['description'] = _decodeHtmlString(data['description']);
          }
          if (data['link'] is String) {
            data['link'] = _decodeHtmlString(data['link']);
          }
          if (data['originallink'] is String) {
            data['originallink'] = _decodeHtmlString(data['originallink']);
          }

          return NewsApi.fromJson(data);
        }).toList()
        ..sort((a, b) {
          try {
            final dateA = DateTime.parse(a.newsPubDate);
            final dateB = DateTime.parse(b.newsPubDate);
            return dateB.compareTo(dateA); // 최신순 정렬
          } catch (e) {
            return 0;
          }
        });
    } catch (e) {
      debugPrint('Error getting bookmarked news API: $e');
      return [];
    }
  }

  // 모든 북마크된 뉴스 가져오기 (News 형식으로 변환하여 통합)
  static Future<List<News>> getAllBookmarkedNewsAsNews() async {
    try {
      final newsItems = await getBookmarkedNews();
      final newsApiItems = await getBookmarkedNewsApi();

      // NewsApi를 News 형식으로 변환
      final convertedApiItems =
          newsApiItems
              .map(
                (apiItem) => News(
                  newsId: 0, // 로컬 용도라 ID는 0으로 설정
                  newsTitle: _removeHtmlTags(
                    _decodeHtmlString(apiItem.newsTitle),
                  ),
                  newsLink: apiItem.newsOriginalLink,
                  newsDescription: _removeHtmlTags(
                    _decodeHtmlString(apiItem.newsDescription),
                  ),
                  newsSummary: _decodeHtmlString(apiItem.newsDescription),
                  newsPubDate: apiItem.newsPubDate,
                  newsSource: _extractDomain(apiItem.newsOriginalLink),
                  newsImageLink: '', // API에서 이미지 URL이 없을 수 있음
                ),
              )
              .toList();

      // 두 목록 합치기
      final allItems = [...newsItems, ...convertedApiItems];

      // 날짜순 정렬
      allItems.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.newsPubDate);
          final dateB = DateTime.parse(b.newsPubDate);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return allItems;
    } catch (e) {
      debugPrint('Error getting all bookmarked news: $e');
      return [];
    }
  }

  // 뉴스 북마크 추가 (News)
  static Future<bool> addNewsBookmark(News news) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsBookmarksKey) ?? [];

      // 이미 북마크되어 있는지 확인
      final exists = bookmarksJson.any((json) {
        final existingNews = News.fromJson(jsonDecode(json));
        return existingNews.newsLink == news.newsLink;
      });

      if (!exists) {
        // 저장 전 HTML 엔티티 디코딩
        Map<String, dynamic> newsJson = news.toJson();

        bookmarksJson.add(jsonEncode(newsJson));
        await prefs.setStringList(newsBookmarksKey, bookmarksJson);
      }
      return true;
    } catch (e) {
      debugPrint('Error adding news bookmark: $e');
      return false;
    }
  }

  // 뉴스 API 북마크 추가 (NewsApi)
  static Future<bool> addNewsApiBookmark(NewsApi news) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsApiBookmarksKey) ?? [];

      // 이미 북마크되어 있는지 확인
      final exists = bookmarksJson.any((json) {
        final existingNews = NewsApi.fromJson(jsonDecode(json));
        return existingNews.newsOriginalLink == news.newsOriginalLink;
      });

      if (!exists) {
        // 저장 전 HTML 엔티티 디코딩
        Map<String, dynamic> newsJson = news.toJson();

        bookmarksJson.add(jsonEncode(newsJson));
        await prefs.setStringList(newsApiBookmarksKey, bookmarksJson);
      }
      return true;
    } catch (e) {
      debugPrint('Error adding news API bookmark: $e');
      return false;
    }
  }

  // 뉴스 북마크 제거 (News)
  static Future<bool> removeNewsBookmark(String newsLink) async {
    try {
      bool removed = false;
      final prefs = await SharedPreferences.getInstance();

      // 1. 먼저 일반 뉴스 북마크에서 찾기
      final newsBookmarksJson = prefs.getStringList(newsBookmarksKey) ?? [];
      int initialNewsCount = newsBookmarksJson.length;

      newsBookmarksJson.removeWhere((json) {
        // <--- ✅ 수정된 로직 시작
        // data['link'] 대신 News.fromJson을 사용
        try {
          final existingNews = News.fromJson(jsonDecode(json));
          return existingNews.newsLink == newsLink;
        } catch (e) {
          debugPrint('Error decoding news for removal: $e');
          return false;
        }
        // <--- ✅ 수정된 로직 끝
      });

      // 북마크가 제거되었는지 확인
      if (initialNewsCount > newsBookmarksJson.length) {
        await prefs.setStringList(newsBookmarksKey, newsBookmarksJson);
        removed = true;
      }

      // 2. 일반 뉴스에서 제거되지 않았으면 NewsApi 북마크에서 찾기
      if (!removed) {
        final newsApiBookmarksJson =
            prefs.getStringList(newsApiBookmarksKey) ?? [];
        int initialApiNewsCount = newsApiBookmarksJson.length;

        newsApiBookmarksJson.removeWhere((json) {
          Map<String, dynamic> data = jsonDecode(json);
          String originalLink = data['originallink']?.toString() ?? '';
          String link = data['link']?.toString() ?? '';
          return originalLink == newsLink || link == newsLink;
        });

        // NewsApi 북마크에서 제거되었는지 확인
        if (initialApiNewsCount > newsApiBookmarksJson.length) {
          await prefs.setStringList(newsApiBookmarksKey, newsApiBookmarksJson);
          removed = true;
        }
      }

      return removed;
    } catch (e) {
      debugPrint('Error removing news bookmark: $e');
      return false;
    }
  }

  // 뉴스 API 북마크 제거 (NewsApi)
  static Future<bool> removeNewsApiBookmark(String newsLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsApiBookmarksKey) ?? [];

      bookmarksJson.removeWhere((json) {
        Map<String, dynamic> data = jsonDecode(json);
        String originalLink = data['originallink']?.toString() ?? '';
        return originalLink == newsLink;
      });

      await prefs.setStringList(newsApiBookmarksKey, bookmarksJson);
      return true;
    } catch (e) {
      debugPrint('Error removing news API bookmark: $e');
      return false;
    }
  }

  // 뉴스가 북마크되어 있는지 확인 (News)
  static Future<bool> isNewsBookmarked(String newsLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsBookmarksKey) ?? [];

      return bookmarksJson.any((json) {
        // <--- ✅ 수정된 로직 시작
        // data['link'] 대신 News.fromJson을 사용
        try {
          final existingNews = News.fromJson(jsonDecode(json));
          return existingNews.newsLink == newsLink;
        } catch (e) {
          debugPrint('Error decoding news for check: $e');
          return false;
        }
        // <--- ✅ 수정된 로직 끝
      });
    } catch (e) {
      debugPrint('Error checking news bookmark status: $e');
      return false;
    }
  }

  // 뉴스 API가 북마크되어 있는지 확인 (NewsApi)
  static Future<bool> isNewsApiBookmarked(String newsLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(newsApiBookmarksKey) ?? [];

      return bookmarksJson.any((json) {
        Map<String, dynamic> data = jsonDecode(json);
        String originalLink = data['originallink']?.toString() ?? '';
        return originalLink == newsLink;
      });
    } catch (e) {
      debugPrint('Error checking news API bookmark status: $e');
      return false;
    }
  }

  // 북마크된 뉴스 검색 (통합)
  static Future<List<News>> searchAllBookmarkedNews(String query) async {
    try {
      final allBookmarkedNews = await getAllBookmarkedNewsAsNews();
      final decodedQuery = _decodeHtmlString(query.toLowerCase());

      return allBookmarkedNews.where((news) {
        String decodedTitle = _decodeHtmlString(news.newsTitle.toLowerCase());
        String decodedDescription = _decodeHtmlString(
          news.newsDescription.toLowerCase(),
        );

        return decodedTitle.contains(decodedQuery) ||
            decodedDescription.contains(decodedQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching bookmarked news: $e');
      return [];
    }
  }

  // HTML 태그 제거 유틸리티 함수
  static String _removeHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  // 도메인 추출 유틸리티 함수
  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return url;
    }
  }

  static Future<bool> isAnyBookmarked(String newsLink) async {
    // News 형식으로 북마크되었는지 확인
    final isNewsBookmark = await isNewsBookmarked(newsLink);
    if (isNewsBookmark) return true;

    // NewsApi 형식으로 북마크되었는지 확인
    final isNewsApiBookmark = await isNewsApiBookmarked(newsLink);
    return isNewsApiBookmark;
  }

  // 북마크된 모든 뉴스 항목을 원본 타입으로 구분해서 가져오기
  static Future<Map<String, dynamic>> getAllBookmarkedNewsByType() async {
    try {
      // News 타입 북마크 가져오기
      final newsItems = await getBookmarkedNews();

      // NewsApi 타입 북마크 가져오기
      final newsApiItems = await getBookmarkedNewsApi();

      // 명시적으로 Map<String, dynamic> 타입으로 만듦
      Map<String, dynamic> result = {
        'news': newsItems,
        'newsApi': newsApiItems,
      };
      return result;
    } catch (e) {
      debugPrint('Error getting all bookmarked news by type: $e');
      return {'news': <News>[], 'newsApi': <NewsApi>[]};
    }
  }

  // 통합 검색 기능 (타입별로 분리)
  static Future<Map<String, dynamic>> searchAllBookmarkedNewsByType(
    String query,
  ) async {
    try {
      // 검색어 디코딩
      final decodedQuery = _decodeHtmlString(query.toLowerCase());

      // News 북마크 검색
      final newsItems = await getBookmarkedNews();
      final filteredNews =
          newsItems.where((news) {
            String decodedTitle = _decodeHtmlString(
              news.newsTitle.toLowerCase(),
            );
            String decodedDescription = _decodeHtmlString(
              news.newsDescription.toLowerCase(),
            );

            return decodedTitle.contains(decodedQuery) ||
                decodedDescription.contains(decodedQuery);
          }).toList();

      // NewsApi 북마크 검색
      final newsApiItems = await getBookmarkedNewsApi();
      final filteredNewsApi =
          newsApiItems.where((newsApi) {
            String decodedTitle =
                _decodeHtmlString(
                  _removeHtmlTags(newsApi.newsTitle),
                ).toLowerCase();
            String decodedDescription =
                _decodeHtmlString(
                  _removeHtmlTags(newsApi.newsDescription),
                ).toLowerCase();

            return decodedTitle.contains(decodedQuery) ||
                decodedDescription.contains(decodedQuery);
          }).toList();

      // 명시적으로 Map<String, dynamic> 타입으로 만듦
      Map<String, dynamic> result = {
        'news': filteredNews,
        'newsApi': filteredNewsApi,
      };
      return result;
    } catch (e) {
      debugPrint('Error searching bookmarked news by type: $e');
      return {'news': <News>[], 'newsApi': <NewsApi>[]};
    }
  }
}
