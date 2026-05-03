# TS-FC-V3-01 导航架构重构 (Navigation Architecture Refactoring)

> 目标版本：v3.0 | 负责人：老张 & AI 首席架构师 | 状态：已定稿

---

## 1. 需求上下文 (Context & Objective)
- **目标**：彻底解决 Flutter Web 端 URL 地址栏同步错乱、浏览器前进/后退键失效以及深层页面死锁的问题。确保应用内所有的实体状态（如特定的歌曲、他人的主页、具体的文章）都有唯一且正确的 URL 映射，支持精准的外部链接分享。
- **非目标 (Non-Goals)**：本次重构仅剥离 GetX 的**路由功能**。项目中现存的**状态管理**（如 `GetXController` 和 `obs`）和**依赖注入**（如 `Get.put`）均保持不变。坚决不引发“把 GetX 连根拔起换成 Riverpod”的灾难级重构。

---

## 2. 当前系统痛点 (Current State & Pain Points)
目前使用 `GetMaterialApp` 管理全局路由，但在主页框架（`MainLayout`）使用了简单的 `IndexedStack` 配合强行注入浏览器 `window.history.replaceState` 的缝合手段：
1. **状态冲突**：GetX 内部的路由栈与 Browser History 是两条平行的线，当用户在底层页点击浏览器原生返回键时，极易发生 `popstate` 竞态崩溃。
2. **栈断层**：因为通过 `replaceState` 欺骗浏览器地址栏，使得主应用的几个 Tab 间切换时不产生真正的历史记录，破坏了 Web 用户的正常交互直觉。
3. **深层传参难**：GetX Web 端路由在处理带有参数的嵌套深层链接（例如 `/article/123/comments`）时存在著名的丢参 BUG。

---

## 3. 方案选型与对比 (Decision)

### 方案 A（决策项）：引入 `go_router` 包接管全局路由
- **说明**：采用 Flutter 官方主推的强声明式路由包 `go_router`。
- **优点**：完美适配 Flutter Web 的 History API；提供原生的 `StatefulShellRoute` 直接替代有缺陷的 `IndexedStack` 实现底部导航栏保留状态的特性。
- **缺点**：迁移成本较高，全项目所有 `Get.toNamed()` 需要被替换为 `context.go()` 或 `context.push()`。

### 方案 B（弃用项）：深挖 GetX Middleware 强缝合
- **说明**：通过编写更复杂的 GetX Middleware 队列，手动接管并拦截 `popstate`。
- **缺点**：与框架对抗，代码极其脆弱。每次 Flutter SDK 大版本升级都有彻底宕机的巨大风险。

### 最终决策 (Decision)
**坚决采用【方案 A】**。长痛不如短痛，彻底剥离 GetX 路由，换取未来的可维护性与极致 Web 体验。

---

## 4. 详细设计 (Detailed Design)

### 4.1 核心路由配置
在 `lib/core/` 下新建 `app_router.dart`，负责声明全站的 GoRouter 树：
```dart
final goRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 使用 StatefulShellRoute.indexedStack 替代目前的 MainLayout 内部实现
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainLayout(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => HomeView())]),
        StatefulShellBranch(routes: [GoRoute(path: '/diary', builder: (c, s) => DiaryView())]),
        // ... 其他主 Tab
      ],
    ),
    // 全局深层页面
    GoRoute(
      path: '/article/:id',
      builder: (context, state) => ArticleDetailView(id: state.pathParameters['id']!),
    ),
  ],
);
```

### 4.2 UI 改造与状态接管
1. `MainLayout` 重构：移除原本内部手写的 `NavigationController`，直接接受 `go_router` 传入的 `navigationShell`，底栏点击事件改为触发 `navigationShell.goBranch(index)`。
2. 顶层替换：`main.dart` 中的 `GetMaterialApp` 替换为 `GetMaterialApp.router`（必须保留 Get，以提供依赖注入上下文），并注入 `goRouter`。

### 4.3 URL 传参改造
原来的 `Get.parameters['id']` 需要全部重构为通过 Widget 的构造函数传参，或者使用 `GoRouterState.of(context).pathParameters` 获取。

---

## 5. 风险评估与兜底 (Risks & Fallbacks)

- **技术风险**：`Get.snackbar` 和 `Get.dialog` 内部严重依赖于 GetX 路由栈的顶层 Context。如果迁移到 `go_router` 后，可能会导致全局弹窗报错（由于找不到对应的 navigator key）。
- **兜底策略**：在注入 `go_router` 时，必须将其 `navigatorKey` 赋给 GetX，或者使用原始的 `ScaffoldMessenger.of(context).showSnackBar` 替换部分有冲突的弹窗。

---

## 6. 实施拆解 (Task Breakdown)
*此部分将直接指导开发阶段。*

- [ ] **Step 1**：引入 `go_router` 依赖 (`flutter pub add go_router`)。
- [ ] **Step 2**：在 `lib/core/router/` 下创建核心路由配置文件，定义出带有 `StatefulShellRoute` 的树状结构。
- [ ] **Step 3**：重构 `MainLayout` 组件，废除自定义的 `NavigationController` 和 `IndexedStack` 逻辑。
- [ ] **Step 4**：重构入口文件 `main.dart`，切换到 `GetMaterialApp.router`。
- [ ] **Step 5**：执行全项目全局搜索 `Get.toNamed`、`Get.back` 等方法，逐一批量替换为 `context.push` 或 `context.pop`。
- [ ] **Step 6**：修正全局弹窗（Dialog/Snackbar）的上下文引用 BUG，确保编译通过并能正常运转。
