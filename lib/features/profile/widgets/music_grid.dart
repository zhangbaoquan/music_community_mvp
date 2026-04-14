/// 音乐网格列表 — 展示用户的音乐作品列表
///
/// 从 [ProfileView] 和 [UserProfileView] 共用的音乐列表组件。
/// 支持响应式网格布局（1-4列自适应），包含播放和删除操作。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/song.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

/// 音乐网格列表
///
/// [songs] 歌曲列表（响应式 RxList）
/// [showDeleteButton] 是否显示删除按钮（仅在个人中心的"我的音乐"中显示）
/// [onDelete] 删除回调
class MusicGrid extends StatelessWidget {
  final List<Song> songs;
  final bool showDeleteButton;
  final Future<void> Function(Song song)? onDelete;

  const MusicGrid({
    super.key,
    required this.songs,
    this.showDeleteButton = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 响应式列数
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 3.0,
          ),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return _buildSongCard(song);
          },
        );
      },
    );
  }

  /// 构建单个歌曲卡片
  Widget _buildSongCard(Song song) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Get.find<PlayerController>().playSong(song),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 封面图
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: song.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(song.coverUrl!.toSecureUrl()),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: song.coverUrl == null
                      ? const Icon(Icons.music_note, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? "Unknown",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // 播放按钮
                IconButton(
                  onPressed: () => Get.find<PlayerController>().playSong(song),
                  icon: const Icon(Icons.play_circle_fill, color: Colors.blue),
                  tooltip: "播放",
                ),
                // 删除按钮（可选）
                if (showDeleteButton && onDelete != null)
                  IconButton(
                    onPressed: () => onDelete!(song),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[300],
                      size: 20,
                    ),
                    tooltip: "删除",
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 音乐空状态占位组件
///
/// [message] 空状态提示文字
/// [actionLabel] 操作按钮文字（可选）
/// [onAction] 操作按钮回调（可选）
class MusicEmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MusicEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.music_note_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
