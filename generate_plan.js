const docx = require("docx");
const fs = require("fs");

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  PageBreak, TableOfContents, PageNumber, Footer, Header,
  TabStopPosition, TabStopType, PositionalTab, PositionalTabAlignment,
  PositionalTabLeader, NumberFormat, LevelFormat, PageOrientation,
  convertInchesToTwip,
} = docx;

// ============ CONSTANTS ============
const PAGE_WIDTH = 11906; // A4 in DXA
const MARGIN = 1440; // 1 inch

const COLOR_PRIMARY = "1F4E79";   // dark blue
const COLOR_SECONDARY = "2E75B6"; // medium blue
const COLOR_ACCENT = "5B9BD5";    // light blue
const COLOR_HEADER_BG = "D6E4F0"; // light blue-grey
const COLOR_WHITE = "FFFFFF";
const COLOR_BLACK = "333333";
const COLOR_GRAY = "666666";
const COLOR_LIGHT_GRAY = "F2F2F2";

// Helper: create a bordered cell with shading
function cell(text, opts = {}) {
  const {
    bold = false,
    shading = undefined,
    width = 2000,
    align = AlignmentType.LEFT,
    fontSize = 21, // half-points, 21 = 10.5pt
    color = COLOR_BLACK,
    borders = {},
  } = opts;

  const children = [];
  if (text) {
    children.push(
      new Paragraph({
        alignment: align,
        spacing: { before: 40, after: 40, line: 276 },
        children: [
          new TextRun({
            text,
            bold,
            size: fontSize,
            font: "Microsoft YaHei",
            color,
          }),
        ],
      })
    );
  }

  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    shading: shading ? { fill: shading, type: ShadingType.CLEAR } : undefined,
    borders: {
      top: { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" },
      bottom: { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" },
      left: { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" },
      right: { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" },
      ...borders,
    },
    children,
  });
}

// Helper: table row
function row(cells) {
  return new TableRow({ children: cells, tableHeader: false });
}

// Helper: header row (blue background)
function headerRow(texts, widths) {
  return new TableRow({
    tableHeader: true,
    children: texts.map((t, i) =>
      cell(t, {
        bold: true,
        shading: COLOR_PRIMARY,
        width: widths[i],
        align: AlignmentType.CENTER,
        color: COLOR_WHITE,
        fontSize: 22,
      })
    ),
  });
}

// Helper: section heading paragraph
function sectionHeading(num, title) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 200 },
    children: [
      new TextRun({
        text: `第${num}章  ${title}`,
        bold: true,
        size: 36,
        font: "Microsoft YaHei",
        color: COLOR_PRIMARY,
      }),
    ],
  });
}

// Helper: sub heading
function subHeading(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 120 },
    children: [
      new TextRun({
        text,
        bold: true,
        size: 28,
        font: "Microsoft YaHei",
        color: COLOR_SECONDARY,
      }),
    ],
  });
}

// Helper: sub-sub heading
function subSubHeading(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 160, after: 80 },
    children: [
      new TextRun({
        text,
        bold: true,
        size: 24,
        font: "Microsoft YaHei",
        color: COLOR_ACCENT,
      }),
    ],
  });
}

// Normal paragraph
function para(text, opts = {}) {
  const { bold = false, indent = 0, spacing = undefined, color = COLOR_BLACK } = opts;
  return new Paragraph({
    spacing: spacing || { before: 60, after: 60, line: 312 },
    indent: indent ? { firstLine: indent } : undefined,
    children: [
      new TextRun({
        text,
        bold,
        size: 22,
        font: "Microsoft YaHei",
        color,
      }),
    ],
  });
}

// Multi-text paragraph
function richPara(runs) {
  return new Paragraph({
    spacing: { before: 60, after: 60, line: 312 },
    children: runs.map(
      (r) =>
        new TextRun({
          text: r.text,
          bold: r.bold || false,
          size: r.size || 22,
          font: "Microsoft YaHei",
          color: r.color || COLOR_BLACK,
          italics: r.italics || false,
        })
    ),
  });
}

// Bullet item
function bullet(text, level = 0) {
  return new Paragraph({
    spacing: { before: 40, after: 40, line: 300 },
    bullet: { level },
    children: [
      new TextRun({
        text,
        size: 22,
        font: "Microsoft YaHei",
      }),
    ],
  });
}

// Empty line spacer
function spacer(h = 120) {
  return new Paragraph({
    spacing: { before: h, after: 0 },
    children: [],
  });
}

// ============ PHASE DATA ============

