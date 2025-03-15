import 'package:flutter/material.dart';
import 'package:omninews_flutter/services/unified_search_service.dart';
import 'package:omninews_flutter/widgets/news_api_item_card.dart';
import 'package:omninews_flutter/widgets/search_rss_channel_card.dart';
import 'package:omninews_flutter/widgets/search_rss_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _controller.addListener(_onTextChanged); // 텍스트 변경 리스너 추가
    // 포커스 및 키보드 자동 표시
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

  // 텍스트 필드 변경 감지
  void _onTextChanged() {
    // 필요 시 상태 업데이트 (예: 지우기 버튼 표시/숨김)
    setState(() {});
  }

  // 검색 실행 함수
  void _search(String query) async {
    // 검색어가 비어있을 경우 반환
    if (query.trim().isEmpty) return;

    // 로딩 상태 설정 및 마지막 검색어 저장
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
      // 검색 시작 시 이전 결과 초기화
      _searchResult = null;
    });

    try {
      // 새로운 검색 실행
      final result =
          await UnifiedSearchService.search(query, sort: _sortOption);

      // UI 업데이트를 확실히 하기 위해 mounted 체크 후 상태 업데이트
      if (mounted) {
        setState(() {
          _searchResult = result;
          _isLoading = false;

          // 검색 결과가 있으면 기본 필터 설정 (모두 보기)
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
      // 오류 발생 시 처리
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
          SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 검색 버튼 클릭 또는 엔터 키 입력 처리
  void _handleSearch() {
    final query = _controller.text;
    if (query.isNotEmpty) {
      _search(query);
      // 키보드 숨기기
      FocusScope.of(context).unfocus();
    }
  }

  // 검색 필드 초기화
  void _clearSearch() {
    _controller.clear();
    // 포커스 주기
    _focusNode.requestFocus();
    // UI 갱신
    setState(() {});
  }

  // 정렬 옵션 변경
  void _updateSortOption(String sortOption) {
    if (_sortOption != sortOption) {
      setState(() {
        _sortOption = sortOption;
      });

      // 이미 검색한 결과가 있다면 새 정렬 옵션으로 재검색
      if (_hasSearched && _lastQuery.isNotEmpty) {
        _search(_lastQuery);
      }
    }
  }

  // 검색어를 뉴스 카테고리에 추가
  Future<void> _addToNewsCategories(String query) async {
    // 확인 다이얼로그 표시
    bool shouldAdd = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('카테고리 추가'),
            content: Text('\'$query\' 검색어를 뉴스 카테고리에 추가하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('추가'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldAdd) return;

    try {
      // 기존 저장된 사용자 카테고리 불러오기
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('user_categories') ?? [];

      // 이미 존재하는 카테고리인지 확인
      if (savedCategories.contains(query)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('\'$query\' 카테고리가 이미 존재합니다'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 새 카테고리 추가
      final newCategories = [...savedCategories, query];
      await prefs.setStringList('user_categories', newCategories);

      // 추가 성공 메시지 및 화면 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'$query\' 카테고리가 추가되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 뉴스 화면으로 이동 (팝업 닫기)
        Navigator.of(context).popUntil((route) => route.isFirst);

        // 새로 추가된 카테고리로 이동하기 위한 인덱스를 SharedPreferences에 저장
        await prefs.setInt('select_category_index', -1); // -1은 마지막 카테고리를 의미
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카테고리 추가 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Contents',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
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
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
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
                            const BorderSide(color: Colors.blue, width: 1),
                      ),
                    ),
                    onSubmitted: _search, // 직접 search 메서드 호출
                    textInputAction: TextInputAction.search,
                  ),
                ),

                // 검색 버튼 추가 (텍스트가 있을 때만)
                if (_controller.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue))
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

  // 검색 옵션 바
  Widget _buildSearchOptionsBar() {
    bool hasResults = _hasResults();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, hasResults ? 0 : 4),
      child: Row(
        children: [
          // 카테고리 추가 버튼 (왼쪽에 배치)
          InkWell(
            onTap: () => _addToNewsCategories(_lastQuery), // _lastQuery 사용
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[100]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "카테고리에 추가",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add_circle_outline,
                      size: 14, color: Colors.blue[700]),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 정렬 옵션 (오른쪽에 배치)
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

  // 검색 결과 필터 칩
  Widget _buildFilterChips() {
    // 모든 필터가 꺼져있으면 하나라도 활성화 (최소 하나는 항상 선택되도록)
    if (!_showNews && !_showRssItems && !_showChannels) {
      setState(() {
        _showNews = true; // 기본적으로 뉴스는 항상 표시
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

  // 필터 칩 위젯
  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isSelected ? Colors.blue[400] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // 검색 결과 리스트 구성
  Widget _buildSearchResultsList() {
    List<Widget> resultWidgets = [];

    // 뉴스 결과
    if (_showNews && _searchResult!.newsResults.isNotEmpty) {
      // 뉴스 섹션 헤더 (필요한 경우)
      if ((_showRssItems && _searchResult!.rssItemResults.isNotEmpty) ||
          (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
        resultWidgets
            .add(_buildSectionHeader('뉴스', _searchResult!.newsResults.length));
      }

      // 뉴스 결과 목록
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
          resultWidgets
              .add(const Divider(height: 1, indent: 16, endIndent: 16));
        }
      }
    }

    // RSS 피드 결과
    if (_showRssItems && _searchResult!.rssItemResults.isNotEmpty) {
      // RSS 피드 섹션 헤더 (필요한 경우)
      if ((_showNews && _searchResult!.newsResults.isNotEmpty) ||
          (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
        resultWidgets.add(_buildSectionHeader(
            'RSS 피드', _searchResult!.rssItemResults.length));
      }

      // RSS 피드 결과 목록
      for (var i = 0; i < _searchResult!.rssItemResults.length; i++) {
        resultWidgets.add(SearchRssItemCard(
          item: _searchResult!.rssItemResults[i],
          onBookmarkChanged: () {
            setState(() {});
          },
        ));

        if (i < _searchResult!.rssItemResults.length - 1 ||
            (_showChannels && _searchResult!.rssChannelResults.isNotEmpty)) {
          resultWidgets
              .add(const Divider(height: 1, indent: 16, endIndent: 16));
        }
      }
    }

    // 채널 결과
    if (_showChannels && _searchResult!.rssChannelResults.isNotEmpty) {
      // 채널 섹션 헤더 (필요한 경우)
      if ((_showNews && _searchResult!.newsResults.isNotEmpty) ||
          (_showRssItems && _searchResult!.rssItemResults.isNotEmpty)) {
        resultWidgets.add(
            _buildSectionHeader('채널', _searchResult!.rssChannelResults.length));
      }

      // 채널 결과 목록
      for (var i = 0; i < _searchResult!.rssChannelResults.length; i++) {
        resultWidgets.add(SearchRssChannelCard(
          channel: _searchResult!.rssChannelResults[i],
          onSubscriptionChanged: () {
            setState(() {});
          },
        ));

        if (i < _searchResult!.rssChannelResults.length - 1) {
          resultWidgets
              .add(const Divider(height: 1, indent: 16, endIndent: 16));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: resultWidgets,
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title, int count) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 검색 전 초기 화면
  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '검색어를 입력하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '뉴스, RSS 피드, 채널을 모두 검색할 수 있습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 검색 결과 없음 화면
  Widget _buildEmptyResultView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '\'${_lastQuery}\' 검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어로 시도해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 심플하고 모던한 정렬 옵션 버튼 위젯
  Widget _buildSortOption(
      {required BuildContext context,
      required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
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
                color: isSelected ? Colors.blue : Colors.black54,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 검색 결과가 있는지 확인
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
