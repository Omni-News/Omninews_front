import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/screens/news_detail_screen.dart';

class NewsListView extends StatelessWidget {
  final Future<List<News>> newsList;

  const NewsListView({super.key, required this.newsList});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<News>>(
      future: newsList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          List<News>? data = snapshot.data;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data?.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    data![index].newsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Published on: ${data[index].newsPubDate}'),
                      Text('Author: ${data[index].newsSource}'),
                    ],
                  ),
                  trailing: data[index].newsImageLink.isNotEmpty
                      ? Image.network(
                          data[index].newsImageLink,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RssDetailScreen(news: data[index]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('No data found.'));
        }
      },
    );
  }
}