const phases = [
  {
    num: "一",
    title: "基础巩固阶段",
    period: "7月 - 8月（第1-8周）",
    weeks: "8周",
    goal: "打下扎实的 Java 基础，掌握数据库核心知识，养成每日刷题习惯",
    monthlyTargets: [
      {
        month: "7月（第1-4周）",
        items: [
          "Java 集合框架全部掌握（ArrayList、LinkedList、HashMap、ConcurrentHashMap 源码级理解）",
          "Java 多线程基础（线程创建、synchronized、volatile、线程池）",
          "MySQL 基础（SQL 语句、表设计、索引原理入门）",
          "LeetCode 刷题 30 道（数组、链表、字符串）",
        ],
      },
      {
        month: "8月（第5-8周）",
        items: [
          "JVM 内存模型、垃圾回收算法、类加载机制",
          "多线程进阶（Lock、AQS、ThreadLocal、并发工具类）",
          "MySQL 进阶（事务隔离级别、MVCC、慢SQL优化、EXPLAIN）",
          "计算机网络 & 操作系统八股文",
          "LeetCode 刷题累计 70 道（加入栈、队列、二叉树）",
        ],
      },
    ],
    dailySchedule: {
      morning: {
        time: "08:30 - 11:30（3小时）",
        tasks: [
          "Java 基础知识学习（看书 / 视频 / 博客）",
          "记笔记，整理当日知识点",
          "手写核心代码示例加深理解",
        ],
      },
      afternoon: {
        time: "14:00 - 17:00（3小时）",
        tasks: [
          "数据库 / 网络 / OS 理论学习",
          "阅读技术博客或源码分析文章",
          "整理面试八股文笔记",
        ],
      },
      evening: {
        time: "19:00 - 21:00（2小时）",
        tasks: ["LeetCode 刷题（每天 1-2 道）", "复盘当日学习内容", "记录疑难问题，第二天优先解决"],
      },
    },
    weeklyCheckpoints: [
      "第1周末：完成 ArrayList、LinkedList、HashMap 源码阅读，刷题 ≥5 道",
      "第2周末：完成 ConcurrentHashMap、线程池源码阅读，刷题 ≥10 道",
      "第3周末：完成 JVM 内存模型学习，刷题 ≥15 道",
      "第4周末（月末）：阶段小测 — 随机抽 5 道八股文口头回答，刷题 ≥20 道",
      "第5周末：完成 MySQL 索引原理学习，刷题 ≥30 道",
      "第6周末：完成事务 & MVCC 学习，刷题 ≥40 道",
      "第7周末：完成网络 & OS 八股文，刷题 ≥50 道",
      "第8周末（月末）：模拟面试 1 次 + 阶段总结，刷题 ≥60 道",
    ],
  },
  {
    num: "二",
    title: "框架上手阶段",
    period: "9月 - 10月中旬（第9-14周）",
    weeks: "6周",
    goal: "掌握 Spring 全家桶核心原理，能独立搭建 Spring Boot 项目",
    monthlyTargets: [
      {
        month: "9月（第9-12周）",
        items: [
          "Spring IoC & AOP 原理（源码级理解，能画图讲清楚）",
          "Spring Bean 生命周期、循环依赖解决",
          "Spring Boot 自动配置原理",
          "Spring MVC 请求处理流程",
          "MyBatis / MyBatis-Plus 使用（#{} vs ${}、动态SQL、分页插件）",
        ],
      },
      {
        month: "10月上旬（第13-14周）",
        items: [
          "Redis 5 种数据结构 + 应用场景（缓存、分布式锁、排行榜）",
          "Redis 缓存穿透/击穿/雪崩解决方案",
          "Redis 持久化（RDB vs AOF）、过期策略",
          "RabbitMQ 基础（消息模型、削峰解耦、延迟队列）",
          "搭建第一个 Spring Boot + MyBatis-Plus + Redis 项目骨架",
        ],
      },
    ],
    dailySchedule: {
      morning: {
        time: "08:30 - 11:30（3小时）",
        tasks: [
          "Spring 源码 / 原理学习（视频 + 博客 + 官方文档）",
          "跟着教程动手搭建项目模块",
          "画架构图 / 流程图加深理解",
        ],
      },
      afternoon: {
        time: "14:00 - 17:00（3小时）",
        tasks: [
          "Redis / MQ / MyBatis 中间件学习",
          "阅读中间件官方文档和最佳实践",
          "整理框架相关八股文",
        ],
      },
      evening: {
        time: "19:00 - 21:30（2.5小时）",
        tasks: [
          "LeetCode 刷题（每天 1-2 道，保持手感）",
          "写当天学习的技术博客（输出倒逼输入）",
          "复盘 + 整理问题",
        ],
      },
    },
    weeklyCheckpoints: [
      "第9周末：能独立手写 Spring IoC 简易实现，刷题 ≥70 道",
      "第10周末：能讲清楚 AOP 原理和动态代理，刷题 ≥80 道",
      "第11周末：能讲清楚 Spring Boot 自动配置，独立搭建项目，刷题 ≥90 道",
      "第12周末（月末）：整合 Spring Boot + MyBatis-Plus 跑通 CRUD，刷题 ≥100 道",
      "第13周末：Redis 核心知识掌握，在项目中集成 Redis 缓存",
      "第14周末：RabbitMQ 基础掌握，阶段总结 + 模拟面试 1 次",
    ],
  },
  {
    num: "三",
    title: "项目实战阶段",
    period: "10月中旬 - 11月底（第13-20周）",
    weeks: "8周（与框架阶段有2周重叠）",
    goal: "完成 1-2 个高质量项目，丰富简历，能深入讲解项目设计",
    monthlyTargets: [
      {
        month: "10月中-11月中（第15-18周）",
        items: [
          "项目一：商城秒杀系统（Spring Boot + MyBatis-Plus + Redis + RabbitMQ）",
          "核心功能：用户登录（JWT）、商品列表、秒杀下单、订单处理、库存扣减",
          "技术亮点：Redis 预减库存、RabbitMQ 异步下单、分布式锁、缓存预热",
          "压测优化：JMeter 压测，分析瓶颈，优化 SQL 和缓存策略",
        ],
      },
      {
        month: "11月下（第19-20周）",
        items: [
          "项目二：博客/论坛系统 或 结合兴趣的自由项目",
          "核心功能：文章发布、评论、点赞、关注、消息通知",
          "技术亮点：Elasticsearch 全文搜索（可选）、接口限流、统一异常处理",
          "项目文档：写 README、架构图、接口文档、部署文档",
          "将两个项目推送到 GitHub，写好 commit 记录",
        ],
      },
    ],
    dailySchedule: {
      morning: {
        time: "08:30 - 11:30（3小时）",
        tasks: [
          "写项目代码（按功能模块推进）",
          "遇到问题先自己查资料解决，培养独立排查能力",
          "每完成一个模块，写单元测试验证",
        ],
      },
      afternoon: {
        time: "14:00 - 17:00（3小时）",
        tasks: [
          "继续项目开发 / 优化重构",
          "学习项目中用到的高级技术点（分布式锁、消息队列消息可靠性等）",
          "写项目文档和技术总结",
        ],
      },
      evening: {
        time: "19:00 - 21:30（2.5小时）",
        tasks: [
          "LeetCode 继续刷题（每天至少 1 道）",
          "复习八股文（结合项目经验回答）",
          "更新 GitHub + 写技术博客",
        ],
      },
    },
    weeklyCheckpoints: [
      "第15周末：项目一 — 完成用户模块 + 商品模块",
      "第16周末：项目一 — 完成秒杀核心逻辑 + Redis 集成",
      "第17周末：项目一 — 完成 RabbitMQ 异步下单 + 压测优化",
      "第18周末：项目一收尾 — 完善文档 + GitHub 上传",
      "第19周末：项目二 — 完成核心功能开发",
      "第20周末：项目二收尾 — 完善文档 + 简历中加入项目描述",
    ],
  },
  {
    num: "四",
    title: "面试冲刺阶段",
    period: "12月 - 投递前（第21-24周）",
    weeks: "4周",
    goal: "系统复习八股文，准备简历，模拟面试，开始投递",
    monthlyTargets: [
      {
        month: "12月上（第21-22周）",
        items: [
          "系统梳理 Java 后端八股文（Java基础、集合、多线程、JVM、Spring、MySQL、Redis、网络、OS）",
          "每天模拟面试 30 分钟（用手机录音，自己听回答质量）",
          "项目问答准备：能用 STAR 法则讲清楚项目背景、设计、难点、成果",
          "简历打磨：找学长/老师/网上帮忙 review 简历",
        ],
      },
      {
        month: "12月下（第23-24周）",
        items: [
          "开始在牛客网 / Boss直聘 / 官网海投简历",
          "参加线上笔试（牛客网有很多模拟笔试）",
          "每次面试完及时复盘，补充薄弱点",
          "算法保持手感：每周至少刷 5 道高频题",
          "准备自我介绍（1分钟版 + 3分钟版）",
        ],
      },
    ],
    dailySchedule: {
      morning: {
        time: "08:30 - 11:30（3小时）",
        tasks: [
          "八股文系统复习（按模块：周一 Java基础、周二 多线程+JVM、周三 Spring、周四 DB+Redis、周五 网络+OS）",
          "背诵 + 手写关键知识点",
          "对照面经查漏补缺",
        ],
      },
      afternoon: {
        time: "14:00 - 17:00（3小时）",
        tasks: [
          "模拟面试 / 参加真实面试",
          "复盘面试中的问题，针对性补强",
          "项目问答练习（用 STAR 法则讲项目）",
        ],
      },
      evening: {
        time: "19:00 - 21:00（2小时）",
        tasks: [
          "刷 LeetCode 高频题（保持手感）",
          "浏览面经、更新简历",
          "投递简历 + 跟进进度",
        ],
      },
    },
    weeklyCheckpoints: [
      "第21周末：八股文第一轮复习完毕，模拟面试 ≥3 次",
      "第22周末：项目问答准备完毕，简历定稿，开始投递",
      "第23周末：投递 ≥20 家公司，参加 ≥2 场面试/笔试",
      "第24周末：持续投递+面试，总结高频面试题，针对性补强",
    ],
  },
];

