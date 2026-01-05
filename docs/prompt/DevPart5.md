### 世界系统实现Prompt

#### 1. 实现内容详细分析描述

世界系统作为游戏的核心架构之一，主要负责构建游戏的三界（现实世界、心理空间、记忆领域）结构，实现玩家在不同维度间的无缝切换，并通过区域解锁和事件触发机制创造动态的游戏体验。系统采用模块化设计，由三个核心子系统组成：

- __三界管理器 (WorldLayerManager)__：负责管理三界的显示层级和切换逻辑。通过CanvasLayer或Scene节点实现不同世界的渲染隔离，使用Portal节点作为切换触发器。Portal可以设计为Area2D碰撞体，当玩家角色进入时触发信号，调用WorldLayerManager的切换方法。切换过程中可添加淡入淡出动画或过渡效果，增强视觉连贯性。需要考虑世界间的状态同步，如玩家的位置、携带物品和心理状态在切换时保持一致。

- __区域解锁系统 (AreaUnlockSystem)__：实现基于条件的区域渐进解锁。每个区域设置能量阈值条件（如收集一定量的心理能量），达到阈值后自动解锁新场景。解锁时可触发奖励发放机制，如给予额外资源或解锁新NPC。该系统可与心理系统集成，将区域解锁与玩家的心理健康状态关联，提升游戏深度。区域数据应支持扩展，包括解锁动画、区域主题音乐和环境特效。

- __事件触发系统 (EventTriggerSystem)__：创建动态事件生态，使用WeightedTable类管理事件概率权重。城市事件通过EventEmitter节点触发，可包括随机遭遇、氛围变化或剧情推进。系统支持事件链式触发，允许一个事件触发后续相关事件，形成更丰富的叙事体验。事件应分类为即时事件（立即执行）和延迟事件（定时触发），并支持条件过滤（如基于玩家位置或心理状态）。

系统集成方面，氛围指数作为全局变量动态影响事件概率权重分布，高氛围指数可能增加正面事件，低氛围指数则提升负面事件概率。心理空间作为特殊世界，可根据角色当前心理状态动态生成内容，如反映焦虑的扭曲环境或平静时的和谐场景。遗漏点补充：需要实现世界间的资源共享机制，如现实世界的物品可在心理空间使用，但有消耗惩罚。

#### 2. 相关实现细节补充

- __三界管理器实现细节__：

  - 使用ViewportContainer实现多世界渲染，每个世界独立渲染避免冲突。
  - Portal节点继承Area2D，添加export变量配置目标世界ID和切换条件。
  - 切换逻辑：保存当前世界状态，加载目标世界场景，应用玩家位置偏移，播放过渡动画。
  - 性能优化：非活跃世界可暂停更新，仅保留活跃世界的物理和逻辑处理。
  - 补充：实现世界边界检测，防止玩家意外走出世界范围；添加世界间传送门网络，支持非线性探索。
  - __新增场景文件__：scenes/world/WorldLayerManager.tscn - 根节点为Node2D，添加子节点ViewportContainer用于渲染不同世界层级。包含多个CanvasLayer子节点，每个代表一个世界（现实、心理、记忆）。添加AnimationPlayer用于世界切换过渡动画。连接到WorldLayerManager.gd脚本处理逻辑。
  - __新增脚本文件__：scripts/world/WorldLayerManager.gd - 继承Node，管理世界切换逻辑。定义枚举WORLD_TYPE枚举世界类型。实现switch_world(target_world: int)方法，处理场景加载和玩家位置同步。使用信号world_switched连接到UI更新。包含世界状态保存/加载方法。
  - __新增场景文件__：scenes/world/Portal.tscn - 根节点为Area2D，添加CollisionShape2D定义触发区域。添加Sprite2D显示传送门视觉效果。连接到Portal.gd脚本处理进入事件和切换信号发射。
  - __新增脚本文件__：scripts/world/Portal.gd - 继承Area2D，处理传送门逻辑。export变量配置目标世界和切换条件。信号body_entered连接到切换方法，验证条件后发射portal_activated信号给WorldLayerManager。

