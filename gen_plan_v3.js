const docx = require('docx');
const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, PageBreak, TableOfContents
} = docx;

const pageMargins = { top: 1134, bottom: 1134, left: 1134, right: 1134 };
const BLUE = '1F4E79', LIGHT = 'EAF1F8', GREY = '555555';

function h(text, lv = HeadingLevel.HEADING_1) {
  return new Paragraph({ heading: lv, children: [new TextRun({ text, bold: true })] });
}
function h2(t) { return h(t, HeadingLevel.HEADING_2); }
function h3(t) { return h(t, HeadingLevel.HEADING_3); }
function para(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120, line: 360 },
    children: [new TextRun({ text, size: 22, font: 'Microsoft YaHei', color: opts.color || '222222', ...opts.run })],
  });
}
function bullet(text) {
  return new Paragraph({
    spacing: { after: 80, line: 340 },
    bullet: { level: 0 },
    children: [new TextRun({ text, size: 22, font: 'Microsoft YaHei' })],
  });
}
function empty() { return new Paragraph({ spacing: { after: 60 }, children: [] }); }
function pageBreak() { return new Paragraph({ children: [new PageBreak()] }); }

function makeTable(headers, rows, colWidths, alignLeftCols = []) {
  const hdr = new TableRow({
    children: headers.map((t, i) => new TableCell({
      width: { size: colWidths[i], type: WidthType.DXA },
      shading: { fill: BLUE, type: 'CLEAR' },
      children: [new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 60, after: 60 },
        children: [new TextRun({ text: t, size: 21, bold: true, font: 'Microsoft YaHei', color: 'FFFFFF' })] })],
    })),
  });
  const body = rows.map((r, ri) => new TableRow({
    children: r.map((t, ci) => new TableCell({
      width: { size: colWidths[ci], type: WidthType.DXA },
      shading: ri % 2 === 0 ? { fill: LIGHT, type: 'CLEAR' } : undefined,
      children: [new Paragraph({ alignment: alignLeftCols.includes(ci) ? AlignmentType.LEFT : AlignmentType.CENTER, spacing: { before: 50, after: 50 },
        children: [new TextRun({ text: t, size: 20, font: 'Microsoft YaHei', color: '333333' })] })],
    })),
  }));
  return new Table({ width: { size: 11400, type: WidthType.DXA }, columnWidths: colWidths, rows: [hdr, ...body] });
}

// ===== 封面 =====
function cover() {
  return [
    empty(), empty(), empty(), empty(), empty(),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 150 },
      children: [new TextRun({ text: 'Java后端实习', size: 56, bold: true, font: 'Microsoft YaHei', color: BLUE })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new TextRun({ text: '12月投递冲刺计划', size: 56, bold: true, font: 'Microsoft YaHei', color: BLUE })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 120 },
      border: { top: { style: BorderStyle.SINGLE, size: 2, color: BLUE, space: 10 }, bottom: { style: BorderStyle.SINGLE, size: 2, color: BLUE, space: 10 } },
      children: [new TextRun({ text: '2026年8月14日 — 2026年12月 · 目标：拿到寒假实习Offer', size: 26, font: 'Microsoft YaHei', color: GREY })] }),
    empty(), empty(),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 },
      children: [new TextRun({ text: '当前进度：Java基础已过 · LeetCode 16题 · 待学：MySQL / Redis / Spring Boot / 项目', size: 22, font: 'Microsoft YaHei', color: '666666', italics: true })] }),
    empty(), empty(), empty(), empty(), empty(), empty(),
    new Paragraph({ alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: '制定日期：2026年8月14日', size: 22, font: 'Microsoft YaHei', color: '999999' })] }),
  ];
}

// ===== 进度盘点表 =====
function progressTable() {
  const headers = ['模块', '状态', '说明'];
  const rows = [
    ['Java 基础（集合/泛型/反射/IO）', '✅ 已完成', '面试够用，无需再深入'],
    ['多线程', '🟡 进行中', '还剩 volatile / CAS / 线程池 / AQS'],
    ['JVM', '❌ 未开始', '内存结构、垃圾回收、类加载'],
    ['MySQL', '❌ 未开始', '最高优先级，10天'],
    ['Redis', '❌ 未开始', '高优先级，7天'],
    ['Spring Boot', '❌ 未开始', '高优先级，10天'],
    ['计算机网络', '❌ 未开始', '中优先级，5天'],
    ['操作系统', '⏭️ 跳过', '实习生权重低，时间不够'],
    ['项目实战', '❌ 未开始', '命根子，最晚9月中启动'],
    ['LeetCode', '🟡 16题', '目标累计100题'],
  ];
  return makeTable(headers, rows, [3400, 1800, 6200], [2]);
}

