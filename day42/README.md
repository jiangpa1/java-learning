# day42 接口回归脚本

2026-09-18 做逻辑删除 / 角色权限 / 限流 / 降级改造时写的接口回归脚本。
**没有单元测试，这些脚本就是当时的验证手段。**

## 使用前：配一个环境变量

脚本里的数据库口令**不硬编码**（避免提交到公开仓库），改为读环境变量：

```powershell
$env:LEARNING_DB_PASS = '你的MySQL口令'        # 当前会话
# 或永久配置（用户作用域）
[Environment]::SetEnvironmentVariable('LEARNING_DB_PASS','你的MySQL口令','User')
```

另外两个前置条件：

- 应用在 `8080` 跑着（脚本通过 HTTP 打接口）
- 脚本里有几个会**自签 JWT** 来构造"已过期/角色不同"的 token，需要读 `JWT_SECRET`（用户作用域的**环境变量**）：

```powershell
[Environment]::SetEnvironmentVariable('JWT_SECRET','至少32字符的密钥','User')
```

## 脚本清单

| 脚本 | 覆盖内容 | 用例数 |
| --- | --- | --- |
| `day42-role-test.ps1` | 角色权限、归属校验、提权、404/403 顺序、refresh 保角色 | 28 |
| `day42-role-crud-test.ps1` | `PUT /user/role`：`@Valid` 校验、最后一个管理员守卫、降级作废凭证 | 21 |
| `day42-cat-perm-test.ps1` | 分类写接口管理员专属 + 读接口不误锁 | 8 |
| `day42-refresh-fix-test.ps1` | refresh 的 JWT 异常处理（含真·已过期 token） | 12 |
| `day42-ratelimit-verify.ps1` | 限流阈值、ZSET 状态、响应头 | 端到端 |
| `day42-ratelimit-order.ps1` | 拦截器顺序：403 请求不消耗限流额度 | 4 |
| `day42-degraded-test.ps1` | **六处 Redis 依赖的降级方向**（需先把 `spring.redis.port` 改成 9999） | 7 |
| `day42-failopen-test.ps1` | 早期 fail-open 探测（已被 degraded 取代，保留作对比） | 5 |
| `day42-final-regression.ps1` | 全功能回归（认证/限流/权限/逻辑删除/缓存/顺序） | 19 |
| `day42-token-degrade-test.ps1` | token 降级路径的早期版本（已被 degraded 取代） | — |
| `day42-redis-keys-probe.ps1` | 纯诊断：Redis key 到底生成了没有 | — |

## 一条值得复用的验证方法

**自签 JWT**：从 `JWT_SECRET` 手工拼 header/payload + HMAC-SHA256 签名，可以构造

- **已过期但签名合法**的 token → 把"过期分支"和"签名错误分支"分开测（只发垃圾串的话两个分支都返 401，测不出区别）
- **指定 role 的 access token** → 不需要真的登录就能测权限分支

这比"发一个垃圾字符串"精确得多。

## 注意事项

- 脚本会**创建并删除**测试账号/文章/分类（结尾有 cleanup），但不保证异常中断时也清理干净 —— 跑之前可以先看一眼 `tb_user` 里的测试账号
- `day42-degraded-test.ps1` 需要**故意把 Redis 指到不可达端口**，跑完记得改回来
- 这些脚本是**当时快照**，改动接口后可能需要同步调整
