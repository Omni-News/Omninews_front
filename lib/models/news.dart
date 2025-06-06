class News {
  final int newsId;
  final String newsTitle;
  final String newsDescription;
  final String newsSummary;
  final String newsLink;
  final String newsSource;
  final String newsPubDate;
  final String newsImageLink;

  News({
    required this.newsId,
    required this.newsTitle,
    required this.newsDescription,
    required this.newsSummary,
    required this.newsLink,
    required this.newsSource,
    required this.newsPubDate,
    required this.newsImageLink,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      newsId: json['news_id'],
      newsTitle: json['news_title'],
      newsDescription: json['news_description'],
      newsSummary: json['news_summary'] ?? '',
      newsLink: json['news_link'],
      newsSource: json['news_source'],
      newsPubDate: json['news_pub_date'] ?? 'Unknown',
      newsImageLink: json['news_image_link'] ?? '',
    );
  }

  toJson() {
    return {
      'news_id': newsId,
      'news_title': newsTitle,
      'news_description': newsDescription,
      'news_summary': newsSummary,
      'news_link': newsLink,
      'news_source': newsSource,
      'news_pub_date': newsPubDate,
      'news_image_link': newsImageLink,
    };
  }
}

class NewsApi {
  final String newsTitle;
  final String newsDescription;
  final String newsLink;
  final String newsOriginalLink;
  final String newsPubDate;

  NewsApi({
    required this.newsTitle,
    required this.newsDescription,
    required this.newsLink,
    required this.newsOriginalLink,
    required this.newsPubDate,
  });

  factory NewsApi.fromJson(Map<String, dynamic> json) {
    return NewsApi(
      newsTitle: json['news_title'] ?? '',
      newsDescription: json['news_description'] ?? '',
      newsLink: json['news_link'] ?? '',
      newsOriginalLink: json['news_original_link'] ?? '',
      newsPubDate: json['news_pub_date'] ?? '',
    );
  }

  // HTML 태그가 제거된 제목
  String get plainTitle {
    return newsTitle.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // HTML 태그가 제거된 설명
  String get plainDescription {
    return newsDescription.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  toJson() {
    return {
      'news_title': newsTitle,
      'news_description': newsDescription,
      'news_link': newsLink,
      'news_original_link': newsOriginalLink,
      'news_pub_date': newsPubDate,
    };
  }
}
