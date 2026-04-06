---
name: Supabase 数据层规范
description: Supabase BaaS 的数据访问封装、RLS 策略管理、Realtime 订阅、Storage 上传、查询优化等质量约束
---

# Supabase 数据层 Skill

本 Skill 定义亲亲心情笔记项目（以及所有 Flutter + Supabase 项目）的数据层质量标准。所有涉及 Supabase 操作的代码必须遵循以下规范。

---

## 1. 数据访问架构

### 1.1 三层隔离原则

```
View 层     → 禁止直接调用 Supabase
Controller  → 禁止直接调用 Supabase
Service 层  → 所有 Supabase 调用的唯一入口
```

### 1.2 Service 层文件组织

```
lib/data/services/
├── log_service.dart         # 日志服务（全局）
├── article_service.dart     # 文章相关 CRUD
├── auth_service.dart        # 认证相关操作
├── comment_service.dart     # 评论相关 CRUD
├── music_service.dart       # 音乐相关 CRUD
├── profile_service.dart     # 用户资料相关
├── social_service.dart      # 社交关系（关注/点赞/收藏）
├── storage_service.dart     # 文件上传/下载
└── stats_service.dart       # 统计数据（RPC 调用）
```

### 1.3 Service 类标准模板

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';
import '../models/article.dart';

/// 文章数据服务
///
/// 封装所有文章相关的 Supabase CRUD 操作。
class ArticleService {
  final _client = Supabase.instance.client;

