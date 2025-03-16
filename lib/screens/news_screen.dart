import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/news_service.dart';
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
  List<String> categories = [
    "정치",
    "경제",
    "사회",
    "생활/문화",
    "세계",
    "IT/과학",
  ];

  // 기본 카테고리 목록을 따로 저장
  final List<String> defaultCategories = [
    "정치",
    "경제",
    "사회",
    "생활/문화",
    "세계",
    "IT/과학",
  ];

  // 카테고리별 뉴스 데이터
  Map<String, Future<List<News>>> newsList = {};
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

    // 현재 화면 너비 가져오기 (이전 하드코딩된 값 대신)
    final screenWidth = MediaQuery.of(context).size.width;
    const double tabPadding = 17.0 * 2;

    // 현재 탭의 평균 너비 계산
    double averageTabWidth = 0;
    for (var category in categories) {
      averageTabWidth += (category.length * 10 + tabPadding);
    }
    averageTabWidth /= categories.length;

    // 현재 탭의 위치 계산
    double offset = _tabController.index * averageTabWidth;

    // 화면 중앙에 위치하도록 조정
    offset = offset - (screenWidth / 2) + (averageTabWidth / 2);

    // 스크롤 범위 내로 조정
    offset = offset.clamp(0.0, _tabScrollController.position.maxScrollExtent);

    // 부드러운 스크롤 애니메이션
    _tabScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadCategories() async {
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

      if (savedCategories != null && savedCategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            // 기본 카테고리 + 저장된 사용자 카테고리
            categories = [...defaultCategories, ...savedCategories];

            // 정렬 옵션 기본값 설정
            for (var category in savedCategories) {
              if (!categorySortOptions.containsKey(category)) {
                categorySortOptions[category] = "sim"; // 기본값은 정확순
              }
            }

            // TabController 재생성
            _tabController.dispose();
            _tabController =
                TabController(length: categories.length, vsync: this);
            _tabController.addListener(_handleTabIndexChange);
            fetchAllNewsLists();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            fetchAllNewsLists();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final userCategories = categories
        .where((category) => !defaultCategories.contains(category))
        .toList();
    await prefs.setStringList('user_categories', userCategories);

    // 정렬 옵션도 저장
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
      // 새로운 정렬 옵션으로 뉴스 다시 불러오기
      customNewsList[category] =
          NewsService.fetchCustomNews(category, 20, sortOption);
    });

    // 변경된 정렬 옵션 저장
    _saveCategories();
  }

  void fetchAllNewsLists() {
    for (var category in categories) {
      // 기본 카테고리와 사용자 추가 카테고리는 다른 API 호출
      if (defaultCategories.contains(category)) {
        newsList[category] = NewsService.fetchNews(category);
      } else {
        // 사용자 추가 카테고리는 저장된 정렬 옵션으로 API 호출
        String sortOption = categorySortOptions[category] ?? "sim";
        customNewsList[category] =
            NewsService.fetchCustomNews(category, 20, sortOption);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      fetchAllNewsLists();
    });
  }

  void _showAddCategoryDialog() {
    final theme = Theme.of(context);
    _categoryController.text = ''; // 컨트롤러 초기화

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
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

    // 기본 카테고리는 삭제 불가
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
      builder: (context) => AlertDialog(
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

  void _deleteCategory(int index) {
    final categoryToDelete = categories[index];

    // 기본 카테고리는 삭제 불가
    if (defaultCategories.contains(categoryToDelete)) {
      return;
    }

    setState(() {
      // 데이터에서 제거
      categories.removeAt(index);
      customNewsList.remove(categoryToDelete);
      categorySortOptions.remove(categoryToDelete);

      // TabController 재생성
      _tabController.dispose();
      _tabController = TabController(
        length: categories.length,
        vsync: this,
        initialIndex: index < categories.length ? index : categories.length - 1,
      );
      _tabController.addListener(_handleTabIndexChange);
    });

    // 카테고리 저장
    _saveCategories();

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'$categoryToDelete\' 카테고리가 삭제되었습니다'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addCategory(String category) {
    if (category.trim().isEmpty) return;

    // 이미 존재하는 카테고리인지 확인
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
      // 새로운 카테고리의 기본 정렬 옵션 설정
      categorySortOptions[category] = "sim"; // 기본값은 정확순

      // 사용자 추가 카테고리는 커스텀 API 호출
      customNewsList[category] =
          NewsService.fetchCustomNews(category, 20, "sim");

      // TabController 재생성
      _tabController.dispose();
      _tabController = TabController(
        length: categories.length,
        vsync: this,
        initialIndex: categories.length - 1, // 새로 추가된 탭으로 이동
      );
      _tabController.addListener(_handleTabIndexChange);
    });

    // 카테고리 저장
    _saveCategories();

    // 카테고리 추가 후 약간의 지연을 주어 UI가 업데이트된 후 스크롤 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tabController.animateTo(categories.length - 1);
        _scrollToCurrentTab(); // 추가된 탭으로 스크롤
      }
    });

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'$category\' 카테고리가 추가되었습니다'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndexChange);
    _tabController.dispose();
    _categoryController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // 설정 Provider 가져오기
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
              ),
            )
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
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
                    ),
                    pinned: true,
                    elevation: 0,
                    backgroundColor: theme.appBarTheme.backgroundColor,
                    title: Text(
                      'News',
                      style: textTheme.headlineMedium,
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: theme.appBarTheme.iconTheme?.color,
                        ),
                        onPressed: _refresh,
                      ),
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
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 17.0),
                          padding: const EdgeInsets.symmetric(horizontal: 9.0),
                          tabAlignment: TabAlignment.start,
                          tabs: List.generate(categories.length, (index) {
                            final category = categories[index];
                            final isCustomCategory =
                                !defaultCategories.contains(category);

                            return GestureDetector(
                              onLongPress: () =>
                                  _showDeleteCategoryDialog(category, index),
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
                                        color: _tabController.index == index
                                            ? theme.primaryColor
                                            : textTheme.bodyLarge?.color
                                                ?.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          _showDeleteCategoryDialog(
                                              category, index);
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: _tabController.index == index
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
                    floating: true,
                    pinned: false,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: categories.map((category) {
                  final isDefaultCategory =
                      defaultCategories.contains(category);

                  if (isDefaultCategory) {
                    // 기본 카테고리용 뉴스 리스트 뷰에 설정 전달
                    return NewsListView(newsList: newsList[category]!);
                  } else {
                    // 사용자 추가 카테고리용 커스텀 뉴스 리스트 뷰에 설정 전달
                    return CustomNewsListView(
                        newsList: customNewsList[category]!,
                        categoryName: category,
                        currentSortOption:
                            categorySortOptions[category] ?? "sim",
                        onSortChanged: (newSortOption) {
                          updateCategorySortOption(category, newSortOption);
                        });
                  }
                }).toList(),
              ),
            ),
      // 카테고리 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// TabBar를 SliverPersistentHeader로 만들기 위한 delegate 클래스
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: overlapsContent
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
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return true;
  }
}
