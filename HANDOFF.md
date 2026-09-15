# HANDOFF — Java 后端实习辅导项目交接文档

> 写给接手这个辅导任务的下一个会话。读完这份文档 + 两个记忆文件即可无缝继续。

---

## 一、用户与目标

- **用户身份**：计算机系大三学生（2026 年秋季升大三），中文交流。
- **目标**：2026 年 12 月投递简历，2026-2027 寒假拿到 Java 后端实习 Offer。
- **时间线**：今天是 2026-09-15，距离投递还有约 3 个月。

## 二、学习进度（截至 2026-09-13）

**已完成：**
- Java 基础：集合、泛型、反射、注解、异常、IO 流
- 多线程：创建方式、synchronized、Lock、线程池、volatile、CAS
- JVM：内存结构、GC、类加载
- MySQL：索引、事务、MVCC、锁、主从复制、分库分表（10 天系统学完）
- Redis：五种数据结构、缓存三问题、持久化、分布式锁、淘汰策略、高可用（7 天学完）
- Spring Boot：IOC/DI、AOP、自动配置、Spring MVC、统一响应、参数校验、全局异常、JWT 登录认证（5 天学完）
- LeetCode：约 20+ 题

**进行中：**
- Spring Boot 项目实战「Learning」博客系统（2026-09-11 起）

**待学：**
- 计算机网络（面试高频，未系统学）
- 项目实战继续（category/comment 模块、Redis 缓存接入）
- 简历 + 八股文（11 月起）

## 三、当前项目「Learning」

**位置**：`C:\Users\ASUS\Desktop\java` 下（实际项目目录以用户为准，可能是子目录）

**技术栈**：
- Spring Boot 2.7.18 + MyBatis-Plus 3.5.5 + MySQL + JDK 17
- jjwt（JWT）、spring-security-crypto（仅 BCrypt，未用完整 security starter）

**包结构**：`com.jiangpa.{common, config, controller, dto, exception, interceptor, properties, service, service.impl, mapper, pojo, vo}`

**已完成功能：**
- 用户模块：`tb_user` 表，增删改查 5 接口、`/auth/register`、`/auth/login`
- 文章模块：`tb_article` 表，详情 / 分页列表 / 发布 / 修改 / 删除五接口
- `Result<T>` 统一响应、JWT 工具类 + `JwtInterceptor` + `WebMvcConfig`（排除 `/auth/**`、`/error`）
- BCrypt 密码加密、`GlobalExceptionHandler` + `BusinessException`、`MybatisPlusConfig` 分页插件

**文章模块的技术亮点（面试可讲）：**
- 列表用 `wrapper.select()` 只查轻量列
- 跨表用 `selectBatchIds` 批量查作者昵称，避免 N+1 查询
- `view_count` 用 `setSql("view_count = view_count + 1")` 自增
- 更新用 `LambdaUpdateWrapper` 显式指定列，避免覆盖 create_time 和 view_count
- 改删校验作者身份，非本人返回 403

**未完成 / 待办：**
- 用户模块列表未分页
- `HttpMessageNotReadableException` / `HttpMediaTypeNotSupportedException` 未单独处理（会掉到兜底返 500）
- category / comment 模块接口（表已建，接口未做）
- 逻辑删除未做
- Redis 缓存尚未接入项目

**架构约定（必须遵守）：**
- HTTP 状态码一律返 200，业务状态放在响应体 `code` 字段里
- 不建物理外键，靠索引 + 应用层保证
- Service 层抛异常，不返回 Result；异常统一由 GlobalExceptionHandler 处理

**已产出文档**（在项目根目录）：
`用户模块接口文档.md`、`JWT鉴权拦截器文档.md`、`全局异常处理器文档.md`、`Postman接口测试文档.md`、`文章模块接口文档.md`、`文章模块Postman测试文档.md`

## 四、已知易踩的坑

- Spring Boot 2.7.8 起 MySQL 驱动坐标是 `com.mysql:mysql-connector-j`（旧坐标省略版本号会报 missing version）
- Spring Boot 2.7 必须用 `javax.servlet`，不是 `jakarta.servlet`
- jjwt 的 `SignatureException` 用 `io.jsonwebtoken.security` 包下那个
- HS256 密钥至少 32 字节

## 五、协作偏好（重要）

**排查问题后，先给「哪里错了 + 为什么错」的清单，让用户自己改；他做不下去或明确说"你帮我改"时，再代改。**

- 原因：他在学 Java 找实习，动手改本身就是学习。
- 代改时保留他原有代码风格和注释习惯。
- 日常交流用中文，回答要具体、可操作。

## 六、每日节奏

用户习惯每天早上问"今天学什么"，据此给当天的学习计划（上午 + 算法 + 下午 + 晚上 + git commit 信息），并让他更新 README 每日记录表 + 提交 GitHub（仓库 `jiangpa1/java-learning`）。

## 七、下一步建议（2026-09-15 起）

1. 继续项目实战：category / comment 模块 → 接入 Redis 缓存（热门文章、浏览数）
2. 项目告一段落后，补计算机网络（TCP/HTTP/HTTPS，面试高频）
3. 10 月底前完成第二个项目或完善现有项目
4. 11 月启动简历 + JavaGuide 八股文系统刷题
5. 12 月海投简历 + 面试

---

**记忆文件位置**（已存在，继续维护即可）：
- `user-profile.md`：用户画像 + 学习进度 + 项目详细状态
- `feedback-editing-style.md`：协作偏好
