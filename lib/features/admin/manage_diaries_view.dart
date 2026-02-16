import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ManageDiariesView extends StatefulWidget {
  const ManageDiariesView({super.key});

  @override
  State<ManageDiariesView> createState() => _ManageDiariesViewState();
}

class _ManageDiariesViewState extends State<ManageDiariesView> {
  final _supabase = Supabase.instance.client;
  final RxList<Map<String, dynamic>> diaries = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    fetchDiaries();
  }

  Future<void> fetchDiaries() async {
    try {
      isLoading.value = true;
      // Fetch latest 100 diaries with author info
      final response = await _supabase
          .from('mood_diaries')
          .select('*, profiles(username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(100);

      diaries.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load diaries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    try {
      await _supabase.from('mood_diaries').delete().eq('id', diaryId);
      diaries.removeWhere((d) => d['id'] == diaryId);
      Get.snackbar('Success', 'Diary deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete diary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "日记管理 (最新100条)",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: fetchDiaries,
                icon: const Icon(Icons.refresh),
                tooltip: "刷新列表",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (diaries.isEmpty) {
                return const Center(child: Text("暂无日记"));
              }

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text("用户")),
                      DataColumn(label: Text("心情")),
                      DataColumn(label: Text("内容")),
                      DataColumn(label: Text("发布时间")),
                      DataColumn(label: Text("操作")),
                    ],
                    rows: diaries.map((diary) {
                      final profile =
                          diary['profiles'] as Map<String, dynamic>?;
                      final username = profile?['username'] ?? "Unknown";
                      final avatarUrl = profile?['avatar_url'];
                      final content = diary['content'] as String? ?? "";
                      final mood = diary['mood'] as String? ?? "-";
                      // Assuming 'created_at' is standard
                      final time =
                          DateTime.tryParse(diary['created_at'].toString()) ??
                          DateTime.now();

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                if (avatarUrl != null)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(mood)),
                          DataCell(
                            SizedBox(
                              width: 300,
                              child: Text(
                                content,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(Text(timeago.format(time, locale: 'zh'))),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: "删除",
                              onPressed: () {
                                CommonDialog.show(
                                  title: "确认删除",
                                  content: "确定要删除这条日记吗？",
                                  confirmText: "删除",
                                  cancelText: "取消",
                                  isDestructive: true,
                                  onConfirm: () async {
                                    Get.back(); // close dialog
                                    await deleteDiary(diary['id']);
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
