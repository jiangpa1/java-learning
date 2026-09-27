# HANDOFF — Java 后端实习辅导 · 任务交接

> 最后更新：**2026-09-27**
> 这份文件管的是**辅导任务本身**（用户状态、协作方式、两个仓库怎么分工、下一步）。
> **项目本身的技术细节请看另一个仓库的 `LearningHANDOFF.md`**（见下方"两个仓库别搞混"）。
>
> ⚠️ **本文件 2026-09-19 全面重写过**。上一版写于 09-15，里面「项目在 `Desktop\java` 下」「category/comment 未做」「Redis 未接入」「逻辑删除未做」等**全部已过时**，不要沿用旧印象。
> ⚠️ **2026-09-27 再修**：补上 09-20～09-24 之间发生的事（Learning 的 Docker/CI、操作系统学习、**海麻 v2 架构重写**）。第五节的规模数字与它自己的交接文档状态已更正 —— 09-27 那版曾把 09-20 已修正的旧数字（54/8445）又写回去，是错的。

---

## 一、用户与目标

| 项 | 内容 |
| --- | --- |
| 身份 | 计算机科学与技术，2026 年秋季升大三，**全程中文交流** |
| 目标 | **2026-12 投递简历**，2027 寒假拿到 Java 后端实习 Offer |
| 方向 | Java 后端（Spring Boot 生态） |
| 当前日期 | 2026-09-27（**09-28～10-07 用户在外旅游，不学习**；10-08 复课 → 12 月投递，实际约 **7.5 周**） |

---

## 二、学习进度

### 已完成

| 主题 | 内容 |
| --- | --- |
| Java 基础 | 集合、泛型、反射、注解、异常、IO 流、Stream |
| 多线程 | 创建方式、`synchronized`、`Lock`、线程池、`volatile`、CAS（**都在 8 月的 `.docx` 里，只有"知道"的程度，没有知识库条目**） |
| JVM | 内存结构、GC、类加载 |
| MySQL | 索引、事务、MVCC、锁、主从复制、分库分表、EXPLAIN 调优 |
| Redis | 五数据结构、缓存三问题、持久化、分布式锁、淘汰策略、高可用 |
| Spring Boot | IOC/DI、AOP、自动配置、Spring MVC、统一响应、参数校验、全局异常、**JWT 双 Token** |
| 计算机网络 | TCP 三次握手四次挥手、TIME_WAIT、**HTTP 基础/状态码/缓存/Cookie-Session**、**HTTPS 握手与证书链**（2026-09-16～19 补齐）、**「从输入 URL 到页面展示」收口**（09-20） |
| **操作系统** | 进程 vs 线程 + 上下文切换 + 线程三模型（09-21，day45）、虚拟内存 / 地址翻译 / 缺页 / 页面置换 / 伙伴系统（09-22，day46）、**五种 IO 模型 / select-poll-epoll / LT-ET**（09-23，day47 ~ 笔记**还没提交**） |
| 项目实战 | **Learning 博客系统**：22 个接口 + 51 个单元测试 + **Docker/compose + GitHub Actions 推镜像**（见第四节） |
| LeetCode | 约 **50+ 题**（每天 1-2 题，跟当天主题搭配） |

### 还没系统学的（面试前必须补）

1. **Java 并发进阶** —— 8 月的多线程只到"知道"：**AQS / ReentrantLock / Condition / ThreadLocal / JMM 与 happens-before / ConcurrentHashMap / CountDownLatch 这一档全空**，而且知识库里一条都没有。这是**现在最大的知识缺口**
2. **操作系统收尾**：`epoll` 的 LT/ET 细节、**线程同步与死锁**（互斥锁/信号量/经典同步问题/死锁四条件与处理）—— 进程、内存、IO 三块主干已过
3. **八股文系统刷题**（11 月起用 JavaGuide）
4. **简历**（11 月起）

---

## 三、两个仓库别搞混 ⭐

这是接手时最容易错的一点：

