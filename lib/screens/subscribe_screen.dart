import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/services/rss_folder_service.dart';
import 'package:omninews_flutter/utils/ad_manager.dart';
import 'package:omninews_flutter/widgets/subscribe_date_view.dart';
import 'package:omninews_flutter/widgets/subscribe_folder_view.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:provider/provider.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RssItem>> _subscribedItems;
  late Future<List<RssFolder>> _folders;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final List<String> _tabs = ['날짜별 보기', '폴더별 보기'];

  // 테마 체크를 위한 변수
  ThemeData? _currentTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 테마 변경 감지
    final newTheme = Theme.of(context);
    if (_currentTheme != null && _currentTheme != newTheme) {
      // 테마가 변경되었을 때 TabController 재생성
      _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: _tabController.index,
      );
      setState(() {});
    }
    _currentTheme = newTheme;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _subscribedItems = SubscribeService.getSubscribedItems();
      _folders = RssFolderService.fetchFolders();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _refreshData();
      }
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _subscribedItems = SubscribeService.searchBookmarkedItems(query);
      } else {
        _refreshData();
      }
    });
  }

  Future<void> _showCreateFolderDialog() async {
    final TextEditingController folderNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('새 폴더 만들기'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: folderNameController,
                decoration: const InputDecoration(
                  labelText: '폴더 이름',
                  hintText: '폴더 이름을 입력하세요',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '폴더 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(folderNameController.text);
                  }
                },
                child: const Text('생성'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final success = await RssFolderService.createFolder(result);
        if (success && mounted) {
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 "$result"가 생성되었습니다'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 생성 중 오류가 발생했습니다: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final adManager = context.watch<AdManager>();

    Widget _buildBannerAdWidget() {
      // RssScreen과 다른 고유한 광고 ID 사용 (AdManager에 정의되어 있다고 가정)
      final bannerAd = adManager.getBannerAd(
        AdManager.subscribeScreenBannerPlacement, // 구독 화면용 배너 ID
      );
      final isLoaded = adManager.isBannerAdLoaded(
        AdManager.subscribeScreenBannerPlacement, // 구독 화면용 배너 ID
      );

      if (adManager.showAds && isLoaded && bannerAd != null) {
        return Container(
          key: ValueKey(bannerAd.hashCode), // 고유 키 보장
          alignment: Alignment.center,
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: theme.appBarTheme.iconTheme?.color,
                ),
                onPressed: () {
                  homeScaffoldKey.currentState?.openDrawer();
                },
                tooltip: '메뉴 열기',
              ),
              pinned: true,
              elevation: 0,
              centerTitle: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              title:
                  _isSearching
                      ? _buildSearchField()
                      : Text('구독', style: textTheme.headlineMedium),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: theme.appBarTheme.iconTheme?.color,
                  ),
                  onPressed: _toggleSearch,
                  tooltip: _isSearching ? '검색 닫기' : '검색',
                ),
                if (_tabController.index == 1 && !_isSearching)
                  IconButton(
                    icon: Icon(
                      Icons.create_new_folder_outlined,
                      color: theme.appBarTheme.iconTheme?.color,
                    ),
                    onPressed: _showCreateFolderDialog,
                    tooltip: '새 폴더 만들기',
                  ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.appBarTheme.iconTheme?.color,
                  ),
                  onPressed: _refreshData,
                  tooltip: '새로고침',
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.primaryColor,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: textTheme.bodyLarge?.color,
                  indicatorWeight: 3,
                  labelStyle: textTheme.labelLarge,
                  unselectedLabelStyle: textTheme.labelMedium,
                  tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
                ),
                theme, // 테마 전달하여 변경 감지할 수 있게 함
              ),
              floating: true,
              pinned: true,
            ),

            SliverToBoxAdapter(child: _buildBannerAdWidget()),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // 날짜별 보기 탭
            SubscribeDateView(
              items: _subscribedItems,
              searchQuery: _searchQuery,
              onRefresh: _refreshData,
            ),
            // 폴더별 보기 탭
            SubscribeFolderView(
              folders: _folders,
              searchQuery: _searchQuery,
              onRefresh: _refreshData,
              onCreateFolder: _showCreateFolderDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '검색어를 입력하세요',
        hintStyle: TextStyle(color: theme.hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
      onChanged: _handleSearch,
    );
  }
}

// SliverPersistentHeaderDelegate 구현
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ThemeData theme; // 테마 추가

  _SliverAppBarDelegate(this.child, this.theme);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow:
            overlapsContent
                ? [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      height: 48.0,
      child: child,
    );
  }

  @override
  double get maxExtent => 48.0;
  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    // 테마가 변경되었을 때 다시 빌드되도록 함
    return oldDelegate.theme != theme;
  }
}
