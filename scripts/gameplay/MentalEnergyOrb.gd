class_name MentalEnergyOrb
extends Area2D

enum EnergyType { POSITIVE, NEGATIVE }

@export var energy_type: EnergyType = EnergyType.POSITIVE
@export var energy_value: float = 10.0
@export var attraction_speed: float = 50.0

# 平衡常量
const ATTRACTION_RANGE = 100.0
const DECAY_TIME = 30.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var decay_timer: Timer = $DecayTimer

var target_player: Node2D = null
var is_attracting: bool = false

func _ready():
    # 设置视觉效果
    setup_visuals()

    # 连接信号
    body_entered.connect(_on_body_entered)
    if decay_timer:
        decay_timer.timeout.connect(_on_decay_timeout)
        decay_timer.start(DECAY_TIME)

    # 开始吸引力逻辑
    check_attraction()

func _physics_process(delta: float):
    if is_attracting and target_player:
        var direction = (target_player.global_position - global_position).normalized()
        global_position += direction * attraction_speed * delta

func setup_visuals():
    if not sprite or not particles:
        return

    match energy_type:
        EnergyType.POSITIVE:
            sprite.modulate = Color.GREEN
            particles.modulate = Color.GREEN
            particles.emission_rate = energy_value * 2
        EnergyType.NEGATIVE:
            sprite.modulate = Color.RED
            particles.modulate = Color.RED
            particles.emission_rate = energy_value

func _on_body_entered(body: Node2D):
    if body.is_in_group("player"):
        collect_energy(body)

func collect_energy(player: Node2D):
    match energy_type:
        EnergyType.POSITIVE:
            # 假设有HealingSystem
            if has_node("/root/HealingSystem"):
                var healing_system = get_node("/root/HealingSystem")
                if healing_system.has_method("add_healing_points"):
                    healing_system.add_healing_points(energy_value)
        EnergyType.NEGATIVE:
            handle_negative_energy(energy_value)

    # 播放收集效果
    play_collection_effect()

    # 通知系统
    if EventBus.has_signal("energy_collected"):
        EventBus.emit_signal("energy_collected", energy_type, energy_value)

    # 销毁节点
    queue_free()

func handle_negative_energy(value: float):
    # 负面能量处理逻辑
    # 例如：临时降低心理健康，或触发特殊事件
    if GameManager.instance and GameManager.instance.player_personality:
        GameManager.instance.player_personality.update_parameter("big5_neuroticism", value * 0.1)

func play_collection_effect():
    # 播放音效和粒子效果
    if AudioManager and AudioManager.has_method("play_sfx"):
        AudioManager.play_sfx("energy_collect")

    # 创建收集特效
    var effect_scene = load("res://scenes/effects/EnergyCollectEffect.tscn")
    if effect_scene:
        var effect = effect_scene.instantiate()
        effect.global_position = global_position
        get_parent().add_child(effect)

func _on_decay_timeout():
    # 开始衰减动画
    if sprite:
        var tween = create_tween()
        tween.tween_property(sprite, "modulate:a", 0.0, 5.0)
        tween.tween_callback(queue_free)

func check_attraction():
    # 检查是否应该吸引玩家
    var player = get_tree().get_first_node_in_group("player")
    if player and global_position.distance_to(player.global_position) < ATTRACTION_RANGE:
        target_player = player
        is_attracting = true
