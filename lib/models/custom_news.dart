class CustomNews {
  final String title;
  final String originalLink;
  final String link;
  final String description;
  final String pubDate;

  CustomNews({
    required this.title,
    required this.originalLink,
    required this.link,
    required this.description,
    required this.pubDate,
  });

  factory CustomNews.fromJson(Map<String, dynamic> json) {
    return CustomNews(
      title: json['news_title'] ?? '',
      originalLink: json['news_original_link'] ?? '',
      link: json['news_link'] ?? '',
      description: json['news_description'] ?? '',
      pubDate: json['news_pub_date'] ?? '',
    );
  }

  // HTML 태그 제거 메소드
  String get plainTitle {
    return title.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get plainDescription {
    return description.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // 날짜 포맷팅 메소드
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(pubDate);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return pubDate;
    }
  }
}
