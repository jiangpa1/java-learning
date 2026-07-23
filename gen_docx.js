const docx = require('docx');
const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, ShadingType, WidthType,
  PageBreak, TableOfContents, PageNumber, Footer, Header,
  LevelFormat, ExternalHyperlink, TabStopPosition, TabStopType,
  convertInchesToTwip, UnderlineType, PageOrientation
} = docx;

const pageMargins = { top: 1134, bottom: 1134, left: 1134, right: 1134 };

function heading(text, level = HeadingLevel.HEADING_1) {
  return new Paragraph({ heading: level, children: [new TextRun({ text, bold: true })] });
}

function subheading(text) {
  return heading(text, HeadingLevel.HEADING_2);
}

function subsubheading(text) {
  return heading(text, HeadingLevel.HEADING_3);
}

function para(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120, line: 360 },
    ...opts,
    children: [new TextRun({ text, size: 22, font: 'Microsoft YaHei', ...opts.runOpts })]
  });
}

function bullet(text, level = 0) {
  return new Paragraph({
    spacing: { after: 80, line: 340 },
    bullet: { level },
    children: [new TextRun({ text, size: 22, font: 'Microsoft YaHei' })]
  });
}

function emptyLine() {
  return new Paragraph({ spacing: { after: 60 }, children: [] });
}

function cell(text, opts = {}) {
  return new TableCell({
    width: { size: opts.width || 2000, type: WidthType.DXA },
    shading: opts.shading ? { fill: opts.shading, type: 'CLEAR' } : undefined,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 60, after: 60 },
      children: [new TextRun({ text, size: 20, font: 'Microsoft YaHei', bold: opts.bold || false, color: opts.color || '333333' })]
    })]
  });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function coverPage() {
  return [
    emptyLine(), emptyLine(), emptyLine(), emptyLine(), emptyLine(), emptyLine(),
    new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new TextRun({ text: 'Java后端开发实习生', size: 52, bold: true, font: 'Microsoft YaHei', color: '2B579A' })]
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new TextRun({ text: '每日学习计划', size: 60, bold: true, font: 'Microsoft YaHei', color: '2B579A' })]
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 200 },
      border: { top: { style: BorderStyle.SINGLE, size: 2, color: '2B579A', space: 12 }, bottom: { style: BorderStyle.SINGLE, size: 2, color: '2B579A', space: 12 } },
      children: [new TextRun({ text: '2026年7月 — 2027年1月 · 寒假实习冲刺', size: 28, font: 'Microsoft YaHei', color: '555555' })]
    }),
    emptyLine(), emptyLine(),
    new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 100 },
      children: [new TextRun({ text: '目标：在寒假前掌握 Java 后端开发核心技能，拿到实习 Offer', size: 24, font: 'Microsoft YaHei', color: '666666', italics: true })]
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER, spacing: { after: 100 },
      children: [new TextRun({ text: '每日投入时间：4-6 小时（学期中）/ 8-10 小时（假期）', size: 24, font: 'Microsoft YaHei', color: '666666', italics: true })]
    }),
    emptyLine(), emptyLine(), emptyLine(), emptyLine(), emptyLine(), emptyLine(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: '制定日期：2026年7月23日', size: 22, font: 'Microsoft YaHei', color: '999999' })]
    })
  ];
}

function roadmapTable() {
  const headers = ['阶段', '时间', '核心内容', '每日时长', '目标产出'];
  const data = [
    ['第一阶段\n基础夯实', '7.23 - 8.31\n(约6周)', 'Java 核心 · Spring Boot 入门\nMySQL 基础 · LeetCode 入门', '6-8h/天\n(暑假)', '1个 CRUD 项目\nLeetCode 50题'],
    ['第二阶段\n进阶深入', '9.1 - 10.31\n(约9周)', 'MySQL 深入 · Redis · JVM\n计算机网络 · 操作系统', '4-5h/天\n(学期中)', 'LeetCode 100题\n技术博客笔记'],
    ['第三阶段\n项目实战', '11.1 - 11.30\n(约4周)', '完整项目开发 · 微服务入门\n消息队列 · Docker 部署', '5-6h/天\n(学期中)', '2个完整项目\n成品简历'],
    ['第四阶段\n面试冲刺', '12.1 - 1.31\n(约8周)', '八股文系统复习\n算法强化 · 模拟面试', '6-8h/天\n(寒假)', '面试 Offer'],
  ];
  const colWidths = [1800, 1800, 3200, 1800, 2800];
  return new Table({
    width: { size: 11400, type: WidthType.DXA },
    columnWidths: colWidths,
    rows: [
      new TableRow({
        children: headers.map((h, i) => new TableCell({
          width: { size: colWidths[i], type: WidthType.DXA },
          shading: { fill: '2B579A', type: 'CLEAR' },
          children: [new Paragraph({
            alignment: AlignmentType.CENTER, spacing: { before: 80, after: 80 },
            children: [new TextRun({ text: h, size: 22, bold: true, font: 'Microsoft YaHei', color: 'FFFFFF' })]
          })]
        }))
      }),
      ...data.map((row, ri) => new TableRow({
        children: row.map((t, ci) => new TableCell({
          width: { size: colWidths[ci], type: WidthType.DXA },
          shading: ri % 2 === 0 ? { fill: 'F0F4FA', type: 'CLEAR' } : undefined,
          children: [new Paragraph({
            alignment: AlignmentType.CENTER, spacing: { before: 80, after: 80 },
            children: [new TextRun({ text: t, size: 20, font: 'Microsoft YaHei', color: '333333' })]
          })]
        }))
      }))
    ]
  });
}

