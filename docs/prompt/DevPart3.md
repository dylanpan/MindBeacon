# 心理系统实现指南 (Psychology System Implementation Guide)

## 1. 系统概述

心理系统是一个多层次的子系统架构，包含三个主要组件：心理状态模型、城市氛围指数和心理能量系统。这些组件相互协作，形成了一个动态的心理生态系统，直接影响游戏的叙事、NPC行为和环境表现。

## 2. 系统架构设计

### 核心组件关系图

```javascript
GameManager (单例)
├── Personality (Resource) - 玩家心理状态
├── CityMoodIndex (float) - 全局氛围指数
├── RegionArea[] (Area2D) - 区域氛围管理
├── MentalEnergyOrb[] (Area2D) - 能量收集器
└── EventBus (信号系统) - 组件间通信
```

### 数据流向

1. 玩家心理状态 → 城市氛围指数 → 事件概率
2. 事件触发 → 能量生成 → 治愈系统 → 心理状态更新

## 3. 详细子系统实现

### 3.1 心理状态模型 (PsychologyModel)

#### Personality类设计

继承自Godot的Resource类，便于序列化和资源管理。

```gdscript
class_name Personality
extends Resource

# MBTI参数 (0-1范围)
@export_range(0.0, 1.0) var mbti_e_i: float  # Extraversion/Introversion
@export_range(0.0, 1.0) var mbti_s_n: float  # Sensing/Intuition  
@export_range(0.0, 1.0) var mbti_t_f: float  # Thinking/Feeling
@export_range(0.0, 1.0) var mbti_j_p: float  # Judging/Perceiving

# Big5人格特质 (0-100范围)
@export_range(0, 100) var big5_openness: float       # 开放性
@export_range(0, 100) var big5_conscientiousness: float  # 尽责性
@export_range(0, 100) var big5_extraversion: float   # 外向性
@export_range(0, 100) var big5_agreeableness: float  # 宜人性
@export_range(0, 100) var big5_neuroticism: float    # 神经质

var mental_health: float = 50.0  # 心理健康值 (0-100)

# 信号定义
signal parameter_changed(param_name: String, new_value: float)
signal mental_health_updated(new_value: float)

func _init():
    # 初始化默认值
    initialize_default_values()

func initialize_default_values():
    # 设置平衡的默认人格参数
    mbti_e_i = 0.5
    mbti_s_n = 0.5
    mbti_t_f = 0.5
    mbti_j_p = 0.5
    
    big5_openness = 50
    big5_conscientiousness = 50
    big5_extraversion = 50
    big5_agreeableness = 50
    big5_neuroticism = 50

func calculate_mental_health() -> float:
    # MBTI贡献：计算人格类型一致性得分
    var mbti_score = (mbti_e_i + mbti_s_n + mbti_t_f + mbti_j_p) / 4.0 * 100
    
    # Big5贡献：计算积极特质平均值 (神经质取反)
    var big5_avg = (big5_openness + big5_conscientiousness + 
                   big5_extraversion + big5_agreeableness + 
                   (100 - big5_neuroticism)) / 5.0
    
    # 复合计算：40% MBTI + 60% Big5
    mental_health = mbti_score * 0.4 + big5_avg * 0.6
    
    # 应用环境修正因子
    mental_health *= get_environment_modifier()
    
    mental_health = clamp(mental_health, 0, 100)
    mental_health_updated.emit(mental_health)
    return mental_health

func get_environment_modifier() -> float:
    # 获取当前环境对心理健康的修正因子
    # 例如：心理空间给予正面修正
    var modifier = 1.0
    if GameManager.current_world_layer == WorldLayer.PSYCHOLOGICAL:
        modifier = 1.2  # 心理空间给予20%加成
    return modifier

func update_parameter(param_name: String, delta: float):
    if not has_property(param_name):
        push_error("Invalid parameter: " + param_name)
        return
    
    var current_value = get(param_name)
    var new_value = clamp(current_value + delta, 0, 100 if param_name.begins_with("big5") else 1)
    set(param_name, new_value)
    parameter_changed.emit(param_name, new_value)
    calculate_mental_health()  # 重新计算心理健康值

func get_mbti_type() -> String:
    var type = ""
    type += "E" if mbti_e_i > 0.5 else "I"
    type += "S" if mbti_s_n > 0.5 else "N"
    type += "T" if mbti_t_f > 0.5 else "F"
    type += "J" if mbti_j_p > 0.5 else "P"
    return type
```

