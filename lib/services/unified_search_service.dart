import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/news_api_service.dart';
import 'package:omninews_flutter/services/rss_search_service.dart';

class UnifiedSearchResult {
  final List<NewsApi> newsResults;
  final List<RssItem> rssItemResults;
  final List<RssChannel> rssChannelResults;

  UnifiedSearchResult({
    required this.newsResults,
    required this.rssItemResults,
    required this.rssChannelResults,
  });
}

class UnifiedSearchService {
  static Future<UnifiedSearchResult> search(String query,
      {String sort = 'sim'}) async {
    // 세 API 요청을 병렬로 실행하되, 각각 개별적으로 결과를 받음
    final newsApiFuture = NewsApiService.fetchNews(query, 20, sort);
    final rssItemsFuture = RssSearchService.searchRssItems(query, sort);
    final channelsFuture = RssSearchService.searchChannels(query, sort);

    // 개별적으로 결과 가져오기
    final newsApiResults = await newsApiFuture;
    final rssItemResults = await rssItemsFuture;
    final channelResults = await channelsFuture;

    return UnifiedSearchResult(
      newsResults: newsApiResults,
      rssItemResults: rssItemResults,
      rssChannelResults: channelResults,
    );
  }
}
