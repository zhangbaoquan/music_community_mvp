import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
import '../music/music_controller.dart';
import '../../data/models/song.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

class ManageMusicView extends StatelessWidget {
  const ManageMusicView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is loaded
    final musicController = Get.put(MusicController());
    // Trigger fetch if empty (or always refresh for admin?)
    if (musicController.rxSongs.isEmpty) {
      musicController.fetchSongs();
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "音乐管理 (最新100首)",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => musicController.fetchSongs(),
                icon: const Icon(Icons.refresh),
                tooltip: "刷新列表",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (musicController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final songs = musicController.rxSongs;
              if (songs.isEmpty) {
                return const Center(child: Text("暂无音乐"));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return _buildMobileList(musicController, songs);
                  } else {
                    return _buildDesktopTable(musicController, songs);
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(MusicController controller, List<Song> songs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(Get.context!).size.width > 800
              ? MediaQuery.of(Get.context!).size.width - 250
              : 800,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columns: const [
              DataColumn(label: Text("封面")),
              DataColumn(label: Text("标题")),
              DataColumn(label: Text("艺术家")),
              DataColumn(label: Text("上传者")),
              DataColumn(label: Text("心情标签")),
              DataColumn(label: Text("操作")),
            ],
            rows: songs.map((song) => _buildDataRow(controller, song)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(MusicController controller, List<Song> songs) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
                image: song.coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(song.coverUrl!.toSecureUrl()),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: song.coverUrl == null
                  ? const Icon(Icons.music_note)
                  : null,
            ),
            title: Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${song.artist ?? '未知'} • ${song.uploaderName ?? '未知'}"),
                if (song.moodTags != null && song.moodTags!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Wrap(
                      spacing: 4,
                      children: song.moodTags!
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(controller, song);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(MusicController controller, Song song) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
              image: song.coverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(song.coverUrl!.toSecureUrl()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        ),
        DataCell(Text(song.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(song.artist ?? "-", overflow: TextOverflow.ellipsis)),
        DataCell(
          // Uploader Logic
          Row(
            children: [
              if (song.uploaderAvatar != null)
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(song.uploaderAvatar!.toSecureUrl()),
                    ),
                  ),
                ),
              Text(
                song.uploaderName ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DataCell(Text(song.moodTags?.join(", ") ?? "-")),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            tooltip: "删除",
            onPressed: () => _confirmDelete(controller, song),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(MusicController controller, Song song) {
    CommonDialog.show(
      title: "确认删除",
      content: "确定要删除歌曲 '${song.title}' 吗？",
      confirmText: "删除",
      cancelText: "取消",
      isDestructive: true,
      onConfirm: () async {
        Get.back(); // close dialog
        await controller.deleteSong(song.id);
      },
    );
  }
}
