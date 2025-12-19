-- ============================================
-- 时光胶囊系统数据库设计
-- Database: timecapsule_db
-- ============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS timecapsule_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE timecapsule_db;

-- ============================================
-- 1. 用户表 (users)
-- ============================================
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `account` VARCHAR(100) NOT NULL COMMENT '账号（邮箱或手机号）',
  `password` VARCHAR(255) NOT NULL COMMENT '密码（加密存储）',
  `nickname` VARCHAR(50) NOT NULL COMMENT '昵称',
  `avatar` VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  `bio` VARCHAR(200) DEFAULT NULL COMMENT '个人简介',
  `status` TINYINT DEFAULT 1 COMMENT '状态：0-禁用，1-正常',
  `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_account` (`account`),
  KEY `idx_nickname` (`nickname`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================
-- 2. 时间胶囊表 (capsules)
-- ============================================
CREATE TABLE `capsules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '胶囊ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `title` VARCHAR(100) NOT NULL COMMENT '标题',
  `content` TEXT NOT NULL COMMENT '内容',
  `cover_image` VARCHAR(500) DEFAULT NULL COMMENT '封面图片URL',
  `open_date` DATE NOT NULL COMMENT '开启日期',
  `privacy` ENUM('private', 'public') DEFAULT 'private' COMMENT '隐私设置：private-私密，public-公开',
  `enable_reminder` TINYINT DEFAULT 1 COMMENT '是否开启提醒：0-关闭，1-开启',
  `status` ENUM('draft', 'published', 'opened') DEFAULT 'published' COMMENT '状态：draft-草稿，published-已发布，opened-已开启',
  `is_opened` TINYINT DEFAULT 0 COMMENT '是否已开启：0-未开启，1-已开启',
  `opened_at` DATETIME DEFAULT NULL COMMENT '开启时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_open_date` (`open_date`),
  KEY `idx_status` (`status`),
  KEY `idx_privacy` (`privacy`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_capsules_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='时间胶囊表';

-- ============================================
-- 3. 胶囊媒体文件表 (capsule_media)
-- ============================================
CREATE TABLE `capsule_media` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '媒体ID',
  `capsule_id` BIGINT UNSIGNED NOT NULL COMMENT '胶囊ID',
  `file_url` VARCHAR(500) NOT NULL COMMENT '文件URL',
  `file_type` ENUM('image', 'video') NOT NULL COMMENT '文件类型：image-图片，video-视频',
  `file_name` VARCHAR(255) DEFAULT NULL COMMENT '原始文件名',
  `file_size` BIGINT UNSIGNED DEFAULT NULL COMMENT '文件大小（字节）',
  `mime_type` VARCHAR(100) DEFAULT NULL COMMENT 'MIME类型',
  `sort_order` INT UNSIGNED DEFAULT 0 COMMENT '排序顺序',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_capsule_id` (`capsule_id`),
  KEY `idx_sort_order` (`sort_order`),
  CONSTRAINT `fk_capsule_media_capsule_id` FOREIGN KEY (`capsule_id`) REFERENCES `capsules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='胶囊媒体文件表';

-- ============================================
-- 4. 目标表 (goals)
-- ============================================
CREATE TABLE `goals` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '目标ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `title` VARCHAR(100) NOT NULL COMMENT '目标名称',
  `description` TEXT DEFAULT NULL COMMENT '目标描述',
  `type` ENUM('short-term', 'long-term') DEFAULT 'short-term' COMMENT '目标类型：short-term-短期，long-term-长期',
  `target_date` DATE NOT NULL COMMENT '期望完成日期',
  `progress` INT UNSIGNED DEFAULT 0 COMMENT '完成进度（0-100）',
  `status` ENUM('in_progress', 'completed', 'cancelled') DEFAULT 'in_progress' COMMENT '状态：in_progress-进行中，completed-已完成，cancelled-已取消',
  `enable_reminder` TINYINT DEFAULT 1 COMMENT '是否开启提醒：0-关闭，1-开启',
  `completed_at` DATETIME DEFAULT NULL COMMENT '完成时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_target_date` (`target_date`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_goals_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='目标表';

-- ============================================
-- 5. 成就表 (achievements) - 系统预设成就
-- ============================================
CREATE TABLE `achievements` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '成就ID',
  `title` VARCHAR(50) NOT NULL COMMENT '成就名称',
  `description` VARCHAR(200) NOT NULL COMMENT '成就描述',
  `icon` VARCHAR(50) NOT NULL COMMENT '图标名称',
  `condition_type` VARCHAR(50) NOT NULL COMMENT '解锁条件类型：create_capsule_count-创建胶囊数，open_capsule_count-开启胶囊数，complete_goal_count-完成目标数，share_capsule_count-分享胶囊数，consecutive_days-连续天数，total_achievements-总成就数',
  `condition_value` INT UNSIGNED NOT NULL COMMENT '解锁条件值',
  `sort_order` INT UNSIGNED DEFAULT 0 COMMENT '排序顺序',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_condition_type` (`condition_type`),
  KEY `idx_sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='成就表';

-- ============================================
-- 6. 用户成就关联表 (user_achievements)
-- ============================================
CREATE TABLE `user_achievements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '关联ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `achievement_id` INT UNSIGNED NOT NULL COMMENT '成就ID',
  `is_new` TINYINT DEFAULT 1 COMMENT '是否为新获得：0-否，1-是',
  `achieved_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '获得时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_achievement` (`user_id`, `achievement_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_achievement_id` (`achievement_id`),
  KEY `idx_achieved_at` (`achieved_at`),
  CONSTRAINT `fk_user_achievements_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_achievements_achievement_id` FOREIGN KEY (`achievement_id`) REFERENCES `achievements` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户成就关联表';

-- ============================================
-- 7. 胶囊草稿表 (capsule_drafts) - 可选
-- ============================================
CREATE TABLE `capsule_drafts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '草稿ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `title` VARCHAR(100) DEFAULT NULL COMMENT '标题',
  `content` TEXT DEFAULT NULL COMMENT '内容',
  `cover_image` VARCHAR(500) DEFAULT NULL COMMENT '封面图片URL',
  `open_date` DATE DEFAULT NULL COMMENT '开启日期',
  `privacy` ENUM('private', 'public') DEFAULT 'private' COMMENT '隐私设置',
  `enable_reminder` TINYINT DEFAULT 1 COMMENT '是否开启提醒',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_updated_at` (`updated_at`),
  CONSTRAINT `fk_capsule_drafts_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='胶囊草稿表';

-- ============================================
-- 8. 用户登录日志表 (user_login_logs) - 可选
-- ============================================
CREATE TABLE `user_login_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `ip_address` VARCHAR(50) DEFAULT NULL COMMENT 'IP地址',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '用户代理',
  `login_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_login_at` (`login_at`),
  CONSTRAINT `fk_user_login_logs_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户登录日志表';

-- ============================================
-- 初始化数据
-- ============================================

-- 插入预设成就数据
INSERT INTO `achievements` (`title`, `description`, `icon`, `condition_type`, `condition_value`, `sort_order`) VALUES
('初学者', '创建第一个时间胶囊', 'Star', 'create_capsule_count', 1, 1),
('记录者', '创建5个时间胶囊', 'Document', 'create_capsule_count', 5, 2),
('时间旅行者', '打开一个过去的时间胶囊', 'Clock', 'open_capsule_count', 1, 3),
('目标达人', '完成3个个人目标', 'Trophy', 'complete_goal_count', 3, 4),
('分享者', '分享5个公开的时间胶囊', 'Share', 'share_capsule_count', 5, 5),
('坚持者', '连续30天创建时间胶囊', 'Calendar', 'consecutive_days', 30, 6),
('成就收集家', '获得10个成就徽章', 'Medal', 'total_achievements', 10, 7),
('完美主义者', '完成所有目标', 'CircleCheck', 'complete_goal_count', 999, 8);

-- ============================================
-- 索引优化说明
-- ============================================
-- 1. 用户表：account 唯一索引用于登录查询
-- 2. 胶囊表：user_id, open_date, status 索引用于用户胶囊列表和筛选
-- 3. 目标表：user_id, status, target_date 索引用于目标列表和进度追踪
-- 4. 成就表：condition_type 索引用于成就检查
-- 5. 所有表都有 created_at 索引用于时间排序

-- ============================================
-- 数据表关系说明
-- ============================================
-- users (1) -> (N) capsules
-- users (1) -> (N) goals
-- users (1) -> (N) user_achievements
-- capsules (1) -> (N) capsule_media
-- achievements (1) -> (N) user_achievements

