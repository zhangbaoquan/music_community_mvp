import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/song.dart';

class MusicController extends GetxController {
  final _supabase = Supabase.instance.client;

  final rxUserSongs = <Song>[].obs;
  final isLoading = false.obs;
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // fetchUserSongs(); // Can fetch on init or when entering profile
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

  Future<bool> uploadSong({
    required PlatformFile audioFile,
    required String title,
    required String artist,
    XFile? coverFile,
    List<String> moodTags = const [],
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value =
          0.0; // Todo: Implement granular progress if possible

      final user = _supabase.auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'You must be logged in to upload');
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

      Get.snackbar('Success', 'Song uploaded successfully!');
      fetchUserSongs(user.id); // Refresh list
      return true;
    } catch (e) {
      print('Upload error: $e');
      Get.snackbar('Error', 'Upload failed: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }
}