#### 实现要点

- 使用`@export_range`装饰器提供编辑器友好的参数调整
- 实现参数验证和边界检查
- 添加人格类型判断函数

### 3.2 城市氛围指数 (CityMoodIndex)

#### 全局变量设计

在GameManager单例中声明全局氛围指数。

```gdscript
# GameManager.gd
var city_mood_index: float = 0.5  # 范围0.0-1.0
var region_areas: Array = []  # 区域列表

signal mood_index_changed(new_value: float)

func update_city_mood_index(new_value: float):
    var old_value = city_mood_index
    city_mood_index = clamp(new_value, 0.0, 1.0)
    
    if abs(city_mood_index - old_value) > 0.01:  # 避免频繁更新
        mood_index_changed.emit(city_mood_index)
        # 触发氛围过渡效果
        apply_mood_transition(old_value, city_mood_index)

func apply_mood_transition(old_value: float, new_value: float):
    var tween = create_tween()
    tween.tween_property(self, "city_mood_index", new_value, 2.0)
    tween.tween_callback(func(): EventBus.emit_signal("mood_transition_complete"))
```

#### RegionArea节点实现

```gdscript
class_name RegionArea
extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var region_mood: float = 0.5
var npc_list: Array = []
var update_timer: Timer

func _ready():
    # 连接信号
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    
    # 设置更新定时器
    update_timer = Timer.new()
    update_timer.wait_time = 5.0  # 每5秒更新一次
    update_timer.timeout.connect(_on_update_timer_timeout)
    add_child(update_timer)
    update_timer.start()
    
    # 注册到GameManager
    GameManager.region_areas.append(self)

func _on_body_entered(body: Node2D):
    if body.is_in_group("player"):
        GameManager.update_city_mood_index(region_mood)
        # 触发区域特效
        play_region_effect()

func _on_body_exited(body: Node2D):
    if body.is_in_group("player"):
        # 可选：离开区域时的处理
        pass

func _on_update_timer_timeout():
    update_region_mood()

func update_region_mood():
    if npc_list.is_empty():
        region_mood = 0.5  # 默认中性氛围
        return
    
    var total_health = 0.0
    for npc in npc_list:
        if npc.has_method("get_personality"):
            total_health += npc.get_personality().mental_health
    
    region_mood = total_health / npc_list.size() / 100.0
    region_mood = clamp(region_mood, 0.0, 1.0)

func add_npc(npc: Node2D):
    if not npc_list.has(npc):
        npc_list.append(npc)

func remove_npc(npc: Node2D):
    npc_list.erase(npc)

func play_region_effect():
    # 播放区域进入音效或视觉效果
    pass
```

#### 技术要点

- 使用Timer定期更新，避免每帧计算
- 实现区域NPC管理，动态计算区域氛围
- 与事件系统集成，氛围影响概率

### 3.3 心理能量系统 (MentalEnergySystem)

#### MentalEnergyOrb类实现

