import 'package:flutter/material.dart';
import 'package:omninews_flutter/screens/bookmark_screen.dart';
import 'package:omninews_flutter/screens/explore_screen.dart';
import 'package:omninews_flutter/screens/news_screen.dart';
import 'package:omninews_flutter/screens/rss_screen.dart';
import 'package:omninews_flutter/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    BookmarkScreen(),
    RssScreen(),
    NewsScreen(),
    ExploreScreen(),
    SearchScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omni News'),
      ),
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Newticles',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(title: const Text('Recently Read'), onTap: () {}),
          ListTile(title: const Text('Choose Theme'), onTap: () {}),
          ListTile(title: const Text('Setting'), onTap: () {}),
        ],
      )),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '북마크'),
          BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: 'Rss'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: '뉴스'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '찾아보기'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
