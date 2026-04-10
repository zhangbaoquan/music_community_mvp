# 亲亲心情笔记 — 代码变更记录（Code Change Log）

> 记录每次代码修改的详细上下文：改了哪些文件、为什么改、怎么改、自测是否通过。
> 新条目始终追加在最顶部（最新的在最上面），不要修改或删除已有的历史条目。

---

## [2026-04-10] BUG-002 URL 路由不随页面切换更新

- **修改文件**：
  - [修改] `lib/features/layout/main_layout.dart`
  - [修改] `lib/main.dart`
  - [修改] `lib/features/home/home_view.dart`
- **原因**：v1.0 回归测试发现所有 Tab 切换后浏览器 URL 始终停留在 `/#/home`，导致浏览器前进/后退失效、无法通过 URL 直达特定 Tab。根因是 `NavigationController.changePage()` 仅修改内存中的 `selectedIndex`，从未通知浏览器更新 URL。
- **修复方案**（方案 B — Browser History API 同步）：
  1. `main_layout.dart`：重构 `NavigationController`，新增 Tab↔URL 双向映射表（0:/home, 1:/diary, 2:/profile, 3:/search, 4:/messages, 5:/about）。`changePage()` 调用时通过 `window.history.pushState()` 同步 URL；`onInit()` 读取当前 URL 设置初始 Tab；监听 `popstate` 事件处理浏览器前进/后退。
  2. `main.dart`：在 `getPages` 中为 `/diary`、`/profile`、`/search`、`/messages`、`/about` 注册独立路由（均指向 `MainLayout()`），支持地址栏直达。同时修复 `_checkAuthAndRedirect()` 不再硬编码跳转 `/home`，改为读取当前 URL hash 做智能跳转。
  3. `home_view.dart`：将 `ContentTabView` 从 `StatelessWidget + DefaultTabController` 改为 `StatefulWidget + 手动 TabController`，监听 Tab 切换事件同步 URL（心情广场→`/#/home`，专栏文章→`/#/home?tab=articles`），支持浏览器前进/后退在广场/专栏间切换。
- **设计决策**：选择方案 B（Browser History API）而非方案 A（每个 Tab 独立 GetPage 路由），因为后者会销毁/重建页面导致状态丢失（滚动位置、已加载数据等）。方案 B 保持 IndexedStack 架构不变，零风险。
- **自测结果**：`flutter analyze` 通过，0 error / 0 warning，118 条 info 全为已有的 avoid_print。

---

## [2026-04-09] BUG-001 首屏加载性能优化（Dart 层）

- **修改文件**：
  - [修改] `web/index.html`
  - [修改] `lib/main.dart`
  - [修改] `lib/core/app_binding.dart`
  - [修改] `lib/features/profile/profile_controller.dart`
- **原因**：v1.0 回归测试发现首屏加载耗时约 40s。经分析，Flutter WASM/CanvasKit 引擎下载（~15-30s）为不可控固有成本，但 Dart 应用层存在 3 处可控瓶颈：(1) AppStartupScreen 中 1500ms 的人为延迟；(2) AppBinding 中 6 个 Controller 全部同步立即初始化；(3) ProfileController.loadProfile() 中 7 个 Supabase 查询完全串行执行。
- **修复方案**：
  1. `main.dart`：删除 `_initServices()` 中的 `Future.delayed(1500ms)`，该延迟是早期为规避 GetX Controller 竞态条件加的 workaround，现在 AppBinding 使用同步 `Get.put()`，Controller 在 `dependencies()` 完成时即可用，延迟已无必要。
  2. `app_binding.dart`：将 `PlayerController`、`ProfileController`、`ArticleController` 从 `Get.put(permanent: true)` 改为 `Get.lazyPut(fenix: true)`，首屏渲染不再阻塞等待这三个 Controller 的 `onInit()` 数据加载。关键路径的 `LogService`、`AuthController`、`SafetyService` 保留 `Get.put` 立即注册。
  3. `profile_controller.dart`：`loadProfile()` 中的 `fetchUserStats()`、`fetchUserReceivedStats()`、`fetchCollectedArticles()`、`fetchBadges()` 从串行 await 改为 `Future.wait()` 并行执行；`fetchUserStats()` 内部的 followers/following/visitors 三个查询也从串行改为 `Future.wait()` 并行。
  4. `index.html`：添加 `<meta name="viewport">` 确保移动端渲染；Loading 副文案从"(首次加载可能需要 1-2 分钟)"改为"✨ 正在准备你的音乐空间"。
- **自测结果**：`flutter analyze` 通过，118 条 info（全为已有的 avoid_print），无 error/warning，无新增问题。

---

## [2026-04-08] BUG-005 退出登录后消息中心红点残留

- **修改文件**：
  - [修改] `lib/features/notifications/notification_service.dart`
- **原因**：退出登录后，`NotificationService` 中的 `unreadCount` 和 `notifications` 列表未被清零。`MessageController` 已正确监听 Auth 状态变化并在 `signedOut` 时清空数据，但 `NotificationService` 缺少同样的监听逻辑，导致被动通知（点赞/评论/关注）的未读计数在退出后依然保留在内存中，侧栏和底栏红点持续显示。
- **修复方案**：
  1. 新增 `StreamSubscription<AuthState>` 成员，在 `onInit` 中监听 `onAuthStateChange`。
  2. 在 `signedOut` 事件触发时调用 `clearNotifications()` 方法，强制将 `notifications` 清空、`unreadCount` 归零。
  3. 在 `signedIn` 事件触发时重新调用 `fetchNotifications()` 拉取新用户的通知数据。
  4. 在 `onClose()` 中取消订阅，防止内存泄漏。
- **自测结果**：代码编译通过，逻辑与 `MessageController` 的清理策略保持一致。

---

## [2026-04-08] BUG-004 手机端底栏「驿站」「日记」点击无效

- **修改文件**：
  - [修改] `lib/features/layout/main_layout.dart`
- **原因**：`BottomNavigationBar` 的 `onTap` 回调中，只编写了 `index == 2`（我的）和 `index == 3`（消息）的分支逻辑，完全遗漏了 `index == 0`（驿站）和 `index == 1`（日记）的处理。点击前两个 Tab 时事件被静默吞掉，`navCtrl.changePage()` 从未被调用，页面不切换。
- **修复方案**：
  在 `onTap` 回调开头补齐两个缺失的分支：
  ```dart
  if (index == 0) {
    navCtrl.changePage(0);
  } else if (index == 1) {
    navCtrl.changePage(1);
  } else if (index == 2) { ...
  ```
- **自测结果**：代码编译通过。四个底栏 Tab 在逻辑层面均已正确映射到对应页面索引。

---
