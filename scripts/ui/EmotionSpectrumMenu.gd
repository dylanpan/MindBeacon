class_name EmotionSpectrumMenu
extends BaseUI

@export var emotion_options: Array[String] = ["joy", "sadness", "anger", "calm", "anxiety", "confidence"]
@export var radius: float = 80.0

@onready var option_container = $OptionContainer
@onready var buttons = option_container.get_children()

signal emotion_selected(emotion_type: String)

func _initialize():
    """初始化方法"""
    _setup_buttons()
    _arrange_emotion_buttons()

func _setup_buttons():
    """设置按钮"""
    for i in range(min(buttons.size(), emotion_options.size())):
        var button = buttons[i]
        button.connect("pressed", _on_option_selected.bind(emotion_options[i]))
        button.connect("mouse_entered", _on_button_hover.bind(button, true))
        button.connect("mouse_exited", _on_button_hover.bind(button, false))

func _arrange_emotion_buttons():
    """排列情绪按钮"""
    for i in range(min(buttons.size(), emotion_options.size())):
        var button = buttons[i]
        var angle = i * (2 * PI / emotion_options.size())
        var target_pos = Vector2(cos(angle), sin(angle)) * radius
        button.position = target_pos
        button.text = emotion_options[i].capitalize()

func show_menu():
    """显示菜单（兼容旧接口）"""
    show_ui()

func hide_menu():
    """隐藏菜单（兼容旧接口）"""
    hide_ui()

func _on_option_selected(emotion_type: String):
    """选项选择处理"""
    emit_signal("emotion_selected", emotion_type)

    # 传递给心理系统应用情绪影响
    if get_node_or_null("/root/PsychologyModel"):
        get_node("/root/PsychologyModel").apply_emotion_impact(emotion_type)

    # 通知UIManager关闭模态UI
    UIManager.instance.hide_ui(UIManager.UIType.EMOTION_SPECTRUM)

func _on_button_hover(button: Button, entered: bool):
    """按钮悬停效果"""
    if entered:
        var tween = create_tween()
        tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.1)
    else:
        var tween = create_tween()
        tween.tween_property(button, "scale", Vector2.ONE, 0.1)

func _on_data_updated(data: Dictionary):
    """数据更新处理"""
    if data.has("available_emotions"):
        emotion_options = data["available_emotions"]
        _arrange_emotion_buttons()

func validate_data(data: Dictionary) -> bool:
    """验证数据"""
    if data.has("available_emotions"):
        if not data["available_emotions"] is Array:
            push_warning("EmotionSpectrumMenu: available_emotions must be an Array")
            return false
    return true
