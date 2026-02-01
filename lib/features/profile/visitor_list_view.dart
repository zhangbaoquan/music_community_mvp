import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

class VisitorListView extends StatefulWidget {
  const VisitorListView({super.key});

  @override
  State<VisitorListView> createState() => _VisitorListViewState();
}

class _VisitorListViewState extends State<VisitorListView> {
  final ProfileController _profileCtrl = Get.find<ProfileController>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _visitors = [];

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    final list = await _profileCtrl.fetchVisitors();
    if (mounted) {
      setState(() {
        _visitors = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('最近访客', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _visitors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _visitors[index];
                final profile = item['profiles'] as Map<String, dynamic>;
                final userId = item['visitor_id'] as String;
                return _VisitorItem(
                  userId: userId,
                  username: profile['username'] ?? 'Unknown',
                  avatarUrl: profile['avatar_url'] ?? '',
                  signature: profile['signature'] ?? '',
                  visitedAt: DateTime.parse(item['visited_at']).toLocal(),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 64,
            color: Colors.grey[300],
          ), // Custom icon if available, or text
          const SizedBox(height: 16),
          Text('还没有人偷偷看过你哦', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _VisitorItem extends StatelessWidget {
  final String userId;
  final String username;
  final String avatarUrl;
  final String signature;
  final DateTime visitedAt;

  const _VisitorItem({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.signature,
    required this.visitedAt,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed('/profile/$userId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (signature.isNotEmpty)
                    Text(
                      signature,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    )
                  else
                    Text(
                      '来访于 ${timeago.format(visitedAt, locale: 'zh')}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(visitedAt, locale: 'zh'),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 8),
                _FollowButtonSmall(targetUserId: userId),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowButtonSmall extends StatefulWidget {
  final String targetUserId;
  const _FollowButtonSmall({required this.targetUserId});

  @override
  State<_FollowButtonSmall> createState() => _FollowButtonSmallState();
}

class _FollowButtonSmallState extends State<_FollowButtonSmall> {
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
    if (_isLoading) return const SizedBox();

    return SizedBox(
      height: 28,
      child: _isFollowing
          ? OutlinedButton(
              onPressed: _toggle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '已关注',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          : ElevatedButton(
              onPressed: _toggle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('关注', style: TextStyle(fontSize: 12)),
            ),
    );
  }
}
