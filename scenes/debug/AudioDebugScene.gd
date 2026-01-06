extends Control

@onready var psychology_slider = $SimulatorPanel/PsychologySlider
@onready var spectrum_rect = $SpectrumPanel/SpectrumRect
@onready var debug_text = $DebugPanel/DebugText

var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var layered_music: LayeredMusicSystem

func _ready():
    spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
    var master_bus = AudioServer.get_bus_index("Master")
    if master_bus >= 0:
        AudioServer.add_bus_effect(master_bus, spectrum_analyzer)

    # 获取LayeredMusicSystem引用（假设为单例）
    layered_music = AudioManager.layered_music
    psychology_slider.connect("value_changed", _on_psychology_changed)

func _process(delta):
    _update_spectrum()
    _update_debug_info()

func _update_spectrum():
    var spectrum = spectrum_analyzer.get_magnitude_for_frequency_range(0, 22050)
    spectrum_rect.queue_redraw()

func _draw():
    var width = spectrum_rect.size.x
    var height = spectrum_rect.size.y
    var spectrum = spectrum_analyzer.get_magnitude_for_frequency_range(0, 22050)

    for i in range(spectrum.size()):
        var x = (i / float(spectrum.size())) * width
        var y = height - (spectrum[i].length() * height * 10)  # 放大显示
        var color = Color(0, 1, 0) if i < spectrum.size() / 3 else Color(1, 1, 0) if i < 2 * spectrum.size() / 3 else Color(1, 0, 0)
        draw_line(Vector2(x, height), Vector2(x, y), color, 2.0)

func _on_psychology_changed(value: float):
    if layered_music:
        layered_music._on_psychology_changed(value)

func _update_debug_info():
    var info = "Audio Debug Info:\n"
    info += "Bus Count: %d\n" % AudioServer.bus_count
    info += "CPU Usage: %.2f%%\n" % (AudioServer.get_bus_peak_volume_left_db(0) * 100)
    info += "Memory: %d KB\n" % (OS.get_static_memory_usage() / 1024)
    debug_text.text = info
