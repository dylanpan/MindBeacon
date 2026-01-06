### UI系统统一管理架构完整方案

基于Godot游戏开发的最佳实践，以下是完整的BaseUI + UIManager解决方案，用于统一管理项目中的所有UI组件。

#### 1. BaseUI.gd - 基础UI类

```gdscript
# scripts/ui/BaseUI.gd
class_name BaseUI
extends Control

# 信号定义
signal ui_shown
signal ui_hidden
signal ui_data_updated(data: Dictionary)

# 导出属性
@export var auto_hide_on_escape: bool = true
@export var use_fade_animation: bool = true
@export var animation_duration: float = 0.3
@export var ui_theme: Theme

# 内部状态
var _is_visible: bool = false
var _animation_player: AnimationPlayer
var _tween: Tween
var _ui_data: Dictionary = {}

func _ready():
    _setup_base_ui()
    _connect_signals()
    _apply_theme()
    _initialize()

func _setup_base_ui():
    """设置基础UI组件"""
    # 创建动画播放器
    _animation_player = AnimationPlayer.new()
    _animation_player.name = "AnimationPlayer"
    add_child(_animation_player)
    
    # 创建默认动画
    if use_fade_animation:
        _create_fade_animations()

func _create_fade_animations():
    """创建淡入淡出动画"""
    # Fade in动画
    var fade_in = Animation.new()
    fade_in.length = animation_duration
    fade_in.add_track(Animation.TYPE_VALUE)
    fade_in.track_set_path(0, "modulate:a")
    fade_in.track_insert_key(0, 0.0, 0.0)
    fade_in.track_insert_key(0, animation_duration, 1.0)
    _animation_player.add_animation("fade_in", fade_in)
    
    # Fade out动画
    var fade_out = Animation.new()
    fade_out.length = animation_duration
    fade_out.add_track(Animation.TYPE_VALUE)
    fade_out.track_set_path(0, "modulate:a")
    fade_out.track_insert_key(0, 0.0, 1.0)
    fade_out.track_insert_key(0, animation_duration, 0.0)
    _animation_player.add_animation("fade_out", fade_out)

func _connect_signals():
    """连接基础信号"""
    if auto_hide_on_escape:
        # ESC键处理将在_input中实现
        set_process_input(true)

func _apply_theme():
    """应用主题"""
    if ui_theme:
        theme = ui_theme
    elif UIManager.instance and UIManager.instance.default_theme:
        theme = UIManager.instance.default_theme

func _input(event):
    """处理输入事件"""
    if auto_hide_on_escape and event.is_action_pressed("ui_cancel") and _is_visible:
        hide_ui()
        get_viewport().set_input_as_handled()

# 虚方法 - 子类重写
func _initialize():
    """子类特定初始化"""
    pass

func show_ui():
    """显示UI"""
    if not _is_visible:
        _is_visible = true
        visible = true
        modulate.a = 0.0  # 确保从透明开始
        
        if use_fade_animation and _animation_player.has_animation("fade_in"):
            _animation_player.play("fade_in")
        else:
            modulate.a = 1.0
        
        emit_signal("ui_shown")

func hide_ui():
    """隐藏UI"""
    if _is_visible:
        _is_visible = false
        
        if use_fade_animation and _animation_player.has_animation("fade_out"):
            _animation_player.play("fade_out")
            await _animation_player.animation_finished
        
        visible = false
        emit_signal("ui_hidden")

func update_data(data: Dictionary):
    """更新UI数据"""
    _ui_data.merge(data, true)
    _on_data_updated(data)
    emit_signal("ui_data_updated", data)

func _on_data_updated(data: Dictionary):
    """子类重写此方法处理数据更新"""
    pass

# 工具方法
func play_ui_sound(sound_name: String):
    """播放UI音效"""
    if UIManager.instance:
        UIManager.instance.play_sound(sound_name)

func show_tooltip(text: String, position: Vector2 = Vector2.ZERO):
    """显示提示"""
    if UIManager.instance:
        UIManager.instance.show_tooltip(text, position)

func request_focus_safe():
    """安全请求焦点"""
    if is_inside_tree() and visible and has_focus():
        grab_focus()

# 属性访问器
func is_ui_visible() -> bool:
    return _is_visible

func get_ui_data() -> Dictionary:
    return _ui_data.duplicate()
```

