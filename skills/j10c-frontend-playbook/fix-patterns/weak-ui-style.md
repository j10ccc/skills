# UI/样式架构缺陷

> CSS 隔离缺失、z-index 冲突、深色模式未同步、样式穿透等视觉层面反复修复的问题

## 触发条件

- 新增页面/组件涉及深色模式适配
- 使用了全局 CSS 或未采用 CSS Modules 隔离
- 设置了硬编码 z-index 值
- 修改主题色/主题系统相关代码
- Taro 组件样式穿透（`styleIsolation` 配置）

## 真实 Commit 引证

| # | Commit | 说明 |
|---|--------|------|
| 1 | [9da5cb8](https://github.com/zjutjh/WeJH-Taro/commit/9da5cb81719ea2e589662ddf0bb16b2935184e2b) | fix(lessonstable): 统一了深色，亮色模式，统一了css modules |
| 2 | [2d375bb](https://github.com/zjutjh/WeJH-Taro/commit/2d375bb9d03fea5caecd08f02c110ae55c56a1a9) | fix(lessonstable): 修复了边框毛玻璃层高显示与课表和时间线冲突的问题 |
| 3 | [27cbe9d](https://github.com/zjutjh/WeJH-Taro/commit/27cbe9d2d0f9729112d07a6364a418a3981dc7a4) | fix(nav-bar): style isolation |

本项目共 101 条 UI/样式 fix commit（占 31.5%），为最高频修复类别。

## 自检清单

- [ ] 新组件是否使用 CSS Modules（`*.module.scss`）隔离样式？
- [ ] 深色模式下所有颜色是否已同步定义（CSS 变量或 `@media (prefers-color-scheme: dark)`）？
- [ ] z-index 是否遵循项目约定层级，而非随意赋值？
- [ ] Taro 组件是否配置了 `styleIsolation: 'apply-shared'` 或 `'isolated'`？
- [ ] 主题色变更是否覆盖了所有使用该色的组件？

## 修复模板

```scss
// 1. 使用 CSS Modules 隔离
// index.module.scss
.container { /* scoped styles */ }

// 2. CSS 变量适配深色模式
.card {
  background: var(--wjh-color-bg-card);
}

@media (prefers-color-scheme: dark) {
  :root {
    --wjh-color-bg-card: #1a1a1a;
  }
}

// 3. z-index 约定
// < 100:  内容层级
// 100-200: 弹层/浮层
// 200+:   模态/全局
```
