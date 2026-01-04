extends "res://scripts/core/StateMachine.gd".State

func enter():
    print("Entering Game Over State")
    # 显示游戏结束UI
    # 停止所有游戏逻辑
    # 显示最终分数/统计

func update(delta: float):
    # 处理游戏结束输入
    if Input.is_action_just_pressed("ui_accept"):
        emit_signal("finished", "MainMenuState")

func exit():
    print("Exiting Game Over State")
    # 清理游戏状态
    # 重置游戏数据
