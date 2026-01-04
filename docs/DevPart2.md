#### 总体架构概述

核心游戏系统采用单例模式设计，以GameManager为中心，协调其他子系统。使用Godot的节点系统和Signal机制实现松耦合的组件通信，避免直接依赖关系。该系统支持游戏状态的持久化和离线收益计算，为心理治愈主题的游戏提供稳定的底层支撑。

#### 子系统详细分析

__1. 游戏管理器 (GameManager)__

- __技术实现__：

  - 继承自Node类，作为AutoLoad单例（在project.godot中配置为自动加载）
  - 集成StateMachine节点（可使用Godot的StateMachine插件或自定义实现）
  - 状态枚举：`enum GameState {MAIN_MENU, PLAYING, PAUSED, GAME_OVER}`
  - 使用`_ready()`初始化状态机，`_process()`处理状态切换逻辑

- __关键功能__：

  - __状态机管理__：处理游戏生命周期，使用`change_state()`方法切换状态，每个状态包含`enter()`、`update()`、`exit()`方法
  - __场景切换__：使用`get_tree().change_scene_to_file()`或预加载场景资源，通过`_on_scene_changed`信号监听切换完成
  - __全局事件总线__：创建EventBus.gd脚本，定义信号如`game_state_changed(state)`, `scene_loaded(scene_path)`, 使用`emit_signal()`广播事件

- __集成要点__：

  - 作为其他子系统的"指挥中心"，持有引用并协调调用
  - 使用Godot的Signal系统避免紧耦合，便于扩展新功能

- __实现细节__：

  - __节点结构__：

    ```javascript
    GameManager (Node)
    ├── StateMachine (Node)
    │   ├── MainMenuState (Node)
    │   ├── PlayingState (Node)
    │   ├── PausedState (Node)
    │   └── GameOverState (Node)
    ├── EventBus (Node)
    └── Timer_AutoSave (Timer)
    ```

  - __核心代码结构__：

    ```gdscript
    extends Node

    # 状态枚举
    enum GameState {MAIN_MENU, PLAYING, PAUSED, GAME_OVER}

    # 单例引用
    static var instance: GameManager

    # 引用其他系统
    @onready var save_system = $SaveSystem
    @onready var offline_system = $OfflineProgressSystem
    @onready var state_machine = $StateMachine

    var current_state: GameState

    func _ready():
        instance = self
        _initialize_state_machine()
        _connect_signals()
        _load_game_data()

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
    ```

  - __状态机实现__： 每个状态节点实现：

    ```gdscript
    extends Node

    func enter():
        # 状态进入逻辑

    func update(delta: float):
        # 状态更新逻辑

    func exit():
        # 状态退出逻辑
    ```

__2. 存档系统 (SaveSystem)__

- __技术实现__：

  - 基于ConfigFile类的Resource管理，使用`ConfigFile.new()`创建存档对象
  - 加密存储：集成AES加密库（Godot 4.6支持Crypto类），使用`Crypto.new().encrypt()`方法
  - Timer节点配置：`one_shot = false`, `wait_time = 900`（15分钟），连接`timeout`信号到`_auto_save()`方法

- __关键功能__：

  - __数据结构__：使用section/key模式存储，如`[player] health=100`, `[game] last_save_time=1234567890`
  - __加密机制__：生成密钥（可使用玩家ID或随机种子），在`save_game()`时加密数据，`load_game()`时解密
  - __自动保存__：Timer定期触发，检查游戏状态为PLAYING时执行保存，避免在菜单或暂停时保存
  - __错误处理__：try-catch机制处理文件I/O异常，保存失败时记录日志并尝试备用位置

- __集成要点__：

  - 与GameManager绑定，游戏状态改变时触发手动保存
  - 存储路径：`user://saves/`目录，支持多存档槽位