  /// 获取文章列表（支持游标分页）
  ///
  /// [limit] 每页数量
  /// [cursor] 上一页最后一条记录的创建时间，首次传 null
  /// 返回文章列表，失败返回空列表
  Future<List<Article>> getArticles({int limit = 20, String? cursor}) async {
    try {
      var query = _client
          .from('articles')
          .select('*, profiles(*), songs(*)')
          .order('created_at', ascending: false)
          .limit(limit);

      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }

      final response = await query;
      return (response as List).map((e) => Article.fromJson(e)).toList();
    } catch (e, stackTrace) {
      LogService.error('获取文章列表失败', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// 创建文章
  ///
  /// [article] 文章数据对象
  /// 返回创建成功的文章，失败返回 null
  Future<Article?> createArticle(Article article) async {
    try {
      final response = await _client
          .from('articles')
          .insert(article.toJson())
          .select()
          .single();
      return Article.fromJson(response);
    } catch (e, stackTrace) {
      LogService.error('创建文章失败', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
```

---

## 2. 错误处理规范

### 2.1 必须 try-catch

**每个** Supabase 调用都必须包裹在 try-catch 中，无例外。

```dart
// ✅ 正确
Future<List<Article>> getArticles() async {
  try {
    final response = await _client.from('articles').select();
    return (response as List).map((e) => Article.fromJson(e)).toList();
  } catch (e, stackTrace) {
    LogService.error('获取文章失败', error: e, stackTrace: stackTrace);
    return []; // 返回安全的默认值
  }
}

// ❌ 错误：无 try-catch
Future<List<Article>> getArticles() async {
  final response = await _client.from('articles').select(); // ❌ 可能抛异常
  return (response as List).map((e) => Article.fromJson(e)).toList();
}
```

### 2.2 错误日志格式

使用 `LogService` 统一记录，包含：
- 操作描述（中文）
- 原始错误对象
- 堆栈追踪

```dart
LogService.error('获取文章列表失败', error: e, stackTrace: stackTrace);
```

### 2.3 返回值安全策略

| 返回类型 | 失败时返回值 |
|---------|------------|
| `Future<List<T>>` | `[]` 空列表 |
| `Future<T?>` | `null` |
| `Future<bool>` | `false` |
| `Future<int>` | `0` |

---

## 3. RLS 策略管理

### 3.1 SQL 文件强制要求

**任何** 涉及 RLS 策略变更的操作，都必须**先在 `sql/` 目录创建对应的 .sql 文件**，然后再通过 Supabase Dashboard 或 CLI 执行。

### 3.2 SQL 文件命名

```
sql/
├── fix_comments_fk.sql              # 修复类：fix_{表名}_{描述}.sql
├── fix_article_mutations_rls.sql    # 修复 RLS 策略
├── fix_app_logs_rls.sql             # 修复日志表 RLS
├── admin_dashboard.sql              # 功能类：{功能名}.sql
├── rpc_get_user_stats.sql           # RPC 类：rpc_{函数名}.sql
└── add_mood_tags_to_songs.sql       # 迁移类：add_{字段}_{表名}.sql
```

### 3.3 SQL 文件模板

```sql
-- ============================================
-- 文件名：rpc_get_user_stats.sql
-- 描述：获取用户统计数据的 RPC 函数
-- 创建日期：2026-04-06
-- ============================================

-- 创建 RPC 函数
CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS JSON AS $$
  SELECT json_build_object(
    'article_count', (SELECT COUNT(*) FROM articles WHERE user_id = target_user_id),
    'follower_count', (SELECT COUNT(*) FROM follows WHERE following_id = target_user_id),
    'like_count', (SELECT COUNT(*) FROM article_likes al 
                   JOIN articles a ON a.id = al.article_id 
                   WHERE a.user_id = target_user_id)
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- 授权匿名用户调用
GRANT EXECUTE ON FUNCTION get_user_stats(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_user_stats(UUID) TO authenticated;
```

---

## 4. Realtime 订阅规范

### 4.1 订阅模式

```dart
class CommentController extends GetxController {
  RealtimeChannel? _commentChannel;

  @override
  void onInit() {
    super.onInit();
    _subscribeToComments();
  }

  /// 订阅评论实时更新
  void _subscribeToComments() {
    _commentChannel = Supabase.instance.client
        .channel('comments:article_${articleId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'article_id',
            value: articleId,
          ),
          callback: (payload) {
            final newComment = Comment.fromJson(payload.newRecord);
            comments.add(newComment);
          },
        )
        .subscribe();
  }

  @override
  void onClose() {
    // ✅ 必须：在 onClose 中取消订阅
    _commentChannel?.unsubscribe();
    super.onClose();
  }
}
```

### 4.2 关键规则

| 规则 | 说明 |
|------|------|
| 订阅位置 | `onInit()` 中订阅 |
| 取消位置 | `onClose()` 中**必须**取消订阅 |
| 防重复 | 在订阅前检查是否已有活跃订阅 |
| Channel 命名 | 使用有意义的名称（如 `comments:article_${id}`） |

---

## 5. Storage 上传规范

### 5.1 文件命名

```dart
// ✅ 正确：包含用户 ID 前缀 + 时间戳，防冲突
final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
final path = 'avatars/$fileName';

// ❌ 错误：无用户 ID 前缀，可能冲突
final fileName = 'avatar.jpg'; // ❌
final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg'; // ❌ 无用户隔离
```

### 5.2 必须指定 contentType

```dart
// ✅ 正确
await _client.storage.from('avatars').upload(
  path,
  fileBytes,
  fileOptions: const FileOptions(contentType: 'image/jpeg'), // ✅ 必须
);

// ❌ 错误：未指定 contentType
await _client.storage.from('avatars').upload(path, fileBytes); // ❌
```

### 5.3 Bucket 组织

| Bucket | 用途 | 访问权限 |
|--------|------|---------|
| `avatars` | 用户头像 | 公开读，认证写 |
| `covers` | 文章封面图 | 公开读，认证写 |
| `article-images` | 文章内插图 | 公开读，认证写 |
| `music` | 音频文件 | 公开读，认证写 |

---

## 6. 查询优化规范

### 6.1 禁止循环查询

```dart
// ❌ 绝对禁止：在循环中发起 Supabase 请求
for (final article in articles) {
  final likes = await _client
      .from('article_likes')
      .select()
      .eq('article_id', article.id); // ❌ N+1 查询！
}

// ✅ 正确：批量查询
final articleIds = articles.map((a) => a.id).toList();
final allLikes = await _client
    .from('article_likes')
    .select()
    .inFilter('article_id', articleIds); // ✅ 一次查询
```

### 6.2 禁止客户端 .count()

```dart
// ❌ 禁止：客户端 .count() 统计
final count = await _client
    .from('article_likes')
    .select()
    .eq('article_id', articleId)
    .count(CountOption.exact); // ❌ 类型变更风险 + 性能差

// ✅ 正确：使用 RPC
final stats = await _client.rpc('get_article_stats', params: {
  'target_article_id': articleId,
}); // ✅ 后端计算
```

### 6.3 使用 select 精确指定字段

```dart
// ✅ 优秀：精确指定需要的字段和关联
final response = await _client
    .from('articles')
    .select('id, title, created_at, profiles(username, avatar_url)')
    .order('created_at', ascending: false)
    .limit(20);

// ⚠️ 可接受但不推荐：select('*') 全量查询
final response = await _client
    .from('articles')
    .select('*'); // 如果表字段很多，会传输不必要的数据
```

---

## 7. RPC 调用规范

### 7.1 标准调用模式

```dart
/// 获取用户统计数据
///
/// 通过 Postgres RPC 在后端完成聚合计算，
/// 避免前端多次查询和客户端计算。
Future<UserStats?> getUserStats(String userId) async {
  try {
    final response = await _client.rpc('get_user_stats', params: {
      'target_user_id': userId,
    });
    return UserStats.fromJson(response);
  } catch (e, stackTrace) {
    LogService.error('获取用户统计失败', error: e, stackTrace: stackTrace);
    return null;
  }
}
```

### 7.2 RPC vs 直接查询的选择

| 场景 | 推荐方式 |
|------|---------|
| 简单 CRUD（增删改查单表） | 直接查询 |
| 多表 JOIN 关联查询 | 直接查询（Supabase 支持） |
| 涉及 COUNT / SUM / AVG 等聚合 | **RPC** |
| 涉及多表计数并组合结果 | **RPC** |
| 涉及复杂条件的分页查询 | **RPC** |
| 需要事务保证的多步操作 | **RPC** |
