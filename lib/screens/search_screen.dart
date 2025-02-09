import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _searchResult = [];

  void _search(String query) {
    setState(() {
      _searchResult = List.generate(10, (index) => '검색 결과 $index: $query');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 검색창
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '뉴스를 검색하세요...',
              suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
            ),
          ),

          const SizedBox(height: 20),
          // 검색 결과
          _searchResult.isEmpty
              ? const Center(child: Text('검색 결과가 없습니다.'))
              : Expanded(
                  child: ListView.builder(
                    itemCount: _searchResult.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300] // 뉴스 이미지 (Placeholder)
                              ),
                          title: Text(_searchResult[index]),
                          subtitle: const Text('설명'),
                          onTap: () {
                            // 검색된 뉴스 상세보기 등 처리
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