| 仓库 | 本地目录 | 装什么 |
| --- | --- | --- |
| **`jiangpa1/Learning`** | `C:\Users\ASUS\Desktop\**Learning**` | **博客项目本体**：`src/main/java` 代码、`md/` 下的设计文档与接口文档、根目录 `LearningHANDOFF.md` 与 **`README.md`**（README 面向访客/面试官，2026-09-19 新增） |
| **`jiangpa1/java-learning`** | `C:\Users\ASUS\Desktop\**java**` | **笔记与练习**：`day1…dayN/` 每日练习、`Java后端知识库.md`、`README.md`（每日记录表）、本文件 |

**⚠️ 病根**：`Desktop\java` 是**每日练习归档目录，真实项目不在这里**。上一版交接文档就是把这俩搞混了，才写出"项目在 `Desktop\java` 下"。

两者都 push 到 GitHub，**都是 public** —— 提交前必须扫一遍有没有口令/密钥。

---

## 四、项目一：Learning 博客系统（主力，只给结论，细节看 `LearningHANDOFF.md`）

**位置**：`C:\Users\ASUS\Desktop\Learning`（**不在 `Desktop\java` 里**）

**一句话**：22 个接口的博客后端，除 CRUD 外还有四层横切能力 + 51 个单元测试。

| 能力 | 状态 |
| --- | --- |
| 用户 / 认证 | ✅ 注册、登录（**双 Token**）、续期轮转、登出、改昵称、**改密码**、改角色、逻辑删除 |
| 文章 / 分类 / 评论 | ✅ 全部接口，含归属校验 403、N+1 优化、缓存 |
| **逻辑删除** | ✅ 四表 `@TableLogic` |
| **角色权限** | ✅ `@RequireRole` + 授权拦截器（水平/纵向越权分开处理） |
| **接口限流** | ✅ 滑动窗口 + Lua，拦截器顺序 JWT→授权→限流 |
| **降级策略** | ✅ 六处 Redis 依赖、两种方向，**全部实测** |
| **单元测试** | ✅ 51 个（JUnit 5 + Mockito），IDEA 里跑全绿 |
| **Docker 化部署** | ✅ **2026-09-20 完成**：多阶段 Dockerfile（非 root）+ `docker compose` 起 MySQL/Redis/app，`.dockerignore` 挡住 `application-local.yml`（`c9c8267`） |
| **CI 推镜像** | ✅ **2026-09-20 完成**：GitHub Actions 构建并推送到 `ghcr.io`（`bf35739`） |
| 接口文档 | ✅ `Learning/md/` 下 12 份，与代码一致 |

**待办**（详见 `LearningHANDOFF.md` 第八节；**2026-09-27 复核**）：
1. ~~文档一致性收尾~~、~~Docker 部署~~、~~CI~~ —— **均已完成**（`a788e52` / `c9c8267` / `bf35739`）
2. 继续铺单测（优先 `UserServiceImpl` 的权限判断 —— `!A || !B` 写反时大部分用例还是绿的，最该有测试；其次 `ArticleServiceImpl` 的缓存降级）
3. 低优先：统一提示语（**昵称兜底文案 4 处不一致**）、`JwtProperties` 改用 `@EnableConfigurationProperties`；**可选**：补 Maven Wrapper（`mvnw`，现在 `.mvn` 是空目录，克隆下来只能靠 IDEA 构建）

> ⚠️ **工作区有 3 个未提交的 Java 文件**（2026-09-27 发现）：`AuthorizationInterceptor`（删两行空行）、
> `TokenServiceImpl`（`isRevoked` 去掉 `Boolean.TRUE.equals(...)` 包装）、`UserServiceImpl`（`login` 改用 `toUserVO`）。
> 后两处**是风格统一，不是 bug**（`hasKey` 返回基本类型 `boolean`，不会 NPE）；但**没跑过测试**，别直接当"已完成"。
> **处理方式**：跑一遍 51 个单测 → 通过就按一处提交（`refactor: 统一 VO 转换与 hasKey 判空写法`）→ 再收工。

