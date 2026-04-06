# AGENTS.md — 亲亲心情笔记 AI 协作行为规则

> 本文件定义 AI 在参与亲亲心情笔记项目开发时的行为约束和红线规则。
> AI 在每次会话开始时必须阅读本文件，确保所有操作符合项目规范。

---

## 🔴 红线规则（最高优先级，违反即停止）

### 1. 禁止破坏运维文件

以下文件**绝对禁止删除、覆盖或大幅修改**（除非用户明确要求）：
- `deploy.sh` — 前端产物部署脚本
- `deploy_nginx.sh` — Nginx 配置热更新脚本
- `nginx.conf` — Nginx 完整配置文件
- `sql/` 目录下的已有 SQL 文件

### 2. 禁止修改 Supabase 初始化配置

`lib/main.dart` 中的 Supabase 初始化代码（URL + anonKey + headers）**禁止修改**，除非用户明确要求迁移环境。

### 3. 禁止硬编码敏感信息

新增代码中**禁止**硬编码任何：
- API 密钥 / Secret Key
- 服务器 IP 地址
- 数据库连接字符串
- 用户密码

如需添加新的配置项，使用环境变量或配置文件。

### 4. 物理写盘红线

所有要求生成、创建、保存的文档和代码，**必须调用真实的文件读写工具写入磁盘**。严禁仅在对话中展示文本预览而不触发写盘操作。

---

## 📋 技术栈约束

### 状态管理

- **只用 GetX**（get: ^4.7.3）
- **禁止引入** Riverpod、Provider、Bloc 或其他状态管理方案
- 响应式变量统一用 `.obs`
- 路由统一使用命名路由（`GetPage` + `Get.toNamed()`）
- 依赖注入使用 `Get.lazyPut` / `Get.put`

### 后端

- **只用 Supabase BaaS**，不自建后端 API
- 数据库操作通过 Supabase Client SDK
- 实时功能使用 Supabase Realtime Channel
- 文件存储使用 Supabase Storage Bucket

### UI 框架

- Material Design 3（useMaterial3: true）
- 主色调：黑（#1A1A1A）白灰体系
- 字体：Google Fonts Outfit（标题/正文）+ NotoSansSC（中文兜底）
- 滚动行为：使用 AppScrollBehavior

### Dart 语言

- SDK：^3.8.1
- Null Safety：**强制开启**
- 禁止使用 `!` 强制解包（除非有 100% 确定性），优先使用 `?.` 和 `??`

---

## 📁 代码风格约束

### 文件规范

| 规则 | 要求 |
|------|------|
| 单文件上限 | **不超过 300 行**（超过必须拆分为子组件） |
| 文件命名 | snake_case（如 `article_detail_view.dart`） |
| 类名 | PascalCase（如 `ArticleDetailView`） |
| 变量名 | camelCase（如 `articleList`） |

### 架构分层

```
lib/
├── core/           # 基础设施（主题/工具/通用Widget）— 不含业务逻辑
├── data/
│   ├── models/     # 纯数据模型（fromJson / toJson / copyWith）
│   └── services/   # 数据服务层（所有 Supabase 调用必须封装在此）
├── features/       # 功能模块（每个模块独立目录）
│   └── xxx/
│       ├── xxx_controller.dart   # 业务逻辑（GetX Controller）
│       ├── xxx_view.dart         # UI 展示（StatelessWidget / GetView）
│       └── widgets/              # 模块内子组件
└── shared/         # 跨模块共享资源
```

### Controller 职责

- 单个 Controller **只负责一个业务域**，禁止"上帝 Controller"
- Controller 中**禁止直接操作 Supabase**，必须通过 data/services 层
- 所有 Supabase 调用必须有 try-catch，并使用 LogService 记录错误

### Widget 拆分

- 禁止嵌套超过 5 层的 Widget 树
- 复杂 UI 必须提取为独立 Widget 文件
- 每个独立 Widget 文件**必须有文档注释**说明用途

---

## 🗄️ Supabase 数据层规范

### 数据访问

- 所有 Supabase 调用**必须封装在 `data/services/` 层**
- Controller 和 View **禁止直接调用** Supabase Client
- 每个 Supabase 调用**必须有 try-catch**，并使用 `LogService` 记录错误

### RLS 策略

- 新增表或修改 RLS 策略时，**必须先在 `sql/` 目录创建对应的 .sql 文件**
- SQL 文件命名格式：`功能描述.sql`（如 `fix_comments_fk.sql`）

### Realtime 订阅

- Realtime Channel 订阅**必须在 Controller 的 `onClose()` 中取消**
- 避免重复订阅同一 Channel

### Storage 规范

- 上传文件**必须指定 contentType**
- 文件命名**必须包含用户 ID 前缀**防冲突（如 `userId_timestamp.jpg`）

### 查询优化

- **禁止在循环中发起 Supabase 请求**
- 复杂聚合计算**必须使用 RPC**，不在客户端做循环计算
- 禁止使用 `.count()` 客户端调用做统计，改用 RPC

---

## 📝 文档约束

### 变更日志

- 所有代码变更**必须追加** `docs/Changelog.md`
- 格式：日期 + 任务编号 + 简述 + 变更文件 + 变更内容 + 设计决策

### 进度看板

- 完成任务后**必须更新** `docs/TaskBoard.md`
- 标记状态：⬜ 待开始 → 🔄 进行中 → ✅ 已完成

### 开发任务清单

- 完成子任务后，在对应的开发任务清单中标记 `[x]`

---

## 🧭 AI 进入项目的标准流程

1. **读 AGENTS.md**（本文件）— 了解红线规则
2. **读 README.md** — 了解项目全貌
3. **读 docs/TaskBoard.md** — 查看当前进度，定位断点
4. **读 docs/Changelog.md** — 了解最近变更
5. **根据任务需要**，阅读对应的：
   - PRD（`docs/prd/`）— 了解业务规则
   - 开发任务清单（`docs/dev/`）— 了解任务范围
   - 测试清单（`docs/test/`）— 了解验收标准
6. **阅读相关源码文件** — 理解已有实现
7. **动手编码** — 遵循本文件的所有约束

---

## 🚨 应急熔断机制

当出现以下情况时，**必须立即停止并向用户汇报**，禁止继续推进：

- `flutter analyze` 报错超过 3 处
- 新代码导致已有功能异常
- 发现架构设计与 PRD 存在重大偏差
- 涉及 RLS 策略变更但未创建 SQL 文件
- 单文件编辑后超过 300 行
