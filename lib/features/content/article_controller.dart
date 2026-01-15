import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/article.dart';

class ArticleController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Observables
  final isLoading = false.obs;
  final isUploading = false.obs;
  final articles = <Article>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchArticles();
  }

  /// Fetch all published articles with author profile info & social stats
  Future<void> fetchArticles() async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;

      // 1. Fetch Articles with Counts
      final response = await _supabase
          .from('articles')
          .select(
            '*, profiles(username, avatar_url), likes:article_likes(count), collections:article_collections(count)',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      final loadedArticles = data.map((e) => Article.fromMap(e)).toList();

      // 2. Fetch User's Interaction Status (if logged in)
      if (userId != null) {
        // Prepare list of article IDs to query
        final articleIds = loadedArticles.map((a) => a.id).toList();

        if (articleIds.isNotEmpty) {
          // Check likes
          final myLikes = await _supabase
              .from('article_likes')
              .select('article_id')
              .eq('user_id', userId)
              .inFilter('article_id', articleIds);

          final likedIds = (myLikes as List)
              .map((e) => e['article_id'])
              .toSet();

          // Check collections
          final myCollections = await _supabase
              .from('article_collections')
              .select('article_id')
              .eq('user_id', userId)
              .inFilter('article_id', articleIds);

          final collectedIds = (myCollections as List)
              .map((e) => e['article_id'])
              .toSet();

          // Merge status
          for (var article in loadedArticles) {
            article.isLiked = likedIds.contains(article.id);
            article.isCollected = collectedIds.contains(article.id);
          }
        }
      }

      articles.value = loadedArticles;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load articles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle Like
  Future<void> toggleLike(Article article) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    try {
      if (article.isLiked) {
        // Unlike
        await _supabase.from('article_likes').delete().match({
          'user_id': userId,
          'article_id': article.id,
        });
        article.isLiked = false;
        article.likesCount = (article.likesCount - 1).clamp(0, 999999);
      } else {
        // Like
        await _supabase.from('article_likes').insert({
          'user_id': userId,
          'article_id': article.id,
        });
        article.isLiked = true;
        article.likesCount++;
      }
      articles.refresh(); // Update UI
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle like: $e');
    }
  }

  /// Toggle Collection
  Future<void> toggleCollection(Article article) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    try {
      if (article.isCollected) {
        // Remove Collection
        await _supabase.from('article_collections').delete().match({
          'user_id': userId,
          'article_id': article.id,
        });
        article.isCollected = false;
        article.collectionsCount = (article.collectionsCount - 1).clamp(
          0,
          999999,
        );
      } else {
        // Add Collection
        await _supabase.from('article_collections').insert({
          'user_id': userId,
          'article_id': article.id,
        });
        article.isCollected = true;
        article.collectionsCount++;
      }
      articles.refresh(); // Update UI
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle collection: $e');
    }
  }

  /// Create a new article
  Future<bool> publishArticle({
    required String title,
    required dynamic contentJson,
    String? summary,
    PlatformFile? coverFile,
  }) async {
    try {
      isUploading.value = true;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar('Error', 'Please login first');
        return false;
      }

      String? coverUrl;

      // 1. Upload Cover if exists
      if (coverFile != null) {
        final bytes = coverFile.bytes;
        final fileExt = coverFile.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '$userId/$fileName';

        if (bytes != null) {
          await _supabase.storage
              .from('article_covers')
              .uploadBinary(
                filePath,
                bytes,
                fileOptions: const FileOptions(
                  contentType:
                      'image/jpeg', // Adjust based on file type if needed
                  upsert: true,
                ),
              );

          coverUrl = _supabase.storage
              .from('article_covers')
              .getPublicUrl(filePath);
        }
      }

      // 2. Insert Article Record
      final article = Article(
        id: '', // Generated by DB
        userId: userId,
        title: title,
        summary: summary,
        coverUrl: coverUrl,
        content: contentJson,
        createdAt: DateTime.now(),
      );

      await _supabase.from('articles').insert(article.toMap());

      // 3. Refresh list (fire and forget, or await if needed)
      fetchArticles();

      return true;
    } catch (e) {
      print('Publish Error: $e'); // Log for debugging
      // Get.snackbar('Error', 'Failed to publish article: $e'); // Move UI to View
      return false;
    } finally {
      isUploading.value = false;
    }
  }
}
