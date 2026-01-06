class_name PsychologyFileUI
extends BaseUI

@onready var big5_bars: Dictionary = {
    "openness": $Panel/ScrollContainer/VBoxContainer/OpennessBar,
    "conscientiousness": $Panel/ScrollContainer/VBoxContainer/ConscientiousnessBar,
    "extraversion": $Panel/ScrollContainer/VBoxContainer/ExtraversionBar,
    "agreeableness": $Panel/ScrollContainer/VBoxContainer/AgreeablenessBar,
    "neuroticism": $Panel/ScrollContainer/VBoxContainer/NeuroticismBar
}

@onready var mbti_type_label: Label = $Panel/ScrollContainer/VBoxContainer/MBTITypeLabel
@onready var mental_health_label: Label = $Panel/ScrollContainer/VBoxContainer/MentalHealthLabel

func _initialize():
    """初始化方法"""
    _connect_personality_signals()
    update_display()

func _connect_personality_signals():
    """连接人格系统信号"""
    if GameManager.instance and GameManager.instance.player_personality:
        GameManager.instance.player_personality.parameter_changed.connect(_on_parameter_changed)
        GameManager.instance.player_personality.mental_health_updated.connect(_on_mental_health_updated)

func _on_data_updated(data: Dictionary):
    """数据更新处理"""
    if data.has("personality_data"):
        _update_personality_display(data["personality_data"])
    else:
        update_display()

func _update_personality_display(personality_data: Dictionary):
    """更新人格数据显示"""
    for param_name in big5_bars:
        if personality_data.has(param_name):
            big5_bars[param_name].value = personality_data[param_name]

    if personality_data.has("mbti_type"):
        mbti_type_label.text = personality_data["mbti_type"]

    if personality_data.has("mental_health"):
        mental_health_label.text = "%.1f" % personality_data["mental_health"]

func _on_parameter_changed(param_name: String, new_value: float):
    """参数变化处理"""
    if param_name in big5_bars:
        big5_bars[param_name].value = new_value

func _on_mental_health_updated(new_value: float):
    """心理健康更新处理"""
    mental_health_label.text = "%.1f" % new_value

func update_display():
    """更新显示（兼容旧代码）"""
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

func validate_data(data: Dictionary) -> bool:
    """验证数据"""
    if data.has("personality_data"):
        var personality_data = data["personality_data"]
        var required_fields = ["mbti_type", "mental_health"]
        for field in required_fields:
            if not personality_data.has(field):
                push_warning("PsychologyFileUI: Missing personality data field: ", field)
                return false
    return true
