extends Node

# 状态枚举
enum GameState {MAIN_MENU, PLAYING, PAUSED, GAME_OVER}
enum WorldLayer {REAL, PSYCHOLOGICAL}  # 添加世界层枚举

# 单例引用
static var instance: GameManager

# 引用其他系统（在_initialize_subsystems中初始化）
var save_system: SaveSystem
var offline_system: OfflineProgressSystem
var state_machine: StateMachine

var current_state: GameState
var current_world_layer: WorldLayer = WorldLayer.REAL  # 当前世界层

# 心理系统变量
var player_personality: Personality
var city_mood_index: float = 0.5  # 范围0.0-1.0
var region_areas: Array = []  # 区域列表

# 信号
signal mood_index_changed(new_value: float)

func _ready():
    instance = self
    _initialize_subsystems()
    _initialize_state_machine()
    _connect_signals()
    _load_game_data()
    _initialize_systems()
    _setup_performance_monitoring()

func _process(delta):
    if state_machine:
        state_machine.update(delta)

func change_game_state(new_state: GameState):
    if new_state != current_state:
        current_state = new_state
        EventBus.emit_signal("game_state_changed", current_state)
        # 触发相应状态逻辑

func switch_scene(scene_path: String):
    get_tree().change_scene_to_file(scene_path)

# 私有方法
func _initialize_subsystems():
    # 初始化子系统节点
    var save_system_node = SaveSystem.new()
    save_system_node.name = "SaveSystem"
    add_child(save_system_node)
    save_system = save_system_node

    var offline_system_node = OfflineProgressSystem.new()
    offline_system_node.name = "OfflineProgressSystem"
    add_child(offline_system_node)
    offline_system = offline_system_node

    var state_machine_node = StateMachine.new()
    state_machine_node.name = "StateMachine"
    add_child(state_machine_node)
    state_machine = state_machine_node

func _initialize_state_machine():
    # 初始化状态机节点
    if state_machine:
        # 添加状态节点
        var main_menu_state = load("res://scripts/core/states/MainMenuState.gd").new()
        main_menu_state.name = "MainMenuState"
        state_machine.add_child(main_menu_state)

        var playing_state = load("res://scripts/core/states/PlayingState.gd").new()
        playing_state.name = "PlayingState"
        state_machine.add_child(playing_state)

        var paused_state = load("res://scripts/core/states/PausedState.gd").new()
        paused_state.name = "PausedState"
        state_machine.add_child(paused_state)

        var game_over_state = load("res://scripts/core/states/GameOverState.gd").new()
        game_over_state.name = "GameOverState"
        state_machine.add_child(game_over_state)

        # 设置初始状态
        state_machine.change_state("MainMenuState")

func _connect_signals():
    # 连接事件总线信号
    EventBus.connect("game_state_changed", Callable(self, "_on_game_state_changed"))

func _load_game_data():
    # 加载游戏数据
    if save_system:
        save_system.load_game()

func _initialize_systems():
    # 1. 初始化事件总线
    EventBus.connect_signals()

    # 2. 初始化UI管理器
    _initialize_ui_manager()

    # 3. 加载存档系统
    if save_system:
        save_system.load_game()

    # 4. 初始化心理系统
    initialize_psychology_system()

    # 5. 计算离线收益
    if offline_system:
        var offline_result = offline_system.calculate_offline_progress(_get_offline_time())
        if offline_result.progress > 0:
            _apply_offline_progress(offline_result)
            if save_system:
                save_system.save_game()  # 立即保存

    # 6. 设置自动保存
    if save_system:
        save_system.setup_auto_save()

    # 7. 进入初始状态
    change_game_state(GameState.MAIN_MENU)

func _get_offline_time() -> float:
    # 获取离线时间
    if save_system:
        var current_save = save_system.load_game()
        if current_save:
            var last_online = current_save.timestamp
            return Time.get_unix_time_from_system() - last_online
    return 0.0

func _apply_offline_progress(result: Dictionary):
    # 使用UIManager显示离线收益UI
    if UIManager.instance:
        UIManager.instance.show_offline_progress({
            "progress_data": result
        })

        # 应用收益到游戏状态（暂时注释，需要实际的玩家数据管理）
        # player_stats.add_energy(result.progress)
    else:
        print("UIManager not available")

func _setup_performance_monitoring():
    var timer = Timer.new()
    timer.name = "PerformanceMonitor"
    timer.wait_time = 60  # 每分钟检查一次
    timer.connect("timeout", Callable(self, "_check_performance"))
    add_child(timer)
    timer.start()

func _check_performance():
    var memory_usage = OS.get_static_memory_usage()
    var fps = Performance.get_monitor(Performance.TIME_FPS)
    # 记录性能数据
    print("Performance - Memory: ", memory_usage, " FPS: ", fps)

func _on_game_state_changed(new_state):
    print("Game state changed to: ", new_state)

# 心理系统方法
func initialize_psychology_system():
    # 加载默认人格模板
    player_personality = load("res://data/configs/default_personality.tres")
    if not player_personality:
        player_personality = Personality.new()

    # 初始化MentalEnergySystem对象池（如果存在）
    if has_node("/root/MentalEnergyPool"):
        var pool = get_node("/root/MentalEnergyPool")
        if pool.has_method("initialize_pool"):
            pool.initialize_pool(100)

func update_city_mood_index(new_value: float):
    var old_value = city_mood_index
    city_mood_index = clamp(new_value, 0.0, 1.0)

    if abs(city_mood_index - old_value) > 0.01:  # 避免频繁更新
        mood_index_changed.emit(city_mood_index)
        # 触发氛围过渡效果
        apply_mood_transition(old_value, city_mood_index)

func apply_mood_transition(old_value: float, new_value: float):
    var tween = create_tween()
    tween.tween_property(self, "city_mood_index", new_value, 2.0)
    tween.tween_callback(func(): EventBus.emit_signal("mood_transition_complete"))

func _initialize_ui_manager():
    """初始化UI管理器"""
    # UIManager已在Main.tscn中实例化，这里获取引用
    var ui_manager = get_node("/root/Main/UI/UIManager")
    if ui_manager and ui_manager is UIManager:
        # UIManager已在_ready()中初始化，这里可以添加额外配置
        pass
    else:
        push_warning("UIManager not found or not properly configured")
