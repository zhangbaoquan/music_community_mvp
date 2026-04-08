---
name: Supabase 数据库迁移规范
description: 规范如何安全可靠地进行 Supabase 数据库表结构变更、RLS 策略编写与迁移文件的管理。
---

# Supabase RLS & Migration Skill

本 Skill 规范了项目中涉及数据库表结构变更、Row Level Security (RLS) 策略变更时的操作步骤和代码标准，防止“删库跑路”或大面积的数据权限漏洞。

## 1. 迁移文件规范

所有的数据库修改（建表、加字段、加 RLS 策略、写 RPC）**绝对禁止**脱离代码库直接在 Supabase Dashboard 盲操。

必须在 `sql/` 目录下创建对应的迁移文件：

- 文件命名：描述性强的字母组/下划线命名法。如 `001_create_private_messages.sql` 或 `add_mood_tags_to_songs.sql`
- 注释头部：必须写明修改意图、操作的影响范围。

```sql
-- ============================================
-- 描述：为 songs 表增加 mood_tags 情绪标签字段
-- 影响：向后兼容，不影响现有行
-- ============================================

ALTER TABLE public.songs
ADD COLUMN IF NOT EXISTS mood_tags TEXT[];
```

## 2. RLS 策略编写规范

写 RLS 时最容易犯的错误是“循环依赖”或“权限漏洞”。请严格遵守以下模板和原则：

1. **默认开启**：新建表必须带上 `ALTER TABLE xxx ENABLE ROW LEVEL SECURITY;`
2. **读权限分离**：明确是对所有人可读，还是仅对自己可读？
    - 所有人可读：`USING (true)`
    - 认证用户可读：`USING (auth.role() = 'authenticated')`
    - 自己可读：`USING (auth.uid() = user_id)`
3. **写权限分离**：新增（INSERT）、修改（UPDATE）、删除（DELETE）必须明确限制为数据拥有者。

**模板示例**：

```sql
-- 开启 RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- 【读】所有人都能看
CREATE POLICY "Public profiles are viewable by everyone."
ON public.posts FOR SELECT
USING ( true );

-- 【增】只能用户自己创建
CREATE POLICY "Users can create their own post."
ON public.posts FOR INSERT
WITH CHECK ( auth.uid() = user_id );

-- 【改】只能修改自己的
CREATE POLICY "Users can update their own post."
ON public.posts FOR UPDATE
USING ( auth.uid() = user_id );

-- 【删】只能删除自己的
CREATE POLICY "Users can delete their own post."
ON public.posts FOR DELETE
USING ( auth.uid() = user_id );
```

## 3. 防踩坑指南

1. **不要 DROP 表**：如果需修改表，用 `ALTER TABLE`。直接 `DROP TABLE` 会丢失有价值的线上数据。
2. **关于 `auth.uid()`**：在 Supabase 中，身份验证的核心是 `auth.uid()`，策略编写基本都围绕它和业务表中的 `user_id` 字段做校验。
3. **安全更新 RLS**：如果是修改现有 RLS，使用 `DROP POLICY IF EXISTS "policy_name" ON table_name;` 后再 `CREATE POLICY`。
