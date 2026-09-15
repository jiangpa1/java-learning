在日常 Java / MyBatis 开发中，最常用的 MySQL 语句主要分为四大部分：**库表操作、增删改查（CRUD）、常用高级查询、事务操作**。

这里为你整理了一份最实用、开发高频使用的 MySQL 语句速查清单：

---

### 一、 数据库与数据表操作（DDL）

在写代码前，通常需要先在数据库建库建表：

#### 1. 库操作
```sql
-- 创建数据库（指定 utf8mb4 字符集，支持存储 Emoji 表情）
CREATE DATABASE IF NOT EXISTS my_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- 使用/切换数据库
USE my_db;

-- 查看所有数据库
SHOW DATABASES;
```

#### 2. 表操作（建表推荐模板）
结合前面你的 MyBatis 项目，一个标准的业务表（如 `user` 表）通常这样建：
```sql
-- 创建用户表
CREATE TABLE IF NOT EXISTS `sys_user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(100) NOT NULL COMMENT '密码',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
    `status` TINYINT DEFAULT 1 COMMENT '状态：1-正常 0-禁用',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`) -- 唯一索引，防止用户名重复
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 查看表结构
DESC sys_user;

-- 修改表：新增一列
ALTER TABLE sys_user ADD COLUMN email VARCHAR(100) DEFAULT NULL COMMENT '邮箱';

-- 删除表
DROP TABLE IF EXISTS sys_user;
```

---

### 二、 核心增删改查（CRUD）

这是你在 MyBatis 的 `Mapper.xml` 或接口中最常写的 SQL：

#### 1. 新增（INSERT）
```sql
-- 插入单条数据
INSERT INTO sys_user (username, password, phone) 
VALUES ('zhangsan', '123456', '13800000000');

-- 批量插入多条（性能比单条多次插入高）
INSERT INTO sys_user (username, password, phone) VALUES 
('lisi', '123456', '13800000001'),
('wangwu', '123456', '13800000002');
```

#### 2. 删除（DELETE）
```sql
-- 根据 ID 删除（千万别漏掉 WHERE，否则会清空全表！）
DELETE FROM sys_user WHERE id = 1;

-- 批量删除
DELETE FROM sys_user WHERE id IN (2, 3, 4);
```

#### 3. 修改（UPDATE）
```sql
-- 修改某个用户的手机号和状态
UPDATE sys_user 
SET phone = '13999999999', status = 0 
WHERE id = 1;
```

#### 4. 查询（SELECT）
```sql
-- 查询全表（生产环境尽量不要写 SELECT *）
SELECT id, username, phone, status FROM sys_user;

-- 条件查询
SELECT * FROM sys_user WHERE status = 1 AND phone IS NOT NULL;
```

---

### 三、 高频业务查询操作（重点）

#### 1. 分页查询（`LIMIT`）—— Web 开发必备
MySQL 分页语法为：`LIMIT 偏移量, 查询条数`
* 公式：`LIMIT (pageNum - 1) * pageSize, pageSize`
```sql
-- 第 1 页，每页查 10 条
SELECT * FROM sys_user LIMIT 0, 10;

-- 第 2 页，每页查 10 条
SELECT * FROM sys_user LIMIT 10, 10;
```

#### 2. 模糊查询（`LIKE`）
```sql
-- 包含 "zhang" 的用户名（两边都加 % 走不了索引）
SELECT * FROM sys_user WHERE username LIKE '%zhang%';

-- 以 "138" 开头的手机号（右模糊，可以命中索引）
SELECT * FROM sys_user WHERE phone LIKE '138%';
```

#### 3. 排序（`ORDER BY`）
```sql
-- 按创建时间倒序排（DESC：倒序/从大到小；ASC：正序/从小到大）
SELECT * FROM sys_user ORDER BY create_time DESC;
```

#### 4. 聚合与分组（`GROUP BY`、`HAVING`）
```sql
-- 统计各状态的用户数量
SELECT status, COUNT(*) AS total_count 
FROM sys_user 
GROUP BY status;

-- 统计状态数量，且只保留总数大于 5 的分组
SELECT status, COUNT(*) AS total_count 
FROM sys_user 
GROUP BY status 
HAVING total_count > 5;
```

#### 5. 多表关联查询（`JOIN`）
假设还有一张用户详情表 `user_info`：
```sql
-- 左连接（LEFT JOIN）：以左表为主，即便右表没匹配到也显示左表数据
SELECT u.id, u.username, i.real_name, i.address
FROM sys_user u
LEFT JOIN user_info i ON u.id = i.user_id
WHERE u.status = 1;
```

---

### 四、 事务操作（控制数据一致性）

在测试多步操作时很有用（对应 Spring 中的 `@Transactional` 注解底层）：

```sql
START TRANSACTION; -- 1. 开启事务

-- 2. 执行一系列 SQL
UPDATE sys_user SET status = 0 WHERE id = 1;
UPDATE user_account SET balance = balance - 100 WHERE user_id = 1;

COMMIT;   -- 3. 成功则提交（持久化到磁盘）
-- ROLLBACK; -- 4. 如果出错则回滚（撤销刚才的所有操作）
```

---

### 💡 开发小贴士：
1. **防止误删**：执行 `UPDATE` 或 `DELETE` 之前，可以先写 `SELECT ... WHERE ...` 查一下条件对不对，确认无误再改成更新/删除语句。
2. **字段名关键字避坑**：建表时，如果字段名叫 `order`、`status`、`desc` 等 SQL 关键字，字段名两边记得加反引号（\`），例如： `` `order` ``。