class FeedbackModel {
  final String id;
  final String?
  userId; // Can be null for anonymous, but we usually enforce auth
  final String? username; // Joined from profile
  final String? avatarUrl; // Joined from profile
  final String content;
  final List<String> images;
  final String? contact;
  final String status;
  final String? replyContent; // Admin reply
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    this.userId,
    this.username,
    this.avatarUrl,
    required this.content,
    required this.images,
    this.contact,
    required this.status,
    this.replyContent,
    required this.createdAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    // Safety for joined 'profiles' data potentially being null or list
    final profileData =
        map['profiles']; // e.g., {username: ..., avatar_url: ...}
    String? name = '访客';
    String? avatar = '';

    if (profileData != null) {
      if (profileData is Map) {
        name = profileData['username'];
        avatar = profileData['avatar_url'];
      }
    }

    // Parse images array. Postgres arrays often come as List<dynamic> in JSON
    final rawImages = map['images'] as List<dynamic>?;
    final List<String> imgList = rawImages != null
        ? rawImages.map((e) => e.toString()).toList()
        : [];

    return FeedbackModel(
      id: map['id'],
      userId: map['user_id'],
      username: name,
      avatarUrl: avatar,
      content: map['content'] ?? '',
      images: imgList,
      contact: map['contact'],
      status: map['status'] ?? 'pending',
      replyContent: map['reply_content'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
    );
  }
}
