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
