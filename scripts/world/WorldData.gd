extends Resource
class_name WorldData

# 世界配置数据
@export var worlds: Array[WorldConfig] = []
# 区域解锁状态
@export var areas: Dictionary = {}  # area_id: bool
# 当前世界ID
@export var current_world_id: int = 0
# 解锁的世界列表
@export var unlocked_worlds: Array[int] = [0]

# 世界配置子类
class WorldConfig:
	var id: int
	var name: String
	var scene_path: String
	var theme_music: String
	var visual_filter: String  # 视觉滤镜资源路径

	func _init(p_id: int = 0, p_name: String = "", p_scene: String = "", p_music: String = "", p_filter: String = ""):
		id = p_id
		name = p_name
		scene_path = p_scene
		theme_music = p_music
		visual_filter = p_filter

# 初始化默认数据
func _init():
	if worlds.is_empty():
		# 添加默认的三界配置
		worlds.append(WorldConfig.new(0, "现实世界", "res://scenes/worlds/reality_world.tscn", "res://assets/audio/music/reality_theme.ogg", ""))
		worlds.append(WorldConfig.new(1, "心理空间", "res://scenes/worlds/mental_world.tscn", "res://assets/audio/music/mental_theme.ogg", "res://assets/shaders/mental_distortion.tres"))
		worlds.append(WorldConfig.new(2, "记忆领域", "res://scenes/worlds/memory_world.tscn", "res://assets/audio/music/memory_theme.ogg", "res://assets/shaders/memory_fog.tres"))

# 检查区域是否解锁
func is_area_unlocked(area_id: String) -> bool:
	return areas.get(area_id, false)

# 解锁区域
func unlock_area(area_id: String):
	areas[area_id] = true

# 检查世界是否解锁
func is_world_unlocked(world_id: int) -> bool:
	return unlocked_worlds.has(world_id)

# 解锁世界
func unlock_world(world_id: int):
	if not unlocked_worlds.has(world_id):
		unlocked_worlds.append(world_id)

# 获取世界配置
func get_world_config(world_id: int) -> WorldConfig:
	for world in worlds:
		if world.id == world_id:
			return world
	return null

# 序列化数据（用于存档）
func to_dict() -> Dictionary:
	var data = {
		"current_world_id": current_world_id,
		"unlocked_worlds": unlocked_worlds,
		"areas": areas
	}
	return data

# 从字典反序列化
func from_dict(data: Dictionary):
	current_world_id = data.get("current_world_id", 0)
	unlocked_worlds = data.get("unlocked_worlds", [0])
	areas = data.get("areas", {})
