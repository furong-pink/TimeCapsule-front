# 时光胶囊系统 API 接口设计文档 (Spring Boot 3)

## 基础信息

- **API 版本**: v1
- **基础URL**: `http://localhost:8080/api/v1`
- **数据格式**: JSON
- **字符编码**: UTF-8
- **认证方式**: JWT Token

## 认证说明

### Token 获取
登录成功后，服务器返回 JWT Token，客户端需要在后续请求的 Header 中携带：

```
Authorization: Bearer {token}
```

### Token 格式
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400
}
```

## 统一响应格式

### 成功响应
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 错误响应
```json
{
  "code": 400,
  "message": "错误信息",
  "data": null,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 分页响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [],
    "page": {
      "number": 0,
      "size": 10,
      "totalElements": 100,
      "totalPages": 10
    }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

## HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，需要登录 |
| 403 | 无权限访问 |
| 404 | 资源不存在 |
| 409 | 资源冲突（如账号已存在） |
| 422 | 数据验证失败 |
| 500 | 服务器内部错误 |

---

## 1. 用户认证接口

### 1.1 用户注册

**接口**: `POST /api/v1/auth/register`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "account": "user@example.com",
  "password": "password123",
  "nickname": "时光旅行者"
}
```

**响应** (201 Created):
```json
{
  "code": 201,
  "message": "注册成功",
  "data": {
    "user": {
      "id": 1,
      "account": "user@example.com",
      "nickname": "时光旅行者",
      "avatar": null,
      "bio": null
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 1.2 用户登录

**接口**: `POST /api/v1/auth/login`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "account": "user@example.com",
  "password": "password123",
  "remember": false
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "user": {
      "id": 1,
      "account": "user@example.com",
      "nickname": "时光旅行者",
      "avatar": "https://example.com/avatar.jpg",
      "bio": "记录生活点滴"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 1.3 刷新Token

**接口**: `POST /api/v1/auth/refresh`

**请求头**: `Authorization: Bearer {token}`

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "刷新成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 1.4 忘记密码

**接口**: `POST /api/v1/auth/forgot-password`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "account": "user@example.com",
  "code": "123456",
  "newPassword": "newpassword123"
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "密码重置成功",
  "data": null,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 1.5 发送验证码

**接口**: `POST /api/v1/auth/send-code`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "account": "user@example.com",
  "type": "FORGOT_PASSWORD"
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "验证码已发送",
  "data": {
    "expiresIn": 300
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 2. 用户信息接口

### 2.1 获取当前用户信息

**接口**: `GET /api/v1/users/profile`

**请求头**: `Authorization: Bearer {token}`

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "account": "user@example.com",
    "nickname": "时光旅行者",
    "avatar": "https://example.com/avatar.jpg",
    "bio": "记录生活点滴，遇见更好的自己",
    "createdAt": "2025-01-01T00:00:00Z"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 2.2 更新用户信息

**接口**: `PUT /api/v1/users/profile`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "nickname": "新的昵称",
  "bio": "新的个人简介",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "更新成功",
  "data": {
    "id": 1,
    "nickname": "新的昵称",
    "bio": "新的个人简介",
    "avatar": "https://example.com/new-avatar.jpg"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 2.3 修改密码

**接口**: `PUT /api/v1/users/password`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "oldPassword": "oldpassword123",
  "newPassword": "newpassword123"
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "密码修改成功",
  "data": null,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 3. 时间胶囊接口

### 3.1 创建时间胶囊

**接口**: `POST /api/v1/capsules`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "title": "致未来的自己",
  "content": "希望未来的自己能够保持初心...",
  "coverImage": "https://example.com/cover.jpg",
  "openDate": "2026-01-01",
  "privacy": "PRIVATE",
  "enableReminder": true,
  "mediaFiles": [
    {
      "fileUrl": "https://example.com/image1.jpg",
      "fileType": "IMAGE",
      "fileName": "image1.jpg",
      "fileSize": 1024000,
      "mimeType": "image/jpeg",
      "sortOrder": 1
    }
  ]
}
```

**响应** (201 Created):
```json
{
  "code": 201,
  "message": "创建成功",
  "data": {
    "id": 1,
    "title": "致未来的自己",
    "content": "希望未来的自己能够保持初心...",
    "coverImage": "https://example.com/cover.jpg",
    "openDate": "2026-01-01",
    "privacy": "PRIVATE",
    "enableReminder": true,
    "status": "PUBLISHED",
    "isOpened": false,
    "createdAt": "2025-01-15T10:30:00Z"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.2 获取时间胶囊列表

**接口**: `GET /api/v1/capsules`

**请求头**: `Authorization: Bearer {token}`

**查询参数**:
- `page`: 页码（默认: 0）
- `size`: 每页数量（默认: 10，最大: 100）
- `year`: 年份筛选（可选，格式: 2025）
- `privacy`: 隐私筛选（PRIVATE/PUBLIC，可选）
- `status`: 状态筛选（DRAFT/PUBLISHED/OPENED，可选）
- `sort`: 排序字段（默认: createdAt，可选: openDate）
- `direction`: 排序方向（ASC/DESC，默认: DESC）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 1,
        "title": "致未来的自己",
        "content": "希望未来的自己能够保持初心...",
        "coverImage": "https://example.com/cover.jpg",
        "openDate": "2026-01-01",
        "privacy": "PRIVATE",
        "status": "PUBLISHED",
        "isOpened": false,
        "createdAt": "2025-01-15T10:30:00Z"
      }
    ],
    "page": {
      "number": 0,
      "size": 10,
      "totalElements": 25,
      "totalPages": 3
    }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.3 获取时间胶囊详情

**接口**: `GET /api/v1/capsules/{id}`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 胶囊ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "userId": 1,
    "title": "致未来的自己",
    "content": "希望未来的自己能够保持初心...",
    "coverImage": "https://example.com/cover.jpg",
    "openDate": "2026-01-01",
    "privacy": "PRIVATE",
    "enableReminder": true,
    "status": "PUBLISHED",
    "isOpened": false,
    "openedAt": null,
    "mediaFiles": [
      {
        "id": 1,
        "fileUrl": "https://example.com/image1.jpg",
        "fileType": "IMAGE",
        "fileName": "image1.jpg",
        "fileSize": 1024000,
        "mimeType": "image/jpeg",
        "sortOrder": 1
      }
    ],
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.4 更新时间胶囊

**接口**: `PUT /api/v1/capsules/{id}`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**路径参数**:
- `id`: 胶囊ID

**请求体**: 同创建接口

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "更新成功",
  "data": {
    "id": 1,
    "title": "更新后的标题",
    ...
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.5 删除时间胶囊

**接口**: `DELETE /api/v1/capsules/{id}`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 胶囊ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "删除成功",
  "data": null,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.6 开启时间胶囊

**接口**: `POST /api/v1/capsules/{id}/open`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 胶囊ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "开启成功",
  "data": {
    "id": 1,
    "isOpened": true,
    "openedAt": "2025-01-15T10:30:00Z"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.7 获取时间轴数据

**接口**: `GET /api/v1/capsules/timeline`

**请求头**: `Authorization: Bearer {token}`

**查询参数**:
- `year`: 年份筛选（可选）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "timeline": [
      {
        "year": 2025,
        "capsules": [
          {
            "id": 1,
            "title": "致未来的自己",
            "coverImage": "https://example.com/cover.jpg",
            "openDate": "2026-01-01",
            "privacy": "PRIVATE",
            "createdAt": "2025-01-15T10:30:00Z"
          }
        ]
      }
    ],
    "years": [2025, 2024, 2023]
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.8 保存草稿

**接口**: `POST /api/v1/capsules/drafts`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**请求体**: 同创建接口（所有字段可选）

**响应** (201 Created):
```json
{
  "code": 201,
  "message": "草稿保存成功",
  "data": {
    "id": 1,
    "title": "草稿标题",
    ...
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 3.9 获取草稿列表

**接口**: `GET /api/v1/capsules/drafts`

**请求头**: `Authorization: Bearer {token}`

**查询参数**:
- `page`: 页码（默认: 0）
- `size`: 每页数量（默认: 10）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 1,
        "title": "草稿标题",
        "updatedAt": "2025-01-15T10:30:00Z"
      }
    ],
    "page": {
      "number": 0,
      "size": 10,
      "totalElements": 5,
      "totalPages": 1
    }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 4. 文件上传接口

### 4.1 上传文件

**接口**: `POST /api/v1/upload`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `multipart/form-data`

**请求参数**:
- `file`: 文件（必填，类型: File）
- `type`: 文件类型（可选，COVER/MEDIA，默认: MEDIA）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "fileUrl": "https://example.com/uploads/image.jpg",
    "fileName": "image.jpg",
    "fileSize": 1024000,
    "mimeType": "image/jpeg",
    "fileType": "IMAGE"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 5. 目标接口

### 5.1 创建目标

**接口**: `POST /api/v1/goals`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**请求体**:
```json
{
  "title": "学习新技术",
  "description": "掌握Vue 3和Element Plus的使用",
  "type": "SHORT_TERM",
  "targetDate": "2025-06-30",
  "progress": 0,
  "enableReminder": true
}
```

**响应** (201 Created):
```json
{
  "code": 201,
  "message": "创建成功",
  "data": {
    "id": 1,
    "title": "学习新技术",
    "description": "掌握Vue 3和Element Plus的使用",
    "type": "SHORT_TERM",
    "targetDate": "2025-06-30",
    "progress": 0,
    "status": "IN_PROGRESS",
    "enableReminder": true,
    "createdAt": "2025-01-15T10:30:00Z"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 5.2 获取目标列表

**接口**: `GET /api/v1/goals`

**请求头**: `Authorization: Bearer {token}`

**查询参数**:
- `page`: 页码（默认: 0）
- `size`: 每页数量（默认: 10）
- `status`: 状态筛选（IN_PROGRESS/COMPLETED/CANCELLED，可选）
- `type`: 类型筛选（SHORT_TERM/LONG_TERM，可选）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "content": [
      {
        "id": 1,
        "title": "学习新技术",
        "description": "掌握Vue 3和Element Plus的使用",
        "type": "SHORT_TERM",
        "targetDate": "2025-06-30",
        "progress": 70,
        "status": "IN_PROGRESS",
        "enableReminder": true,
        "createdAt": "2025-01-15T10:30:00Z"
      }
    ],
    "page": {
      "number": 0,
      "size": 10,
      "totalElements": 10,
      "totalPages": 1
    },
    "statistics": {
      "total": 10,
      "completed": 3,
      "inProgress": 6,
      "cancelled": 1
    }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 5.3 获取目标详情

**接口**: `GET /api/v1/goals/{id}`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 目标ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "title": "学习新技术",
    "description": "掌握Vue 3和Element Plus的使用",
    "type": "SHORT_TERM",
    "targetDate": "2025-06-30",
    "progress": 70,
    "status": "IN_PROGRESS",
    "enableReminder": true,
    "completedAt": null,
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-20T10:30:00Z"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 5.4 更新目标

**接口**: `PUT /api/v1/goals/{id}`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**路径参数**:
- `id`: 目标ID

**请求体**: 同创建接口（所有字段可选）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "更新成功",
  "data": {
    "id": 1,
    "title": "更新后的目标",
    ...
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 5.5 更新目标进度

**接口**: `PATCH /api/v1/goals/{id}/progress`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**路径参数**:
- `id`: 目标ID

**请求体**:
```json
{
  "progress": 80
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "进度更新成功",
  "data": {
    "id": 1,
    "progress": 80,
    "status": "IN_PROGRESS"
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 5.6 删除目标

**接口**: `DELETE /api/v1/goals/{id}`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 目标ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "删除成功",
  "data": null,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 5.7 切换提醒开关

**接口**: `PATCH /api/v1/goals/{id}/reminder`

**请求头**: `Authorization: Bearer {token}`

**Content-Type**: `application/json`

**路径参数**:
- `id`: 目标ID

**请求体**:
```json
{
  "enableReminder": true
}
```

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "更新成功",
  "data": {
    "id": 1,
    "enableReminder": true
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 6. 成就接口

### 6.1 获取成就列表

**接口**: `GET /api/v1/achievements`

**请求头**: `Authorization: Bearer {token}`

**查询参数**:
- `filter`: 筛选类型（ALL/ACHIEVED/LOCKED，默认: ALL）

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "list": [
      {
        "id": 1,
        "title": "初学者",
        "description": "创建第一个时间胶囊",
        "icon": "Star",
        "conditionType": "CREATE_CAPSULE_COUNT",
        "conditionValue": 1,
        "achieved": true,
        "achievedAt": "2025-01-15T10:30:00Z",
        "isNew": false,
        "progress": {
          "current": 1,
          "total": 1
        }
      },
      {
        "id": 2,
        "title": "记录者",
        "description": "创建5个时间胶囊",
        "icon": "Document",
        "conditionType": "CREATE_CAPSULE_COUNT",
        "conditionValue": 5,
        "achieved": false,
        "achievedAt": null,
        "isNew": false,
        "progress": {
          "current": 2,
          "total": 5
        }
      }
    ],
    "statistics": {
      "total": 8,
      "achieved": 2,
      "locked": 6
    }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 6.2 获取成就详情

**接口**: `GET /api/v1/achievements/{id}`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 成就ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "title": "初学者",
    "description": "创建第一个时间胶囊",
    "icon": "Star",
    "conditionType": "CREATE_CAPSULE_COUNT",
    "conditionValue": 1,
    "achieved": true,
    "achievedAt": "2025-01-15T10:30:00Z",
    "progress": {
      "current": 1,
      "total": 1
    }
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 6.3 标记成就已读

**接口**: `PATCH /api/v1/achievements/{id}/read`

**请求头**: `Authorization: Bearer {token}`

**路径参数**:
- `id`: 成就ID

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "标记成功",
  "data": {
    "id": 1,
    "isNew": false
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 6.4 检查并解锁成就

**接口**: `POST /api/v1/achievements/check`

**请求头**: `Authorization: Bearer {token}`

**说明**: 系统自动检查用户是否满足成就条件，如果满足则自动解锁

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "检查完成",
  "data": {
    "newAchievements": [
      {
        "id": 1,
        "title": "初学者",
        "achievedAt": "2025-01-15T10:30:00Z"
      }
    ]
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 7. 统计接口

### 7.1 获取首页统计数据

**接口**: `GET /api/v1/statistics/home`

**请求头**: `Authorization: Bearer {token}`

**响应** (200 OK):
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "userStats": {
      "capsuleCount": 10,
      "completedGoals": 3,
      "achievements": 5
    },
    "todayGoal": {
      "target": "完成 1 封时间胶囊",
      "progress": 0,
      "completed": false
    },
    "recentCapsules": [
      {
        "id": 1,
        "title": "致未来的自己",
        "coverImage": "https://example.com/cover.jpg",
        "openDate": "2026-01-01",
        "privacy": "PRIVATE",
        "createdAt": "2025-01-15T10:30:00Z"
      }
    ]
  },
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 枚举类型定义

### Privacy (隐私设置)
- `PRIVATE` - 私密
- `PUBLIC` - 公开

### CapsuleStatus (胶囊状态)
- `DRAFT` - 草稿
- `PUBLISHED` - 已发布
- `OPENED` - 已开启

### GoalType (目标类型)
- `SHORT_TERM` - 短期目标
- `LONG_TERM` - 长期目标

### GoalStatus (目标状态)
- `IN_PROGRESS` - 进行中
- `COMPLETED` - 已完成
- `CANCELLED` - 已取消

### FileType (文件类型)
- `IMAGE` - 图片
- `VIDEO` - 视频

### AchievementConditionType (成就条件类型)
- `CREATE_CAPSULE_COUNT` - 创建胶囊数量
- `OPEN_CAPSULE_COUNT` - 开启胶囊数量
- `COMPLETE_GOAL_COUNT` - 完成目标数量
- `SHARE_CAPSULE_COUNT` - 分享胶囊数量
- `CONSECUTIVE_DAYS` - 连续天数
- `TOTAL_ACHIEVEMENTS` - 总成就数量

---

## 接口调用示例

### Java (RestTemplate)

```java
// 登录
RestTemplate restTemplate = new RestTemplate();
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_JSON);

LoginRequest request = new LoginRequest("user@example.com", "password123");
HttpEntity<LoginRequest> entity = new HttpEntity<>(request, headers);

ResponseEntity<ApiResponse<LoginResponse>> response = restTemplate.exchange(
    "http://localhost:8080/api/v1/auth/login",
    HttpMethod.POST,
    entity,
    new ParameterizedTypeReference<ApiResponse<LoginResponse>>() {}
);

String token = response.getBody().getData().getToken();

// 获取胶囊列表
headers.setBearerAuth(token);
HttpEntity<String> authEntity = new HttpEntity<>(headers);
ResponseEntity<ApiResponse<PageResponse<CapsuleDTO>>> capsulesResponse = restTemplate.exchange(
    "http://localhost:8080/api/v1/capsules?page=0&size=10",
    HttpMethod.GET,
    authEntity,
    new ParameterizedTypeReference<ApiResponse<PageResponse<CapsuleDTO>>>() {}
);
```

### JavaScript (Axios)

```javascript
// 登录
const login = async (account, password) => {
  const response = await axios.post('/api/v1/auth/login', {
    account,
    password
  });
  localStorage.setItem('token', response.data.data.token);
  return response.data;
};

// 获取胶囊列表
const getCapsules = async (page = 0, size = 10) => {
  const token = localStorage.getItem('token');
  const response = await axios.get('/api/v1/capsules', {
    params: { page, size },
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.data;
};
```

---

## 注意事项

1. **认证**: 除认证接口外，其他接口都需要在 Header 中携带 Token
2. **时间格式**: 所有时间字段使用 ISO 8601 格式（如: `2025-01-15T10:30:00Z`）
3. **分页**: 列表接口使用 Spring Data 分页，页码从 0 开始
4. **文件上传**: 单个文件最大 10MB，支持 jpg、png、gif、mp4 格式
5. **速率限制**: 建议实现接口调用频率限制，防止恶意请求
6. **数据验证**: 使用 Bean Validation 进行数据验证
7. **异常处理**: 使用全局异常处理器统一处理异常

