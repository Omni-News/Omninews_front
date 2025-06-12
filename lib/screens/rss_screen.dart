import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/services/rss_folder_service.dart';
import 'package:omninews_flutter/screens/rss_add_screen.dart';
import 'package:omninews_flutter/screens/rss_channel_detail_screen.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/widgets/rss_screen_widget.dart';

class RssScreen extends StatefulWidget {
  const RssScreen({super.key});

  @override
  State<RssScreen> createState() => _RssScreenState();
}

class _RssScreenState extends State<RssScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<List<RssChannel>> subscribedChannels;
  late Future<List<RssChannel>> recommendedChannels;
  late Future<List<RssFolder>> folders;
  List<RssChannel> subscribedChannelsList = [];
  List<RssFolder> foldersList = [];
  late TabController _tabController;
  final List<String> _tabs = ['구독 중', '인기 RSS'];
  bool _isLoading = true;
  // 기본값을 true로 변경하여 폴더 모드로 시작
  bool _isFolderView = true;
  bool _isDragging = false;
  RssChannel? _draggingChannel;
  final Map<String, bool> _subscribingStatus = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  // 기본 폴더 생성 메서드 추가

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  // 반환 타입 수정
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    subscribedChannels = RssService.fetchSubscribedChannels();
    folders = RssFolderService.fetchFolders();

    subscribedChannelsList = await subscribedChannels;
    foldersList = await folders;
    recommendedChannels = _fetchFilteredRecommendedChannels();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<RssChannel>> _fetchFilteredRecommendedChannels() async {
    final allRecommended = await RssService.fetchRecommendedChannels();
    final subscribedLinks =
        subscribedChannelsList.map((e) => e.channelRssLink).toSet();
    return allRecommended
        .where((channel) => !subscribedLinks.contains(channel.channelRssLink))
        .toList();
  }

  Future<void> _subscribeToChannel(RssChannel channel) async {
    if (_subscribingStatus[channel.channelRssLink] == true) return;

    setState(() {
      _subscribingStatus[channel.channelRssLink] = true;
    });

    try {
      final success = await RssService.subscribeChannel(channel.channelId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${channel.channelTitle} 구독되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _refreshData();
        _tabController.animateTo(0);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('구독 처리 중 오류가 발생했습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _subscribingStatus[channel.channelRssLink] = false;
        });
      }
    }
  }

  Future<void> _unsubscribeFromChannel(RssChannel channel) async {
    if (_subscribingStatus[channel.channelRssLink] == true) return;

    setState(() {
      _subscribingStatus[channel.channelRssLink] = true;
    });

    try {
      final success = await RssService.unsubscribeChannel(channel.channelId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${channel.channelTitle} 구독 취소되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _refreshData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('구독 취소 처리 중 오류가 발생했습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _subscribingStatus[channel.channelRssLink] = false;
        });
      }
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final TextEditingController folderNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('새 폴더 만들기'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: folderNameController,
                decoration: const InputDecoration(
                  labelText: '폴더 이름',
                  hintText: '폴더 이름을 입력하세요',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '폴더 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(folderNameController.text);
                  }
                },
                child: const Text('생성'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // createFolder가 이제 bool 반환한다고 가정
        final success = await RssFolderService.createFolder(result);

        if (success && mounted) {
          // 폴더 생성 성공 시에만 폴더 목록 새로고침
          _refreshData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 "$result"가 생성되었습니다'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
            ),
          );
        } else if (mounted) {
          // 폴더 생성 실패 시 오류 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 생성에 실패했습니다'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 생성 중 오류가 발생했습니다: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
            ),
          );
        }
      }
    }
  }

  // 폴더 삭제 메서드 - 채널을 구독 취소하지 않고 폴더에서만 제거하도록 수정
  Future<void> _deleteFolder(RssFolder folder) async {
    try {
      // 폴더에 채널이 있는 경우
      if (folder.folderChannels.isNotEmpty) {
        // 확인 다이얼로그 표시
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('폴더 삭제'),
                content: Text(
                  '${folder.folderName} 폴더를 삭제하면 포함된 채널들은 폴더에서 제거됩니다.\n\n계속하시겠습니까?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('삭제'),
                  ),
                ],
              ),
        );

        if (confirmed != true) return;

        // 폴더의 모든 채널을 먼저 폴더에서 제거 (구독 취소 없이)
        final channels = [...folder.folderChannels]; // 목록 복사
        for (final channel in channels) {
          await RssFolderService.removeChannelFromFolder(
            channel.channelId,
            folder.folderId,
          );
        }
      }

      // 폴더 삭제
      await RssFolderService.deleteFolder(folder.folderId);
      _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('폴더 "${folder.folderName}"가 삭제되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
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
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  Future<void> _addChannelToFolder(RssChannel channel, RssFolder folder) async {
    try {
      await RssFolderService.addChannelToFolder(
        channel.channelId,
        folder.folderId,
      );
      _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${channel.channelTitle}이(가) ${folder.folderName} 폴더에 추가되었습니다',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채널을 폴더에 추가하는 중 오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  Future<void> _removeChannelFromFolder(
    RssChannel channel,
    RssFolder folder,
  ) async {
    try {
      // 폴더의 마지막 채널인지 확인
      final isLastChannel = folder.folderChannels.length == 1;

      // 채널 제거 요청
      final success = await RssFolderService.removeChannelFromFolder(
        channel.channelId,
        folder.folderId,
      );

      if (success) {
        // 성공적으로 제거된 경우 알림 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${channel.channelTitle}이(가) ${folder.folderName} 폴더에서 제거되었습니다',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
            ),
          );
        }

        // 마지막 채널이었던 경우, 서버에서 폴더가 삭제됐을 가능성이 있으므로
        // 빈 폴더를 다시 생성 시도
        if (isLastChannel) {
          try {
            // 제거 후 폴더 존재 여부 확인하는 로직 추가 필요
            // 현재 구현에서는 서버에 직접 요청하는 대신 로컬에서 처리
            final existingFolders = await RssFolderService.fetchFolders();
            final folderExists = existingFolders.any(
              (f) => f.folderId == folder.folderId,
            );

            if (!folderExists) {
              // 폴더가 삭제되었다면 같은 이름으로 다시 생성
              await RssFolderService.createFolder(folder.folderName);
            }
          } catch (e) {
            print('빈 폴더 유지 시도 중 오류: $e');
          }
        }
      }

      // 최종적으로 데이터 새로고침
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채널을 폴더에서 제거하는 중 오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  // 폴더에 속하지 않은 채널들 필터링
  List<RssChannel> _getUnfolderedChannels(List<RssFolder> folders) {
    final allFolderedChannelIds = <int>{};
    for (final folder in folders) {
      allFolderedChannelIds.addAll(
        folder.folderChannels.map((c) => c.channelId),
      );
    }
    return subscribedChannelsList
        .where((channel) => !allFolderedChannelIds.contains(channel.channelId))
        .toList();
  }

  void _navigateToChannelDetail(RssChannel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RssChannelDetailScreen(
              channel: channel,
              isSubscribed: true,
              onSubscriptionChanged: _refreshData,
            ),
      ),
    ).then((_) => _refreshData());
  }

  Future<void> _navigateToAddRss() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RssAddScreen(onChannelAdded: _refreshData),
      ),
    );
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 앱바
            SliverAppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  homeScaffoldKey.currentState?.openDrawer();
                },
              ),
              pinned: true,
              elevation: 0,
              centerTitle: true,
              title: Text('RSS Feeds', style: textTheme.headlineMedium),
              actions: [
                // 보기 모드 전환 버튼
                if (_tabController.index == 0)
                  IconButton(
                    icon: Icon(
                      _isFolderView ? Icons.list : Icons.folder_copy_outlined,
                    ),
                    tooltip: _isFolderView ? '리스트 보기' : '폴더 보기',
                    onPressed: () {
                      setState(() {
                        _isFolderView = !_isFolderView;
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
              ],
            ),

            // 탭바
            SliverPersistentHeader(
              delegate: SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.primaryColor,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: textTheme.bodyLarge?.color,
                  indicatorWeight: 3,
                  labelStyle: textTheme.labelLarge,
                  unselectedLabelStyle: textTheme.labelMedium,
                  tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
                ),
                theme: theme,
              ),
              floating: true,
              pinned: true,
            ),
          ];
        },

        // 메인 콘텐츠
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                )
                : TabBarView(
                  controller: _tabController,
                  children: [
                    // 구독 중 탭
                    _isFolderView ? _buildFolderView() : _buildSubscribedTab(),

                    // 추천 RSS 탭
                    _buildRecommendedTab(),
                  ],
                ),
      ),

      // FloatingActionButton 추가 (직접 구현)
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add),
        onPressed: () {
          // 바텀 시트로 메뉴 표시
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder:
                (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 제목
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '옵션 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Divider(height: 1),

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
                          Navigator.pop(context); // 바텀시트 닫기
                          _showCreateFolderDialog(); // 폴더 생성 다이얼로그
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
                          Navigator.pop(context); // 바텀시트 닫기
                          _navigateToAddRss(); // RSS 추가 화면
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }

  // 폴더 보기 화면
  Widget _buildFolderView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<RssFolder>>(
        future: folders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('폴더를 불러오는데 실패했습니다: ${snapshot.error}'));
          } else {
            // 폴더가 없는 경우에도 계속 진행
            final folderData = snapshot.data ?? [];

            // 폴더에 속하지 않은 채널 필터링
            final unfolderedChannels = _getUnfolderedChannels(folderData);

            // 항상 심플한 폴더 시스템 UI 생성 (빈 폴더 목록이어도 진행)
            return RssScreenWidget.buildSimpleFolderSystem(
              folders: folderData,
              unfolderedChannels: unfolderedChannels,
              context: context,
              onDeleteFolder: _deleteFolder,
              onAddChannelToFolder: _addChannelToFolder,
              onRemoveChannelFromFolder: _removeChannelFromFolder,
              onChannelTap: _navigateToChannelDetail,
              onSubscribe: _subscribeToChannel,
              onUnsubscribe: _unsubscribeFromChannel,
              subscribingStatus: _subscribingStatus,
              onDragStatusChanged: (isDragging) {
                setState(() {
                  _isDragging = isDragging;
                });
              },
              onDraggingChannelChanged: (channel) {
                setState(() {
                  _draggingChannel = channel;
                });
              },
            );
          }
        },
      ),
    );
  }

  // 구독 중인 RSS 탭
  Widget _buildSubscribedTab() {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: FutureBuilder<List<RssChannel>>(
        future: subscribedChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: subscribeStyle.errorIconColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '데이터를 불러올 수 없습니다',
                    style: TextStyle(
                      color: subscribeStyle.emptyTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    // 얇고 샤프한 구분선
                    thickness: 0.2,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
              itemBuilder: (context, index) {
                final channel = snapshot.data![index];
                return RssScreenWidget.buildChannelListItem(
                  channel: channel,
                  isSubscribed: true,
                  context: context,
                  onTap: _navigateToChannelDetail,
                  onSubscribe: _subscribeToChannel,
                  onUnsubscribe: _unsubscribeFromChannel,
                  subscribingStatus: _subscribingStatus,
                );
              },
            );
          } else {
            return RssScreenWidget.buildEmptyState(
              '구독 중인 RSS가 없습니다',
              Icons.rss_feed,
              context,
            );
          }
        },
      ),
    );
  }

  // 추천 RSS 탭
  Widget _buildRecommendedTab() {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: FutureBuilder<List<RssChannel>>(
        future: recommendedChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: subscribeStyle.errorIconColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '추천 채널을 불러오는데 실패했습니다',
                    style: TextStyle(
                      color: subscribeStyle.emptyTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    // 얇고 샤프한 구분선
                    thickness: 0.2,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
              itemBuilder: (context, index) {
                final channel = snapshot.data![index];
                return RssScreenWidget.buildChannelListItem(
                  channel: channel,
                  isSubscribed: false,
                  context: context,
                  onTap: _navigateToChannelDetail,
                  onSubscribe: _subscribeToChannel,
                  onUnsubscribe: _unsubscribeFromChannel,
                  subscribingStatus: _subscribingStatus,
                );
              },
            );
          } else {
            return RssScreenWidget.buildEmptyState(
              '모든 추천 채널을 이미 구독 중입니다',
              Icons.check_circle,
              context,
            );
          }
        },
      ),
    );
  }
}
