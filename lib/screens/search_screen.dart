import 'package:flutter/material.dart';
import 'package:omninews_flutter/services/unified_search_service.dart';
import 'package:omninews_flutter/widgets/news_api_item_card.dart';
import 'package:omninews_flutter/widgets/search_rss_channel_card.dart';
import 'package:omninews_flutter/widgets/search_rss_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // 검색창 포커스 관리용

  // 검색 결과 상태 관리
  UnifiedSearchResult? _searchResult;
  bool _isLoading = false;
  bool _hasSearched = false;
  String _sortOption = 'sim';
  String _lastQuery = ''; // 마지막 검색어 저장

  // 결과 필터링
  bool _showNews = true;
  bool _showRssItems = true;
  bool _showChannels = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
      _searchResult = null;
    });

    try {
      final result =
          await UnifiedSearchService.search(query, sort: _sortOption);

      if (mounted) {
        setState(() {
          _searchResult = result;
          _isLoading = false;

          if (result.newsResults.isNotEmpty ||
              result.rssItemResults.isNotEmpty ||
              result.rssChannelResults.isNotEmpty) {
            _showNews = true;
            _showRssItems = true;
            _showChannels = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResult = UnifiedSearchResult(
            newsResults: [],
            rssItemResults: [],
            rssChannelResults: [],
          );
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleSearch() {
    final query = _controller.text;
    if (query.isNotEmpty) {
      _search(query);
      FocusScope.of(context).unfocus();
    }
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.requestFocus();
    setState(() {});
  }

  void _updateSortOption(String sortOption) {
    if (_sortOption != sortOption) {
      setState(() {
        _sortOption = sortOption;
      });

      if (_hasSearched && _lastQuery.isNotEmpty) {
        _search(_lastQuery);
      }
    }
  }

  Future<void> _addToNewsCategories(String query) async {
    final theme = Theme.of(context);

    bool shouldAdd = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '카테고리 추가',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineMedium?.color,
              ),
            ),
            backgroundColor: theme.dialogBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(
              '\'$query\' 검색어를 뉴스 카테고리에 추가하시겠습니까?',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '취소',
                  style: TextStyle(
                      color:
                          theme.textTheme.bodyLarge?.color?.withOpacity(0.7)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
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
        ) ??
        false;

    if (!shouldAdd) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('user_categories') ?? [];

      if (savedCategories.contains(query)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('\'$query\' 카테고리가 이미 존재합니다'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        return;
      }

      final newCategories = [...savedCategories, query];
      await prefs.setStringList('user_categories', newCategories);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'$query\' 카테고리가 추가되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.primaryColor,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
        await prefs.setInt('select_category_index', -1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카테고리 추가 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Search Contents',
          style: textTheme.headlineMedium,
        ),
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // 검색 입력 필드
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: '뉴스, RSS 피드, 채널을 검색하세요...',
                      hintStyle: TextStyle(color: theme.hintColor),
                      prefixIcon: Icon(Icons.search,
                          color: theme.iconTheme.color?.withOpacity(0.6)),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color:
                                      theme.iconTheme.color?.withOpacity(0.6)),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? theme.cardColor
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: theme.primaryColor, width: 1),
                      ),
                    ),
                    style: TextStyle(color: textTheme.bodyLarge?.color),
                    onSubmitted: _search,
                    textInputAction: TextInputAction.search,
                  ),
                ),

                // 검색 버튼
                if (_controller.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('검색'),
                  ),
                ],
              ],
            ),
          ),

          // 검색 결과가 있을 때의 옵션 바
          if (_hasSearched && _searchResult != null && !_isLoading)
            _buildSearchOptionsBar(),

          // 결과 필터 칩
          if (_hasSearched &&
              _searchResult != null &&
              !_isLoading &&
              _hasResults())
            _buildFilterChips(),

          // 검색 결과
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor))
                : !_hasSearched
                    ? _buildInitialView()
                    : !_hasResults()
                        ? _buildEmptyResultView()
                        : _buildSearchResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOptionsBar() {
    final theme = Theme.of(context);
    final hasResults = _hasResults();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, hasResults ? 0 : 4),
      child: Row(
        children: [
          // 카테고리 추가 버튼
          InkWell(
            onTap: () => _addToNewsCategories(_lastQuery),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "카테고리에 추가",
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add_circle_outline,
                      size: 14, color: theme.colorScheme.onPrimaryContainer),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 정렬 옵션
          _buildSortOption(
            context: context,
            label: "정확순",
            isSelected: _sortOption == "sim",
            onTap: () => _updateSortOption("sim"),
          ),
          const SizedBox(width: 16),
          _buildSortOption(
            context: context,
            label: "인기순",
            isSelected: _sortOption == "pop",
            onTap: () => _updateSortOption("pop"),
          ),
          const SizedBox(width: 16),
          _buildSortOption(
            context: context,
            label: "최신순",
            isSelected: _sortOption == "date",
            onTap: () => _updateSortOption("date"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    // 모든 필터가 꺼져있으면 하나라도 활성화
    if (!_showNews && !_showRssItems && !_showChannels) {
      setState(() {
        _showNews = true;
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: '뉴스',
              count: _searchResult!.newsResults.length,
              isSelected: _showNews,
              onTap: () => setState(() => _showNews = !_showNews),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'RSS 피드',
              count: _searchResult!.rssItemResults.length,
              isSelected: _showRssItems,
              onTap: () => setState(() => _showRssItems = !_showRssItems),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: '채널',
              count: _searchResult!.rssChannelResults.length,
              isSelected: _showChannels,
              onTap: () => setState(() => _showChannels = !_showChannels),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final searchStyle = AppTheme.searchStyleOf(context);

    Color chipBackground;
    Color chipBorderColor;
    Color chipTextColor;

    if (isSelected) {
      if (label == '뉴스') {
        chipBackground = theme.primaryColor.withOpacity(0.1);
        chipBorderColor = theme.primaryColor.withOpacity(0.3);
        chipTextColor = theme.primaryColor;
      } else if (label == 'RSS 피드') {
        chipBackground = searchStyle.rssTagBackground.withOpacity(0.8);
        chipBorderColor = searchStyle.rssTagBorder;
        chipTextColor = searchStyle.rssTagText;
      } else {
        chipBackground = searchStyle.channelTagBackground.withOpacity(0.8);
        chipBorderColor = searchStyle.channelTagBorder;
        chipTextColor = searchStyle.channelTagText;
      }
    } else {
      chipBackground = theme.brightness == Brightness.dark
          ? Colors.grey[800]!.withOpacity(0.5)
          : Colors.grey[100]!;
      chipBorderColor = theme.brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!;
      chipTextColor = theme.brightness == Brightness.dark
          ? Colors.grey[300]!
          : Colors.grey[700]!;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipBorderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: chipTextColor,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipTextColor.withOpacity(0.2)
                    : theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: chipTextColor,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: chipTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    final theme = Theme.of(context);
    List<Widget> resultWidgets = [];

    // 뉴스 결과
    if (_showNews && _searchResult!.newsResults.isNotEmpty) {
      if ((_showRssItems && _searchResult!.rssItemResults.isNotEmpty) ||
          (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
        resultWidgets
            .add(_buildSectionHeader('뉴스', _searchResult!.newsResults.length));
      }

      for (var i = 0; i < _searchResult!.newsResults.length; i++) {
        resultWidgets.add(NewsApiItemCard(
          news: _searchResult!.newsResults[i],
          onBookmarkChanged: () {
            setState(() {});
          },
        ));

        if (i < _searchResult!.newsResults.length - 1 ||
            (_showRssItems && _searchResult!.rssItemResults.isNotEmpty) ||
            (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
          resultWidgets.add(Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerTheme.color,
          ));
        }
      }
    }

    // RSS 피드 결과
    if (_showRssItems && _searchResult!.rssItemResults.isNotEmpty) {
      if ((_showNews && _searchResult!.newsResults.isNotEmpty) ||
          (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
        resultWidgets.add(_buildSectionHeader(
            'RSS 피드', _searchResult!.rssItemResults.length));
      }

      for (var i = 0; i < _searchResult!.rssItemResults.length; i++) {
        resultWidgets.add(SearchRssItemCard(
          item: _searchResult!.rssItemResults[i],
          onBookmarkChanged: () {
            setState(() {});
          },
        ));

        if (i < _searchResult!.rssItemResults.length - 1 ||
            (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
          resultWidgets.add(Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerTheme.color,
          ));
        }
      }
    }

    // 채널 결과
    if (_showChannels && _searchResult!.rssChannelResults.isNotEmpty) {
      if ((_showNews && _searchResult!.newsResults.isNotEmpty) ||
          (_showRssItems && _searchResult!.rssItemResults.isNotEmpty)) {
        resultWidgets.add(
            _buildSectionHeader('채널', _searchResult!.rssChannelResults.length));
      }

      for (var i = 0; i < _searchResult!.rssChannelResults.length; i++) {
        resultWidgets.add(SearchRssChannelCard(
          channel: _searchResult!.rssChannelResults[i],
          onSubscriptionChanged: () {
            setState(() {});
          },
        ));

        if (i < _searchResult!.rssChannelResults.length - 1) {
          resultWidgets.add(Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerTheme.color,
          ));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: resultWidgets,
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final theme = Theme.of(context);

    Color backgroundColor = theme.brightness == Brightness.dark
        ? theme.cardColor.withOpacity(0.3)
        : Colors.grey[50]!;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleSmall?.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: subscribeStyle.emptyIconColor),
          const SizedBox(height: 16),
          Text(
            '검색어를 입력하세요',
            style: TextStyle(
              fontSize: 16,
              color: subscribeStyle.emptyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '뉴스, RSS 피드, 채널을 모두 검색할 수 있습니다',
            style: TextStyle(
              fontSize: 14,
              color: subscribeStyle.hintTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultView() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64, color: subscribeStyle.emptyIconColor),
          const SizedBox(height: 16),
          Text(
            '\'${_lastQuery}\' 검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: subscribeStyle.emptyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어로 시도해보세요',
            style: TextStyle(
              fontSize: 14,
              color: subscribeStyle.hintTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
      {required BuildContext context,
      required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasResults() {
    if (_searchResult == null) return false;

    final hasNewsResults = _showNews && _searchResult!.newsResults.isNotEmpty;
    final hasRssItemResults =
        _showRssItems && _searchResult!.rssItemResults.isNotEmpty;
    final hasChannelResults =
        _showChannels && _searchResult!.rssChannelResults.isNotEmpty;

    return hasNewsResults || hasRssItemResults || hasChannelResults;
  }
}
