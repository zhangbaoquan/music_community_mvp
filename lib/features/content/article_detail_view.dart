/// 文章详情页 — 展示文章内容、作者信息、评论区
///
/// UI 层只负责渲染，业务逻辑通过 [ArticleController] 处理。
/// 不直接调用 Supabase，不管理业务状态。
///
/// 子组件拆分到 widgets/ 目录：
/// - [ArticleBodySection]：文章正文区域
/// - [ArticleBottomBar]：底部操作栏
/// - [CommentPreviewItem]：评论预览卡片
/// - [ArticleMusicPlayerCard]：BGM 播放器
/// - [BottomActionBtn]：底栏操作按钮
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/data/models/song.dart';
import 'package:music_community_mvp/data/services/article_service.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'article_controller.dart';
import 'article_comment_drawer.dart';
import '../profile/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/comment_preview_item.dart';
import 'widgets/article_body_section.dart';
import 'widgets/article_bottom_bar.dart';
import '../../core/router/app_router.dart';

class ArticleDetailView extends StatefulWidget {
  final Article article;
  final bool autoOpenComments;

  const ArticleDetailView({
    super.key,
    required this.article,
    this.autoOpenComments = false,
  });

  @override
  State<ArticleDetailView> createState() => _ArticleDetailViewState();
}

class _ArticleDetailViewState extends State<ArticleDetailView> {
  late QuillController _quillController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 关注状态
  final _isFollowing = false.obs;
  final _isFollowLoading = false.obs;

  /// 当前展示的文章数据
  late Article _currentArticle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 确保 Controller 已注册
    if (!Get.isRegistered<ArticleController>()) {
      Get.put(ArticleController());
    }

    _currentArticle = widget.article;

    // 深链接场景：仅有 ID 无内容
    if (_currentArticle.title.isEmpty && _currentArticle.id.isNotEmpty) {
      _isLoading = true;
      _quillController = QuillController.basic();
      _loadFullArticle();
    } else {
      _initQuill();
    }

    // 加载评论 + 关注状态
    Get.find<ArticleController>().fetchComments(widget.article.id);
    _checkFollowStatus();

