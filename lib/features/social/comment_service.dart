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
}
