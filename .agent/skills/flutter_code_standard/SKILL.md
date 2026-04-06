---
name: Flutter 代码规范
description: Flutter + GetX 项目的代码风格、架构分层、Widget 拆分、命名规范等质量约束
---

# Flutter 代码规范 Skill

本 Skill 定义亲亲心情笔记项目（以及所有 Flutter + GetX 项目）的代码质量标准。AI 在编写或修改 Dart 代码时，必须遵循以下所有规范。

---

## 1. 文件规范

### 1.1 文件大小限制

| 规则 | 约束 |
|------|------|
| 单文件行数上限 | **300 行**（包含注释和空行） |
| 超限处理 | 必须拆分为子组件或子文件 |
| 检查时机 | 每次编辑后自查 |

**拆分策略**：
- View 文件超限 → 提取子 Widget 到 `widgets/` 子目录
- Controller 文件超限 → 拆分为多个职责单一的 Controller，或提取辅助方法到独立文件
- Model 文件超限 → 通常不会，但如果有复杂的序列化逻辑，可提取到扩展文件

### 1.2 文件命名

```
# 正确 ✅
article_detail_view.dart
profile_controller.dart
user_stats_widget.dart

# 错误 ❌
ArticleDetailView.dart     # 不允许 PascalCase
articledetailview.dart      # 不允许无分隔
article-detail-view.dart   # 不允许 kebab-case
```

### 1.3 文件目录结构

每个 Feature 模块必须遵循以下结构：

```
features/
└── {feature_name}/
    ├── {feature_name}_controller.dart   # 必须：业务逻辑
    ├── {feature_name}_view.dart         # 必须：UI 展示
    └── widgets/                         # 可选：模块内子组件
        ├── {widget_name}_widget.dart
        └── ...
```

---

## 2. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | snake_case | `article_detail_view.dart` |
| 类名 | PascalCase | `ArticleDetailView` |
| 变量名 | camelCase | `articleList` |
| 常量 | camelCase 或 SCREAMING_SNAKE_CASE | `maxRetryCount` 或 `MAX_RETRY_COUNT` |
| 私有成员 | 下划线前缀 | `_isLoading` |
| GetX 响应式变量 | camelCase + `.obs` | `final articles = <Article>[].obs;` |
| 枚举值 | camelCase | `ArticleType.diary` |

---

## 3. 架构分层规范

### 3.1 层级职责

```
┌─────────────────────────────────────────┐
│  View 层 (features/xxx/xxx_view.dart)    │  只做 UI 渲染
│  - StatelessWidget / GetView<XxxCtrl>    │  不含业务逻辑
│  - Obx(() => ...) 响应式绑定             │  不直接调用 Supabase
└─────────────┬───────────────────────────┘
              │ 调用
┌─────────────▼───────────────────────────┐
│  Controller 层 (xxx_controller.dart)     │  业务逻辑编排
│  - extends GetxController                │  调用 Service 层
│  - .obs 响应式状态                        │  不直接调用 Supabase
└─────────────┬───────────────────────────┘
              │ 调用
┌─────────────▼───────────────────────────┐
│  Service 层 (data/services/)             │  数据操作封装
│  - 所有 Supabase CRUD 调用               │  每个调用有 try-catch
│  - 返回类型化的 Model 对象               │  使用 LogService 记录错误
└─────────────┬───────────────────────────┘
              │ 使用
┌─────────────▼───────────────────────────┐
│  Model 层 (data/models/)                 │  纯数据结构
│  - fromJson / toJson / copyWith          │  无业务逻辑
└─────────────────────────────────────────┘
```

### 3.2 严格禁止的跨层调用

```dart
// ❌ 绝对禁止：View 层直接调用 Supabase
class ArticleView extends GetView<ArticleController> {
  Widget build(context) {
    final data = Supabase.instance.client.from('articles').select(); // ❌
  }
}

// ❌ 绝对禁止：Controller 直接调用 Supabase
class ArticleController extends GetxController {
  void loadArticles() {
    final data = Supabase.instance.client.from('articles').select(); // ❌
  }
}

// ✅ 正确做法：Controller 通过 Service 层
class ArticleController extends GetxController {
  final _articleService = ArticleService();
  
  void loadArticles() async {
    final articles = await _articleService.getArticles(); // ✅
  }
}
```

---

## 4. GetX 使用规范

### 4.1 响应式变量