**已知取舍（不是缺陷，别再当 bug 修）**：列表页浏览量滞后、逻辑删除后名字不可复用、评论不级联、限流阈值是演示值、管理员可自降（有守卫）。

---

## 五、项目二：海南麻将联机版（已上线，**当前最强**）

| 项 | 内容 |
| --- | --- |
| 位置 | `F:\HainanMaJhong2` |
| 仓库 | `https://github.com/jiangpa1/HainanMaJhong`（public，分支 `main`） |
| **线上** | **`http://jiangpahnmj.cn`** —— 2026-09-20 复核：`/`、`/index.html`、`/lobby.html`、`/game.html`、`/api/room/pending` 全部 200，`nginx/1.18.0 (Ubuntu)`。⚠️ **只有 HTTP，没有 HTTPS**（`https://` 超时）；⚠️ 域名解析出 **19 个阿里云 IP**（跨北京/上海/深圳/杭州），需自己确认是 CDN 还是轮询配置 |
| 技术栈 | Spring Boot 2.7.18 + **原生 WebSocket**（`/room`、`/game` 双端点）+ MySQL + Redis；前端 **Vue 3 + Vite 单页应用**（09-24 重写前是原生 HTML/JS） |
| 规模 | **`HainanMaJhong` 模块（他写的代码）：38 个 Java 文件 / 6679 行** + 76 个前端文件（2026-09-20 实测）。⚠️ 之前写的"54 / 8445"是**把 `mjlib_java` 参考库也算进去的全树合计** —— **简历上只能用 38 / 6679**。⚠️ 但 09-24 那次架构重写（见下）后行数又变了，**引用前重新 `cloc` 一遍** |
| 它自己的交接 | `F:\HainanMaJhong2\HANDOFF.md`（**2026-09-24 已重写，190 行，是当前唯一权威版**）。恢复该任务时先读它 —— 它比本节新，**本节只保留"跨项目视角"的结论** |

> ⚠️ **2026-09-24 有一次架构重写（本节成文于 09-20，之后发生的）**：
> 提交 `2a75c4d`（274 文件，+29033/−7432），分支 `release/v2-arch` 已快进到 `main`。
> **后端**改为 18 个包的分层架构（`config/interceptor/service/engine/room/rules/websocket`…）+ 全局拦截器 + JWT 身份校验；
> **前端从原生 HTML/JS 改成 Vue 3 + Vite 单页应用**（含手机虚拟横屏）。所以下面"四条调用链"的类名仍有效，
> 但**"下一步要学 Vue3"这件事已经作废** —— 前端已经是 Vue3 了。

**为什么它值钱**：它具备简历上最稀缺的三个要素 —— **真实上线 + 自有域名 + 多人实时联机**（Learning 是本地/Docker 跑的 CRUD 项目）。⚠️ **但正因为它"最强"、而他现在还讲不清代码，它也是当前最大的面试风险** —— 见下面「代码来源实情」。**在吃透之前，它不能当主打项目讲。**

**读那份 190 行的文档时，注意两件事**：

1. **它是 2026-09-24 重写的**，比本节（09-20 复核）新 —— **以它为准**，本节只做补充。
2. **线上现在是坏的，不是"旧版本"这么简单**：`jiangpahnmj.cn` 跑的还是重写前的旧代码，
   而且**服务器连错了数据库**（应用在往 `192.168.133.128:3306` 这个本机开发 VM 地址发 SYN，
   公网服务器永远连不上）→ 登录报「服务器内部错误」/ 502。
   修法见那份文档 §6.1：给 systemd unit 加 `Environment=SPRING_PROFILES_ACTIVE=prod`，
   并在 `/opt/mahjong/.env` 写 `DB_HOST=127.0.0.1` 等。**新 jar 已打好但还没部署。**

