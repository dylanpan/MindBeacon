extends Node
class_name EventTriggerSystem

# 信号
signal event_started(event_id: String, position: Vector2)
signal event_completed(event_id: String, success: bool)

# 事件数据结构
class EventData:
	var id: String
	var type: String  # "immediate", "delayed"
	var description: String
	var weight: float
	var effects: Array[Callable]  # 效果函数数组
	var follow_up_events: Array[String]  # 后续事件ID
	var conditions: Array[Callable]  # 条件检查函数
	
	func _init(p_id: String = "", p_type: String = "immediate", p_desc: String = "", p_weight: float = 1.0):
		id = p_id
		type = p_type
		description = p_desc
		weight = p_weight
		effects = []
		follow_up_events = []
		conditions = []

# 导出变量
@export var base_event_weights: Dictionary = {
	"city_encounter": 1.0,
	"mood_change": 0.8,
	"plot_progress": 0.3
}

# 内部变量
var event_table: WeightedTable
var active_events: Dictionary = {}  # event_id: EventData
var event_emitters: Array[EventEmitter] = []
var atmosphere_influence: float = 0.0  # 氛围指数影响

func _ready():
	_initialize_event_table()
	_connect_signals()

# 初始化事件权重表
func _initialize_event_table():
	event_table = WeightedTable.new(base_event_weights)

# 连接信号
func _connect_signals():
	# 连接氛围指数变化信号（假设有全局事件总线）
	if EventBus.has_signal("atmosphere_changed"):
		EventBus.atmosphere_changed.connect(_on_atmosphere_changed)

# 氛围指数变化回调
func _on_atmosphere_changed(new_atmosphere: float):
	atmosphere_influence = new_atmosphere
	_update_event_weights()

# 更新事件权重基于氛围
func _update_event_weights():
	var adjusted_weights = base_event_weights.duplicate()
	
	# 高氛围指数增加正面事件
	if atmosphere_influence > 0.5:
		adjusted_weights["city_encounter"] *= 1.2
		adjusted_weights["mood_change"] *= 0.8
	# 低氛围指数增加负面事件
	elif atmosphere_influence < -0.5:
		adjusted_weights["city_encounter"] *= 0.8
		adjusted_weights["mood_change"] *= 1.3
	
	event_table.set_weights(adjusted_weights)

# 在指定位置触发事件
func trigger_event(position: Vector2) -> String:
	var event_id = event_table.select_random()
	if event_id == null:
		return ""
	
	var event_data = _get_event_data(event_id)
	if event_data == null:
		return ""
	
	# 检查条件
	if not _check_event_conditions(event_data):
		return ""
	
	# 创建事件发射器
	var emitter = EventEmitter.new()
	emitter.event_id = event_id
	emitter.position = position
	emitter.event_triggered.connect(_on_emitter_triggered)
	
	# 添加到场景
	get_tree().current_scene.add_child(emitter)
	event_emitters.append(emitter)
	
	active_events[event_id] = event_data
	event_started.emit(event_id, position)
	
	return event_id

# 获取事件数据（可以扩展为从配置文件加载）
func _get_event_data(event_id: String) -> EventData:
	var data = EventData.new()
	data.id = event_id
	
	match event_id:
		"city_encounter":
			data.type = "immediate"
			data.description = "遇到城市居民"
			data.effects.append(_effect_city_encounter)
		"mood_change":
			data.type = "delayed"
			data.description = "城市氛围变化"
			data.effects.append(_effect_mood_change)
		"plot_progress":
			data.type = "immediate"
			data.description = "剧情推进事件"
			data.effects.append(_effect_plot_progress)
	
	return data

# 检查事件条件
func _check_event_conditions(event_data: EventData) -> bool:
	for condition in event_data.conditions:
		if not condition.call():
			return false
	return true

# 发射器触发事件
func _on_emitter_triggered(event_id: String, emitter: EventEmitter):
	var event_data = active_events.get(event_id)
	if event_data == null:
		return
	
	# 执行效果
	for effect in event_data.effects:
		effect.call()
	
	# 触发后续事件
	for follow_up_id in event_data.follow_up_events:
		trigger_event(emitter.position)
	
	event_completed.emit(event_id, true)
	
	# 清理发射器
	event_emitters.erase(emitter)
	emitter.queue_free()

# 事件效果函数
func _effect_city_encounter():
	# 实现城市遭遇效果
	print("City encounter triggered")

func _effect_mood_change():
	# 实现氛围变化效果
	print("Mood change triggered")

func _effect_plot_progress():
	# 实现剧情推进效果
	print("Plot progress triggered")

# 添加自定义事件
func add_event(event_data: EventData):
	active_events[event_data.id] = event_data
	event_table.add_item(event_data.id, event_data.weight)

# 移除事件
func remove_event(event_id: String):
	if active_events.has(event_id):
		active_events.erase(event_id)
		event_table.remove_item(event_id)

# 暂停/恢复事件系统
func set_paused(paused: bool):
	for emitter in event_emitters:
		emitter.set_active(!paused)

# 清理所有活动事件
func clear_events():
	for emitter in event_emitters:
		emitter.queue_free()
	event_emitters.clear()
	active_events.clear()
