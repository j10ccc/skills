# Fix Patterns Index

基于 WeJH-Taro 全仓库 321 条 fix commit 分析提炼的前端薄弱模式库。
每个模式含定义、触发条件、真实 commit 引证、自检清单和修复模板。

持续监控：每日 23:00 Hermes cron job 自动扫描 j10ccc 新合入的 PR，
命中既有薄弱模式时自动追加具体例子到对应文件。

| 模式 | 文件 | Commit 数 | 占比 | 一句话定义 |
|------|------|-----------|------|-----------|
| UI/样式架构缺陷 | [weak-ui-style.md](weak-ui-style.md) | 101 | 31.5% | CSS 隔离缺失、z-index 冲突、深色模式未同步 |
| 业务逻辑盲区 | [weak-logic-bug.md](weak-logic-bug.md) | 89 | 27.7% | 边界输入未处理、浮点精度丢失、key 重复 |
| 类型守卫与空指针 | [weak-type-null.md](weak-type-null.md) | 34 | 10.6% | 类型定义不当、null/undefined 未守卫、不当断言 |

---

*数据来源：zjutjh/WeJH-Taro 全仓库 fix commit 审计（2023-08 至 2026-05）*
*持续追加：Hermes cron job `daily-pr-fix-pattern-review`（ID: e10817b586fb）*
