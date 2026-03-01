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

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (e) {
        return DateTime.now();
      }
    }

    return PrivateMessage(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: parseDate(map['created_at']),

      senderName: senderProfile != null
          ? senderProfile['username']?.toString()
          : null,
      senderAvatar: senderProfile != null
          ? senderProfile['avatar_url']?.toString()
          : null,
      receiverName: receiverProfile != null
          ? receiverProfile['username']?.toString()
          : null,
      receiverAvatar: receiverProfile != null
          ? receiverProfile['avatar_url']?.toString()
          : null,
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
