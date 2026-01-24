import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/music/music_controller.dart';
import 'package:music_community_mvp/features/player/player_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MusicPickerSheet extends StatefulWidget {
  final Function(String songId, String songTitle) onSelected;

  const MusicPickerSheet({super.key, required this.onSelected});

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final MusicController _musicCtrl = Get.put(MusicController());
  final PlayerController _playerCtrl = Get.find(); // For previewing

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Fetch system/all songs for 'Moods' tab?
    // For MVP, let's just fetch "All Public Songs" for tab 1, and "My Songs" for tab 2.
    // Or just "Discovery" vs "Mine".
    _musicCtrl.fetchSongs(); // Discovery

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _musicCtrl.fetchUserSongs(userId);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabCtrl,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(text: "发现音乐"),
              Tab(text: "我的音乐"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSongList(isMySongs: false),
                _buildSongList(isMySongs: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList({required bool isMySongs}) {
    return Obx(() {
      final songs = isMySongs ? _musicCtrl.rxUserSongs : _musicCtrl.rxSongs;
      if (songs.isEmpty) {
        return Center(child: Text(isMySongs ? "暂无上传音乐" : "加载中或暂无音乐"));
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: song.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(song.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: song.coverUrl == null
                      ? const Icon(Icons.music_note)
                      : null,
                ),
                // Tiny play button to preview
                IconButton(
                  icon: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                  ),
                  onPressed: () => _playerCtrl.playSong(song),
                ),
              ],
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(song.artist ?? 'Unknown', maxLines: 1),
            trailing: ElevatedButton(
              onPressed: () {
                widget.onSelected(song.id, song.title);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text("选择"),
            ),
          );
        },
      );
    });
  }
}