| 它（09-09 旧版）里写的 | 实际（2026-09-20 实测） |
| --- | --- |
| 当前分支 `v4-update`（已 push origin） | **`main`** —— 远端**只有 `main`，`v4-update` 已不存在**（09-17 为凭据清理改的名） |
| "大量未提交改动在工作区"、"`application.yml` 未提交且含密码默认值" | **工作区干净（0 个未提交）**；`application.yml` 已**凭据环境变量化并提交** |
| "命令行无 mvn"，要手拼 classpath 编译 | **mvn 现在可用**：`C:\Users\ASUS\tools\apache-maven-3.9.16\bin\mvn.cmd`（配好 `JAVA_HOME` 即可），打包直接用 `mvn clean package` |
| 验证命令用 `?v=20260907g` | 线上实际是 **`?v=20260908d`** |
| 完全没提凭据事故 | 09-17 已完成：轮换 MySQL/Redis 密码、`filter-repo` 清洗全部历史、删 `target/`、停跟踪 19 个文件、分支改名、全新克隆验证（仓库 48MB → 10.4MB） |

### ⚠️ 写简历前必须知道的两件事

**① 代码来源实情（决定简历措辞，别写过头）**

- **胡牌判定是查表法，参考了 GitHub 上的 `mjlib_java`**（该仓库自述"table 查表法 / 查表法由网友 ak 翻译过来"）。
- 用户**自己做的扩展**是：把判定从固定 14 张，支持到 **2/5/8/11/14 张暗牌**（因为吃、碰、杠之后暗牌张数会变）—— **这部分是他的**。
- **其余绝大部分由 AI 生成，他没有仔细读过代码。**
- **所以现在不能写"独立完成""自研胡牌算法"。** 诚实且不亏的写法是：
  > "参考开源查表实现，**扩展支持 2/5/8/11/14 张暗牌**" —— 突出自己做的扩展，不宣称从零实现。
- **要吃透之后才能用完整措辞**（见下面的吃透路径）。

**② 凭据事故已处理完毕，不要重复排查**

起因：仓库是 public，而数据库密码曾进过 git 历史。2026-09-17 已处理完：

1. 在云服务器**轮换了 MySQL / Redis 密码**并验证能正常打牌 ← **这才是真正的修复**（已泄露的密码清历史救不回来）
2. `git filter-repo --replace-text` 清洗全部历史：密码主体、密码后缀、服务器 IP **全部 0 处**
3. `git filter-repo --path-glob "*/target/*" --invert-paths` 删掉编译产物（jar 里烤进了配置）→ 仓库 48MB → **10.4MB**
4. 停止跟踪 19 个不该入库的文件（`.idea`×11、Eclipse 配置×5、`.class`×3）
5. 分支 `v4-update` 改名 `main`，删掉垃圾分支 `master`
6. **全新克隆验证**：敏感串 0 处、垃圾文件 0 个、项目文件完整

> **遗留提醒**：Learning 的库密码沿用的是**和海南麻将同一套构造模式**（就是已被泄露的那套），**必须轮换**；并且**两个项目不要用同一个密码**。
>
> ⚠️ 此处原本写明了该模式的字面内容，**已于 2026-09-19 删去** —— 但**它在 git 历史里仍然存在**（提交 `7fd0e2f` 起）。**真正的修复是改密码，不是删文档** —— 已经公开过的东西清历史救不回来。

### 吃透路径（**按调用链读，不要按文件读**）

用户计划**先做完 Learning、再学 Vue3（约 5-7 天）之后**才来吃透海麻 —— **不急**，别主动催。轮到时按这四条链路：

1. **一次出牌的全链路**：前端 → WebSocket → `RoomManager` → 广播 → 渲染
2. **断线重连**：座位保留 / bot 托管 / `pushSeatState` 补发 —— ⚠️ 注意**暗牌不能补发给别人**
3. **Redis 快照恢复**：`room:{code}`
4. **规则引擎与结算**：`HainanScore`

**判断标准**：能合上代码**画出带方法名的时序图**。

