import 'package:get/get.dart';
import '../profile/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../safety/safety_service.dart';

class DiaryEntry {
  final String id;
  final String content;
  final DateTime createdAt;
  final String moodType;

  DiaryEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.moodType,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
      moodType: json['mood_type'] ?? 'Calm',
    );
  }
}

class DiaryController extends GetxController {
  final _supabase = Supabase.instance.client;
  var entries = <DiaryEntry>[].obs;
  var isLoading = false.obs;
  final currentMoodFilter = ''.obs;

  void setMoodFilter(String mood) {
    if (currentMoodFilter.value == mood) {
      currentMoodFilter.value = ''; // Toggle off
    } else {
      currentMoodFilter.value = mood;
    }
    fetchEntries();
  }

  @override
  void onInit() {
    super.onInit();
    fetchEntries();
  }

  Future<void> fetchEntries() async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      var query = _supabase.from('mood_diaries').select().eq('user_id', userId);

      if (currentMoodFilter.value.isNotEmpty) {
        query = query.eq('mood_type', currentMoodFilter.value);
      }

      final response = await query.order('created_at', ascending: false);

      final List<dynamic> data = response;
      entries.value = data.map((json) => DiaryEntry.fromJson(json)).toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to load diaries: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addEntry(String content, String mood) async {
    if (!Get.find<ProfileController>().checkActionAllowed('发布日记')) return;

    // Safety Check
    if (!Get.find<SafetyService>().canPost(content, 'add_diary')) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar("Error", "Please login first");
        return;
      }

      final newEntry = {
        'user_id': userId,
        'content': content,
        'mood_type': mood,
      };

      await _supabase.from('mood_diaries').insert(newEntry);

      // Refresh list
      fetchEntries();
      Get.snackbar("Success", "Diary saved!");
    } catch (e) {
      Get.snackbar("Error", "Failed to save diary: $e");
    }
  }
}
