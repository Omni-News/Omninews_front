import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/services/news_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<NewsApi> _searchResult = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _sortOption = 'sim';  // 기본값은 정확도순

  @override
  void initState() {
    super.initState();
    // 포커스 및 키보드 자동 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      List<NewsApi> result = await NewsApiService.fetchNews(query, 20, _sortOption);
      setState(() {
        _searchResult = result;
      });
    } catch (e) {
      print('Failed to fetch news: $e');
      setState(() {
        _searchResult = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  // 정렬 옵션 변경
  void _updateSortOption(String sortOption) {
    if (_sortOption != sortOption) {
      setState(() {
        _sortOption = sortOption;
      });
      
      // 이미 검색한 결과가 있다면 새 정렬 옵션으로 재검색
      if (_hasSearched && _controller.text.isNotEmpty) {
        _search(_controller.text);
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
    ) ?? false;
    
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
        // NewsScreen에서 이 값을 확인하여 해당 탭으로 이동
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
          'Search News',
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
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '뉴스를 검색하세요...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                        },
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
                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                ),
              ),
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
            ),
          ),
          
          // 카테고리 추가 및 정렬 옵션 (검색 후에만 표시)
          if (_hasSearched && _searchResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  // 카테고리 추가 버튼 (왼쪽에 배치)
                  InkWell(
                    onTap: () => _addToNewsCategories(_controller.text),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
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
                          Icon(Icons.add_circle_outline, size: 14, color: Colors.blue[700]),
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
                    label: "최신순",
                    isSelected: _sortOption == "date",
                    onTap: () => _updateSortOption("date"),
                  ),
                ],
              ),
            ),
          
          // 검색 결과
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : !_hasSearched
                    ? _buildInitialView()
                    : _searchResult.isEmpty
                        ? _buildEmptyResultView()
                        : ListView.separated(
                            padding: const EdgeInsets.only(top: 4, bottom: 16),
                            itemCount: _searchResult.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1, 
                              indent: 16, 
                              endIndent: 16
                            ),
                            itemBuilder: (context, index) {
                              final item = _searchResult[index];
                              return InkWell(
                                onTap: () => _launchURL(item.newsOriginalLink),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 뉴스 제목
                                      Text(
                                        _removeHtmlTags(item.newsTitle),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          height: 1.3,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      
                                      // 뉴스 내용 요약
                                      Text(
                                        _truncateDescription(_removeHtmlTags(item.newsDescription)),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // 출처 및 날짜
                                      Row(
                                        children: [
                                          Text(
                                            _extractDomain(item.newsOriginalLink),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(item.newsPubDate),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
          Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '\'${_controller.text}\' 검색 결과가 없습니다',
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
  Widget _buildSortOption({
    required BuildContext context, 
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
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

  // HTML 태그 제거 유틸리티 함수
  String _removeHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  // 설명 텍스트 자르기
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  // 도메인 추출
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return url;
    }
  }

  // 날짜 포맷팅
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return DateFormat('MM/dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
