import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/news_service.dart';
import 'package:omninews_flutter/utils/ad_manager.dart'; // [✅ 수정] show 제거 불필요
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

  Map<String, Future<List<CustomNews>>> customNewsList = {};
  Map<String, String> categorySortOptions = {};

  final TextEditingController _categoryController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _loadCategories();
    _tabController.addListener(_handleTabIndexChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigateToNewCategory();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndexChange);
    _tabController.dispose();
    _categoryController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigateToNewCategory() async {
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
    if (!_tabController.indexIsChanging) {
      _scrollToCurrentTab();
    }
  }

  void _scrollToCurrentTab() {
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('user_categories');
      final savedSortOptions = prefs.getStringList('category_sort_options');
      if (savedSortOptions != null && savedSortOptions.isNotEmpty) {
        for (int i = 0; i < savedSortOptions.length; i += 2) {
          if (i + 1 < savedSortOptions.length) {
            categorySortOptions[savedSortOptions[i]] = savedSortOptions[i + 1];
          }
        }
      }
      List<String> loadedCategories = List.from(defaultCategories);
      if (savedCategories != null && savedCategories.isNotEmpty) {
        loadedCategories.addAll(savedCategories);
        for (var category in savedCategories) {
          if (!categorySortOptions.containsKey(category)) {
            categorySortOptions[category] = "sim";
          }
        }
      }
      if (mounted) {
        setState(() {
          categories = loadedCategories;
          _tabController.dispose();
          _tabController = TabController(
            length: categories.length,
            vsync: this,
          );
          _tabController.addListener(_handleTabIndexChange);
          fetchCustomNewsLists();
          _isLoading = false;
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

  void fetchCustomNewsLists() {
    // ... (변경 없음) ...
    for (var category in categories) {
      if (!defaultCategories.contains(category)) {
        String sortOption = categorySortOptions[category] ?? "sim";
        customNewsList[category] = NewsService.fetchCustomNews(
          category,
          20,
          sortOption,
        );
      }
    }
  }

  Future<void> _refreshCustomNews() async {
    // ... (변경 없음) ...
    setState(() {
      fetchCustomNewsLists();
    });
  }

  Future<void> _saveCategories() async {
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
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
    // ... (변경 없음) ...
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

    // [✅ 수정] 배너 광고 위젯 빌더 (Placement ID 사용)
    Widget _buildBannerAdWidget() {
      // 해당 Placement ID로 광고 정보 가져오기
      final bannerAd = adManager.getBannerAd(
        AdManager.newsScreenBannerPlacement,
      ); // ID 사용
      final isLoaded = adManager.isBannerAdLoaded(
        AdManager.newsScreenBannerPlacement,
      ); // ID 사용

      if (adManager.showAds && isLoaded && bannerAd != null) {
        return Container(
          key: ValueKey(bannerAd.hashCode),
          alignment: Alignment.center,
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      } else {
        // 로드 안됐거나 실패 시 빈 공간
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      /* ... AppBar ... */
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
                      actions: [/* ... Actions ... */],
                    ),
                    SliverPersistentHeader(
                      /* ... TabBar ... */
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
                    // [✅ 수정 없음] 배너 광고 위치는 그대로
                    SliverToBoxAdapter(child: _buildBannerAdWidget()),
                  ];
                },
                body: TabBarView(
                  /* ... TabBarView ... */
                  controller: _tabController,
                  children:
                      categories.map((category) {
                        final isDefaultCategory = defaultCategories.contains(
                          category,
                        );
                        if (isDefaultCategory) {
                          return NewsListView(
                            key: ValueKey('newslist_$category'),
                            category: category,
                            onBookmarkChanged: () {},
                          );
                        } else {
                          return CustomNewsListView(
                            key: ValueKey('customlist_$category'),
                            newsList: customNewsList[category]!,
                            categoryName: category,
                            currentSortOption:
                                categorySortOptions[category] ?? "sim",
                            onSortChanged: (newSortOption) {
                              updateCategorySortOption(category, newSortOption);
                            },
                          );
                        }
                      }).toList(),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        /* ... FAB ... */
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
