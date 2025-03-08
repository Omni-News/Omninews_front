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
  bool _isPreviewLoading = false;
  RssChannel? _previewChannel;
  String? _errorMessage;
  bool _isExistingRss = false;
  bool _isAlreadySubscribed = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

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
      _isPreviewLoading = true;
      _errorMessage = null;
      _previewChannel = null;
      _isExistingRss = false;
      _isAlreadySubscribed = false;
    });

    try {
      final preview = await RssService.previewRssFromUrl(url);

      if (preview != null) {
        final exists = await RssService.checkRssExists(url);
        final alreadySubscribed =
            await RssService.isChannelAlreadySubscribed(preview.channelRssLink);

        if (mounted) {
          setState(() {
            _previewChannel = preview;
            _isExistingRss = exists;
            _isAlreadySubscribed = alreadySubscribed;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'RSS 피드를 불러올 수 없습니다';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }

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
        if (mounted) {
          setState(() {
            _isExistingRss = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RSS가 성공적으로 추가되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'RSS 추가 중 오류가 발생했습니다';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'RSS 추가 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _subscribeChannel() async {
    if (_previewChannel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await RssService.subscribeChannel(_previewChannel!.channelRssLink);

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
        if (mounted) {
          setState(() {
            _errorMessage = '이미 구독 중인 채널입니다';
            _isAlreadySubscribed = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '구독 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'RSS 추가',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트
              const Text(
                'RSS 피드 URL 입력',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'RSS 주소를 입력하고 미리보기 버튼을 눌러주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 20),

              // URL 입력 필드
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/rss',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Icon(Icons.link, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.blue[300]!, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onSubmitted: (_) => _previewRss(),
                    ),

                    const SizedBox(height: 12),

                    // 미리보기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPreviewLoading ? null : _previewRss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor: Colors.blue.withValues(),
                        ),
                        child: _isPreviewLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'RSS 미리보기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // 오류 메시지
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 미리보기 결과
              if (_previewChannel != null) ...[
                const SizedBox(height: 30),
                const Row(
                  children: [
                    Icon(Icons.preview, size: 22, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'RSS 미리보기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPreviewCard(),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (_previewChannel == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채널 헤더 영역
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 채널 썸네일
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isValidImageUrl(_previewChannel!.channelImageUrl)
                          ? Image.network(
                              _previewChannel!.channelImageUrl!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultChannelIcon();
                              },
                            )
                          : _buildDefaultChannelIcon(),
                    ),

                    const SizedBox(width: 16),

                    // 채널 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _previewChannel!.channelTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _previewChannel!.channelLink,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
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

                // 채널 설명
                Text(
                  _previewChannel!.channelDescription,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // 태그 정보
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      label: '언어: ${_previewChannel!.channelLanguage}',
                      icon: Icons.language,
                    ),
                    _buildInfoChip(
                      label: '랭크: ${_previewChannel!.channelRank}',
                      icon: Icons.star,
                      iconColor: Colors.amber,
                    ),
                    if (_previewChannel!.rssGenerator != null &&
                        _previewChannel!.rssGenerator != 'None')
                      _buildInfoChip(
                        label: _previewChannel!.rssGenerator!,
                        icon: Icons.settings,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // 구독 버튼
                _buildSubscriptionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionButton() {
    if (_isAlreadySubscribed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text(
            '이미 구독 중인 채널',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.grey[700],
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[700],
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    final bool addingNew = !_isExistingRss;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _isLoading ? null : (addingNew ? _addRssToDb : _subscribeChannel),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                addingNew ? Icons.add_circle_outline : Icons.rss_feed,
                size: 18,
              ),
        label: Text(
          addingNew ? 'RSS 추가하기' : '구독하기',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: addingNew ? Colors.green : Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor:
              addingNew ? Colors.green.withValues() : Colors.blue.withValues(),
        ),
      ),
    );
  }

  Widget _buildDefaultChannelIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[400]!, Colors.blue[700]!],
        ),
      ),
      child: const Icon(
        Icons.rss_feed,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}
