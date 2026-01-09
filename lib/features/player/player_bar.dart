import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/social/comments_sheet.dart';
import 'player_controller.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          height: 80,
          color: Colors.white,
          child: isMobile
              ? _buildMobileLayout(controller)
              : _buildDesktopLayout(controller),
        );
      },
    );
  }

  Widget _buildMobileLayout(PlayerController controller) {
    return Row(
      children: [
        // Song Info (Expanded)
        Expanded(child: _buildSongInfo(controller, isMobile: true)),

        // Controls (Compact)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: controller.togglePlay,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Obx(() {
                  if (controller.isBuffering.value) {
                    return const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    );
                  }
                  return Icon(
                    controller.isPlaying.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  );
                }),
              ),
            ),
            const SizedBox(width: 16),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showComments(),
              icon: const Icon(Icons.mode_comment_outlined),
              iconSize: 24,
              color: const Color(0xFF1A1A1A),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 28,
              color: const Color(0xFF1A1A1A),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(PlayerController controller) {
    return Row(
      children: [
        _buildSongInfo(controller),
        const Spacer(flex: 1),
        _buildControls(controller),
        const Spacer(flex: 1),
        _buildExtraControls(controller),
      ],
    );
  }

  Widget _buildSongInfo(PlayerController controller, {bool isMobile = false}) {
    return SizedBox(
      width: isMobile ? null : 200, // No fixed width on mobile
      child: Row(
        children: [
          // Mini Album Art
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.grey[800], // Dark placeholder background
              borderRadius: BorderRadius.circular(8),
              // Remove NetworkImage to avoid Unsplash blocking
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          // Text Info
          Expanded(
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.currentTitle.value.isEmpty
                        ? "暂无音乐"
                        : controller.currentTitle.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    controller.currentArtist.value.isEmpty
                        ? "未知歌手"
                        : controller.currentArtist.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Buttons
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 24,
                color: const Color(0xFF1A1A1A),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: controller.togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: controller.isBuffering.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          controller.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 24,
                color: const Color(0xFF1A1A1A),
              ),
            ],
          ),
        ),

        // Mini Progress Bar
        SizedBox(
          width: 400,
          height: 16,
          child: Obx(() {
            final position = controller.currentPosition.value.inSeconds
                .toDouble();
            final total = controller.totalDuration.value.inSeconds.toDouble();
            final max = total > 0 ? total : 1.0;
            final value = position > max ? max : position;

            return SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: const Color(0xFF1A1A1A),
                inactiveTrackColor: Colors.grey[200],
                thumbColor: const Color(0xFF1A1A1A),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: max,
                onChanged: (val) {
                  controller.seek(Duration(seconds: val.toInt()));
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildExtraControls(PlayerController controller) {
    return SizedBox(
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => _showComments(), // Use helper
            icon: const Icon(Icons.mode_comment_outlined),
            color: Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Icon(Icons.playlist_play_rounded, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Icon(Icons.volume_up_rounded, color: Colors.grey[600]),
        ],
      ),
    );
  }

  void _showComments() {
    if (Get.width >= 600) {
      // Desktop: Side Drawer
      Get.generalDialog(
        barrierDismissible: true,
        barrierLabel: "Comments",
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, anim1, anim2) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 400, // Fixed width for drawer
                height: double.infinity,
                child: const CommentsSheet(),
              ),
            ),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
            child: child,
          );
        },
      );
    } else {
      // Mobile: Bottom Sheet
      Get.bottomSheet(
        const CommentsSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }
}
