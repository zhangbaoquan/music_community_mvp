import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/content/article_controller.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'package:music_community_mvp/features/music/music_controller.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  const UserProfileView({super.key, required this.userId});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final ProfileController _profileCtrl = Get.find<ProfileController>();
  late final MusicController _musicCtrl;
  late final ArticleController _articleCtrl;

  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _isMe = widget.userId == Supabase.instance.client.auth.currentUser?.id;

    // Use unique tags to verify 'state pollution' issue
    // This creates a separate instance for this specific profile view
    _musicCtrl = Get.put(MusicController(), tag: 'user_${widget.userId}');
    _articleCtrl = Get.put(ArticleController(), tag: 'user_${widget.userId}');

    _loadProfile();
  }

  @override
  void dispose() {
    // Clean up the tagged controllers when we leave this page
    Get.delete<MusicController>(tag: 'user_${widget.userId}');
    Get.delete<ArticleController>(tag: 'user_${widget.userId}');
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _profileCtrl.getPublicProfile(widget.userId);
      // Fetch content using the TAGGED controllers
      _musicCtrl.fetchUserSongs(widget.userId);
      _articleCtrl.fetchUserArticles(widget.userId);

      // Record Visit (Phase 6.4)
      if (!_isMe) {
        _profileCtrl.recordVisit(widget.userId);
      }

      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          // _profileData remains null, triggers "User doesn't exist" or error UI
        });
      }
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
      appBar: AppBar(
        title: Text(
          _profileData!['username'] ?? 'Profile',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),

              // Stats
              _buildStatsRow(),
              const SizedBox(height: 40),

              // Music
              _buildMusicSection(),
              const SizedBox(height: 40),

              // Articles
              _buildArticlesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                (_profileData!['avatar_url'] != null &&
                    _profileData!['avatar_url'].isNotEmpty)
                ? NetworkImage(_profileData!['avatar_url'])
                : null,
            child:
                (_profileData!['avatar_url'] == null ||
                    _profileData!['avatar_url'].isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileData!['username'] ?? 'Unknown',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profileData!['signature'] ?? '这个人很懒，什么都没写...',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (!_isMe) ...[
            _FollowButton(targetUserId: widget.userId),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                Get.toNamed(
                  '/chat/${widget.userId}',
                  parameters: {
                    'name': _profileData!['username'] ?? 'Unknown',
                    'avatar': _profileData!['avatar_url'] ?? '',
                  },
                );
              },
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text("私信"),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      // decoration: BoxDecoration(
      //   border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[100]!)),
      // ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => Get.toNamed('/follows/${widget.userId}/following'),
            child: _statItem("关注", "${_profileData!['following_count'] ?? 0}"),
          ),
          InkWell(
            onTap: () => Get.toNamed('/follows/${widget.userId}/followers'),
            child: _statItem("粉丝", "${_profileData!['followers_count'] ?? 0}"),
          ),
          _statItem("日记", "${_profileData!['diary_count'] ?? 0}"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMusicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "原创音乐",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final songs = _musicCtrl
              .rxUserSongs; // Note: Ensure MusicController is isolated or handles multiple user streams.
          // Actually MusicController stores list in 'rxUserSongs'.
          // If we enter this page, we called fetchUserSongs(userId), so it should be correct for THIS user.
          // BUT, if we go back to ProfileView, we might need to refresh My Songs.
          // Ideally MusicController should separate 'currentUserSongs' and 'viewedUserSongs'.
          // For MVP, simplistic sharing is okay, but beware of state pollution.

          if (songs.isEmpty)
            return const Text("暂无发布", style: TextStyle(color: Colors.grey));

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: song.coverUrl != null
                            ? DecorationImage(
                                image: NetworkImage(song.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: song.coverUrl == null
                          ? const Icon(Icons.music_note, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            song.artist ?? '',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.blue,
                      ),
                      onPressed: () =>
                          Get.find<PlayerController>().playSong(song),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "发布文章",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final articles =
              _articleCtrl.userArticles; // Same scoping note as music
          if (articles.isEmpty)
            return const Text("暂无文章", style: TextStyle(color: Colors.grey));

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final article = articles[index];
              return InkWell(
                onTap: () =>
                    Get.toNamed('/article/${article.id}', arguments: article),
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
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.coverUrl != null &&
                          article.coverUrl!.isNotEmpty)
                        Container(
                          height: 120, // Slightly smaller than main list
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(article.coverUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (article.summary != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          article.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
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

class _FollowButton extends StatefulWidget {
  final String targetUserId;
  const _FollowButton({required this.targetUserId});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;
  final ProfileController _profileCtrl = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await _profileCtrl.checkIsFollowing(widget.targetUserId);
    if (mounted) {
      setState(() {
        _isFollowing = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle() async {
    setState(() => _isLoading = true);
    bool success;
    if (_isFollowing) {
      success = await _profileCtrl.unfollowUser(widget.targetUserId);
      if (success) _isFollowing = false;
    } else {
      success = await _profileCtrl.followUser(widget.targetUserId);
      if (success) _isFollowing = true;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return SizedBox(
      height: 36,
      child: _isFollowing
          ? OutlinedButton(
              onPressed: _toggle,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: const Text('已关注', style: TextStyle(color: Colors.grey)),
            )
          : ElevatedButton(
              onPressed: _toggle,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: const Text('关注 TA'),
            ),
    );
  }
}