function dailySchedule() {
  const headers = ['时间段', '学习内容', '说明'];
  const data = [
    ['08:30 - 09:00', '晨读 / 复习', '回顾昨天笔记，背 Java 面试题'],
    ['09:00 - 11:00', '核心学习（上午）', 'Java / Spring Boot / 框架新技术学习'],
    ['11:00 - 11:30', '休息放松', ''],
    ['11:30 - 12:30', '算法练习', 'LeetCode 1-2 题，坚持每日刷题'],
    ['14:00 - 16:00', '核心学习（下午）', '数据库 / Redis / 计算机基础理论学习'],
    ['16:00 - 16:30', '休息放松', ''],
    ['16:30 - 18:00', '项目实战', '动手做项目，写代码，不要只看不写'],
    ['20:00 - 21:30', '复习 + 整理笔记', '今日所学回顾，写技术博客/笔记'],
    ['21:30 - 22:00', '规划次日', '规划明天的具体学习任务'],
  ];
  const colWidths = [2200, 3200, 6000];
  return new Table({
    width: { size: 11400, type: WidthType.DXA },
    columnWidths: colWidths,
    rows: [
      new TableRow({
        children: headers.map((h, i) => new TableCell({
          width: { size: colWidths[i], type: WidthType.DXA },
          shading: { fill: '2B579A', type: 'CLEAR' },
          children: [new Paragraph({
            alignment: AlignmentType.CENTER, spacing: { before: 60, after: 60 },
            children: [new TextRun({ text: h, size: 22, bold: true, font: 'Microsoft YaHei', color: 'FFFFFF' })]
          })]
        }))
      }),
      ...data.map((row, ri) => new TableRow({
        children: row.map((t, ci) => new TableCell({
          width: { size: colWidths[ci], type: WidthType.DXA },
          shading: ri % 2 === 0 ? { fill: 'F0F4FA', type: 'CLEAR' } : undefined,
          children: [new Paragraph({
            alignment: ci < 2 ? AlignmentType.CENTER : AlignmentType.LEFT,
            spacing: { before: 60, after: 60 },
            children: [new TextRun({ text: t, size: 20, font: 'Microsoft YaHei', color: '333333' })]
          })]
        }))
      }))
    ]
  });
}

function weekPlan(weekNum, dates, theme, tasks) {
  return [
    subsubheading('第 ' + weekNum + ' 周（' + dates + '）—— ' + theme),
    ...tasks.map(function(t) { return bullet(t); }),
    emptyLine()
  ];
}

