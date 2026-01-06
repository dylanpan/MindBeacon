### UI系统实现Prompt

#### 1. 实现内容分析描述

UI系统实现Prompt 定义了游戏的用户界面子系统，主要包含三个核心UI组件：

- __主界面 (MainUI)__：作为游戏的核心显示界面，使用Godot的Control节点作为基础容器。通过Label控件展示游戏资源信息（如心理能量、治愈进度等），ProgressBar用于可视化进度条显示。Button控件实现快捷操作功能，采用信号(Signal)机制处理用户交互事件。

- __心理档案界面 (PsychologyFileUI)__：采用ScrollContainer实现可滚动的拟物化档案界面。界面设计模拟真实档案风格，包含心理数据的图表可视化展示。可能包含MBTI类型分布、Big5人格特质雷达图、心理健康趋势曲线等图表元素。

- __情绪光谱菜单 (EmotionSpectrumMenu)__：自定义RadialMenu节点实现环形菜单。支持动画展开情绪选项（如喜悦、悲伤、愤怒等情绪状态），用户可以通过点击选择影响角色心理状态的选项。

集成方面，所有UI组件都需要绑定到游戏数据系统，实现实时更新显示。通过信号连接机制与GameManager和PsychologyModel进行数据同步。

#### 2. 相关实现细节补充说明

针对每个UI组件的具体实现细节补充如下：

__主界面 (MainUI) 实现细节：__

显示信息内容：

- 心理能量值（Mental Energy）：显示当前收集的心理能量数量
- 心理健康进度条（Psychology Health）：显示角色心理健康状态百分比
- 治愈进度（Healing Progress）：显示当前治愈过程的完成度
- 快捷操作按钮：保存游戏、开始治愈、打开档案等

```gdscript
# MainUI.gd 示例代码结构
extends Control

@onready var energy_label = $EnergyLabel
@onready var health_bar = $HealthProgressBar
@onready var healing_progress = $HealingProgressBar
@onready var quick_action_buttons = $QuickActions.get_children()

func _ready():
    # 连接游戏数据更新信号
    GameManager.connect("data_updated", _update_display)
    HealingSystem.connect("healing_progress_updated", _update_healing_progress)
    _update_display()

func _update_display():
    energy_label.text = "Mental Energy: %d" % GameManager.mental_energy
    health_bar.value = GameManager.psychology_health

func _update_healing_progress(progress: float):
    healing_progress.value = progress

func _on_quick_action_pressed(action_type: String):
    # 处理快捷操作逻辑
    match action_type:
        "heal":
            HealingSystem.start_healing()
        "save":
            SaveSystem.manual_save()
        "open_profile":
            show_psychology_file()
```

__心理档案界面 (PsychologyFileUI) 实现细节：__

显示信息内容：

- Big5人格特质条形图：开放性（Openness）、尽责性（Conscientiousness）、外向性（Extraversion）、宜人性（Agreeableness）、神经质（Neuroticism）- 数值范围0-100
- MBTI类型标签：显示完整的MBTI人格类型字符串（如"ENFJ"）
- 心理健康数值：显示计算后的心理健康分数（浮点数格式）

```gdscript
# PsychologyFileUI.gd 关键方法（基于现有代码）
func update_display():
    if not GameManager.instance or not GameManager.instance.player_personality:
        return

    var personality = GameManager.instance.player_personality

    # 更新Big5参数条（进度条显示0-100范围）
    for param_name in big5_bars:
        var value = personality.get(param_name)
        big5_bars[param_name].value = value

    # 更新MBTI类型显示
    mbti_type_label.text = personality.get_mbti_type()

    # 更新心理健康值显示
    mental_health_label.text = "%.1f" % personality.mental_health
```

__情绪光谱菜单 (EmotionSpectrumMenu) 实现细节：__

显示信息内容：

- 情绪选项环形排列：正面情绪（喜悦、平静、自信）和负面情绪（悲伤、愤怒、焦虑）选项
- 每个情绪选项显示图标和文本标签
- 选中状态高亮显示当前选择的情绪影响

```gdscript
# EmotionSpectrumMenu.gd 核心逻辑
@export var emotion_options: Array[String] = ["joy", "sadness", "anger", "calm", "anxiety", "confidence"]

func show_menu():
    visible = true
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2.ZERO)
    
    # 排列情绪选项
    for i in range(emotion_options.size()):
        var option_button = $OptionContainer.get_child(i)
        var angle = i * (2 * PI / emotion_options.size())
        option_button.position = Vector2(cos(angle), sin(angle)) * radius
        option_button.text = emotion_options[i].capitalize()
    
func _on_option_selected(emotion_type: String):
    emit_signal("emotion_selected", emotion_type)
    # 传递给心理系统应用情绪影响
    PsychologyModel.apply_emotion_impact(emotion_type)
```

#### 3. 待实现UI/场景补充说明

根据项目结构分析，目前已存在部分UI脚本文件，但以下组件可能需要补充实现：

- __MainUI场景__：scenes/ui/MainUI.tscn - 需要创建主界面场景文件，包含所有子控件布局
- __EmotionSpectrumMenu场景__：scenes/ui/EmotionSpectrumMenu.tscn - 自定义径向菜单节点实现
- __UI主题资源__：assets/ui/themes/MainTheme.tres - 统一样式主题文件
- __图标资源__：assets/ui/icons/ 目录下添加情绪图标、快捷操作图标等

待实现的具体内容：

__MainUI.tscn 场景结构：__

- Control根节点
- VBoxContainer垂直布局
- HBoxContainer资源显示栏（能量标签、健康进度条）
- ProgressBar治愈进度条
- GridContainer快捷按钮区域
- Label显示区域解锁状态

__EmotionSpectrumMenu.tscn 实现要点：__

- 中心圆形背景
- 环形排列的Button节点（6个情绪选项）
- 动画控制器(Tween)
- 鼠标悬停高亮效果
- 图标TextureRect子节点

#### 4. Git管理操作说明

针对UI系统实现的相关文件，需要执行以下Git操作：

添加文件操作：

```javascript
git add scenes/ui/MainUI.tscn
git add scenes/ui/EmotionSpectrumMenu.tscn
git add scripts/ui/MainUI.gd
git add scripts/ui/EmotionSpectrumMenu.gd
git add assets/ui/themes/MainTheme.tres
```

提交操作：

```javascript
git commit -m "Implement MainUI subsystem

- Add MainUI scene and script for resource display
- Display mental energy, psychology health, healing progress
- Include quick action buttons for save, heal, profile access"
```

```javascript
git commit -m "Add PsychologyFileUI enhancements

- Implement scrollable archive interface
- Display Big5 personality traits, MBTI type, mental health value
- Integrate with Personality class parameters"
```

```javascript
git commit -m "Create EmotionSpectrumMenu component

- Custom RadialMenu node with emotion options
- Display joy, sadness, anger, calm, anxiety, confidence
- Ring-based layout with tween animations"
```
