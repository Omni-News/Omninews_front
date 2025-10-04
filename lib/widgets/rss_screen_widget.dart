import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

/// RSS 화면에서 사용되는 모든 UI 위젯을 모아둔 클래스
class RssScreenWidget {
  // 채널 이미지 위젯
  static Widget buildChannelImage(RssChannel channel, BuildContext context) {
    final rssTheme = AppTheme.rssThemeOf(context);
    final imageUrl = channel.channelImageUrl ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
      child:
          imageUrl.isNotEmpty
              ? Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, _) {
                  if (frame != null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Theme.of(context).cardColor.withOpacity(0.6),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return buildDefaultChannelImage(context);
                },
              )
              : buildDefaultChannelImage(context),
    );
  }

  // 기본 채널 이미지 위젯
  static Widget buildDefaultChannelImage(BuildContext context) {
    final rssTheme = AppTheme.rssThemeOf(context);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rssTheme.channelImageGradientColors,
        ),
      ),
      child: const Icon(Icons.rss_feed, color: Colors.white, size: 30),
    );
  }

  // 구독 상태 표시 위젯
  static Widget buildSubscriptionIndicator(
    bool isSubscribed,
    String channelRssLink,
    Map<String, bool> subscribingStatus,
    BuildContext context,
  ) {
    final rssTheme = AppTheme.rssThemeOf(context);
    final isProcessing = subscribingStatus[channelRssLink] == true;

    return Semantics(
      button: true,
      label: isSubscribed ? '구독 중' : '구독하기',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child:
            isProcessing
                ? SizedBox(
                  key: const ValueKey('processing'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        isSubscribed
                            ? rssTheme.subscribeButtonActiveText
                            : rssTheme.subscribeButtonInactiveText,
                  ),
                )
                : Container(
                  key: ValueKey(isSubscribed ? 'subscribed' : 'unsubscribed'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSubscribed
                            ? rssTheme.subscribeButtonActivedBackground
                            : rssTheme.subscribeButtonInactiveBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSubscribed ? Icons.check : Icons.add,
                        size: 16,
                        color:
                            isSubscribed
                                ? rssTheme.subscribeButtonActiveText
                                : rssTheme.subscribeButtonInactiveText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSubscribed ? '구독 중' : '구독하기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isSubscribed
                                  ? rssTheme.subscribeButtonActiveText
                                  : rssTheme.subscribeButtonInactiveText,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  // 빈 상태 위젯
  static Widget buildEmptyState(
    String message,
    IconData icon,
    BuildContext context,
  ) {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: subscribeStyle.emptyIconColor),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subscribeStyle.emptyTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (icon == Icons.rss_feed) ...[
            Text(
              'RSS 피드를 추가하려면 아래 + 버튼을 눌러주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subscribeStyle.hintTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 빈 폴더 상태 위젯
  static Widget buildEmptyFolderState(
    BuildContext context,
    VoidCallback onSwitchToListView,
  ) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: subscribeStyle.emptyIconColor,
          ),
          const SizedBox(height: 16),
          Text(
            '생성된 폴더가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: subscribeStyle.emptyTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 새 폴더를 만들어보세요',
            style: TextStyle(fontSize: 14, color: subscribeStyle.hintTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onSwitchToListView,
            icon: Icon(Icons.list, color: theme.primaryColor),
            label: Text(
              '리스트 보기로 전환',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // 채널 리스트 아이템 위젯
  static Widget buildChannelListItem({
    required RssChannel channel,
    required bool isSubscribed,
    required BuildContext context,
    required Function(RssChannel) onTap,
    required Function(RssChannel) onSubscribe,
    required Function(RssChannel) onUnsubscribe,
    required Map<String, bool> subscribingStatus,
    bool showRemoveButton = false,
    VoidCallback? onRemoveFromFolder,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => onTap(channel),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 채널 아이콘
            Hero(
              tag: 'channel_${channel.channelRssLink}',
              child: buildChannelImage(channel, context),
            ),
            const SizedBox(width: 16),

            // 채널 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.channelTitle,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.channelDescription,
                    style: textTheme.bodyMedium?.copyWith(height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: 12,
                        color: textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        channel.channelLanguage ?? 'Unknown',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${channel.channelRank}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 폴더에서 제거 버튼
            if (showRemoveButton && onRemoveFromFolder != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: '폴더에서 제거',
                onPressed: onRemoveFromFolder,
                iconSize: 20,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),

            // 구독 버튼
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                if (isSubscribed) {
                  onUnsubscribe(channel);
                } else {
                  onSubscribe(channel);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: buildSubscriptionIndicator(
                isSubscribed,
                channel.channelRssLink,
                subscribingStatus,
                context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 폴더 시스템 - 매우 심플하고 직관적인 디자인
  static Widget buildSimpleFolderSystem({
    required List<RssFolder> folders,
    required List<RssChannel> unfolderedChannels,
    required BuildContext context,
    required Function(RssFolder) onDeleteFolder,
    required Function(RssChannel, RssFolder) onAddChannelToFolder,
    required Function(RssChannel, RssFolder) onRemoveChannelFromFolder,
    required Function(RssChannel) onChannelTap,
    required Function(RssChannel) onSubscribe,
    required Function(RssChannel) onUnsubscribe,
    required Map<String, bool> subscribingStatus,
    Function(bool)? onDragStatusChanged,
    Function(RssChannel?)? onDraggingChannelChanged,
  }) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        // 1. 폴더 섹션
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 4, bottom: 10),
          child: Text(
            '폴더',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        if (folders.isEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 16, top: 2),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.dividerColor.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 40,
                    color: theme.hintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '폴더가 없습니다',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+ 버튼을 눌러 새 폴더를 만들어보세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.hintColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          // 폴더 목록
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _buildSimpleFolderItem(
                folder: folder,
                context: context,
                onDeleteFolder: onDeleteFolder,
                onAddChannelToFolder: onAddChannelToFolder,
                onRemoveChannelFromFolder: onRemoveChannelFromFolder,
                onChannelTap: onChannelTap,
                onSubscribe: onSubscribe,
                onUnsubscribe: onUnsubscribe,
                subscribingStatus: subscribingStatus,
                onDragStatusChanged: onDragStatusChanged,
                onDraggingChannelChanged: onDraggingChannelChanged,
              );
            },
          ),

        // 2. 폴더에 속하지 않은 채널 섹션
        if (unfolderedChannels.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 4, bottom: 10),
            child: Text(
              '폴더에 속하지 않은 채널',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: unfolderedChannels.length,
            separatorBuilder:
                (context, index) => Divider(
                  height: 1,
                  thickness: 0.2,
                  color: theme.dividerColor.withOpacity(0.3),
                ),
            itemBuilder: (context, index) {
              return _buildDraggableChannelItem(
                channel: unfolderedChannels[index],
                isInFolder: false,
                context: context,
                onChannelTap: onChannelTap,
                onSubscribe: onSubscribe,
                onUnsubscribe: onUnsubscribe,
                subscribingStatus: subscribingStatus,
                onDragStatusChanged: onDragStatusChanged,
                onDraggingChannelChanged: onDraggingChannelChanged,
              );
            },
          ),
        ],

        // 플로팅 버튼을 위한 공간
        const SizedBox(height: 80),
      ],
    );
  }

  // 매우 심플한 폴더 아이템 - 검은줄 제거, 항상 삭제 버튼 표시
  static Widget _buildSimpleFolderItem({
    required RssFolder folder,
    required BuildContext context,
    required Function(RssFolder) onDeleteFolder,
    required Function(RssChannel, RssFolder) onAddChannelToFolder,
    required Function(RssChannel, RssFolder) onRemoveChannelFromFolder,
    required Function(RssChannel) onChannelTap,
    required Function(RssChannel) onSubscribe,
    required Function(RssChannel) onUnsubscribe,
    required Map<String, bool> subscribingStatus,
    Function(bool)? onDragStatusChanged,
    Function(RssChannel?)? onDraggingChannelChanged,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 4, top: 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: DragTarget<RssChannel>(
        onWillAccept: (channel) => channel != null,
        onAccept: (channel) {
          final isAlreadyInFolder = folder.folderChannels.any(
            (c) => c.channelId == channel.channelId,
          );
          if (!isAlreadyInFolder) {
            onAddChannelToFolder(channel, folder);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isDragging = candidateData.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  isDragging
                      ? theme.primaryColor.withOpacity(0.05)
                      : Colors.transparent,
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
                childrenPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_outlined, color: theme.primaryColor),
                title: const Text(
                  '폴더',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  folder.folderName.isNotEmpty
                      ? '${folder.folderName} • ${folder.folderChannels.length}개의 채널'
                      : '${folder.folderChannels.length}개의 채널',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 항상 삭제 버튼 표시
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => onDeleteFolder(folder),
                      tooltip: '폴더 삭제',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 22),
                  ],
                ),
                children:
                    folder.folderChannels.isEmpty
                        ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '이 폴더에 채널을 추가하려면 드래그하세요',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]
                        : folder.folderChannels.map((channel) {
                          return _buildDraggableChannelItem(
                            channel: channel,
                            isInFolder: true,
                            context: context,
                            onChannelTap: onChannelTap,
                            onSubscribe: onSubscribe,
                            onUnsubscribe: onUnsubscribe,
                            subscribingStatus: subscribingStatus,
                            onDragStatusChanged: onDragStatusChanged,
                            onDraggingChannelChanged: onDraggingChannelChanged,
                            onRemoveFromFolder:
                                () =>
                                    onRemoveChannelFromFolder(channel, folder),
                          );
                        }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // 드래그 가능한 채널 아이템
  static Widget _buildDraggableChannelItem({
    required RssChannel channel,
    required bool isInFolder,
    required BuildContext context,
    required Function(RssChannel) onChannelTap,
    required Function(RssChannel) onSubscribe,
    required Function(RssChannel) onUnsubscribe,
    required Map<String, bool> subscribingStatus,
    VoidCallback? onRemoveFromFolder,
    Function(bool)? onDragStatusChanged,
    Function(RssChannel?)? onDraggingChannelChanged,
  }) {
    return LongPressDraggable<RssChannel>(
      data: channel,
      feedback: _buildDragFeedback(channel, context),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildChannelListItemSimple(channel: channel, context: context),
      ),
      onDragStarted: () {
        onDragStatusChanged?.call(true);
        onDraggingChannelChanged?.call(channel);
      },
      onDragEnd: (details) {
        onDragStatusChanged?.call(false);
        onDraggingChannelChanged?.call(null);
      },
      child: _buildChannelListItemSimple(
        channel: channel,
        context: context,
        onTap: () => onChannelTap(channel),
        isInFolder: isInFolder,
        onRemoveFromFolder: onRemoveFromFolder,
      ),
    );
  }

  // 매우 간결한 채널 리스트 아이템
  static Widget _buildChannelListItemSimple({
    required RssChannel channel,
    required BuildContext context,
    VoidCallback? onTap,
    bool isInFolder = false,
    VoidCallback? onRemoveFromFolder,
  }) {
    final theme = Theme.of(context);
    final imageUrl = channel.channelImageUrl ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // 이미지 (작게)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: theme.primaryColor.withOpacity(0.2),
                                child: Icon(
                                  Icons.rss_feed,
                                  color: theme.primaryColor,
                                ),
                              ),
                        )
                        : Container(
                          color: theme.primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.rss_feed,
                            color: theme.primaryColor,
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // 채널 정보 (간결하게)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.channelTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    channel.channelDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 폴더에서 제거 버튼
            if (isInFolder && onRemoveFromFolder != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: onRemoveFromFolder,
                color: theme.colorScheme.error.withOpacity(0.7),
                tooltip: '폴더에서 제거',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 24,
                  height: 24,
                ),
              ),

            // 드래그 핸들
            Icon(
              Icons.drag_indicator,
              size: 18,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  // 드래그 중인 채널 미리보기
  static Widget _buildDragFeedback(RssChannel channel, BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = channel.channelImageUrl ?? '';

    return Material(
      color: Colors.transparent,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        width: 220,
        child: Row(
          children: [
            // 작은 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 30,
                height: 30,
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: theme.primaryColor.withOpacity(0.2),
                                child: Icon(
                                  Icons.rss_feed,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                              ),
                        )
                        : Container(
                          color: theme.primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.rss_feed,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // 채널명
            Expanded(
              child: Text(
                channel.channelTitle,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 개선된 FloatingActionButton 메뉴 (SpeedDial 스타일)
  static Widget buildSpeedDialButton({
    required BuildContext context,
    required VoidCallback onCreateFolder,
    required VoidCallback onAddRss,
  }) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      heroTag: 'mainFab',
      backgroundColor: theme.primaryColor,
      elevation: 4,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder:
              (context) => SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '옵션 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // 폴더 생성 옵션
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.create_new_folder_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      title: const Text('폴더 생성하기'),
                      subtitle: const Text('RSS 채널을 구성할 새 폴더를 만듭니다'),
                      onTap: () {
                        Navigator.pop(context);
                        onCreateFolder();
                      },
                    ),

                    // RSS 추가 옵션
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.rss_feed_rounded,
                          color: theme.primaryColor,
                        ),
                      ),
                      title: const Text('RSS 추가하기'),
                      subtitle: const Text('새로운 RSS 피드를 구독합니다'),
                      onTap: () {
                        Navigator.pop(context);
                        onAddRss();
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
        );
      },
      child: const Icon(Icons.add, size: 24),
    );
  }
}

// TabBar를 위한 SliverPersistentHeader delegate 클래스
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ThemeData theme;

  SliverAppBarDelegate(this.child, {required this.theme});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow:
            overlapsContent
                ? [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
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
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) => true;
}
