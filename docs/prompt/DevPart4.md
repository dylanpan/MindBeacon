### 角色系统实现详细分析

#### 总体架构设计

角色系统作为游戏的核心玩法模块，需要实现：

- NPC的动态生成和管理
- 玩家治愈角色的交互机制
- 角色数据的持久化存储
- 与心理系统的参数联动

系统采用Godot的节点树结构设计，核心节点为单例模式的`NPCManager`，管理所有角色实例。角色数据通过自定义`Resource`类实现序列化，支持热重载。

#### 子系统详细实现

##### 1. NPC管理器 (NPCManager)

__核心实现：__

- 继承`Node2D`，作为游戏世界的子节点
- 维护一个`Pool`字典，键为区域ID，值为NPC节点数组
- 使用`_ready()`预加载NPC场景模板（`.tscn`文件）
- 实现`spawn_npc(region_id: String, position: Vector2)`方法，基于区域动态实例化NPC

__动态生成逻辑：__

- 区域触发器（`Area2D`）检测玩家进入时，调用NPCManager生成NPC
- NPC类型基于区域心理氛围随机选择（正面/负面NPC）
- 销毁机制：离开区域后延迟移除，防止频繁创建销毁开销

__AI实现 - BehaviorTree（使用Godot内置节点）：__

- __树结构设计__：每个NPC根节点下挂载`BehaviorTreeRoot`（自定义Node），管理行为评估

- __复合节点__：

  - `BTSelector`（选择器）：继承`Node`，按优先级执行子节点，直到成功
  - `BTSequence`（序列）：继承`Node`，按顺序执行所有子节点
  - `BTDecorator`（装饰器）：继承`Node`，修改子节点结果（如Invert成功/失败）

- __叶子节点__：

  - `BTCondition`（条件）：检查状态，如`IsPlayerNear()`、`IsMoodLow()`
  - `BTAction`（行动）：执行行为，如`MoveToPlayer()`、`PlayIdleAnim()`

- __评估机制__：使用`_process(delta)`每帧或定时（0.5秒）评估树，从根节点向下遍历

- __具体树结构__：

  ```javascript
  BehaviorTreeRoot
  ├── BTSelector (主选择器)
  │   ├── BTSequence (交互序列)
  │   │   ├── BTCondition (玩家接近 && 心理健康 > 50%)
  │   │   └── BTAction (显示对话气泡)
  │   ├── BTSequence (逃离序列)
  │   │   ├── BTCondition (氛围指数 < 30% 或 负面情绪高)
  │   │   └── BTAction (远离玩家移动)
  │   └── BTAction (随机闲逛)
  ```

- __错误处理__：节点执行失败时返回`BTStatus.FAILED`，树回退到默认Idle行动

- __调试支持__：添加`BTDebugger`节点，可视化树执行状态（开发阶段使用，发布时移除）

- __性能监控__：集成Godot Profiler，监控评估耗时；超过阈值时降低评估频率

- __AI平衡__：添加随机性参数（如条件阈值±10%波动），避免行为可预测

- __行为树扩展__：预留`load_subtree()`接口，支持动态加载子树（如根据NPC类型加载模块）

__补充实现细节：__

- NPC视觉表现：`AnimatedSprite2D`播放行走/待机动画
- 碰撞检测：`CollisionShape2D`圆形，用于玩家交互范围
- 性能优化：最大NPC数量限制为50个，超出时优先移除远处NPC；行为树评估使用协程避免阻塞
- __测试覆盖__：为BT节点编写单元测试，确保条件和行动逻辑正确

##### 2. 治愈系统 (HealingSystem)

__核心实现：__

- 继承`Node`，作为NPC的子组件
- 维护`healing_progress: float`变量（0-1）
- 实现`start_healing(method: String)`方法，启动治愈流程

__治愈方法选择：__

- 方法类型：`Talk`（对话治愈）、`Music`（音乐疗愈）、`Activity`（活动引导）
- 各方法速度倍率：Talk=1.0, Music=1.5, Activity=2.0
- 使用`Timer`节点模拟治愈进度，间隔0.5秒更新