// ===== 冲刺路线表 =====
function roadmapTable() {
  const headers = ['阶段', '时间', '核心任务', 'LeetCode累计'];
  const rows = [
    ['核心技能攻坚', '8月中 - 9月中\n(4周)', '多线程收尾 + JVM(1周)\nMySQL + Redis(2周)\nSpring Boot + MyBatis-Plus(1周)', '60题'],
    ['项目 + 计算机基础', '9月中 - 10月底\n(6周)', '第一个完整项目\n计算机网络穿插学\n第二个项目或完善', '100题'],
    ['简历 + 八股文', '11月\n(4周)', '打磨项目、写简历\n刷JavaGuide八股文\n项目部署云服务器', '保持手感'],
    ['投递 + 面试', '12月\n(4周)', '海投简历、笔试\n模拟面试、复盘', '按公司标签刷'],
  ];
  return makeTable(headers, rows, [2400, 2200, 4600, 2200], [2]);
}

// ===== 周计划 =====
function week(no, dates, theme, tasks) {
  return [
    h3('第 ' + no + ' 周（' + dates + '）—— ' + theme),
    ...tasks.map(bullet),
    empty(),
  ];
}

const doc = new Document({
  styles: { default: { document: { run: { size: 22, font: 'Microsoft YaHei' } } } },
  sections: [
    { properties: { page: { margin: pageMargins } }, children: [ ...cover(), pageBreak(), h('目录'), new TableOfContents(), pageBreak() ] },
    {
      properties: { page: { margin: pageMargins } },
      children: [
        h('一、当前进度盘点'),
        empty(),
        para('截至 2026年8月14日，Java 基础已经过完，多线程正在进行中。当前最大缺口是 MySQL、Redis、Spring Boot 三大核心，以及最重要的——项目。'),
        empty(), progressTable(), empty(),

        h('二、冲刺路线总览'),
        empty(),
        para('距离12月投递还有约 3 个半月。砍掉低权重内容（操作系统），聚焦 MySQL / Redis / Spring Boot + 项目。'),
        empty(), roadmapTable(), empty(),
        bullet('操作系统跳过，时间花在刀刃上'),
        bullet('多线程和 JVM 不再往深钻，够面试用即可'),
        bullet('最晚 9 月 15 日必须启动第一个项目'),
        pageBreak(),

        // ===== 第一阶段 =====
        h('三、第一阶段：核心技能攻坚（8月中 — 9月中）'),
        empty(),

        week(1, '8.14 - 8.20', '多线程收尾 + JVM', [
          'volatile 可见性与禁止指令重排、CAS 原理与 ABA 问题',
          '线程池 ThreadPoolExecutor 7 大参数、拒绝策略、执行流程',
          'JVM 内存结构（堆/栈/方法区/程序计数器）、垃圾回收算法',
          '常见 GC 收集器（Serial/Parallel/CMS/G1）、类加载双亲委派',
          'LeetCode 每日 1-2 题，目标累计 25 题',
        ]),
        week(2, '8.21 - 8.27', 'MySQL 系统学（上）', [
          'SQL 语句：DDL/DML/DQL、JOIN、GROUP BY、子查询',
          '索引原理：B+ 树、聚簇索引 vs 非聚簇索引、最左前缀',
          'EXPLAIN 分析执行计划、慢查询优化',
          'LeetCode 每日 1-2 题，目标累计 35 题',
        ]),
        week(3, '8.28 - 9.3', 'MySQL 系统学（下）', [
          '事务 ACID、四种隔离级别、MVCC 原理',
          '锁机制（行锁/表锁/间隙锁）、死锁排查',
          '分库分表入门、主从复制、读写分离概念',
          'LeetCode 每日 1-2 题，目标累计 45 题',
        ]),
        week(4, '9.4 - 9.13', 'Redis + Spring Boot 入门', [
          'Redis 五种数据结构及使用场景',
          '缓存穿透/击穿/雪崩、持久化 RDB/AOF、分布式锁',
          'Spring IOC/DI、AOP、Spring Boot 自动配置原理',
          'MyBatis-Plus 集成 CRUD、分页、条件构造器',
          'LeetCode 每日 1-2 题，目标累计 60 题',
        ]),
        pageBreak(),

        // ===== 第二阶段 =====
        h('四、第二阶段：项目 + 计算机基础（9月中 — 10月底）'),
        empty(),
        week(5, '9.14 - 9.20', '项目一启动：博客系统', [
          '功能：用户注册登录(JWT)、文章CRUD、分类标签、评论、分页搜索',
          '技术栈：Spring Boot + MyBatis-Plus + MySQL + Redis',
          '用 Redis 缓存热门文章，练习分布式锁',
          '计算机网络：OSI/TCP-IP、三次握手四次挥手',
        ]),
        week(6, '9.21 - 9.27', '项目一收尾 + 部署', [
          '完善博客系统：全局异常处理、参数校验、统一响应',
          '部署到云服务器（阿里云/腾讯云学生机）+ Docker',
          '计算机网络：HTTP/HTTPS、TLS 握手、DNS',
        ]),
        week(7, '9.28 - 10.11', '项目二：秒杀系统', [
          '功能：商品列表、秒杀下单、订单异步处理',
          '技术栈：Spring Boot + Redis + RabbitMQ + MySQL',
          '核心：Redis 预减库存防超卖、消息队列削峰',
          '计算机网络：TCP 拥塞控制、HTTP2',
        ]),
        week(8, '10.12 - 10.25', '项目二收尾 + 计算机基础', [
          '秒杀系统：限流、压测、README 架构图',
          '操作系统核心：进程线程、死锁、内存管理、IO多路复用',
          'LeetCode 目标累计 100 题',
        ]),
        pageBreak(),

        // ===== 第三阶段 =====
        h('五、第三阶段：简历 + 八股文（11月）'),
        empty(),
        week(9, '11.1 - 11.7', '简历打磨', [
          'STAR 法则写项目经历：背景/技术选型/职责/难点/量化成果',
          '准备 1 分钟和 3 分钟自我介绍',
          '整理"为什么选 Java 后端"回答思路',
        ]),
        week(10, '11.8 - 11.14', '八股文系统刷（一）', [
          'Java 核心：集合、多线程、JVM（JavaGuide 每天 20 条）',
          'MySQL：索引、事务、MVCC、SQL 优化场景题',
        ]),
        week(11, '11.15 - 11.21', '八股文系统刷（二）', [
          'Redis：数据结构、缓存三大问题、分布式锁、集群',
          '框架：Spring IOC/AOP、自动配置、Spring MVC 流程',
        ]),
        week(12, '11.22 - 11.30', '八股文系统刷（三）+ 模拟面试', [
          '计网：TCP/UDP、HTTP/HTTPS、DNS',
          '场景设计：秒杀系统、短链、排行榜',
          '牛客网刷面经、模拟面试',
        ]),
        pageBreak(),

        // ===== 第四阶段 =====
        h('六、第四阶段：投递 + 面试（12月）'),
        empty(),
        week(13, '12.1 - 12.15', '海投简历', [
          'Boss直聘、拉勾、实习僧、牛客网同步投递',
          '每天至少投 5 家，跟进进度',
          'LeetCode 按公司标签刷（字节/美团/阿里高频）',
        ]),
        week(14, '12.16 - 12.31', '面试实战', [
          '每场面试后立即复盘，记录题目和薄弱点',
          '针对薄弱环节当天突击补充',
          '收到 Offer 后对比：技术栈、团队、转正机会',
        ]),
        pageBreak(),

        // ===== 资源 =====
        h('七、核心资源'),
        empty(),
        h2('书籍'),
        bullet('《深入理解Java虚拟机》—— JVM 面试必备'),
        bullet('《高性能MySQL》—— 索引和事务章节'),
        bullet('《Redis设计与实现》—— 底层原理'),
        h2('在线'),
        bullet('JavaGuide（javaguide.cn）—— 八股文大全'),
        bullet('LeetCode —— 算法刷题'),
        bullet('牛客网 —— 面经、笔试、内推'),
        bullet('小林 Coding —— 计网图解'),
        h2('项目'),
        bullet('博客系统（自研，简历项目首选）'),
        bullet('秒杀系统（参考 JavaGuide 秒杀系列）'),
      ],
    },
  ],
});

const out = 'C:\\Users\\ASUS\\Desktop\\java\\Java后端12月投递冲刺计划.docx';
Packer.toBuffer(doc).then(buf => { fs.writeFileSync(out, buf); console.log('DONE'); }).catch(e => { console.error(e); process.exit(1); });
