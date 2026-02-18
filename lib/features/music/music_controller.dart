import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/song.dart';
import '../profile/profile_controller.dart';
import '../player/player_controller.dart'; // Import PlayerController

class MusicController extends GetxController {
  final _supabase = Supabase.instance.client;

  final rxUserSongs = <Song>[].obs;
  final rxSongs = <Song>[].obs; // For discovery/all songs
  final isLoading = false.obs;
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // fetchUserSongs(); // Can fetch on init or when entering profile
    // fetchSongs(); // Fetch discovery songs
  }

  // Fetch all public songs (discovery)
  Future<void> fetchSongs() async {
    try {
      isLoading.value = true;
      final response = await _supabase
          .from('songs')
          .select('*, profiles(username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(100);

      final List<dynamic> data = response;
      rxSongs.value = data.map((e) => Song.fromMap(e)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load songs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserSongs(String userId) async {
    try {
      isLoading.value = true;
      final response = await _supabase
          .from('songs')
          .select()
          .eq('uploader_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      rxUserSongs.value = data.map((e) => Song.fromMap(e)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load songs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // V14: Play a song based on Mood Tag (List of keywords for broader match)
  Future<void> playMood(List<String> moodKeywords) async {
    // 1. Ensure we have songs loaded (discovery list)
    if (rxSongs.isEmpty) {
      await fetchSongs();
    }

    // Helper function to check match
    bool hasMatch(Song s) {
      if (s.moodTags == null || s.moodTags!.isEmpty) return false;
      // Check if ANY tag contains ANY keyword (Case Insensitive)
      return s.moodTags!.any((tag) {
        return moodKeywords.any(
          (keyword) => tag.toLowerCase().contains(keyword.toLowerCase()),
        );
      });
    }

    // 2. Filter songs by mood (Fuzzy Match for better results)
    var moodSongs = rxSongs.where(hasMatch).toList();

    // If still empty, try force refresh once
    if (moodSongs.isEmpty && rxSongs.isNotEmpty) {
      await fetchSongs();
      moodSongs = rxSongs.where(hasMatch).toList();
    }

    if (moodSongs.isEmpty) {
      // Show the first keyword as the main one for the message
      final mainMood = moodKeywords.isNotEmpty ? moodKeywords.first : '未知';
      Get.snackbar('暂无音乐', '还没有找到"$mainMood"相关心情的音乐哦，去上传一首吧！');
      return;
    }

    // 3. Pick a random song or the first one
    // Let's pick random to make it feel like a radio
    moodSongs.shuffle();
    final songToPlay = moodSongs.first;

    // 4. Play it
    // Use PlayerController for actual playback logic
    Get.find<PlayerController>().playSong(songToPlay);
  }

  Future<bool> uploadSong({
    required PlatformFile audioFile,
    required String title,
    required String artist,
    XFile? coverFile,
    List<String> moodTags = const [],
  }) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('上传音乐'))
      return false;
    try {
      isUploading.value = true;
      uploadProgress.value =
          0.0; // Todo: Implement granular progress if possible

      final user = _supabase.auth.currentUser;
      if (user == null) {
        Get.snackbar('错误', '请先登录后再上传');
        return false;
      }

      // 1. Upload Audio
      final audioExt = audioFile.extension ?? 'mp3';
      final audioPath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$audioExt';

      // For web, use bytes. For mobile, use path.
      // FilePicker returns bytes for web.
      if (audioFile.bytes == null && audioFile.path == null) {
        throw Exception("Audio file data is missing");
      }

      // Using bytes for simplicity (works well for web and smaller files)
      // For large files on mobile, strict path usage is better.
      final audioBytes =
          audioFile.bytes ?? await XFile(audioFile.path!).readAsBytes();

      await _supabase.storage
          .from('songs')
          .uploadBinary(
            audioPath,
            audioBytes,
            fileOptions: const FileOptions(upsert: false),
          );
      final audioUrl = _supabase.storage.from('songs').getPublicUrl(audioPath);

      // 2. Upload Cover (Optional)
      String? coverUrl;
      if (coverFile != null) {
        final coverExt = coverFile.name.split('.').last;
        final coverPath =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}_cover.$coverExt';
        final coverBytes = await coverFile.readAsBytes();

        await _supabase.storage
            .from('song_covers')
            .uploadBinary(
              coverPath,
              coverBytes,
              fileOptions: const FileOptions(upsert: false),
            );
        coverUrl = _supabase.storage
            .from('song_covers')
            .getPublicUrl(coverPath);
      }

      // 3. Insert into DB
      final song = Song(
        id: '', // Supabase generates this
        title: title,
        artist: artist.isEmpty ? "Unknown" : artist,
        url: audioUrl,
        coverUrl: coverUrl,
        moodTags: moodTags,
        uploaderId: user.id,
      );

      // We exclude 'id' and 'created_at' from toMap if they are null/empty, or let DB handle defaults
      // But our toMap includes them. Let's create a specific map for insertion.
      final insertData = {
        'title': song.title,
        'artist': song.artist,
        'url': song.url,
        'cover_url': song.coverUrl,
        'mood_tags': song.moodTags,
        'uploader_id': song.uploaderId,
      };

      await _supabase.from('songs').insert(insertData);

      Get.snackbar('成功', '音乐上传成功！');
      fetchUserSongs(user.id); // Refresh list
      return true;
    } catch (e) {
      print('Upload error: $e');
      Get.snackbar('错误', '上传失败: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> deleteSong(String songId) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('删除音乐'))
      return false;
    try {
      // 1. Delete from DB (RLS will handle permission check)
      await _supabase.from('songs').delete().eq('id', songId);

      // 2. Refresh lists
      rxSongs.removeWhere((s) => s.id == songId); // Optimistic update
      rxUserSongs.removeWhere((s) => s.id == songId);

      Get.snackbar('成功', '音乐已删除');
      return true;
    } catch (e) {
      print('Delete error: $e');
      Get.snackbar('错误', '删除失败: $e');
      return false;
    }
  }
}
