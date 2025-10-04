import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SubscribeChannelView extends StatefulWidget {
  final Future<Map<RssChannel, List<RssItem>>> channelItems;
  final String searchQuery;
  final VoidCallback onRefresh;

  const SubscribeChannelView({
    super.key,
    required this.channelItems,
    required this.searchQuery,
    required this.onRefresh,
  });

  @override
  State<SubscribeChannelView> createState() => _SubscribeChannelViewState();
}

class _SubscribeChannelViewState extends State<SubscribeChannelView> {
  // 특정 채널이 더보기로 확장되었는지 추적
  final Map<String, bool> _expandedChannels = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
      },
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: FutureBuilder<Map<RssChannel, List<RssItem>>>(
        future: widget.channelItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // RefreshIndicator가 동작하도록 항상 스크롤 가능한 위젯 반환
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는데 실패했습니다', context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              widget.searchQuery.isEmpty ? '구독 중인 채널이 없습니다' : '검색 결과가 없습니다',
              widget.searchQuery.isEmpty ? Icons.feed : Icons.search,
            );
          }

          // 원본을 변형하지 않도록 복사 후 검색어 필터링
          final q = widget.searchQuery.trim().toLowerCase();
          final entries = snapshot.data!.entries.toList();

          final visibleEntries = <MapEntry<RssChannel, List<RssItem>>>[];
          for (final e in entries) {
            final channel = e.key;
            final items = e.value;

            if (q.isEmpty) {
              visibleEntries.add(e);
              continue;
            }

            final titleMatch = channel.channelTitle.toLowerCase().contains(q);
            final filteredItems =
                items.where((it) {
                  final t = it.rssTitle.toLowerCase();
                  final d = it.rssDescription.toLowerCase();
                  return t.contains(q) || d.contains(q);
                }).toList();

            if (titleMatch || filteredItems.isNotEmpty) {
              visibleEntries.add(
                MapEntry(channel, titleMatch ? items : filteredItems),
              );
            }
          }

          if (visibleEntries.isEmpty) {
            return _buildEmptyState('검색 결과가 없습니다', Icons.search);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: visibleEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final channel = visibleEntries[index].key;
              final items = visibleEntries[index].value;
              return _buildChannelCard(context, channel, items);
            },
          );
        },
      ),
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    RssChannel channel,
    List<RssItem> items,
  ) {
    final theme = Theme.of(context);

    final keyValue = channel.channelRssLink; // 고유 키로 사용
    final isExpanded = _expandedChannels[keyValue] ?? false;
    final itemsToShow = isExpanded ? items : items.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: theme.highlightColor,
          highlightColor: theme.highlightColor,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          expandedAlignment: Alignment.topLeft,
          maintainState: true,
          backgroundColor: theme.cardColor,
          collapsedBackgroundColor: theme.cardColor,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              _buildChannelImage(channel),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.channelTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${items.length}개의 항목',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  theme.brightness == Brightness.dark
                      ? theme.cardColor.withOpacity(0.3)
                      : theme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
          ),
          onExpansionChanged: (expanded) {
            // ExpansionTile 열림/닫힘은 콘텐츠 표시에는 영향 없이 단순히 펼침 영역만 제어
            // '더보기'/`접기`는 _expandedChannels를 통해 개별적으로 제어함
            setState(() {});
          },
          children: [
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: List.generate(itemsToShow.length, (i) {
                    final item = itemsToShow[i];
                    return Column(
                      children: [
                        RssItemCard(
                          item: item,
                          onBookmarkChanged: widget.onRefresh,
                        ),
                        if (i < itemsToShow.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            if (items.length > 3 && !isExpanded)
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedChannels[keyValue] = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        theme.brightness == Brightness.dark
                            ? theme.cardColor.withOpacity(0.3)
                            : theme.cardColor.withOpacity(0.8),
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${items.length - 3}개 더보기',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (items.length > 3 && isExpanded)
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedChannels[keyValue] = false;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        theme.brightness == Brightness.dark
                            ? theme.cardColor.withOpacity(0.3)
                            : theme.cardColor.withOpacity(0.8),
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '접기',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelImage(RssChannel channel) {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);

    return Hero(
      tag: 'channel_${channel.channelRssLink}',
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            rssTheme.channelImageBorderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            rssTheme.channelImageBorderRadius,
          ),
          child:
              (channel.channelImageUrl != null &&
                      channel.channelImageUrl!.isNotEmpty)
                  ? Image.network(
                    channel.channelImageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 48,
                        height: 48,
                        color:
                            theme.brightness == Brightness.dark
                                ? theme.cardColor.withOpacity(0.5)
                                : theme.cardColor.withOpacity(0.8),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultChannelIcon();
                    },
                  )
                  : _buildDefaultChannelIcon(),
        ),
      ),
    );
  }

  Widget _buildDefaultChannelIcon() {
    final rssTheme = AppTheme.rssThemeOf(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rssTheme.channelImageGradientColors,
        ),
      ),
      child: const Center(
        child: Icon(Icons.rss_feed, color: Colors.white, size: 20),
      ),
    );
  }

  // 에러 상태(당겨서 새로고침 가능)
  Widget _buildErrorState(String message, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
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
        ),
      ],
    );
  }

  // 빈 상태(당겨서 새로고침 가능)
  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
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
                if (widget.searchQuery.isEmpty && icon == Icons.feed) ...[
                  const SizedBox(height: 16),
                  Text(
                    '아직 구독한 채널이 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: subscribeStyle.hintTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.brightness == Brightness.dark
                              ? theme.cardColor.withOpacity(0.3)
                              : theme.cardColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      'RSS 화면에서 채널을 구독해보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: subscribeStyle.hintTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
