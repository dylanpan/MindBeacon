extends Node
class_name WorldLayerManager

# 枚举定义
enum WORLD_TYPE { REALITY = 0, MENTAL = 1, MEMORY = 2 }

# 信号
signal world_switched(from_world: int, to_world: int)
signal world_loading_started(world_id: int)
signal world_loading_completed(world_id: int)

# 导出变量
@export var world_container_path: NodePath  # 世界容器节点路径
@export var transition_duration: float = 1.0  # 切换过渡时间

# 内部变量
var current_world_id: int = WORLD_TYPE.REALITY
var world_scenes: Dictionary = {}  # world_id: PackedScene
var active_world_instances: Dictionary = {}  # world_id: Node
var world_container: Node
var is_transitioning: bool = false
var player_reference: Node2D  # 玩家节点引用
var transition_tween: Tween

func _ready():
	_initialize_world_container()
	_load_world_scenes()
	_spawn_initial_world()

# 初始化世界容器
func _initialize_world_container():
	if world_container_path:
		world_container = get_node(world_container_path)
	else:
		# 创建默认容器
		world_container = Node.new()
		world_container.name = "WorldContainer"
		add_child(world_container)

# 加载世界场景资源
func _load_world_scenes():
	# 从WorldData加载场景路径
	var world_data = WorldData.new()
	for config in world_data.worlds:
		var scene = load(config.scene_path) as PackedScene
		if scene:
			world_scenes[config.id] = scene
		else:
			push_error("Failed to load world scene: " + config.scene_path)

# 生成初始世界
func _spawn_initial_world():
	switch_world(current_world_id, false)  # 无过渡

# 切换世界
func switch_world(target_world_id: int, use_transition: bool = true):
	if is_transitioning or target_world_id == current_world_id:
		return
	
	is_transitioning = true
	var from_world = current_world_id
	
	if use_transition:
		_start_transition(from_world, target_world_id)
	else:
		_perform_world_switch(from_world, target_world_id)

# 执行世界切换
func _perform_world_switch(from_world: int, to_world: int):
	# 隐藏当前世界
	if active_world_instances.has(from_world):
		active_world_instances[from_world].visible = false
	
	# 显示或创建目标世界
	if not active_world_instances.has(to_world):
		_spawn_world(to_world)
	else:
		active_world_instances[to_world].visible = true
	
	# 更新当前世界ID
	current_world_id = to_world
	
	# 同步玩家位置和状态
	_sync_player_to_world(to_world)
	
	# 应用世界特效
	_apply_world_effects(to_world)
	
	# 保存世界状态
	_save_world_state(from_world)
	
	# 发送信号
	world_switched.emit(from_world, to_world)
	
	is_transitioning = false

# 生成世界实例
func _spawn_world(world_id: int):
	if not world_scenes.has(world_id):
		push_error("World scene not found for ID: " + str(world_id))
		return
	
	var scene = world_scenes[world_id]
	var instance = scene.instantiate()
	instance.name = "World_" + str(world_id)
	
	# 设置层级
	if world_id == WORLD_TYPE.REALITY:
		instance.z_index = 0
	elif world_id == WORLD_TYPE.MENTAL:
		instance.z_index = 1
	else:  # MEMORY
		instance.z_index = 2
	
	world_container.add_child(instance)
	active_world_instances[world_id] = instance
	
	# 隐藏初始状态
	instance.visible = false

# 开始过渡动画
func _start_transition(from_world: int, to_world: int):
	world_loading_started.emit(to_world)
	
	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	
	# 淡出当前世界
	if active_world_instances.has(from_world):
		var from_instance = active_world_instances[from_world]
		transition_tween.tween_property(from_instance, "modulate:a", 0.0, transition_duration * 0.5)
	
	# 中间延迟
	transition_tween.tween_interval(transition_duration * 0.5)
	
	# 执行切换
	transition_tween.tween_callback(_perform_world_switch.bind(from_world, to_world))
	
	# 淡入新世界
	transition_tween.tween_callback(func():
		if active_world_instances.has(to_world):
			var to_instance = active_world_instances[to_world]
			to_instance.modulate.a = 0.0
			transition_tween = create_tween()
			transition_tween.tween_property(to_instance, "modulate:a", 1.0, transition_duration * 0.5)
			transition_tween.tween_callback(func(): world_loading_completed.emit(to_world))
	)

# 同步玩家到世界
func _sync_player_to_world(world_id: int):
	if not player_reference:
		_find_player()
		return
	
	# 根据世界类型调整玩家属性
	match world_id:
		WORLD_TYPE.REALITY:
			player_reference.modulate = Color.WHITE
		WORLD_TYPE.MENTAL:
			player_reference.modulate = Color(0.8, 0.9, 1.0)  # 轻微蓝色调
		WORLD_TYPE.MEMORY:
			player_reference.modulate = Color(0.9, 0.8, 1.0)  # 轻微紫色调

# 应用世界特效
func _apply_world_effects(world_id: int):
	var world_data = WorldData.new()
	var config = world_data.get_world_config(world_id)
	
	if config and config.visual_filter:
		# 应用视觉滤镜（假设有全局相机系统）
		if CameraManager:
			CameraManager.apply_filter(config.visual_filter)
	
	# 播放世界背景音乐
	if config and config.theme_music:
		if AudioManager:
			AudioManager.play_world_music(config.theme_music)

# 保存世界状态
func _save_world_state(world_id: int):
	# 保存当前世界的状态到WorldData
	var world_data = WorldData.new()
	var state_data = {
		"player_position": player_reference.global_position if player_reference else Vector2.ZERO,
		"world_objects": {}  # 可以扩展保存世界中物体的状态
	}
	
	# 这里可以扩展保存逻辑
	print("World state saved for world: ", world_id)

# 查找玩家节点
func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0] as Node2D

# 设置玩家引用
func set_player_reference(player: Node2D):
	player_reference = player

# 获取当前世界实例
func get_current_world() -> Node:
	return active_world_instances.get(current_world_id)

# 检查世界是否已加载
func is_world_loaded(world_id: int) -> bool:
	return active_world_instances.has(world_id)

# 预加载世界
func preload_world(world_id: int):
	if not is_world_loaded(world_id):
		_spawn_world(world_id)

# 卸载世界
func unload_world(world_id: int):
	if active_world_instances.has(world_id) and world_id != current_world_id:
		active_world_instances[world_id].queue_free()
		active_world_instances.erase(world_id)

# 获取世界信息
func get_world_info(world_id: int) -> Dictionary:
	var world_data = WorldData.new()
	var config = world_data.get_world_config(world_id)
	
	if config:
		return {
			"name": config.name,
			"id": config.id,
			"unlocked": world_data.is_world_unlocked(world_id)
		}
	
	return {}

# 强制切换（用于调试）
func force_switch_world(world_id: int):
	current_world_id = world_id
	_perform_world_switch(current_world_id, world_id)
