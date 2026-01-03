import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final _supabase = Supabase.instance.client;

  final userEmail = ''.obs;
  final diaryCount = 0.obs;
  final joinDate = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? 'files@example.com';
      joinDate.value = user.createdAt.split('T')[0]; // Simple date format

      // Fetch stats
      // Note: count() is more efficient but for MVP we can just get length
      final response = await _supabase
          .from('mood_diaries')
          .select('id')
          .eq('user_id', user.id);

      final List data = response;
      diaryCount.value = data.length;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // AuthController listener will handle redirection
  }
}
