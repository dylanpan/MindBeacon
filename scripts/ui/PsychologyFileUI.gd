extends Control

@onready var big5_bars: Dictionary = {
    "openness": $Panel/ScrollContainer/VBoxContainer/OpennessBar,
    "conscientiousness": $Panel/ScrollContainer/VBoxContainer/ConscientiousnessBar,
    "extraversion": $Panel/ScrollContainer/VBoxContainer/ExtraversionBar,
    "agreeableness": $Panel/ScrollContainer/VBoxContainer/AgreeablenessBar,
    "neuroticism": $Panel/ScrollContainer/VBoxContainer/NeuroticismBar
}

@onready var mbti_type_label: Label = $Panel/ScrollContainer/VBoxContainer/MBTITypeLabel
@onready var mental_health_label: Label = $Panel/ScrollContainer/VBoxContainer/MentalHealthLabel

func _ready():
    if GameManager.instance and GameManager.instance.player_personality:
        GameManager.instance.player_personality.parameter_changed.connect(_on_parameter_changed)
        GameManager.instance.player_personality.mental_health_updated.connect(_on_mental_health_updated)
        update_display()

func _on_parameter_changed(param_name: String, new_value: float):
    if param_name in big5_bars:
        big5_bars[param_name].value = new_value

func _on_mental_health_updated(new_value: float):
    mental_health_label.text = "%.1f" % new_value

func update_display():
    if not GameManager.instance or not GameManager.instance.player_personality:
        return

    var personality = GameManager.instance.player_personality

    # 更新Big5参数条
    for param_name in big5_bars:
        var value = personality.get(param_name)
        big5_bars[param_name].value = value

    # 更新MBTI类型
    mbti_type_label.text = personality.get_mbti_type()

    # 更新心理健康值
    mental_health_label.text = "%.1f" % personality.mental_health

# 调试方法
func _on_randomize_personality_pressed():
    if GameManager.instance and GameManager.instance.player_personality:
        var personality = GameManager.instance.player_personality
        for param in ["mbti_e_i", "mbti_s_n", "mbti_t_f", "mbti_j_p"]:
            personality.set(param, randf())
        for param in ["big5_openness", "big5_conscientiousness", "big5_extraversion", "big5_agreeableness", "big5_neuroticism"]:
            personality.set(param, randi_range(0, 100))
        personality.calculate_mental_health()
        update_display()
