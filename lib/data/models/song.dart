class Song {
  final String id;
  final String title;
  final String? artist;
  final String url;
  final String? coverUrl;
  final int? duration;
  final List<String>? moodTags;
  final String? uploaderId; // Added for Phase 4
  final DateTime? createdAt;

  // UI Helpers (fetched via join)
  final String? uploaderName;
  final String? uploaderAvatar;

  Song({
    required this.id,
    required this.title,
    this.artist,
    required this.url,
    this.coverUrl,
    this.duration,
    this.moodTags,
    this.uploaderId,
    this.createdAt,
    this.uploaderName,
    this.uploaderAvatar,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profile;
    if (map['profiles'] != null) {
      profile = map['profiles'] as Map<String, dynamic>;
    }

    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      url: map['url'] as String,
      coverUrl: map['cover_url'] as String?,
      duration: map['duration'] as int?,
      moodTags: (map['mood_tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      uploaderId: map['uploader_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      uploaderName: profile?['username'],
      uploaderAvatar: profile?['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'url': url,
      'cover_url': coverUrl,
      'duration': duration,
      'mood_tags': moodTags,
      'uploader_id': uploaderId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
