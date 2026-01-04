extends "res://scripts/core/StateMachine.gd".State

func enter():
    print("Entering Playing State")
    # 启动游戏逻辑
    # 显示游戏UI
    # 开始物理模拟

func update(delta: float):
    # 处理游戏输入
    if Input.is_action_just_pressed("ui_cancel"):
        emit_signal("finished", "PausedState")

func exit():
    print("Exiting Playing State")
    # 暂停游戏逻辑（可选）
