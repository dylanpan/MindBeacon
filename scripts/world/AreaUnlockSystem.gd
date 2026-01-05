extends Node
class_name AreaUnlockSystem

# 信号
signal area_unlocked(area_id: String, rewards: Array)
signal unlock_progress_changed(area_id: String, current: float, required: float)

# 区域数据结构
class AreaData:
	var id: String
	var name: String
	var description: String
	var unlock_condition: Dictionary  # {"type": "energy", "threshold": 1000}
	var scene_path: String
	var rewards: Array[Dictionary]  # [{"type": "resource", "id": "mental_energy", "amount": 50}]
	var preview_texture: String
	var difficulty_curve: float = 1.0  # 解锁难度系数
	
	func _init(p_id: String = "", p_name: String = "", p_desc: String = ""):
		id = p_id
		name = p_name
		description = p_desc
		unlock_condition = {}
		rewards = []
		difficulty_curve = 1.0

# 导出变量
@export var areas_data: Array[AreaData] = []
@export var check_interval: float = 1.0  # 检查间隔（秒）

# 内部变量
var areas_progress: Dictionary = {}  # area_id: current_progress
var unlock_timer: Timer
var world_data: WorldData

func _ready():
	_initialize_areas()
	_setup_timer()
	_load_progress()

# 初始化区域数据
func _initialize_areas():
	if areas_data.is_empty():
		# 添加默认区域
		var area1 = AreaData.new("downtown", "市中心", "繁华的都市中心区域")
		area1.unlock_condition = {"type": "energy", "threshold": 100}
		area1.rewards = [{"type": "resource", "id": "mental_energy", "amount": 25}]
		area1.scene_path = "res://scenes/worlds/downtown.tscn"
		areas_data.append(area1)
		
		var area2 = AreaData.new("park", "中央公园", "宁静的都市绿洲")
		area2.unlock_condition = {"type": "energy", "threshold": 250}
		area2.rewards = [{"type": "resource", "id": "mental_energy", "amount": 50}]
		area2.scene_path = "res://scenes/worlds/park.tscn"
		areas_data.append(area2)

# 设置定时器
func _setup_timer():
	unlock_timer = Timer.new()
	unlock_timer.wait_time = check_interval
	unlock_timer.timeout.connect(_check_unlock_conditions)
	add_child(unlock_timer)
	unlock_timer.start()

# 加载进度
func _load_progress():
	# 从SaveSystem加载进度（假设存在）
	if SaveSystem.has_data("area_progress"):
		areas_progress = SaveSystem.get_data("area_progress")

# 保存进度
func _save_progress():
	if SaveSystem:
		SaveSystem.set_data("area_progress", areas_progress)

# 检查解锁条件
func _check_unlock_conditions():
	for area_data in areas_data:
		if world_data and world_data.is_area_unlocked(area_data.id):
			continue  # 已解锁
		
		var condition = area_data.unlock_condition
		var current_progress = _get_current_progress(condition)
		
		# 更新进度
		areas_progress[area_data.id] = current_progress
		
		# 检查是否达到阈值
		var threshold = condition.get("threshold", 0) * area_data.difficulty_curve
		if current_progress >= threshold:
			_unlock_area(area_data)
		
		# 发送进度更新信号
		unlock_progress_changed.emit(area_data.id, current_progress, threshold)

# 获取当前进度
func _get_current_progress(condition: Dictionary) -> float:
	var type = condition.get("type", "")
	match type:
		"energy":
			# 假设有全局能量系统
			return MentalEnergyPool.get_total_energy()
		"time":
			return Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60
		_:
			return 0.0

# 解锁区域
func _unlock_area(area_data: AreaData):
	if world_data:
		world_data.unlock_area(area_data.id)
	
	# 发放奖励
	var granted_rewards = []
	for reward in area_data.rewards:
		_grant_reward(reward)
		granted_rewards.append(reward)
	
	# 保存进度
	_save_progress()
	
	# 发送解锁信号
	area_unlocked.emit(area_data.id, granted_rewards)
	
	print("Area unlocked: ", area_data.name)

# 发放奖励
func _grant_reward(reward: Dictionary):
	var type = reward.get("type", "")
	var id = reward.get("id", "")
	var amount = reward.get("amount", 0)
	
	match type:
		"resource":
			if id == "mental_energy":
				MentalEnergyPool.add_energy(amount)
		"item":
			# 假设有物品系统
			pass
		"achievement":
			# 假设有成就系统
			pass

# 手动检查特定区域
func check_area_unlock(area_id: String):
	for area_data in areas_data:
		if area_data.id == area_id:
			var condition = area_data.unlock_condition
			var current = _get_current_progress(condition)
			var threshold = condition.get("threshold", 0) * area_data.difficulty_curve
			
			if current >= threshold and world_data and not world_data.is_area_unlocked(area_id):
				_unlock_area(area_data)
			break

# 获取区域数据
func get_area_data(area_id: String) -> AreaData:
	for area_data in areas_data:
		if area_data.id == area_id:
			return area_data
	return null

# 获取所有区域ID
func get_all_area_ids() -> Array[String]:
	var ids: Array[String] = []
	for area in areas_data:
		ids.append(area.id)
	return ids

# 设置世界数据引用
func set_world_data(data: WorldData):
	world_data = data

# 暂停/恢复检查
func set_paused(paused: bool):
	if paused:
		unlock_timer.stop()
	else:
		unlock_timer.start()
