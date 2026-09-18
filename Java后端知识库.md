# Java 后端知识库

> **用途**：把学习过程中问过的每一个知识点沉淀在这里，供面试前复习。
> **维护约定**：用户每问一个知识点，就按下面的固定格式追加一条；已存在的条目**就地更新**，不重复开条目。条目按主题分组、**不编号**，新增时挂到对应主题末尾即可（避免每次插入都要重排编号）。
> **位置**：`C:\Users\ASUS\Desktop\java\Java后端知识库.md`（与 `HANDOFF.md`、`README.md` 同级）
> 建立日期：2026-09-15

---

## 条目格式（新增时照抄）

```
### 知识点标题
**问题**：一句话说清这是什么问题。
**答案**：核心结论，面试能直接说出口的版本。
**本项目实例**：Learning 项目里对应的代码或表，给出文件路径。
**面试怎么答**：被问到时的回答思路（含追问方向）。
```

---

## 目录

**索引与 SQL 优化**
- [复合索引消除 filesort](#复合索引消除-filesort)
- [索引不是越多越好](#索引不是越多越好)

**数据库约束与异常**
- [DuplicateKeyException 与唯一约束双保险](#duplicatekeyexception-与唯一约束双保险)

**MyBatis-Plus**
- [Wrapper（条件构造器）是什么，必须传吗](#wrapper条件构造器是什么必须传吗)
- [N+1 查询与 selectBatchIds](#n1-查询与-selectbatchids)
- [UpdateWrapper 显式指定列](#updatewrapper-显式指定列)

**表设计**
- [NOT NULL DEFAULT 0 与 NPE](#not-null-default-0-与-npe)
- [为什么不建物理外键](#为什么不建物理外键)
- [平铺评论 vs 盖楼](#平铺评论-vs-盖楼)

**Java 基础与 Stream**
- [Collectors.toMap 的合并函数是什么](#collectorstomap-的合并函数是什么)

**Redis 与缓存**
- [Cache Aside：更新时删缓存还是更新缓存](#cache-aside更新时删缓存还是更新缓存)
- [缓存 TTL 该设多久](#缓存-ttl-该设多久)
- [缓存穿透：空对象缓存 vs 布隆过滤器](#缓存穿透空对象缓存-vs-布隆过滤器)
- [计数器什么时候回写数据库（惰性 vs 定时）](#计数器什么时候回写数据库惰性-vs-定时)
- [为什么生产环境禁用 KEYS 命令](#为什么生产环境禁用-keys-命令)
- [Redis key 到底占多少内存，永久保存会不会爆](#redis-key-到底占多少内存永久保存会不会爆)
- [缓存三兄弟：穿透 / 击穿 / 雪崩怎么区分](#缓存三兄弟穿透--击穿--雪崩怎么区分)

**计算机网络**
- [TCP 三次握手与四次挥手](#tcp-三次握手与四次挥手)
- [TIME_WAIT 为什么等 2MSL](#time_wait-为什么等-2msl)

**Spring**
- [@RestController vs @Controller](#restcontroller-vs-controller)
- [构造器注入 vs 字段注入](#构造器注入-vs-字段注入)
- [@Valid 漏写 = 所有校验注解静默失效](#valid-漏写--所有校验注解静默失效)

**JWT 与鉴权**
- [为什么需要双 Token](#为什么需要双-token)
- [登出怎么让 JWT 立即失效](#登出怎么让-jwt-立即失效)
- [安全层 fail-closed 与性能层 fail-open](#安全层-fail-closed-与性能层-fail-open)
- [Redis 六处依赖的降级方向与超时代价](#redis-六处依赖的降级方向与超时代价)
- [JWT 登录与鉴权的完整链路](#jwt-登录与鉴权的完整链路)
- [refresh token 什么时候轮换](#refresh-token-什么时候轮换)
- [JWT 异常要在哪几处 catch](#jwt-异常要在哪几处-catch)

**认证与授权**
- [认证 ≠ 授权：水平越权和纵向越权](#认证--授权水平越权和纵向越权)
- [删除/修改类接口的权限判断写反了会怎样](#删除修改类接口的权限判断写反了会怎样)

---

# 索引与 SQL 优化

### 复合索引消除 filesort

**问题**：`SELECT ... WHERE article_id = ? ORDER BY create_time DESC LIMIT ?,?` 这条查询，只给 `article_id` 建了单列索引，排序还要额外排序吗？

**答案**：要。单列索引 `idx_article_id` 只能用来快速**过滤**出该文章的评论，过滤完之后 MySQL 必须把结果集按 `create_time` 重新排序，也就是 `EXPLAIN` 里 `Extra` 出现的 **`Using filesort`**。改成复合索引 `(article_id, create_time)` 之后，B+ 树里 `article_id` 相同的那一段本身就是按 `create_time` 有序的，过滤和排序**一次索引扫描全搞定**，`Using filesort` 消失。

顺序不能反：复合索引遵循**最左前缀**，必须是"等值过滤的列在前 + 排序的列在后"。

```sql
ALTER TABLE tb_comment ADD INDEX idx_article_create (article_id, create_time);
```

**本项目实例**：`tb_comment` 表（Learning 项目）。2026-09-15 做评论模块时发现。

**2026-09-15 实测（Learning 项目 `tb_comment`，真实数据）**：用 `IGNORE INDEX` 可以在**同一张表上**对比有/无复合索引的执行计划，是验证索引效果的干净手法：

| 执行的查询 | `key` | `Extra` |
| --- | --- | --- |
| 默认（单列 + 复合都存在） | `idx_article_create` | **`Backward index scan`**（无 filesort） |
| `IGNORE INDEX (idx_article_create)` | `idx_article_id` | **`Using filesort`** |
| `IGNORE INDEX (idx_article_id)` | `idx_article_create` | `Backward index scan` |

两个结论：

1. **有复合索引时 `Extra` 显示 `Backward index scan`** —— MySQL 8.0 会**反向扫描**索引来满足 `ORDER BY create_time DESC`，所以不需要额外排序。看到这个词就说明排序走了索引。
2. **第三行证明单列 `idx_article_id` 是冗余的** —— 复合索引 `(article_id, create_time)` 以 `article_id` 为最左列，按最左前缀原则已完全覆盖单列索引的作用。留着它只会白白增加写入维护成本和存储。**加完复合索引后应该把被覆盖的单列索引删掉**（`DROP INDEX idx_article_id ON tb_comment`）。这就是"索引不是越多越好"的具体体现。

**面试怎么答**：先答"能消除 filesort"，再答**为什么**——等值列在前、排序列在后，B+ 树局部有序所以省掉排序。追问方向通常是「范围查询为什么不能放排序前面」（因为范围列之后的列在 B+ 树里不再全局有序）。**配合 EXPLAIN 前后对比讲，说服力最强**；如果能补一句"加完复合索引后我把被覆盖的单列索引删了"，说明你懂最左前缀的实际含义，而不只是会加索引。

---

### 索引不是越多越好

**问题**：既然索引能加速查询，是不是给每个字段都建索引最好？

**答案**：不是。每个二级索引都是一棵独立的 B+ 树，**写入时（INSERT/UPDATE/DELETE）都要同步维护**，索引越多写入越慢、占空间越大。只给**确定会出现在 WHERE / ORDER BY / JOIN 条件里**的字段建索引。

**本项目实例**：`tb_article` 只建了 `idx_user_id`、`idx_create_time`、`idx_category_id` 三个，对应"我的文章"、"列表按时间倒序"、"按分类筛选"三个确定查询。

**面试怎么答**：答"索引是空间和写入性能换查询性能的权衡"，然后**举出自己项目里实际建了哪几个、分别对应什么查询** —— 比背理论可信得多。

---

# 数据库约束与异常

### DuplicateKeyException 与唯一约束双保险

**问题**：唯一约束冲突时怎么给用户准确提示？能不能只靠捕获数据库异常？

**答案**：**不能只靠数据库异常**，要"应用层先查 + 数据库兜底"两层：

1. **应用层**：Service 里先查重，命中就主动抛 `BusinessException(400, "分类名已存在")` → 文案准确、可控。
2. **数据库兜底**：唯一索引仍然保留。因为两个并发请求可能**同时**通过第 1 步的检查，此时数据库的唯一约束会拦住第二个，防止脏数据。

反过来只靠数据库有致命问题：异常消息只有 SQL 错误文本，解析约束名很脆弱；而且像 `GlobalExceptionHandler` 里写死一句 `"用户名已存在！"`，换个表就变成**错误提示**。

**本项目实例**：`GlobalExceptionHandler.java` 第 30~34 行把 `DuplicateKeyException` 的提示写死成"用户名已存在！"。2026-09-15 加分类模块时暴露：`tb_category.name` 有 `uk_name` 唯一约束，添加重名分类会误报"用户名已存在"。

**面试怎么答**：答"先查后插给准确文案 + 唯一索引兜底防并发"，并主动指出**为什么不能依赖解析异常文本**。这是设计题，能体现你想到了并发。

---

# MyBatis-Plus

### Wrapper（条件构造器）是什么，必须传吗

**问题**：`xxxMapper.selectList(wrapper)` 里的 `wrapper` 是什么？必须传吗？

**答案**：`Wrapper` 是 MyBatis-Plus 的**条件构造器** —— 用 Java 链式调用拼装 SQL 的 `WHERE` / `ORDER BY` / `SELECT` 片段，替代手写 XML 里的 `<if test="...">` 动态 SQL，也避免手拼字符串（拼错逗号、SQL 注入）。

**参数位必须给，但可以传 `null`。** 反编译你项目里的 `mybatis-plus-core-3.5.5.jar` 可以确认，`BaseMapper` 只有一个签名、**没有无参重载**：

```
public abstract java.util.List<T> selectList(com.baomidou.mybatisplus.core.conditions.Wrapper<T>);
```

所以：

```java
categoryMapper.selectList(wrapper);   // ✅ 带条件
categoryMapper.selectList(null);      // ✅ 合法：无条件，等于 SELECT * FROM tb_category
categoryMapper.selectList();          // ❌ 编译不过，不存在这个重载
```

MP 内部对 `null` 有判断，不会拼出 `WHERE null`，而是直接不带 WHERE 子句。

**继承体系**（记住"Lambda 版"和"普通版"两条线就够）：

```
Wrapper<T>（抽象根）
├── AbstractWrapper<T>           提供 eq/ne/gt/ge/lt/le/like/in/between/orderBy...
│   ├── QueryWrapper<T>          字段名用【字符串】
│   └── UpdateWrapper<T>         同上 + set()（用于 UPDATE）
└── AbstractLambdaWrapper<T>
    ├── LambdaQueryWrapper<T>    字段名用【方法引用】  ← 项目里用这个
    └── LambdaUpdateWrapper<T>   同上 + set()
```

**为什么该用 Lambda 版**：`LambdaQueryWrapper` 用 `Category::getName` 这种**方法引用**，字段名写错**编译期就报错**；`QueryWrapper` 用 `eq("name", ...)` 字符串，写错只能等运行期报 `Unknown column`，而且字段改名后 IDE 无法帮你重构。

常用方法速查（Lambda 版，`Category::getXxx` 对应数据库列 `xxx`）：

| 方法 | 生成的 SQL 片段 |
| --- | --- |
| `eq` / `ne` | `= ?` / `<> ?` |
| `gt` / `ge` / `lt` / `le` | `> ?` / `>= ?` / `< ?` / `<= ?` |
| `like` / `likeLeft` / `likeRight` | `LIKE '%?%'` / `'%?'` / `'?%'` |
| `in` / `notIn` | `IN (...)` / `NOT IN (...)` |
| `isNull` / `isNotNull` | `IS NULL` / `IS NOT NULL` |
| `between` | `BETWEEN ? AND ?` |
| `orderByAsc` / `orderByDesc` | `ORDER BY ... ASC/DESC` |
| `select` | 只查指定列（配合 `selectPage` 省带宽） |
| `and` / `or` / `nested` | 嵌套条件；**`or` 要用 `nested` 包起来**，否则优先级会出错 |

**本项目实例**：`ArticleServiceImpl` 全篇在用 —— 列表查询用 `LambdaQueryWrapper` + `wrapper.select(...)` 只查轻量列；更新用 `LambdaUpdateWrapper` 显式 `.set(...)`。

```java
// 分类列表：无条件但要排序 —— 仍然要 new 一个 wrapper
List<Category> list = categoryMapper.selectList(
    new LambdaQueryWrapper<Category>().orderByAsc(Category::getId));

// 查重名
boolean exists = categoryMapper.exists(
    new LambdaQueryWrapper<Category>().eq(Category::getName, dto.getName()));
```

**⚠️ 一个被广泛误传的点，已用字节码核实**：`exists(wrapper)` **并不比 `selectCount(wrapper) > 0` 快**。反编译 `BaseMapper.exists` 的字节码，它内部就是直接调 `selectCount`：

```
2: invokeinterface  // InterfaceMethod selectCount:(...Wrapper;)Ljava/lang/Long;
...
17: lconst_0
18: lcmp            // 和 0 比较
```

两者生成的 SQL 完全相同（都是 `SELECT COUNT(*)`）。网上很多文章说 `exists` 会优化成 `LIMIT 1`，**在 MyBatis-Plus 里是错的**。用哪个只看可读性：单纯判断存在用 `exists` 更顺口，需要具体数字才用 `selectCount`。

**判断"是否存在"不要用 `selectOne`。** `selectOne(wrapper)` 做查重有两个问题：

1. **白查一整行**：它会把匹配的记录查出并映射成实体，而查重只需要一个布尔值。`exists`/`selectCount` 只让数据库返回一个计数。
2. **隐含依赖唯一索引**：`selectOne` 匹配到**多行**时会抛 `TooManyResultsException`。所以用它做查重的正确性，其实建立在"那条唯一索引确实存在"之上 —— 索引一旦被去掉（比如为了排查性能问题临时删掉），查重就直接 500。

判断存在用 `exists()`：语义直白（返回 `boolean`，没有 `null` 风险），也不依赖索引。

（另注：`selectCount` 返回的是包装类型 `Long`，理论上可能为 null，所以 `exists` 内部做了 `null != count && count > 0` 判断。）

**面试怎么答**：这题属于"工具类用法"，一般不会深问，但**能顺带展示两件事**：一是知道 Lambda 版 vs 字符串版的区别（编译期安全），二是**亲自反编译核实过库的实现、不盲信博客**。后者是很好的加分项 —— 被问"你怎么确认一个 API 的真实行为"时，答"反编译看字节码 / 看源码"。

---

### N+1 查询与 selectBatchIds

**问题**：列表接口要显示关联表的字段（如文章列表显示作者昵称），怎么查？

**答案**：**先收集本页所有外键 id，去重，再用一次 `selectBatchIds` 批量查回来，装进 Map 供拼装**。总查询次数 = 2 次（分页查询 1 次 + 批量查询 1 次），与页大小无关。

**错误做法**：在 `stream().map()` 里对每条记录调一次 `userMapper.selectById()` —— 10 条记录就是 10 次 SQL，这就是 **N+1**（1 次主查询 + N 次关联查询）。

```java
List<Long> userIds = records.stream().map(Article::getUserId).distinct().toList();
Map<Long, String> nicknameMap = userIds.isEmpty() ? new HashMap<>()
    : userMapper.selectBatchIds(userIds).stream()
        .collect(Collectors.toMap(User::getId,
            u -> u.getNickname() != null ? u.getNickname() : "默认昵称",
            (oldVal, newVal) -> oldVal));   // 合并函数：防重复 key 抛异常
```

注意两点：`userIds.isEmpty()` 要短路，否则 `selectBatchIds` 传空集合；`toMap` 的**第三个参数（合并函数）不能省**，否则重复 key 会抛 `IllegalStateException`。

**本项目实例**：`ArticleServiceImpl.java` 第 77~88 行（文章列表查作者昵称）。**评论列表是同一个问题，直接复用这个模式。**

**面试怎么答**：先定义 N+1，再说自己的解法，最后补一句"查询次数从 1+N 降到 2"。追问方向：**数据量极大时批量查会不会有问题**（答：可以进一步用 JOIN 一次查完，或对 id 分批）。

---

### UpdateWrapper 显式指定列

**问题**：更新一条记录时，怎么避免把不该动的字段覆盖掉？

**答案**：用 `LambdaUpdateWrapper` **显式 `.set()` 每一个要更新的字段**，而不是先查出实体、改几个字段、再整体 `updateById`。

因为整体 update 会把实体里所有非 null 字段都写回数据库 —— 你只是想改标题，结果把 `create_time`、`view_count` 一起覆盖成查出来的旧值（`view_count` 甚至可能丢掉并发期间的累加）。

```java
LambdaUpdateWrapper<Article> wrapper = new LambdaUpdateWrapper<>();
wrapper.eq(Article::getId, id)
       .set(Article::getTitle, dto.getTitle())
       .set(Article::getContent, dto.getContent())
       .set(Article::getUpdateTime, LocalDateTime.now());
articleMapper.update(null, wrapper);   // 第一个参数传 null，条件全写在 wrapper 里
```

**本项目实例**：`ArticleServiceImpl.updateArticle`，注释写明"避免覆盖 create_time 和 view_count"。

**面试怎么答**：答"字段级更新 vs 整体覆盖"，并说明**并发场景下整体覆盖会丢更新**。这其实和数据库的"更新丢失"问题是同一个话题，可以顺势带到乐观锁（`@Version`）。

---

# 表设计

### NOT NULL DEFAULT 0 与 NPE

**问题**：计数类字段（浏览量、点赞数）建表时要注意什么？

**答案**：一定要写成 **`NOT NULL DEFAULT 0`**。如果允许 NULL，代码里做 `count + 1` 就会 **NPE**。

**本项目实例**：`tb_article.view_count INT NOT NULL DEFAULT 0`（这条做对了）；但 `ArticleServiceImpl.selectArticleById` 第 58 行有 `article.getViewCount() + 1` —— 假如这个字段变成可空，这里立刻空指针。**写新表的计数字段时保持一致：`NOT NULL DEFAULT 0`。**

**面试怎么答**：属于"防御性设计"的小点，可以在讲表设计时顺带提一句"计数字段一律 NOT NULL DEFAULT 0，避免应用层做算术时空指针"。

---

### 为什么不建物理外键

**问题**：`tb_article.category_id` 关联 `tb_category.id`，为什么不加 `FOREIGN KEY`？

**答案**：互联网项目普遍**不用物理外键**，原因有三：

1. **性能**：每次写入都要加锁检查引用完整性，高并发下是额外开销。
2. **扩展性**：分库分表之后，关联的两张表可能不在同一个库，外键根本无法维护。
3. **灵活性**：删除/迁移数据时外键会带来意外的级联或阻断。

关联关系的正确性改由 **应用层 + 索引**保证（索引保证查询性能，应用层保证引用有效）。这也是《阿里巴巴 Java 开发手册》的明确要求。

**代价（要主动说出来）**：数据库不再帮你挡悬空引用，**应用层必须自己校验**。例如 `tb_article.category_id` 可空且无外键，那么删除分类时数据库**不会**阻止你，删除后文章的 `category_id` 就悬空了 —— 必须由应用层决定怎么处理。同理，发表评论前必须校验 `article_id` 存在，否则会产生"评论挂在不存在的文章上"的脏数据。

**本项目实例**：`tb_article`（`idx_category_id`）、`tb_comment`（`idx_article_id`）都只有普通索引，无外键。

**面试怎么答**：答完三条理由**一定要补代价和应对**——"因为数据库不挡了，所以我们在应用层校验"，这样才是完整回答，否则听起来像只会背结论。

---

### 平铺评论 vs 盖楼

**问题**：评论表要不要 `parent_id` 支持回复？

**答案**：取决于产品形态，两种都常见。

- **平铺**（本项目的选择）：表里只有 `article_id / user_id / content / create_time`。实现简单，查询就是一个分页列表。
- **盖楼/回复**：加 `parent_id BIGINT NOT NULL DEFAULT 0`（`0` 表示顶级评论）。列表**仍然返回扁平结构 + `parentId` 字段**，由前端按 `parentId` 组装成树 —— 后端不做嵌套，分页才不会被破坏。

为什么不让后端直接返回嵌套结构：一旦嵌套，分页的语义就乱了（一页 10 条是 10 条顶级评论还是 10 条含回复？），而且"只查这一页的回复"很难高效实现。

**本项目实例**：`tb_comment` **没有** `parent_id`，所以只做平铺评论（这是 2026-09-13 建表时就定下的设计，见 `文章模块接口文档.md`）。

**面试怎么答**：被问"评论怎么支持盖楼"，答"加 `parent_id`，列表返回扁平结构由前端组装树，后端保持分页简单"。**追问方向**：回复数量多怎么办（答：只加载前 N 条回复 + 点击展开）。

---

# Java 基础与 Stream

### Collectors.toMap 的合并函数是什么

**问题**：`Collectors.toMap(k, v, (oldVal, newVal) -> oldVal)` 里的第三个参数是什么意思？为什么必须写？

**答案**：它是**合并函数（merge function）**，唯一作用是规定 **key 重复时保留哪一个**。

`toMap` 有三个重载：

```java
toMap(keyMapper, valueMapper)                              // 2 参
toMap(keyMapper, valueMapper, mergeFunction)               // 3 参
toMap(keyMapper, valueMapper, mergeFunction, mapSupplier)  // 4 参
```

因为 `Map` 的 key 唯一，当流里有两条数据算出**同一个 key** 时 `toMap` 无法决定保留谁 —— 给了合并函数就用它的返回值，**不给（2 参版本）就直接抛异常**：

```
java.lang.IllegalStateException: Duplicate key 1 (attempted merging values 张三 and 张三丰)
```

lambda 拆解（参数名是惯例，不是关键字）：

```java
(oldVal, newVal) -> oldVal
   ↑        ↑         ↑
 参数1     参数2     返回值
```

真实语义是 `(已经放进 Map 的值, 这次新来的值) -> 保留哪个`。底层走 `Map.merge`，而 `merge` 内部的调用是 `fn.apply(旧值, 新值)`，所以**第一个参数一定是先到的**。三种常见写法：

```java
(o, n) -> o            // 保留【先出现】的
(o, n) -> n            // 用【后出现】的覆盖
(o, n) -> o + "," + n  // 两个都留（拼字符串）
```

**⚠️ 一个关键的判断**：合并函数**只在 key 真的会重复时才有意义**。本项目里 key 来自 `selectBatchIds`（`WHERE id IN (...)` 查主键），返回的 `id` 天然唯一 → **合并函数永远不会被调用**，写 `oldVal` 还是 `newVal` 结果完全一样。它的定位是**安全网而非业务逻辑**：不写则万一数据出现重复 key 就直接抛异常、接口 500；写了则安静地按规则选一个。所以"理论上不会重复但仍然写上"是合理的防御性写法。

**什么时候它是真正的业务逻辑**：key 本来就会重复时。例如想得到「每个作者最新一篇文章的标题」：

```java
Map<Long, String> map = articles.stream()
        .collect(Collectors.toMap(Article::getUserId, Article::getTitle, (o, n) -> n));
```

这时选 `o` 还是 `n` 直接决定结果对错。

**⚠️ 另一个坑**：合并函数**返回 `null` 时这个 entry 会被从 Map 里静默删除**（`Map.merge` 的语义，不报错）。排查"Map 里为什么少了一个 key"时先看这里。

**替代品**：想「一个 key 对应一组值」而不是二选一，用 `groupingBy` —— 它天然处理重复 key，不需要合并函数：

```java
Map<Long, List<Article>> byUser = articles.stream()
        .collect(Collectors.groupingBy(Article::getUserId));
Map<Long, Long> countByUser = articles.stream()
        .collect(Collectors.groupingBy(Article::getUserId, Collectors.counting()));
```

**本项目实例**：`ArticleServiceImpl`（第 82~87 行）和 `CommentServiceImpl` 批量查作者昵称时都用了。两处合并函数写得不同（`oldVal` / `newVal`），但**行为完全相同**，因为 `selectBatchIds` 保证 key 不重复。

**面试怎么答**：这题常以"`toMap` 报 Duplicate key 怎么解决"的形式出现。答"加第三个参数合并函数，并说明它决定撞车时保留谁"；**加分点**是补一句"我的场景 key 来自主键批量查询、天然不重复，写它纯粹是兜底，不是业务规则"—— 显示你清楚自己每一行代码的作用，而不是照抄。追问方向：`toMap` 和 `groupingBy` 怎么选（答：一个值用 `toMap`，一组值用 `groupingBy`）。

---

# Redis 与缓存

### Cache Aside：更新时删缓存还是更新缓存

**问题**：数据更新时，缓存应该"删除"还是"更新"？

**答案**：**删除缓存（Cache Aside / 旁路缓存）**，且顺序是 **先更新数据库 → 再删缓存**。理由是三条：

1. **更新缓存在并发下会写脏。** 两个请求并发更新同一条数据：A 改 DB 为 v1，B 改 DB 为 v2（DB 最终是 v2），但"写缓存"这一步的到达顺序可能反过来 —— 缓存里最终留下 v1，与 DB 的 v2 长期不一致，且**没有任何机制会纠正它**（直到 TTL 过期）。而"删除"是**幂等**的，谁先谁后结果一样（都是"缓存没了"）。
2. **避免无效更新（懒加载）。** 更新缓存意味着每次写都产生一次缓存写，但这份数据可能压根没人读 —— 白写。删除则把"重建缓存"推迟到真正有人读的时候。
3. **降低更新成本。** 有些缓存值需要多表聚合才能算出来（比如文章详情要拼作者昵称）。"更新缓存"就得重新算一遍全部聚合；"删除"什么都不用算。

**Cache Aside 的标准流程**：
- **读**：查缓存 → 命中直接返回 → miss 查 DB → 回填缓存（带 TTL）
- **写**：更新 DB → **删除**缓存（不是更新）

**⚠️ "先更新 DB 再删缓存"仍有一个竞态窗口**：读请求 A 查缓存 miss → 查 DB 拿到旧值 → （此时写请求 B 更新了 DB 并删了缓存）→ A 才把旧值回填进缓存。缓存里就长期是旧值了。缓解手段是**延迟双删**（更新 DB 后删一次缓存，延迟几百毫秒再删一次），因为"回填"这个动作通常在毫秒级完成。**极端情况下仍不保险**，彻底解法是给缓存加版本号或走 binlog 订阅（Canal）。

**⚠️ 缓存粒度与"反向索引"难题**：如果缓存的是聚合对象（如 `ArticleDetailVO` 里含 `authorNickname`），那么**用户改昵称时，你不知道该失效哪些缓存** —— 因为需要"按 userId 反查他有哪些文章被缓存了"，而 Redis 里没有这个索引。两个应对：

- **接受 TTL 内的不一致**（推荐，博客系统完全够用）：改昵称后最多脏一个 TTL 周期，而昵称变更极低频。
- 额外维护"用户 → 文章 id 列表"的索引集合，改昵称时批量失效 —— 复杂度和收益不成正比，一般不值得。

**这也说明缓存粒度是个真实取舍**：缓存整体对象读取最快，但失效颗粒度粗；拆开缓存（文章一份、昵称一份）失效精准，但一次请求要查多次 Redis。

**本项目实例**：Learning 项目 `GET /article/{id}`。`ArticleDetailVO` 含 `authorNickname`（来自 `tb_user`），所以存在上面的反向索引问题。2026-09-16 接入。

**面试怎么答**：这题几乎是缓存必问。答"用 Cache Aside，先更新 DB 再删缓存"，然后**主动说清为什么是删不是更新**（并发写会脏、避免无效更新、聚合值重建成本）。**加分点**是继续讲出那个残留竞态窗口和延迟双删，并说明"为什么不追求强一致"（缓存的初衷就是牺牲一致性换性能，TTL 兜底）。追问方向：如果业务真要求强一致怎么办（答：那就别缓存，或者用分布式锁/Canal 订阅）。

---

### 缓存 TTL 该设多久

**问题**：缓存的过期时间按什么依据来定？

**答案**：TTL 由两个因素决定，**跟"用户会看多久"无关**：

1. **你能容忍多久的数据不一致（staleness window）。** TTL 是"缓存允许比数据库旧多久"的上限。业务越不能容忍脏读，TTL 越短。
2. **内存占用 vs 命中率的权衡。** TTL 长 → 命中率高、DB 压力小，但内存占用大、数据更旧；TTL 短 → 数据新鲜，但命中率低、回源多。

另外还要按数据特性分类：**读多写少、变更低频**的数据（文章详情、分类列表）TTL 可以放长（几十分钟到几小时）；**变更频繁**的数据（库存、点赞数）TTL 要短，或者干脆不用 TTL 兜底而靠主动失效。

**⚠️ 一个常见错误**：把 TTL 理解成"用户大概会用多久"（比如"用户读一篇文章约 30 分钟，所以 TTL 设 30 分钟"）。这个推理是错的 —— 用户读多久和缓存该活多久没有逻辑关系。真要按用户行为算，用户停留越久反而越希望缓存一直有效（TTL 更长）。**定 TTL 时要问的是"我允许这份数据旧多久"，而不是"用户会用多久"。**

**⚠️ 防雪崩**：大批 key 设成同一个 TTL，会在同一时刻集体失效，请求瞬间全打到 DB（缓存雪崩）。所以 TTL 要**加随机量**：

```java
long ttl = 30 * 60 + ThreadLocalRandom.current().nextInt(300); // 30分钟 ± 5分钟
```

**本项目实例**：Learning 项目文章详情缓存，2026-09-16 接入。文章改动低频，TTL 可取 30 分钟量级，并加随机偏移防雪崩。

**面试怎么答**：先答"TTL 取决于能容忍的不一致时长和内存/命中率权衡"，**再主动纠正那个常见误解**（TTL 不是用户使用时长）—— 这个纠正很能体现理解深度。然后补一句"同一批 key 要加随机偏移防雪崩"。

---

### 缓存穿透：空对象缓存 vs 布隆过滤器

**问题**：有人反复请求一个**不存在**的 id（如 `articleId=999999`），缓存永远不命中、每次都打到 DB —— 怎么防？

**答案**：两种主流解法，**选哪个取决于 key 空间和攻击强度**。

| 方案 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| **空对象缓存** | 查 DB 为空也在缓存里写一个"空"标记（短 TTL） | 实现极简，无需额外组件 | 大量不同的不存在 id 会占用内存（所以 TTL 要短） |
| **布隆过滤器** | 启动时把所有存在的 id 预热进布隆过滤器；请求先过过滤器，判定"一定不存在"就直接拒绝 | 内存极省，能挡住海量随机 id | 有**误判率**（说不存在一定不存在，说存在可能不存在）；**原生不支持删除**元素；需要预热和与 DB 同步维护 |

**选型**：
- **本项目（博客系统）→ 空对象缓存。** id 空间有限、数据量小、不存在"遍历几百万 id"的攻击场景，空对象缓存足够，且不用引入和维护布隆过滤器。
- **布隆过滤器适合**：key 空间巨大 + 恶意流量明显（如电商被刷不存在的商品 id）。此时空对象缓存反而会被撑爆内存。

**⚠️ 实现空对象缓存的坑**：不能直接把 `null` 写进 Redis —— 序列化器通常不接受，而且读出来无法区分"缓存了空值"和"缓存没命中"。标准做法是存一个**哨兵值**并单独判断：

```java
private static final String NULL_SENTINEL = "__NULL__";

String json = redis.opsForValue().get(key);
if (json != null) {
    if (NULL_SENTINEL.equals(json)) {
        throw new BusinessException(404, "文章不存在");   // 命中空值缓存，不打 DB
    }
    return JSON.parseObject(json, ArticleDetailVO.class);
}
// 真 miss：查 DB
Article article = articleMapper.selectById(id);
if (article == null) {
    redis.opsForValue().set(key, NULL_SENTINEL, 2, TimeUnit.MINUTES);  // 空值 TTL 要短
    throw new BusinessException(404, "文章不存在");
}
```

空值的 TTL 要**明显短于正常值**（如 2 分钟 vs 30 分钟）—— 因为一旦这个 id 后来真的被创建了，短 TTL 能让它更快恢复正常。

**本项目实例**：Learning 项目文章详情缓存，2026-09-16 接入，选空对象缓存。

**面试怎么答**：两种都要能讲，然后**给出选型依据**（key 空间大小、是否有恶意流量、能否接受误判）。只说"用布隆过滤器"而不说场景，会显得像背答案。追问方向：布隆过滤器为什么不能删元素（答：位数组被多个 key 共享，清位会影响别的 key；要用计数布隆过滤器）、误判的方向性（答：假阳性——说不存在必然不存在，说存在可能不存在）。

---

### 计数器什么时候回写数据库（惰性 vs 定时）

**问题**：把浏览量这类高频计数放到 Redis 累加后，什么时候写回数据库？

**答案**：两种策略，取决于"能接受多大的丢失窗口"。

#### 策略一：惰性回写（在缓存 miss 时同步）

只在**缓存 miss 的分支里**把 Redis 的当前计数写回 DB。因为 miss 是读流量自然触发的，所以：

- **回写时机** = 下次 miss 时，也就是 TTL 过期后的第一次访问
- 热文：每 30 分钟（一个 TTL 周期）回写一次
- **1 万次访问可能只写 2 次库** —— 这就是省下的写压力

**能成立的关键是播种那一步必须用 `setIfAbsent` 而不是 `set`**：

```java
stringRedisTemplate.opsForValue().setIfAbsent(viewsKey, String.valueOf(article.getViewCount()));
Long views = stringRedisTemplate.opsForValue().increment(viewsKey);
```

miss 时从 DB 读到的是**旧值**（如 1），而 Redis 里已经累积到 10000。若用 `set` 会把 Redis 覆盖成 1，**累积的 9999 次浏览当场全丢**。`setIfAbsent` 只在 key 不存在时写入，天然幂等，也正好用来"只在首次播种"。

**三个已知代价**：

1. **回写节奏跟着读流量走，不可控。** 冷文可能几天没人访问 → DB 长期是旧值（但**会自愈**：下次访问立刻回写，最终一致）。
2. **Redis 崩溃会丢一个周期的增量。** 增量在写回 DB 之前只存在于 Redis 一处。浏览量可以接受；**订单金额、库存扣减绝不能这么做**。
3. **计数 key 不能设 TTL**（或必须远长于内容缓存的 TTL）。因为命中分支是直接 `increment` 而没有播种逻辑 —— key 一旦过期，`increment` 会从 0 创建并返回 1，**把真实计数抹掉**。

#### 策略二：定时回写 + dirty set

每次 `INCR` 顺手把 id 记进一个"待回写"集合，再用 `@Scheduled` 定期批量刷回 DB：

```java
stringRedisTemplate.opsForSet().add("learning:article:views:dirty", String.valueOf(id));
```

```java
@Scheduled(fixedDelay = 5 * 60 * 1000)          // 每 5 分钟
public void flushViews() {
    Set<String> dirty = stringRedisTemplate.opsForSet().members(DIRTY_KEY);
    if (dirty == null || dirty.isEmpty()) return;
    for (String sid : dirty) {
        String v = stringRedisTemplate.opsForValue().get(CacheKeys.articleViews(Long.valueOf(sid)));
        if (v == null) continue;
        articleMapper.update(null, new LambdaUpdateWrapper<Article>()
                .eq(Article::getId, Long.valueOf(sid))
                .set(Article::getViewCount, Long.valueOf(v)));
        stringRedisTemplate.opsForSet().remove(DIRTY_KEY, sid);
    }
}
```

好处：固定节奏、冷文也能及时落库、崩溃丢失窗口从 30 分钟缩到 5 分钟。代价：多一个调度器，且必须自己维护 dirty 索引（原因见下一条）。

**本项目实例**：Learning 项目文章浏览量（`ArticleServiceImpl.selectArticleById`），2026-09-16 接入，**采用策略一（惰性回写）**。对博客足够；面试时能说清代价和替代方案即可。

**面试怎么答**：先说自己的选型，再**主动说清回写时机**（"miss 时同步，所以回写节奏跟着读流量走"）和**丢失窗口**（"Redis 崩溃会丢一个周期的增量"）。**加分点是那句取舍**："浏览量这种非关键计数可以接受，换成订单金额就必须改成定时回写或用可靠消息。"追问方向：怎么保证不丢（答：定时回写 + dirty set，或让 Redis 开 AOF）。

---

### 为什么生产环境禁用 KEYS 命令

**问题**：想找出所有符合某模式的 key（如 `article:views:*`），能不能用 `KEYS`？

**答案**：**不能。`KEYS` 是生产环境的禁忌命令。**

三个原因：

1. **Redis 是单线程处理命令的**（命令执行本身串行，IO 多路复用只解决网络等待）。`KEYS` 执行期间，**整个实例的其他所有请求全部排队等待**。
2. **`KEYS` 的复杂度是 O(N)** —— N 是库里的 key 总数，不是匹配数。它有全量扫描，无法提前剪枝。
3. **key 越多阻塞越久**：几十万个 key 能卡住几百毫秒甚至几秒。对一个要求毫秒级响应的服务来说，这等于**一次线上故障**。

官方文档对此的措辞是：**`KEYS` 只应在调试时使用，不要在生产环境使用。**

**替代方案**：

| 方案 | 说明 |
| --- | --- |
| **`SCAN`** | 游标式增量遍历，每次只返回少量元素，不阻塞。代价：可能返回重复元素（需客户端去重）、要多次调用才遍历完、期间新增/删除的 key 不保证被看到 |
| **自己维护索引**（推荐） | 写入时就登记到一个 Set/ZSet 里（如 dirty set），需要时直接读索引，复杂度 O(1) 取集合 + O(M) 遍历目标。这也是"定时回写"必须自己维护 dirty set 的原因 |

**本项目实例**：Learning 项目浏览量定时回写（若采用）必须用 dirty set 记录脏 id，而不能 `KEYS learning:article:views:*` 去扫。

**面试怎么答**：这是区分"用过 Redis"和"背过 Redis"的题。答"用 `SCAN`，不要用 `KEYS`"，然后**说清为什么**：Redis 单线程 + `KEYS` 是 O(N) 全量扫描会阻塞整个实例。**再补一层**："更好的做法是写入时自己维护索引，根本不用扫" —— 这句会让人觉得你真的想过生产场景。追问方向：`SCAN` 有什么缺点（答：可能重复、非快照、需多次调用）。

---

### Redis key 到底占多少内存，永久保存会不会爆

**问题**：把浏览量这类计数器永久存在 Redis 里（不设 TTL），会不会把内存占满？

**答案**：关键认知是 —— **占内存的是「有多少个 key」，不是「访问了多少次」**。

浏览量从 0 涨到 1000 万，key 数量不变，只是 value 从 `"0"`（1 字节）变成 `"10000000"`（8 字节）。**只增长 7 字节。**

**一个小 String key 的内存构成**（Redis 7 / jemalloc）：

| 部分 | 大致大小 |
| --- | --- |
| key 字符串（SDS，如 `learning:article:views:1`） | ~29 字节 |
| `redisObject` 头 | 16 字节 |
| 哈希表 `dictEntry` | 24 字节 |
| 哈希桶指针（摊薄） | ~8 字节 |
| value | **0 字节** |

**value 为什么是 0 字节**：`INCR` 产生的值能放进 `long` 时，Redis 用 `OBJ_ENCODING_INT` 编码，**直接把数字塞进 `robj` 的指针字段**，不再单独分配内存。

合计**约 80 字节/key**：

| key 数量 | 总内存 |
| --- | --- |
| 1,000 | ~80 KB |
| 10,000 | ~0.8 MB |
| 100,000 | ~8 MB |
| 1,000,000 | ~80 MB |

**10 万个 key 才 8 MB。** 只有当 key 数量达到上亿量级才需要认真考虑 TTL 或分片。

**什么时候才真的会爆**：不是"访问量涨了"，而是 **key 的基数没有上界** —— 比如每个用户、每次会话、每次请求建一个 key。**只要有天然上界（如"每篇文章一个"），就是安全的。**

**别猜，直接量**：

```bash
redis-cli MEMORY USAGE learning:article:views:1      # 精确到字节
redis-cli INFO memory | grep used_memory_human       # 整体
```

**若仍然想设 TTL，有三个坑**：

1. **`INCR` 不会刷新 TTL。** 很多人以为"每次访问都 INCR，TTL 会续上"—— 不会。`INCR` 只改值、不碰 TTL，过期时间从建 key 那一刻算死。要滑动过期必须手动 `EXPIRE`。
2. **TTL 必须远大于内容缓存的 TTL。** 因为缓存的命中分支是直接 `increment` 而没有播种逻辑（播种只在 miss 分支）。一旦计数 key 先于内容缓存过期，`increment` 会在不存在的 key 上**从 0 创建并返回 1**，把真实计数抹掉。
3. **更彻底的做法是"回写后删 key"**：定时回写把值刷进 DB 后删掉计数 key，下次 miss 时从 DB 重新播种。这样内存只留"最近活跃"的 key，自动收敛。**但必须同时删内容缓存**，否则回到坑 2。

**⚠️ 共享 Redis 的额外风险**：如果这台 Redis 是多项目共用的，要确认两个配置：

- `maxmemory = 0`（不限制）→ 不用担心
- 若设了 `maxmemory` 且 policy 是 **`noeviction`** → 内存满时 `INCR` **直接报错**
- 若 policy 是 **`allkeys-lru`** → 计数 key **可能被淘汰**，累计值丢失

**这里有个设计层面的要点**：把 Redis 当**缓存**用时配 `allkeys-lru` 是标准做法；但当**存储**用时（计数是权威值）就**不能放在会被淘汰的地方** —— 否则等于把权威数据寄存在随时会被清理的地方。

**本项目实例**：Learning 项目 `learning:article:views:{id}`，2026-09-16 接入，**不设 TTL**。上界 = 文章数 × ~80 字节，博客系统完全无压力。前提是 `views` key 生命周期 ≥ `detail` 缓存生命周期。

**面试怎么答**：被问"Redis 内存会不会被撑爆"，答"**看 key 的基数有没有上界**，而不是看访问量"—— 这个角度比背"要设 TTL"更准确。再补一句"小 String key 约 80 字节，而且整数用 `OBJ_ENCODING_INT` 编码不额外占空间"。追问方向：怎么精确测（答：`MEMORY USAGE`）、缓存和存储的 `maxmemory-policy` 该怎么配（答：纯缓存用 `allkeys-lru`，当存储用 `noeviction`，两者不能混）。

---

### 缓存三兄弟：穿透 / 击穿 / 雪崩怎么区分

**问题**：缓存穿透、缓存击穿、缓存雪崩经常被混为一谈，怎么区分？

**答案**：先看这张表 —— **关键看"数据存不存在"和"范围多大"**：

| | **穿透** | **击穿** | **雪崩** |
| --- | --- | --- | --- |
| **数据存不存在** | **不存在** | **存在** | 存在 |
| **范围** | 单个/多个不存在的 key | **单个热点 key** | **大量 key** |
| **触发条件** | 一直查不存在的数据 | 热点 key **刚失效**的瞬间 | 大量 key **同时失效**，或 Redis 整体挂 |
| **后果** | 每次都打 DB（可被恶意利用） | 瞬时并发打 DB | DB 被整体打垮 |
| **对策** | 空对象缓存 / 布隆过滤器 | 互斥锁重建 / 逻辑过期 | TTL 加随机 + 降级 + 限流 |

**一句话记忆**：

- **穿透** = 数据**本来就没有**，缓存"挡不住"
- **击穿** = 数据**有**，但**一个热点**的缓存破了，一群请求冲进 DB
- **雪崩** = **一大片**缓存同时破了（或缓存层整个不可用）

**三种对策的细节**：

1. **穿透 → 空对象缓存**：查 DB 为空也写一个哨兵值（短 TTL）。不能存 `null`（序列化器不接受，且读出来分不清"空值"和"未命中"）。选它还是布隆过滤器取决于 **key 空间大小**——key 有上界、无恶意流量就用空对象。
2. **击穿 → 互斥锁**：`setIfAbsent(lockKey, uuid, 10, SECONDS)` 只让一个请求重建，其他等待后重读缓存。**四个坑**：锁必须包住 DB 查询、锁要有过期时间、解锁放 `finally`、重试要有上限。更严谨还要「UUID + Lua 校验后删」防误删别人的锁。替代方案是**逻辑过期**（不设 Redis TTL，过期时间放进 value，发现逻辑过期就返回旧值 + 异步重建）。
3. **雪崩 → TTL 加随机**：`ttl = BASE + random(JITTER)`，把过期时间打散到一个窗口，避免集体失效。另外 Redis 整体宕机也会造成雪崩，这靠**降级**兜底。

**⚠️ 降级要覆盖"依赖不可用"，不只是"依赖返回坏数据"**：很多人的降级只写了"反序列化失败就当 miss"，但**连接失败是另一回事**。若 `redisTemplate.get(...)` 直接抛 `RedisConnectionFailureException`（`RuntimeException`），而你的 catch 只捕获 `JsonProcessingException`，异常会一路冒到全局异常处理器 → **整个接口 500**，而不是降级查 DB。所以缓存操作要单独包一层：任何 Redis 异常都退化成"未命中 / 跳过回填"，**绝不让缓存故障升级成业务故障**。

**本项目实例**（Learning 项目 `ArticleServiceImpl`，2026-09-16~17）：

| 问题 | 代码位置 | 实现 |
| --- | --- | --- |
| Cache Aside | 读 L59~107 / 写 L198~199、L215~216 | 读时回填；写时**删**缓存（不是更新） |
| **穿透** | L66~68（命中哨兵）/ L231~234（写哨兵） | `__NULL__` 哨兵 + 2 分钟 TTL |
| **击穿** | L82~106 | `setIfAbsent` 互斥锁 + 等待重试 + 兜底 |
| **雪崩** | L246 + 降级 L75~78、L249~251 | TTL 30 分钟 ± 5 分钟随机；序列化失败降级 |

**踩过的真实坑（很有讲头）**：锁最初加在 DB 查询**之后** —— 要保护的那次查询在锁外面，**等于没加**。挪进锁内才真正生效。

**面试怎么答**：这题最适合**主动带出来讲项目**，因为它证明的是"踩过并解决了真实问题"而不是背概念。推荐串法：

> "文章详情我做了 Redis 缓存，用 Cache Aside。过程中踩了四类问题。**穿透**用空对象缓存 + 短 TTL，没选布隆过滤器因为博客 id 空间有限、误判和复杂度不划算。**雪崩**给 TTL 加了随机偏移，另外做了降级保证缓存故障不影响接口。**击穿**用 `setIfAbsent` 互斥锁，只让一个请求重建 —— 这里我踩过一个坑：锁本来加在 DB 查询之后，等于没加，挪进锁里才生效。还有一个是**缓存与计数器的冲突**：浏览量要求每次访问都写 DB，缓存要求命中时不查 DB，两者直接矛盾，所以我把浏览量拆出来用 Redis `INCR`，缓存 miss 时才回写。"

**这段话里有设计取舍、有踩坑、有量化**，比"我用了 Redis 做缓存"强得多。追问方向：击穿和穿透的区别（答：数据存不存在）、互斥锁的代价（答：抢不到锁的请求要等待，所以有逻辑过期这个替代方案）、降级怎么做（答：缓存操作包一层，异常退化为不用缓存）。

---

# 计算机网络

### TCP 三次握手与四次挥手

**问题**：TCP 建立连接为什么要三次握手，断开为什么要四次挥手？

**答案**：

**三次握手**（建立连接，双方都要确认"我能发、我能收、你能发、你能收"）：

```
客户端                                服务端
  |------- SYN, seq=x --------------->|     ① 客户端：我要连你，我的序号是 x
  |<--- SYN+ACK, seq=y, ack=x+1 ------|     ② 服务端：收到，我也要连你，序号 y
  |------- ACK, ack=y+1 ------------->|     ③ 客户端：收到，确认
```

**为什么是三次，不是两次？**

1. **防止历史连接。** 如果客户端一个**滞留在网络里的旧 SYN** 突然到达服务端，两次握手的话服务端会立刻建立连接并分配资源，然后干等一个根本不会来的客户端 —— 白白占用。三次握手时，客户端收到这个莫名其妙的 `SYN+ACK` 会回 `RST` 拒绝，服务端不会进入建立状态。
2. **确认双方的收发能力。** 只有三次才能让**双方都确认**对方"能收也能发"：
   - 第 1 次后，服务端知道：客户端能发、自己能收
   - 第 2 次后，客户端知道：自己能发能收、服务端能发能收
   - 第 3 次后，**服务端才知道**：客户端能收、自己能发
   
   两次的话，服务端发完 `SYN+ACK` 就认为连上了，但它**并不知道客户端是否收到了**。

**四次挥手**（断开连接，因为 TCP 是**全双工**，两个方向要分别关闭）：

```
客户端                                服务端
  |------- FIN, seq=u --------------->|     ① 客户端：我没数据要发了
  |<------ ACK, ack=u+1 --------------|     ② 服务端：知道了（但可能还有数据要发）
  |<------ FIN, seq=w --------------- |     ③ 服务端：我也发完了
  |------- ACK, ack=w+1 ------------->|     ④ 客户端：收到
```

**为什么挥手要四次？** 因为**服务端收到 FIN 后，自己的数据可能还没发完**。

- 收到 `FIN` 只表示"客户端→服务端"这个方向没有数据了（**半关闭**）
- 服务端先回 `ACK`（表示收到），然后继续把剩余数据发完
- 发完了再发自己的 `FIN`
- 所以 `ACK` 和 `FIN` **不能合并**，比握手多一次

> **特殊情况下挥手可以是三次**：如果服务端收到 `FIN` 时恰好也没有数据要发了，`ACK` 和 `FIN` 可以合并成一个报文发出去（**延迟确认** + 无数据待发）。这是面试的进阶追问点。

**本项目实例**：Learning 项目的 `GET /article/{id}` 走 HTTP。HTTP/1.1 默认 `Connection: keep-alive`，所以**一次 TCP 连接可以复用多次请求**，不用每个请求都握手。同理，项目里的 **HikariCP 数据库连接池**和 **Redis 的 Lettuce 客户端**都保持长连接 —— 连接池存在的意义之一就是**避免每次访问 DB/Redis 都重新三次握手**。这也是为什么连接池参数（最大连接数、空闲超时）配不好会显著影响吞吐。

**面试怎么答**：这题几乎必问。先画时序图说清流程，再答"**为什么三次**"（历史连接 + 双方收发能力确认）和"**为什么四次**"（全双工，服务端可能还有数据要发，ACK 与 FIN 不能合并）。**加分点**：主动补一句"特定情况下挥手可以合并成三次"，以及把话题落到自己项目上——"连接池/长连接的存在就是为了避免反复握手"。

---

### TIME_WAIT 为什么等 2MSL

**问题**：主动关闭连接的一方，在发完最后一个 `ACK` 后为什么要等 `2MSL` 才真正关闭？

**答案**：`MSL`（Maximum Segment Lifetime）是报文在网络中的最大存活时间。等待 `2MSL` 有两个原因：

**1. 保证最后一个 ACK 能到达对端（让对端能正常关闭）。**

如果客户端发的最后一个 `ACK` 丢了，服务端会超时重传 `FIN`。此时如果客户端**已经彻底关闭**（端口释放），收到重传的 `FIN` 就只能回 `RST`，服务端会收到错误而不是正常关闭。

等 `2MSL` 就留出了窗口：**一个 MSL 用于自己的 ACK 到达对端，一个 MSL 用于对端重传的 FIN 回来**。在这期间收到重传的 FIN，客户端还能重发 ACK。

**2. 让本次连接的所有报文在网络中消散。**

防止"旧连接的延迟报文"被后面**用同一组四元组（源IP:源端口 + 目的IP:目的端口）建立的新连接**收到，造成数据错乱。

**为什么要问这个（面试角度）**：这题考的是"你是不是只知道 TIME_WAIT 存在，而不知道它为什么存在"。

**补充两个常见追问**：

- **TIME_WAIT 只出现在主动关闭方。** 被动关闭方进入的是 `CLOSE_WAIT`，它的常见原因是**代码里忘了 `close()`**（连接一直不释放），会导致句柄耗尽。
- **TIME_WAIT 过多怎么处理？** 先分清是"正常的主动关闭方多"还是"被攻击"。手段有 `SO_REUSEADDR`、调小 `net.ipv4.tcp_fin_timeout`、`tcp_tw_reuse` 等。**但不要用 `tcp_tw_recycle`** —— 它在 NAT 环境下会丢包，已被 Linux 移除。

**本项目实例**：Learning 项目跑在 8080，客户端/浏览器访问时由**服务端主动关闭**还是客户端主动关闭，取决于哪边先发 `FIN`。连接池（HikariCP / Lettuce）复用长连接，本身就大幅减少了 `TIME_WAIT` 的产生。

**面试怎么答**：答两个原因 —— **① 保证最后的 ACK 能到达，让对端正常关闭；② 让旧连接的延迟报文消散，避免污染同四元组的新连接。** 追问方向：`CLOSE_WAIT` 和 `TIME_WAIT` 的区别（答：前者是被动关闭方、通常是代码没 close 导致的泄漏；后者是主动关闭方的正常状态）、`TIME_WAIT` 过多怎么办（答：`tcp_tw_reuse` / 调短超时，**绝不能用已废弃的 `tcp_tw_recycle`**）。

---

# Spring

### 构造器注入 vs 字段注入

**问题**：`@Autowired` 字段注入和构造器注入，用哪个？

**答案**：**优先构造器注入**。三个理由：

1. **能声明 `final`**：依赖不可变，杜绝运行期被改。
2. **依赖缺失在启动时就报错**，而不是等到运行期抛 NPE。
3. **便于单元测试**：直接 `new` 出来传 mock，不依赖 Spring 容器（字段注入必须反射或起容器才能注入）。

```java
@Service
public class ArticleServiceImpl implements ArticleService {
    private final ArticleMapper articleMapper;
    private final UserMapper userMapper;
    public ArticleServiceImpl(ArticleMapper articleMapper, UserMapper userMapper) { ... }
}
```

（Spring 4.3 起，类只有一个构造器时 `@Autowired` 可以省略。）

**本项目实例**：`ArticleServiceImpl` 用的是构造器注入（**这是对的**），但 `ArticleController` / `UserController` 用的是 `@Autowired` 字段注入 —— **风格不统一，建议统一成构造器注入**。

**面试怎么答**：答三条理由，重点落在**"依赖缺失提前到启动期暴露"**和**"可测试性"**。追问方向：循环依赖怎么办（答：构造器注入下循环依赖会在启动时直接报错，这其实是好事 —— 强迫你解耦；字段注入能靠三级缓存绕过，但掩盖了设计问题）。

---

### @RestController vs @Controller

**问题**：写接口该用 `@RestController` 还是 `@Controller`？只写 `@RequestMapping` 行不行？

**答案**：写 REST 接口**必须用 `@RestController`**。三者关系是：

```java
@RestController  ==  @Controller + @ResponseBody
```

- `@Controller` 是**传统的 MVC 控制器**，返回值被当作**视图名**，交给视图解析器去找模板（JSP / Thymeleaf）。返回一个普通对象时，Spring 会把它当**模型属性**塞进 Model，然后仍然去找视图 —— 没有模板引擎就 404 或报 `Circular view path`。**返回不了 JSON。**
- `@RestController` 加了 `@ResponseBody` 语义：返回值经 `HttpMessageConverter` 直接序列化成 JSON 写进响应体。
- **只写 `@RequestMapping` 不加任何类级 stereotype 注解 → 这个类根本不是 Spring Bean。** `@RequestMapping`/`@GetMapping` 这些是**映射注解，不是 stereotype**，`@ComponentScan` 不会因为它们把类注册成 Bean。结果是整个 Controller 静默失效，所有路径 404。

**易错点**：`@Controller` 写错**编译完全通过**，只在真正调接口时才暴露。同理漏写注解也编译通过。

**本项目实例**：2026-09-15 写分类与评论模块时踩了两个：
- `CategoryController` 用了 `@Controller`（应为 `@RestController`）→ 4 个接口返回不了 JSON；
- `CommentController` **完全没写类级注解**，只有 `@RequestMapping` → 3 个接口直接 404。
对比 `ArticleController` / `UserController` 用的都是 `@RestController`，是当时的正确写法。

**面试怎么答**：答"`@RestController` = `@Controller` + `@ResponseBody`，前者返回视图名后者返回 JSON"。**更有价值的追问方向**：为什么漏写 stereotype 注解会静默失效（答：`@ComponentScan` 只认 `@Component` 及其派生注解，`@RequestMapping` 不在其中）。再补一句"这类错误编译期发现不了，必须靠真正调用接口来验证"。

---

# JWT 与鉴权

### 为什么需要双 Token

**问题**：JWT 是无状态的，签发之后服务端改不了它，那过期时间该设多长？

**答案**：单 token 无论设多长都是错的 —— 设长了，登出/改密后旧 token 在有效期内一直能用；设短了，用户每隔半小时被踢去登录一次。所以把两个矛盾的需求拆成两个 token：

| | access token | refresh token |
|---|---|---|
| 有效期 | 30 分钟 | 7 天 |
| 用在哪 | 每个业务请求的 `Authorization` 头 | 只用来调 `/auth/refresh` 换新 access |
| 存哪 | 前端内存 / localStorage | 前端 + 服务端 Redis |
| 泄露后果 | 最多被冒用 30 分钟 | 可以整条作废 |

两个 token **用同一个密钥签**，靠自定义 claim `type` 区分。**必须双向校验 type**：业务接口只收 `type=access`，刷新接口只收 `type=refresh`。漏了这一步，7 天的 refresh 就能直接当 access 用 —— 双 token 的设计收益直接归零。

**⚠️ 踩过的真坑：同一秒签发的两个 token 完全相同。** JWT 的 `iat`/`exp` 是**秒级精度**，payload 里又没有随机字段，所以同一用户在同一秒内签发的两个 token 字节级一模一样。表现为"登录后马上 refresh，新旧 refresh 相等"→ **refresh 轮转形同虚设，旧 token 没被换掉**。修法是签发时加唯一 id：`.setId(UUID.randomUUID().toString())`（即 JWT 标准里的 `jti`）。这个问题手工点接口很容易漏，因为人手点两次通常已经跨秒了；要写脚本在同一秒内连发两次才暴露。

**本项目实例**（Learning，2026-09-17）：
- `src/main/java/com/jiangpa/utils/JwtUtils.java`：`generateToken(userId, username, Duration ttl, String typ)` 统一签发，`setClaim("type", ...)` + `setId(UUID...)`；
- `src/main/java/com/jiangpa/interceptor/JwtInterceptor.java`：`isAccessToken()` 不通过就 401「token 类型错误」；
- `src/main/java/com/jiangpa/service/impl/TokenServiceImpl.java`：`refresh()` 里 `isRefreshToken()` 校验，轮转时复用 `issue()`。

**面试怎么答**：先给结论"用双 token 把'有效期短'和'可撤销'这两个矛盾需求拆开"，再主动讲 jti 那个坑 —— 它证明你真的测过而不是照抄教程。追问方向：为什么不用 Session（答：JWT 无状态、易水平扩展，代价就是撤销要额外机制）、refresh 泄露怎么办（答：存 Redis 绑定 userId + 轮转，异常即整条删除）、refresh 存 localStorage 还是 httpOnly Cookie（答：Cookie 防 XSS 但有 CSRF，要配 SameSite）。

---

### 登出怎么让 JWT 立即失效

**问题**：JWT 无状态、服务端不存它，"退出登录"凭什么让它立刻失效？

**答案**：JWT 本身撤销不了，必须在服务端补一点状态，两条路：

| | 黑名单（减法） | 白名单 / 单端登录（加法） |
|---|---|---|
| 存什么 | 已作废的 access | 有效的 refresh |
| key | `token:blacklist:{sha256(token)}` | `token:refresh:{userId}` |
| TTL | 该 token 的**剩余有效期** | refresh 的有效期（7 天） |
| 校验时机 | 每个请求查一次 | 只在 refresh 时查 |
| 语义 | 默认有效，逐个作废 | 默认无效，登录才生效 |

关键细节：
1. **存哈希不存原文**：key 用 `SHA-256(token)`，避免把可用凭证原文写进 Redis、监控和日志；
2. **TTL 取剩余有效期**而不是固定值：token 本来就只剩 3 分钟，黑名单存 30 分钟纯属浪费。`getRemainingMillis(token)` 算出来给 Redis；
3. 已经过期的 token 不用进黑名单（它本来就无效），所以解析要能容忍 `ExpiredJwtException`，否则"用过期 token 登出"会直接报错卡住前端；
4. refresh 以 `userId` 为 key **覆盖式写入** = 天然的单端登录（后登录的挤掉先登录的）；key 换成 `userId + deviceId` 就变成多端登录。

**本项目实例**：`TokenServiceImpl.logout()`（`stripBearer` → `parseQuietly` 容忍过期 → 删 refresh key → `remaining > 0` 才写黑名单）、`CacheKeys.tokenRefresh(userId)` / `tokenBlacklist(hash)`；拦截器每个请求查一次 `isRevoked()`。实测登出后同一个 access 再访问业务接口 → 401「登录已失效」。

**面试怎么答**：答"JWT 撤销要在服务端补状态：access 走黑名单、存哈希、TTL 取剩余有效期；refresh 用 userId 作 key 存 Redis，覆盖写入顺便实现单端登录"。追问方向：黑名单会不会无限增长（答：TTL 自动清理，量级只有"30 分钟内的登出次数"）、为什么不用布隆过滤器（答：需要删除，布隆不支持删除）、多端登录怎么改。

---

### 安全层 fail-closed 与性能层 fail-open

**问题**：Redis 挂了，接口应该降级放行还是直接报错？

**答案**：看这一层是**性能层**还是**安全层**，两者策略正好相反：

| | 性能层（缓存） | 安全层（鉴权 / 黑名单） |
|---|---|---|
| Redis 挂了 | **fail-open**：当未命中，直接查 DB | **fail-closed**：拒绝请求，报错 |
| 返回 | 正常 200（只是变慢） | 503 |
| 理由 | 缓存只是加速，挂了顶多慢一点 | "查不到黑名单" ≠ "没被拉黑"，放行 = 所有已登出的 token 集体复活 |

代码形态几乎一样（都是 `try/catch` 包住 Redis 调用），**差别只在 catch 里写什么**：缓存里是 `return null`（降级），鉴权里是 `throw new BusinessException(503, "鉴权服务暂不可用")`（fail-closed）。能主动说出"同一段 try/catch、两层相反策略"比背概念更能体现工程判断。

**状态码要分清 401 和 503**：
- **401 = 凭证本身无效**（过期、签名错、被拉黑）→ 前端应清 token、跳登录页；
- **503 = 鉴权服务不可用**（Redis 挂了）→ token 可能还是好的，前端**保留 token 稍后重试**。

把 503 当 401 处理，结果就是"Redis 抖一下，全站用户被踢下线"。

**本项目实例**：
- `ArticleServiceImpl` 的缓存包装方法全部 `catch (Exception)` → 降级查 DB（2026-09-16 实测：停掉 Redis，文章详情接口仍正常返回）；
- `TokenServiceImpl.isRevoked()` → `catch (Exception)` 后 `throw new BusinessException(503, ...)`，绝不 `return false`。

**面试怎么答**：结论先行 —— "降级策略取决于这层是性能还是安全：缓存 fail-open，鉴权 fail-closed"。追问方向：fail-closed 会不会让 Redis 变成拖垮登录的单点（答：会，所以要 Redis 高可用 + 短超时，但不能为了可用性牺牲鉴权）、还有哪些类似取舍（答：限流、风控、幂等去重）。

---

### JWT 登录与鉴权的完整链路

**问题**：一次"登录 → 带着 token 访问业务接口"在后端到底经过了哪些环节？每一环各自负责什么、失败时返什么码？

**答案**：拆成两段 —— **签发段**（登录，不需要 token）和 **验证段**（业务接口，每个请求都走一遍）。

**第一段：`POST /auth/login`**

```
@Valid 参数校验（Bean Validation，失败 → 400）
  → UserService.authenticate：查 tb_user + BCrypt.matches
       失败统一返 400「用户名或密码错误」（不区分用户不存在 / 密码错 → 防用户名枚举）
  → TokenService.issue：签 access(30m) + refresh(7d)
       Redis SET learning:token:refresh:{userId} = sha256(refresh)  TTL 7 天
  → { code:200, data:{ accessToken, refreshToken, expiresIn } }
```

关键点：**登录接口必须放行拦截器**（`/auth/**`），否则"拿 token 得先有 token"死锁。另外 `issue` 里用 `set` 而不是 `setIfAbsent` —— 覆盖是期望行为（新登录挤掉旧 refresh = 单端登录）。返回 `expiresIn` 是给前端**提前 60 秒主动刷新**用的，比"等 401 再重试"体验好。

**第二段：`GET /article/1` + `Authorization: Bearer <access>`，拦截器 `preHandle` 五步**

| 步 | 做什么 | 不过时 |
|---|---|---|
| 1 | 取 `Authorization` 头，null/空判 | 401「未登录，请先登录」 |
| 2 | 剥 `Bearer `（先判长度再 `substring` 防越界；`equalsIgnoreCase`） | 401「token 格式错误」 |
| 3 | `parseToken`：验签 + 验期 + 验 `iss` | 401「token 无效 / 已过期」 |
| 4 | **`type` 必须是 `access`** | 401「token 类型错误」 |
| 5 | **查黑名单**（Redis `hasKey`） | 命中 → 401；Redis 异常 → **503** |
| 6 | 挂 `userId` / `username` 到 request attribute，`return true` | — |

第 4 步漏了，7 天的 refresh 就能当 access 用，双 token 白做；第 5 步的 503 是 fail-closed（见上一条）。

**第 6 步之后身份怎么用**：Controller 用 `@RequestAttribute("userId") Long userId` 取，**DTO 里根本没有 userId 字段**。作者 id 只从 JWT 拿，允许前端传 = 任何人改个数字就能以别人名义发文（最典型的越权漏洞）。`getUserId` 从 `sub` 取而不是 `id` claim，因为 JSON 数字可能被反序列化成 `Integer`。

**⚠️ 一个容易忽略的执行细节：拦截器里抛的异常谁能接住？**

`preHandle` 里 `throw new BusinessException(503, ...)` 一路穿透到 `@RestControllerAdvice`，靠的是两件事同时成立：

1. **`BusinessException extends RuntimeException`，不是 `JwtException` 的子类** —— 所以不会被 `catch (JwtException e)` 那个兜底分支吃掉（拦截器里三个 catch 都不会误伤它）；
2. **`preHandle` 是在 `DispatcherServlet.doDispatch` 的 try 块内被调用的** —— 所以异常能走到 `HandlerExceptionResolver` 链。如果它是在 `doDispatch` 之外调的（比如 Filter 层），`@RestControllerAdvice` 就接不住了，得自己往 response 里写。

**本项目实例**（Learning，2026-09-17 双 Token 改造后）：
- `config/WebMvcConfig.java`：`addPathPatterns("/**")` + `excludePathPatterns("/auth/**", "/error")`（`/error` 不放行会让真实错误被 401 盖住）；
- `controller/AuthController.java`：`login` 只做"`userService.authenticate` 认证 → `tokenService.issue` 签发"，**认证与签发分开是为了避免 `UserService` ↔ `TokenService` 循环依赖**；
- `service/impl/UserServiceImpl.java`：`authenticate()` 里两处 `throw new BusinessException(400, "用户名或密码错误")` 文案完全相同；
- `utils/JwtUtils.java`：私有 `generateToken(userId, username, ttl, type)` 统一签发（`type` claim + `jti`）；
- `interceptor/JwtInterceptor.java`：五步校验 + `writeUnauthorized()`（自己往 response 写 401 JSON，因为 `preHandle` 返 false 不会自动生成响应体）；
- `service/impl/TokenServiceImpl.java`：`issue` / `refresh` / `logout` / `isRevoked`；
- 全链路业务码在 `code` 里，HTTP 状态码恒 200。

**面试怎么答**：按"签发段 → 验证段"两段讲，验证段用五步串起来，重点砸在三个地方：① 放行 `/auth/**` 的原因；② `type` 校验漏了会怎样（refresh 变万能通行证）；③ 黑名单失败为什么返 503 不返 401。追问方向：拦截器返 false 为什么还要自己写响应（答：Spring 不会帮你生成响应体，不写前端收到内容为空的 200）、`@RequestAttribute` 和从 body 拿 userId 的区别（答：越权）、拦截器和 Filter 的区别（答：Filter 更早、拿不到 handler，但能覆盖静态资源；拦截器能拿到 `HandlerMethod`）、异常在拦截器里抛为什么也能被全局异常处理器接住（答：`preHandle` 在 `doDispatch` 的 try 块内 + 异常不是 `JwtException` 子类）。

---

### refresh token 什么时候轮换

**问题**：refresh 轮换到底由什么触发？访问业务接口时会轮换吗？登录会吗？另外——为什么每次刷新后登录状态又能续 7 天？

**答案**：**唯一触发点 = `POST /auth/refresh` 校验通过的那一次**。轮换不是定时任务，也不由业务请求触发；它由"用户来换新 access"这个动作驱动。

```
POST /auth/refresh { refreshToken: R1 }
  ├─ parseToken(R1)：验签 + 验期，失败 → 401
  ├─ isRefreshToken(claims)：失败 → 401「token 类型错误」
  ├─ Redis GET token:refresh:{userId}，与 sha256(R1) 比对，不匹配 → 401
  └─ 通过 → issue(userId, username)
        ├─ 签 A2（新 access）、R2（新 refresh）
        ├─ Redis SET token:refresh:{userId} = sha256(R2)，TTL 重新计满 7 天  ← ★ 覆盖即轮换
        └─ 返回 { A2, R2, expiresIn }（R1 当场作废，即使用它自身还没过期）
```

**哪些地方不轮换**（契约边界，别想当然）：

| 动作 | 结果 |
|---|---|
| 访问业务接口（带 A1） | 完全不碰 refresh；A1 也不变，30 分钟内一直可用 |
| `POST /auth/logout` | 只 `DEL token:refresh:{userId}` + A1 进黑名单，**不签发任何新 token**（登出后没有"下一个 refresh"） |
| 再次登录 | 也是覆盖 `token:refresh:{userId}`，但语义是**新建会话**，不是轮换 |
| access token | **从不轮换**。它无状态、改不了，只能等自然过期或登出时进黑名单 |

**★ 最容易被忽略的一点：轮换顺带把 TTL 重置成满 7 天 → 滑动窗口续期。**

`issue()` 里 `SET` 的 TTL 是 `refreshExpiration`（7 天这个**常量**），不是 `getRemainingMillis(R1)`（剩余时间）。所以**每一次 refresh 都把过期时间推到"此刻 + 7 天"** —— 过期时间点随刷新动作不断右移，这就是**滑动窗口续期（sliding expiration）**，而不是"从登录起 7 天到点就走"的固定窗口。

**但要分清哪一半是后端保证的、哪一半不是**：

| | 谁决定 | 说明 |
|---|---|---|
| **每次 refresh 都把 TTL 重置为满** | ✅ **后端保证**（代码事实） | `issue()` 传常量 TTL，写死的行为 |
| **"每 30 分钟刷新一次"** | ❌ **前端策略**，后端管不着 | 后端只被调用，决定不了被调用的频率 |

**这个项目没有前端代码**（Learning 仓库是纯后端，`md/JWT双Token实现设计文档.md` 第七节的"提前 60 秒刷新"是**给前端的建议**，不是已实现的事实）。所以准确的说法是：

> 后端保证的是"**每次 refresh 都重置 TTL**"；**滑动窗口有多长，由前端的刷新频率决定**。
> - 前端若按设计文档做"提前刷新"（access 30 分钟，每次请求前发现临近过期就刷）→ 活跃用户的间隔约 30 分钟 → 每次把 TTL 推到 7 天后 → **只要连续两次访问的间隔 < 7 天，就永远不会掉线**。
> - 前端若只做"等 401 再被动刷新"→ 刷新频率取决于用户访问量 → 冷用户仍会在登录 7 天后被踢。

**所以"活跃用户永不下线"是前端频率的函数，不是后端的固有属性。** 后端真正固定下来的是一个**语义选择**：`SET` 传的是 `refreshExpiration` 常量而不是剩余时间 —— 这**明确选了 sliding window 而不是 absolute expiry**。想改成"登录后 7 天铁定过期"，把 TTL 换成 `jwtUtils.getRemainingMillis(claims)`（R1 的剩余有效期）就行 —— 但那样 `refresh` 就没有"续命"作用了，refresh token 会准时失效。

这个语义选择带来的代价：真正需要强制重新认证的场景（改密码、怀疑盗号）**必须显式删掉 `token:refresh:{userId}`**，光等 TTL 等不到。这一点面试官很爱追问。

✅ **"TTL 被重置"已于 2026-09-18 实测证实**：登录后 TTL=604800 → 闲置 4 秒降到 604796 → `POST /auth/refresh` 之后**跳回 604800**。既证明 TTL 确实在倒计时（否则测不出"跳回"），也证明写的不是剩余时间。**滑动窗口从代码推导升级为实测事实。**

**为什么失败不轮换**：校验失败（过期、类型错、Redis 里哈希对不上）时**不签发任何东西、也不改动 Redis**。所以"随便拿个垃圾 token 打 refresh"既拿不到新凭证，也不会把受害者当前的 refresh 顶掉 —— 这正是不把"不匹配"升级成"吊销该用户全部会话"的原因（见下一条的边界讨论）。

**按项目实际行为实测修正（2026-09-18）**：
- Redis 侧：完全成立 —— 三种失败输入打 `/auth/refresh` 之后，`learning:token:refresh:{userId}` 的 TTL 一秒没变，**确认失败不轮换**；
- **但 HTTP 层文案错了**：过期 token / 篡改签名的 token / 垃圾字符串，返回的都是 `code=500「服务器开小差了」`，**不是文档设计的 401**。原因是 `TokenServiceImpl.refresh` 里的 `parseToken` 没有 catch `JwtException`，异常一路掉到兜底处理器。**这是真缺陷，记入「JWT 异常要在哪几处 catch」—— 已修复（2026-09-18 晚）并复测通过。**

**并发刷新会怎样**：两个请求同时拿 R1 去刷新。**后写的覆盖先写的**，Redis 里最终只剩一个 R2（假设是 R2b）。但**两个响应都返回 200**，各自带着不同的 token 对；如果前端采用了"输掉"的那个 R2a，下一次刷新就会 401。所以前端**必须做刷新去重**（第一个 401 触发刷新，其余请求挂起等结果复用同一对新 token），否则页面上几个并发请求会互相作废。

**本项目实例**（Learning，2026-09-17）：
- `service/impl/TokenServiceImpl.java`：`refresh()` 第 60-65 行读 Redis 比对哈希，第 65 行 `return issue(userId, ...)` —— **轮换是复用 `issue()` 顺带完成的**，没有单独的轮换代码路径。这也是"签发逻辑只有一份"的直接收益：轮换不需要额外实现。
- `issue()` 第 39-40 行用 `set`（不是 `setIfAbsent`）。**如果用 `setIfAbsent`，轮换根本不会发生**（key 已存在则写入失败，R1 永远有效）—— 这是设计文档踩坑清单第 7 条。
- 实测判据（2026-09-17 已验证）：`refresh(R1)` 成功 → 再用 `R1` → 401（R1 已轮转）；`R2` → 200。
- **"TTL 被重置"已实测（2026-09-18）**：用原生 TCP 直连 Redis 发 `TTL learning:token:refresh:{userId}`，得到 604800 → 604796（闲置 4 秒）→ refresh 后 **604800**。附带验证：`GET` 出来的值 == `sha256(新 refreshToken)`（64 位十六进制），旧 refresh 复用 → 401。**这是把"滑动窗口"从代码推导变成实测证据的实验，3 分钟可复现。**
- 附带机制：`JwtUtils.generateToken` 里的 `.setId(UUID.randomUUID())`（jti）是轮换能生效的前提 —— 否则同一秒签发的 R1 和 R2 字节级相同，哈希一样，覆盖后旧 token 照样能用，轮换静默失效。

**面试怎么答**：一句定调 —— "轮换由 `refresh` 成功那一刻触发，作用是**一次性凭证用完即废**，把泄露窗口从 7 天压到下一次续期之前"。然后主动补两个加分点：① **`SET` 时传的是常量 TTL 而不是剩余时间，所以这是个滑动窗口续期** —— 刷新频率越高、登录状态续得越久（说清"频率由前端决定，后端只保证每次刷新重置 TTL"，别说成"每 30 分钟自动续一次"，后端没有那个定时器）；② **并发刷新必须前端去重**，否则多次轮转互相作废、用户莫名掉线。追问方向：刷新失败的三种原因怎么区分（答：正常轮转 / 新设备登录 / 凭证被盗，服务端**无法区分**后两者，所以不能因不匹配就吊销全部会话）、真正的重放检测怎么做（答：记录"已用过的 token 哈希"，收到历史值才判定泄露 —— 但要和并发刷新的宽限期共存，本项目的取舍就是不引入它，用前端去重兜住并发）、session 绝对过期怎么实现（答：TTL 换成该 refresh 的剩余有效期，或另存一个"登录时间"key 做绝对上限）。

---

### JWT 异常要在哪几处 catch

**问题**：`ExpiredJwtException` / `MalformedJwtException` / `SignatureException` 这些 JWT 异常，应该在哪些地方捕获？漏了会怎样？

**答案**：**每一个「调用 `parseToken` 的入口」都必须单独处理，一处都不能少。** JWT 异常是**运行时异常**，没人接就会一路掉到 `@RestControllerAdvice` 的 `catch (Exception)` 兜底分支 → **前端收到 `code=500「服务器开小差了」`**，而不是"你的凭证无效"。

本项目有 **3 个** 调用 `parseToken` 的入口，当前覆盖情况（2026-09-18 实测）：

| # | 入口 | 改法 | 覆盖情况 |
| --- | --- | --- | --- |
| 1 | `JwtInterceptor.preHandle`（业务接口） | catch `ExpiredJwtException` / `SignatureException` / `MalformedJwtException` / `JwtException` 四档 → 401 | ✅ 已 catch。实测过期 access token → **401** |
| 2 | `TokenServiceImpl.refresh` | 只判 `isRefreshToken` + Redis 哈希比对 | ⚠️ **曾经漏 catch**：实测"垃圾串 / 篡改签名 / 已过期"三种 refresh token **全部 → 500**。**已修复**（补三档 catch）并复测：四类畸形输入全部 → **401** ✅ |
| 3 | `TokenServiceImpl.logout` | `parseQuietly` 里 catch `ExpiredJwtException` 取 `e.getClaims()`，其余 catch 后 `return null` | ✅ 已 catch。实测过期 access token 登出 → **200 且 refresh key 被删** |

**为什么 3 个入口要各写一遍、不能用同一个 catch 兜住**：它们对"失败"的**语义**完全不同 —— 拦截器失败 = 拒绝请求（401），refresh 失败 = 凭证无效（401，让前端跳登录页），logout 失败 = **必须继续成功**（用户的意图是登出，不是证明 token 有效）。同一个异常，三种处理方式，所以只能是三处独立 catch。

**这个缺陷的实际危害**（为什么它不只是"文案难看"）：
1. **打断前端的自动续期链路**。前端逻辑是"401 → 用 refreshToken 换新的 → 换不到才跳登录页"。refresh 返回 500 既不是 401 也不是 200，前端只能显示"服务异常"，用户被卡在中间态；
2. **最讽刺的一点**：access token 过期（30 分钟，**必然发生**）触发的 refresh 请求，正好是 refresh 最需要 401 的场景 —— 却返回 500。**这不是边缘 case，是每天每个活跃用户都会走到的正常路径**；
3. 和缓存降级那套设计对照：`TokenService.refresh` 已经是"失败就拒绝"（安全），但**返回错误的失败信号**，调用方会做出错误动作 —— 与 `isRevoked` 那条"必须返 503 不能返 401"是同一个道理。

**修法**：在 `TokenServiceImpl.refresh` 里给 `parseToken` 加 catch，和拦截器保持一致的 401 语义（`ExpiredJwtException` 与"无效"可以给不同文案，但必须是 401）。**已按此修复。**

**本项目实例**：`interceptor/JwtInterceptor.java`（catch 四档，写法可照搬）、`service/impl/TokenServiceImpl.java` 的 `refresh()`（**曾漏 catch，已按同样三档补上** —— 2026-09-18 复测：垃圾串 / 篡改签名 / 不可解析 payload / 真·已过期，四类全部 → 401）与 `parseQuietly()`（logout 的正确写法）。

**修复后的验收判据（实测过）**：

| 输入 `/auth/refresh` | 修复前 | 修复后 |
| --- | --- | --- |
| 合法 refresh token | 200 | **200** ✅ |
| 垃圾字符串 | 500 | **401** ✅ |
| 签名被篡改 | 500 | **401** ✅ |
| payload 不可解析 | 500 | **401** ✅ |
| **真·已过期**（用项目密钥自签） | 500 | **401**「登录已过期，请重新登陆」✅ |
| access token（类型不对） | 401 | **401** ✅ 未回归 |

> **怎么造"已过期 but 签名合法"的 token（可复现的测法）**：从用户作用域取 `JWT_SECRET` → 手工拼 header/payload → HMAC-SHA256 签名 → `exp` 设成 60 秒前。这一步能把"过期分支"和"签名错误分支"彻底分开测，比只发垃圾串有价值得多。


**面试怎么答**：答"JWT 异常是运行时异常，**每个 `parseToken` 调用点都要独立 catch**，因为失败语义不同：拦截器拒绝请求、refresh 让前端跳登录、logout 必须放行到成功"。然后主动讲这个坑：**access 过期是必然事件，它触发的 refresh 如果返回 500 而不是 401，前端的自动续期链路会直接断掉** —— "我一开始把拦截器写对了，但漏了 service 里那一处，**测试时才暴露：过期 refresh token 返回 500**"。追问方向：为什么不用 `@ExceptionHandler(ExpiredJwtException.class)` 全局兜住（答：可以兜住类型，但兜不住"logout 要装作没发生"这种**行为差异**）、JWT 异常要不要给用户看细节（答：不要，统一"凭证无效/已过期"，避免泄露签名算法与内部结构）。

---

### 认证 ≠ 授权：水平越权和纵向越权

**问题**：接口已经有 JWT 拦截器了，为什么还会"任何登录用户都能删掉别人的账号"？

**答案**：因为 JWT 拦截器只解决了**认证**（Authentication，你是谁），没解决**授权**（Authorization，你能动谁）。**验签通过只证明"这是个合法用户"，不代表他有权操作这个资源。**

授权分两类，**必须用两套不同机制**：

| 越权类型 | 例子 | 资源特征 | 判定机制 | 失败返回 |
| --- | --- | --- | --- | --- |
| **水平越权** | A 删 B 的账号/文章/评论 | **有主**（属于某个用户） | **归属校验**：比对资源所有者与当前用户 | 403 |
| **纵向越权** | 普通用户删分类、拉全站用户列表、把自己提成管理员 | **无主**（全站资产） | **角色校验**：比对角色 | 403 |

**关键点：归属校验解决不了纵向越权** —— 分类、用户列表这种"全站资产"**没有所有者**，你没法比对。反过来，角色校验也解决不了水平越权 —— 两个都是普通用户（`role` 相同），角色判断必然通过。**两者是正交的，缺一不可。**

**实测过的完整漏洞链（Learning，2026-09-18）**：

```
任意登录用户 -> DELETE /user/{id}      -> 200，删掉任何人（水平越权，缺归属校验）
任意登录用户 -> GET    /user/list      -> 200，拉走全站用户（纵向越权，缺角色校验）
任意登录用户 -> DELETE /category/{id}  -> 200，删掉全站分类（纵向越权，缺角色校验）
```

**危害**：用户 id 是自增的，**从 1 遍历即可删光整张表**；被删用户逻辑删除后接口返回 404、登录返回 400，**受害者察觉不到是"账号被删了"**。

**本项目实例**：`interceptor/JwtInterceptor.java`（认证）+ `annotation/RequireRole.java` + `interceptor/AuthorizationInterceptor.java`（纵向授权）+ `UserServiceImpl.selectUser/delete` 的归属判断（水平授权）。角色用 `role` 字段（0=用户 1=管理员）并**写进 JWT claim**，拦截器直接读，不查库。

**面试怎么答**：先给结论 —— "认证解决'你是谁'，授权解决'你能干什么'，**JWT 只做了前者**"。然后按水平/纵向展开，重点强调**两者机制不同、不能互相替代**（这是最容易答错的点）。主动补一句"我把 role 放进 JWT claim 而不是每请求查库，代价是角色变更最长 30 分钟才生效（access 有效期），用短有效期兜住"。追问方向：为什么归属校验防不住管理员删别人（答：管理员本来就该有权限，所以是**或**关系：「自己 **或** 管理员」）、全站资产的接口怎么办（答：只能靠角色，所以必须引入 role）、为什么不用 Spring Security（答：本项目只手写轻量方案，能讲清原理；生产用 Spring Security 的 `@PreAuthorize`）。

---

### 删除/修改类接口的权限判断写反了会怎样

**问题**：权限判断就是一行 `if`，为什么写成 `!A || !B` 会导致"自己的资料自己看不了"，而测试还发现不了？

**答案**：因为权限判断是**布尔逻辑**，而 `!A || !B` 和 `!A && !B` **只差一个符号**，却表达了**互补**的两种语义 —— 更麻烦的是**写反之后"禁止"的分支往往还是对的**，所以测试很容易通过。

**规则（照着念就不会错）**：

> 我要的是 **`A` 或 `B`**（自己 **或** 管理员）→ 拒绝条件就是 **`!A && !B`**（既不是自己 **也不是** 管理员）
> 我要的是 **`A` 且 `B`** → 拒绝条件才是 `!A || !B`

**实测踩到的写法（Learning，2026-09-18）**：

```java
// ❌ 写成 || ：等价于 !(A && B)，要求"必须同时是自己且是管理员"
if (!Objects.equals(id, userId) || !Objects.equals(role, 1)) {
    throw new BusinessException(403, "无权操作他人账号");
}

// ✅ 正确：自己 或 管理员
if (!Objects.equals(id, userId) && !Objects.equals(role, 1)) {
    throw new BusinessException(403, "无权操作他人账号");
}
```

**为什么测试能漏掉**：写错后两个账号的**部分用例恰好是正确的** ——

| 用例 | 期望 | 错误代码的实际结果 | 看起来 |
| --- | --- | --- | --- |
| 普通用户查**别人** | 403 | 403 | ✅ 像是对的 |
| 普通用户删**别人** | 403 | 403 | ✅ 像是对的 |
| 普通用户查**自己** | 200 | **403** | ❌ 被漏测 |
| **管理员**查别人 | 200 | **403** | ❌ 被漏测 |
| 普通用户删**自己** | 200 | **403** | ❌ 被漏测 |

**结论：权限测试必须"对称地测两个方向"** —— 既测"该拒绝的拒绝了"，也测"**该放行的放行了**"。只测前一半，一个 `||`/`&&` 写反就能骗过整套测试。

**另外一个易混点**：`@RequireRole` 注解和 Service 里的归属校验**不要叠加**。
`DELETE /user/{id}` 的设计是「自己 **或** 管理员」，所以**不能**在 Controller 上加 `@RequireRole(1)`（那会先按角色拦掉普通用户，Service 里的"删自己"分支永远走不到）。**一个接口的权限规则只在一个地方表达**，否则两处语义冲突时，行为由"谁先执行"决定 —— 极难排查。

**本项目实例**：`service/impl/UserServiceImpl.java` 的 `selectUser` / `delete`（`&&` 写法 + 404 优先于 403 的顺序）、`controller/UserController.java`（`DELETE` 上**不加** `@RequireRole`，权限交给 Service）。

**面试怎么答**：答"权限判断是布尔逻辑，`!A || !B` 和 `!A && !B` 语义互补，**写反了编译和大部分测试都能过**"。然后讲测试方法：**"权限用例必须成对写 —— 该拒的拒、该放的放，特别是'操作自己的资源'和'管理员操作他人资源'这两条，它们正是写反时唯一会失败的用例"**。追问方向：404 和 403 哪个先判（答：先判存在性返 404，再判归属返 403；反了会用 403 掩盖"资源不存在"）、为什么权限规则只在一个地方表达（答：两处叠加时行为取决于执行顺序，无法推理）。

---

### @Valid 漏写 = 所有校验注解静默失效

**问题**：DTO 上 `@NotNull`、`@Min`、`@Max` 都写齐了，为什么越界值还是能写进数据库？

**答案**：因为**约束注解不会自己执行**。它们只是"元数据"，必须由 **`@Valid`（或 `@Validated`）触发 Bean Validation** 才会被检查。`@RequestBody` 参数上漏写 `@Valid`，**所有约束集体失效**，接口照常返回 200。

```java
// ❌ 注解全白写：请求体不经过校验
public Result<?> updateRole(@RequestBody UserRoleUpdateDTO dto) { ... }

// ✅ 加上 @Valid 才生效
public Result<?> updateRole(@Valid @RequestBody UserRoleUpdateDTO dto) { ... }
```

**⚠️ 这个坑比"注解写错类型"更隐蔽，因为它的表现完全不同**：

| 情况 | 表现 | 特征 |
| --- | --- | --- |
| **漏写 `@Valid`** | 越界值**静默通过**，返回 200 | **不报错、日志干净** —— 你以为校验在保护，其实完全没有 |
| **注解用错类型**（如 `@Size` 标在 `Integer` 上） | 校验器抛 `UnexpectedTypeException` → 掉到兜底 → **500** | **连 `@NotNull` 也一起崩** —— 表现为"该返 400 的返了 500" |

**实测（Learning，2026-09-18，`PUT /user/role`）**：

```
漏写 @Valid：
  {id:18, role:9}   -> 200，DB 真的写成 role=9
  {id:18, role:-1}  -> 200，DB 写成 -1
  {id:18}           -> 200，DB 写成 NULL（绕过了建表的 NOT NULL DEFAULT 0）

补上 @Valid：
  {id:18, role:9}   -> 400「权限值只能是 0(降级) 或 1(升级)」，DB 不变 ✅
  {id:18}           -> 400「权限设定不能为空！」✅
```

**为什么这个漏洞特别危险（和权限结合时）**：这里的 `role` 决定权限，而权限判断是 `role.intValue() != 1`。所以**能写任意 role 值 = 能造出"非 1 但依然有管理权限"的账号**，同时 DB 里的值还看不出异常。**校验失效 + 字段决定权限 = 权限模型被绕过。**

**怎么快速发现**：写完 DTO 校验后，**主动发一个明确越界的值**（超范围、缺必填、类型不对），看是否被拒。
- 返回 200 → **`@Valid` 没生效**
- 返回 500 → **某个注解用错了类型**
- 返回 400 + 正确文案 → 才是真的在工作

**顺带记一个"看似等价的替代"**：类上加 `@Validated` 只对**方法级/参数级校验**（如 `@PathVariable` 上的 `@Min`）有意义；**`@RequestBody` 的嵌套对象校验仍然需要 `@Valid`**。两者不能互相替代。

**本项目实例**：`controller/UserController.java` —— 同一份文件里 `update`（有 `@Valid`）和 `updateRole`（曾漏写）是正反两个样本；`dto/UserRoleUpdateDTO.java`（`@NotNull` + `@Min(0)` + `@Max(1)`）。

**面试怎么答**：答"`@Valid` 是触发校验的开关，约束注解只是元数据 —— **漏写 `@Valid` 会让整组约束静默失效**，接口不报错、日志也干净，比注解写错类型更难发现（后者至少会 500）"。然后把它和权限场景串起来：**"如果被校验的字段恰好决定权限，校验失效就等于权限模型被绕过"**。追问方向：`@Valid` 和 `@Validated` 的区别（答：`@Validated` 是 Spring 的，支持**分组校验**和类级方法校验；`@Valid` 是标准 Bean Validation，支持嵌套对象级联 `@Valid`）、嵌套对象为什么有时不校验（答：内层字段需要在内层字段上加 `@Valid` 才能级联）、分组校验怎么用（答：`@Validated(Create.class)` + 注解上的 `groups`，用于"新增要校验 id 为空、修改要校验 id 非空"这类场景）。

---

### Redis 六处依赖的降级方向与超时代价

**问题**：项目里同一个 Redis 被用在缓存、限流、令牌黑名单、refresh key 上。"Redis 挂了怎么办"是**一个**问题还是**六个**问题？把它们都设计成 fail-closed 就安全了吗？

**答案**：是**六个**问题。同一个 Redis 有**两种方向、三种操作语义**。而且真正的杀手不是方向选错，而是**超时**。

**本项目实测数据**（把 `spring.redis.port` 改成 9999 制造不可达，逐一打接口）：

| # | Redis 操作 | 层次 | 方向 | 实测结果 | 耗时 |
| --- | --- | --- | --- | --- | --- |
| 1 | 缓存（detail/views/lock） | 性能 | **fail-open** | 回源查 DB，接口正常 | — |
| 2 | 限流（滑动窗口） | 性能 | **fail-open** | 连打 7 次全 200（无 429、无 500） | — |
| 3 | 黑名单**读**（`isRevoked`） | 安全 | **fail-closed** | 503「认证服务暂时不可用」 | 2052ms |
| 4 | 黑名单**写**（logout） | 安全 | **fail-closed** | 503 | 4038ms |
| 5 | refresh key **写**（issue/登录） | 认证 | **fail-closed** | 503「服务暂时不可用」 | 5060ms |
| 6 | refresh key **读**（refresh） | 认证 | **fail-closed** | 503 | 4037ms |
| 7 | refresh key **删**（logout） | 认证 | **fail-open** | 记日志，登出照常返回 | — |

**⭐ 判别规律（比"性能层/安全层"更细一层）**：

```
安全 / 认证相关的"读"和"写"  → fail-closed（读不到、写不进都不该声称成功）
安全 / 认证相关的"删"        → 可以 fail-open（删不掉不产生错误的成功语义）
纯性能层（缓存 / 限流）      → 一律 fail-open
```

**最能说明问题的是第 4 条 vs 第 7 条**：同一个 `logout` 方法里，**删 refresh key 失败可以放行，写黑名单失败必须拒绝** ——
- 删失败：access token 已经进黑名单了，双重保险还剩一层，登出目的基本达到；
- 写失败：**等于 access token 没被作废**。此时若返 200，用户以为"退了"，实际那个 token 在剩余 30 分钟里**仍然完全有效** —— 安全控制静默失效。

**⭐⭐ 真正值钱的一条：超时时间决定故障时的"伤害半径"。**

实测每次失败的 Redis 往返 ≈ **2 秒**（配的 `spring.redis.timeout: 3000ms`）：

```
不碰 Redis 的路径（无 token 直接 401）     25 ms   ← 快速拒绝
读一次 Redis 失败                        2052 ms
删 + 写各失败一次（logout）               4038 ms
限流 + 写 refresh 各失败一次（login）      5060 ms
```

**一次请求里可能撞多次超时**（登录要过限流 + 写 refresh → 5 秒）。

> **所以 fail-closed 的代价不只是"拒绝请求"，而是"每个请求都等满超时"。** 生产上 `spring.redis.timeout` 必须设短（几百毫秒级），否则 Redis 抖动期间所有接口被拖慢 2~5 秒 → Tomcat 线程被占住 → 连接池耗尽 → **从"部分功能不可用"升级为"整站雪崩"**。
>
> 一句话：**降级策略决定可用性，超时时间决定故障时的伤害半径。**

**本项目实例**：`ArticleServiceImpl`（9 个 `cacheXxx` 封装，全 fail-open）、`RateLimitInterceptor`（`catch (Exception)` → `return true`）、`TokenServiceImpl`（`issue`/`refresh` 抛 503；`logout` 的删 key fail-open、写黑名单 fail-closed）。

**面试怎么答**：先说"'Redis 挂了怎么办'不是一个问题" —— **同一个中间件在不同用途上方向可以完全相反**，再给判别规律：性能层一律放行；安全/认证层的读和写要拒绝，但**删除类操作可以放行**（对比 `logout` 里"删 refresh key"与"写黑名单"两种处理）。最后补超时这条：**"fail-closed 必须配短超时，否则 Redis 抖动会把整个服务拖死 —— 降级策略决定可用性，超时决定伤害半径。"** 追问方向：超时设多少（答：看 P99，一般几百毫秒，要比接口总超时小得多）、要不要加重试（答：谨慎，重试会放大超时，只有幂等操作才适合重试）、Redis 高可用怎么做（答：哨兵/集群 + 客户端拓扑发现）。

---

*（新知识点挂到上方对应主题的末尾）*