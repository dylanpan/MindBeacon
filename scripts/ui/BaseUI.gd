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
@export var transition_type: String = "fade"  # fade, slide, scale

# 内部状态
var _is_visible: bool = false
var _animation_player: AnimationPlayer
var _tween: Tween
var _ui_data: Dictionary = {}
var _saved_state: Dictionary = {}

func _ready():
    _setup_base_ui()
    _connect_signals()
    _apply_theme()
    _apply_localization()
    _initialize()

func _setup_base_ui():
    """设置基础UI组件"""
    # 创建动画播放器
    _animation_player = AnimationPlayer.new()
    _animation_player.name = "AnimationPlayer"
    add_child(_animation_player)

    # 创建默认动画
    if use_fade_animation:
        _create_animations()

func _create_animations():
    """创建动画"""
    if transition_type == "fade":
        _create_fade_animations()
    elif transition_type == "slide":
        _create_slide_animations()
    elif transition_type == "scale":
        _create_scale_animations()

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

func _create_slide_animations():
    """创建滑动动画"""
    var slide_in = Animation.new()
    slide_in.length = animation_duration
    slide_in.add_track(Animation.TYPE_VALUE)
    slide_in.track_set_path(0, "position:x")
    slide_in.track_insert_key(0, -size.x, position.x)
    slide_in.track_insert_key(0, animation_duration, position.x)
    _animation_player.add_animation("slide_in", slide_in)

    var slide_out = Animation.new()
    slide_out.length = animation_duration
    slide_out.add_track(Animation.TYPE_VALUE)
    slide_out.track_set_path(0, "position:x")
    slide_out.track_insert_key(0, position.x, position.x)
    slide_out.track_insert_key(0, animation_duration, size.x)
    _animation_player.add_animation("slide_out", slide_out)

func _create_scale_animations():
    """创建缩放动画"""
    var scale_in = Animation.new()
    scale_in.length = animation_duration
    scale_in.add_track(Animation.TYPE_VALUE)
    scale_in.track_set_path(0, "scale")
    scale_in.track_insert_key(0, Vector2.ZERO, Vector2.ZERO)
    scale_in.track_insert_key(0, animation_duration, Vector2.ONE)
    _animation_player.add_animation("scale_in", scale_in)

    var scale_out = Animation.new()
    scale_out.length = animation_duration
    scale_out.add_track(Animation.TYPE_VALUE)
    scale_out.track_set_path(0, "scale")
    scale_out.track_insert_key(0, Vector2.ONE, Vector2.ONE)
    scale_out.track_insert_key(0, animation_duration, Vector2.ZERO)
    _animation_player.add_animation("scale_out", scale_out)

func _connect_signals():
    """连接基础信号"""
    if auto_hide_on_escape:
        set_process_input(true)

func _apply_theme():
    """应用主题"""
    if ui_theme:
        theme = ui_theme
    elif UIManager.instance and UIManager.instance.default_theme:
        theme = UIManager.instance.default_theme

func _apply_localization():
    """应用本地化"""
    # 遍历所有文本节点应用本地化
    _localize_node(self)

func _localize_node(node: Node):
    """递归本地化节点"""
    if node is Label or node is Button:
        if node.has_meta("localization_key"):
            var key = node.get_meta("localization_key")
            var localized_text = tr(key)
            if localized_text != key:  # 确保翻译存在
                node.text = localized_text

    # 递归子节点
    for child in node.get_children():
        _localize_node(child)

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

        # 根据过渡类型设置初始状态
        if transition_type == "fade":
            modulate.a = 0.0
        elif transition_type == "slide":
            position.x = -size.x
        elif transition_type == "scale":
            scale = Vector2.ZERO

        # 播放显示动画
        var anim_name = transition_type + "_in"
        if _animation_player.has_animation(anim_name):
            _animation_player.play(anim_name)
        else:
            # 默认淡入
            modulate.a = 1.0

        emit_signal("ui_shown")

func hide_ui():
    """隐藏UI"""
    if _is_visible:
        _is_visible = false

        # 播放隐藏动画
        var anim_name = transition_type + "_out"
        if _animation_player.has_animation(anim_name):
            _animation_player.play(anim_name)
            await _animation_player.animation_finished

        visible = false
        emit_signal("ui_hidden")

func update_data(data: Dictionary):
    """更新UI数据"""
    if validate_data(data):
        _ui_data.merge(data, true)
        _on_data_updated(data)
        emit_signal("ui_data_updated", data)

func _on_data_updated(data: Dictionary):
    """子类重写此方法处理数据更新"""
    pass

func validate_data(data: Dictionary) -> bool:
    """验证传入数据格式"""
    # 子类可以重写此方法添加特定验证
    return true

# 状态保存恢复
func save_ui_state() -> Dictionary:
    """保存UI状态"""
    return {
        "visible": _is_visible,
        "data": _ui_data.duplicate(),
        "position": position,
        "scale": scale,
        "modulate": modulate
    }

func restore_ui_state(state: Dictionary):
    """恢复UI状态"""
    if state.has("visible"):
        _is_visible = state["visible"]
        visible = _is_visible
    if state.has("data"):
        _ui_data = state["data"].duplicate()
    if state.has("position"):
        position = state["position"]
    if state.has("scale"):
        scale = state["scale"]
    if state.has("modulate"):
        modulate = state["modulate"]

# 本地化支持
func set_locale(locale: String):
    """设置语言"""
    TranslationServer.set_locale(locale)
    _apply_localization()

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
    if is_inside_tree() and visible:
        grab_focus()

# 属性访问器
func is_ui_visible() -> bool:
    return _is_visible

func get_ui_data() -> Dictionary:
    return _ui_data.duplicate()

func get_transition_type() -> String:
    return transition_type

func set_transition_type(type: String):
    transition_type = type
    # 重新创建动画
    _create_animations()