__UI实现：__

- 进度条：`ProgressBar`节点，绑定`healing_progress`值
- 方法选择：`VBoxContainer`布局的`Button`组，每个按钮连接`start_healing`信号
- 位置：作为`CanvasLayer`覆盖在NPC上方，玩家靠近时显示
- __可访问性__：添加键盘导航（Tab键切换按钮），符合无障碍设计

__反馈机制：__

- 粒子效果：`GPUParticles2D`节点，治愈成功时播放心形粒子
- 音效：调用`AudioManager`播放治愈音效
- 视觉反馈：进度条颜色渐变（红色→绿色），成功时屏幕闪光

__补充实现细节：__

- 中断机制：玩家移动远离NPC时自动停止，进度重置
- 成功判定：进度达到100%时触发`healed`信号，修改心理参数
- 失败惩罚：多次失败增加NPC负面情绪，影响后续交互

##### 3. 角色数据模型 (CharacterData)

__核心实现：__

- 继承`Resource`，文件扩展名为`.tres`

- 属性结构：

  ```gdscript
  @export var name: String
  @export var level: int = 1
  @export var health: float = 100.0
  @export var personality: Personality  # 引用心理系统Personality类
  @export var accessories: Array[Accessory]  # 职业特征列表
  ```

__Accessory子节点实现：__

- 自定义`Accessory`类继承`Node2D`
- 类型：`Visual`（视觉效果，如光环）、`Modifier`（属性加成，如治愈速度+20%）
- 动态附加：使用`add_child()`在NPC实例化时添加

__数据持久化：__

- 通过`SaveSystem`序列化到JSON
- 加载时重建Accessory节点树

__补充实现细节：__

- 属性计算：使用getter方法动态计算（如总治愈效率 = 基础 + 所有Accessory加成）
- 升级系统：经验值积累，达到阈值时level+1，解锁新Accessory

#### 系统集成细节

- __与心理系统绑定：__

  - NPC实例化时，从`PsychologyModel`获取区域心理参数初始化personality
  - 治愈过程：`healed`信号触发，调用`PsychologyModel.update_health(heal_amount)`
  - 参数影响：personality的MBTI类型决定行为树条件权重（如I型更倾向于Music治愈相关行动）

- __事件联动：__

  - 治愈成功触发`EventBus.emit("npc_healed", npc_data)`
  - 影响城市氛围指数和事件概率

#### UI实现补充说明

- __治愈UI界面：__

  - 场景文件：`scenes/ui/HealingUI.tscn`
  - 布局：`Control`根节点，包含进度条、按钮组和粒子发射器
  - 动画：`AnimationPlayer`控制UI淡入淡出
  - 主题：使用`Theme`资源统一按钮样式

- __NPC交互提示：__

  - 悬浮UI：`Label`显示NPC状态（如"需要治愈"）
  - 显示条件：玩家进入NPC碰撞区域时激活

#### Git版本管理操作

- __初始实现：__

  - 创建功能分支：`git checkout -b feature/character-system`
  - 提交核心脚本：`git add scripts/characters/ && git commit -m "Implement NPCManager and CharacterData"`

- __UI开发：__

  - 新建分支：`git checkout -b feature/healing-ui`
  - 提交场景和脚本：`git add scenes/ui/HealingUI.tscn scripts/ui/HealingSystem.gd && git commit -m "Add healing UI components"`

- __集成测试：__

  - 合并分支：`git checkout main && git merge feature/character-system feature/healing-ui`
  - 冲突解决：若有Resource引用冲突，手动编辑.tres文件
  - 标签发布：`git tag v0.3-character-system`

- __持续维护：__

  - 平衡调整：创建hotfix分支修改Accessory参数
  - 代码审查：推送到GitHub后创建PR，确保与其他系统（如心理系统）兼容

#### 文档更新

- 在`docs/tech/`目录添加`BehaviorTree-Design.md`，详细说明树结构、节点职责和扩展接口
