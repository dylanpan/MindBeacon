## 参数配置化统一管理

### 1. 创建ConfigManager.gd (配置管理类)

__位置__: `scripts/core/ConfigManager.gd`

__核心功能__:

- 单例模式，确保全局唯一实例
- 自动加载所有JSON配置文件
- 提供类型安全的数据获取方法
- 支持默认值回退和嵌套路径访问
- 完善的错误处理和回退机制

__关键方法__:

```gdscript
class_name ConfigManager
extends Node

static var instance: ConfigManager
var config_data: Dictionary = {}

func _ready():
    instance = self
    load_all_configs()

func load_all_configs() -> void:
    var config_files = ["game_balance", "ui_config", "audio_config", "world_config", "system_config"]
    for config_name in config_files:
        load_config(config_name)

func load_config(config_name: String) -> void:
    var path = "res://data/configs/" + config_name + ".json"
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var result = json.parse(json_string)
        if result == OK:
            config_data[config_name] = json.get_data()
            print("Config loaded: " + config_name)
        else:
            push_error("JSON parse error in " + config_name + ": " + json.get_error_message())
            _create_default_config(config_name)
    else:
        push_error("Failed to load config file: " + path)
        _create_default_config(config_name)

func _create_default_config(config_name: String) -> void:
    # 为每个配置文件提供默认配置，确保游戏能够运行
    match config_name:
        "game_balance":
            config_data[config_name] = {
                "mental_energy": {
                    "attraction_range": 100.0,
                    "decay_time": 30.0,
                    "default_energy_value": 10.0,
                    "attraction_speed": 50.0,
                    "volume_scale": 0.1,
                    "pitch_positive_min": 1.0,
                    "pitch_positive_max": 1.2,
                    "pitch_negative_min": 0.8,
                    "pitch_negative_max": 1.0
                },
                "personality": {
                    "mbti_weight": 0.4,
                    "big5_weight": 0.6,
                    "default_mental_health": 50.0,
                    "psychological_modifier": 1.2,
                    "neuroticism_impact": 0.1
                },
                "offline_progress": {
                    "max_offline_hours": 24.0,
                    "offline_exponent": 0.7,
                    "max_progress_multiplier": 2.0,
                    "default_base_yield": 1.0
                },
                "mental_energy_pool": {
                    "pool_size": 100
                }
            }
        "ui_config":
            config_data[config_name] = {
                "animation": {
                    "transition_duration": 1.0,
                    "animation_duration": 0.3,
                    "tooltip_delay": 2.0,
                    "emotion_menu_radius": 80.0
                },
                "ui_management": {
                    "max_pool_size": 5,
                    "healing_ui_offset": 50,
                    "ui_z_index_increment": 1
                }
            }
        "audio_config":
            config_data[config_name] = {
                "music": {
                    "volume_min": -60.0,
                    "volume_max": 0.0,
                    "pitch_energy_base": 0.8,
                    "pitch_energy_scale": 0.4
                },
                "sfx": {
                    "pool_size_high_end": 10,
                    "pool_size_low_end": 5,
                    "volume_randomization": 6.0
                }
            }
        "world_config":
            config_data[config_name] = {
                "portal": {
                    "cooldown_time": 2.0,
                    "default_energy_requirement": 0.0,
                    "portal_radius": 32.0,
                    "particle_amount": 20,
                    "particle_lifetime": 0.5,
                    "emission_radius": 16.0,
                    "spread_angle": 45.0,
                    "initial_velocity_min": 50.0,
                    "initial_velocity_max": 100.0
                },
                "event_emitter": {
                    "trigger_radius": 50.0,
                    "cooldown_time": 10.0
                },
                "region_area": {
                    "update_interval": 5.0,
                    "default_mood": 0.5,
                    "mood_dark_threshold": 0.3,
                    "mood_neutral_threshold": 0.7
                },
                "area_unlock": {
                    "check_interval": 1.0,
                    "default_difficulty_curve": 1.0
                }
            }
        "system_config":
            config_data[config_name] = {
                "game_manager": {
                    "default_city_mood": 0.5,
                    "performance_monitor_interval": 60,
                    "mood_transition_duration": 2.0,
                    "mood_change_threshold": 0.01,
                    "mental_energy_pool_size": 100
                },
                "save_system": {
                    "save_version": 1,
                    "auto_save_interval": 900
                },
                "npc_manager": {
                    "max_npcs_per_region": 10,
                    "total_max_npcs": 50
                }
            }

func get_nested_value(config_name: String, path: String, default_value = null):
    if not config_data.has(config_name):
        return default_value
    
    var current = config_data[config_name]
    var keys = path.split("/")
    
    for key in keys:
        if typeof(current) == TYPE_DICTIONARY and current.has(key):
            current = current[key]
        else:
            return default_value
    
    return current

# 类型安全获取方法
func get_float(config_name: String, key_path: String, default: float = 0.0) -> float:
    return float(get_nested_value(config_name, key_path, default))

func get_int(config_name: String, key_path: String, default: int = 0) -> int:
    return int(get_nested_value(config_name, key_path, default))

func get_string(config_name: String, key_path: String, default: String = "") -> String:
    return str(get_nested_value(config_name, key_path, default))

func get_bool(config_name: String, key_path: String, default: bool = false) -> bool:
    return bool(get_nested_value(config_name, key_path, default))
````

### 2. JSON配置文件详细内容

__确保 `data/configs/` 目录存在，如果不存在请先创建该目录__

__game_balance.json__:

```json
{
  "mental_energy": {
    "attraction_range": 100.0,
    "decay_time": 30.0,
    "default_energy_value": 10.0,
    "attraction_speed": 50.0,
    "volume_scale": 0.1,
    "pitch_positive_min": 1.0,
    "pitch_positive_max": 1.2,
    "pitch_negative_min": 0.8,
    "pitch_negative_max": 1.0
  },
  "personality": {
    "mbti_weight": 0.4,
    "big5_weight": 0.6,
    "default_mental_health": 50.0,
    "psychological_modifier": 1.2,
    "neuroticism_impact": 0.1
  },
  "offline_progress": {
    "max_offline_hours": 24.0,
    "offline_exponent": 0.7,
    "max_progress_multiplier": 2.0,
    "default_base_yield": 1.0
  },
  "mental_energy_pool": {
    "pool_size": 100
  }
}
```

__ui_config.json__:

```json
{
  "animation": {
    "transition_duration": 1.0,
    "animation_duration": 0.3,
    "tooltip_delay": 2.0,
    "emotion_menu_radius": 80.0
  },
  "ui_management": {
    "max_pool_size": 5,
    "healing_ui_offset": 50,
    "ui_z_index_increment": 1
  }
}
```

__audio_config.json__:

```json
{
  "music": {
    "volume_min": -60.0,
    "volume_max": 0.0,
    "pitch_energy_base": 0.8,
    "pitch_energy_scale": 0.4
  },
  "sfx": {
    "pool_size_high_end": 10,
    "pool_size_low_end": 5,
    "volume_randomization": 6.0
  }
}
```

__world_config.json__:

```json
{
  "portal": {
    "cooldown_time": 2.0,
    "default_energy_requirement": 0.0,
    "portal_radius": 32.0,
    "particle_amount": 20,
    "particle_lifetime": 0.5,
    "emission_radius": 16.0,
    "spread_angle": 45.0,
    "initial_velocity_min": 50.0,
    "initial_velocity_max": 100.0
  },
  "event_emitter": {
    "trigger_radius": 50.0,
    "cooldown_time": 10.0
  },
  "region_area": {
    "update_interval": 5.0,
    "default_mood": 0.5,
    "mood_dark_threshold": 0.3,
    "mood_neutral_threshold": 0.7
  },
  "area_unlock": {
    "check_interval": 1.0,
    "default_difficulty_curve": 1.0
  }
}
```

__system_config.json__:

```json
{
  "game_manager": {
    "default_city_mood": 0.5,
    "performance_monitor_interval": 60,
    "mood_transition_duration": 2.0,
    "mood_change_threshold": 0.01,
    "mental_energy_pool_size": 100
  },
  "save_system": {
    "save_version": 1,
    "auto_save_interval": 900
  },
  "npc_manager": {
    "max_npcs_per_region": 10,
    "total_max_npcs": 50
  }
}
```

### 3. 脚本修改具体步骤

__重要说明__:

- 对于 `const` 常量：需要在声明时使用配置值
- 对于 `@export` 变量：可以在声明时设置默认值，或在 `_ready()` 中初始化
- 对于运行时计算的值：在相应方法中获取配置值

__MentalEnergyOrb.gd 修改__:

```gdscript
const ATTRACTION_RANGE = ConfigManager.instance.get_float("game_balance", "mental_energy/attraction_range", 100.0)
const DECAY_TIME = ConfigManager.instance.get_float("game_balance", "mental_energy/decay_time", 30.0)

