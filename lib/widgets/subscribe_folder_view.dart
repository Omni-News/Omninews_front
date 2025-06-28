import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/screens/folder_content_screen.dart';
import 'package:omninews_flutter/services/rss_folder_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SubscribeFolderView extends StatefulWidget {
  final Future<List<RssFolder>> folders;
  final String searchQuery;
  final VoidCallback onRefresh;
  final VoidCallback onCreateFolder;

  const SubscribeFolderView({
    super.key,
    required this.folders,
    required this.searchQuery,
    required this.onRefresh,
    required this.onCreateFolder,
  });

  @override
  State<SubscribeFolderView> createState() => _SubscribeFolderViewState();
}

class _SubscribeFolderViewState extends State<SubscribeFolderView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
      },
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: FutureBuilder<List<RssFolder>>(
        future: widget.folders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('폴더를 불러오는데 실패했습니다', context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              widget.searchQuery.isEmpty ? '구독 폴더가 없습니다' : '검색 결과가 없습니다',
              widget.searchQuery.isEmpty ? Icons.folder_outlined : Icons.search,
            );
          }

          final folders = snapshot.data!;

          // 검색어가 있으면 필터링
          if (widget.searchQuery.isNotEmpty) {
            folders.retainWhere(
              (folder) => folder.folderName.toLowerCase().contains(
                widget.searchQuery.toLowerCase(),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _buildFolderCard(folder);
            },
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(RssFolder folder) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _navigateToFolderContent(folder);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 폴더 아이콘
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 폴더 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.folderName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${folder.folderChannels.length}개 채널 · ${_calculateItemCount(folder)}개 항목',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subscribeStyle.hintTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 삭제 버튼
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error.withOpacity(0.7),
                    ),
                    onPressed: () => _confirmDeleteFolder(folder),
                  ),
                ],
              ),

              if (folder.folderChannels.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 채널 미리보기 그리드 (최대 3개) - 수정된 부분
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildChannelPreviewGrid(folder, theme),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 채널 미리보기 그리드를 만드는 새 메서드
  List<Widget> _buildChannelPreviewGrid(RssFolder folder, ThemeData theme) {
    // 표시할 채널 수 결정 (최대 3개)
    final displayCount =
        folder.folderChannels.length > 3 ? 3 : folder.folderChannels.length;

    final List<Widget> channelWidgets = [];

    // 채널 위젯 생성
    for (var i = 0; i < displayCount; i++) {
      final channel = folder.folderChannels[i];
      channelWidgets.add(
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          constraints: const BoxConstraints(
            maxWidth: 110,
          ), // 너비 제한으로 한 줄에 3개 표시
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 채널 이미지
              if (channel.channelImageUrl != null &&
                  channel.channelImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    channel.channelImageUrl!,
                    width: 16,
                    height: 16,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Icons.rss_feed,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                  ),
                )
              else
                Icon(Icons.rss_feed, size: 12, color: theme.primaryColor),
              const SizedBox(width: 4),

              // 채널 이름 (짧게)
              Flexible(
                child: Text(
                  _shortenTitle(channel.channelTitle),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // "더보기" 위젯 추가 (3개 초과 시)
    if (folder.folderChannels.length > 3) {
      channelWidgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8),
          child: Text(
            "+ ${folder.folderChannels.length - 3}개 더 있음",
            style: TextStyle(
              fontSize: 12,
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return channelWidgets;
  }

  // 채널 이름 짧게 표시
  String _shortenTitle(String title) {
    if (title.length > 10) {
      return '${title.substring(0, 8)}..';
    }
    return title;
  }

  // 폴더 내 채널들의 총 항목 수를 계산하는 더미 함수 (변경 없음)
  int _calculateItemCount(RssFolder folder) {
    // 이 부분은 실제 항목 수를 계산하는 로직으로 대체해야 함
    return folder.folderChannels.length * 5; // 임시로 채널당 5개 항목으로 가정
  }

  // 폴더 삭제 확인 다이얼로그
  Future<void> _confirmDeleteFolder(RssFolder folder) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('폴더 삭제'),
            content: Text('${folder.folderName} 폴더를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  '삭제',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        final success = await RssFolderService.deleteFolder(folder.folderId);
        if (success && mounted) {
          widget.onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 ${folder.folderName}가 삭제되었습니다'),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 삭제 중 오류가 발생했습니다: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // 폴더 컨텐츠 화면으로 이동
  void _navigateToFolderContent(RssFolder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FolderContentScreen(
              folder: folder,
              onRefresh: widget.onRefresh,
            ),
      ),
    ).then((_) => widget.onRefresh());
  }

  Widget _buildErrorState(String message, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: subscribeStyle.errorIconColor,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subscribeStyle.emptyTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: subscribeStyle.emptyIconColor),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: subscribeStyle.emptyTextColor,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.searchQuery.isEmpty &&
                icon == Icons.folder_outlined) ...[
              const SizedBox(height: 8),
              Text(
                '구독 폴더가 없습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: subscribeStyle.hintTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onCreateFolder,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('새 폴더 만들기'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
