class_name MainUI
extends BaseUI

@onready var energy_label = $Panel/VBoxContainer/ResourceDisplay/EnergyLabel
@onready var health_bar = $Panel/VBoxContainer/ResourceDisplay/HealthBar
@onready var healing_progress = $Panel/VBoxContainer/HealingProgress
@onready var quick_action_buttons = $Panel/VBoxContainer/QuickActions.get_children()

func _initialize():
    """重写初始化方法"""
    _setup_buttons()
    _connect_game_signals()

func _setup_buttons():
    """设置按钮"""
    for button in quick_action_buttons:
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

func validate_data(data: Dictionary) -> bool:
    """验证数据"""
    # 检查必需的数据字段
    var required_fields = ["mental_energy", "psychology_health"]
    for field in required_fields:
        if not data.has(field):
            push_warning("MainUI: Missing required data field: ", field)
            return false
    return true