@export var energy_value: float = 10.0
@export var attraction_speed: float = 50.0

func _ready():
    energy_value = ConfigManager.instance.get_float("game_balance", "mental_energy/default_energy_value", 10.0)
    attraction_speed = ConfigManager.instance.get_float("game_balance", "mental_energy/attraction_speed", 50.0)
    # ... 其他初始化代码
```

__Personality.gd 修改__:

```gdscript
const MBTI_WEIGHT = ConfigManager.instance.get_float("game_balance", "personality/mbti_weight", 0.4)
const BIG5_WEIGHT = ConfigManager.instance.get_float("game_balance", "personality/big5_weight", 0.6)

var mental_health: float = 50.0

func initialize_default_values():
    mental_health = ConfigManager.instance.get_float("game_balance", "personality/default_mental_health", 50.0)
    # ... 其他初始化
```

__OfflineProgressSystem.gd 修改__:

```gdscript
const MAX_OFFLINE_HOURS = 24.0
const OFFLINE_EXPONENT = 0.7

func _ready():
    # 在运行时获取配置值
    pass

func calculate_offline_progress(offline_seconds: float) -> Dictionary:
    var max_offline_hours = ConfigManager.instance.get_float("game_balance", "offline_progress/max_offline_hours", 24.0)
    var offline_exponent = ConfigManager.instance.get_float("game_balance", "offline_progress/offline_exponent", 0.7)
    var max_progress_multiplier = ConfigManager.instance.get_float("game_balance", "offline_progress/max_progress_multiplier", 2.0)
    
    var offline_hours = min(offline_seconds / 3600.0, max_offline_hours)
    # ... 使用配置值的计算逻辑
