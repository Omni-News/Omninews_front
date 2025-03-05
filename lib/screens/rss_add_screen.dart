import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/rss_service.dart';

class RssAddScreen extends StatefulWidget {
  final Function onChannelAdded;

  const RssAddScreen({super.key, required this.onChannelAdded});

  @override
  State<RssAddScreen> createState() => _RssAddScreenState();
}

class _RssAddScreenState extends State<RssAddScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  RssChannel? _previewChannel;
  String? _errorMessage;

  // RSS가 DB에 존재하는지 여부를 저장하는 변수 추가
  bool _isExistingRss = false;
  // RSS 추가가 완료되었는지 여부 저장
  bool _isRssAdded = false;
  bool _isAlreadySubscribed = false; // 추가: 이미 구독 중인지 여부

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // URL이 유효한지 확인하는 함수
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _previewRss() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'URL을 입력해주세요';
        _previewChannel = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewChannel = null;
      _isExistingRss = false;
      _isRssAdded = false;
      _isAlreadySubscribed = false;
    });

    try {
      final preview = await RssService.previewRssFromUrl(url);

      if (preview != null) {
        final exists = await RssService.checkRssExists(url);

        final alreadySubscribed =
            await RssService.isChannelAlreadySubscribed(preview);

        setState(() {
          _isLoading = false;
          _previewChannel = preview;
          _isExistingRss = exists;
          _isAlreadySubscribed = alreadySubscribed;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'RSS 피드를 불러올 수 없습니다';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '오류가 발생했습니다: $e';
      });
    }
  }

  // RSS를 DB에 추가
  Future<void> _addRssToDb() async {
    if (_previewChannel == null) return;

    final url = _urlController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await RssService.addRssToDb(url);

      if (success) {
        setState(() {
          _isLoading = false;
          _isRssAdded = true;
          _isExistingRss = true; // 이제 DB에 존재하므로 true로 설정
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RSS가 성공적으로 추가되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'RSS 추가 중 오류가 발생했습니다';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'RSS 추가 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 구독 처리
  Future<void> _subscribeChannel() async {
    if (_previewChannel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await RssService.subscribeChannel(_previewChannel!);

      if (success) {
        widget.onChannelAdded();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RSS 채널이 구독되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '이미 구독 중인 채널입니다';
          _isAlreadySubscribed = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '구독 중 오류가 발생했습니다: $e';
      });
    }
  }

  Widget _buildActionButton() {
    // 이미 구독 중이면 비활성화된 버튼 표시
    if (_isAlreadySubscribed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null, // 비활성화
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            '이미 구독 중인 채널',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_isExistingRss ? _subscribeChannel : _addRssToDb),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isExistingRss ? Colors.blue : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isExistingRss ? '구독하기' : 'RSS 추가하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RSS 추가',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RSS 피드 URL을 입력하세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/rss',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _previewRss(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _previewRss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading && _previewChannel == null
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('미리보기'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_previewChannel != null) ...[
              const SizedBox(height: 25),
              const Text(
                '미리보기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 이미지 URL이 유효한지 확인하고 사용
                          _isValidImageUrl(_previewChannel!.channelImageUrl)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _previewChannel!.channelImageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultChannelIcon();
                                    },
                                  ),
                                )
                              : _buildDefaultChannelIcon(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _previewChannel!.channelTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _previewChannel!.channelLink,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _previewChannel!.channelDescription,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // 여기에서 _buildActionButton() 메서드 사용하도록 변경
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 기본 아이콘 위젯을 생성하는 메서드
  Widget _buildDefaultChannelIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.rss_feed,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
