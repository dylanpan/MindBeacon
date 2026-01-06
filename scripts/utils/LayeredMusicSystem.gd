extends Node

@onready var ambient_player = $AmbientPlayer
@onready var melody_player = $MelodyPlayer
@onready var percussion_player = $PercussionPlayer

func _ready():
    # 设置总线
    ambient_player.bus = "Music/Ambient"
    melody_player.bus = "Music/Melody"
    percussion_player.bus = "Music/Percussion"

    # 连接心理状态信号
    EventBus.connect("psychology_changed", _on_psychology_changed)

    # 设置循环播放
    for player in [ambient_player, melody_player, percussion_player]:
        player.stream.loop = true

func _on_psychology_changed(health_value: float):
    var energy = lerp(0.3, 1.5, health_value / 100.0)
    var tween = create_tween()
    tween.tween_property(ambient_player, "volume_db", -20 + energy * 10, 2.0)
    tween.parallel().tween_property(melody_player, "pitch_scale", 0.8 + energy * 0.4, 2.0)
    tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
    # 过渡完成后的处理
    pass

func switch_region_music(region_type: String):
    # 区域音乐切换逻辑
    match region_type:
        "forest":
            ambient_player.stream = preload("res://assets/audio/music/forest_ambient.ogg")
        "city":
            ambient_player.stream = preload("res://assets/audio/music/city_ambient.ogg")
    ambient_player.play()
