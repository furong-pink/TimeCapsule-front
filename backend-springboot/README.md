# 时光胶囊系统 Spring Boot 3 后端开发指南

## 技术栈

- **框架**: Spring Boot 3.x
- **Java版本**: Java 17+
- **构建工具**: Maven 或 Gradle
- **数据库**: MySQL 8.0+
- **ORM**: Spring Data JPA / Hibernate
- **安全**: Spring Security + JWT
- **文档**: Spring Doc (OpenAPI 3)
- **缓存**: Spring Cache + Redis (可选)

## 项目结构

```
timecapsule-backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── timecapsule/
│   │   │           ├── TimeCapsuleApplication.java
│   │   │           ├── config/              # 配置类
│   │   │           │   ├── SecurityConfig.java
│   │   │           │   ├── JwtConfig.java
│   │   │           │   ├── WebConfig.java
│   │   │           │   └── FileUploadConfig.java
│   │   │           ├── controller/           # 控制器
│   │   │           │   ├── AuthController.java
│   │   │           │   ├── UserController.java
│   │   │           │   ├── CapsuleController.java
│   │   │           │   ├── GoalController.java
│   │   │           │   ├── AchievementController.java
│   │   │           │   └── UploadController.java
│   │   │           ├── service/              # 服务层
│   │   │           │   ├── AuthService.java
│   │   │           │   ├── UserService.java
│   │   │           │   ├── CapsuleService.java
│   │   │           │   ├── GoalService.java
│   │   │           │   └── AchievementService.java
│   │   │           ├── repository/           # 数据访问层
│   │   │           │   ├── UserRepository.java
│   │   │           │   ├── CapsuleRepository.java
│   │   │           │   ├── GoalRepository.java
│   │   │           │   └── AchievementRepository.java
│   │   │           ├── entity/               # 实体类
│   │   │           │   ├── User.java
│   │   │           │   ├── Capsule.java
│   │   │           │   ├── CapsuleMedia.java
│   │   │           │   ├── Goal.java
│   │   │           │   ├── Achievement.java
│   │   │           │   └── UserAchievement.java
│   │   │           ├── dto/                  # 数据传输对象
│   │   │           │   ├── request/
│   │   │           │   │   ├── LoginRequest.java
│   │   │           │   │   ├── RegisterRequest.java
│   │   │           │   │   ├── CapsuleCreateRequest.java
│   │   │           │   │   └── GoalCreateRequest.java
│   │   │           │   ├── response/
│   │   │           │   │   ├── LoginResponse.java
│   │   │           │   │   ├── UserResponse.java
│   │   │           │   │   ├── CapsuleResponse.java
│   │   │           │   │   └── GoalResponse.java
│   │   │           │   └── ApiResponse.java
│   │   │           ├── security/             # 安全相关
│   │   │           │   ├── JwtTokenProvider.java
│   │   │           │   ├── JwtAuthenticationFilter.java
│   │   │           │   └── UserDetailsServiceImpl.java
│   │   │           ├── exception/            # 异常处理
│   │   │           │   ├── GlobalExceptionHandler.java
│   │   │           │   ├── ResourceNotFoundException.java
│   │   │           │   └── BusinessException.java
│   │   │           ├── util/                 # 工具类
│   │   │           │   ├── PasswordUtil.java
│   │   │           │   ├── FileUtil.java
│   │   │           │   └── DateUtil.java
│   │   │           └── enums/                # 枚举类
│   │   │               ├── Privacy.java
│   │   │               ├── CapsuleStatus.java
│   │   │               ├── GoalType.java
│   │   │               └── GoalStatus.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── db/
│   │           └── migration/                # Flyway 迁移脚本
│   │               └── V1__init.sql
│   └── test/
│       └── java/
│           └── com/timecapsule/
│               └── TimeCapsuleApplicationTests.java
├── pom.xml (或 build.gradle)
└── README.md
```

## Maven 依赖配置

### pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>

    <groupId>com.timecapsule</groupId>
    <artifactId>timecapsule-backend</artifactId>
    <version>1.0.0</version>
    <name>Time Capsule Backend</name>
    <description>时光胶囊系统后端服务</description>

    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <!-- Spring Boot Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Spring Boot Data JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <!-- Spring Boot Security -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>

        <!-- Spring Boot Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- MySQL Driver -->
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- JWT -->
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.12.3</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.12.3</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.12.3</version>
            <scope>runtime</scope>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- Spring Doc (OpenAPI) -->
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>2.3.0</version>
        </dependency>

        <!-- File Upload -->
        <dependency>
            <groupId>commons-fileupload</groupId>
            <artifactId>commons-fileupload</artifactId>
            <version>1.5</version>
        </dependency>

        <!-- Redis (可选) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>

        <!-- Flyway (数据库迁移) -->
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-mysql</artifactId>
        </dependency>

        <!-- Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

## 配置文件

### application.yml

```yaml
spring:
  application:
    name: timecapsule-backend
  
  # 数据源配置
  datasource:
    url: jdbc:mysql://localhost:3306/timecapsule_db?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: your_password
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000

  # JPA配置
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
        format_sql: true
        use_sql_comments: true

  # 文件上传配置
  servlet:
    multipart:
      enabled: true
      max-file-size: 10MB
      max-request-size: 50MB

  # Flyway配置
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true

# JWT配置
jwt:
  secret: your-secret-key-change-in-production
  expiration: 86400000 # 24小时 (毫秒)
  refresh-expiration: 604800000 # 7天 (毫秒)

# 文件存储配置
file:
  upload:
    path: ./uploads
    url-prefix: http://localhost:8080/uploads

# 服务器配置
server:
  port: 8080
  servlet:
    context-path: /
    encoding:
      charset: UTF-8
      enabled: true
      force: true

# 日志配置
logging:
  level:
    root: INFO
    com.timecapsule: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: logs/timecapsule.log
    max-size: 10MB
    max-history: 30

# Spring Doc配置
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
    enabled: true
```

