class Comment {
  final String id;
  final String userId;
  final String songId;
  final String content;
  final String? userNickname;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.songId,
    required this.content,
    this.userNickname,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      songId: json['song_id'] as String,
      content: json['content'] as String,
      userNickname: json['user_nickname'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'song_id': songId,
      'content': content,
      'user_nickname': userNickname,
    };
  }
}