#### 2. UIManager.gd - UI管理器

```gdscript
# scripts/ui/UIManager.gd
class_name UIManager
extends CanvasLayer

# 单例实例
static var instance: UIManager

# UI类型枚举
enum UIType {
    MAIN,
    PSYCHOLOGY_FILE,
    EMOTION_SPECTRUM,
    HEALING,
    OFFLINE_PROGRESS,
    DEBUG_PANEL
}

# UI场景资源
@export var ui_scenes: Dictionary = {
    UIType.MAIN: preload("res://scenes/ui/MainUI.tscn"),
    UIType.PSYCHOLOGY_FILE: preload("res://scenes/ui/PsychologyFileUI.tscn"),
    UIType.EMOTION_SPECTRUM: preload("res://scenes/ui/EmotionSpectrumMenu.tscn"),
    UIType.HEALING: preload("res://scenes/ui/HealingUI.tscn"),
    UIType.OFFLINE_PROGRESS: preload("res://scenes/ui/OfflineProgressUI.tscn"),
    UIType.DEBUG_PANEL: preload("res://scenes/ui/DebugPsychologyPanel.tscn")
}

# UI管理
@export var default_theme: Theme
@export var enable_sound_effects: bool = true
@export var enable_tooltips: bool = true

# 内部状态
var active_uis: Dictionary = {}  # UIType -> BaseUI实例
var ui_stack: Array[UIType] = []  # UI堆栈（模态管理）
var persistent_uis: Array[UIType] = [UIType.MAIN]  # 常驻UI
var ui_z_index: int = 0  # Z轴层级管理

# 信号
signal ui_shown(ui_type: UIType, ui_instance: BaseUI)
signal ui_hidden(ui_type: UIType)
signal ui_stack_changed

func _ready():
    instance = self
    _initialize_persistent_uis()
    _connect_game_events()

func _initialize_persistent_uis():
    """初始化常驻UI"""
    for ui_type in persistent_uis:
        show_ui(ui_type)

func _connect_game_events():
    """连接游戏事件"""
    if GameManager.instance:
        GameManager.instance.connect("game_state_changed", _on_game_state_changed)
    
    if EventBus.instance:
        EventBus.instance.connect("show_ui_request", _on_show_ui_request)
        EventBus.instance.connect("hide_ui_request", _on_hide_ui_request)
        EventBus.instance.connect("toggle_ui_request", _on_toggle_ui_request)

func show_ui(ui_type: UIType, data: Dictionary = {}, modal: bool = false) -> BaseUI:
    """显示UI"""
    if active_uis.has(ui_type):
        # UI已存在，更新数据并显示
        var existing_ui = active_uis[ui_type]
        existing_ui.update_data(data)
        if not existing_ui.is_ui_visible():
            existing_ui.show_ui()
        return existing_ui
    
    # 创建新UI实例
    if not ui_scenes.has(ui_type):
        push_error("UI scene not found for type: ", UIType.keys()[ui_type])
        return null
    
    var ui_scene = ui_scenes[ui_type]
    var ui_instance = ui_scene.instantiate()
    
    if not ui_instance is BaseUI:
        push_error("UI instance must inherit from BaseUI: ", ui_instance.name)
        ui_instance.queue_free()
        return null
    
    # 添加到场景树
    add_child(ui_instance)
    active_uis[ui_type] = ui_instance
    
    # 设置层级
    ui_instance.z_index = ui_z_index
    ui_z_index += 1
    
    # 连接信号
    ui_instance.connect("ui_shown", _on_ui_shown.bind(ui_type))
    ui_instance.connect("ui_hidden", _on_ui_hidden.bind(ui_type))
    
    # 初始化数据
    ui_instance.update_data(data)
    
    # 显示UI
    ui_instance.show_ui()
    
    # 播放音效
    if enable_sound_effects:
        play_sound("ui_show")
    
    # 管理模态堆栈
    if modal and not ui_type in persistent_uis:
        ui_stack.append(ui_type)
        emit_signal("ui_stack_changed")
    
    emit_signal("ui_shown", ui_type, ui_instance)
    return ui_instance

func hide_ui(ui_type: UIType):
    """隐藏UI"""
    if not active_uis.has(ui_type):
        return
    
    var ui_instance = active_uis[ui_type]
    ui_instance.hide_ui()
    
    # 播放音效
    if enable_sound_effects:
        play_sound("ui_hide")
    
    # 从堆栈移除
    if ui_type in ui_stack:
        ui_stack.erase(ui_type)
        emit_signal("ui_stack_changed")

func hide_all_modal_uis():
    """隐藏所有模态UI"""
    var modal_stack = ui_stack.duplicate()
    for ui_type in modal_stack:
        hide_ui(ui_type)

func toggle_ui(ui_type: UIType, data: Dictionary = {}):
    """切换UI显示状态"""
    if is_ui_visible(ui_type):
        hide_ui(ui_type)
    else:
        show_ui(ui_type, data)

func is_ui_visible(ui_type: UIType) -> bool:
    """检查UI是否可见"""
    return active_uis.has(ui_type) and active_uis[ui_type].is_ui_visible()

func get_ui(ui_type: UIType) -> BaseUI:
    """获取UI实例"""
    return active_uis.get(ui_type)

# 便捷方法
func show_main_ui():
    show_ui(UIType.MAIN)

func show_psychology_file(data: Dictionary = {}):
    show_ui(UIType.PSYCHOLOGY_FILE, data, true)

func show_emotion_spectrum(data: Dictionary = {}):
    show_ui(UIType.EMOTION_SPECTRUM, data, true)

func show_healing_ui(npc_data: Dictionary):
    var data = {
        "npc": npc_data.get("npc"),
        "healing_system": npc_data.get("healing_system")
    }
    show_ui(UIType.HEALING, data, true)

func show_offline_progress(data: Dictionary = {}):
    show_ui(UIType.OFFLINE_PROGRESS, data, true)

func show_debug_panel():
    show_ui(UIType.DEBUG_PANEL, {}, true)

# 工具方法
func play_sound(sound_name: String):
    """播放UI音效"""
    if AudioManager.instance and AudioManager.instance.has_method("play_ui_sound"):
        AudioManager.instance.play_ui_sound(sound_name)

func show_tooltip(text: String, position: Vector2):
    """显示提示信息"""
    if enable_tooltips:
        # 实现提示显示逻辑
        pass

# 事件处理
func _on_game_state_changed(new_state: String):
    """游戏状态变化处理"""
    match new_state:
        "playing":
            show_main_ui()
        "paused":
            hide_all_modal_uis()
        "menu":
            hide_all_modal_uis()
        "game_over":
            hide_all_modal_uis()

func _on_show_ui_request(ui_name: String, data: Dictionary = {}):
    """UI显示请求"""
    var ui_type = _string_to_ui_type(ui_name)
    if ui_type != null:
        show_ui(ui_type, data)

func _on_hide_ui_request(ui_name: String):
    """UI隐藏请求"""
    var ui_type = _string_to_ui_type(ui_name)
    if ui_type != null:
        hide_ui(ui_type)

func _on_toggle_ui_request(ui_name: String, data: Dictionary = {}):
    """UI切换请求"""
    var ui_type = _string_to_ui_type(ui_name)
    if ui_type != null:
        toggle_ui(ui_type, data)

func _on_ui_shown(ui_type: UIType):
    """UI显示回调"""
    pass

func _on_ui_hidden(ui_type: UIType):
    """UI隐藏回调"""
    # 清理非持久UI实例
    if not ui_type in persistent_uis and active_uis.has(ui_type):
        var ui_instance = active_uis[ui_type]
        ui_instance.queue_free()
        active_uis.erase(ui_type)

func _string_to_ui_type(ui_name: String) -> UIType:
    """字符串转UI类型"""
    match ui_name.to_lower():
        "main", "main_ui": return UIType.MAIN
        "psychology_file", "profile", "psychology": return UIType.PSYCHOLOGY_FILE
        "emotion_spectrum", "emotions", "emotion": return UIType.EMOTION_SPECTRUM
        "healing", "heal": return UIType.HEALING
        "offline_progress", "offline": return UIType.OFFLINE_PROGRESS
        "debug", "debug_panel": return UIType.DEBUG_PANEL
        _: 
            push_warning("Unknown UI type: ", ui_name)
            return -1

# 输入处理
func _input(event):
    """全局输入处理"""
    if event.is_action_pressed("ui_cancel") and ui_stack.size() > 0:
        # ESC关闭顶层模态UI
        hide_ui(ui_stack.back())
        get_viewport().set_input_as_handled()
```

