import 'package:flutter/material.dart';
import 'package:omninews_flutter/screens/news_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

class RssDetailScreen extends StatelessWidget {
  final Rss rss;

  const RssDetailScreen({super.key, required this.rss});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rss.rssTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(rss.rssLink);
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
              rss.rssTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Published on: ${rss.rssPubDate}'),
            Text('Author: ${rss.rssAuthor}'),
            SizedBox(height: 16),
            Text(
              rss.rssDescription,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse(rss.rssLink);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch ${rss.rssLink}';
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
