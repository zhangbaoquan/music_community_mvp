/// 文章内嵌音乐播放器卡片 — 在文章详情页中展示当前播放的 BGM
///
/// 显示歌曲封面、标题、艺术家，提供播放/暂停和音量控制。
/// 通过 [PlayerController] 获取播放状态，纯展示组件。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

/// 文章内嵌音乐播放器
///
/// 当有歌曲正在播放时显示播放器卡片，否则隐藏。
/// 包含：封面图、歌曲信息、播放/暂停按钮、音量滑块。
class ArticleMusicPlayerCard extends StatelessWidget {
  const ArticleMusicPlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();

    return Obx(() {
      final song = player.currentSong.value;
      // 没有歌曲时不显示
      if (song == null) return const SizedBox();

      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 1. 歌曲封面
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: song.coverUrl != null && song.coverUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(song.coverUrl!.toSecureUrl()),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: song.coverUrl == null || song.coverUrl!.isEmpty
                      ? const Icon(Icons.music_note, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                // 2. 歌曲信息
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
                // 3. 播放/暂停按钮
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 缓冲中显示 Loading 圈
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
            // 4. 音量控制滑块
            Row(
              children: [
                const Icon(Icons.volume_down, size: 16, color: Colors.grey),
                SizedBox(
                  width: 120,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 2,
                      activeTrackColor: Colors.black54,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.black,
                      overlayShape: SliderComponentShape.noOverlay,
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
