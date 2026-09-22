# Java 后端学习记录


## 学习路线

- **第一阶段（7-8月）**：Java 基础 · Spring Boot · MySQL · LeetCode 入门（目标 50 题）
- **第二阶段（9-10月）**：MySQL 深入 · Redis · JVM · 计算机网络 · 操作系统（目标 100 题）
- **第三阶段（11月）**：项目实战 · 微服务入门 · 简历打磨
- **第四阶段（12-1月）**：八股文复习 · 面试冲刺

## 技术栈

Java · Spring Boot · MyBatis-Plus · MySQL · Redis · RabbitMQ · Docker · Git

## 每日记录

| 日期 | 内容 | LeetCode |
|------|------|----------|
| 7.23 | Two Sum（暴力 + HashMap）、Git 入门 | #1 |
| 7.24 | 多态、HashMap 源码、三数之和、异常处理 | #15 |
| 7.25 | ArrayList vs LinkedList 源码、泛型、反射、环形链表 | #141, #142 |
| 7.26 | File 类（路径、CRUD、递归遍历）、反转链表、合并有序链表 | #206, #21 |
| 7.27 | Stream 流（filter/map/collect/分组）、合并有序数组、相交链表 | #88, #160 |
| 7.28 | IO字节流：FileInputStream/FileOutputStream、BufferedStream性能对比 |  |
| 7.31 | IO字符流：FileReader/FileWriter、BufferedReader/BufferedWriter、回文链表、删除倒数第N个结点 | #234, #19 |
| 8.3 | IO实战：随机点名系统（生成名单 + 概率抽取 + 不重复 + 多轮循环） | - |
| 8.6 | 多线程基础：三种创建方式（Thread/Runnable/Callable）、start vs run、生命周期 | #5, #20 |
| 8.7 | 多线程：线程安全、synchronized（三种用法、锁升级）、最大子数组和、买卖股票 | #53, #121 |
| 8.15 | 多线程：volatile、CAS、ABA、线程池7参数与拒绝策略、只出现一次的数字 | #136 |
| 8.16 | JVM：运行时数据区五部分、堆栈区别、可达性分析、垃圾回收算法、分代回收、二叉树最大深度/翻转 | #104, #226 |
| 8.17 | JVM：垃圾收集器(Serial/Parallel/CMS/G1)、类加载双亲委派、合并二叉树/对称二叉树 | #617, #101 |
| 8.18 | MySQL：SQL基础(DDL/DML/DQL)、JOIN、GROUP BY、索引入门、有序数组转二叉搜索树/平衡二叉树 | #108, #110 |
| 8.19 | MySQL：B+树原理、聚簇/非聚簇索引、回表、覆盖索引、最左前缀、二叉搜索树搜索 | #700, #653 |
| 8.20 | MySQL：EXPLAIN执行计划、SQL优化、事务ACID、四种隔离级别、二叉搜索树插入/验证 | #701, #98 |
| 8.21 | MySQL：MVCC(隐藏列/undo log/ReadView)、快照读vs当前读、行锁/间隙锁/临键锁、死锁 | #230, #530 |
| 8.22 | MySQL：主从复制binlog/relay log、读写分离、分库分表、二叉搜索树最近公共祖先/中序遍历 | #235, #94 |
| 8.23 | MySQL：InnoDB架构(Buffer Pool/Change Buffer)、redo log/undo log/Double Write、WAL、层序遍历 | #102, #107 |
| 8.24 | MySQL：redo log深入、binlog区别、两阶段提交、崩溃恢复、二叉树右视图/层平均值 | #199, #637 |
| 8.25 | MySQL：索引失效8大场景、EXPLAIN实战验证、慢查询日志、相同的树/另一棵树的子树 | #100, #572 |
| 8.26 | MySQL：三大范式、电商库表设计、HikariCP/Druid连接池、慢查询定位流程、二叉树直径/路径总和 | #543, #112 |
| 8.31 | Redis：入门、为什么快、五种数据结构及场景、用栈实现队列/用队列实现栈 | #232, #225 |
| 9.1 | Redis：缓存穿透/击穿/雪崩、RDB/AOF/混合持久化、有效的括号/最小栈 | #20, #155 |
| 9.2 | Redis：分布式锁(SETNX/Lua/Redisson)、过期删除、内存淘汰策略、逆波兰表达式 | #150, #239 |
| 9.3 | Redis：主从/哨兵/集群、哈希槽、缓存一致性(Cache Aside/延迟双删)、字符串解码/每日温度 | #394, #739 |
| 9.4 | Redis：底层数据结构(SDS/quicklist/跳表)、单线程模型、IO多路复用epoll、第K大元素/前K高频 | #215, #347 |
| 9.5 | Redis：六大场景实战、高频面试题自测、LRU缓存/LFU缓存 | #146, #460 |
| 9.6 | Redis总复习 + Spring Boot环境搭建、HelloWorld | #206, #21 |
| 9.8 | Spring Boot：IOC/DI、Bean与容器、@Component/@Service/@Autowired、三层结构 | #206, #21 |
| 9.9 | Spring Boot：AOP(切面/切点/通知/动态代理)、自动配置原理、最长公共前缀/两数组交集 | #14, #349 |
| 9.10 | Spring Boot：Spring MVC请求流程、RESTful注解、MyBatis-Plus集成CRUD、删除重复项/移除元素 | #26, #27 |
| 9.11 | Spring Boot：统一响应Result、@Valid参数校验、@RestControllerAdvice全局异常、移动零/合并有序数组 | \#283, #88 |
| 9.12 | Spring Boot：JWT登录认证、拦截器vs过滤器、HandlerInterceptor权限校验、有序数组平方/两数之和II | \#977, #167 |
| 9.13 | 项目实战：博客系统建表、用户模块(注册/登录/BCrypt加密/JWT)、反转字符串 | \#344, #557 |
| 9.14 | 项目实战：文章模块CRUD、分页查询、作者权限校验、反转字符串中的单词/验证回文串 | \#151, #125 |
| 9.15 | 项目实战：分类模块(4接口)+评论模块(3接口)、代码审查修复3个bug、建立Java后端知识库.md | \#704, #34 |
| 9.16 | 项目实战：文章详情Redis缓存(Cache Aside/浏览量Redis计数/空值防穿透)、Controller改构造器注入、清理冗余索引；计网TCP三次握手四次挥手；前端JS入门 | \#35, #875 |
| 9.17 | 项目实战：JWT双Token(access30m+refresh7d、type校验、登出黑名单、refresh轮转)、修复同秒签发token相同的jti缺陷、安全层fail-closed vs 性能层fail-open；知识库补3条JWT条目；力扣长度最小的子数组 | \#209 |
| 9.18 | 项目实战：逻辑删除(@TableLogic+唯一索引冲突取舍)、角色权限(@RequireRole+授权拦截器+水平/纵向越权)、refresh异常处理(500→401)、接口限流(滑动窗口+Lua+拦截器顺序)、六处Redis依赖降级实测；代码审查修复8个缺陷；4份设计文档回填实现记录；知识库补6条 | - |
| 9.19 | 计算机网络：HTTP报文/方法语义(安全与幂等)/状态码(401vs403vs429vs503)/HTTP缓存(强缓存vs协商缓存)/Cookie-Session与JWT对比、HTTPS握手与证书链(混合加密原理)；项目实战：用户列表分页、请求体解析异常(500→400)、文章分类关联校验、**改密码接口(改完删refreshKey强制下线)**、**分页组件化(PageQueryDTO+越界返400)**、补3类参数异常处理器(否则返500)；**单元测试入门**(JUnit5+Mockito，51个用例覆盖降级方向与已修缺陷)；用户模块接口文档按实现重写；全局异常处理器补注释；知识库补4条；**晚间：文档一致性收尾**(四表 DDL 按 `SHOW CREATE TABLE` 与库逐字对齐、逻辑删除验收项改正、列表页浏览量滞后落文档)、**新增 Learning/README.md**、**接入 Knife4j 在线接口文档**(22 接口可在线调试，踩通三个坑)、**6 个类补 `@ToString.Exclude`** 防日志泄露、端口 8080→8081 全文档同步、知识库补 1 条(refreshToken 被盗的危害与防护) | \#56 |
| 9.20 | Docker 部署：补 spring-boot-maven-plugin(瘦jar→可执行fat jar)、.dockerignore 挡住 application-local.yml 不进镜像、多阶段构建 + docker-compose 起 MySQL/Redis/应用、配置全走环境变量；网络收口「从输入 URL 到页面展示」 | #438 |
| 9.21 | 操作系统：进程vs线程(资源分配vs调度单位、PCB、私有栈与共享堆)、进程五状态与合法/非法转换(含挂起态)、上下文切换代价(寄存器/PCB/页表→TLB失效、Linux PCID)、线程实现三模型(用户级/内核级/混合、Java线程=内核级1:1、JDK21虚拟线程)、进程间通信IPC核心对比表；力扣扁平化二叉树为链表 | #114 |

## 项目

- 博客系统 Learning（进行中）：**22 个接口**，含 JWT 双 Token 鉴权、Redis 缓存、逻辑删除、角色权限、接口限流、51 个单元测试、**Knife4j 在线接口文档（`/doc.html`）**、**Docker 化部署（多阶段构建 + `docker compose` 一键起全栈）**
- 海南麻将
