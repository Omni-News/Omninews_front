import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

class RssDetailScreen extends StatelessWidget {
  final News news;

  const RssDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.newsTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(news.newsLink);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.newsTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Published on: ${news.newsPubDate}'),
            Text('Author: ${news.newsSource}'),
            SizedBox(height: 16),
            Text(
              news.newsDescription,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse(news.newsLink);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch ${news.newsLink}';
                  }
                },
                child: Text('Go to Website'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