```gdscript
class_name MentalEnergyOrb
extends Area2D

enum EnergyType { POSITIVE, NEGATIVE }

@export var energy_type: EnergyType = EnergyType.POSITIVE
@export var energy_value: float = 10.0
@export var attraction_speed: float = 50.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var decay_timer: Timer = $DecayTimer

var target_player: Node2D = null
var is_attracting: bool = false

func _ready():
    # 设置视觉效果
    setup_visuals()
    
    # 连接信号
    body_entered.connect(_on_body_entered)
    decay_timer.timeout.connect(_on_decay_timeout)
    decay_timer.start(30.0)  # 30秒后开始衰减
    
    # 开始吸引力逻辑
    check_attraction()

func _physics_process(delta: float):
    if is_attracting and target_player:
        var direction = (target_player.global_position - global_position).normalized()
        global_position += direction * attraction_speed * delta

func setup_visuals():
    match energy_type:
        EnergyType.POSITIVE:
            sprite.modulate = Color.GREEN
            particles.modulate = Color.GREEN
            particles.emission_rate = energy_value * 2
        EnergyType.NEGATIVE:
            sprite.modulate = Color.RED
            particles.modulate = Color.RED
            particles.emission_rate = energy_value

func _on_body_entered(body: Node2D):
    if body.is_in_group("player"):
        collect_energy(body)

func collect_energy(player: Node2D):
    match energy_type:
        EnergyType.POSITIVE:
            HealingSystem.add_healing_points(energy_value)
        EnergyType.NEGATIVE:
            handle_negative_energy(energy_value)
    
    # 播放收集效果
    play_collection_effect()
    
    # 通知系统
    EventBus.emit_signal("energy_collected", energy_type, energy_value)
    
    # 销毁节点
    queue_free()

func handle_negative_energy(value: float):
    # 负面能量处理逻辑
    # 例如：临时降低心理健康，或触发特殊事件
    GameManager.player_personality.update_parameter("big5_neuroticism", value * 0.1)

func play_collection_effect():
    # 播放音效和粒子效果
    AudioManager.play_sfx("energy_collect")
    var effect = preload("res://scenes/effects/EnergyCollectEffect.tscn").instantiate()
    effect.global_position = global_position
    get_parent().add_child(effect)

func _on_decay_timeout():
    # 开始衰减动画
    var tween = create_tween()
    tween.tween_property(sprite, "modulate:a", 0.0, 5.0)
    tween.tween_callback(queue_free)

func check_attraction():
    # 检查是否应该吸引玩家
    var player = get_tree().get_first_node_in_group("player")
    if player and global_position.distance_to(player.global_position) < 100:
        target_player = player
        is_attracting = true
```

#### 对象池管理

```gdscript
class_name MentalEnergyPool
extends Node

const POOL_SIZE = 100
var orb_pool: Array = []
var orb_scene = preload("res://scenes/MentalEnergyOrb.tscn")

func _ready():
    initialize_pool()

func initialize_pool():
    for i in POOL_SIZE:
        var orb = orb_scene.instantiate()
        orb.visible = false
        orb_pool.append(orb)
        add_child(orb)

func get_orb() -> MentalEnergyOrb:
    for orb in orb_pool:
        if not orb.visible:
            orb.visible = true
            return orb
    # 如果池已满，创建新实例
    var new_orb = orb_scene.instantiate()
    orb_pool.append(new_orb)
    add_child(new_orb)
    return new_orb

func spawn_energy(position: Vector2, type: MentalEnergyOrb.EnergyType, value: float):
    var orb = get_orb()
    orb.global_position = position
    orb.energy_type = type
    orb.energy_value = value
    orb.setup_visuals()
```

#### 平衡性考虑

- 能量生成率：每分钟5-10个正面能量，2-5个负面能量
- 吸引力范围：100像素内自动吸引
- 衰减时间：30秒后开始消失

## 4. 系统集成与数据流

### 4.1 与NPC系统的集成

```gdscript
# NPCManager.gd
func create_npc(personality_template: Personality = null) -> NPC:
    var npc = npc_scene.instantiate()
    
    # 分配人格
    if personality_template:
        npc.personality = personality_template.duplicate()
    else:
        npc.personality = generate_random_personality()
    
    # 注册到当前区域
    var current_area = get_current_region_area(npc.global_position)
    if current_area:
        current_area.add_npc(npc)
    
    return npc

func generate_random_personality() -> Personality:
    var personality = Personality.new()
    # 随机生成人格参数
    for param in ["mbti_e_i", "mbti_s_n", "mbti_t_f", "mbti_j_p"]:
        personality.set(param, randf())
    for param in ["big5_openness", "big5_conscientiousness", "big5_extraversion", "big5_agreeableness", "big5_neuroticism"]:
        personality.set(param, randi_range(20, 80))
    return personality
```

### 4.2 与环境系统的集成

```gdscript
# WorldLayerManager.gd
func _on_mood_changed(new_mood: float):
    # 调整环境参数
    environment.sky_color = lerp(Color(0.1, 0.1, 0.2), Color(0.5, 0.7, 1.0), new_mood)
    environment.ambient_light_color = lerp(Color(0.3, 0.3, 0.4), Color(0.8, 0.8, 0.9), new_mood)
    
    # 调整音频
    background_music.volume_db = lerp(-20, 0, new_mood)
    
    # 心理空间特效
    if current_layer == WorldLayer.PSYCHOLOGICAL:
        apply_psychological_effects(new_mood)

func apply_psychological_effects(mood: float):
    # 根据心理健康应用视觉扭曲效果
    var distortion_strength = 1.0 - (GameManager.player_personality.mental_health / 100.0)
    psychological_shader.set_shader_parameter("distortion", distortion_strength * mood)
```