#### 3. 现有UI迁移示例

```gdscript
# scripts/ui/MainUI.gd - 迁移后
class_name MainUI
extends BaseUI

@onready var energy_label = $Panel/VBoxContainer/ResourceDisplay/EnergyLabel
@onready var health_bar = $Panel/VBoxContainer/ResourceDisplay/HealthBar
@onready var healing_progress = $Panel/VBoxContainer/HealingProgress

func _initialize():
    """重写初始化方法"""
    _setup_buttons()
    _connect_game_signals()

func _setup_buttons():
    """设置按钮"""
    var quick_actions = $Panel/VBoxContainer/QuickActions
    for button in quick_actions.get_children():
        button.connect("pressed", _on_quick_action_pressed.bind(button.name))

func _connect_game_signals():
    """连接游戏信号"""
    if GameManager.instance:
        GameManager.instance.connect("data_updated", _update_display)

func _on_data_updated(data: Dictionary):
    """数据更新处理"""
    if data.has("mental_energy"):
        energy_label.text = "Mental Energy: %d" % data["mental_energy"]
    if data.has("psychology_health"):
        health_bar.value = data["psychology_health"]
    if data.has("healing_progress"):
        healing_progress.value = data["healing_progress"]

func _on_quick_action_pressed(button_name: String):
    """按钮按下处理"""
    match button_name:
        "HealButton":
            if get_node_or_null("/root/HealingSystem"):
                get_node("/root/HealingSystem").start_healing()
        "SaveButton":
            if get_node_or_null("/root/SaveSystem"):
                get_node("/root/SaveSystem").manual_save()
        "ProfileButton":
            UIManager.instance.show_psychology_file()
```

