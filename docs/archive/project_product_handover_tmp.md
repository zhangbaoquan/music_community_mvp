# 亲亲心情笔记 (Music Community MVP) - 项目全局上下文交接文档

## 1. 核心产品定位与全栈架构
*   **产品定位**：一个主打“音乐+心情日记”理念的纯粹内容社区。主推独立开发者一人建站、轻后端及沉浸式体验。
*   **前端选型**：Flutter Web + GetX。兼顾高度统一的跨浏览器渲染及极具潜力的跨移动端伸缩拓展力，提供全局音频后台挂载能力（`PlayerController`）及流媒体瀑布流。
*   **核心功能组件**：
    *   利用 `flutter_quill` 实现包含图片富文本日记核心。
    *   内建基础管理员权限模块（Admin Panel）、游戏化微章模块（Badge System）。
*   **后端支撑 (BaaS)**：Supabase (PostgreSQL 基础引擎)。高度倚重其 RLS (Row Level Security) 鉴权安全、对象存储 S3，以及 WebSocket 驱动的 Realtime 引擎（支撑实时评论区等业务网）。

## 2. Web 核心重难点排坑记（架构变迁历史）
*   **首屏体验拯救行动**：摒弃传统强缓存 PWA Service Worker。植入极简 CSS 加快白屏 FCP 渲染，利用 Dart 到 JS 互操作，在框架帧起飞的刹那顺滑移除 Loader 动画，提供极致首屏体感。
*   **HTTPS 与高并发网络分发防卫战**：
    *   *遭遇战*：前期采取直连 HTTPS 和 Cloudflare 方案，遭遇严重的国际出口防火墙 (GFW) 封杀及神秘的网关握手错误 `ERR_CONNECTION_CLOSED`。
    *   *决胜演进架构*：全面拥抱本地云骨干网络调度。撤销 Cloudflare 流量代理代理（仅依赖其硬解根域名的高级 CNAME Flattening 特性作纯 DNS） ➜ 全面切换**腾讯云 CDN 泛边缘加速节点**部署 ➜ 通过 Let's Encrypt / TrustAsia 通配证书完成 CDN 前置 SSL 卸载。
    *   *网关追猎计划*：通过分析底层 CDN 的请求 Header 透传链路（寻找 `X-Forwarded-For`），重构了部署在国内计算节点的应用层 Nginx 防火墙规则（删掉原有 CF IP 白名单，更新安全拦截准入及针对 TCP 等级恶意抓取的并发 `limit_conn` 锁死策略），完全溯源出 C端真实操作 IP。
*   **API 阻断与框架依赖降级风波**：
    *   排查并紧急处理由于 Supabase 官方 SDK（由于 Flutter 本地 pub 版本更新差异），由 `.count(CountOption.exact)` 所引发的底层返回值改变报错（从类对象变成了直切纯 `int` 基础结构）。直接在 [profile_controller.dart](cci:7://file:///Users/zhangbaoquan/Documents/Work/Porject/music_community_mvp/lib/features/profile/profile_controller.dart:0:0-0:0) 切割赋值语句避免系统 Panic。

## 3. 运维流向及自动化管线
使用 [deploy.sh](cci:7://file:///Users/zhangbaoquan/Documents/Work/Porject/music_community_mvp/deploy.sh:0:0-0:0) (前端产物差量打包推流) 与 [deploy_nginx.sh](cci:7://file:///Users/zhangbaoquan/Documents/Work/Porject/music_community_mvp/deploy_nginx.sh:0:0-0:0) (云服务网关安全热更新不掉线流) 代替笨重的 CI/CD 机器狗，实施一人敏捷开发作战。

## 4. 遗留缺陷及 Todo 技术债池（新会话待解决重点任务）
1.  **致命查询修正重审（高优）**：虽然 Supabase Count 报错被处理并热加载在脚本层分析，还需在全新端最终校验并彻底发布该更新，确保云端用户 Profile （粉丝数、访客图谱）的数字链路健康恢复。
2.  **前端载入优化池（亟待介入）**：应用尚缺骨架屏 (Skeleton UI) 和列表游标算法拉取逻辑 (Cursor Pagination)，目前暴力拉取全量 List 可能会在日落或高并发期引爆 WebVM 内存。
3.  **富媒体资源压缩链路缺失**：现所有图片和音频文件作为原稿直接在云存储流转。需在前端管道流引入 `flutter_image_compress` 甚至将音轨切片减负。
4.  **云端 SQL 切片聚合 (Postgres RPC) 探索**：目前的获赞数、历史评论数严重依赖前端客户端轮询调用多次计算拼接拼盘；为了解决单节点拥塞，我们需要将所有这种大统计工作前置绑定由于后端发行的 RPC 逻辑视图处理上。