- __实现细节__：

  - __数据结构定义__：

    ```gdscript
    class SaveData:
        var player_data: Dictionary
        var game_progress: Dictionary
        var timestamp: int
        
        func to_dict() -> Dictionary:
            return {
                "player": player_data,
                "game": game_progress,
                "timestamp": timestamp
            }
    ```

  - __加密保存方法__：

    ```gdscript
    extends Node

    const SAVE_PATH = "user://saves/game_save.cfg"
    # 改进加密模式使用CBC
    const KEY = "your_32_byte_key_here"  # 32字节密钥
    const IV = "your_16_byte_iv_here"    # 16字节初始化向量

    func encrypt_data(data: PackedByteArray) -> PackedByteArray:
        var crypto = Crypto.new()
        return crypto.encrypt(Crypto.AES_MODE_CBC, KEY.to_utf8(), IV.to_utf8(), data)

    func decrypt_data(encrypted: PackedByteArray) -> PackedByteArray:
        var crypto = Crypto.new()
        return crypto.decrypt(Crypto.AES_MODE_CBC, KEY.to_utf8(), IV.to_utf8(), encrypted)

    func save_game(slot: int = 0):
        var config = ConfigFile.new()
        var save_data = _collect_save_data()
        
        # 序列化数据
        var json_data = JSON.stringify(save_data.to_dict())
        
        # AES加密
        var crypto = Crypto.new()
        var encrypted_data = encrypt_data(json_data.to_utf8())
        
        # 保存到文件
        var file = FileAccess.open(SAVE_PATH + str(slot), FileAccess.WRITE)
        file.store_buffer(encrypted_data)
        file.close()

    func load_game(slot: int = 0) -> SaveData:
        if not FileAccess.file_exists(SAVE_PATH + str(slot)):
            return null
            
        var file = FileAccess.open(SAVE_PATH + str(slot), FileAccess.READ)
        var encrypted_data = file.get_buffer(file.get_length())
        file.close()
        
        # AES解密
        var decrypted_data = decrypt_data(encrypted_data)
        var json_string = decrypted_data.get_string_from_utf8()
        
        var parsed_data = JSON.parse_string(json_string)
        return _dict_to_save_data(parsed_data)
    ```

  - __自动保存配置__：

    ```gdscript
    func _setup_auto_save():
        var timer = Timer.new()
        timer.name = "AutoSaveTimer"
        timer.wait_time = 900  # 15分钟
        timer.one_shot = false
        timer.connect("timeout", Callable(self, "_on_auto_save_timeout"))
        add_child(timer)
        timer.start()

    func _on_auto_save_timeout():
        if GameManager.instance.current_state == GameManager.GameState.PLAYING:
            save_game()
    ```

  - __存档升级__：

    ```gdscript
    const SAVE_VERSION = 1

    class SaveData:
        var version: int = SAVE_VERSION
        # ... 其他字段
        
        func migrate_from_old_version(old_data: Dictionary) -> SaveData:
            var new_save = SaveData.new()
            # 迁移逻辑
            if old_data.has("version") and old_data.version < SAVE_VERSION:
                # 执行迁移
                pass
            return new_save
    ```
    
    __多存档槽位管理__：

    ```gdscript
    func get_available_slots() -> Array:
        var slots = []
        for i in range(3):  # 3个存档槽位
            var path = SAVE_PATH + str(i)
            if FileAccess.file_exists(path):
                slots.append({"slot": i, "exists": true, "timestamp": _get_save_timestamp(i)})
            else:
                slots.append({"slot": i, "exists": false})
        return slots
    ```


__3. 离线收益系统 (OfflineProgressSystem)__

- __技术实现__：

  - 继承自Node，集成到GameManager中
  - 使用`OS.get_system_time_secs()`获取时间戳，计算离线时长
  - 分形算法实现：`pow(offline_time_hours, 0.7)`提供非线性收益曲线

- __关键功能__：

  - __收益计算__：

    ```gdscript
    func calculate_offline_progress(offline_seconds: float) -> float:
        var offline_hours = offline_seconds / 3600.0
        var base_yield = get_base_yield()  # 从存档读取
        var building_efficiency = get_building_efficiency()  # 计算建筑加成
        var progress = base_yield * pow(offline_hours, 0.7) * building_efficiency
        return clamp(progress, 0, get_max_offline_cap())  # 防止收益过高
    ```
  - __离线收益UI通知__：
    在GameManager中添加UI显示

    ```gdscript
    func _apply_offline_progress(result: Dictionary):
        # 显示离线收益UI
        var ui = preload("res://scenes/ui/OfflineProgressUI.tscn").instantiate()
        ui.set_progress_data(result)
        add_child(ui)
        
        # 应用收益到游戏状态
        player_stats.add_energy(result.progress)
    ```

  - __上限机制__：实现收益上限（例如24小时等效收益），使用`clamp()`函数限制

  - __时间验证__：存储上次在线时间戳，游戏启动时计算离线时长，防止时间篡改（可添加服务器验证）