### 4.3 数据流设计

```gdscript
# EventBus.gd (信号中继器)
extends Node

signal mood_index_changed(new_value: float)
signal energy_collected(type: int, value: float)
signal personality_updated()
signal region_mood_updated(region_name: String, new_mood: float)

# GameManager.gd 信号连接
func _ready():
    EventBus.mood_index_changed.connect(_on_mood_changed)
    EventBus.energy_collected.connect(_on_energy_collected)
    EventBus.personality_updated.connect(_on_personality_updated)
```

## 5. 实现步骤与代码示例

### 5.1 初始化步骤

1. 在GameManager._ready()中调用initialize_psychology_system()
2. 创建默认人格模板资源文件
3. 设置MentalEnergyPool单例实例

### 5.2 场景设置

1. 在主场景中添加RegionArea节点覆盖游戏区域
2. 配置区域碰撞形状和分组
3. 添加MentalEnergyPool到场景树

### 5.3 UI集成

```gdscript
# PsychologyFileUI.gd
@onready var big5_bars: Dictionary = {
    "openness": $VBoxContainer/OpennessBar,
    "conscientiousness": $VBoxContainer/ConscientiousnessBar,
    "extraversion": $VBoxContainer/ExtraversionBar,
    "agreeableness": $VBoxContainer/AgreeablenessBar,
    "neuroticism": $VBoxContainer/NeuroticismBar
}

func _ready():
    GameManager.player_personality.parameter_changed.connect(_on_parameter_changed)
    update_display()

func _on_parameter_changed(param_name: String, new_value: float):
    if param_name in big5_bars:
        big5_bars[param_name].value = new_value

func update_display():
    for param_name in big5_bars:
        var value = GameManager.player_personality.get(param_name)
        big5_bars[param_name].value = value
    
    $MBTITypeLabel.text = GameManager.player_personality.get_mbti_type()
    $MentalHealthLabel.text = "%.1f" % GameManager.player_personality.mental_health
```

## 6. 测试与调试

### 6.1 调试工具

```gdscript
# DebugPsychology.gd
func _input(event):
    if event.is_action_pressed("debug_psychology"):
        show_debug_menu()

func show_debug_menu():
    var debug_panel = preload("res://scenes/ui/DebugPsychologyPanel.tscn").instantiate()
    add_child(debug_panel)

# DebugPsychologyPanel.gd
func _on_randomize_personality_pressed():
    for param in ["mbti_e_i", "mbti_s_n", "mbti_t_f", "mbti_j_p"]:
        GameManager.player_personality.set(param, randf())
    for param in ["big5_openness", "big5_conscientiousness", "big5_extraversion", "big5_agreeableness", "big5_neuroticism"]:
        GameManager.player_personality.set(param, randi_range(0, 100))
    GameManager.player_personality.calculate_mental_health()

func _on_force_mood_pressed():
    GameManager.update_city_mood_index(0.8)  # 强制高氛围
```

### 6.2 性能监控

- 使用Godot的Profiler监控系统更新频率
- 添加帧率显示和内存使用统计
- 实现区域更新频率的可调参数

## 7. 平衡调整指南

### 7.1 算法权重调参

- MBTI权重建议：0.3-0.5
- Big5权重建议：0.5-0.7
- 环境修正因子：0.8-1.5

### 7.2 事件概率平衡

- 氛围对事件概率的影响：0.2-2.0倍率
- 负面事件触发阈值：氛围指数 < 0.3
- 正面事件奖励倍率：氛围指数 > 0.7

### 7.3 能量系统平衡

- 正面能量生成率：每分钟5-10个
- 负面能量生成率：每分钟2-5个
- 能量价值范围：5-50点
- 吸引力范围：50-200像素

## 8. 待创建的场景文件

### 1. MentalEnergyOrb.tscn

__位置__: scenes/gameplay/MentalEnergyOrb.tscn __节点结构__:

```javascript
MentalEnergyOrb (Area2D)
├── CollisionShape2D
├── Sprite2D (能量精灵)
├── GPUParticles2D (粒子效果)
└── Timer (衰减定时器)
```

