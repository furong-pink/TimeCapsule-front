# 时光胶囊系统数据库设计文档

## 数据库概述

- **数据库名称**: timecapsule_db
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci
- **存储引擎**: InnoDB

## 数据表结构

### 1. 用户表 (users)

存储用户基本信息。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 用户ID（主键） |
| account | VARCHAR(100) | 账号（邮箱或手机号，唯一） |
| password | VARCHAR(255) | 密码（加密存储） |
| nickname | VARCHAR(50) | 昵称 |
| avatar | VARCHAR(500) | 头像URL |
| bio | VARCHAR(200) | 个人简介 |
| status | TINYINT | 状态：0-禁用，1-正常 |
| last_login_at | DATETIME | 最后登录时间 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

**索引**:
- PRIMARY KEY (id)
- UNIQUE KEY (account)
- KEY (nickname)
- KEY (created_at)

### 2. 时间胶囊表 (capsules)

存储用户创建的时间胶囊。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 胶囊ID（主键） |
| user_id | BIGINT UNSIGNED | 用户ID（外键） |
| title | VARCHAR(100) | 标题 |
| content | TEXT | 内容 |
| cover_image | VARCHAR(500) | 封面图片URL |
| open_date | DATE | 开启日期 |
| privacy | ENUM | 隐私设置：private-私密，public-公开 |
| enable_reminder | TINYINT | 是否开启提醒：0-关闭，1-开启 |
| status | ENUM | 状态：draft-草稿，published-已发布，opened-已开启 |
| is_opened | TINYINT | 是否已开启：0-未开启，1-已开启 |
| opened_at | DATETIME | 开启时间 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

**索引**:
- PRIMARY KEY (id)
- KEY (user_id)
- KEY (open_date)
- KEY (status)
- KEY (privacy)
- KEY (created_at)

**外键**:
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

### 3. 胶囊媒体文件表 (capsule_media)

存储时间胶囊的媒体文件（图片、视频）。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 媒体ID（主键） |
| capsule_id | BIGINT UNSIGNED | 胶囊ID（外键） |
| file_url | VARCHAR(500) | 文件URL |
| file_type | ENUM | 文件类型：image-图片，video-视频 |
| file_name | VARCHAR(255) | 原始文件名 |
| file_size | BIGINT UNSIGNED | 文件大小（字节） |
| mime_type | VARCHAR(100) | MIME类型 |
| sort_order | INT UNSIGNED | 排序顺序 |
| created_at | DATETIME | 创建时间 |

**索引**:
- PRIMARY KEY (id)
- KEY (capsule_id)
- KEY (sort_order)

**外键**:
- FOREIGN KEY (capsule_id) REFERENCES capsules(id) ON DELETE CASCADE

### 4. 目标表 (goals)

存储用户的个人目标。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 目标ID（主键） |
| user_id | BIGINT UNSIGNED | 用户ID（外键） |
| title | VARCHAR(100) | 目标名称 |
| description | TEXT | 目标描述 |
| type | ENUM | 目标类型：short-term-短期，long-term-长期 |
| target_date | DATE | 期望完成日期 |
| progress | INT UNSIGNED | 完成进度（0-100） |
| status | ENUM | 状态：in_progress-进行中，completed-已完成，cancelled-已取消 |
| enable_reminder | TINYINT | 是否开启提醒：0-关闭，1-开启 |
| completed_at | DATETIME | 完成时间 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

**索引**:
- PRIMARY KEY (id)
- KEY (user_id)
- KEY (status)
- KEY (target_date)
- KEY (created_at)

**外键**:
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

### 5. 成就表 (achievements)

存储系统预设的成就定义。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | INT UNSIGNED | 成就ID（主键） |
| title | VARCHAR(50) | 成就名称 |
| description | VARCHAR(200) | 成就描述 |
| icon | VARCHAR(50) | 图标名称 |
| condition_type | VARCHAR(50) | 解锁条件类型 |
| condition_value | INT UNSIGNED | 解锁条件值 |
| sort_order | INT UNSIGNED | 排序顺序 |
| created_at | DATETIME | 创建时间 |

