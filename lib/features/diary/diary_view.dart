import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import '../profile/profile_controller.dart';
import 'diary_controller.dart';
import 'package:intl/intl.dart';

class DiaryView extends StatefulWidget {
  const DiaryView({super.key});

  @override
  State<DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends State<DiaryView> {
  // Use putOrFind to be safe, though usually put is fine for pages
  final controller = Get.put(DiaryController());
  final textController = TextEditingController();

  // Mood Selection State
  String selectedMood = '平静';
  final List<String> moodOptions = ['开心', '忧郁', '平静', '专注'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "心情日记",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Input Area (Write a new diary)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "记录当下的心情与故事...",
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mood Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMood,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          items: moodOptions.map((String mood) {
                            return DropdownMenuItem<String>(
                              value: mood,
                              child: Row(
                                children: [
                                  Icon(
                                    _getMoodIcon(mood),
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    mood,
                                    style: GoogleFonts.outfit(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedMood = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    // Save Button
                    ElevatedButton(
                      onPressed: () {
                        if (!Get.find<ProfileController>().checkActionAllowed(
                          '发布日记',
                        )) {
                          return;
                        }

                        if (textController.text.isNotEmpty) {
                          controller.addEntry(
                            textController.text,
                            selectedMood,
                          );
                          textController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        "保存",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // List Area (Display existing diaries)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 48, color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      Text(
                        "这里很安静...",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "试着写下第一笔心事吧，\n文字会安抚你的灵魂。",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: controller.entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final entry = controller.entries[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Date
                            Text(
                              DateFormat(
                                'yyyy年M月d日 • HH:mm',
                              ).format(entry.createdAt.toLocal()),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            // Mood Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getMoodColor(entry.moodType),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getMoodIcon(entry.moodType),
                                    size: 10,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.moodType,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.content,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case '开心':
        return Icons.sunny;
      case '忧郁':
        return Icons.cloud;
      case '平静':
        return Icons.spa;
      case '专注':
        return Icons.coffee;
      default:
        return Icons.circle;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case '开心':
        return Colors.orange[100]!;
      case '忧郁':
        return Colors.blueGrey[100]!;
      case '平静':
        return Colors.green[100]!;
      case '专注':
        return Colors.brown[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
