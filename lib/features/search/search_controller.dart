import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_community_mvp/data/models/article.dart';

class SearchController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Search Input
  final searchText = ''.obs;
  final isLoading = false.obs;

  // Results
  final users = <Map<String, dynamic>>[].obs;
  final diaries = <Map<String, dynamic>>[].obs;
  final articles = <Article>[].obs;

  // Debounce worker
  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    // Auto-search when text changes (optional, maybe stick to manual enter for now to save quota/performance)
    // _debounceWorker = debounce(searchText, (enteredText) {
    //   if (enteredText.isNotEmpty) search(enteredText);
    // }, time: const Duration(milliseconds: 800));
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    isLoading.value = true;
    users.clear();
    diaries.clear();
    articles.clear();

    try {
      // 1. Search Users (username)
      // Note: plain '%query%' ilike might be slow on large tables without trigram index, but OK for MVP.
      try {
        final userRes = await _supabase
            .from('profiles')
            .select('id, username, avatar_url, signature')
            .ilike('username', '%$query%')
            .limit(20);
        users.value = List<Map<String, dynamic>>.from(userRes);
      } catch (e) {
        print('Search Users Error: $e');
      }

      // 2. Search Diaries (content)
      // We need user info for diaries too
      try {
        final diaryRes = await _supabase
            .from('mood_diaries')
            .select('*, profiles(username, avatar_url)')
            .ilike('content', '%$query%')
            .limit(20);
        diaries.value = List<Map<String, dynamic>>.from(diaryRes);
      } catch (e) {
        print('Search Diaries Error: $e');
        // If ambiguous FK, it might fail here
      }

      // 3. Search Articles (title or content)
      // Supabase .or() syntax: 'title.ilike.%query%,content.ilike.%query%'
      try {
        final articleRes = await _supabase
            .from('articles')
            .select('*, profiles(username, avatar_url)')
            .ilike('title', '%$query%')
            .limit(20);

        articles.value = (articleRes as List)
            .map((e) => Article.fromMap(e))
            .toList();
      } catch (e) {
        print('Search Articles Error: $e');
      }

      isLoading.value =
          false; // Set loading false here instead of finally if we split execution

      // Check if everything failed or just some
      if (users.isEmpty &&
          diaries.isEmpty &&
          articles.isEmpty &&
          (query.isNotEmpty)) {
        // Optional: could show error if completely failed, but for now silent partial failure is better than total failure notification
      }
    } catch (e) {
      print('Search Error: $e');
      Get.snackbar('搜索出错', '请稍后重试');
      isLoading.value =
          false; // Ensure loading is false even if the outer try-catch catches an error
    }
  }

  void clear() {
    searchText.value = '';
    users.clear();
    diaries.clear();
    articles.clear();
  }
}
