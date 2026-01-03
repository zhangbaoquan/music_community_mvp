import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'player_controller.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing controller
    final controller = Get.find<PlayerController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 80,
      color: Colors.white,
      child: Row(
        children: [
          // 1. Song Info (Left)
          _buildSongInfo(controller),

          const Spacer(flex: 1),

          // 2. Player Controls (Center)
          _buildControls(controller),

          const Spacer(flex: 1),

          // 3. Extra Controls / Volume (Right)
          _buildExtraControls(controller),
        ],
      ),
    );
  }

  Widget _buildSongInfo(PlayerController controller) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          // Mini Album Art
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
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
                        ? "No Song"
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
                        ? "Unknown"
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
                  child: Icon(
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
          Icon(Icons.playlist_play_rounded, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Icon(Icons.volume_up_rounded, color: Colors.grey[600]),
        ],
      ),
    );
  }
}
