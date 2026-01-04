extends "res://scripts/core/StateMachine.gd".State

func enter():
    print("Entering Main Menu State")
    # 显示主菜单UI
    # 暂停游戏逻辑
    # 允许设置和退出

func update(delta: float):
    # 处理菜单输入
    if Input.is_action_just_pressed("ui_accept"):
        emit_signal("finished", "PlayingState")

func exit():
    print("Exiting Main Menu State")
    # 隐藏主菜单UI
