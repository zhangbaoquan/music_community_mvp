import 'dart:typed_data'; // For Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comment_model.dart';

class CommentService {
  final _supabase = Supabase.instance.client;

  // Fetch existing comments
  Future<List<Comment>> fetchComments(String songId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('song_id', songId)
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  // Post a new comment
  Future<void> postComment({
    required String songId,
    required String content,
    String? userNickname,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('comments').insert({
      'user_id': userId,
      'song_id': songId,
      'content': content,
      'user_nickname': userNickname,
    });
  }

  // Subscribe to real-time updates
  RealtimeChannel subscribeToComments(
    String songId,
    void Function(Comment) onNewComment,
  ) {
    return _supabase
        .channel('public:comments:$songId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'song_id',
            value: songId,
          ),
          callback: (payload) {
            print("New comment received: ${payload.newRecord}");
            onNewComment(Comment.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  // Toggle Like
  Future<bool> toggleLike(String commentId) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      // Check if exists
      final check = await _supabase
          .from('comment_likes')
          .select()
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .maybeSingle();

      if (check != null) {
        // Remove
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('user_id', userId)
            .eq('comment_id', commentId);
        return false; // Liked -> Unliked
      } else {
        // Add
        await _supabase.from('comment_likes').insert({
          'user_id': userId,
          'comment_id': commentId,
        });
        return true; // Unliked -> Liked
      }
    } catch (e) {
      print("Like error: $e");
      rethrow;
    }
  }

  // Toggle Collection
  Future<bool> toggleCollection(String commentId) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final check = await _supabase
          .from('comment_collections')
          .select()
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .maybeSingle();

      if (check != null) {
        await _supabase
            .from('comment_collections')
            .delete()
            .eq('user_id', userId)
            .eq('comment_id', commentId);
        return false;
      } else {
        await _supabase.from('comment_collections').insert({
          'user_id': userId,
          'comment_id': commentId,
        });
        return true;
      }
    } catch (e) {
      print("Collect error: $e");
      rethrow;
    }
  }

  // Delete Comment
  Future<void> deleteComment(String commentId) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId); // Double check ownership safely
    } catch (e) {
      print("Delete error: $e");
      rethrow;
    }
  }

  // Update Comment
  Future<void> updateComment(String commentId, String newContent) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      await _supabase
          .from('comments')
          .update({'content': newContent})
          .eq('id', commentId)
          .eq('user_id', userId);
    } catch (e) {
      print("Update error: $e");
      rethrow;
    }
  }

  // Upload Image
  Future<String> uploadImage(Uint8List bytes, String extension) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = '$userId/$fileName';

      await _supabase.storage
          .from('story_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from('story_images')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print("Upload error: $e");
      rethrow;
    }
  }
}