```dart
// ✅ 正确：使用 .obs
final isLoading = false.obs;
final articles = <Article>[].obs;
final currentUser = Rxn<User>();

// ❌ 错误：不使用 .obs 的普通变量做状态
bool isLoading = false;       // ❌ UI 不会自动更新
List<Article> articles = [];  // ❌ UI 不会自动更新
```

### 4.2 路由

```dart
// ✅ 正确：使用命名路由
Get.toNamed('/article/$articleId');
Get.toNamed('/profile/$userId');

// ❌ 错误：使用 Get.to() 直接传页面
Get.to(ArticleDetailView(article: article)); // ❌
```

### 4.3 依赖注入

```dart
// ✅ 全局单例（在 AppBinding 中）
Get.lazyPut<PlayerController>(() => PlayerController(), fenix: true);

// ✅ 页面级 Controller
Get.lazyPut<ArticleController>(() => ArticleController());

// ❌ 错误：在 Widget build 方法中 new Controller
final ctrl = ArticleController(); // ❌
```

### 4.4 Controller 生命周期

```dart
class ArticleController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // 初始化：加载数据、订阅 Channel
    _loadArticles();
    _subscribeComments();
  }
  
  @override
  void onClose() {
    // 清理：取消订阅、释放资源
    _commentChannel?.unsubscribe(); // ← 必须取消 Realtime 订阅
    super.onClose();
  }
}
```

---

## 5. Widget 拆分规范

### 5.1 嵌套层级限制

Widget 树嵌套**不超过 5 层**。超过时必须提取为独立 Widget。

```dart
// ❌ 错误：嵌套过深
Scaffold(
  body: Column(
    children: [
      Container(
        child: Padding(
          child: Row(
            children: [
              Expanded(
                child: Column(  // ← 第 6 层，禁止！
                  ...
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

// ✅ 正确：提取子组件
Scaffold(
  body: Column(
    children: [
      _ArticleHeader(article: article),  // 提取为独立 Widget
      _ArticleContent(content: content), // 提取为独立 Widget
    ],
  ),
);
```

### 5.2 子 Widget 文件要求

每个独立的子 Widget 文件**必须有文档注释**：

```dart
/// 文章详情页的评论输入区域
/// 
/// 包含文本输入框、表情选择器和发送按钮。
/// 使用 [ArticleController] 的 [sendComment] 方法提交评论。
class CommentInputWidget extends StatelessWidget {
  // ...
}
```

---

## 6. Null Safety 规范

### 6.1 禁止强制解包

```dart
// ❌ 禁止：使用 ! 强制解包（除非 100% 确定非空）
final name = user!.name;

// ✅ 正确：使用 ?. 和 ??
final name = user?.name ?? '匿名用户';

// ✅ 正确：使用 if-null 检查
if (user != null) {
  final name = user.name;
}
```

### 6.2 唯一允许使用 ! 的场景

```dart
// ✅ 仅在 Get.parameters 已由路由框架保证存在时使用
GetPage(
  name: '/profile/:id',
  page: () => UserProfileView(userId: Get.parameters['id']!),
  // 路由参数由框架保证存在
);
```

---

## 7. 注释规范

### 7.1 必须注释的场景

| 场景 | 要求 |
|------|------|
| 所有 public 类 | `///` 文档注释，说明用途 |
| 所有 public 方法 | `///` 文档注释，说明参数和返回值 |
| 复杂业务逻辑 | 行内注释说明 why |
| 非显而易见的技术决策 | 注释说明理由 |

### 7.2 注释示例

```dart
/// 文章数据服务
/// 
/// 封装所有文章相关的 Supabase CRUD 操作。
/// 所有方法均包含错误处理，失败时返回空结果。
class ArticleService {
  /// 获取文章列表
  /// 
  /// [limit] 每页数量，默认 20
  /// [cursor] 分页游标，首次加载传 null
  /// 返回文章列表，失败返回空列表
  Future<List<Article>> getArticles({int limit = 20, String? cursor}) async {
    // ...
  }
}
```

---

## 8. 错误处理规范

### 8.1 标准错误处理模式

```dart
/// 所有异步操作必须使用 try-catch
Future<void> loadArticles() async {
  try {
    isLoading.value = true;
    final articles = await _articleService.getArticles();
    this.articles.assignAll(articles);
  } catch (e, stackTrace) {
    LogService.error('加载文章失败', error: e, stackTrace: stackTrace);
    Get.snackbar('错误', '加载文章失败，请重试');
  } finally {
    isLoading.value = false;
  }
}
```
