import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/data/models/song.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'article_controller.dart';
import 'package:music_community_mvp/data/models/article_comment.dart';
import 'article_comment_drawer.dart';

import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ArticleDetailView extends StatefulWidget {
  final Article article;

  const ArticleDetailView({super.key, required this.article});

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

  @override
  void initState() {
    super.initState();
    // Load content
    try {
      if (widget.article.content != null) {
        _quillController = QuillController(
          document: Document.fromJson(widget.article.content),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } else {
        _quillController = QuillController.basic();
      }
    } catch (e) {
      _quillController = QuillController.basic();
    }
    // Fetch comments
    Get.find<ArticleController>().fetchComments(widget.article.id);

    // Check Follow Status
    _checkFollowStatus();

    // Setup BGM
    _playBgm();
  }

  void _playBgm() {
    print(
      "ArticleDetailView: _playBgm called. SongID: ${widget.article.bgmSongId}",
    );
    if (widget.article.bgmSongId != null) {
      Get.find<PlayerController>(); // Early init check
      // We might not have the full song details here if not joined.
      // We need to fetch the full song or ensure the previous join got it.
      _fetchAndPlaySong(widget.article.bgmSongId!);
    } else {
      print("ArticleDetailView: No BGM ID found.");
    }
  }

  Future<void> _fetchAndPlaySong(String songId) async {
    try {
      final res = await Supabase.instance.client
          .from('songs')
          .select()
          .eq('id', songId)
          .single();

      final song = Song.fromMap(res);

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
    if (currentUserId != null && widget.article.userId != currentUserId) {
      _isFollowing.value = await profileCtrl.checkIsFollowing(
        widget.article.userId,
      );
    }
  }

  Widget _buildFollowButton() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    // Don't show button for self
    if (currentUserId == widget.article.userId) return const SizedBox();

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
            success = await profileCtrl.unfollowUser(widget.article.userId);
          } else {
            success = await profileCtrl.followUser(widget.article.userId);
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
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: ArticleCommentDrawer(articleId: widget.article.id),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sliver App Bar with Cover
          SliverAppBar(
            expandedHeight: widget.article.coverUrl != null ? 300 : 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: widget.article.coverUrl == null
                  ? Text(
                      widget.article.title,
                      style: const TextStyle(color: Colors.black),
                    )
                  : null, // If cover exists, show title in body instead for better visuals
              background: widget.article.coverUrl != null
                  ? Image.network(widget.article.coverUrl!, fit: BoxFit.cover)
                  : null,
            ),
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(
              color: widget.article.coverUrl != null
                  ? Colors.white
                  : Colors.black,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Block
                  Text(
                    widget.article.title,
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
                        backgroundImage: widget.article.authorAvatar != null
                            ? NetworkImage(widget.article.authorAvatar!)
                            : null,
                        child: widget.article.authorAvatar == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.article.authorName ?? '未知作者',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildFollowButton(),
                            ],
                          ),
                          Text(
                            '发布于 ${timeago.format(widget.article.createdAt, locale: 'zh')}',
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
                  if (widget.article.summary != null &&
                      widget.article.summary!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.blueAccent, width: 4),
                        ),
                      ),
                      child: Text(
                        widget.article.summary!,
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
                    config: const QuillEditorConfig(
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.only(top: 24), // Add padding here
                    ),
                  ),

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
                  onTap: () {
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
                    icon: widget.article.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: widget.article.likesCount.toString(),
                    isActive: widget.article.isLiked,
                    activeColor: Colors.red,
                    onTap: () async {
                      await Get.find<ArticleController>().toggleLike(
                        widget.article,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16), // Gap between buttons
                  _BottomActionBtn(
                    icon: widget.article.isCollected
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: widget.article.collectionsCount.toString(),
                    isActive: widget.article.isCollected,
                    activeColor: Colors.orange,
                    onTap: () async {
                      await Get.find<ArticleController>().toggleCollection(
                        widget.article,
                      );
                      setState(() {});
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
              backgroundImage: comment.userAvatar != null
                  ? NetworkImage(comment.userAvatar!)
                  : null,
              child: comment.userAvatar == null
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
            const SizedBox(height: 8),
            // 4. Volume Slider
            Row(
              children: [
                const Icon(Icons.volume_down, size: 16, color: Colors.grey),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 2,
                      activeTrackColor: Colors.black54,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.black,
                    ),
                    child: Slider(
                      value: player.volume.value,
                      onChanged: (v) => player.setVolume(v),
                    ),
                  ),
                ),
                const Icon(Icons.volume_up, size: 16, color: Colors.grey),
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
