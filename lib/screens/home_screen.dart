import 'package:flutter/material.dart';
import 'package:omninews_flutter/screens/settings_screen.dart';
import 'package:omninews_flutter/screens/subscribe_screen.dart';
import 'package:omninews_flutter/screens/bookmark_screen.dart';
import 'package:omninews_flutter/screens/news_screen.dart';
import 'package:omninews_flutter/screens/rss_screen.dart';
import 'package:omninews_flutter/screens/search_screen.dart';
import 'package:omninews_flutter/theme/theme_selection_dialog.dart';

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

  // 테마 선택 다이얼로그 표시
  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (_) => const ThemeSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 테마 속성 가져오기
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      key: homeScaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: Drawer(
        backgroundColor: theme.drawerTheme.backgroundColor,
        child: Column(
          children: [
            // 헤더 부분 - 다크 모드에서는 어두운 색상 사용
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                // 다크 모드일 때 어두운 색상, 라이트 모드일 때는 기존 primaryColor 사용
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1A2038) // 다크 모드용 어두운 색상
                    : theme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 50, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omni News',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your News, Your Way',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 피드 섹션
                  _buildSectionHeader('MY FEEDS', theme.colorScheme.secondary),

                  _buildDrawerItem(
                    icon: Icons.access_time,
                    title: 'Recently Read',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.subscriptions_outlined,
                    title: 'Subscriptions',
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(0);
                    },
                    isSelected: _selectedIndex == 0,
                  ),

                  _buildDrawerItem(
                    icon: Icons.rss_feed_outlined,
                    title: 'RSS Feeds',
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(1);
                    },
                    isSelected: _selectedIndex == 1,
                  ),

                  _buildDrawerItem(
                    icon: Icons.newspaper_outlined,
                    title: 'News',
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(2);
                    },
                    isSelected: _selectedIndex == 2,
                  ),

                  _buildDrawerItem(
                    icon: Icons.bookmark_outline_sharp,
                    title: 'Bookmarks',
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(3);
                    },
                    isSelected: _selectedIndex == 3,
                  ),

                  const Divider(),

                  // 설정 섹션
                  _buildSectionHeader(
                      'PREFERENCES', theme.colorScheme.secondary),

                  _buildDrawerItem(
                    icon: Icons.color_lens_outlined,
                    title: 'Choose Theme',
                    onTap: () {
                      Navigator.pop(context);
                      _showThemeSelectionDialog();
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()));
                    },
                  ),

                  const Divider(),

                  // 추가 섹션 - About & Help
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Feedback',
                    onTap: () {
                      Navigator.pop(context);
                    },
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
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
              theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions_outlined),
              activeIcon: Icon(Icons.subscriptions),
              label: 'Sub',
              tooltip: 'Subscriptions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rss_feed_outlined),
              activeIcon: Icon(Icons.rss_feed),
              label: 'RSS',
              tooltip: 'RSS Feeds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'News',
              tooltip: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks_outlined),
              activeIcon: Icon(Icons.bookmarks),
              label: 'Bookmarks',
              tooltip: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
              tooltip: 'Search',
            ),
          ],
        ),
      ),
    );
  }

  // 드로어 섹션 헤더를 위한 위젯
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // 드로어 아이템을 위한 위젯
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
      dense: true,
      onTap: onTap,
      selected: isSelected,
      selectedTileColor:
          isSelected ? theme.colorScheme.primary.withOpacity(0.12) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      minLeadingWidth: 24,
    );
  }
}
