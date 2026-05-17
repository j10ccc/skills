# 业务逻辑盲区

> 边界输入未处理、浮点精度丢失、key 重复、数据流不完整等业务逻辑遗漏

## 触发条件

- 新功能涉及数值计算（特别是浮点运算）
- 使用 `v-for`/`map` 渲染列表但 key 生成逻辑可能重复
- API 返回值可能为空数组/null/undefined
- 功能模块涉及状态切换或多步骤流程
- 日期/时间格式化与展示

## 真实 Commit 引证

| # | Commit | 说明 |
|---|--------|------|
| 1 | [9cc0789](https://github.com/zjutjh/WeJH-Taro/commit/9cc07895a8d32c8c439592ab753e23bd22860508) | fix(score): 修复浮点数加法导致绩点值出错 |
| 2 | [6bd1134](https://github.com/zjutjh/WeJH-Taro/commit/6bd113411cce523f32dd1dae5dc99ddcf7ce3f15) | fix(lessonTable): 某天上下午有同一节课, v-for中key会一样导致问题 |
| 3 | [646af91](https://github.com/zjutjh/WeJH-Taro/commit/646af9196aff81a25f83da2149b243e56e25f25a) | fix: 消费记录保留两位小数 |

本项目共 89 条业务逻辑 Bug + 数据展示 fix commit（占 27.7%），为第二大修复类别。

## 自检清单

- [ ] 浮点运算是否使用 `toFixed()` 或整数化后计算？
- [ ] `v-for`/`map` 的 key 是否保证唯一（日期+节次+课程ID 等组合 key）？
- [ ] API 返回空值/null/undefined 是否有兜底展示（非空白区域）？
- [ ] 边界输入（零值/空数组/极值）是否逐一测试？
- [ ] 多步骤流程是否有"上一步未完成就进入下一步"的防护？

## 修复模板

```typescript
// 1. 浮点精度
const gpa = +(totalPoints / totalCredits).toFixed(2);

// 2. 唯一 key 生成
const lessonKey = `${day}-${period}-${course.id}`;

// 3. 空值兜底
const displayName = data?.name ?? '暂无数据';

// 4. 边界守卫
const items = Array.isArray(data) ? data : [];
const first = items[0] ?? defaultItem;
```
