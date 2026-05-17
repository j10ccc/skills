# 类型守卫与空指针

> TypeScript 类型定义不当、null/undefined 未守卫、不当类型断言导致的运行时错误

## 触发条件

- 访问 API 返回值的嵌套属性
- 从 Store/Vuex/Pinia 获取状态
- 使用 `as` 类型断言或 `!` 非空断言
- 数组索引访问（`arr[0]`）未判断长度
- 对 `Record<K, V>` 的值做属性访问
- 重构/重命名后修改类型定义

## 真实 Commit 引证

| # | Commit | 说明 |
|---|--------|------|
| 1 | [27a32d4](https://github.com/zjutjh/WeJH-Taro/commit/27a32d4d2baad7fe08850502a9966949cf5c7991) | fix: term-picker default value fits the type defination |
| 2 | [c6ec966](https://github.com/zjutjh/WeJH-Taro/commit/c6ec9665f00f6cc46bfbdc6620ce46b61eeef9e1) | fix(bus): placeholder 取值越界 |
| 3 | [2caeff1](https://github.com/zjutjh/WeJH-Taro/commit/2caeff15c8790a5169c088a524517a057d1d03e5) | fix: 可能的空指针问题，以及预处理 parseFloat |

本项目共 34 条类型错误 + 空指针 + 边界 fix commit（占 10.6%），是代码质量的系统性薄弱点。

## 自检清单

- [ ] 所有 API 返回值是否标注了可能为 `undefined` 的字段？
- [ ] 是否存在 `as X` 或 `!` 非空断言在业务逻辑中？（应替换为类型守卫）
- [ ] 数组索引访问前是否检查了 `.length`？
- [ ] `Record<K, V>` 的值访问是否用了可选链 `?.`？
- [ ] 重构（重命名/移动/拆分）后是否运行了 `pnpm typecheck`？

## 修复模板

```typescript
// 1. 用类型守卫替代 as 断言
function isUser(val: unknown): val is User {
  return typeof val === 'object' && val !== null && 'id' in val;
}

// 2. 可选链 + 空值合并
const name = user?.profile?.name ?? '未知用户';

// 3. 数组安全访问
const first = arr.length > 0 ? arr[0] : undefined;

// 4. 收紧类型定义（而非放宽）
interface ApiResp {
  data: UserInfo | null;  // 明确 null 可能
}

// 5. 重构后必须 typecheck
// pnpm typecheck
```