    // 初始化播放器并播放 BGM
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController());
    }
    if (_currentArticle.title.isNotEmpty) _playBgm();

    // 从通知进入时自动打开评论抽屉
    if (widget.autoOpenComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openEndDrawer();
      });
    }
  }

  @override
  void didUpdateWidget(ArticleDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.id != widget.article.id) {
      setState(() => _currentArticle = widget.article);
      if (_currentArticle.title.isEmpty && _currentArticle.id.isNotEmpty) {
        _loadFullArticle();
      } else {
        _initQuill();
      }
      Get.find<ArticleController>().fetchComments(widget.article.id);
      _checkFollowStatus();
      _playBgm();
    }
  }

  /// 初始化 Quill 编辑器（只读模式）
  void _initQuill() {
    try {
      if (_currentArticle.content != null) {
        _quillController = QuillController(
          document: Document.fromJson(_currentArticle.content),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } else {
        _quillController = QuillController.basic();
      }
    } catch (e) {
      _quillController = QuillController.basic();
    }
  }

  /// 加载完整文章数据（深链接场景）
  Future<void> _loadFullArticle() async {
    setState(() => _isLoading = true);
    final fullArticle = await Get.find<ArticleController>()
        .fetchArticleDetails(widget.article.id);
    if (fullArticle != null) {
      setState(() {
        _currentArticle = fullArticle;
        _isLoading = false;
        _initQuill();
      });
      _playBgm();
      _checkFollowStatus();
    } else {
      setState(() => _isLoading = false);
      Get.snackbar('错误', '文章加载失败或已被删除');
    }
  }

  /// 播放 BGM（通过 Service 获取歌曲数据）
  Future<void> _playBgm() async {
    if (_currentArticle.bgmSongId == null) return;
    final playerCtrl = Get.find<PlayerController>();
    await playerCtrl.ready;

    // 已在播放同一首歌则直接恢复
    if (playerCtrl.currentSong.value?.id == _currentArticle.bgmSongId) {
      playerCtrl.playSong(playerCtrl.currentSong.value!);
      return;
    }

    try {
      final songData =
          await ArticleService().fetchSongById(_currentArticle.bgmSongId!);
      final song = Song.fromMap(songData);
      if (playerCtrl.currentSong.value?.id != song.id) {
        playerCtrl.playSong(song);
      }
    } catch (e) {
      Get.snackbar('背景音乐错误', '加载失败: $e');
    }
  }

  /// 检查关注状态
  Future<void> _checkFollowStatus() async {
    final profileCtrl = Get.put(ProfileController());
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null && _currentArticle.userId != currentUserId) {
      _isFollowing.value = await profileCtrl.checkIsFollowing(
        _currentArticle.userId,
      );
    }
  }

  /// 构建关注/取消关注按钮
  Widget _buildFollowButton() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == _currentArticle.userId) return const SizedBox();

    return Obx(() {
      if (_isFollowLoading.value) {
        return const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      final isFollowing = _isFollowing.value;
      return GestureDetector(
        onTap: () async {
          _isFollowLoading.value = true;
          final profileCtrl = Get.find<ProfileController>();
          final success = isFollowing
              ? await profileCtrl.unfollowUser(_currentArticle.userId)
              : await profileCtrl.followUser(_currentArticle.userId);
          if (success) _isFollowing.value = !isFollowing;
          _isFollowLoading.value = false;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.grey[200] : Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isFollowing ? Icons.check : Icons.add,
                size: 10,
                color: isFollowing ? Colors.black54 : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                isFollowing ? '已关注' : '关注',
                style: TextStyle(
                  fontSize: 10,
                  color: isFollowing ? Colors.black54 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _quillController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_currentArticle.title.isEmpty) {
      return const Scaffold(body: Center(child: Text("加载失败")));
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: ArticleCommentDrawer(articleId: _currentArticle.id),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: ArticleBodySection(
              article: _currentArticle,
              quillController: _quillController,
              followButton: _buildFollowButton(),
            ),
          ),
          _buildCommentsHeader(),
          _buildCommentsList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      bottomNavigationBar: ArticleBottomBar(
        article: _currentArticle,
        scaffoldKey: _scaffoldKey,
        onStateChanged: () => setState(() {}),
      ),
    );
  }

  /// 顶部封面图 AppBar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _currentArticle.coverUrl != null ? 300 : 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: _currentArticle.coverUrl == null
            ? Text(_currentArticle.title,
                style: const TextStyle(color: Colors.black))
            : null,
        background: _currentArticle.coverUrl != null &&
                _currentArticle.coverUrl!.isNotEmpty
            ? Image.network(
                _currentArticle.coverUrl!,
                fit: BoxFit.cover,
              )
            : null,
      ),
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(
        color: _currentArticle.coverUrl != null ? Colors.white : Colors.black,
      ),
      actions: [
        if (_currentArticle.userId ==
            Supabase.instance.client.auth.currentUser?.id)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('删除后无法恢复，确定要删除吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => appRouter.pop(false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => appRouter.pop(true),
                      child: const Text('删除',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final success = await Get.find<ArticleController>()
                    .deleteArticle(_currentArticle.id);
                if (success) appRouter.pop();
              }
            },
          ),
      ],
    );
  }

  /// 评论区标题
  Widget _buildCommentsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 24),
            Obx(() {
              final count =
                  Get.find<ArticleController>().totalCommentsCount.value;
              return Text(
                '评论 ($count)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 评论列表
  Widget _buildCommentsList() {
    return Obx(() {
      final controller = Get.find<ArticleController>();
      if (controller.isCommentsLoading.value) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      if (controller.currentComments.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('暂无评论，快来抢沙发吧！',
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        );
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final comment = controller.currentComments[index];
          return CommentPreviewItem(
            comment: comment,
            onTap: () {
              controller.selectedThread.value = comment;
              _scaffoldKey.currentState?.openEndDrawer();
            },
          );
        }, childCount: controller.currentComments.length),
      );
    });
  }
}
