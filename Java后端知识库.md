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

**Spring**
- [@RestController vs @Controller](#restcontroller-vs-controller)
- [构造器注入 vs 字段注入](#构造器注入-vs-字段注入)

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

**面试怎么答**：先答"能消除 filesort"，再答**为什么**——等值列在前、排序列在后，B+ 树局部有序所以省掉排序。追问方向通常是「范围查询为什么不能放排序前面」（因为范围列之后的列在 B+ 树里不再全局有序）。**配合 EXPLAIN 前后对比讲，说服力最强。**

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

*（新知识点挂到上方对应主题的末尾）*
