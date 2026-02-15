import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/data/models/song.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'article_controller.dart';
import 'package:music_community_mvp/data/models/article_comment.dart';
import 'article_comment_drawer.dart';
import '../safety/report_dialog.dart';

import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  // Follow State
  final _isFollowing = false.obs;
  final _isFollowLoading = false.obs;

  // Local state for deep linking support
  late Article _currentArticle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 0. Ensure ArticleController exists FIRST
    if (!Get.isRegistered<ArticleController>()) {
      Get.put(ArticleController());
    }

    // 1. Initialize with passed article
    _currentArticle = widget.article;

    // 2. Check if deep link (Stub: ID exists but title is empty)
    if (_currentArticle.title.isEmpty && _currentArticle.id.isNotEmpty) {
      _isLoading = true; // Set directly before async call
      _quillController = QuillController.basic(); // Safe init
      _loadFullArticle();
    } else {
      _initQuill();
    }

    // Fetch comments (Always fetch for the ID)
    Get.find<ArticleController>().fetchComments(widget.article.id);

    // Check Follow Status
    _checkFollowStatus(); // Will access _currentArticle inside

    // Setup BGM
    // Ensure PlayerController exists
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController());
    }

    // Defer BGM play until we are sure we have the article data (especially song ID)
    if (_currentArticle.title.isNotEmpty) {
      _playBgm();
    }

    // Auto-open comments if requested
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
      print(
        "[ArticleDetailView] DidUpdateWidget: Switching from ${oldWidget.article.title} to ${widget.article.title}",
      );

      setState(() {
        _currentArticle = widget.article;
      });

      if (_currentArticle.title.isEmpty && _currentArticle.id.isNotEmpty) {
        _loadFullArticle();
      } else {
        _initQuill();
      }

      Get.find<ArticleController>().fetchComments(widget.article.id);
      _checkFollowStatus();

      // Force play BGM for the new article
      print("[ArticleDetailView] Triggering BGM for new article...");
      _playBgm();
    }
  }

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

  Future<void> _loadFullArticle() async {
    setState(() => _isLoading = true);
    final ctrl = Get.find<ArticleController>();
    final fullArticle = await ctrl.fetchArticleDetails(widget.article.id);

    if (fullArticle != null) {
      setState(() {
        _currentArticle = fullArticle;
        _isLoading = false;
        _initQuill(); // Init editor with new content
      });
      // Now play BGM and check follow
      _playBgm();
      _checkFollowStatus();
    } else {
      setState(() => _isLoading = false);
      Get.snackbar('错误', '文章加载失败或已被删除');
    }
  }

  Future<void> _playBgm() async {
    print(
      "[ArticleDetailView] _playBgm called. SongID: ${_currentArticle.bgmSongId}",
    );
    if (_currentArticle.bgmSongId != null) {
      final playerCtrl = Get.find<PlayerController>();

      // Wait for player to be fully initialized
      await playerCtrl.ready;

      final currentSongId = playerCtrl.currentSong.value?.id;
      print(
        "[ArticleDetailView] Player Current Song ID: $currentSongId vs Target: ${_currentArticle.bgmSongId}",
      );

      // If we already have the song loaded, just play it
      if (currentSongId == _currentArticle.bgmSongId) {
        print("[ArticleDetailView] Song matches. Requesting Play directly.");
        playerCtrl.playSong(playerCtrl.currentSong.value!);
        return;
      }

      // Otherwise fetch and play
      print("[ArticleDetailView] Song mismatch/empty. Fetching target song...");
      _fetchAndPlaySong(_currentArticle.bgmSongId!);
    } else {
      print("[ArticleDetailView] No BGM ID found for this article.");
    }
  }

  Future<void> _fetchAndPlaySong(String songId) async {
    try {
      print("ArticleDetailView: Fetching song details for $songId");

      final res = await Supabase.instance.client
          .from('songs')
          .select()
          .eq('id', songId)
          .single()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw "Fetch Song Timeout";
            },
          );

      final song = Song.fromMap(res);
      print("ArticleDetailView: Song fetched: ${song.title}");

      // Auto-play (maybe check if already playing same song?)
      final playerCtrl = Get.find<PlayerController>();
      if (playerCtrl.currentSong.value?.id != song.id) {
        playerCtrl.playSong(song);
      }
    } catch (e) {
      print("Failed to load BGM: $e");
      Get.snackbar('背景音乐错误', '加载失败: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    final profileCtrl = Get.put(ProfileController()); // Ensure IT exists
    // Don't check if it's me
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null && _currentArticle.userId != currentUserId) {
      _isFollowing.value = await profileCtrl.checkIsFollowing(
        _currentArticle.userId,
      );
    }
  }

  Widget _buildFollowButton() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    // Don't show button for self
    if (currentUserId == _currentArticle.userId) return const SizedBox();

    return Obx(() {
      if (_isFollowLoading.value) {
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      final isFollowing = _isFollowing.value;
      return GestureDetector(
        onTap: () async {
          _isFollowLoading.value = true;
          final profileCtrl = Get.find<ProfileController>();
          bool success;
          if (isFollowing) {
            success = await profileCtrl.unfollowUser(_currentArticle.userId);
          } else {
            success = await profileCtrl.followUser(_currentArticle.userId);
          }

          if (success) {
            _isFollowing.value = !isFollowing;
          }
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
                  fontWeight: FontWeight.bold,
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
    // Show loading if stub or fetch in progress
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Safety check: if load failed and title still empty
    if (_currentArticle.title.isEmpty) {
      return const Scaffold(body: Center(child: Text("加载失败")));
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: ArticleCommentDrawer(articleId: _currentArticle.id),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sliver App Bar with Cover
          SliverAppBar(
            expandedHeight: _currentArticle.coverUrl != null ? 300 : 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: _currentArticle.coverUrl == null
                  ? Text(
                      _currentArticle.title,
                      style: const TextStyle(color: Colors.black),
                    )
                  : null, // If cover exists, show title in body instead for better visuals
              background:
                  _currentArticle.coverUrl != null &&
                      _currentArticle.coverUrl!.isNotEmpty
                  ? Image.network(_currentArticle.coverUrl!, fit: BoxFit.cover)
                  : null,
            ),
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(
              color: _currentArticle.coverUrl != null
                  ? Colors.white
                  : Colors.black,
            ),
            actions: [
              // Only keep Delete for own articles
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
                            onPressed: () => Get.back(result: false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text(
                              '删除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final success = await Get.find<ArticleController>()
                          .deleteArticle(_currentArticle.id);
                      if (success) Get.back();
                    }
                  },
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Block
                  Text(
                    _currentArticle.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            _currentArticle.authorAvatar != null &&
                                _currentArticle.authorAvatar!.isNotEmpty
                            ? NetworkImage(_currentArticle.authorAvatar!)
                            : null,
                        child:
                            _currentArticle.authorAvatar == null ||
                                _currentArticle.authorAvatar!.isEmpty
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_currentArticle.authorName != null)
                                Text(
                                  _currentArticle.authorName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (_currentArticle.authorName == null)
                                const Text(
                                  '未知作者',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              _buildFollowButton(),
                            ],
                          ),
                          Text(
                            '发布于 ${timeago.format(_currentArticle.createdAt, locale: 'zh')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Music Player Card
                  const _MusicPlayerCard(), // Add control
                  // Summary Quote
                  if (_currentArticle.summary != null &&
                      _currentArticle.summary!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.blueAccent, width: 4),
                        ),
                      ),
                      child: Text(
                        _currentArticle.summary!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  const Divider(height: 1), // Divider before content
                  // Quill Content
                  QuillEditor(
                    controller: _quillController,
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                    config: QuillEditorConfig(
                      autoFocus: false,
                      expands: false,
                      padding: const EdgeInsets.only(
                        top: 24,
                      ), // Add padding here
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Comments Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    height: 1,
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                  ),
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
          ),

          // Comments Section (Root Comments Only)
          Obx(() {
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
                    child: Text(
                      '暂无评论，快来抢沙发吧！',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final comment = controller.currentComments[index];
                return _CommentPreviewItem(
                  comment: comment,
                  onTap: () {
                    controller.selectedThread.value = comment;
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                );
              }, childCount: controller.currentComments.length),
            );
          }),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 1. Comment Input (Opens Drawer for New Comment)
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (!await Get.find<ProfileController>().checkActionAllowed(
                      '发布评论',
                    )) {
                      return;
                    }
                    // Open drawer in "All Comments" mode (or generic input mode)
                    Get.find<ArticleController>().selectedThread.value = null;
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          '写下你的想法...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // 2. Action Buttons (Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomActionBtn(
                    icon: _currentArticle.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: _currentArticle.likesCount.toString(),
                    isActive: _currentArticle.isLiked,
                    activeColor: Colors.red,
                    onTap: () async {
                      // Controller handles auth check
                      await Get.find<ArticleController>().toggleLike(
                        _currentArticle,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16), // Gap between buttons
                  _BottomActionBtn(
                    icon: _currentArticle.isCollected
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: _currentArticle.collectionsCount.toString(),
                    isActive: _currentArticle.isCollected,
                    activeColor: Colors.orange,
                    onTap: () async {
                      // Controller handles auth check
                      await Get.find<ArticleController>().toggleCollection(
                        _currentArticle,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16), // Gap
                  // Share Button (Moved from Top)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black54),
                    onPressed: () => Get.snackbar("提示", "分享功能开发中"),
                  ),
                  const SizedBox(width: 8),

                  // Report Button (Only if not me)
                  if (_currentArticle.userId !=
                      Supabase.instance.client.auth.currentUser?.id)
                    IconButton(
                      icon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.black54,
                      ),
                      onPressed: () async {
                        if (!await Get.find<ProfileController>()
                            .checkActionAllowed('举报内容')) {
                          return;
                        }
                        Get.dialog(
                          ReportDialog(
                            targetType: 'article',
                            targetId: _currentArticle.id,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentPreviewItem extends StatelessWidget {
  final ArticleComment comment;
  final VoidCallback onTap;

  const _CommentPreviewItem({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        Get.bottomSheet(
          Container(
            color: Colors.white,
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.report_problem, color: Colors.red),
                  title: const Text(
                    '举报评论',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Get.back();
                    Get.dialog(
                      ReportDialog(targetType: 'comment', targetId: comment.id),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                  ? NetworkImage(comment.userAvatar!)
                  : null,
              child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName ?? '未知用户',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(comment.createdAt, locale: 'zh'),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                      const SizedBox(width: 16),
                      // Like Button
                      GestureDetector(
                        onTap: () =>
                            Get.find<ArticleController>().toggleCommentLike(
                              comment,
                            ), // Re-use controller logic
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 14,
                              color: comment.isLiked
                                  ? Colors.red
                                  : Colors.grey[400],
                            ),
                            if (comment.likesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: comment.isLiked
                                      ? Colors.red
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  // Reply Count Badge if replies exist
                  if (comment.totalRepliesCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${comment.totalRepliesCount} 条回复 >',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicPlayerCard extends StatelessWidget {
  const _MusicPlayerCard();

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();

    return Obx(() {
      final song = player.currentSong.value;
      if (song == null) return const SizedBox();

      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50], // Light background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 1. Cover / Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: song.coverUrl != null && song.coverUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(song.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: song.coverUrl == null || song.coverUrl!.isEmpty
                      ? const Icon(Icons.music_note, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                // 2. Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist ?? '未知艺术家',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. Play/Pause
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (player.isBuffering.value)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        onPressed: player.togglePlay,
                        icon: Icon(
                          player.isPlaying.value
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 40,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 4. Volume Slider
            Row(
              children: [
                const Icon(Icons.volume_down, size: 16, color: Colors.grey),
                SizedBox(
                  width:
                      120, // Limit width to make it look like a control, not a progress bar
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 2,
                      activeTrackColor: Colors.black54,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.black,
                      overlayShape: SliderComponentShape
                          .noOverlay, // Remove the large hover circle
                    ),
                    child: Slider(
                      value: player.volume.value,
                      onChanged: (v) => player.setVolume(v),
                    ),
                  ),
                ),
                const Icon(Icons.volume_up, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "${(player.volume.value * 100).toInt()}%",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _BottomActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _BottomActionBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.grey[600],
            size: 24,
          ),
          if (label != '0') ...[
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
