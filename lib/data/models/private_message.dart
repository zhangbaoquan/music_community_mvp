class PrivateMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  // Optional: sender/receiver profile info (if joined)
  final String? senderName;
  final String? senderAvatar;
  final String? receiverName;
  final String? receiverAvatar;

  PrivateMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.receiverName,
    this.receiverAvatar,
  });

  factory PrivateMessage.fromMap(Map<String, dynamic> map, {String? myUserId}) {
    // Attempt to extract profile info if available
    // Structure depends on query. e.g. select(*, sender:profiles!sender_id(...), receiver:profiles!receiver_id(...))

    final senderProfile = map['sender'] ?? {};
    final receiverProfile = map['receiver'] ?? {};

    return PrivateMessage(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      content: map['content'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),

      senderName: senderProfile['username'],
      senderAvatar: senderProfile['avatar_url'],
      receiverName: receiverProfile['username'],
      receiverAvatar: receiverProfile['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead, // Usually readonly on client
    };
  }
}
