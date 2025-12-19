# 实体类设计示例

## 1. User 实体类

```java
package com.timecapsule.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_account", columnList = "account"),
    @Index(name = "idx_nickname", columnList = "nickname")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 100)
    private String account;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, length = 50)
    private String nickname;

    @Column(length = 500)
    private String avatar;

    @Column(length = 200)
    private String bio;

    @Column(nullable = false)
    private Boolean status = true;

    private LocalDateTime lastLoginAt;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
```

## 2. Capsule 实体类

```java
package com.timecapsule.entity;

import com.timecapsule.enums.CapsuleStatus;
import com.timecapsule.enums.Privacy;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "capsules", indexes = {
    @Index(name = "idx_user_id", columnList = "user_id"),
    @Index(name = "idx_open_date", columnList = "open_date"),
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_privacy", columnList = "privacy")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Capsule {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "cover_image", length = 500)
    private String coverImage;

    @Column(name = "open_date", nullable = false)
    private LocalDate openDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Privacy privacy = Privacy.PRIVATE;

    @Column(name = "enable_reminder", nullable = false)
    private Boolean enableReminder = true;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CapsuleStatus status = CapsuleStatus.PUBLISHED;

    @Column(name = "is_opened", nullable = false)
    private Boolean isOpened = false;

    @Column(name = "opened_at")
    private LocalDateTime openedAt;

    @OneToMany(mappedBy = "capsule", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC")
    private List<CapsuleMedia> mediaFiles;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
```

## 3. CapsuleMedia 实体类

```java
package com.timecapsule.entity;

import com.timecapsule.enums.FileType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "capsule_media", indexes = {
    @Index(name = "idx_capsule_id", columnList = "capsule_id"),
    @Index(name = "idx_sort_order", columnList = "sort_order")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CapsuleMedia {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "capsule_id", nullable = false)
    private Capsule capsule;

    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "file_type", nullable = false)
    private FileType fileType;

    @Column(name = "file_name", length = 255)
    private String fileName;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
```

## 4. Goal 实体类

```java
package com.timecapsule.entity;

import com.timecapsule.enums.GoalStatus;
import com.timecapsule.enums.GoalType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "goals", indexes = {
    @Index(name = "idx_user_id", columnList = "user_id"),
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_target_date", columnList = "target_date")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Goal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private GoalType type = GoalType.SHORT_TERM;

    @Column(name = "target_date", nullable = false)
    private LocalDate targetDate;

    @Column(nullable = false)
    private Integer progress = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private GoalStatus status = GoalStatus.IN_PROGRESS;

    @Column(name = "enable_reminder", nullable = false)
    private Boolean enableReminder = true;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
```

## 5. Achievement 实体类

```java
package com.timecapsule.entity;

import com.timecapsule.enums.AchievementConditionType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "achievements", indexes = {
    @Index(name = "idx_condition_type", columnList = "condition_type"),
    @Index(name = "idx_sort_order", columnList = "sort_order")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Achievement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, length = 50)
    private String title;

    @Column(nullable = false, length = 200)
    private String description;

    @Column(nullable = false, length = 50)
    private String icon;

    @Enumerated(EnumType.STRING)
    @Column(name = "condition_type", nullable = false, length = 50)
    private AchievementConditionType conditionType;

    @Column(name = "condition_value", nullable = false)
    private Integer conditionValue;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
```

## 6. UserAchievement 实体类

```java
package com.timecapsule.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_achievements", 
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "achievement_id"}),
    indexes = {
        @Index(name = "idx_user_id", columnList = "user_id"),
        @Index(name = "idx_achievement_id", columnList = "achievement_id"),
        @Index(name = "idx_achieved_at", columnList = "achieved_at")
    })
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserAchievement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "achievement_id", nullable = false)
    private Achievement achievement;

    @Column(name = "is_new", nullable = false)
    private Boolean isNew = true;

    @CreationTimestamp
    @Column(name = "achieved_at", nullable = false, updatable = false)
    private LocalDateTime achievedAt;
}
```

## 枚举类示例

### Privacy.java

```java
package com.timecapsule.enums;

public enum Privacy {
    PRIVATE,
    PUBLIC
}
```

### CapsuleStatus.java

```java
package com.timecapsule.enums;

public enum CapsuleStatus {
    DRAFT,
    PUBLISHED,
    OPENED
}
```

### GoalType.java

```java
package com.timecapsule.enums;

public enum GoalType {
    SHORT_TERM,
    LONG_TERM
}
```

### GoalStatus.java

```java
package com.timecapsule.enums;

public enum GoalStatus {
    IN_PROGRESS,
    COMPLETED,
    CANCELLED
}
```

### FileType.java

```java
package com.timecapsule.enums;

public enum FileType {
    IMAGE,
    VIDEO
}
```

### AchievementConditionType.java

```java
package com.timecapsule.enums;

public enum AchievementConditionType {
    CREATE_CAPSULE_COUNT,
    OPEN_CAPSULE_COUNT,
    COMPLETE_GOAL_COUNT,
    SHARE_CAPSULE_COUNT,
    CONSECUTIVE_DAYS,
    TOTAL_ACHIEVEMENTS
}
```