### 2. RegionArea.tscn

__位置__: scenes/gameplay/RegionArea.tscn __节点结构__:

```javascript
RegionArea (Area2D)
├── CollisionShape2D (区域碰撞形状)
└── Timer (区域更新定时器)
```

### 3. PsychologyFileUI.tscn

__位置__: scenes/ui/PsychologyFileUI.tscn\
__节点结构__:

```javascript
PsychologyFileUI (Control)
└── VBoxContainer
    ├── ProgressBar (Openness)
    ├── ProgressBar (Conscientiousness)  
    ├── ProgressBar (Extraversion)
    ├── ProgressBar (Agreeableness)
    ├── ProgressBar (Neuroticism)
    ├── Label (MBTI Type)
    └── Label (Mental Health)
```

### 4. DebugPsychologyPanel.tscn

__位置__: scenes/ui/DebugPsychologyPanel.tscn __节点结构__:

```javascript
DebugPsychologyPanel (Panel)
└── VBoxContainer
    ├── Button (随机人格)
    ├── Button (高氛围模式)
    ├── Label (状态显示)
    └── Button (关闭)
```

## 创建步骤

1. __MentalEnergyOrb场景__:

   - 创建Area2D作为根节点
   - 添加CollisionShape2D（圆形碰撞）
   - 添加Sprite2D用于视觉显示
   - 添加GPUParticles2D用于粒子效果
   - 添加Timer用于衰减计时

2. __RegionArea场景__:

   - 创建Area2D作为根节点
   - 添加CollisionShape2D（矩形碰撞）
   - 添加Timer用于定期更新

3. __UI场景__:

   - 使用Godot的UI节点创建相应的界面布局
   - 设置适当的主题和样式

4. __默认人格资源__:

   - 创建data/configs/default_personality.tres资源文件

## 9. Git版本控制说明

### Act模式实现步骤

在切换到Act模式后，按照以下步骤进行心理系统的实现：

#### 步骤1: 创建基础脚本文件

```bash
# 创建Personality资源脚本
git add scripts/core/Personality.gd
git commit -m "Add Personality resource class for psychology system"

# 创建RegionArea节点脚本  
git add scripts/gameplay/RegionArea.gd
git commit -m "Add RegionArea node for city mood management"

# 创建MentalEnergyOrb节点脚本
git add scripts/gameplay/MentalEnergyOrb.gd
git commit -m "Add MentalEnergyOrb node for energy collection system"
```

#### 步骤2: 集成到GameManager

```bash
# 更新GameManager添加心理系统变量和方法
git add scripts/core/GameManager.gd
git commit -m "Integrate psychology system into GameManager singleton"
```

#### 步骤3: 创建场景和资源

```bash
# 创建MentalEnergyOrb场景
git add scenes/gameplay/MentalEnergyOrb.tscn
git commit -m "Create MentalEnergyOrb scene with visual effects"

# 创建RegionArea场景
git add scenes/gameplay/RegionArea.tscn
git commit -m "Create RegionArea scene template"

# 创建默认人格模板资源
git add data/configs/default_personality.tres
git commit -m "Add default personality template resource"
```

#### 步骤4: UI系统实现

```bash
# 实现PsychologyFileUI
git add scripts/ui/PsychologyFileUI.gd
git add scenes/ui/PsychologyFileUI.tscn
git commit -m "Implement psychology profile UI with parameter display"
```

#### 步骤5: 测试和调试

```bash
# 添加调试工具
git add scripts/utils/DebugPsychology.gd
git add scenes/ui/DebugPsychologyPanel.tscn
git commit -m "Add psychology system debugging tools"

# 运行测试场景验证功能
git commit -m "Test psychology system integration"
```

#### 步骤6: 性能优化和平衡调整

```bash
# 实现对象池和优化
git add scripts/utils/MentalEnergyPool.gd
git commit -m "Add object pooling for energy orbs performance"

# 应用平衡调整
git commit -m "Balance psychology system parameters and event probabilities"
```

#### 步骤7: 文档和注释

```bash
# 更新代码注释和文档
git commit -m "Add comprehensive code documentation and inline comments"

# 最终测试和验证
git commit -m "Final testing and validation of psychology system"
```
