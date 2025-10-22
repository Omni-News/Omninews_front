import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/news_service.dart';
import 'package:omninews_flutter/utils/ad_manager.dart' show AdManager;
import 'package:omninews_flutter/widgets/news_list_view.dart';
import 'package:omninews_flutter/widgets/custom_news_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  createState() => NewsScreenState();
}

class NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> categories = ["정치", "경제", "사회", "생활/문화", "세계", "IT/과학"];

  final List<String> defaultCategories = [
    "정치",
    "경제",
    "사회",
    "생활/문화",
    "세계",
    "IT/과학",
  ];

  // [✅ 수정] Map<String, Future<List<News>>> newsList 제거
  // Map<String, Future<List<News>>> newsList = {};
  Map<String, Future<List<CustomNews>>> customNewsList = {}; // CustomNews는 유지
  Map<String, String> categorySortOptions = {};

  final TextEditingController _categoryController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  bool _isLoading = true; // 카테고리 로딩 상태

  // [✅ 추가] 각 NewsListView의 상태를 관리하기 위한 GlobalKey 맵
  // (새로고침 등을 외부에서 트리거해야 할 경우 필요, 지금은 사용 안 함)
  // final Map<String, GlobalKey<_NewsListViewState>> _newsListKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _loadCategories(); // 카테고리 목록 로드 및 초기 데이터 요청 시작
    _tabController.addListener(_handleTabIndexChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigateToNewCategory();
    });
  }

  // ... (dispose, _checkAndNavigateToNewCategory, _handleTabIndexChange, _scrollToCurrentTab - 변경 없음) ...
  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndexChange);
    _tabController.dispose();
    _categoryController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigateToNewCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final selectIndex = prefs.getInt('select_category_index');

    if (selectIndex != null) {
      int targetIndex = selectIndex == -1 ? categories.length - 1 : selectIndex;

      if (targetIndex >= 0 && targetIndex < categories.length) {
        _tabController.animateTo(targetIndex);
        _scrollToCurrentTab();
      }

      await prefs.remove('select_category_index');
    }
  }

  void _handleTabIndexChange() {
    if (!_tabController.indexIsChanging) {
      _scrollToCurrentTab();
    }
  }

  void _scrollToCurrentTab() {
    if (!mounted || !_tabScrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    const double tabPadding = 17.0 * 2;
    double averageTabWidth = 0;
    for (var category in categories) {
      averageTabWidth += (category.length * 10 + tabPadding);
    }
    averageTabWidth /= categories.length;
    double offset = _tabController.index * averageTabWidth;
    offset = offset - (screenWidth / 2) + (averageTabWidth / 2);
    offset = offset.clamp(0.0, _tabScrollController.position.maxScrollExtent);
    _tabScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadCategories() async {
    // ... (카테고리 로드 로직 - 변경 없음) ...
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('user_categories');
      final savedSortOptions = prefs.getStringList('category_sort_options');

      // 정렬 옵션 로드
      if (savedSortOptions != null && savedSortOptions.isNotEmpty) {
        for (int i = 0; i < savedSortOptions.length; i += 2) {
          if (i + 1 < savedSortOptions.length) {
            categorySortOptions[savedSortOptions[i]] = savedSortOptions[i + 1];
          }
        }
      }

      List<String> loadedCategories = List.from(
        defaultCategories,
      ); // 기본 카테고리로 시작

      if (savedCategories != null && savedCategories.isNotEmpty) {
        loadedCategories.addAll(savedCategories); // 저장된 사용자 카테고리 추가

        // 사용자 카테고리의 기본 정렬 옵션 설정
        for (var category in savedCategories) {
          if (!categorySortOptions.containsKey(category)) {
            categorySortOptions[category] = "sim"; // 기본값은 정확순
          }
        }
      }

      if (mounted) {
        setState(() {
          categories = loadedCategories; // 최종 카테고리 목록 업데이트

          // TabController 재생성
          _tabController.dispose(); // 이전 컨트롤러 해제
          _tabController = TabController(
            length: categories.length,
            vsync: this,
          );
          _tabController.addListener(_handleTabIndexChange);

          // CustomNews 데이터 로드 시작 (NewsListView는 자체적으로 로드)
          fetchCustomNewsLists(); // [✅ 수정] 함수명 변경 및 분리

          _isLoading = false; // 카테고리 로딩 완료
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("Error loading categories: $e");
    }
  }

  // [✅ 수정] CustomNews 데이터만 로드하도록 변경
  void fetchCustomNewsLists() {
    for (var category in categories) {
      if (!defaultCategories.contains(category)) {
        // 사용자 추가 카테고리는 저장된 정렬 옵션으로 API 호출
        String sortOption = categorySortOptions[category] ?? "sim";
        customNewsList[category] = NewsService.fetchCustomNews(
          category,
          20, // 초기 로드 개수 또는 페이지 크기
          sortOption,
        );
      }
    }
  }

  // [✅ 삭제] fetchAllNewsLists 함수 제거 (NewsListView가 자체 처리)
  // void fetchAllNewsLists() { ... }

  // [✅ 수정] _refresh 함수는 이제 CustomNews만 새로고침 (NewsListView는 내부에서 처리)
  Future<void> _refreshCustomNews() async {
    setState(() {
      fetchCustomNewsLists(); // CustomNews만 다시 로드
    });
    // NewsListView의 새로고침은 해당 위젯 내부의 RefreshIndicator가 담당
  }

  // ... (_saveCategories, updateCategorySortOption, _showAddCategoryDialog, _showDeleteCategoryDialog, _addCategory, _deleteCategory - 변경 없음) ...
  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final userCategories =
        categories.where((c) => !defaultCategories.contains(c)).toList();
    await prefs.setStringList('user_categories', userCategories);

    List<String> sortOptionsList = [];
    categorySortOptions.forEach((category, sortOption) {
      sortOptionsList.add(category);
      sortOptionsList.add(sortOption);
    });
    await prefs.setStringList('category_sort_options', sortOptionsList);
  }

  void updateCategorySortOption(String category, String sortOption) {
    setState(() {
      categorySortOptions[category] = sortOption;
      customNewsList[category] = NewsService.fetchCustomNews(
        category,
        20,
        sortOption,
      );
    });
    _saveCategories();
  }

  void _showAddCategoryDialog() {
    final theme = Theme.of(context);
    _categoryController.text = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '새 카테고리 추가',
              style: TextStyle(
                color: theme.textTheme.headlineMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: '카테고리 이름',
                hintText: '새 카테고리 이름을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
              ),
              autofocus: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addCategory(value);
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _addCategory(_categoryController.text);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  void _showDeleteCategoryDialog(String category, int index) {
    final theme = Theme.of(context);
    if (defaultCategories.contains(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('기본 카테고리는 삭제할 수 없습니다'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '카테고리 삭제',
              style: TextStyle(
                color: theme.textTheme.headlineMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(
              '\'$category\' 카테고리를 삭제하시겠습니까?',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _deleteCategory(index);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }

  void _addCategory(String category) {
    if (category.trim().isEmpty) return;
    if (categories.contains(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'$category\' 카테고리가 이미 존재합니다'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      categories.add(category);
      categorySortOptions[category] = "sim";
      customNewsList[category] = NewsService.fetchCustomNews(
        category,
        20,
        "sim",
      );
      _tabController.dispose();
      _tabController = TabController(
        length: categories.length,
        vsync: this,
        initialIndex: categories.length - 1,
      );
      _tabController.addListener(_handleTabIndexChange);
    });
    _saveCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tabController.animateTo(categories.length - 1);
        _scrollToCurrentTab();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'$category\' 카테고리가 추가되었습니다'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteCategory(int index) {
    final categoryToDelete = categories[index];
    if (defaultCategories.contains(categoryToDelete)) return;
    setState(() {
      categories.removeAt(index);
      customNewsList.remove(categoryToDelete);
      categorySortOptions.remove(categoryToDelete);
      _tabController.dispose();
      _tabController = TabController(
        length: categories.length,
        vsync: this,
        initialIndex: index < categories.length ? index : categories.length - 1,
      );
      _tabController.addListener(_handleTabIndexChange);
    });
    _saveCategories();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'$categoryToDelete\' 카테고리가 삭제되었습니다'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final adManager = context.watch<AdManager>();

    Widget _buildBannerAdWidget() {
      if (adManager.showAds &&
          adManager.isBannerAdLoaded &&
          adManager.bannerAd != null) {
        return Container(
          alignment: Alignment.center,
          width: adManager.bannerAd!.size.width.toDouble(),
          height: adManager.bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: adManager.bannerAd!),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body:
          _isLoading // 카테고리 로딩 중일 때
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      leading: IconButton(
                        tooltip: '메뉴 열기',
                        icon: Icon(
                          Icons.menu,
                          color: theme.appBarTheme.iconTheme?.color,
                        ),
                        onPressed:
                            () => homeScaffoldKey.currentState?.openDrawer(),
                      ),
                      pinned: true,
                      elevation: 0,
                      backgroundColor: theme.appBarTheme.backgroundColor,
                      title: Text('뉴스', style: textTheme.headlineMedium),
                      actions: [
                        // [✅ 수정] 새로고침 버튼은 NewsListView 내부로 이동했으므로 제거 또는 다른 기능 할당
                        // IconButton(
                        //   tooltip: '새로고침',
                        //   icon: Icon(Icons.refresh, color: theme.appBarTheme.iconTheme?.color),
                        //   onPressed: _refreshCustomNews, // CustomNews만 새로고침? 또는 제거
                        // ),
                      ],
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        SingleChildScrollView(
                          controller: _tabScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            indicatorColor: theme.primaryColor,
                            labelColor: theme.primaryColor,
                            unselectedLabelColor: textTheme.bodyLarge?.color,
                            indicatorWeight: 3,
                            labelStyle: textTheme.labelLarge,
                            unselectedLabelStyle: textTheme.labelMedium,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 17.0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9.0,
                            ),
                            tabAlignment: TabAlignment.start,
                            tabs: List.generate(categories.length, (index) {
                              final category = categories[index];
                              final isCustomCategory =
                                  !defaultCategories.contains(category);
                              return GestureDetector(
                                onLongPress:
                                    () => _showDeleteCategoryDialog(
                                      category,
                                      index,
                                    ),
                                child: Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(category),
                                      if (isCustomCategory) ...[
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.search,
                                          size: 16,
                                          color:
                                              _tabController.index == index
                                                  ? theme.primaryColor
                                                  : textTheme.bodyLarge?.color
                                                      ?.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap:
                                              () => _showDeleteCategoryDialog(
                                                category,
                                                index,
                                              ),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color:
                                                _tabController.index == index
                                                    ? theme.primaryColor
                                                    : textTheme.bodyLarge?.color
                                                        ?.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      pinned: true,
                    ),
                    SliverToBoxAdapter(child: _buildBannerAdWidget()),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children:
                      categories.map((category) {
                        final isDefaultCategory = defaultCategories.contains(
                          category,
                        );

                        if (isDefaultCategory) {
                          // [✅ 수정] NewsListView에 category 전달
                          return NewsListView(
                            // [✅ 수정] key 추가 (필요시 상태 유지 또는 특정 위젯 식별용)
                            key: ValueKey('newslist_$category'),
                            category: category,
                            onBookmarkChanged: () {
                              // 북마크 변경 시 필요한 동작 (예: 다른 화면 업데이트)
                            },
                          );
                        } else {
                          // CustomNewsListView는 기존 방식 유지 (Future 사용)
                          return CustomNewsListView(
                            key: ValueKey('customlist_$category'), // key 추가
                            newsList: customNewsList[category]!,
                            categoryName: category,
                            currentSortOption:
                                categorySortOptions[category] ?? "sim",
                            onSortChanged: (newSortOption) {
                              updateCategorySortOption(category, newSortOption);
                            },
                            // CustomNewsListView에도 페이지네이션 구현 필요 시 유사하게 수정
                          );
                        }
                      }).toList(),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        tooltip: '카테고리 추가',
        onPressed: _showAddCategoryDialog,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// _SliverAppBarDelegate (변경 없음)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate(this.child);
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow:
            overlapsContent
                ? [
                  BoxShadow(
                    color: theme.shadowColor,
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
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) => true;
}