### application-dev.yml

```yaml
spring:
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: update

logging:
  level:
    com.timecapsule: DEBUG
```

### application-prod.yml

```yaml
spring:
  jpa:
    show-sql: false
    hibernate:
      ddl-auto: validate

logging:
  level:
    root: WARN
    com.timecapsule: INFO
```

## 核心代码示例

### 1. 统一响应类

```java
package com.timecapsule.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {
    private Integer code;
    private String message;
    private T data;
    private LocalDateTime timestamp;

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(200, "success", data, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(200, message, data, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> error(Integer code, String message) {
        return new ApiResponse<>(code, message, null, LocalDateTime.now());
    }
}
```

### 2. 实体类示例 (User)

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
@Table(name = "users")
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

### 3. Repository 示例

```java
package com.timecapsule.repository;

import com.timecapsule.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByAccount(String account);
    boolean existsByAccount(String account);
    boolean existsByNickname(String nickname);
}
```

### 4. Service 示例

```java
package com.timecapsule.service;

import com.timecapsule.dto.request.LoginRequest;
import com.timecapsule.dto.request.RegisterRequest;
import com.timecapsule.dto.response.LoginResponse;
import com.timecapsule.entity.User;
import com.timecapsule.repository.UserRepository;
import com.timecapsule.security.JwtTokenProvider;
import com.timecapsule.util.PasswordUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordUtil passwordUtil;

    @Transactional
    public LoginResponse register(RegisterRequest request) {
        if (userRepository.existsByAccount(request.getAccount())) {
            throw new BusinessException("账号已存在");
        }

        User user = new User();
        user.setAccount(request.getAccount());
        user.setPassword(passwordUtil.encode(request.getPassword()));
        user.setNickname(request.getNickname());
        user = userRepository.save(user);

        String token = jwtTokenProvider.generateToken(user.getId(), user.getAccount());
        return new LoginResponse(user, token);
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByAccount(request.getAccount())
                .orElseThrow(() -> new BusinessException("账号或密码错误"));

        if (!passwordUtil.matches(request.getPassword(), user.getPassword())) {
            throw new BusinessException("账号或密码错误");
        }

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        String token = jwtTokenProvider.generateToken(user.getId(), user.getAccount());
        return new LoginResponse(user, token);
    }
}
```

### 5. Controller 示例

```java
package com.timecapsule.controller;

import com.timecapsule.dto.ApiResponse;
import com.timecapsule.dto.request.LoginRequest;
import com.timecapsule.dto.request.RegisterRequest;
import com.timecapsule.dto.response.LoginResponse;
import com.timecapsule.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<LoginResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        LoginResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("注册成功", response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("登录成功", response));
    }
}
```

### 6. 全局异常处理

```java
package com.timecapsule.exception;

import com.timecapsule.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<?>> handleBusinessException(BusinessException e) {
        return ResponseEntity.status(e.getStatus())
                .body(ApiResponse.error(e.getStatus().value(), e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationException(
            MethodArgumentNotValidException e) {
        Map<String, String> errors = new HashMap<>();
        e.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "数据验证失败", errors));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<?>> handleException(Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(500, "服务器内部错误"));
    }
}
```

## 开发步骤

### 1. 初始化项目

```bash
# 使用 Spring Initializr 创建项目
# 或使用 IDE (IntelliJ IDEA / Eclipse) 创建 Spring Boot 项目
```

### 2. 配置数据库

```bash
# 执行数据库脚本
mysql -u root -p < database/design.sql
```

### 3. 运行项目

```bash
# Maven
mvn spring-boot:run

# 或使用 IDE 直接运行
```

### 4. 访问 API 文档

```
http://localhost:8080/swagger-ui.html
```

## 测试

### 单元测试示例

```java
@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void testRegister() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setAccount("test@example.com");
        request.setPassword("password123");
        request.setNickname("测试用户");

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value(201));
    }
}
```

## 部署

### 1. 打包

```bash
mvn clean package -DskipTests
```

### 2. 运行 JAR

```bash
java -jar target/timecapsule-backend-1.0.0.jar
```

### 3. Docker 部署

```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/timecapsule-backend-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## 安全建议

1. **密码加密**: 使用 BCryptPasswordEncoder
2. **JWT Secret**: 生产环境使用强随机密钥
3. **HTTPS**: 生产环境必须使用 HTTPS
4. **SQL注入**: 使用 JPA 参数化查询
5. **XSS防护**: 对用户输入进行转义
6. **CORS配置**: 限制允许的域名
7. **速率限制**: 使用 Spring Security 或 Redis 实现

## 性能优化

1. **数据库索引**: 确保常用查询字段有索引
2. **连接池**: 配置 HikariCP 连接池
3. **缓存**: 使用 Redis 缓存热点数据
4. **分页**: 所有列表接口实现分页
5. **异步处理**: 使用 @Async 处理耗时操作

