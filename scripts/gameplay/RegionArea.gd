class_name RegionArea
extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var region_mood: float = 0.5
var npc_list: Array = []
var update_timer: Timer

func _ready():
    # 连接信号
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    # 设置更新定时器
    update_timer = Timer.new()
    update_timer.wait_time = 5.0  # 每5秒更新一次
    update_timer.timeout.connect(_on_update_timer_timeout)
    add_child(update_timer)
    update_timer.start()

    # 注册到GameManager
    if GameManager.instance:
        GameManager.instance.region_areas.append(self)

func _on_body_entered(body: Node2D):
    if body.is_in_group("player"):
        if GameManager.instance:
            GameManager.instance.update_city_mood_index(region_mood)
        # 触发区域音乐切换
        switch_region_music()
        # 触发区域特效
        play_region_effect()

func _on_body_exited(body: Node2D):
    if body.is_in_group("player"):
        # 淡出区域音乐
        fade_out_region_music()

func _on_update_timer_timeout():
    update_region_mood()

func update_region_mood():
    if npc_list.is_empty():
        region_mood = 0.5  # 默认中性氛围
        return

    var total_health = 0.0
    for npc in npc_list:
        if npc.has_method("get_personality") and npc.get_personality():
            total_health += npc.get_personality().mental_health

    region_mood = total_health / npc_list.size() / 100.0
    region_mood = clamp(region_mood, 0.0, 1.0)

func add_npc(npc: Node2D):
    if not npc_list.has(npc):
        npc_list.append(npc)

func remove_npc(npc: Node2D):
    npc_list.erase(npc)

func play_region_effect():
    # 播放区域进入音效或视觉效果
    # TODO: 实现区域特效
    pass

func switch_region_music():
    var region_type = "default"
    if region_mood < 0.3:
        region_type = "dark"
    elif region_mood < 0.7:
        region_type = "neutral"
    else:
        region_type = "bright"

    if AudioManager and AudioManager.layered_music:
        AudioManager.layered_music.switch_region_music(region_type)

func fade_out_region_music():
    # 使用Tween淡出当前区域音乐
    if AudioManager and AudioManager.layered_music:
        var tween = create_tween()
        tween.tween_property(AudioManager.layered_music, "volume_db", -60.0, 2.0)
        tween.finished.connect(_on_music_fade_out_finished)

func _on_music_fade_out_finished():
    # 恢复默认音乐或停止
    if AudioManager and AudioManager.layered_music:
        AudioManager.layered_music.volume_db = 0.0