- __集成要点__：

  - 在GameManager的`_ready()`中检查离线收益，应用到游戏状态
  - 与SaveSystem联动，离线收益计算后立即保存进度

- __实现细节__：

  - __收益计算增强__：

    ```gdscript
    extends Node

    const MAX_OFFLINE_HOURS = 24.0
    const OFFLINE_EXPONENT = 0.7

    func calculate_offline_progress(offline_seconds: float) -> Dictionary:
        var offline_hours = min(offline_seconds / 3600.0, MAX_OFFLINE_HOURS)
        
        # 获取基础收益和建筑效率
        var base_yield = SaveSystem.get_player_stat("base_yield")
        var building_efficiency = _calculate_building_efficiency()
        
        # 分形算法计算
        var raw_progress = base_yield * pow(offline_hours, OFFLINE_EXPONENT) * building_efficiency
        
        # 应用上限和衰减
        var max_progress = base_yield * pow(MAX_OFFLINE_HOURS, OFFLINE_EXPONENT) * 2.0  # 2倍上限
        var final_progress = min(raw_progress, max_progress)
        
        return {
            "progress": final_progress,
            "time_offline": offline_seconds,
            "efficiency_multiplier": building_efficiency
        }

    func _calculate_building_efficiency() -> float:
        # 计算所有建筑的效率加成
        var buildings = SaveSystem.get_buildings()
        var efficiency = 1.0
        
        for building in buildings:
            efficiency *= building.get("efficiency", 1.0)
        
        return efficiency
    ```

#### 技术挑战与解决方案

- __性能优化__：SaveSystem使用异步保存避免卡顿，OfflineProgressSystem在游戏加载时计算避免运行时开销
- __安全性__：AES加密防止存档篡改，离线收益添加合理上限避免游戏平衡破坏
- __可扩展性__：使用Godot的Resource系统便于添加新存档字段，Signal机制支持新事件类型

#### 集成逻辑细节

__GameManager初始化顺序__：

```gdscript
func _initialize_systems():
    # 1. 初始化事件总线
    EventBus.connect_signals()
    
    # 2. 加载存档系统
    save_system.load_game()
    
    # 3. 计算离线收益
    var offline_result = offline_system.calculate_offline_progress(_get_offline_time())
    if offline_result.progress > 0:
        _apply_offline_progress(offline_result)
        save_system.save_game()  # 立即保存
    
    # 4. 设置自动保存
    save_system.setup_auto_save()
    
    # 5. 进入初始状态
    change_game_state(GameState.MAIN_MENU)
```

__异步保存优化__：

```gdscript
func save_game_async(slot: int = 0) -> void:
    var thread = Thread.new()
    thread.start(Callable(self, "_save_worker").bind(slot))
    
func _save_worker(slot: int):
    # 执行保存逻辑
    call_deferred("_on_save_completed", slot)

func _on_save_completed(slot: int):
    print("Save completed for slot: ", slot)
```

__错误恢复机制__：

```gdscript
func load_game_with_backup(slot: int = 0) -> SaveData:
    var primary_path = SAVE_PATH + str(slot)
    var backup_path = SAVE_PATH + str(slot) + ".bak"
    
    # 尝试加载主存档
    var data = load_game(primary_path)
    if data == null and FileAccess.file_exists(backup_path):
        # 加载备份
        data = load_game(backup_path)
        if data:
            print("Loaded from backup")
    
    return data
```

__性能监控集成__：

```gdscript
func _setup_performance_monitoring():
    var timer = Timer.new()
    timer.wait_time = 60  # 每分钟检查一次
    timer.connect("timeout", Callable(self, "_check_performance"))
    add_child(timer)
    timer.start()

func _check_performance():
    var memory_usage = OS.get_static_memory_usage()
    var fps = Performance.get_monitor(Performance.TIME_FPS)
    # 记录性能数据
```

#### 实现优先级建议

1. 先实现GameManager的基础状态机
2. 集成SaveSystem的基本读写功能
3. 添加OfflineProgressSystem的收益计算
4. 逐步完善加密和自动保存机制

#### 调试和测试建议

- __日志记录__：为每个系统添加详细日志，使用`print_debug()`记录关键操作
- __单元测试__：为收益计算创建测试用例，验证边界条件
- __性能监控__：使用Godot的Profiler监控保存操作的性能影响
- __错误恢复__：实现存档损坏时的自动恢复机制，创建备份文件
