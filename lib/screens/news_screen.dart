import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'rss_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  createState() => NewsScreenState();
}

class NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> categories = [
    "사회",
    "경제",
    "정치",
    "과학기술",
    "Apple",
    "연예",
    "스포츠",
  ];
  Map<String, Future<List<Rss>>> rssLists = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    fetchAllRssLists();
  }

  void fetchAllRssLists() {
    for (var category in categories) {
      rssLists[category] = fetchRss(category);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      fetchAllRssLists();
    });
  }

  void _addCategory(String category) {
    setState(() {
      categories.add(category);
      rssLists[category] = fetchRss(category);
      _tabController.dispose();
      _tabController = TabController(length: categories.length, vsync: this);
    });
  }

  Future<List<Rss>> fetchRss(String category) async {
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8080/search/rss"),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "search_value": category,
          "search_type": "Accuracy",
        }),
      );

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse.map((rss) => Rss.fromJson(rss)).toList();
      } else {
        throw Exception('Failed to load RSS');
      }
    } catch (e) {
      //print('Error fetching RSS: $e');
      throw Exception('Failed to load RSS');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              String? category = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController controller = TextEditingController();
                  return AlertDialog(
                    title: const Text('카테고리 추가'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: '카테고리 이름'),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(controller.text);
                        },
                        child: const Text('추가'),
                      ),
                    ],
                  );
                },
              );
              if (category != null && category.isNotEmpty) {
                _addCategory(category);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          return RssListView(rssList: rssLists[category]!);
        }).toList(),
      ),
    );
  }
}

class RssListView extends StatelessWidget {
  final Future<List<Rss>> rssList;

  const RssListView({super.key, required this.rssList});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Rss>>(
      future: rssList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          List<Rss>? data = snapshot.data;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data?.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    data![index].rssTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Published on: ${data[index].rssPubDate}'),
                      Text('Author: ${data[index].rssAuthor}'),
                    ],
                  ),
                  trailing: data[index].rssImageLink.isNotEmpty
                      ? Image.network(
                          data[index].rssImageLink,
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
                        builder: (context) => RssDetailScreen(rss: data[index]),
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

class Rss {
  final int rssId;
  final int channelId;
  final String rssTitle;
  final String rssDescription;
  final String rssLink;
  final String rssAuthor;
  final String rssPubDate;
  final int rssRank;
  final String rssImageLink;

  Rss({
    required this.rssId,
    required this.channelId,
    required this.rssTitle,
    required this.rssDescription,
    required this.rssLink,
    required this.rssAuthor,
    required this.rssPubDate,
    required this.rssRank,
    required this.rssImageLink,
  });

  factory Rss.fromJson(Map<String, dynamic> json) {
    return Rss(
      rssId: json['rss_id'],
      channelId: json['channel_id'],
      rssTitle: json['rss_title'],
      rssDescription: json['rss_description'],
      rssLink: json['rss_link'],
      rssAuthor: json['rss_author'],
      rssPubDate: json['rss_pub_date'],
      rssRank: json['rss_rank'],
      rssImageLink: json['rss_image_link'],
    );
  }
}
