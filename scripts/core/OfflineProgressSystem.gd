extends Node

const MAX_OFFLINE_HOURS = 24.0
const OFFLINE_EXPONENT = 0.7

func _ready():
    pass

func calculate_offline_progress(offline_seconds: float) -> Dictionary:
    var max_offline_hours = ConfigManager.instance.get_float("game_balance", "offline_progress/max_offline_hours", 24.0)
    var offline_exponent = ConfigManager.instance.get_float("game_balance", "offline_progress/offline_exponent", 0.7)
    var offline_hours = min(offline_seconds / 3600.0, max_offline_hours)

    # 获取基础收益和建筑效率
    var base_yield = _get_base_yield()
    var building_efficiency = _calculate_building_efficiency()

    # 分形算法计算
    var raw_progress = base_yield * pow(offline_hours, offline_exponent) * building_efficiency

    # 应用上限和衰减
    var max_progress_multiplier = ConfigManager.instance.get_float("game_balance", "offline_progress/max_progress_multiplier", 2.0)
    var max_progress = base_yield * pow(max_offline_hours, offline_exponent) * max_progress_multiplier
    var final_progress = min(raw_progress, max_progress)

    return {
        "progress": final_progress,
        "time_offline": offline_seconds,
        "efficiency_multiplier": building_efficiency,
        "hours_offline": offline_hours
    }

func _calculate_building_efficiency() -> float:
    # 计算所有建筑的效率加成
    var buildings = _get_buildings()
    var efficiency = 1.0

    for building in buildings:
        efficiency *= building.get("efficiency", 1.0)

    return efficiency

func _get_base_yield() -> float:
    # 从存档系统获取基础收益
    if GameManager.instance and GameManager.instance.save_system:
        return GameManager.instance.save_system.get_player_stat("base_yield")
    return ConfigManager.instance.get_float("game_balance", "offline_progress/default_base_yield", 1.0)  # 默认值

func _get_buildings() -> Array:
    # 从存档系统获取建筑数据
    if GameManager.instance and GameManager.instance.save_system:
        return GameManager.instance.save_system.get_buildings()
    return []

# 简单的离线时间计算（在实际项目中需要更复杂的实现）
func calculate_offline_time(last_online_timestamp: int) -> float:
    var current_time = Time.get_unix_time_from_system()
    var offline_seconds = current_time - last_online_timestamp

    # 防止负数或过大值
    return max(0, min(offline_seconds, MAX_OFFLINE_HOURS * 3600))

# 格式化离线时间显示
func format_offline_time(seconds: float) -> String:
    var hours = int(seconds / 3600)
    var minutes = int((seconds - hours * 3600) / 60)

    if hours > 0:
        return "%d小时%d分钟" % [hours, minutes]
    else:
        return "%d分钟" % minutes

# 格式化收益显示
func format_progress_amount(amount: float) -> String:
    if amount >= 1000000:
        return "%.1fM" % (amount / 1000000.0)
    elif amount >= 1000:
        return "%.1fK" % (amount / 1000.0)
    else:
        return "%.1f" % amount
