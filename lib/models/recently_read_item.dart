import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/news.dart';

enum ReadItemType {
  rss,
  news,
}

class RecentlyReadItem {
  final int id;
  final String title;
  final String description;
  final String link;
  final String imageUrl;
  final String source;
  final String pubDate;
  final ReadItemType type;
  final DateTime readAt;

  RecentlyReadItem({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.source,
    required this.pubDate,
    required this.type,
    required this.readAt,
    this.imageUrl = '',
  });

  // RSS 아이템으로부터 생성
  factory RecentlyReadItem.fromRssItem(RssItem item) {
    return RecentlyReadItem(
      id: 0,
      title: item.rssTitle,
      description: item.rssDescription,
      link: item.rssLink,
      source: "",
      pubDate: item.rssPubDate,
      imageUrl: item.rssImageLink ?? '',
      type: ReadItemType.rss,
      readAt: DateTime.now(),
    );
  }

  // News 아이템으로부터 생성
  factory RecentlyReadItem.fromNews(News news) {
    return RecentlyReadItem(
      id: 0,
      title: news.newsTitle,
      description: news.newsDescription,
      link: news.newsLink,
      source: news.newsSource,
      pubDate: news.newsPubDate,
      imageUrl: news.newsImageLink,
      type: ReadItemType.news,
      readAt: DateTime.now(),
    );
  }

  factory RecentlyReadItem.fromCustomNews(CustomNews news) {
    return RecentlyReadItem(
      id: 0,
      title: news.title,
      description: news.description,
      link: news.link,
      source: "",
      pubDate: news.pubDate,
      imageUrl: "",
      type: ReadItemType.news,
      readAt: DateTime.now(),
    );
  }

  factory RecentlyReadItem.fromApiNews(NewsApi news) {
    return RecentlyReadItem(
      id: 0,
      title: news.newsTitle,
      description: news.newsDescription,
      link: news.newsLink,
      source: news.newsOriginalLink,
      pubDate: news.newsPubDate,
      imageUrl: "",
      type: ReadItemType.news,
      readAt: DateTime.now(),
    );
  }
  // JSON으로부터 생성
  factory RecentlyReadItem.fromJson(Map<String, dynamic> json) {
    return RecentlyReadItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      link: json['link'],
      source: json['source'],
      pubDate: json['pubDate'],
      imageUrl: json['imageUrl'] ?? '',
      type: ReadItemType.values[json['type']],
      readAt: DateTime.parse(json['readAt']),
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'link': link,
      'source': source,
      'pubDate': pubDate,
      'imageUrl': imageUrl,
      'type': type.index,
      'readAt': readAt.toIso8601String(),
    };
  }

  // RSS 아이템으로 변환
  RssItem toRssItem() {
    return RssItem(
        rssId: 0,
        rssTitle: title,
        rssDescription: description,
        rssLink: link,
        rssPubDate: pubDate,
        rssImageLink: imageUrl.isNotEmpty ? imageUrl : null,
        rssRank: 0,
        channelId: 0);
  }

  // News 객체로 변환
  News toNews() {
    return News(
      newsId: 0,
      newsTitle: title,
      newsDescription: description,
      newsLink: link,
      newsSource: source,
      newsPubDate: pubDate,
      newsImageLink: imageUrl,
    );
  }
}
