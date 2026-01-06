extends Control

@onready var master_slider = $VBoxContainer/MasterSlider
@onready var music_slider = $VBoxContainer/MusicSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider
@onready var reverb_toggle = $VBoxContainer/ReverbToggle
@onready var preset_option = $VBoxContainer/PresetOption

func _ready():
    _load_settings()
    master_slider.connect("value_changed", _on_master_changed)
    music_slider.connect("value_changed", _on_music_changed)
    sfx_slider.connect("value_changed", _on_sfx_changed)
    reverb_toggle.connect("toggled", _on_reverb_toggled)
    preset_option.connect("item_selected", _on_preset_selected)

func _load_settings():
    var config = ConfigFile.new()
    var err = config.load("user://audio_settings.cfg")
    if err == OK:
        master_slider.value = config.get_value("audio", "master_volume", 0.0)
        music_slider.value = config.get_value("audio", "music_volume", 0.0)
        sfx_slider.value = config.get_value("audio", "sfx_volume", 0.0)
        reverb_toggle.button_pressed = config.get_value("audio", "reverb_enabled", true)
    else:
        # 默认设置
        master_slider.value = 0.0
        music_slider.value = 0.0
        sfx_slider.value = 0.0
        reverb_toggle.button_pressed = true

func _on_master_changed(value: float):
    var bus_idx = AudioServer.get_bus_index("Master")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, value)

func _on_music_changed(value: float):
    var bus_idx = AudioServer.get_bus_index("Music")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, value)

func _on_sfx_changed(value: float):
    var bus_idx = AudioServer.get_bus_index("SFX")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, value)

func _on_reverb_toggled(enabled: bool):
    var bus_idx = AudioServer.get_bus_index("Music")
    if bus_idx >= 0:
        var effect_idx = AudioServer.get_bus_effect_index(bus_idx, "Reverb")
        if effect_idx >= 0:
            AudioServer.set_bus_effect_enabled(bus_idx, effect_idx, enabled)

func _on_preset_selected(index: int):
    match index:
        0: # 默认
            master_slider.value = 0.0
            music_slider.value = 0.0
            sfx_slider.value = 0.0
        1: # 沉浸
            master_slider.value = 3.0
            music_slider.value = 6.0
            sfx_slider.value = -3.0
        2: # 游戏
            master_slider.value = 0.0
            music_slider.value = -6.0
            sfx_slider.value = 6.0
        3: # 静音
            master_slider.value = -60.0

func _save_settings():
    var config = ConfigFile.new()
    config.set_value("audio", "master_volume", master_slider.value)
    config.set_value("audio", "music_volume", music_slider.value)
    config.set_value("audio", "sfx_volume", sfx_slider.value)
    config.set_value("audio", "reverb_enabled", reverb_toggle.button_pressed)
    config.save("user://audio_settings.cfg")
