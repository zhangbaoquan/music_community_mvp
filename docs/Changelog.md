# 亲亲心情笔记 — 变更日志（Changelog）

> 记录项目的所有重大变更，用于 AI 跨会话记忆恢复。

---

## [2026-04-14] T27 代码质量提升 — 巨型文件拆分（全部完成）

- **变更文件**：新增 14 个文件，重写 6 个文件
- **变更内容**：
  1. 新建 `ArticleService` 数据服务层，封装所有文章相关 Supabase 调用
  2. 用 mixin 拆分上帝 Controller（article_controller 770→312 行）
  3. View 层移除 Supabase 直调，拆出 6 个子组件到 content/widgets/ 目录
  4. Profile 模块拆出 4 个共享组件到 profile/widgets/ 目录
  5. 所有新代码添加充足的中文注释
- **设计决策**：采用 B 策略（拆分 + 逻辑下沉），不仅是机械拆分文件，同时修正了 View 层的架构违规
- **关联任务**：T27-1/2/3/4/5/6 全部完成

---


## [2026-04-10] BUG-002 — URL 路由同步修复

- **变更文件**：`lib/features/layout/main_layout.dart`、`lib/main.dart`、`lib/features/home/home_view.dart`
- **变更内容**：
  1. NavigationController 增加 Tab↔URL 双向同步（Browser History API pushState/popstate）
  2. 6 个主 Tab 路由注册到 getPages，支持地址栏直达
  3. 修复启动时硬编码跳转 /home，改为尊重用户输入的 URL
  4. 主页广场/专栏 Tab 也追踪到 URL（?tab=articles）
- **设计决策**：采用方案 B（Browser History API 同步），保持 IndexedStack 架构不变，页面状态零丢失

---

## [2026-04-09] BUG-001 — 首屏加载性能优化

- **变更文件**：`web/index.html`、`lib/main.dart`、`lib/core/app_binding.dart`、`lib/features/profile/profile_controller.dart`
- **变更内容**：
  1. 移除 AppStartupScreen 中 1500ms 的人为延迟（早期竞态条件 workaround，已无必要）
  2. 非关键 Controller（Player/Profile/Article）改为 `Get.lazyPut` 延迟加载
  3. ProfileController.loadProfile() 中 7 个串行 Supabase 查询改为 `Future.wait()` 并行执行
  4. index.html 添加 viewport meta、Loading 文案从"1-2分钟"改为"正在准备你的音乐空间"
- **设计决策**：Flutter Web WASM 引擎下载（~15-30s）为不可控的固有成本，本次优化聚焦 Dart 层可控部分，预计压缩 Dart 启动耗时从 ~5s 至 ~1s

---

## [2026-04-06] Agent 资产体系建设

- **变更内容**：建立完整的 Agent 资产体系（README / docs / PRD / 任务清单 / 测试清单 / AGENTS.md / Workflows / Skills）
- **设计决策**：采用 Luban 项目验证有效的三层资产体系（基础设施层 + SOP 流程层 + 质量护栏层），根据亲亲音乐的 Flutter + Supabase 技术栈做定制迁移

---

## [2026-04-06] Workflows 项目内注册

- **变更文件**：`.agent/workflows/music-dev-task.md`（新增）、`.agent/workflows/music-test-report.md`（新增）
- **变更内容**：将 Workflows 从 AI_Study 项目复制到 music_community_mvp/.agent/workflows/ 目录下，使 `/music-dev` 和 `/music-test` 指令可在项目内部直接触发
- **设计决策**：原 Workflows 仅存放在 AI_Study/workflows/ 中，当 AI 仅在 music_community_mvp 工作区工作时无法自动发现。采用副本方式而非符号链接，确保项目独立可用

---

## [2025-xx] v1.0 代码质量清理

- **变更内容**：系统性清理静态分析警告和 deprecation
- **变更文件**：多个 Controller 和 View 文件
- **涉及项**：修复 unused imports、deprecated 方法、web interop 更新等

---

## [2025-xx] Sentry 错误监控集成

- **变更内容**：集成 sentry_flutter 生产环境错误监控
- **变更文件**：`lib/main.dart`, `pubspec.yaml`
- **设计决策**：配置 SentryNavigatorObserver 追踪路由遥测，ErrorWidget.builder 自定义错误展示

---

## [2025-xx] Supabase SDK 兼容修复

- **变更内容**：修复 `.count(CountOption.exact)` 返回值类型变更导致的崩溃
- **变更文件**：`lib/features/profile/profile_controller.dart`
- **设计决策**：Supabase SDK 更新后 `.count()` 返回值从类对象变为纯 `int`，直接切割赋值语句避免系统 Panic

---

## [2025-xx] HTTPS 架构迁移（腾讯云 CDN）

- **变更内容**：从 Cloudflare 迁移至腾讯云 CDN 全链路加速
- **变更文件**：`nginx.conf`, DNS 配置
- **设计决策**：
  - Cloudflare 海外节点受 GFW 随机阻断，导致 `ERR_CONNECTION_CLOSED` 频发
  - 迁移方案：Cloudflare 仅保留 DNS 解析（关闭橙色云）→ 腾讯云 CDN 接管加速 → TrustAsia SSL 证书前置卸载
  - 重写 Nginx `set_real_ip_from` 白名单，从 CF IP 切换为腾讯云 CDN IP

---

## [2025-xx] Nginx 安全加固

- **变更内容**：配置 Web 攻击防护矩阵
- **变更文件**：`nginx.conf`
- **涉及项**：
  - `limit_req_zone` IP 频控（防爬虫/暴力破解）
  - `limit_conn_zone` 并发连接限制（防 TCP 饱和攻击）
  - User-Agent 黑名单（拦截自动扫描爬虫）

---

## [2025-xx] 首屏加载优化

- **变更内容**：解决 Flutter Web 首屏白屏/黑屏问题
- **变更文件**：`web/index.html`, `lib/main.dart`
- **设计决策**：
  - 植入极简 CSS Loading 骨架动画
  - 使用 `dart:js` 互操作在首帧渲染完毕后安全销毁 JS Loading 遮罩
  - 移除默认 PWA Service Worker，采用版本号清缓存策略

---

## [2025-xx] v1.0 项目启动

- **变更内容**：初始化 Flutter Web 项目
- **涉及项**：
  - 引入 GetX + Supabase 技术栈
  - 搭建 core / data / features / shared 目录结构
  - 配置 17 个 Feature 模块框架
  - 部署生产环境（北京 BGP 节点 + Nginx）
