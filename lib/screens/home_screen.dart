import 'package:flutter/material.dart';
import 'package:omninews_flutter/screens/subscribe_screen.dart';
import 'package:omninews_flutter/screens/bookmark_screen.dart';
import 'package:omninews_flutter/screens/news_screen.dart';
import 'package:omninews_flutter/screens/rss_screen.dart';
import 'package:omninews_flutter/screens/search_screen.dart';

// 전역 키를 선언하여 어디서든 접근할 수 있게 합니다
final GlobalKey<ScaffoldState> homeScaffoldKey = GlobalKey<ScaffoldState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // NewsScreen에 scaffoldKey를 전달합니다
    _pages = [
      const SubscribeScreen(),
      const RssScreen(),
      const NewsScreen(),
      const BookmarkScreen(),
      const SearchScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 모던 색상 테마
    const primaryColor = Color(0xFF2979FF);
    const backgroundColor = Color(0xFFFAFAFA);
    const cardColor = Colors.white;
    const secondaryColor = Color(0xFF546E7A);

    return Scaffold(
      key: homeScaffoldKey, // 글로벌 키를 Scaffold에 할당
      backgroundColor: backgroundColor,
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 125,
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omni News',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your News, Your Way',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 카테고리 섹션
                  const Padding(
                    padding: EdgeInsets.fromLTRB(17, 16, 16, 8),
                    child: Text(
                      'MY FEEDS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Recently Read'),
                    dense: true,
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.subscriptions_outlined),
                    title: const Text('Subscriptions'),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(0); // BookmarkScreen 인덱스
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.rss_feed_outlined),
                    title: const Text('RSS Feeds'),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(1); // RssScreen 인덱스
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.newspaper_outlined),
                    title: const Text('News'),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(2); // NewsScreen 인덱스
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline_sharp),
                    title: const Text('Bookmarks'),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(3); // ExploreScreen 인덱스
                    },
                  ),

                  const Divider(),

                  // 설정 섹션
                  const Padding(
                    padding: EdgeInsets.fromLTRB(17, 8, 16, 8),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.color_lens_outlined),
                    title: const Text('Choose Theme'),
                    dense: true,
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    dense: true,
                    onTap: () {},
                  ),

                  const Divider(),

                  // 추가 섹션
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    dense: true,
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Feedback'),
                    dense: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: cardColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 9,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions_outlined),
              activeIcon: Icon(Icons.subscriptions),
              label: 'Sub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rss_feed_outlined),
              activeIcon: Icon(Icons.rss_feed),
              label: 'RSS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks_outlined),
              activeIcon: Icon(Icons.bookmarks),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }
}