### 架构局限（被问时要能答）

**房间状态存在内存里**（`MultiPlayerRoomService`）→ **只能单机部署**。
被问"怎么支持更多人在线"，答案是：**状态外置到 Redis + 网关按房间码做粘性路由**（同一个房间的请求必须落到同一台机器）。

### 可复用的踩坑（当时处理凭据时踩的）

- `git filter-repo --replace-text` 的规则文件**带 UTF-8 BOM 会静默失效**（hash 不变就是没生效）→ 用 `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))` 写无 BOM
- `pip install` 被注册表里的系统代理 `127.0.0.1:7897` 卡住 → 设 `NO_PROXY=*` 绕过
- `git rm -r --cached <目录>` 对被 `.gitignore` 忽略的目录会报 `pathspec did not match` → 先用 `git ls-files` 取出显式列表再 `git rm --cached`
- `--path X --invert-paths` 没匹配上，要用 `--path-glob "*/target/*" --invert-paths`

---

## 六、协作偏好（重要）

**排查问题后，先给「哪里错了 + 为什么错」的清单，让他自己改**；他明确说"你帮我改"或连续卡住时才代改。

- **原因**：他在学 Java 找实习，**动手调试和踩坑本身就是学习**；直接交付成品会把最有价值的环节拿走，面试时也讲不出来。
- 代改时保留他原有风格：构造器注入、`Result` 包装、`LambdaQueryWrapper`、中文注释。
- 给清单时**顺手写全验收判据** —— 他改完的标准动作是「**你验证一下**」（高频指令）。
- 优先问设计取舍（如「删除分类时关联文章怎么办」），而不是直接给答案。
- 日常交流用中文，回答要**具体、可操作**。

**其他习惯**：
- 喜欢把设计写成 markdown，认可「**先写设计 → 实现 → 把实测结果和踩坑回填到实现记录**」这个流程。
- 他把**每天的学习主题也写成笔记**（`dayNN/主题.md`），知识库条目应基于笔记提炼 + 挂项目实例，不要照抄。
- 收尾时更新 `README.md` 每日记录表，然后**两个仓库分别 commit + push**。

---

## 七、每日节奏

他习惯早上问「**今天学什么**」。给计划时：

1. **按剩余时间排** —— 常在上午已过或下午才问，别硬凑上午。
2. **说清今天的主线**（学新知识 / 项目实战 / 收尾），不要为凑时间塞满。
3. 框架是「上午学新 → 算法 1h → 下午项目 → 晚上补漏」，**但实际执行常超时**（9-18、9-19 都做到 19:00 以后）。
4. 计划末尾给 **README 记录行 + 两个仓库的 commit message**。

---

## 八、下一步建议（**2026-09-27 重排：用户 09-28～10-07 在外旅游**）

> 上一次排是 09-20。这之后已完成：Learning 的 **Docker + GitHub Actions**（`c9c8267`、`bf35739`）、
> 「从输入 URL 到页面展示」收口、**操作系统大半（进程/线程、内存管理、IO 模型）**。
> 剩下的时间：**10-08 复课 → 12 月投递，实际只有约 7.5 周**。所以下面按"能不能赶上 12 月"倒排。

**出行前（09-27 晚～09-28）**：
1. **把 Learning 那 3 个未提交的 Java 文件处理掉**（`AuthorizationInterceptor`、`TokenServiceImpl`、`UserServiceImpl`，见第九节末尾）—— 别留在工作区
2. **海麻线上修复 + 部署新版本**（见第五节）—— 线上现在是坏的，**要么修好要么把域名摘掉**，别挂个打不开的链接
3. 顺手把 `Desktop\java` 里的 4 个探针输出 + `HumanDiscardPromptTest.java` 归档或删除

