extends Node

# 核心系统集成测试脚本
func _ready():
    print("=== 核心游戏系统集成测试开始 ===")
    test_save_system()
    test_offline_system()
    test_state_machine()
    print("=== 核心游戏系统集成测试完成 ===")

func test_save_system():
    print("\n--- 测试存档系统 ---")
    var save_system = SaveSystem.new()
    add_child(save_system)

    # 测试保存
    save_system.save_game(0)
    print("存档保存测试: 完成")

    # 测试加载
    var loaded_data = save_system.load_game(0)
    if loaded_data:
        print("存档加载测试: 成功")
    else:
        print("存档加载测试: 失败")

    # 测试多槽位
    var slots = save_system.get_available_slots()
    print("存档槽位测试: 找到 ", slots.size(), " 个槽位")

    save_system.queue_free()

func test_offline_system():
    print("\n--- 测试离线收益系统 ---")
    var offline_system = OfflineProgressSystem.new()
    add_child(offline_system)

    # 测试收益计算
    var result = offline_system.calculate_offline_progress(3600)  # 1小时
    print("离线收益计算测试: ", result.progress, " 收益")

    # 测试格式化
    var time_str = offline_system.format_offline_time(3661)
    print("时间格式化测试: ", time_str)

    var amount_str = offline_system.format_progress_amount(1234.56)
    print("收益格式化测试: ", amount_str)

    offline_system.queue_free()

func test_state_machine():
    print("\n--- 测试状态机 ---")
    var state_machine = StateMachine.new()
    add_child(state_machine)

    # 添加测试状态
    var test_state = StateMachine.State.new()
    test_state.name = "TestState"
    state_machine.add_child(test_state)

    # 测试状态切换
    state_machine.change_state("TestState")
    print("状态机测试: 状态切换到 ", state_machine.get_current_state_name())

    state_machine.queue_free()

# 运行测试的方法
static func run_tests():
    var test_node = SystemTest.new()
    # 在实际使用时，需要添加到场景树中
    return test_node
