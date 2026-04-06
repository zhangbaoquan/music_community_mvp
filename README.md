# 🎵 亲亲心情笔记 (Music Community MVP)

> **"听见情绪，写下声音"** — 一个主打 "音乐 + 心情日记" 的纯粹内容社区

[![Flutter Web](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)](https://flutter.dev/)
[![GetX](https://img.shields.io/badge/State-GetX-purple)](https://pub.dev/packages/get)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)](https://supabase.com/)

---

## 📋 项目简介

亲亲心情笔记是一款以**音乐伴随心情记录**为核心体验的轻量级社交社区。用户在记录此刻心情的同时，可以自由搭配一首能够代表当下的原创或喜爱的心境音乐，实现"音乐 + 心情"的双向表达。

- **产品形态**：Flutter Web 单页应用（SPA）
- **项目阶段**：v1.0 已上线运行，v2.0 优化规划中
- **开发模式**：独立开发者单兵作战

## 🏗️ 技术架构总览

| 层级 | 技术选型 | 说明 |
|------|---------|------|
| **前端框架** | Flutter Web (Dart) | 跨端渲染引擎，未来可复用至 iOS/Android |
| **状态管理** | GetX | 响应式状态 + 依赖注入 + 路由管理 |
| **后端服务 (BaaS)** | Supabase | PostgreSQL + Auth + Realtime + Storage |
| **富文本编辑** | flutter_quill | 图文混排心情日记编辑器 |
| **音频播放** | just_audio | 全局跨页面音乐播放引擎 |
| **错误监控** | Sentry | 生产环境异常追踪 |
| **CDN 加速** | 腾讯云 CDN | 国内全链路节点内容分发 |
| **Web 服务器** | Nginx | SPA 路由转发 + 安全防护 + 缓存 |
| **部署方式** | Shell 脚本 (rsync) | deploy.sh 差量推送 + deploy_nginx.sh 热更新 |

### 架构拓扑

```
用户浏览器
  ↓ HTTPS
腾讯云 CDN (边缘加速 + SSL 卸载)
  ↓ 回源
Nginx (SPA 路由 + 安全防护 + 静态缓存)
  ↓ 反向代理
Flutter Web 静态资源 (/var/www/html/)
  ↓ API 调用
Supabase (PostgreSQL + Auth + Realtime + Storage)
```

## 📁 目录结构

```
music_community_mvp/
├── lib/
│   ├── main.dart                    # 应用入口：Supabase 初始化、路由表、主题配置
│   ├── core/                        # 核心基础设施
│   │   ├── app_binding.dart         # GetX 全局依赖注入绑定
│   │   ├── app_scroll_behavior.dart # 自定义滚动行为
│   │   ├── shim_google_fonts.dart   # Google Fonts 垫片层
│   │   ├── fonts/                   # 本地字体文件 (NotoSansSC)
│   │   ├── ui/                      # UI 常量（颜色、间距、主题）
│   │   ├── utils/                   # 工具函数
│   │   └── widgets/                 # 全局通用 Widget
│   ├── data/
│   │   ├── models/                  # 数据模型（6 个）
│   │   │   ├── article.dart         # 文章/日记模型
│   │   │   ├── article_comment.dart # 评论模型
│   │   │   ├── badge.dart           # 成就徽章模型
│   │   │   ├── feedback_model.dart  # 反馈模型
│   │   │   ├── private_message.dart # 私信模型
│   │   │   └── song.dart            # 音乐模型
│   │   └── services/
│   │       └── log_service.dart     # 日志服务
│   ├── features/                    # 功能模块（17 个 Feature）
│   │   ├── about/                   # 关于页面
│   │   ├── admin/                   # 管理后台（用户管理 + 内容审核）
│   │   ├── auth/                    # 用户认证（登录/注册/密码）
│   │   ├── content/                 # 内容引擎（文章CRUD + 富文本编辑器）
│   │   ├── diary/                   # 心情日记
│   │   ├── gamification/            # 游戏化激励（成就徽章系统）
│   │   ├── home/                    # 首页信息流
│   │   ├── layout/                  # 响应式布局框架
│   │   ├── messages/                # 私信系统
│   │   ├── music/                   # 音乐金库（上传/管理）
│   │   ├── notifications/           # 通知系统
│   │   ├── player/                  # 全局音乐播放器
│   │   ├── profile/                 # 个人中心（数据展板 + 资产管理）
│   │   ├── safety/                  # 安全与举报
│   │   ├── search/                  # 搜索
│   │   ├── social/                  # 社交互动（关注/粉丝）
│   │   └── sponsor/                 # 赞助通道
│   └── shared/                      # 共享资源
├── sql/                             # Supabase SQL 迁移文件
├── assets/                          # 静态资源（图片等）
├── web/                             # Web 入口（index.html + Service Worker）
├── docs/                            # 项目文档中心
├── deploy.sh                        # 前端产物部署脚本
├── deploy_nginx.sh                  # Nginx 配置热更新脚本
├── nginx.conf                       # Nginx 完整配置文件
├── AGENTS.md                        # AI 协作行为规则
└── pubspec.yaml                     # 依赖管理
```

## 🔑 核心依赖清单

| 依赖 | 版本 | 用途 |
|------|------|------|
| `get` | ^4.7.3 | 状态管理 + 路由 + 依赖注入 |
| `supabase_flutter` | ^2.12.0 | BaaS 全家桶（Auth/DB/Realtime/Storage） |
| `flutter_quill` | ^11.5.0 | 富文本编辑器引擎 |
| `just_audio` | ^0.10.5 | 音频播放引擎 |
| `google_fonts` | ^6.3.2 | 自定义字体加载 |
| `sentry_flutter` | ^9.14.0 | 生产环境错误监控 |
| `image_picker` | ^1.2.1 | 图片选择器 |
| `timeago` | ^3.7.1 | 时间友好展示（如"3分钟前"） |
| `emoji_picker_flutter` | ^4.4.0 | Emoji 选择器 |
| `confetti` | ^0.8.0 | 成就达成庆祝动画 |

## 🚀 环境搭建与运行

### 前置要求

- Flutter SDK >= 3.8.1
- Dart SDK >= 3.8.1
- 支持的浏览器（Chrome 推荐）

### 本地运行

```bash
# 1. 安装依赖
flutter pub get

# 2. 启动开发服务器
flutter run -d chrome

# 3. 或启动 Web Server 模式
flutter run -d web-server --web-port=3000
```

### 生产构建与部署

```bash
# 构建生产包
flutter build web --release --pwa-strategy=none

# 部署到服务器（需要配置 SSH 密钥）
bash deploy.sh

# 更新 Nginx 配置（需要 SSH 权限）
bash deploy_nginx.sh
```

### 代码检查

```bash
# 静态分析
flutter analyze

# 运行测试
flutter test
```

## 📚 文档索引

| 文档 | 路径 | 说明 |
|------|------|------|
| **PRD v1.0** | `docs/prd/prd-v1.0.md` | 一期已上线功能的产品需求文档 |
| **PRD v2.0** | `docs/prd/prd-v2.0.md` | 二期优化规划的产品需求文档 |
| **开发任务清单 v1.0** | `docs/dev/开发任务清单-v1.0.md` | 一期已完成任务回溯 |
| **开发任务清单 v2.0** | `docs/dev/开发任务清单-v2.0.md` | 二期待做任务清单 |
| **测试清单 v1.0** | `docs/test/测试清单-v1.0.md` | 一期功能回归测试用例 |
| **测试清单 v2.0** | `docs/test/测试清单-v2.0.md` | 二期新功能测试用例 |
| **Changelog** | `docs/Changelog.md` | 变更日志 |
| **TaskBoard** | `docs/TaskBoard.md` | 进度看板（跨会话断点恢复） |
| **产品设计复盘** | `docs/archive/product_design_review.md` | 产品设计与复盘文档 |
| **技术设计方案** | `docs/archive/project_technical_design.md` | 技术架构设计文档 |
| **交接文档** | `docs/archive/project_product_handover_tmp.md` | 项目上下文交接文档 |

## 🤖 AI 协作说明

如果你是 AI 助手，进入本项目后请按以下顺序阅读：

1. **AGENTS.md** — 了解项目的红线规则和代码约束
2. **本 README.md** — 掌握项目全貌和技术架构
3. **docs/TaskBoard.md** — 查看当前进度，实现断点恢复
4. **docs/Changelog.md** — 了解最近的变更历史
5. **根据任务需要**，再深入阅读对应的 PRD、任务清单或测试清单

### 关键约束

- **状态管理**：只用 GetX，禁止引入 Riverpod / Provider / Bloc
- **后端**：只用 Supabase BaaS，不自建后端
- **代码风格**：Controller 与 View 分离，数据调用经过 data/services 层
- **安全**：禁止硬编码密钥或服务器地址到新代码中
- **运维文件**：禁止删除或覆盖 deploy.sh / nginx.conf 等运维文件

## 📄 License

本项目为私有项目，暂不公开发布。