- __区域解锁系统实现细节__：

  - 区域数据使用Resource类存储，包含解锁条件、场景路径和奖励配置。
  - 条件检查通过信号连接到能量收集事件，实时监控进度。
  - 解锁动画：区域图标从锁定状态渐变到解锁，使用Tween节点实现平滑过渡。
  - 奖励发放：支持多种奖励类型，包括资源、物品或成就解锁。
  - 补充：实现区域难度曲线，随着解锁区域增加，解锁条件逐渐复杂化；添加区域预览功能，在解锁前显示区域截图或描述。
  - __新增脚本文件__：scripts/world/AreaUnlockSystem.gd - 继承Node，管理区域解锁。使用字典存储区域数据（AreaData资源）。实现check_unlock_conditions()方法监控能量阈值。解锁时调用reward_system发放奖励，并发射area_unlocked信号触发UI通知。

- __事件触发系统实现细节__：

  - WeightedTable实现使用字典存储事件ID和权重，随机选择时计算累积概率。
  - EventEmitter继承Node2D，可配置触发区域、事件类型和冷却时间。
  - 事件数据结构：包含事件描述、效果函数和后续事件链。
  - 动态权重调整：基于氛围指数和玩家行为历史实时更新权重表。
  - 补充：实现事件日志系统，记录玩家经历的事件用于回放或成就系统；添加事件优先级队列，确保高优先级事件优先触发。
  - __新增脚本文件__：scripts/world/EventTriggerSystem.gd - 继承Node，管理事件触发。包含WeightedTable实例管理概率。实现trigger_event(position: Vector2)方法在指定位置生成事件。支持事件链通过信号event_completed连接后续事件。
  - __新增脚本文件__：scripts/world/WeightedTable.gd - 工具类，实现权重随机选择。构造函数接受权重字典。提供select_random()方法返回选中项ID，使用累积概率算法确保权重准确。
  - __新增脚本文件__：scripts/world/EventEmitter.gd - 继承Node2D，事件发射器。export变量配置事件类型、触发半径和冷却时间。使用Timer实现冷却，Area2D检测玩家进入时触发事件。

- __集成细节补充__：

  - 与心理系统的绑定：心理参数影响世界渲染，如高焦虑时添加视觉滤镜（模糊、扭曲）。
  - 数据持久化：世界状态保存到SaveSystem，包括解锁进度和当前世界位置。
  - 性能考虑：事件系统使用对象池模式复用EventEmitter实例，避免频繁创建销毁。
  - 补充：实现跨世界通信机制，如现实世界的NPC可在心理空间投影出现；添加世界主题系统，每个世界有独特的视觉风格和BGM。
  - __新增脚本文件__：scripts/world/WorldData.gd - Resource类，存储世界相关数据。包含数组worlds存储世界配置，字典areas存储区域状态。支持序列化用于存档系统。

#### 3. 待实现UI补充说明

世界系统涉及多个UI元素需要实现：

- __世界切换UI__：在Portal附近显示切换提示按钮，使用Control节点实现半透明悬浮面板，显示目标世界名称和切换确认按钮。动画效果：按钮随玩家接近逐渐显示。
- __区域解锁通知UI__：解锁时刻弹出Toast通知，使用Panel节点实现，显示解锁区域名称、奖励列表和庆祝动画。支持点击查看区域详情。
- __事件提示UI__：事件触发时显示悬浮文本或图标，使用Label节点结合Tween动画实现从屏幕边缘滑入的效果。支持多事件同时显示的队列管理。
- __世界地图UI__：可选的全屏地图界面，显示三界布局和区域连接关系，使用GraphNode或自定义节点绘制拓扑图。玩家当前位置高亮显示，解锁区域可点击跳转。

这些UI应遵循游戏的拟物化设计风格，使用渐变和阴影增强视觉层次。补充：实现UI主题同步，根据当前世界自动调整颜色方案和字体样式；添加无障碍支持，如屏幕阅读器兼容性。

#### 4. Git管理操作

世界系统实现涉及的文件添加和提交：

- git add scenes/world/WorldLayerManager.tscn scripts/world/WorldLayerManager.gd scenes/world/Portal.tscn scripts/world/Portal.gd scripts/world/AreaUnlockSystem.gd scripts/world/EventTriggerSystem.gd scripts/world/WeightedTable.gd scripts/world/EventEmitter.gd scripts/world/WorldData.gd
- git commit -m "Implement world system with three-layer architecture

- Add WorldLayerManager for multi-layer world switching with scene management
- Implement AreaUnlockSystem for progressive area unlocking with rewards
- Create EventTriggerSystem with weighted probability events
- Add Portal mechanics for seamless transitions
- Include supporting data structures including WeightedTable, EventEmitter, and WorldData resources for cross-world integration"
