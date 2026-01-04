extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array = []

func _ready():
    music_player = AudioStreamPlayer.new()
    add_child(music_player)

    # 创建音效播放器池
    for i in range(5):
        var player = AudioStreamPlayer.new()
        sfx_players.append(player)
        add_child(player)

func play_music(stream: AudioStream):
    music_player.stream = stream
    music_player.play()

func play_sfx(stream: AudioStream, volume_db: float = 0.0):
    for player in sfx_players:
        if not player.playing:
            player.stream = stream
            player.volume_db = volume_db
            player.play()
            break

func stop_music():
    music_player.stop()
