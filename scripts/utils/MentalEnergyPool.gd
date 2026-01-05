class_name MentalEnergyPool
extends Node

const POOL_SIZE = 100
var orb_pool: Array = []
var orb_scene = preload("res://scenes/gameplay/MentalEnergyOrb.tscn")

func _ready():
    initialize_pool()

func initialize_pool():
    for i in POOL_SIZE:
        var orb = orb_scene.instantiate()
        orb.visible = false
        orb_pool.append(orb)
        add_child(orb)

func get_orb() -> Node:
    for orb in orb_pool:
        if not orb.visible:
            orb.visible = true
            return orb
    # 如果池已满，创建新实例
    var new_orb = orb_scene.instantiate()
    orb_pool.append(new_orb)
    add_child(new_orb)
    return new_orb

func spawn_energy(position: Vector2, type: int, value: float):
    var orb = get_orb()
    if orb:
        orb.global_position = position
        orb.energy_type = type
        orb.energy_value = value
        if orb.has_method("setup_visuals"):
            orb.setup_visuals()

func return_orb(orb: Node):
    if orb in orb_pool:
        orb.visible = false
        # 重置状态
        orb.energy_type = MentalEnergyOrb.EnergyType.POSITIVE
        orb.energy_value = 10.0
        orb.target_player = null
        orb.is_attracting = false
        if orb.has_method("setup_visuals"):
            orb.setup_visuals()

func get_active_count() -> int:
    var count = 0
    for orb in orb_pool:
        if orb.visible:
            count += 1
    return count

func clear_pool():
    for orb in orb_pool:
        if orb.visible:
            orb.queue_free()
    orb_pool.clear()
    initialize_pool()
