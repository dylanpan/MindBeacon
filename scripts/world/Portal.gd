extends Area2D
class_name Portal

# 信号
signal portal_activated(portal: Portal, player: Node2D)
signal portal_enter_attempted(portal: Portal, player: Node2D, success: bool)

# 导出变量
@export var target_world_id: int = 1
@export var required_energy: float = 0.0  # 进入所需能量
@export var portal_name: String = "Portal"
@export var auto_activate: bool = true  # 是否自动激活
@export var one_way: bool = false  # 是否单向传送
@export var cooldown_time: float = 2.0  # 使用冷却时间

# 内部变量
var is_active: bool = true
var last_use_time: float = 0.0
var portal_sprite: Sprite2D
var animation_player: AnimationPlayer
var cooldown_timer: Timer

func _ready():
	_setup_visuals()
	_setup_collision()
	_setup_cooldown_timer()
	_connect_signals()

# 设置视觉效果
func _setup_visuals():
	# 添加精灵
	portal_sprite = Sprite2D.new()
	portal_sprite.texture = preload("res://assets/sprites/ui/portal.png")  # 假设有传送门贴图
	portal_sprite.modulate = Color(0.5, 0.8, 1.0, 0.8)  # 半透明蓝色
	add_child(portal_sprite)
	
	# 添加动画播放器
	animation_player = AnimationPlayer.new()
	add_child(animation_player)
	
	# 创建闪烁动画
	var animation = Animation.new()
	var track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, "Portal:modulate:a")
	animation.track_insert_key(track, 0.0, 0.6)
	animation.track_insert_key(track, 0.5, 1.0)
	animation.track_insert_key(track, 1.0, 0.6)
	animation.length = 1.0
	animation.loop = true
	
	animation_player.add_animation("idle", animation)
	animation_player.play("idle")

# 设置碰撞区域
func _setup_collision():
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 32.0  # 传送门半径
	collision_shape.shape = circle_shape
	add_child(collision_shape)

# 设置冷却计时器
func _setup_cooldown_timer():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(cooldown_timer)

# 连接信号
func _connect_signals():
	body_entered.connect(_on_body_entered)

# 玩家进入传送门
func _on_body_entered(body: Node2D):
	if not is_active or not auto_activate:
		return
	
	if body.is_in_group("player"):
		_attempt_portal_use(body)

# 尝试使用传送门
func _attempt_portal_use(player: Node2D):
	var can_use = _check_usage_conditions(player)
	
	portal_enter_attempted.emit(self, player, can_use)
	
	if can_use:
		_activate_portal(player)
	else:
		_play_denied_effect()

# 检查使用条件
func _check_usage_conditions(player: Node2D) -> bool:
	# 检查冷却
	if Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"] - last_use_time < cooldown_time:
		return false
	
	# 检查能量要求
	if required_energy > 0:
		if MentalEnergyPool.get_total_energy() < required_energy:
			return false
	
	# 检查世界解锁状态
	var world_data = WorldData.new()
	if not world_data.is_world_unlocked(target_world_id):
		return false
	
	return true

# 激活传送门
func _activate_portal(player: Node2D):
	last_use_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
	
	# 消耗能量
	if required_energy > 0:
		MentalEnergyPool.consume_energy(required_energy)
	
	# 播放激活效果
	_play_activation_effect()
	
	# 发送激活信号
	portal_activated.emit(self, player)
	
	# 开始冷却
	cooldown_timer.start(cooldown_time)

# 播放激活效果
func _play_activation_effect():
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 16.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.gravity = Vector3(0, 0, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.color = Color(0.5, 0.8, 1.0)
	
	particles.process_material = material
	particles.amount = 20
	particles.lifetime = 0.5
	particles.one_shot = true
	
	add_child(particles)
	particles.emitting = true
	
	# 自动清理
	get_tree().create_timer(1.0).timeout.connect(func(): particles.queue_free())

# 播放拒绝效果
func _play_denied_effect():
	portal_sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(portal_sprite, "modulate", Color(0.5, 0.8, 1.0, 0.8), 0.5)

# 冷却完成
func _on_cooldown_finished():
	pass  # 可以添加视觉反馈

# 手动激活
func activate(player: Node2D = null):
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if player:
		_attempt_portal_use(player)

# 设置激活状态
func set_active(active: bool):
	is_active = active
	portal_sprite.visible = active
	set_deferred("monitoring", active)

# 更新目标世界
func set_target_world(world_id: int):
	target_world_id = world_id

# 获取传送门信息
func get_portal_info() -> Dictionary:
	return {
		"name": portal_name,
		"target_world": target_world_id,
		"required_energy": required_energy,
		"active": is_active,
		"cooldown_remaining": cooldown_timer.time_left if not cooldown_timer.is_stopped() else 0.0
	}

# 更新视觉效果（基于状态）
func _update_visuals():
	if not is_active:
		portal_sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	else:
		portal_sprite.modulate = Color(0.5, 0.8, 1.0, 0.8)
