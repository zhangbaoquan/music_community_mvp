import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowListView extends StatefulWidget {
  final String userId;
  final String title;
  final String type; // 'followers' or 'following'

  const FollowListView({
    super.key,
    required this.userId,
    required this.title,
    required this.type,
  });

  @override
  State<FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<FollowListView> {
  final ProfileController _profileCtrl = Get.find<ProfileController>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final String _currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    if (widget.type == 'followers') {
      final raw = await _profileCtrl.fetchFollowersList(widget.userId);
      // Transform to flat structure
      _users = raw.map((e) {
        final profile = e['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'user_id': e['follower_id'],
          'username': profile['username'] ?? 'User',
          'avatar_url': profile['avatar_url'] ?? '',
          'signature': profile['signature'] ?? '',
        };
      }).toList();
    } else {
      final raw = await _profileCtrl.fetchFollowingList(widget.userId);
      _users = raw.map((e) {
        final profile = e['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'user_id': e['following_id'],
          'username': profile['username'] ?? 'User',
          'avatar_url': profile['avatar_url'] ?? '',
          'signature': profile['signature'] ?? '',
        };
      }).toList();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? Center(
              child: Text('暂无列表数据', style: TextStyle(color: Colors.grey[400])),
            )
          : ListView.separated(
              itemCount: _users.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isMe = user['user_id'] == _currentUserId;

                return InkWell(
                  onTap: () {
                    if (isMe) {
                      // Navigate to my own profile (tab switch) or just back
                      Get.back(); // Simplest for now
                    } else {
                      Get.toNamed('/profile/${user['user_id']}');
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            (user['avatar_url'] != null &&
                                user['avatar_url'].isNotEmpty)
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child:
                            (user['avatar_url'] == null ||
                                user['avatar_url'].isEmpty)
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['username'],
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (user['signature'] != null &&
                                user['signature'].isNotEmpty)
                              Text(
                                user['signature'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isMe) _FollowButton(targetUserId: user['user_id']),
                    ],
                  ),
                );
              },
            ),
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
      height: 32,
      child: _isFollowing
          ? OutlinedButton(
              onPressed: _toggle,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: const Text(
                '已关注',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          : ElevatedButton(
              onPressed: _toggle,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: const Text('关注', style: TextStyle(fontSize: 12)),
            ),
    );
  }
}
