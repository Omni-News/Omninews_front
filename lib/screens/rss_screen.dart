import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/services/rss_folder_service.dart';
import 'package:omninews_flutter/screens/rss_add_screen.dart';
import 'package:omninews_flutter/screens/rss_channel_detail_screen.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/widgets/rss_screen_widget.dart';
import 'package:omninews_flutter/utils/ad_manager.dart';
import 'package:provider/provider.dart';

class RssScreen extends StatefulWidget {
  const RssScreen({super.key});

  @override
  State<RssScreen> createState() => _RssScreenState();
}

class _RssScreenState extends State<RssScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // [✅ 수정] Future 변수 초기화 (null safety 및 초기 로딩 상태 표시 개선)
  late Future<List<RssChannel>> subscribedChannels = Future.value(
    [],
  ); // 빈 리스트로 초기화
  late Future<List<RssChannel>> recommendedChannels = Future.value([]);
  late Future<List<RssFolder>> folders = Future.value([]);

  List<RssChannel> subscribedChannelsList = [];
  List<RssFolder> foldersList = [];
  late TabController _tabController;
  final List<String> _tabs = ['구독 중', '추천 RSS'];
  bool _isLoading = true; // 메인 로딩 상태는 유지
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
    _refreshData(); // 데이터 로딩 시작

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  // [✅ 수정] 로딩 상태 관리 및 Future 업데이트 방식 개선
  Future<void> _refreshData() async {
    // 새로고침 시작 시 로딩 상태 설정
    if (mounted) {
      setState(() {
        _isLoading = true;
        // FutureBuilder가 즉시 로딩 상태를 표시하도록 Completer 사용 (선택적)
        // subscribedChannels = Completer<List<RssChannel>>().future;
        // folders = Completer<List<RssFolder>>().future;
        // recommendedChannels = Completer<List<RssChannel>>().future;
      });
    } else {
      _isLoading = true; // initState 등 마운트 전 호출 시
    }

    try {
      // 데이터 병렬 로딩
      final results = await Future.wait([
        RssService.fetchSubscribedChannels(),
        RssFolderService.fetchFolders(),
        RssService.fetchRecommendedChannels(),
      ]);

      // 결과 처리 (await 이후 mounted 확인 필수)
      if (!mounted) return;

      subscribedChannelsList = results[0] as List<RssChannel>;
      foldersList = results[1] as List<RssFolder>;
      final allRecommended = results[2] as List<RssChannel>;

      final subscribedLinks =
          subscribedChannelsList.map((e) => e.channelRssLink).toSet();
      final filteredRecommended =
          allRecommended
              .where(
                (channel) => !subscribedLinks.contains(channel.channelRssLink),
              )
              .toList();

      // 모든 데이터 처리 후 한번에 상태 업데이트
      setState(() {
        subscribedChannels = Future.value(subscribedChannelsList);
        folders = Future.value(foldersList);
        recommendedChannels = Future.value(filteredRecommended);
        _isLoading = false; // 로딩 완료
      });
    } catch (e) {
      debugPrint("Error refreshing RSS data: $e");
      if (mounted) {
        // 오류 발생 시에도 로딩 상태 해제 및 Future에 오류 전달
        setState(() {
          subscribedChannels = Future.error(e);
          folders = Future.error(e);
          recommendedChannels = Future.error(e);
          _isLoading = false; // 로딩 완료 (오류 상태)
        });
        // 사용자에게 오류 알림 (선택적)
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('데이터 로딩 실패: $e')));
      }
    }
  }

  Future<List<RssChannel>> _fetchFilteredRecommendedChannels() async {
    // _refreshData에서 필터링된 Future를 반환
    return recommendedChannels;
  }

  // ... (다른 메서드들 - 변경 없음) ...
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
        final success = await RssFolderService.createFolder(result);
        if (success && mounted) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('폴더 생성에 실패했습니다'),
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

  Future<void> _deleteFolder(RssFolder folder) async {
    try {
      if (folder.folderChannels.isNotEmpty) {
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
        final channels = [...folder.folderChannels];
        for (final channel in channels) {
          await RssFolderService.removeChannelFromFolder(
            channel.channelId,
            folder.folderId,
          );
        }
      }
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
      final isLastChannel = folder.folderChannels.length == 1;
      final success = await RssFolderService.removeChannelFromFolder(
        channel.channelId,
        folder.folderId,
      );
      if (success) {
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
      }
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

  Future<void> _navigateToChannelDetail(RssChannel channel) async {
    try {
      setState(() {
        _subscribingStatus[channel.channelRssLink] = true;
      });
      final isSubscribed = await RssService.isChannelAlreadySubscribed(
        channel.channelRssLink,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RssChannelDetailScreen(
                  channel: channel,
                  isSubscribed: isSubscribed,
                  onSubscriptionChanged: _refreshData,
                ),
          ),
        ).then((_) => _refreshData());
      }
    } catch (e) {
      debugPrint('채널 상세 이동 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('채널 정보를 불러오는 중 오류가 발생했습니다'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
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
    final adManager = context.watch<AdManager>();

    Widget _buildBannerAdWidget() {
      // ... (배너 광고 위젯 빌더 - 변경 없음) ...
      final bannerAd = adManager.getBannerAd(
        AdManager.rssScreenBannerPlacement,
      );
      final isLoaded = adManager.isBannerAdLoaded(
        AdManager.rssScreenBannerPlacement,
      );
      if (adManager.showAds && isLoaded && bannerAd != null) {
        return Container(
          key: ValueKey(bannerAd.hashCode),
          alignment: Alignment.center,
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              /* ... AppBar ... */
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => homeScaffoldKey.currentState?.openDrawer(),
                tooltip: '메뉴 열기',
              ),
              pinned: true,
              elevation: 0,
              centerTitle: true,
              title: Text('RSS 피드', style: textTheme.headlineMedium),
              actions: [
                if (_tabController.index == 0)
                  IconButton(
                    icon: Icon(
                      _isFolderView ? Icons.list : Icons.folder_copy_outlined,
                    ),
                    tooltip: _isFolderView ? '리스트 보기' : '폴더 보기',
                    onPressed:
                        () => setState(() => _isFolderView = !_isFolderView),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                  tooltip: '새로고침',
                ),
              ],
            ),
            SliverPersistentHeader(
              /* ... TabBar ... */
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
              floating: false,
              pinned: true,
            ),
            SliverToBoxAdapter(child: _buildBannerAdWidget()), // 배너 광고 위치
          ];
        },
        // [✅ 수정] 메인 로딩 인디케이터 조건 확인
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                ) // 메인 로딩
                : TabBarView(
                  // 데이터 로드 완료 후 TabBarView 표시
                  controller: _tabController,
                  children: [
                    // 각 탭 내용은 FutureBuilder가 자체 로딩/에러 처리
                    _isFolderView ? _buildFolderView() : _buildSubscribedTab(),
                    _buildRecommendedTab(),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        /* ... FAB ... */
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
        onPressed: () {
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
                          _showCreateFolderDialog();
                        },
                      ),
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
                          _navigateToAddRss();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
          );
        },
        tooltip: '추가',
      ),
    );
  }

  // 폴더 보기 화면 빌더
  Widget _buildFolderView() {
    // [✅ 수정] FutureBuilder 로직 강화
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).primaryColor,
      child: FutureBuilder<List<RssFolder>>(
        future: folders, // initState 또는 _refreshData에서 할당된 Future 사용
        builder: (context, snapshot) {
          // 로딩 중: Future가 아직 완료되지 않았고, 이전에 로드된 데이터(foldersList)도 없을 때
          if (snapshot.connectionState == ConnectionState.waiting &&
              foldersList.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }
          // 에러 발생 시
          else if (snapshot.hasError) {
            // 새로고침 중 에러가 발생해도 이전 데이터(foldersList)라도 보여주도록 시도 (선택적)
            if (foldersList.isNotEmpty) {
              final unfoldered = _getUnfolderedChannels(foldersList);
              // 에러 메시지와 함께 이전 데이터 표시 (UI 개선 필요)
              // return Column(children: [ Text("오류 발생: ${snapshot.error}"), Expanded(...) ]);
              return RssScreenWidget.buildSimpleFolderSystem(
                folders: foldersList,
                unfolderedChannels: unfoldered,
                /* ... other params ... */ context: context,
                onDeleteFolder: _deleteFolder,
                onAddChannelToFolder: _addChannelToFolder,
                onRemoveChannelFromFolder: _removeChannelFromFolder,
                onChannelTap: _navigateToChannelDetail,
                onSubscribe: _subscribeToChannel,
                onUnsubscribe: _unsubscribeFromChannel,
                subscribingStatus: _subscribingStatus,
                onDragStatusChanged:
                    (isDragging) => setState(() => _isDragging = isDragging),
                onDraggingChannelChanged:
                    (channel) => setState(() => _draggingChannel = channel),
              );
            } else {
              // 이전 데이터도 없으면 에러 화면 표시
              return Center(child: Text('폴더 로딩 실패: ${snapshot.error}'));
            }
          }
          // 데이터 로드 성공 또는 새로고침 중 (이전 데이터 표시)
          else {
            // snapshot에 데이터가 있으면 최신 데이터 사용, 없으면 이전 데이터 사용
            final currentFolders =
                snapshot.hasData ? snapshot.data! : foldersList;
            // 구독 채널 목록은 _refreshData에서 업데이트된 _subscribedChannelsList 사용
            final unfolderedChannels = _getUnfolderedChannels(currentFolders);

            if (currentFolders.isEmpty && unfolderedChannels.isEmpty) {
              return RssScreenWidget.buildEmptyState(
                '구독 중인 채널이 없습니다.\nRSS 피드를 추가해보세요.',
                Icons.rss_feed,
                context,
              );
            }

            return RssScreenWidget.buildSimpleFolderSystem(
              folders: currentFolders,
              unfolderedChannels: unfolderedChannels,
              /* ... other params ... */
              context: context,
              onDeleteFolder: _deleteFolder,
              onAddChannelToFolder: _addChannelToFolder,
              onRemoveChannelFromFolder: _removeChannelFromFolder,
              onChannelTap: _navigateToChannelDetail,
              onSubscribe: _subscribeToChannel,
              onUnsubscribe: _unsubscribeFromChannel,
              subscribingStatus: _subscribingStatus,
              onDragStatusChanged:
                  (isDragging) => setState(() => _isDragging = isDragging),
              onDraggingChannelChanged:
                  (channel) => setState(() => _draggingChannel = channel),
            );
          }
        },
      ),
    );
  }

  // 구독 중 리스트 보기 화면 빌더
  Widget _buildSubscribedTab() {
    // [✅ 수정] FutureBuilder 로직 강화
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: FutureBuilder<List<RssChannel>>(
        future: subscribedChannels, // 상태 변수 사용
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              subscribedChannelsList.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            if (subscribedChannelsList.isNotEmpty) {
              // 이전 데이터 표시 (UI 개선 필요)
              // return Column(children: [ Text("오류 발생: ${snapshot.error}"), Expanded(...) ]);
              return ListView.separated(
                /* ... ListView ... */ padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                itemCount: subscribedChannelsList.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      thickness: 0.2,
                      color: theme.dividerColor.withOpacity(0.3),
                    ),
                itemBuilder: (context, index) {
                  final channel = subscribedChannelsList[index];
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
                      '데이터 로딩 실패',
                      style: TextStyle(
                        color: subscribeStyle.emptyTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
          } else {
            final currentChannels =
                snapshot.hasData ? snapshot.data! : subscribedChannelsList;
            if (currentChannels.isEmpty) {
              return RssScreenWidget.buildEmptyState(
                '구독 중인 RSS가 없습니다.\nRSS 피드를 추가해보세요.',
                Icons.rss_feed,
                context,
              );
            }
            return ListView.separated(
              /* ... ListView ... */ padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              itemCount: currentChannels.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    thickness: 0.2,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
              itemBuilder: (context, index) {
                final channel = currentChannels[index];
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
          }
        },
      ),
    );
  }

  // 추천 RSS 탭 화면 빌더
  Widget _buildRecommendedTab() {
    // [✅ 수정] FutureBuilder 로직 강화
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: FutureBuilder<List<RssChannel>>(
        future: recommendedChannels, // 상태 변수 사용
        builder: (context, snapshot) {
          // 추천 탭은 초기 로딩 중에도 다른 탭을 볼 수 있으므로, _isLoading과 무관하게 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터가 없는 초기 상태에서는 로딩 표시
            // (subscribedChannelsList는 다른 탭 데이터지만, 로딩 판단 기준으로 사용)
            if (subscribedChannelsList.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              );
            } else {
              // 새로고침 중에는 이전 데이터 (있다면) 보여주거나 빈 화면
              return const SizedBox.shrink(); // 혹은 이전 데이터 표시 로직 추가
            }
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
                    '추천 채널 로딩 실패',
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
            final recommended = snapshot.data!;
            return ListView.separated(
              /* ... ListView ... */ padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              itemCount: recommended.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    thickness: 0.2,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
              itemBuilder: (context, index) {
                final channel = recommended[index];
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
              '더 이상 추천할 채널이 없습니다.\n직접 RSS 피드를 추가해보세요.',
              Icons.check_circle_outline,
              context,
            );
          }
        },
      ),
    );
  }
} // End of _RssScreenState

// SliverAppBarDelegate (변경 없음)
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final ThemeData theme;

  SliverAppBarDelegate(this.tabBar, {required this.theme});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: theme.appBarTheme.backgroundColor ?? theme.canvasColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || theme != oldDelegate.theme;
  }
}
