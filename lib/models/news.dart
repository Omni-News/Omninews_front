class News {
  final int newsId;
  final String newsTitle;
  final String newsDescription;
  final String newsLink;
  final String newsSource;
  final String newsPubDate;
  final String newsImageLink;

  News({
    required this.newsId,
    required this.newsTitle,
    required this.newsDescription,
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
      newsLink: json['news_link'],
      newsSource: json['news_source'],
      newsPubDate: json['news_pub_date'] ?? 'Unknown',
      newsImageLink: json['news_image_link'] ?? '',
    );
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
      newsTitle: json['news_title'],
      newsDescription: json['news_description'],
      newsLink: json['news_original_link'],
      newsOriginalLink: json['news_link'],
      newsPubDate: json['news_pub_date'],
    );
  }
}