const doc = new Document({
  styles: {
    default: {
      document: {
        run: { size: 22, font: 'Microsoft YaHei' }
      }
    }
  },
  sections: [
    // Cover + TOC
    {
      properties: { page: { margin: pageMargins } },
      children: [
        ...coverPage(),
        pageBreak(),
        heading('目录'),
        new TableOfContents(),
        pageBreak(),
      ]
    },
    // Main content
    {
      properties: { page: { margin: pageMargins } },
      children: [
        heading('一、总体学习路线'),
        emptyLine(),
        para('以下表格展示了从 2026 年 7 月到 2027 年 1 月的四阶段学习路线。每个阶段有明确的核心内容、时间投入和产出目标。'),
        emptyLine(),
        roadmapTable(),
        emptyLine(),
        bullet('暑假（7-8月）每天 6-8 小时高强度学习，快速夯实基础'),
        bullet('学期中（9-11月）每天 4-6 小时，以项目驱动为主'),
        bullet('寒假前（12-1月）全力冲刺面试，查漏补缺'),
        emptyLine(),

        heading('二、每日作息建议'),
        emptyLine(),
        para('以下为暑假期间（7-8月）的推荐每日安排，学期中可根据课程灵活调整：'),
        emptyLine(),
        dailySchedule(),
        emptyLine(),
        bullet('上午效率最高，安排核心新技术学习'),
        bullet('下午适合深入理论（数据库、网络、操作系统）和动手写代码'),
        bullet('晚上用于巩固复习，不做新知识输入'),
        bullet('周末安排复盘 + 做项目，可以适当放松半天'),
        bullet('LeetCode 每天至少 1 题，雷打不动'),
        pageBreak(),

        // Stage 1
        heading('三、第一阶段：基础夯实（7月23日 — 8月31日）'),
        emptyLine(),
        para('暑假黄金期，每天 6-8 小时。目标是 Java 基础扎实 + Spring Boot 能跑通完整项目 + LeetCode 入门 50 题。'),
        ...weekPlan(1, '7.23 - 7.27', 'Java 基础速通（上）', [
          'Java 数据类型、包装类、String/StringBuilder 区别与底层原理',
          '面向对象三大特性：封装、继承、多态；接口 vs 抽象类',
          '集合框架源码阅读：ArrayList、LinkedList、HashMap、HashSet',
          '异常处理机制、泛型、反射、注解',
          'LeetCode 每日 1 题：数组 + 哈希表（Two Sum、三数之和等）',
        ]),
        ...weekPlan(2, '7.28 - 8.3', 'Java 基础速通（下）+ MySQL 入门', [
          '多线程基础：Thread、Runnable、线程池（ThreadPoolExecutor 7 参数）',
          'synchronized、volatile、Lock、CAS 原理深入理解',
          'JVM 内存模型（堆、栈、方法区、程序计数器）',
          'MySQL 安装、DDL/DML/DQL 基本语句、JOIN 查询',
          'LeetCode 每日 1 题：链表（反转链表、环形链表、合并有序链表）',
          '周末：用 JDBC 写一个简单的控制台 CRUD 程序',
        ]),
        ...weekPlan(3, '8.4 - 8.10', 'Spring Boot 入门', [
          'Spring IOC/DI 原理，@Autowired/@Component/@Service 等核心注解',
          'Spring Boot 项目结构、application.yml 配置详解',
          'RESTful API 设计：@RestController、@GetMapping/@PostMapping',
          'MyBatis-Plus 集成：实体类、Mapper、Service、分页查询',
          'LeetCode 每日 1 题：栈与队列（有效括号、用栈实现队列）',
          '周末：搭建第一个 Spring Boot + MySQL 项目（用户表 CRUD）',
        ]),
        ...weekPlan(4, '8.11 - 8.17', 'Spring Boot 进阶', [
          'Spring AOP 原理与应用场景（日志记录、权限校验）',
          '全局异常处理（@ControllerAdvice + @ExceptionHandler）',
          '参数校验（@Valid + BindingResult）、统一响应封装',
          'Spring Boot 拦截器 vs 过滤器的区别与使用',
          'LeetCode 每日 1 题：二叉树遍历（前中后序、层序遍历）',
          '周末：完善项目——加入登录注册、JWT 认证',
        ]),
        ...weekPlan(5, '8.18 - 8.24', '项目实战 + MySQL 深入', [
          'MySQL 索引原理：B+ 树、聚簇索引 vs 非聚簇索引、最左前缀原则',
          'SQL 优化实战：EXPLAIN 分析执行计划、慢查询日志',
          '事务隔离级别（读未提交/读已提交/可重复读/串行化）、MVCC 原理',
          '做一个博客系统后端：文章 CRUD + 分类标签 + 分页查询',
          'LeetCode 每日 1 题：动态规划入门（爬楼梯、最大子数组和）',
        ]),
        ...weekPlan(6, '8.25 - 8.31', '阶段总结 + 查漏补缺', [
          '回顾前 5 周所学全部知识点，用思维导图系统整理笔记',
          'Java 核心知识点系统性复盘（集合、多线程、JVM 三大块）',
          '完成博客系统剩余功能（评论、搜索），本地部署测试',
          'LeetCode 复习错题 + 补做之前做不出的题，确保累计 50 题',
          '写好第一阶段学习总结，标注自己的薄弱点',
          '预习第二阶段内容：Redis、计算机网络核心概念',
        ]),
        pageBreak(),

        // Stage 2
        heading('四、第二阶段：进阶深入（9月1日 — 10月31日）'),
        emptyLine(),
        para('开学后每天 4-5 小时，周末适当加量。目标是 MySQL/Redis 深入理解 + 计算机基础过关 + LeetCode 达到 100 题。'),
        ...weekPlan(7, '9.1 - 9.7', 'MySQL 深度', [
          'InnoDB 存储引擎架构：Buffer Pool、Change Buffer、Double Write',
          '索引优化实战：覆盖索引、索引下推、联合索引设计技巧',
          '分库分表入门（ShardingSphere 概念了解）',
          '主从复制原理、读写分离方案',
          'LeetCode 每日 1 题：回溯算法（全排列、子集、组合总和）',
        ]),
        ...weekPlan(8, '9.8 - 9.14', 'Redis 入门到进阶', [
          'Redis 五种数据结构及使用场景（String、Hash、List、Set、ZSet）',
          '缓存穿透、缓存击穿、缓存雪崩——概念、区别与解决方案',
          'Redis 持久化机制：RDB 快照 vs AOF 日志',
          'Redis 分布式锁（SETNX + Lua 脚本）、Redisson 框架',
          'LeetCode 每日 1 题：贪心算法专题',
        ]),
        ...weekPlan(9, '9.15 - 9.21', '计算机网络', [
          'OSI 七层模型与 TCP/IP 四层模型对比',
          'TCP 三次握手四次挥手（深入理解状态转换与 TIME_WAIT）',
          'TCP 拥塞控制（慢启动、拥塞避免、快重传、快恢复）',
          'HTTP/1.1 vs HTTP/2 vs HTTPS（TLS 1.3 握手过程）',
          'LeetCode 每日 1 题：排序算法手写（快排、归并、堆排）',
          '周末：将博客项目接入 Redis 缓存层',
        ]),
        ...weekPlan(10, '9.22 - 9.28', '操作系统', [
          '进程与线程的区别、上下文切换开销',
          '进程间通信方式（管道、消息队列、共享内存、Socket）',
          '死锁四个必要条件、预防与避免（银行家算法了解）',
          '内存管理：虚拟内存、分页分段、页面置换算法（LRU/LFU）',
          'LeetCode 每日 1 题：二分查找及其变体',
        ]),
        ...weekPlan(11, '9.29 - 10.5', 'JVM 深入', [
          'JVM 内存结构详解（堆、栈、方法区/元空间、直接内存）',
          '垃圾回收算法：标记-清除、标记-整理、复制、分代收集',
          '常见 GC 收集器对比：Serial、Parallel、CMS、G1、ZGC',
          '类加载机制（双亲委派模型）、JVM 调优参数入门',
          'LeetCode 每日 1 题：滑动窗口专题',
          '国庆假期集中开发——做一个"秒杀 Demo"项目',
        ]),
        ...weekPlan(12, '10.6 - 10.12', 'Spring 原理深入', [
          'Spring Bean 完整生命周期（实例化→属性填充→初始化→销毁）',
          'Spring 循环依赖问题与三级缓存解决方案',
          'Spring 事务传播机制（7 种）与 @Transactional 失效场景',
          'Spring Boot 自动配置原理（@SpringBootApplication 源码分析）',
          'LeetCode 每日 1 题：前缀和 + 差分数组',
        ]),
        ...weekPlan(13, '10.13 - 10.19', 'Linux + Docker', [
          'Linux 常用命令：文件操作、权限管理、进程管理、网络诊断',
          'Shell 脚本基础（变量、循环、条件判断、函数）',
          'Docker 核心三要素：镜像、容器、仓库',
          '编写 Dockerfile + docker-compose，将项目容器化部署',
          'LeetCode 每日 1 题：单调栈专题',
        ]),
        ...weekPlan(14, '10.20 - 10.26', '微服务入门 + 消息队列', [
          '微服务架构概念：服务拆分、服务注册与发现、配置中心',
          'Spring Cloud 核心组件：Nacos、Gateway、Feign、Sentinel',
          '用 Spring Cloud 搭一个简单的微服务 Demo（至少 2 个服务）',
          '消息队列入门：RabbitMQ 安装、基本概念、五种工作模式',
          'LeetCode 每日 1 题：BFS / DFS 进阶',
        ]),
        ...weekPlan(15, '10.27 - 10.31', '第二阶段总结', [
          '复习第二阶段全部知识点，更新思维导图和笔记',
          '完善秒杀项目：加入 Redis 预减库存 + 消息队列异步下单',
          'LeetCode 回顾所有错题，确保累计完成 100 题以上',
          '客观评估当前水平，标记薄弱环节，调整第三阶段计划',
        ]),
        pageBreak(),

        // Stage 3
        heading('五、第三阶段：项目实战（11月1日 — 11月30日）'),
        emptyLine(),
        para('这个月以项目为核心驱动，边做边学。目标是完成 2 个完整的、可以写进简历的项目，并打磨出第一版简历。'),
        ...weekPlan(16, '11.1 - 11.7', '项目一：商城秒杀系统（上）', [
          '功能设计：用户登录注册 → 商品列表 → 商品详情 → 秒杀下单',
          '技术栈：Spring Boot + MyBatis-Plus + Redis + RabbitMQ + MySQL',
          '核心难点攻克：超卖问题（Redis 预减库存 + Lua 脚本原子操作）',
          '接口防刷（验证码 + 接口限流）、订单异步处理',
          'LeetCode 每日 1 题（保持手感不间断）',
        ]),
        ...weekPlan(17, '11.8 - 11.14', '项目一收尾 + 项目二启动', [
          '秒杀系统完善：Sentinel 限流、JMeter 压力测试',
          '编写项目 README（系统架构图、技术选型说明、QPS 测试数据）',
          '项目二选题建议：RuoYi 若依 / 仿牛客论坛 / 博客系统升级版',
          '搭建项目二基础框架，规划功能模块',
          'LeetCode 每日 1 题',
        ]),
        ...weekPlan(18, '11.15 - 11.21', '项目二开发 + 简历初稿', [
          '项目二核心功能开发（按规划推进）',
          '开始撰写简历：教育背景 + 技术栈 + 项目经历（STAR 法则）',
          '每个项目写清：背景动机、技术选型、个人职责、难点与解决、量化成果',
          'LeetCode 每日 1 题',
        ]),
        ...weekPlan(19, '11.22 - 11.30', '收尾 + 简历打磨', [
          '项目二完成并部署到云服务器（阿里云/腾讯云学生机）',
          '简历精修：找学长/前辈帮忙 review，反复打磨措辞',
          '准备自我介绍（1 分钟简短版和 3 分钟详细版）',
          '整理"为什么选择 Java 后端"的回答思路和要点',
          '将项目部署地址、GitHub 仓库整理好，加入简历',
        ]),
        pageBreak(),

        // Stage 4
        heading('六、第四阶段：面试冲刺（12月1日 — 1月31日）'),
        emptyLine(),
        para('全力冲刺面试。每天安排：2-3 小时八股文复习 + 2 小时算法 + 2 小时投简历和模拟面试。'),
        ...weekPlan(20, '12.1 - 12.7', '八股文系统复习（一）—— Java 核心', [
          'Java 核心：集合框架、多线程、JVM 三大块逐条过，确保每道题能讲 3 分钟',
          '背诵 JavaGuide 高频面试题（每天至少 20 条）',
          'LeetCode Hot 100 专项突破：数组、字符串、链表',
          '更新各大招聘平台简历（Boss直聘、拉勾、实习僧、牛客网）',
        ]),
        ...weekPlan(21, '12.8 - 12.14', '八股文系统复习（二）—— 数据库与中间件', [
          'MySQL 高频：索引（B+树、最左匹配）、事务（隔离级别、MVCC）、SQL 优化场景题',
          'Redis 高频：五种数据结构、缓存三兄弟（穿透/击穿/雪崩）、分布式锁、集群方案',
          '框架高频：Spring IOC/AOP 原理、Spring Boot 自动配置、Spring MVC 请求流程',
          'LeetCode Hot 100 专项：二叉树、动态规划',
          '开始投递简历，每天至少投 5 家公司',
        ]),
        ...weekPlan(22, '12.15 - 12.21', '八股文系统复习（三）—— 计网 + OS + 场景题', [
          '计算机网络：TCP/UDP 对比、HTTP/HTTPS、DNS 解析过程、CDN 原理',
          '操作系统：进程线程、死锁、内存管理、IO 多路复用（select/poll/epoll）',
          '系统设计场景题：秒杀系统设计、短链系统设计、排行榜设计',
          'LeetCode Hot 100 专项：回溯、贪心、排序',
        ]),
        ...weekPlan(23, '12.22 - 12.31', '模拟面试 + 笔试集训', [
          '牛客网找模拟面试资源，每天看 3-5 篇最新面经',
          '对着镜子或录视频练习自我介绍和项目介绍（控制语速和逻辑）',
          '刷各大公司往年笔试题（字节、阿里、美团、腾讯高频题）',
          'LeetCode 按公司标签刷题（字节高频、美团高频等）',
          '持续投简历，主动跟进面试进度，不要干等',
        ]),
        ...weekPlan(24, '1.1 - 1.15', '面试实战高峰期', [
          '这是面试最密集的时期，合理安排时间，避免面试冲突',
          '每场面试结束后立即复盘：记录所有面试题，整理没答好的点',
          '针对面试中暴露的薄弱环节，当天突击补充',
          '保持良好作息和心态，面试是双向选择',
          '收到 Offer 后仔细对比：技术栈匹配度、团队氛围、转正机会',
        ]),
        ...weekPlan(25, '1.16 - 1.31', '收尾与决策', [
          '综合对比收到的 Offer，做出最终选择',
          '入职前准备：了解公司技术栈、提前熟悉业务',
          '回顾整个学习过程，总结经验和不足',
          '为实习做好准备：Git 工作流、代码规范、沟通协作',
        ]),
        pageBreak(),

        // Resources
        heading('七、推荐学习资源'),
        emptyLine(),
        subheading('必读书籍'),
        bullet('《Java核心技术 卷I》—— Java 入门必读，基础概念讲得最清楚'),
        bullet('《深入理解Java虚拟机》（周志明）—— JVM 学习圣经，面试必备'),
        bullet('《Java并发编程的艺术》—— 多线程进阶，原理讲得透彻'),
        bullet('《高性能MySQL》（第4版）—— 数据库深入，索引和优化章节必读'),
        bullet('《Redis设计与实现》—— Redis 底层原理，数据结构实现精彩'),
        bullet('《计算机网络：自顶向下方法》—— 计网首选教材，通俗易懂'),
        bullet('《现代操作系统》—— 操作系统经典教材'),
        emptyLine(),
        subheading('在线资源（强烈推荐）'),
        bullet('JavaGuide（javaguide.cn）—— Java 八股文大全，面试前必刷三遍'),
        bullet('CS-Notes（cyc2018.xyz）—— 精简版技术面试必备，适合快速复习'),
        bullet('LeetCode（leetcode.cn）—— 算法刷题首选平台，会员值得开'),
        bullet('牛客网（nowcoder.com）—— 面经、笔试真题、内推信息一站式'),
        bullet('小林 Coding（xiaolincoding.com）—— 计网 + OS 图解，非常直观'),
        bullet('程序员鱼皮（bilibili）—— 项目实战视频教程，适合跟着做'),
        emptyLine(),
        subheading('实战项目推荐（Gitee/GitHub 可搜索）'),
        bullet('RuoYi-Vue —— 开源后台管理系统，Spring Boot 全家桶最佳学习项目'),
        bullet('mall（macrozheng/mall）—— 完整电商系统，技术栈全面'),
        bullet('秒杀系统设计 —— 参考 JavaGuide 秒杀系列文章，适合作为简历项目'),
        bullet('仿牛客论坛 —— 牛客网官方项目，Spring Boot + Redis + Kafka 全栈'),
        pageBreak(),

        // Daily check-in sheets
        heading('八、每日学习打卡表'),
        emptyLine(),
        para('以下为每周一张的可打印打卡模板。完成当天任务后在对应格子打 ✓。坚持打卡，保持自律！'),
        emptyLine(),
        subheading('打卡规则'),
        bullet('每天结束时如实填写各时段完成情况'),
        bullet('"算法"列记录当天 LeetCode 完成的题数（如 "2" 表示做了 2 题）'),
        bullet('"项目"列用一句话记录当天项目开发进度（如 "完成用户模块接口"）'),
        bullet('周末进行周总结，评估本周完成率，低于 60% 需要及时调整计划'),
        bullet('连续 3 天完成率低于 60% → 说明计划过紧或执行有问题，需要复盘'),
      ]
    }
  ]
});

const outPath = 'C:\\Users\\ASUS\\Desktop\\java\\Java后端实习每日学习计划.docx';

Packer.toBuffer(doc).then(function(buf) {
  fs.writeFileSync(outPath, buf);
  console.log('Done! File written successfully to ' + outPath);
}).catch(function(err) {
  console.error('Error:', err);
  process.exit(1);
});
