extends Node

# 事件信号定义
signal npc_healed(npc_id, amount)
signal energy_collected(amount, type)
signal area_unlocked(area_id)
signal city_mood_changed(new_mood)
signal offline_progress_calculated(progress_data)

func _ready():
    pass
