import 'package:flutter_test/flutter_test.dart';
import 'package:music_community_mvp/data/models/article.dart';

void main() {
  group('Article Model Tests', () {
    test('fromMap should parse standard response correctly', () {
      final mockJson = {
        'id': 'article-123',
        'user_id': 'user-1',
        'title': 'Hello World',
        'summary': 'A test summary',
        'cover_url': 'http://example.com/cover.jpg',
        'content': '[{"insert": "Hello"}]',
        'is_published': true,
        'type': 'original',
        'tags': ['flutter', 'dart'],
        'created_at': '2023-01-01T12:00:00Z',
      };

      final article = Article.fromMap(mockJson);

      expect(article.id, 'article-123');
      expect(article.userId, 'user-1');
      expect(article.title, 'Hello World');
      expect(article.summary, 'A test summary');
      expect(article.coverUrl, 'http://example.com/cover.jpg');
      expect(article.isPublished, true);
      expect(article.type, 'original');
      expect(article.tags, ['flutter', 'dart']);
      // UTC to Local
      expect(article.createdAt.isUtc, false); 
    });

    test('fromMap should handle joined profile and song data', () {
      final mockJson = {
        'id': 'article-123',
        'user_id': 'user-1',
        'title': 'Joined Data',
        'created_at': '2023-01-01T12:00:00Z',
        'bgm_song_id': 'song-1',
        'profiles': {
          'username': 'Test Author',
          'avatar_url': 'http://example.com/avatar.jpg'
        },
        'songs': {
          'title': 'Test Song'
        }
      };

      final article = Article.fromMap(mockJson);

      expect(article.authorName, 'Test Author');
      expect(article.authorAvatar, 'http://example.com/avatar.jpg');
      expect(article.bgmSongId, 'song-1');
      expect(article.bgmTitle, 'Test Song');
    });

    test('fromMap should parse count arrays correctly', () {
      final mockJson = {
        'id': 'article-123',
        'user_id': 'user-1',
        'title': 'Counts',
        'created_at': '2023-01-01T12:00:00Z',
        'likes': [{'count': 42}],
        'collections': [{'count': 10}],
        'comments': [{'count': 5}],
      };

      final article = Article.fromMap(mockJson);

      expect(article.likesCount, 42);
      expect(article.collectionsCount, 10);
      expect(article.commentsCount, 5);
    });

    test('fromMap should handle empty or null counts', () {
      final mockJson = {
        'id': 'article-123',
        'user_id': 'user-1',
        'title': 'Empty Counts',
        'created_at': '2023-01-01T12:00:00Z',
        'likes': null,
        'collections': [],
      };

      final article = Article.fromMap(mockJson);

      expect(article.likesCount, 0);
      expect(article.collectionsCount, 0);
      expect(article.commentsCount, 0);
    });

    test('copyWith should return a new instance with updated values', () {
      final original = Article(
        id: '1',
        userId: 'u1',
        title: 'Title',
        createdAt: DateTime.now(),
        likesCount: 1,
      );

      final updated = original.copyWith(
        title: 'New Title',
        likesCount: 2,
        isLiked: true,
      );

      expect(updated.id, '1'); // Unchanged
      expect(updated.title, 'New Title'); // Changed
      expect(updated.likesCount, 2); // Changed
      expect(updated.isLiked, true); // Changed
    });
  });
}
