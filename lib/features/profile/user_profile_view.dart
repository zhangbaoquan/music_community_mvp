/// 他人主页 — 展示指定用户的公开信息、音乐和文章
///
/// 通过 tagged Controller 隔离数据，避免与全局状态污染。
/// 子组件已拆分到 widgets/ 目录：
/// - [FollowButton]：关注/取消关注按钮
/// - [MusicGrid]：音乐网格列表
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/content/article_controller.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/features/music/music_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../safety/report_dialog.dart';
import 'widgets/follow_button.dart';
import 'widgets/music_grid.dart';
import '../../core/router/app_router.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  const UserProfileView({super.key, required this.userId});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final ProfileController _profileCtrl = Get.find<ProfileController>();

  /// 使用 tagged Controller 隔离数据，避免与全局状态冲突
  late final MusicController _musicCtrl;
  late final ArticleController _articleCtrl;

  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _isMe = widget.userId == Supabase.instance.client.auth.currentUser?.id;
    _musicCtrl = Get.put(MusicController(), tag: 'user_${widget.userId}');
    _articleCtrl = Get.put(ArticleController(), tag: 'user_${widget.userId}');
    _loadProfile();
  }

  @override
  void dispose() {
    // 清理 tagged Controller
    Get.delete<MusicController>(tag: 'user_${widget.userId}');
    Get.delete<ArticleController>(tag: 'user_${widget.userId}');
    super.dispose();
  }

  /// 加载用户资料和内容
  Future<void> _loadProfile() async {
    try {
      final data = await _profileCtrl.getPublicProfile(widget.userId);
      _musicCtrl.fetchUserSongs(widget.userId);
      _articleCtrl.fetchUserArticles(widget.userId);

      // 记录访客（不记录自己）
      if (!_isMe) _profileCtrl.recordVisit(widget.userId);

      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_profileData == null) {
      return const Scaffold(body: Center(child: Text('用户不存在')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatsRow(),
              const SizedBox(height: 40),
              _buildMusicSection(),
              const SizedBox(height: 40),
              _buildArticlesSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部导航栏（含举报菜单）
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _profileData!['username'] ?? 'Profile',
        style: const TextStyle(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        if (!_isMe)
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () async {
              if (!await _profileCtrl.checkActionAllowed('举报用户')) return;
              Get.bottomSheet(
                Container(
                  color: Colors.white,
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.report_problem,
                            color: Colors.red),
                        title: const Text('举报用户',
                            style: TextStyle(color: Colors.red)),
                        onTap: () {
                          appRouter.pop();
                          Get.dialog(ReportDialog(
                              targetType: 'user', targetId: widget.userId));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// 用户信息头部（响应式布局）
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUserInfo()),
                ]),
                const SizedBox(height: 16),
                if (!_isMe)
                  Row(children: [
                    Expanded(child: FollowButton(targetUserId: widget.userId)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMessageButton()),
                  ]),
              ],
            );
          } else {
            return Row(children: [
              _buildAvatar(),
              const SizedBox(width: 24),
              Expanded(child: _buildUserInfo()),
              if (!_isMe) ...[
                FollowButton(targetUserId: widget.userId),
                const SizedBox(width: 12),
                _buildMessageButton(),
              ],
            ]);
          }
        },
      ),
    );
  }

  /// 头像
  Widget _buildAvatar() {
    final avatarUrl = _profileData!['avatar_url'];
    return CircleAvatar(
      radius: 40,
      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? NetworkImage((avatarUrl as String).toSecureUrl())
          : null,
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? const Icon(Icons.person, size: 40, color: Colors.grey)
          : null,
    );
  }

  /// 用户名 + 签名 + 封禁状态
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _profileData!['username'] ?? 'Unknown',
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _profileData!['signature'] ?? '这个人很懒，什么都没写...',
          style: GoogleFonts.outfit(
              color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
        if (_profileData!['status'] == 'banned') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: const Text("违规封禁中",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  /// 私信按钮
  Widget _buildMessageButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        if (!await _profileCtrl.checkActionAllowed('发送私信')) return;
        Get.toNamed('/chat/${widget.userId}', parameters: {
          'name': _profileData!['username'] ?? 'Unknown',
          'avatar': _profileData!['avatar_url'] ?? '',
        });
      },
      icon: const Icon(Icons.mail_outline, size: 18),
      label: const Text("私信"),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// 统计行（关注/粉丝/日记）
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => appRouter.push('/follows/${widget.userId}/following'),
            child:
                _statItem("关注", "${_profileData!['following_count'] ?? 0}"),
          ),
          InkWell(
            onTap: () => appRouter.push('/follows/${widget.userId}/followers'),
            child:
                _statItem("粉丝", "${_profileData!['followers_count'] ?? 0}"),
          ),
          _statItem("日记", "${_profileData!['diary_count'] ?? 0}"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ]);
  }

  /// 音乐区域（使用共享 MusicGrid 组件）
  Widget _buildMusicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("我的音乐",
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Obx(() {
          final songs = _musicCtrl.rxUserSongs;
          if (songs.isEmpty) {
            return const MusicEmptyState(message: "还没有发布过原创歌曲");
          }
          return MusicGrid(songs: songs);
        }),
      ],
    );
  }

  /// 文章区域
  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("发布文章",
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Obx(() {
          final articles = _articleCtrl.userArticles;
          if (articles.isEmpty) {
            return const Text("暂无文章", style: TextStyle(color: Colors.grey));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final article = articles[index];
              return InkWell(
                onTap: () => appRouter.push('/article/${article.id}', extra: article),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.coverUrl != null &&
                          article.coverUrl!.isNotEmpty)
                        Container(
                          height: 120,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                  article.coverUrl!.toSecureUrl()),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Text(article.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (article.summary != null) ...[
                        const SizedBox(height: 8),
                        Text(article.summary!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        "发布于 ${article.createdAt.toLocal().toString().split(' ')[0]}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
