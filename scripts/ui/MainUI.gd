extends Control

@onready var energy_label = $Panel/VBoxContainer/ResourceDisplay/EnergyLabel
@onready var health_bar = $Panel/VBoxContainer/ResourceDisplay/HealthBar
@onready var healing_progress = $Panel/VBoxContainer/HealingProgress
@onready var quick_action_buttons = $Panel/VBoxContainer/QuickActions.get_children()

func _ready():
    # 连接游戏数据更新信号
    if GameManager.instance:
        GameManager.instance.connect("data_updated", _update_display)
    if get_node_or_null("/root/HealingSystem"):
        var healing_system = get_node("/root/HealingSystem")
        healing_system.connect("healing_progress_updated", _update_healing_progress)
    _update_display()

    # 连接按钮信号
    for button in quick_action_buttons:
        button.connect("pressed", _on_quick_action_pressed.bind(button.name))

func _update_display():
    if not GameManager.instance:
        return
    energy_label.text = "Mental Energy: %d" % GameManager.instance.mental_energy
    health_bar.value = GameManager.instance.psychology_health

func _update_healing_progress(progress: float):
    healing_progress.value = progress

func _on_quick_action_pressed(button_name: String):
    # 处理快捷操作逻辑
    match button_name:
        "HealButton":
            if get_node_or_null("/root/HealingSystem"):
                get_node("/root/HealingSystem").start_healing()
        "SaveButton":
            if get_node_or_null("/root/SaveSystem"):
                get_node("/root/SaveSystem").manual_save()
        "ProfileButton":
            show_psychology_file()

func show_psychology_file():
    # 显示心理档案界面
    var profile_ui = load("res://scenes/ui/PsychologyFileUI.tscn").instantiate()
    add_child(profile_ui)
    profile_ui.show()
