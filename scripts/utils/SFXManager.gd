extends Node

var sfx_pool = {}
var player_pool = []

func _ready():
    # 预加载音效
    sfx_pool["button_click"] = preload("res://assets/audio/sfx/button_click.wav")
    sfx_pool["footstep"] = preload("res://assets/audio/sfx/footstep.wav")

    # 初始化播放器池
    var pool_size = 10 if OS.get_processor_count() > 4 else 5  # 动态池大小
    for i in pool_size:
        var player = AudioStreamPlayer2D.new()
        player.bus = "SFX"
        add_child(player)
        player_pool.append(player)

func play_sfx(type: String, position: Vector2, volume_db: float = 0.0):
    var stream = sfx_pool.get(type)
    if not stream:
        push_error("SFX type not found: " + type)
        return

    var player = _get_available_player()
    if not player:
        push_warning("No available audio player")
        return

    player.stream = stream
    player.position = position
    player.volume_db = volume_db + randf_range(-3, 3)  # 随机化
    player.play()

func _get_available_player() -> AudioStreamPlayer2D:
    for player in player_pool:
        if not player.playing:
            return player
    return player_pool[0]  # 复用最旧的

func _exit_tree():
    # 清理音频池
    for player in player_pool:
        player.queue_free()
    player_pool.clear()
    sfx_pool.clear()
