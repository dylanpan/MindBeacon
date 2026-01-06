extends Node

@onready var layered_music = $LayeredMusicSystem
@onready var sfx_manager = $SFXManager

func _ready():
    # 设置为单例
    if get_parent() == get_tree().root:
        # 自动初始化音频总线
        _setup_audio_buses()

func _setup_audio_buses():
    # 创建音频总线
    if AudioServer.get_bus_index("Music") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")

    if AudioServer.get_bus_index("SFX") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")

    # 创建音乐子总线
    if AudioServer.get_bus_index("Music/Ambient") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music/Ambient")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Music")

    if AudioServer.get_bus_index("Music/Melody") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music/Melody")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Music")

    if AudioServer.get_bus_index("Music/Percussion") == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music/Percussion")
        AudioServer.set_bus_send(AudioServer.bus_count - 1, "Music")
