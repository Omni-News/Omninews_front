import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/news_api_service.dart';
import 'package:omninews_flutter/services/rss_search_service.dart';

class UnifiedSearchResult {
  final List<NewsApi> newsResults;
  final List<RssItem> rssItemResults;
  final List<RssChannel> rssChannelResults;
  final int page;
  final bool hasNextRssItems;
  final bool hasNextChannels;

  UnifiedSearchResult({
    required this.newsResults,
    required this.rssItemResults,
    required this.rssChannelResults,
    this.page = 1,
    this.hasNextRssItems = false,
    this.hasNextChannels = false,
  });

  UnifiedSearchResult copyWith({
    List<NewsApi>? newsResults,
    List<RssItem>? rssItemResults,
    List<RssChannel>? rssChannelResults,
    int? page,
    bool? hasNextNews,
    bool? hasNextRssItems,
    bool? hasNextChannels,
  }) {
    return UnifiedSearchResult(
      newsResults: newsResults ?? this.newsResults,
      rssItemResults: rssItemResults ?? this.rssItemResults,
      rssChannelResults: rssChannelResults ?? this.rssChannelResults,
      page: page ?? this.page,
      hasNextRssItems: hasNextRssItems ?? this.hasNextRssItems,
      hasNextChannels: hasNextChannels ?? this.hasNextChannels,
    );
  }
}

class UnifiedSearchService {
  static Future<UnifiedSearchResult> search(
    String query, {
    String sort = 'sim',
    int page = 1,
  }) async {
    // 세 API 요청을 병렬로 실행하되, 각각 개별적으로 결과를 받음
    final newsApiFuture = NewsApiService.fetchNews(query, 20, sort);
    final rssItemsFuture = RssSearchService.searchRssItems(query, sort, page);
    final channelsFuture = RssSearchService.searchChannels(query, sort, page);

    // 개별적으로 결과 가져오기
    print('UnifiedSearchService: API 요청 완료, 응답 대기 중');

    final newsApiResults = await newsApiFuture;
    final rssItemResults = await rssItemsFuture;
    final channelResults = await channelsFuture;

    return UnifiedSearchResult(
      newsResults: newsApiResults,
      rssItemResults: rssItemResults.items,
      rssChannelResults: channelResults.channels,
      page: page,
      hasNextRssItems: rssItemResults.hasNext,
      hasNextChannels: channelResults.hasNext,
    );
  }
}
