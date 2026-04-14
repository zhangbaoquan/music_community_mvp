/// 关注按钮 — 他人主页中的关注/取消关注按钮
///
/// 独立管理关注状态的 StatefulWidget，
/// 从 [UserProfileView] 拆出。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';

/// 关注按钮组件
///
/// [targetUserId] 目标用户 ID
/// 自动查询当前关注状态，支持点击切换。
class FollowButton extends StatefulWidget {
  final String targetUserId;
  const FollowButton({super.key, required this.targetUserId});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;
  final ProfileController _profileCtrl = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  /// 查询当前关注状态
  Future<void> _checkStatus() async {
    final status = await _profileCtrl.checkIsFollowing(widget.targetUserId);
    if (mounted) {
      setState(() {
        _isFollowing = status;
        _isLoading = false;
      });
    }
  }

  /// 切换关注/取消关注
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
