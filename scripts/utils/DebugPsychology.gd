class_name DebugPsychologyPanel
extends BaseUI

@onready var randomize_button = $VBoxContainer/RandomizeButton
@onready var high_mood_button = $VBoxContainer/HighMoodButton
@onready var status_label = $VBoxContainer/StatusLabel
@onready var close_button = $VBoxContainer/CloseButton

func _initialize():
    """初始化方法"""
    if randomize_button:
        randomize_button.connect("pressed", _on_randomize_personality)
    if high_mood_button:
        high_mood_button.connect("pressed", _on_force_high_mood)
    if close_button:
        close_button.connect("pressed", _on_close_pressed)

    _update_status_display()

func _on_data_updated(data: Dictionary):
    """数据更新处理"""
    _update_status_display()

func _on_randomize_personality():
    """随机化人格参数"""
    if GameManager.instance and GameManager.instance.player_personality:
        var personality = GameManager.instance.player_personality
        for param in ["mbti_e_i", "mbti_s_n", "mbti_t_f", "mbti_j_p"]:
            personality.set(param, randf())
        for param in ["big5_openness", "big5_conscientiousness", "big5_extraversion", "big5_agreeableness", "big5_neuroticism"]:
            personality.set(param, randi_range(0, 100))
        personality.calculate_mental_health()
        _update_status_display()
        print("随机化人格完成")

func _on_force_high_mood():
    """强制高氛围模式"""
    if GameManager.instance:
        GameManager.instance.update_city_mood_index(0.8)
        _update_status_display()
        print("强制设置为高氛围模式")

func _update_status_display():
    """更新状态显示"""
    if status_label and GameManager.instance:
        var personality = GameManager.instance.player_personality
        var mood = GameManager.instance.city_mood_index
        status_label.text = "MBTI: %s\n心理健康: %.1f\n城市氛围: %.2f" % [
            personality.get_mbti_type() if personality else "N/A",
            personality.mental_health if personality else 0.0,
            mood
        ]
    elif status_label:
        status_label.text = "GameManager未初始化"

func _on_close_pressed():
    """关闭按钮处理"""
    UIManager.instance.hide_ui(UIManager.UIType.DEBUG_PANEL)

func _input(event):
    """输入处理"""
    if event.is_action_pressed("debug_psychology"):
        UIManager.instance.show_debug_panel()

# 兼容旧API的方法
func show_debug_menu():
    """兼容旧API"""
    UIManager.instance.show_debug_panel()

func update_status_label(label: Label):
    """兼容旧API"""
    _update_status_display()