```

__需要修改的文件列表和关键修改点__:

- scripts/gameplay/MentalEnergyOrb.gd - 吸引范围、衰减时间、能量值、吸引速度
- scripts/core/Personality.gd - MBTI/Big5权重、心理健康默认值、环境修正因子
- scripts/core/OfflineProgressSystem.gd - 最大离线时间、收益指数、收益上限倍数
- scripts/utils/MentalEnergyPool.gd - 对象池大小
- scripts/world/WorldLayerManager.gd - 过渡持续时间
- scripts/ui/BaseUI.gd - 动画持续时间
- scripts/ui/EmotionSpectrumMenu.gd - 情感菜单半径
- scripts/ui/HealingUI.gd - 治疗UI偏移、延迟时间
- scripts/ui/UIManager.gd - UI池大小、工具提示延迟
- scripts/world/Portal.gd - 冷却时间、能量需求、粒子参数
- scripts/world/EventEmitter.gd - 触发半径、冷却时间
- scripts/world/AreaUnlockSystem.gd - 检查间隔、难度曲线
- scripts/core/GameManager.gd - 城市心情默认值、性能监控间隔、心情过渡参数
- scripts/core/SaveSystem.gd - 保存版本、自动保存间隔
- scripts/characters/NPCManager.gd - NPC数量限制
- scripts/gameplay/RegionArea.gd - 区域更新间隔、心情阈值
- scripts/utils/LayeredMusicSystem.gd - 音乐音量范围、音调参数
- scripts/utils/SFXManager.gd - 音效池大小、音量随机化

### 4. GameManager.gd 集成ConfigManager

__重要__: ConfigManager需要在所有其他系统初始化之前加载

```gdscript
func _ready():
    instance = self
    _initialize_config_manager()  # 最先初始化配置管理器
    _initialize_subsystems()
    _connect_signals()
    _load_game_data()
    _initialize_systems()
    _setup_performance_monitoring()

func _initialize_config_manager():
    var config_manager_node = ConfigManager.new()
    config_manager_node.name = "ConfigManager"
    add_child(config_manager_node)
    
    # 等待配置加载完成
    await config_manager_node._ready()
```

### 5. Git操作序列

__添加文件 (每个文件单独add)__:

```bash
git add scripts/core/ConfigManager.gd
git add data/configs/game_balance.json
git add data/configs/ui_config.json
git add data/configs/audio_config.json
git add data/configs/world_config.json
git add data/configs/system_config.json

# 添加所有修改的脚本文件
git add scripts/gameplay/MentalEnergyOrb.gd
git add scripts/core/Personality.gd
git add scripts/core/OfflineProgressSystem.gd
git add scripts/utils/MentalEnergyPool.gd
git add scripts/world/WorldLayerManager.gd
git add scripts/ui/BaseUI.gd
git add scripts/ui/EmotionSpectrumMenu.gd
git add scripts/ui/HealingUI.gd
git add scripts/ui/UIManager.gd
git add scripts/world/Portal.gd
git add scripts/world/EventEmitter.gd
git add scripts/world/AreaUnlockSystem.gd
git add scripts/core/GameManager.gd
git add scripts/core/SaveSystem.gd
git add scripts/characters/NPCManager.gd
git add scripts/gameplay/RegionArea.gd
git add scripts/utils/LayeredMusicSystem.gd
git add scripts/utils/SFXManager.gd
```

__提交 (分行编写)__:

```bash
git commit -m "feat: Add configuration management system

- Add ConfigManager.gd for centralized config loading with nested path support
- Create game_balance.json with game mechanics parameters  
- Create ui_config.json with UI/animation settings
- Create audio_config.json with audio parameters
- Create world_config.json with world/area settings
- Create system_config.json with system parameters
- Refactor all hardcoded values in scripts to use configuration system
- Add error handling and fallback default configurations

This refactoring extracts hardcoded values into configurable JSON files,
making the game parameters easily adjustable without code changes.
All systems now support runtime parameter tuning
```