#### 4. 项目集成

__在主场景中添加UIManager：__

- 在`scenes/main/Main.tscn`中添加CanvasLayer节点
- 附加`UIManager.gd`脚本
- 设置默认主题

__在GameManager中集成：__

```gdscript
func _ready():
    # ... 现有代码 ...
    UIManager.instance.show_main_ui()
```

__使用示例：__

```gdscript
# 显示心理档案
UIManager.instance.show_psychology_file({"player_data": player_data})

# 显示情绪菜单
UIManager.instance.show_emotion_spectrum({"emotions": available_emotions})

# 事件驱动
EventBus.instance.emit_signal("show_ui_request", "emotion_spectrum", data)
```
#### 5. 额外高级功能实现说明

1. 本地化支持

# BaseUI.gd 中添加
func _apply_localization():
    # 遍历所有Label/Button节点应用本地化
    pass

func set_locale(locale: String):
    # 切换语言
    pass

2. 性能优化

# UIManager.gd 中添加
var ui_pool: Dictionary = {}  # UI对象池
var max_pool_size: int = 5

func get_pooled_ui(ui_type: UIType) -> BaseUI:
    # 从池中获取或创建UI实例
    pass

3. 状态保存恢复

# BaseUI.gd 中添加
func save_ui_state() -> Dictionary:
    return {
        "visible": _is_visible,
        "data": _ui_data,
        "position": position
    }

func restore_ui_state(state: Dictionary):
    # 恢复UI状态
    pass

4. 高级动画效果

# BaseUI.gd 中添加
@export var transition_type: String = "fade"  # fade, slide, scale
func _create_advanced_animations():
    # 实现多种过渡效果
    pass

5. 调试和监控

# UIManager.gd 中添加
func _debug_ui_status():
    print("Active UIs: ", active_uis.keys())
    print("UI Stack: ", ui_stack)

6. 验证机制

# BaseUI.gd 中添加
func validate_data(data: Dictionary) -> bool:
    # 验证传入数据格式
    return true

#### 6. 方案优势总结

1. __统一架构__：所有UI继承BaseUI，保证一致行为
2. __集中管理__：UIManager统一处理UI生命周期
3. __模态支持__：UI堆栈管理，支持ESC关闭
4. __事件驱动__：通过EventBus响应游戏事件
5. __数据流__：标准化的数据传递机制
6. __资源管理__：自动清理临时UI实例
7. __扩展性__：添加新UI只需继承BaseUI并注册到UIManager
8. __维护性__：修改通用功能只需改BaseUI/UIManager
9. __调试友好__：便于跟踪UI状态和性能
