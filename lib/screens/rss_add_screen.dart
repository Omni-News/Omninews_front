import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/rss_channel.dart';
import 'package:omninews_test_flutter/services/rss_service.dart';
import 'package:omninews_test_flutter/theme/app_theme.dart';

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
            SnackBar(
              content: const Text('RSS가 성공적으로 추가되었습니다'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
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
            SnackBar(
              content: const Text('RSS 채널이 구독되었습니다'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'RSS 추가',
          style: textTheme.headlineMedium,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트
              Text(
                'RSS 피드 URL 입력',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'RSS 주소를 입력하고 미리보기 버튼을 눌러주세요.',
                style: textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              // URL 입력 필드
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
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
                        hintStyle: TextStyle(color: theme.hintColor),
                        filled: true,
                        fillColor: theme.cardColor,
                        prefixIcon: Icon(Icons.link,
                            color: theme.iconTheme.color?.withOpacity(0.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: theme.dividerColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: theme.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: textTheme.bodyLarge?.copyWith(fontSize: 16),
                      onSubmitted: (_) => _previewRss(),
                    ),

                    const SizedBox(height: 12),

                    // 미리보기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPreviewLoading ? null : _previewRss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor:
                              theme.primaryColor.withOpacity(0.5),
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
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.error,
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
                Row(
                  children: [
                    Icon(Icons.preview, size: 22, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'RSS 미리보기',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 18,
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

    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
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
              color: theme.cardColor,
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
                      borderRadius: BorderRadius.circular(
                          rssTheme.channelImageBorderRadius),
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
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _previewChannel!.channelLink,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
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
                  style: textTheme.bodyMedium?.copyWith(height: 1.5),
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
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? theme.iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: chipTheme.labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionButton() {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);

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
            backgroundColor: theme.disabledColor.withOpacity(0.2),
            foregroundColor: theme.disabledColor,
            disabledBackgroundColor: theme.disabledColor.withOpacity(0.2),
            disabledForegroundColor: theme.disabledColor,
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
          backgroundColor: addingNew
              ? Colors.green
              : rssTheme.subscribeButtonActiveBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: addingNew
              ? Colors.green.withOpacity(0.5)
              : theme.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildDefaultChannelIcon() {
    final rssTheme = AppTheme.rssThemeOf(context);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rssTheme.channelImageGradientColors,
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
