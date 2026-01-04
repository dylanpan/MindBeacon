extends "res://scripts/core/StateMachine.gd".State

func enter():
    print("Entering Paused State")
    # 显示暂停菜单
    # 暂停游戏逻辑
    # 停止物理模拟

func update(delta: float):
    # 处理暂停菜单输入
    if Input.is_action_just_pressed("ui_cancel"):
        emit_signal("finished", "PlayingState")

func exit():
    print("Exiting Paused State")
    # 隐藏暂停菜单
    # 恢复游戏逻辑
