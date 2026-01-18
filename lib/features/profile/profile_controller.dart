import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final _supabase = Supabase.instance.client;

  final userEmail = ''.obs;
  final username = ''.obs;
  final avatarUrl = ''.obs;
  final signature = ''.obs;
  final diaryCount = 0.obs;

  // Social Stats (Mock/Placeholder for now)
  final followingCount = 0.obs;
  final followersCount = 0.obs;
  final visitorsCount = 0.obs;
  final moodIndex = 85.obs; // Mock value for existing stat

  final email = ''.obs;

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

      try {
        // Fetch Profile Data
        final response = await _supabase
            .from('profiles')
            .select('username, avatar_url, signature')
            .eq('id', user.id)
            .single();

        username.value = response['username'] as String? ?? '';
        avatarUrl.value = response['avatar_url'] as String? ?? '';
        signature.value = response['signature'] as String? ?? '';

        // Mock data for social stats (TODO: Implement real fetching)
        followingCount.value = 70;
        followersCount.value = 12;
        visitorsCount.value = 6;
        diaryCount.value =
            3; // Keep using mock or fetch real count if available

        // Fetch stats
        final statsResponse = await _supabase
            .from('mood_diaries')
            .select('id')
            .eq('user_id', user.id);

        final List data = statsResponse;
        diaryCount.value = data.length;
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  /// Update Profile
  Future<bool> updateProfile({
    String? newUsername,
    String? newSignature,
    PlatformFile? newAvatar,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newUsername != null) updates['username'] = newUsername;
      if (newSignature != null) updates['signature'] = newSignature;

      // Upload Avatar if provided
      if (newAvatar != null && newAvatar.bytes != null) {
        final fileExt = newAvatar.name.split('.').last;
        final fileName =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await _supabase.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              newAvatar.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);
        updates['avatar_url'] = publicUrl;
        avatarUrl.value = publicUrl;
      }

      await _supabase.from('profiles').upsert({'id': user.id, ...updates});

      // Update Local State
      if (newUsername != null) username.value = newUsername;
      if (newSignature != null) signature.value = newSignature;

      Get.snackbar('成功', '个人资料已更新');
      return true;
    } catch (e) {
      print('Profile Update Error: $e');
      Get.snackbar('错误', '更新失败: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // AuthController listener will handle redirection
  }
}
