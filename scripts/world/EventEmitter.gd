extends Node2D
class_name EventEmitter

# 信号
signal event_triggered(event_id: String, emitter: EventEmitter)

# 导出变量
@export var event_id: String = "default_event"
@export var trigger_radius: float = 50.0
@export var cooldown_time: float = 10.0
@export var auto_trigger: bool = true  # 是否自动触发
@export var one_time: bool = false  # 是否一次性触发

# 内部变量
var is_active: bool = true
var last_trigger_time: float = 0.0
var trigger_area: Area2D
var cooldown_timer: Timer

func _ready():
	_setup_trigger_area()
	_setup_cooldown_timer()

# 设置触发区域
func _setup_trigger_area():
	trigger_area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = trigger_radius
	
	collision_shape.shape = circle_shape
	trigger_area.add_child(collision_shape)
	add_child(trigger_area)
	
	# 连接信号
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

# 设置冷却计时器
func _setup_cooldown_timer():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(cooldown_timer)

# 玩家进入触发区域
func _on_body_entered(body: Node2D):
	if not is_active or not auto_trigger:
		return
	
	if body.is_in_group("player"):
		_try_trigger_event()

# 玩家离开触发区域
func _on_body_exited(body: Node2D):
	pass  # 可以添加离开逻辑

# 尝试触发事件
func _try_trigger_event():
	if not _can_trigger():
		return
	
	last_trigger_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
	
	event_triggered.emit(event_id, self)
	
	if one_time:
		is_active = false
	else:
		cooldown_timer.start(cooldown_time)

# 检查是否可以触发
func _can_trigger() -> bool:
	if not is_active:
		return false
	
	if cooldown_timer.is_stopped():
		return true
	
	return false

# 冷却完成
func _on_cooldown_finished():
	pass  # 可以添加视觉反馈

# 手动触发事件
func trigger_event():
	_try_trigger_event()

# 激活/停用发射器
func set_active(active: bool):
	is_active = active

# 更新触发半径
func set_trigger_radius(radius: float):
	trigger_radius = radius
	if trigger_area and trigger_area.get_child(0) is CollisionShape2D:
		var shape = trigger_area.get_child(0).shape as CircleShape2D
		if shape:
			shape.radius = radius

# 获取当前状态
func get_status() -> Dictionary:
	return {
		"active": is_active,
		"cooldown_remaining": cooldown_timer.time_left if not cooldown_timer.is_stopped() else 0.0,
		"event_id": event_id
	}
