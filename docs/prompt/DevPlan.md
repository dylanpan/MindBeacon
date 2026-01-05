## 项目结构规划Prompt

__目标：__ 搭建完整的Godot项目目录结构和配置文件。

__实现步骤：__

1. 创建project.godot文件，配置Godot 4.6项目设置
2. 建立assets/目录结构：sprites/, audio/, fonts/, ui/
3. 建立scenes/目录：main/, characters/, environments/, ui/
4. 建立scripts/目录：core/, characters/, gameplay/, ui/
5. 建立data/目录：configs/, saves/
6. 添加docs/目录用于文档

__技术要点：__ 使用Godot的Project Settings配置输入映射和物理设置。

## 1. 核心游戏系统实现Prompt

__子系统：__

- __游戏管理器 (GameManager)__：实现状态机管理游戏流程，使用StateMachine节点处理主菜单→游戏中→暂停状态切换。集成场景切换和全局事件总线（使用Signal系统）。
- __存档系统 (SaveSystem)__：使用ConfigFile类实现本地加密存储，结合AES加密。实现每15分钟自动保存，使用Timer节点。
- __离线收益系统 (OfflineProgressSystem)__：计算离线时间，应用分形算法：收益 = 基础收益 * pow(离线时间, 0.7) * 建筑效率。防止收益过高。

__集成：__ GameManager作为单例管理其他子系统。

## 2. 心理系统实现Prompt

__子系统：__

- __心理状态模型 (PsychologyModel)__：创建Personality类，包含MBTI（E/I, S/N, T/F, J/P）和Big5（开放性、尽责性、外向性、宜人性、神经质）参数。实现复合算法计算心理健康值。
- __城市氛围指数 (CityMoodIndex)__：全局变量，影响事件概率。区域心理状态通过Area2D检测。
- __心理能量系统 (MentalEnergySystem)__：能量收集器节点，类型区分（正面/负面），转化机制影响治愈。

__集成：__ 心理参数影响NPC行为和环境渲染。

## 3. 角色系统实现Prompt

__子系统：__

- __NPC管理器 (NPCManager)__：使用Node2D管理NPC池，动态生成基于区域。AI使用BehaviorTree或简单状态机。
- __治愈系统 (HealingSystem)__：进度条UI，方法选择影响治愈速度，反馈通过粒子效果。
- __角色数据模型 (CharacterData)__：Resource类存储属性，职业特征通过Accessory子节点实现。

__集成：__ 与心理系统绑定，治愈过程修改参数。

## 4. 世界系统实现Prompt

__子系统：__

- __三界管理器 (WorldLayerManager)__：使用CanvasLayer或Scene切换实现三界。Portal节点触发切换。
- __区域解锁系统 (AreaUnlockSystem)__：条件检查（能量阈值），解锁后添加场景，发放奖励。
- __事件触发系统 (EventTriggerSystem)__：概率云使用WeightedTable类，城市事件通过EventEmitter节点。

__集成：__ 氛围指数影响事件概率，心理空间反映角色状态。

## 5. UI系统实现Prompt

__子系统：__

- __主界面 (MainUI)__：Control节点显示资源，使用Label和ProgressBar。快捷操作通过Button信号。
- __心理档案界面 (PsychologyFileUI)__：ScrollContainer实现拟物化档案，图表显示心理数据。
- __情绪光谱菜单 (EmotionSpectrumMenu)__：自定义RadialMenu节点，动画展开情绪选项。

__集成：__ 绑定到游戏数据，实时更新显示。

## 6. 音频系统实现Prompt

__子系统：__

- __音乐分层系统 (LayeredMusicSystem)__：多个AudioStreamPlayer分层播放，使用AudioBus混合。动态调整基于心理状态。
- __交互音效管理 (SFXManager)__：预加载音效池，使用AudioStreamPlayer2D播放位置音效。

__集成：__ 与事件系统联动，治愈时刻生成个性化音乐。

## 7. 扩展玩法系统实现Prompt（暂不实现）

__保留以备将来：__ 记忆拼图、装修系统、心灵图鉴的框架设计。
