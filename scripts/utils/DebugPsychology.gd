extends Node

func _input(event):
    if event.is_action_pressed("debug_psychology"):
        show_debug_menu()

func show_debug_menu():
    var debug_panel_scene = load("res://scenes/ui/DebugPsychologyPanel.tscn")
    if debug_panel_scene:
        var debug_panel = debug_panel_scene.instantiate()
        get_tree().root.add_child(debug_panel)
    else:
        # 如果没有场景，创建临时的调试面板
        create_temp_debug_panel()

func create_temp_debug_panel():
    var panel = Panel.new()
    panel.set_size(Vector2(400, 300))
    panel.position = Vector2(100, 100)

    var vbox = VBoxContainer.new()
    panel.add_child(vbox)

    # 随机人格按钮
    var randomize_btn = Button.new()
    randomize_btn.text = "随机人格"
    randomize_btn.connect("pressed", Callable(self, "_on_randomize_personality"))
    vbox.add_child(randomize_btn)

    # 强制氛围按钮
    var mood_btn = Button.new()
    mood_btn.text = "高氛围模式"
    mood_btn.connect("pressed", Callable(self, "_on_force_high_mood"))
    vbox.add_child(mood_btn)

    # 显示当前状态
    var status_label = Label.new()
    status_label.name = "StatusLabel"
    vbox.add_child(status_label)
    update_status_label(status_label)

    # 关闭按钮
    var close_btn = Button.new()
    close_btn.text = "关闭"
    close_btn.connect("pressed", Callable(panel, "queue_free"))
    vbox.add_child(close_btn)

    get_tree().root.add_child(panel)

func _on_randomize_personality():
    if GameManager.instance and GameManager.instance.player_personality:
        var personality = GameManager.instance.player_personality
        for param in ["mbti_e_i", "mbti_s_n", "mbti_t_f", "mbti_j_p"]:
            personality.set(param, randf())
        for param in ["big5_openness", "big5_conscientiousness", "big5_extraversion", "big5_agreeableness", "big5_neuroticism"]:
            personality.set(param, randi_range(0, 100))
        personality.calculate_mental_health()
        print("随机化人格完成")

func _on_force_high_mood():
    if GameManager.instance:
        GameManager.instance.update_city_mood_index(0.8)
        print("强制设置为高氛围模式")

func update_status_label(label: Label):
    if GameManager.instance:
        var personality = GameManager.instance.player_personality
        var mood = GameManager.instance.city_mood_index
        label.text = "MBTI: %s\n心理健康: %.1f\n城市氛围: %.2f" % [
            personality.get_mbti_type() if personality else "N/A",
            personality.mental_health if personality else 0.0,
            mood
        ]
    else:
        label.text = "GameManager未初始化"