**回来之后（10-08 起）**：
4. 项目侧：Learning **补单元测试**（优先 `UserServiceImpl` 权限判断）→ 补 Maven Wrapper → 低优先项
5. 项目侧：**海麻吃透**（按第五节四条调用链）+ 部署 / 收尾 §6.2 的 6 条
6. 知识侧：**补 Java 并发**（AQS / ReentrantLock / ThreadLocal / JMM / ConcurrentHashMap —— 8 月的 `.docx` 只到"知道"，没有知识库条目）
7. 11 月：简历 + JavaGuide 八股文；12 月：投递 + 面试

---

## 九、环境与工具（踩过的坑，省时间）

| 项 | 情况 |
| --- | --- |
| MySQL / Redis | 虚拟机 `192.168.133.128`，库名 `learning`；**虚拟机经常关机，动手前先确认连得上** |
| 凭据 | 在 `Learning/src/main/resources/application-local.yml`（已 gitignore，**不要写进记忆或文档**） |
| 应用 | **默认不启动**，要验证时在 IDEA 里跑（端口 **8081**，2026-09-19 从 8080 改的） |
| Maven | **项目没有 `mvnw`，`mvn` 也不在 PATH** —— 命令行编译/跑测试要自己拼 classpath |
| 回归脚本 | `Desktop\java\day42-*.ps1` / `day43-*.ps1`；**口令已改为读环境变量 `LEARNING_DB_PASS`**，另需用户作用域的 `JWT_SECRET` |
| **手工 classpath 的陷阱** | **不能"递归收集 `.m2` 全部 jar"** —— 本地仓库里有多个版本（MyBatis-Plus 3.4.3/3.5.5、Tomcat 9.0.46/9.0.83、commons-pool2 只有 2.8.1 与 lettuce 6.1.10 不兼容），会覆盖成旧版本导致**误报编译失败**。用"同 artifact 取最高版本"可规避大部分 |
| PowerShell 5.1 | **写验证脚本用纯 ASCII 输出**（含中文的 `.ps1` 被按 GBK 读会解析失败）；URL 里的 `&` 在单引号字符串里也被拦（用 `[char]38` 拼）；`$P`/`$host` 是保留变量别当计数器；写文件用 `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))`（`Set-Content -Encoding UTF8` 会带 BOM） |
| git commit | **用 `git commit -F 文件`**，不要 `-m $var` —— 消息里的 `` ` ``/`+`/`"` 会被 git 当成 pathspec，**提交静默失败** |

---

## 十、记忆文件位置（继续维护即可）

`C:\Users\ASUS\.claude\projects\C--Users-ASUS-Desktop-java\memory\`

| 文件 | 内容 | 上次更新 |
| --- | --- | --- |
| `MEMORY.md` | 索引 | 2026-09-19 |
| `user-profile.md` | 用户画像 + 节奏 + 仓库 | 2026-09-19 |
| `feedback-editing-style.md` | 协作偏好 + **验证方法 7 条** | 2026-09-19 |
| `feedback-knowledge-base.md` | 知识库维护约定（**条目追加在末尾 + 同步目录**） | 2026-09-19 |
| `project-learning-blog.md` | Learning 项目状态速查（细节指向 `LearningHANDOFF.md`） | 2026-09-19 |
| `project-hainan-mahjong.md` | 海南麻将第二项目（已上线）+ 凭据事故处理 + 吃透路径 | 2026-09-19 |

---

## 十一、接手动作清单

1. 读本文件 + `Learning/LearningHANDOFF.md` + `memory/` 下 5 个记忆文件
2. `git -C Desktop\Learning status` 和 `git -C Desktop\java status` 确认工作区状态（**2026-09-19 收工时两个都 clean 且与远端同步**）
3. 确认虚拟机 MySQL/Redis 连得上（`Test-NetConnection 192.168.133.128 -Port 3306`）
4. **两个项目的关系**：Learning = 主力（在做，收尾中）；海南麻将 = 第二项目（**已上线，待吃透，用户自己排的顺序是先 Learning 后海麻**）
5. 问他"今天学什么"时，**按剩余时间给计划 + 明确主线**，末尾附 README 行与 commit message