// ============ BUILD DOCUMENT ============

const children = [];

// ------- COVER PAGE -------
children.push(spacer(2400));
children.push(spacer(0));
children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 200 },
    children: [
      new TextRun({
        text: "Java 后端实习",
        bold: true,
        size: 64,
        font: "Microsoft YaHei",
        color: COLOR_PRIMARY,
      }),
    ],
  })
);
children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 120 },
    children: [
      new TextRun({
        text: "每日学习计划",
        bold: true,
        size: 64,
        font: "Microsoft YaHei",
        color: COLOR_PRIMARY,
      }),
    ],
  })
);
children.push(spacer(600));
children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 60 },
    children: [
      new TextRun({
        text: "2026 年 7 月 — 2026 年 12 月",
        size: 32,
        font: "Microsoft YaHei",
        color: COLOR_SECONDARY,
      }),
    ],
  })
);
children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 60 },
    children: [
      new TextRun({
        text: "目标：寒假拿到 Java 后端实习 Offer",
        size: 28,
        font: "Microsoft YaHei",
        color: COLOR_GRAY,
      }),
    ],
  })
);
children.push(spacer(1200));
children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    border: {
      top: { style: BorderStyle.SINGLE, size: 2, color: COLOR_PRIMARY, space: 12 },
    },
    spacing: { before: 200 },
    children: [
      new TextRun({
        text: "计算机科学与技术 · 大三",
        size: 24,
        font: "Microsoft YaHei",
        color: COLOR_GRAY,
      }),
    ],
  })
);
children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 200 },
    children: [
      new TextRun({
        text: "2026 年 7 月 23 日",
        size: 24,
        font: "Microsoft YaHei",
        color: COLOR_GRAY,
      }),
    ],
  })
);

