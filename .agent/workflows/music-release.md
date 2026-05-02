---
description: 执行一键打包发布流程（生成 Release Note, 打包 web 产物, 同步服务器, 版本归档）
---

# 亲亲音乐 上线发布工作流

当用户通过 `/music-release` 触发本工作流时，进入正式发版部署流程。

## 触发方式

**指令格式**：`/music-release [版本号] [可选更新说明]`

| 指令示例 | 含义 |
|---------|------|
| `/music-release v2.0` | 发布 v2.0 正式版 |
| `/music-release v2.1-hotfix` | 发布 v2.1 热修复版本 |

---

## 执行步骤

### 阶段 1：发布前检查 (Pre-flight Checks)

1. **检查分支和构建状态**
   - 运行静态代码扫描：`flutter analyze`
   - 确保没有任何影响编译的红线警告。

2. **状态核验**
   - 阅读 `docs/TaskBoard.md` 确认本期计划上线的任务都已经标记为✅。
   - 确认测试流程 `docs/test_reports/` 是否有近期尚未通过的缺陷 (P0/P1)。

### 阶段 2：生成版本更新说明 (Release Notes)

3. **汇总内容**
   - 读取 `docs/Changelog.md` 中最近的一批相关更新，梳理成向外部发布的日志。
   - 归纳总结出一个结构清晰的 Release Note 文本（作为部署后的输出）。

### 阶段 3：构建与部署 (Build & Deploy)

4. **发版构建**
   - 运行构建命令产生 web 产物：`flutter build web --release --pwa-strategy=none`
   - 等待产物生成到 `build/web/` 目录。
   - *(如果在执行途中出错，立即熔断向用户汇报)*

5. **执行同步部署脚本**
   - 明确提示用户确认后再执行触发自动化同步脚本：`bash deploy.sh`。
   - *（如果是本地测试环境没有配置线上服务器的 ssh 密钥可能会失败，遇到报错可停止并提示用户：已完成构建，可手动部署产物）*

### 阶段 4：版本归档 (Milestone Archive) 🆕

> **目的**：将当前版本的历史上下文归档封存，为下一版本创建干净的起点，
> 避免随着版本迭代 Token 预读成本无限增长（详见 Token 消耗分析）。
>
> **触发条件**：仅在**大版本发布**（如 v1.0→v2.0、v2.0→v3.0）时执行。
> Hotfix 小版本（如 v2.1-hotfix）**不执行**归档。

6. **创建归档目录**
   ```
   docs/archive/v{当前版本}/
   ```
   例如发布 v2.0 后：`docs/archive/v2.0/`

7. **归档 CodeChangeLog**
   - 将 `docs/CodeChangeLog.md` **整体复制**为 `docs/archive/v{版本}/CodeChangeLog-v{版本}.md`
   - 清空 `docs/CodeChangeLog.md`，仅保留文件头：
   ```markdown
   # 代码变更记录（Code Change Log）

   > 本文件记录 v{下一版本} 开发期间的详细代码变更。
   > v{当前版本} 及更早版本的变更记录已归档至 `docs/archive/v{版本}/`。

   ---
   ```

8. **归档 Changelog**
   - 将 `docs/Changelog.md` **整体复制**为 `docs/archive/v{版本}/Changelog-v{版本}.md`
   - 清空 `docs/Changelog.md`，仅保留文件头：
   ```markdown
   # 变更日志（Changelog）

   > 本文件记录 v{下一版本} 开发期间的变更摘要。
   > v{当前版本} 及更早版本的变更日志已归档至 `docs/archive/v{版本}/`。

   ---
   ```

9. **归档测试清单**
   - 将 `docs/test/测试清单-v{版本}.md` **复制**到 `docs/archive/v{版本}/`
   - 该文件保留原位（下一版本的清单会是新文件，如 `测试清单-v3.0.md`）

10. **归档开发任务清单**
    - 将 `docs/dev/开发任务清单-v{版本}.md` **复制**到 `docs/archive/v{版本}/`
    - 该文件保留原位（下一版本的清单会是新文件，如 `开发任务清单-v3.0.md`）

11. **精简 TaskBoard**
    - 将 TaskBoard 中已标记 `✅ 已完成` 且属于当前版本的任务行，**折叠为一行摘要**：
    ```markdown
    ## v{版本} — 已上线 ✅
    > 共完成 N 个任务，详见 `docs/archive/v{版本}/`
    ```

12. **归档确认**
    - 向用户汇报归档结果：
      - 归档了哪些文件
      - 下一版本的活跃文档已清空
      - 预估下一版本的预读 Token 成本

### 阶段 5：交付与汇报

13. 部署结束后，给用户展示完整的《发版成功报告》，包含：
    - 📦 打包结果：`build/web` 数据总结
    - 🚀 部署状态：推送成功与否
    - 📝 发版日志：归纳好的 Release Notes
    - 📁 归档状态：版本归档是否完成（仅大版本）

---

## 归档目录结构示例

执行 v2.0 发布归档后，`docs/archive/` 目录结构：

```
docs/archive/
├── v2.0/
│   ├── CodeChangeLog-v2.0.md      ← v1.0~v2.0 期间所有代码变更
│   ├── Changelog-v2.0.md          ← v1.0~v2.0 期间变更摘要
│   ├── 测试清单-v2.0.md           ← v2.0 测试用例（含结果）
│   └── 开发任务清单-v2.0.md       ← v2.0 开发任务（含完成状态）
├── product_design_review.md       ← 早期归档文件（已有）
├── project_product_handover_tmp.md
└── project_technical_design.md
```

---

## 归档后的预读变化

| 文件 | 归档前（v2.0 末期） | 归档后（v3.0 初期） |
|------|-------------------|-------------------|
| CodeChangeLog.md | ~15 KB → ~45 KB | ~0.5 KB（仅文件头） |
| Changelog.md | ~6 KB → ~15 KB | ~0.5 KB（仅文件头） |
| 测试清单 | v2.0 清单（~11 KB） | v3.0 新清单（~2 KB） |
| 开发任务清单 | v2.0 清单（~7 KB） | v3.0 新清单（~2 KB） |
| **预读总成本** | **~25,000 Token** | **~12,000 Token** |

---

## 注意事项

- **归档是复制+清空，不是删除**。旧版本数据始终保留在 `docs/archive/` 中，需要时可随时查阅。
- **排查历史 BUG 时**，AI 可按需读取 `docs/archive/v{版本}/CodeChangeLog-v{版本}.md`，无需每次都加载。
- **归档操作不可逆**，执行前必须确认用户同意。
