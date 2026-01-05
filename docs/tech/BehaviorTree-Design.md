# BehaviorTree Design Document

## 概述
本项目采用自定义BehaviorTree（行为树）系统实现NPC AI，避免使用第三方插件以保持代码可控性和性能优化。BehaviorTree基于组合模式设计，支持复合节点（Selector、Sequence、Decorator）和叶子节点（Condition、Action）。

## 架构设计

### 核心节点类型

#### BTNode (基础节点)
- **继承**: Node
- **属性**:
  - `status: BTStatus` - 当前执行状态 (RUNNING/SUCCESS/FAILED)
- **方法**:
  - `tick(delta: float) -> BTStatus` - 执行节点逻辑
  - `reset()` - 重置节点状态

#### 复合节点

##### BTSelector (选择器)
- **逻辑**: 按优先级执行子节点，第一个返回SUCCESS或RUNNING的子节点决定结果
- **用途**: 实现"或"逻辑，如尝试多个行动之一

##### BTSequence (序列)
- **逻辑**: 按顺序执行所有子节点，所有子节点成功才返回SUCCESS
- **用途**: 实现"与"逻辑，如完成一系列步骤

##### BTDecorator (装饰器)
- **逻辑**: 修改单个子节点的结果，支持反转（Invert）等操作
- **用途**: 条件反转、重复执行等

#### 叶子节点

##### BTCondition (条件)
- **逻辑**: 检查游戏状态，返回SUCCESS或FAILED
- **用途**: 状态验证，如玩家接近检查

##### BTAction (行动)
- **逻辑**: 执行具体行为，可能需要多帧完成
- **用途**: 移动、播放动画等

### BehaviorTreeRoot (树根)
- **继承**: BTNode
- **功能**:
  - 管理树执行周期
  - 支持子树动态加载
  - 调试模式开关
- **配置**:
  - `tick_rate: float` - 执行频率（默认0.5秒）
  - `enable_debug: bool` - 启用调试输出

## 示例树结构

```
BehaviorTreeRoot
├── BTSelector (主选择器)
│   ├── BTSequence (交互序列)
│   │   ├── BTCondition (IsPlayerNear)
│   │   │   └── check_condition() -> 检查玩家距离
│   │   └── BTAction (ShowDialogue)
│   │       └── execute_action() -> 显示对话气泡
│   ├── BTSequence (逃离序列)
│   │   ├── BTCondition (IsMoodLow)
│   │   │   └── check_condition() -> 检查氛围指数
│   │   └── BTAction (FleeFromPlayer)
│   │       └── execute_action() -> 远离玩家移动
│   └── BTAction (IdleWander)
│       └── execute_action() -> 随机闲逛
```

## 执行流程

1. **初始化**: BehaviorTreeRoot在_process中定时调用tick_tree()
2. **遍历**: 从根节点向下递归执行tick()
3. **状态传播**: 子节点状态向上返回给父节点
4. **决策**: 基于节点类型和子状态确定结果

## 性能优化

- **执行频率**: 可配置tick_rate，避免每帧执行
- **协程支持**: 复杂行动可使用协程分帧执行
- **缓存优化**: 条件检查结果可缓存减少重复计算
- **调试开关**: 生产环境关闭调试输出

## 扩展机制

### 子树加载
- `load_subtree(path: String)` 方法支持动态加载行为子树
- 适用于不同NPC类型使用不同行为模式

### 自定义节点
- 继承相应基类实现自定义Condition和Action
- 示例: IsPlayerNearCondition, MoveToPlayerAction

### 参数化
- 节点可通过export变量参数化
- 支持随机性注入避免行为可预测

## 调试支持

### BTDebugger
- 可视化树结构和执行状态
- 实时状态更新
- 开发阶段工具，发布时移除

### 日志输出
- enable_debug开启时输出执行日志
- 便于问题排查和行为调优

## 集成要点

- **与心理系统**: 条件节点可检查MBTI类型和情绪状态
- **与治愈系统**: 行动节点可触发治愈流程
- **与事件系统**: 树执行结果可影响城市氛围指数

## 最佳实践

1. **树深度**: 保持树深度合理，避免过深递归
2. **节点复用**: 设计通用节点减少重复代码
3. **状态管理**: 正确处理RUNNING状态的持续执行
4. **测试覆盖**: 为关键节点编写单元测试
5. **性能监控**: 定期检查树执行耗时

## 未来扩展

- **黑板系统**: 全局状态共享
- **动态权重**: 运行时调整节点优先级
- **学习机制**: 基于玩家行为调整树结构
