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

# 对象池
var ui_pool: Dictionary = {}  # UIType -> Array[BaseUI]
var max_pool_size: int = 5

# UI状态保存
var saved_ui_states: Dictionary = {}  # UIType -> Dictionary

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

    # 尝试从对象池获取
    var ui_instance = _get_pooled_ui(ui_type)
    if not ui_instance:
        # 创建新UI实例
        if not ui_scenes.has(ui_type):
            push_error("UI scene not found for type: ", UIType.keys()[ui_type])
            return null

        var ui_scene = ui_scenes[ui_type]
        ui_instance = ui_scene.instantiate()

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

    # 保存状态（如果需要）
    if ui_instance.has_method("save_ui_state"):
        saved_ui_states[ui_type] = ui_instance.save_ui_state()

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

# 对象池管理
func _get_pooled_ui(ui_type: UIType) -> BaseUI:
    """从对象池获取UI实例"""
    if ui_pool.has(ui_type) and ui_pool[ui_type].size() > 0:
        var pooled_ui = ui_pool[ui_type].pop_back()
        if is_instance_valid(pooled_ui):
            return pooled_ui
    return null

func _return_to_pool(ui_type: UIType, ui_instance: BaseUI):
    """将UI实例返回对象池"""
    if not ui_pool.has(ui_type):
        ui_pool[ui_type] = []

    if ui_pool[ui_type].size() < max_pool_size:
        # 重置UI状态
        ui_instance.visible = false
        ui_instance.modulate = Color.WHITE
        ui_instance.scale = Vector2.ONE
        ui_instance.position = Vector2.ZERO

        ui_pool[ui_type].append(ui_instance)
    else:
        # 池已满，销毁实例
        ui_instance.queue_free()

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

# 状态保存恢复
func save_all_ui_states() -> Dictionary:
    """保存所有UI状态"""
    var all_states = {}
    for ui_type in active_uis:
        var ui_instance = active_uis[ui_type]
        if ui_instance.has_method("save_ui_state"):
            all_states[ui_type] = ui_instance.save_ui_state()
    return all_states

func restore_all_ui_states(states: Dictionary):
    """恢复所有UI状态"""
    for ui_type in states:
        if active_uis.has(ui_type):
            var ui_instance = active_uis[ui_type]
            if ui_instance.has_method("restore_ui_state"):
                ui_instance.restore_ui_state(states[ui_type])

func save_ui_state(ui_type: UIType) -> Dictionary:
    """保存特定UI状态"""
    if active_uis.has(ui_type):
        var ui_instance = active_uis[ui_type]
        if ui_instance.has_method("save_ui_state"):
            return ui_instance.save_ui_state()
    return {}

func restore_ui_state(ui_type: UIType, state: Dictionary):
    """恢复特定UI状态"""
    if active_uis.has(ui_type):
        var ui_instance = active_uis[ui_type]
        if ui_instance.has_method("restore_ui_state"):
            ui_instance.restore_ui_state(state)

# 工具方法
func play_sound(sound_name: String):
    """播放UI音效"""
    if AudioManager.instance and AudioManager.instance.has_method("play_ui_sound"):
        AudioManager.instance.play_ui_sound(sound_name)

func show_tooltip(text: String, position: Vector2):
    """显示提示信息"""
    if enable_tooltips:
        # 实现提示显示逻辑
        var tooltip = _create_tooltip(text, position)
        if tooltip:
            add_child(tooltip)
            # 延迟隐藏
            get_tree().create_timer(2.0).timeout.connect(func(): tooltip.queue_free())

func _create_tooltip(text: String, position: Vector2) -> Control:
    """创建提示控件"""
    var tooltip = Panel.new()
    tooltip.position = position

    var label = Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tooltip.add_child(label)

    tooltip.size = label.size + Vector2(10, 10)
    return tooltip

# 本地化支持
func set_global_locale(locale: String):
    """设置全局语言"""
    TranslationServer.set_locale(locale)
    # 通知所有活跃UI更新本地化
    for ui_instance in active_uis.values():
        if ui_instance.has_method("set_locale"):
            ui_instance.set_locale(locale)

# 调试和监控
func _debug_ui_status():
    """调试UI状态"""
    print("=== UI Manager Debug Info ===")
    print("Active UIs: ", active_uis.keys())
    print("UI Stack: ", ui_stack)
    print("UI Pool sizes: ", _get_pool_sizes())
    print("Persistent UIs: ", persistent_uis)
    print("Z-Index: ", ui_z_index)

func _get_pool_sizes() -> Dictionary:
    """获取对象池大小"""
    var sizes = {}
    for ui_type in ui_pool:
        sizes[ui_type] = ui_pool[ui_type].size()
    return sizes

func get_ui_stats() -> Dictionary:
    """获取UI统计信息"""
    return {
        "active_count": active_uis.size(),
        "stack_size": ui_stack.size(),
        "pool_sizes": _get_pool_sizes(),
        "persistent_count": persistent_uis.size()
    }

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
    _debug_ui_status()

func _on_ui_hidden(ui_type: UIType):
    """UI隐藏回调"""
    # 清理非持久UI实例或返回对象池
    if not ui_type in persistent_uis and active_uis.has(ui_type):
        var ui_instance = active_uis[ui_type]
        active_uis.erase(ui_type)

        # 返回对象池或销毁
        _return_to_pool(ui_type, ui_instance)

    _debug_ui_status()

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
