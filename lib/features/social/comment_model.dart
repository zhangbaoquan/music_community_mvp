class Comment {
  final String id;
  final String userId;
  final String songId;
  final String content;
  final String? userNickname;
  final DateTime createdAt;

  // Interactions
  int likeCount;
  bool isLiked;
  int collectionCount;
  bool isCollected;

  Comment({
    required this.id,
    required this.userId,
    required this.songId,
    required this.content,
    this.userNickname,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.collectionCount = 0,
    this.isCollected = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      songId: json['song_id'] as String,
      content: json['content'] as String,
      userNickname: json['user_nickname'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      // We will handle filling these in the Service,
      // or if we use a view that joins them.
      // For now, default to 0/false if missing.
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      collectionCount: json['collection_count'] ?? 0,
      isCollected: json['is_collected'] ?? false,
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