**条件类型说明**:
- `create_capsule_count`: 创建胶囊数量
- `open_capsule_count`: 开启胶囊数量
- `complete_goal_count`: 完成目标数量
- `share_capsule_count`: 分享胶囊数量
- `consecutive_days`: 连续天数
- `total_achievements`: 总成就数量

**索引**:
- PRIMARY KEY (id)
- KEY (condition_type)
- KEY (sort_order)

### 6. 用户成就关联表 (user_achievements)

存储用户获得的成就记录。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 关联ID（主键） |
| user_id | BIGINT UNSIGNED | 用户ID（外键） |
| achievement_id | INT UNSIGNED | 成就ID（外键） |
| is_new | TINYINT | 是否为新获得：0-否，1-是 |
| achieved_at | DATETIME | 获得时间 |

**索引**:
- PRIMARY KEY (id)
- UNIQUE KEY (user_id, achievement_id)
- KEY (user_id)
- KEY (achievement_id)
- KEY (achieved_at)

**外键**:
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE

### 7. 胶囊草稿表 (capsule_drafts) - 可选

存储用户保存的草稿。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 草稿ID（主键） |
| user_id | BIGINT UNSIGNED | 用户ID（外键） |
| title | VARCHAR(100) | 标题 |
| content | TEXT | 内容 |
| cover_image | VARCHAR(500) | 封面图片URL |
| open_date | DATE | 开启日期 |
| privacy | ENUM | 隐私设置 |
| enable_reminder | TINYINT | 是否开启提醒 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

**索引**:
- PRIMARY KEY (id)
- KEY (user_id)
- KEY (updated_at)

**外键**:
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

### 8. 用户登录日志表 (user_login_logs) - 可选

存储用户登录记录。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT UNSIGNED | 日志ID（主键） |
| user_id | BIGINT UNSIGNED | 用户ID（外键） |
| ip_address | VARCHAR(50) | IP地址 |
| user_agent | VARCHAR(500) | 用户代理 |
| login_at | DATETIME | 登录时间 |

**索引**:
- PRIMARY KEY (id)
- KEY (user_id)
- KEY (login_at)

**外键**:
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

## 数据表关系图

```
users (1) ──< (N) capsules
users (1) ──< (N) goals
users (1) ──< (N) user_achievements
users (1) ──< (N) capsule_drafts
users (1) ──< (N) user_login_logs

capsules (1) ──< (N) capsule_media

achievements (1) ──< (N) user_achievements
```

## 预设成就数据

系统初始化时会插入以下8个预设成就：

1. **初学者** - 创建第一个时间胶囊
2. **记录者** - 创建5个时间胶囊
3. **时间旅行者** - 打开一个过去的时间胶囊
4. **目标达人** - 完成3个个人目标
5. **分享者** - 分享5个公开的时间胶囊
6. **坚持者** - 连续30天创建时间胶囊
7. **成就收集家** - 获得10个成就徽章
8. **完美主义者** - 完成所有目标

## 使用说明

### 1. 创建数据库

```bash
mysql -u root -p < database/design.sql
```

### 2. 或者手动执行

```sql
source database/design.sql;
```

### 3. 验证表结构

```sql
USE timecapsule_db;
SHOW TABLES;
DESCRIBE users;
```

## 注意事项

1. **密码加密**: 用户密码必须使用安全的哈希算法（如 bcrypt）加密存储
2. **文件存储**: 媒体文件建议存储在对象存储服务（如 OSS、S3）中，数据库只存储URL
3. **索引优化**: 根据实际查询场景，可能需要添加复合索引
4. **数据备份**: 建议定期备份数据库，特别是用户数据和时间胶囊内容
5. **软删除**: 如需保留删除记录，可添加 `deleted_at` 字段实现软删除

## 扩展建议

1. **消息通知表**: 用于存储系统通知和提醒
2. **用户关注表**: 用于实现用户之间的关注功能
3. **胶囊评论表**: 用于公开胶囊的评论功能
4. **胶囊点赞表**: 用于公开胶囊的点赞功能
5. **标签表**: 用于胶囊分类和标签功能

