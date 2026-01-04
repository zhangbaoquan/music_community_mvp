import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'player_controller.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PlayerController());

    return Container(
      padding: const EdgeInsets.all(20),
      // Minimalist Card Design
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Album Art / Mood Placeholder
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=400&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title & Artist
          Obx(() => Column(
            children: [
              Text(
                controller.currentTitle.value.isEmpty ? "Loading..." : controller.currentTitle.value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                controller.currentArtist.value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )),
          
          const SizedBox(height: 32),
          
          // Progress Bar
          Obx(() {
            final position = controller.currentPosition.value.inSeconds.toDouble();
            final total = controller.totalDuration.value.inSeconds.toDouble();
            // Prevent division by zero or invalid range
            final max = total > 0 ? total : 1.0;
            final value = position > max ? max : position;
            
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: const Color(0xFF1A1A1A),
                inactiveTrackColor: Colors.grey[200],
                thumbColor: const Color(0xFF1A1A1A),
                overlayColor: const Color(0xFF1A1A1A).withOpacity(0.1),
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
          
          const SizedBox(height: 8),
          
          // Time Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(controller.currentPosition.value),
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: Colors.grey[400]),
                ),
                Text(
                  _formatDuration(controller.totalDuration.value),
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            )),
          ),
          
          const SizedBox(height: 32),
          
          // Controls
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous_rounded, size: 32, color: Colors.grey)),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: controller.togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next_rounded, size: 32, color: Colors.grey)),
            ],
          )),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