children.push(
  new Paragraph({
    children: [new PageBreak()],
  })
);

// ------- TABLE OF CONTENTS -------
children.push(
  new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 240 },
    children: [
      new TextRun({
        text: "目  录",
        bold: true,
        size: 36,
        font: "Microsoft YaHei",
        color: COLOR_PRIMARY,
      }),
    ],
  })
);
children.push(
  new TableOfContents("目录", {
    hyperlink: true,
    headingStyleRange: "1-3",
  })
);

children.push(
  new Paragraph({
    children: [new PageBreak()],
  })
);

// ------- CHAPTER: SKILL CHECKLIST -------
children.push(sectionHeading("一", "技能清单总览"));

children.push(
  para(
    "以下是 Java 后端实习岗位的核心技能要求，按重要性分为三个等级。在后续的学习中，请对照此清单检查自己的掌握情况。"
  )
);

children.push(subHeading("1.1  必会技能（面试必问，占 80%）"));

const skillTable1 = new Table({
  width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
  columnWidths: [2000, 3000, 4000],
  rows: [
    headerRow(["技能分类", "核心知识点", "掌握标准"], [2000, 3000, 4000]),
    row([
      cell("Java 基础", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("集合框架、多线程、JVM", { width: 3000 }),
      cell("能画出 HashMap 数据结构，能讲清楚线程池工作原理", { width: 4000 }),
    ]),
    row([
      cell("Spring 全家桶", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("IoC/AOP、Spring Boot、Spring MVC", { width: 3000 }),
      cell("能手写简易 IoC 容器，能讲清楚自动配置原理", { width: 4000 }),
    ]),
    row([
      cell("MySQL", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("SQL、索引、事务、MVCC", { width: 3000 }),
      cell("能手写复杂 SQL，能用 EXPLAIN 分析执行计划", { width: 4000 }),
    ]),
    row([
      cell("Redis", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("数据结构、缓存策略、持久化", { width: 3000 }),
      cell("能在项目中正确使用 Redis 做缓存", { width: 4000 }),
    ]),
    row([
      cell("计算机网络", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("TCP/HTTP、三次握手、状态码", { width: 3000 }),
      cell("能画出 TCP 握手挥手流程图", { width: 4000 }),
    ]),
    row([
      cell("数据结构与算法", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("数组、链表、树、排序、DP", { width: 3000 }),
      cell("LeetCode 中等题能 30 分钟内 AC", { width: 4000 }),
    ]),
  ],
});
children.push(skillTable1);

children.push(subHeading("1.2  加分技能（拉开差距）"));

const skillTable2 = new Table({
  width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
  columnWidths: [2000, 3000, 4000],
  rows: [
    headerRow(["技能分类", "核心知识点", "掌握标准"], [2000, 3000, 4000]),
    row([
      cell("消息队列", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("RabbitMQ / RocketMQ 基础", { width: 3000 }),
      cell("能讲清楚削峰解耦的应用场景", { width: 4000 }),
    ]),
    row([
      cell("微服务入门", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("Spring Cloud 基础组件", { width: 3000 }),
      cell("了解注册中心、配置中心、网关概念", { width: 4000 }),
    ]),
    row([
      cell("设计模式", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("单例、工厂、代理、策略", { width: 3000 }),
      cell("能结合 Spring 源码讲设计模式的应用", { width: 4000 }),
    ]),
    row([
      cell("Linux", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("常用命令、看日志、部署", { width: 3000 }),
      cell("能在 Linux 上部署 Spring Boot 项目", { width: 4000 }),
    ]),
    row([
      cell("Docker", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("镜像、容器、Docker Compose", { width: 3000 }),
      cell("能用 Docker 搭建开发环境", { width: 4000 }),
    ]),
  ],
});
children.push(skillTable2);

children.push(subHeading("1.3  工具链"));

const skillTable3 = new Table({
  width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
  columnWidths: [2000, 4000, 3000],
  rows: [
    headerRow(["工具", "用途", "熟练标准"], [2000, 4000, 3000]),
    row([
      cell("Git", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("版本控制：commit、branch、merge、rebase", { width: 4000 }),
      cell("日常工作流无障碍使用", { width: 3000 }),
    ]),
    row([
      cell("Maven / Gradle", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("项目构建与依赖管理", { width: 4000 }),
      cell("能配置依赖、插件、多模块", { width: 3000 }),
    ]),
    row([
      cell("Postman / Apifox", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("接口调试与测试", { width: 4000 }),
      cell("能构造各种请求、管理环境变量", { width: 3000 }),
    ]),
    row([
      cell("IDEA", { bold: true, width: 2000, shading: COLOR_LIGHT_GRAY }),
      cell("开发 IDE", { width: 4000 }),
      cell("熟练使用调试、插件、快捷键", { width: 3000 }),
    ]),
  ],
});
children.push(skillTable3);

children.push(
  new Paragraph({
    children: [new PageBreak()],
  })
);

// ------- PHASE CHAPTERS -------
for (const phase of phases) {
  children.push(sectionHeading(phase.num, phase.title));

  // Overview box
  children.push(
    new Paragraph({
      spacing: { before: 120, after: 60 },
      border: {
        top: { style: BorderStyle.SINGLE, size: 1, color: COLOR_ACCENT, space: 8 },
        bottom: { style: BorderStyle.SINGLE, size: 1, color: COLOR_ACCENT, space: 8 },
        left: { style: BorderStyle.SINGLE, size: 1, color: COLOR_ACCENT, space: 8 },
        right: { style: BorderStyle.SINGLE, size: 1, color: COLOR_ACCENT, space: 8 },
      },
      children: [
        new TextRun({
          text: `时间：${phase.period}　|　周期：${phase.weeks}　|　目标：${phase.goal}`,
          size: 22,
          font: "Microsoft YaHei",
          color: COLOR_SECONDARY,
        }),
      ],
    })
  );

  children.push(subHeading(`${phase.num}.1  月度目标`));

  for (const mt of phase.monthlyTargets) {
    children.push(subSubHeading(mt.month));
    for (const item of mt.items) {
      children.push(bullet(item));
    }
  }

  children.push(subHeading(`${phase.num}.2  每日时间安排`));

  const sched = phase.dailySchedule;

  const scheduleTable = new Table({
    width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
    columnWidths: [2000, 2500, 6500],
    rows: [
      headerRow(["时间段", "时间", "学习内容"], [2000, 2500, 6500]),
      row([
        cell("☀ 上午", { bold: true, width: 2000, shading: COLOR_HEADER_BG, align: AlignmentType.CENTER }),
        cell(sched.morning.time, { width: 2500, align: AlignmentType.CENTER }),
        cell(sched.morning.tasks.map((t) => `• ${t}`).join("\n"), { width: 6500 }),
      ]),
      row([
        cell("☀ 下午", { bold: true, width: 2000, shading: COLOR_HEADER_BG, align: AlignmentType.CENTER }),
        cell(sched.afternoon.time, { width: 2500, align: AlignmentType.CENTER }),
        cell(sched.afternoon.tasks.map((t) => `• ${t}`).join("\n"), { width: 6500 }),
      ]),
      row([
        cell("🌙 晚上", { bold: true, width: 2000, shading: COLOR_HEADER_BG, align: AlignmentType.CENTER }),
        cell(sched.evening.time, { width: 2500, align: AlignmentType.CENTER }),
        cell(sched.evening.tasks.map((t) => `• ${t}`).join("\n"), { width: 6500 }),
      ]),
    ],
  });
  children.push(scheduleTable);
  children.push(
    richPara([
      { text: "⏱ 每日总学习时间：", bold: true },
      { text: "约 8 小时", bold: true, color: COLOR_SECONDARY },
      { text: "（可根据个人课程安排灵活调整，保证每周 ≥ 40 小时有效学习时间）" },
    ])
  );

  children.push(subHeading(`${phase.num}.3  每周检查点`));
  children.push(
    para("以下检查点在每周日晚上进行自我评估，完成的打 ✓，未完成的列入下周优先任务。")
  );

  for (const cp of phase.weeklyCheckpoints) {
    children.push(
      richPara([
        { text: "☐  ", bold: true, color: COLOR_SECONDARY },
        { text: cp, size: 22 },
      ])
    );
  }

  children.push(
    new Paragraph({
      children: [new PageBreak()],
    })
  );
}

// ------- CHAPTER: RESOURCES -------
children.push(sectionHeading("六", "推荐学习资源"));

children.push(subHeading("6.1  视频教程"));

const resVideoTable = new Table({
  width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
  columnWidths: [2500, 3500, 2000, 1000],
  rows: [
    headerRow(["课程名称", "内容", "平台", "优先级"], [2500, 3500, 2000, 1000]),
    row([
      cell("黑马程序员 Spring Boot", { bold: true, width: 2500 }),
      cell("Spring Boot 从入门到实战，覆盖 MyBatis、Redis 集成", { width: 3500 }),
      cell("B站", { width: 2000 }),
      cell("必看", { width: 1000, shading: "FFF2CC", bold: true, align: AlignmentType.CENTER }),
    ]),
    row([
      cell("尚硅谷 Redis", { bold: true, width: 2500 }),
      cell("Redis 核心原理 + 实战，讲得很细", { width: 3500 }),
      cell("B站", { width: 2000 }),
      cell("必看", { width: 1000, shading: "FFF2CC", bold: true, align: AlignmentType.CENTER }),
    ]),
    row([
      cell("尚硅谷 MySQL 高级", { bold: true, width: 2500 }),
      cell("MySQL 优化、索引、锁、主从复制", { width: 3500 }),
      cell("B站", { width: 2000 }),
      cell("推荐", { width: 1000, shading: "E2EFDA", align: AlignmentType.CENTER }),
    ]),
    row([
      cell("黑马程序员 JVM", { bold: true, width: 2500 }),
      cell("JVM 内存结构、GC、调优", { width: 3500 }),
      cell("B站", { width: 2000 }),
      cell("必看", { width: 1000, shading: "FFF2CC", bold: true, align: AlignmentType.CENTER }),
    ]),
    row([
      cell("黑马程序员 RabbitMQ", { bold: true, width: 2500 }),
      cell("消息队列基础 + Spring Boot 整合", { width: 3500 }),
      cell("B站", { width: 2000 }),
      cell("推荐", { width: 1000, shading: "E2EFDA", align: AlignmentType.CENTER }),
    ]),
    row([
      cell("尚硅谷 Java 大厂面试题", { bold: true, width: 2500 }),
      cell("面试前刷一遍，查漏补缺", { width: 3500 }),
      cell("B站", { width: 2000 }),
      cell("面试前必看", { width: 1000, shading: "FCE4D6", align: AlignmentType.CENTER }),
    ]),
  ],
});
children.push(resVideoTable);

children.push(subHeading("6.2  书籍推荐"));

children.push(
  richPara([
    { text: "《Java 核心技术 卷 I》", bold: true },
    { text: " — Java 入门经典，适合系统学习（不适合速成，当字典查阅）" },
  ])
);
children.push(
  richPara([
    { text: "《深入理解 Java 虚拟机（第3版）》", bold: true },
    { text: " — JVM 必读，面试前至少看完前 5 章" },
  ])
);
children.push(
  richPara([
    { text: "《Java 并发编程的艺术》", bold: true },
    { text: " — 多线程进阶，源码分析透彻" },
  ])
);
children.push(
  richPara([
    { text: "《高性能 MySQL（第4版）》", bold: true },
    { text: " — MySQL 进阶必读（太厚，看前 8 章即可）" },
  ])
);
children.push(
  richPara([
    { text: "《Redis 设计与实现》", bold: true },
    { text: " — 理解 Redis 底层原理，面试加分" },
  ])
);

children.push(subHeading("6.3  在线资源"));

children.push(
  richPara([
    { text: "JavaGuide", bold: true, color: COLOR_SECONDARY },
    { text: "（javaguide.cn）— 最全的 Java 八股文，免费，必看！" },
  ])
);
children.push(
  richPara([
    { text: "小林Coding", bold: true, color: COLOR_SECONDARY },
    { text: "（xiaolincoding.com）— 网络 & OS 图解，通俗易懂" },
  ])
);
children.push(
  richPara([
    { text: "代码随想录", bold: true, color: COLOR_SECONDARY },
    { text: "（programmercarl.com）— 算法刷题路线，跟着刷就行" },
  ])
);
children.push(
  richPara([
    { text: "LeetCode 中国站", bold: true, color: COLOR_SECONDARY },
    { text: "（leetcode.cn）— 刷题平台，优先刷热门 100 题" },
  ])
);
children.push(
  richPara([
    { text: "牛客网", bold: true, color: COLOR_SECONDARY },
    { text: "（nowcoder.com）— 面经 + 笔试 + 内推，找实习必备" },
  ])
);
children.push(
  richPara([
    { text: "GitHub", bold: true, color: COLOR_SECONDARY },
    { text: "（github.com）— 搜 \"Java 面试\" 能找到大量面经仓库" },
  ])
);

children.push(
  new Paragraph({
    children: [new PageBreak()],
  })
);

// ------- CHAPTER: INTERVIEW PREP -------
children.push(sectionHeading("七", "面试准备清单"));

children.push(subHeading("7.1  简历要点"));

children.push(bullet("一页纸原则：HR 看简历只有 10 秒，控制在 1 页 A4 纸"));
children.push(bullet("教育背景：学校、专业、GPA（如果 3.5+/4.0）、相关课程"));
children.push(bullet("技术栈：按熟练程度分级写，精通 5 个 > 了解 20 个"));
children.push(bullet("项目经验：每个项目用 STAR 法则（背景-任务-行动-结果）描述"));
children.push(bullet("避免写\"了解\"一堆没学过的技术，面试官会顺着问"));
children.push(bullet("GitHub 链接放在显眼位置，项目 README 要完善"));

children.push(subHeading("7.2  面试高频八股文 TOP 20"));

const interviewQA = [
  ["1", "HashMap 的底层原理？1.7 和 1.8 的区别？"],
  ["2", "ConcurrentHashMap 如何保证线程安全？"],
  ["3", "线程池的 7 个参数和拒绝策略？"],
  ["4", "synchronized 和 ReentrantLock 的区别？"],
  ["5", "JVM 内存模型？堆和栈的区别？"],
  ["6", "垃圾回收算法有哪些？CMS 和 G1 的区别？"],
  ["7", "类加载机制和双亲委派模型？"],
  ["8", "谈谈你对 Spring IoC 和 AOP 的理解？"],
  ["9", "Spring Bean 的生命周期？"],
  ["10", "Spring Boot 自动配置原理？"],
  ["11", "Spring MVC 处理请求的流程？"],
  ["12", "MySQL 索引底层数据结构？为什么用 B+Tree？"],
  ["13", "MySQL 事务隔离级别？MVCC 原理？"],
  ["14", "SQL 优化怎么做？EXPLAIN 各字段含义？"],
  ["15", "Redis 缓存穿透/击穿/雪崩是什么？怎么解决？"],
  ["16", "Redis 持久化 RDB 和 AOF 的区别？"],
  ["17", "TCP 三次握手和四次挥手？为什么是三次？"],
  ["18", "HTTP 和 HTTPS 的区别？HTTPS 加密过程？"],
  ["19", "进程和线程的区别？协程是什么？"],
  ["20", "常用的设计模式有哪些？你在项目中怎么用的？"],
];

const interviewTable = new Table({
  width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
  columnWidths: [600, 8500],
  rows: [
    headerRow(["序号", "面试题"], [600, 8500]),
    ...interviewQA.map(([num, q]) =>
      row([
        cell(num, { width: 600, align: AlignmentType.CENTER, bold: true }),
        cell(q, { width: 8500 }),
      ])
    ),
  ],
});
children.push(interviewTable);

children.push(subHeading("7.3  面试准备时间线"));

children.push(
  richPara([
    { text: "面试前 1 个月：", bold: true },
    { text: "完成八股文第一轮背诵，每天模拟面试 30 分钟" },
  ])
);
children.push(
  richPara([
    { text: "面试前 2 周：", bold: true },
    { text: "简历定稿，开始在牛客网 / Boss直聘投递" },
  ])
);
children.push(
  richPara([
    { text: "面试前 1 周：", bold: true },
    { text: "准备自我介绍（1 分钟版 + 3 分钟版），练习到自然流利" },
  ])
);
children.push(
  richPara([
    { text: "每次面试后：", bold: true },
    { text: "立即复盘 — 记录被问到的问题，不会的当天查清楚" },
  ])
);
children.push(
  richPara([
    { text: "拿 Offer 后：", bold: true },
    { text: "不是终点！继续学习，为入职做好准备" },
  ])
);

children.push(subHeading("7.4  常用投递渠道"));

children.push(bullet("牛客网 — 校招/实习信息最全，还有笔试题库和内推"));
children.push(bullet("Boss直聘 — 直接和 HR/技术负责人沟通，反馈快"));
children.push(bullet("实习僧 — 专注实习岗位"));
children.push(bullet("公司官网 — 大厂都有自己的校招官网，直接投"));
children.push(bullet("学长学姐内推 — 最高效的方式，主动去问"));

children.push(
  new Paragraph({
    children: [new PageBreak()],
  })
);

// ------- CHAPTER: WEEKLY TRACKER -------
children.push(sectionHeading("八", "每日学习打卡模板"));

children.push(
  para(
    "以下是一个周度学习打卡表模板，建议打印出来贴在桌前，每天完成后打 ✓。也可以使用 Notion / Excel 电子版替代。"
  )
);

// Weekly table template
const days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
const weeklyRows = [
  headerRow(["时间段", ...days], [1800, 1200, 1200, 1200, 1200, 1200, 1200, 1200]),
  row([
    cell("上午\n(3h)", { bold: true, width: 1800, align: AlignmentType.CENTER, shading: COLOR_HEADER_BG }),
    ...days.map(() => cell("", { width: 1200, align: AlignmentType.CENTER })),
  ]),
  row([
    cell("下午\n(3h)", { bold: true, width: 1800, align: AlignmentType.CENTER, shading: COLOR_HEADER_BG }),
    ...days.map(() => cell("", { width: 1200, align: AlignmentType.CENTER })),
  ]),
  row([
    cell("晚上\n(2h)", { bold: true, width: 1800, align: AlignmentType.CENTER, shading: COLOR_HEADER_BG }),
    ...days.map(() => cell("", { width: 1200, align: AlignmentType.CENTER })),
  ]),
  row([
    cell("刷题数", { bold: true, width: 1800, align: AlignmentType.CENTER, shading: COLOR_LIGHT_GRAY }),
    ...days.map(() => cell("", { width: 1200, align: AlignmentType.CENTER })),
  ]),
  row([
    cell("完成度", { bold: true, width: 1800, align: AlignmentType.CENTER, shading: COLOR_LIGHT_GRAY }),
    ...days.map(() => cell("", { width: 1200, align: AlignmentType.CENTER })),
  ]),
];

const weeklyTable = new Table({
  width: { size: PAGE_WIDTH - MARGIN * 2, type: WidthType.DXA },
  columnWidths: [1800, 1200, 1200, 1200, 1200, 1200, 1200, 1200],
  rows: weeklyRows,
});
children.push(weeklyTable);

children.push(spacer(120));
children.push(
  richPara([
    { text: "备注：", bold: true },
    { text: "完成度评分标准 — A：超额完成　B：按计划完成　C：基本完成　D：未完成（需记录原因）" },
  ])
);

children.push(spacer(240));

// ------- FINAL ENCOURAGEMENT -------
children.push(
  new Paragraph({
    spacing: { before: 360, after: 120 },
    border: {
      top: { style: BorderStyle.SINGLE, size: 2, color: COLOR_PRIMARY, space: 12 },
      bottom: { style: BorderStyle.SINGLE, size: 2, color: COLOR_PRIMARY, space: 12 },
    },
    children: [
      new TextRun({
        text: "💪 坚持就是胜利，每天进步一点点，寒假 Offer 就在前方！",
        bold: true,
        size: 28,
        font: "Microsoft YaHei",
        color: COLOR_PRIMARY,
      }),
    ],
  })
);

children.push(
  para(
    "这份计划是一个框架，请根据自己的实际进度灵活调整。重要的是保持每天学习的节奏感和持续输出的习惯（写博客、记笔记、做项目）。祝你在寒假顺利拿到心仪的 Java 后端实习 Offer！"
  )
);

// ============ CREATE DOCUMENT ============

const doc = new Document({
  styles: {
    default: {
      document: {
        run: {
          size: 22,
          font: "Microsoft YaHei",
        },
      },
    },
  },
  numbering: {
    config: [
      {
        reference: "bullet-list",
        levels: [
          {
            level: 0,
            format: LevelFormat.BULLET,
            text: "•",
            alignment: AlignmentType.LEFT,
            style: {
              paragraph: {
                indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.25) },
              },
            },
          },
        ],
      },
    ],
  },
  sections: [
    {
      properties: {
        page: {
          size: { width: PAGE_WIDTH, height: 16838 },
          margin: {
            top: MARGIN,
            bottom: MARGIN,
            left: MARGIN,
            right: MARGIN,
          },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              children: [
                new TextRun({
                  text: "Java 后端实习 · 每日学习计划",
                  size: 18,
                  font: "Microsoft YaHei",
                  color: COLOR_GRAY,
                  italics: true,
                }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({
                  text: "— ",
                  size: 18,
                  font: "Microsoft YaHei",
                  color: COLOR_GRAY,
                }),
                new TextRun({
                  children: [PageNumber.CURRENT],
                  size: 18,
                  font: "Microsoft YaHei",
                  color: COLOR_GRAY,
                }),
                new TextRun({
                  text: " —",
                  size: 18,
                  font: "Microsoft YaHei",
                  color: COLOR_GRAY,
                }),
              ],
            }),
          ],
        }),
      },
      children,
    },
  ],
});

// ============ OUTPUT ============

const outPath = "C:/Users/ASUS/Desktop/java/Java后端实习每日学习计划_v2.docx";
Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(outPath, buffer);
  console.log(`Document saved to: ${outPath}`);
});
