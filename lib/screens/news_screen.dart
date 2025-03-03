import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/services/news_service.dart';
import 'package:omninews_flutter/widgets/news_list_view.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  createState() => NewsScreenState();
}

/*
* 정치 : 100
* 경제 : 101
* 사회 : 102
* 생활/문화 : 103
* 세계 : 104
* IT/과학 : 105
*/
class NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> categories = [
    "정치",
    "경제",
    "사회",
    "생활/문화",
    "세계",
    "IT/과학",
  ];

  Map<String, Future<List<News>>> newsList = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    fetchAllNewsLists();
  }

  void fetchAllNewsLists() {
    for (var category in categories) {
      newsList[category] = NewsService.fetchNews(category);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      fetchAllNewsLists();
    });
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
          return NewsListView(newsList: newsList[category]!);
        }).toList(),
      ),
    );
  }
}
