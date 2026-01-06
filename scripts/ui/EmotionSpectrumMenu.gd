extends Control

@export var emotion_options: Array[String] = ["joy", "sadness", "anger", "calm", "anxiety", "confidence"]
@export var radius: float = 80.0

@onready var option_container = $OptionContainer
@onready var buttons = option_container.get_children()

signal emotion_selected(emotion_type: String)

func _ready():
    visible = false
    # 连接按钮信号
    for i in range(buttons.size()):
        var button = buttons[i]
        button.connect("pressed", _on_option_selected.bind(emotion_options[i]))
        button.connect("mouse_entered", _on_button_hover.bind(button, true))
        button.connect("mouse_exited", _on_button_hover.bind(button, false))

func show_menu():
    visible = true
    scale = Vector2.ZERO
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # 排列情绪选项
    for i in range(emotion_options.size()):
        var button = buttons[i]
        var angle = i * (2 * PI / emotion_options.size())
        var target_pos = Vector2(cos(angle), sin(angle)) * radius
        button.position = target_pos
        button.text = emotion_options[i].capitalize()

func hide_menu():
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_callback(queue_free)

func _on_option_selected(emotion_type: String):
    emit_signal("emotion_selected", emotion_type)
    # 传递给心理系统应用情绪影响
    if get_node_or_null("/root/PsychologyModel"):
        get_node("/root/PsychologyModel").apply_emotion_impact(emotion_type)
    hide_menu()

func _on_button_hover(button: Button, entered: bool):
    if entered:
        var tween = create_tween()
        tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.1)
    else:
        var tween = create_tween()
        tween.tween_property(button, "scale", Vector2.ONE, 0.1)
