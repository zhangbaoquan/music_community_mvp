---
name: 变更日志写作规范 (Change-Level Archiving)
description: 定义项目中每次代码变更后生成独立 Change 文件的格式与质量标准，基于 OpenSpec 理念实现变更级归档，避免单体日志导致 Token 爆炸。
---

## Skill 用途
这个 Skill 用来规范变更日志的撰写流程和输出质量。从 v3.0 开始，项目**彻底废弃**向单一 `Changelog.md` 追加记录的做法，改用**变更级归档（Change-Level Archiving）**。每次任务完成后，必须生成一个独立的 markdown 文件。

# 为什么存在
传统的单体 `Changelog.md` 随着版本推进会无限膨胀，导致 AI 预读成本过高且容易引发上下文截断（"失忆"）。
采用 `docs/changes/` 目录制后，每完成一个任务即刻生成一份独立档案。AI 日常开发无需预读整个历史，只有在排查特定功能的 BUG 时才按需加载特定的变更记录。

# 适用范围
- 在完成一组代码变更后，保存变更纪要的场景。
- 输入：本次变更的任务编号、修改的文件列表、具体内容、设计决策。
- 输出：在 `docs/changes/` 目录下生成一个全新的独立 markdown 文件。

## 禁止项
- 🚫 **禁止**将变更记录追加到 `docs/Changelog.md` 或 `docs/CodeChangeLog.md` 中。
- 禁止模糊描述（必须指明文件和具体修改了哪一行逻辑）。
- 禁止省略设计决策（特别是架构层面的取舍）。

## 执行约束

### 文件命名规范
文件必须严格按照以下格式命名：
`docs/changes/YYYYMMDD-[任务编号]-[简短英文或拼音描述].md`
例如：`docs/changes/20260502-T28-1-nav-refactor.md`

### 文件内容结构模板
新建的文件必须包含以下核心内容：

```markdown
# [任务编号] — [一句话简述]

- **日期**：YYYY-MM-DD
- **状态**：✅ 已完成

## 1. 变更文件列表
- `[新增]` path/to/new_file.dart
- `[修改]` path/to/modified_file.dart
- `[删除]` path/to/deleted_file.dart

## 2. 变更内容详情
- 详细说明修改了哪些核心逻辑（如：重写了 `NavigationController` 的 `onInit` 方法，移除了对 `BrowserHistory` 的底层拦截）。

## 3. 设计决策 (Trade-offs)
- 说明为什么这样做。例如：在方案 A 和方案 B 之间为什么选择了 B？是否引入了新的状态管理逻辑？这为以后的 Debug 提供了关键线索。
```

### 归档与引用
- 当版本发布执行 `/music-release` 时，`docs/changes/` 目录下的相关文件可以随版本归档打包，以保持活跃目录整洁。
