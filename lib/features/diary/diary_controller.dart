import 'package:get/get.dart';

class DiaryEntry {
  final String content;
  final String date;
  final String mood;

  DiaryEntry({required this.content, required this.date, required this.mood});
}

class DiaryController extends GetxController {
  var entries = <DiaryEntry>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // Load some dummy data
    entries.add(DiaryEntry(content: "今天听这首歌，感觉很平静...", date: "2024-12-28", mood: "Peaceful"));
  }

  void addEntry(String content) {
    if (content.isNotEmpty) {
      entries.insert(0, DiaryEntry(
        content: content,
        date: DateTime.now().toString().split(' ')[0], 
        mood: "Calm" // Default for MVP
      ));
    }
  }
}
