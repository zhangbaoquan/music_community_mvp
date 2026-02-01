import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../music/music_controller.dart';

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

              // Use a DataTable for better density on desktop
              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("封面")),
                      DataColumn(label: Text("标题")),
                      DataColumn(label: Text("艺术家")),
                      DataColumn(label: Text("上传者")), // Added Uploader column
                      DataColumn(label: Text("心情标签")),
                      DataColumn(label: Text("操作")),
                    ],
                    rows: songs.map((song) {
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
                                        image: NetworkImage(song.coverUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(song.title, overflow: TextOverflow.ellipsis),
                          ),
                          DataCell(
                            Text(
                              song.artist ?? "-",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                                        image: NetworkImage(
                                          song.uploaderAvatar!,
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  song.uploaderName ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(song.moodTags?.join(", ") ?? "-")),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: "删除",
                              onPressed: () {
                                Get.defaultDialog(
                                  title: "确认删除",
                                  middleText: "确定要删除歌曲 '${song.title}' 吗？",
                                  textConfirm: "删除",
                                  textCancel: "取消",
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.red,
                                  onConfirm: () async {
                                    Get.back(); // close dialog
                                    await musicController.deleteSong(song.id);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
