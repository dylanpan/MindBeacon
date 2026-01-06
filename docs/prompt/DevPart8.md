### 音频系统实现Prompt

#### 整体架构概述

音频系统作为游戏的核心支撑模块，负责提供沉浸式的听觉体验。主要分为两个子系统：音乐分层系统和交互音效管理。系统设计遵循Godot引擎的音频架构，通过AudioBus进行音量混合和效果处理，实现动态音频适应游戏状态。重点关注心理状态对音乐的实时影响，以及位置音效的空间感营造。

#### 子系统详细分析

__1. 音乐分层系统 (LayeredMusicSystem)__

- __核心机制__：采用多层音频播放器叠加播放，实现丰富音乐层次。每个AudioStreamPlayer负责独立音轨（如背景旋律、和声、节奏），通过AudioBus进行最终混音输出。

- __动态调整实现__：基于角色心理状态实时修改音频参数，包括音量、播放速度、滤波效果。系统监听Personality类的参数变化，映射到音频总线效果器。

- __技术实现要点__：

  - 使用Tween节点实现平滑音量过渡，避免突兀切换
  - AudioBus配置包含Reverb、EQ、Compressor等效果器
  - 内存优化：循环播放避免重复加载大文件

__补充实现细节__：

- __音频总线配置__：创建Master、Music、SFX三个主总线，Music总线下设Ambient、Melody、Percussion子总线
- __状态映射算法__：心理健康值(0-100)线性映射到音乐能量系数(0.3-1.5)，影响整体音量和滤波强度
- __音频资源管理__：音频文件按类型组织在assets/audio/目录下（music/ambient.ogg, sfx/button_click.wav），配置音频压缩格式（优先OGG/MP3，WAV仅短音效）
- __跨平台兼容性__：检测设备音频能力，动态调整音频池大小和压缩质量

__代码示例__（GDScript）：

```gdscript
# LayeredMusicSystem.gd
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
```

__2. 交互音效管理 (SFXManager)__

- __核心机制__：维护音效资源池，通过位置音频播放器实现空间音效。预加载机制减少播放延迟，支持2D/3D音频混合。

- __播放策略__：使用AudioStreamPlayer2D绑定场景节点，音效随对象移动。支持随机化音调和音量增加真实感。

- __技术实现要点__：

  - 对象池管理AudioStreamPlayer2D实例
  - 音效分类：UI反馈、环境音效、角色动作音效
  - 性能优化：距离衰减和优先级队列

__补充实现细节__：

- __音效池设计__：Dictionary存储预加载的AudioStream，键为音效类型，值为Array[AudioStream]
- __位置播放逻辑__：计算听者到音源距离，应用衰减公式：volume = max_volume / (1 + distance * attenuation)
- __音频池大小配置__：根据设备性能动态调整player_pool大小（低端设备5个，高性能10个以上）
- __错误处理__：音频播放失败时的fallback机制，记录错误日志但不中断游戏流程

__代码示例__（GDScript）：

```gdscript
# SFXManager.gd
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
```

#### 系统集成说明

- __与事件系统联动__：EventEmitter触发音效播放，EventTriggerSystem调用SFXManager.play_sfx()
- __治愈时刻个性化音乐__：在HealingSystem完成时，LayeredMusicSystem生成基于角色人格的音乐序列，使用算法合成器或预设音乐片段组合
- __跨场景音频连续性__：通过单例模式保持音乐播放，场景切换时平滑过渡
- __AudioManager主控制器__：作为音频系统单例管理器，在GameManager启动时优先初始化，负责创建音频总线和子系统实例
- __性能监控__：统计音频CPU占用和内存使用，提供调试接口

#### 待实现UI/场景补充说明

##### 1. 音频设置UI (AudioSettingsUI) 实现补充

- __UI结构设计__：继承Control节点，布局使用VBoxContainer垂直排列。顶部标题Label，中间设置区域ScrollContainer，底部应用/取消Button组。
- __音量控制__：三个HSlider分别绑定Master/Music/SFX AudioBus音量，范围-60dB到+6dB，实时更新AudioServer.bus_volume_db。
- __效果器开关__：CheckButton控制Reverb/Compressor启用状态，通过AudioEffect实例动态添加/移除。
- __预设选项__：OptionButton提供"默认"、"沉浸"、"游戏"、"静音"预设，一键应用音量组合。
- __集成方式__：作为MainUI子节点，通过信号连接UIManager.show_audio_settings()显示。保存设置到配置文件。
- __文件路径__：scenes/ui/AudioSettingsUI.tscn，脚本scenes/ui/AudioSettingsUI.gd
- __错误处理__：音频总线不存在时的安全检查，配置文件读取失败的默认值处理

__代码结构__：

```gdscript
# AudioSettingsUI.gd
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
```

##### 2. 音频调试场景 (AudioDebugScene) 实现补充

- __场景节点结构__：Scene根节点Control，包含心理状态模拟器Panel，频谱分析器TextureRect，音乐层控制Panel。
- __心理状态模拟器__：HSlider模拟心理健康值(0-100)，实时调用LayeredMusicSystem._on_psychology_changed()。
- __频谱显示__：使用AudioEffectSpectrumAnalyzer获取频率数据，绘制实时频谱图。显示低频/中频/高频能量条。
- __音乐层测试__：Button组控制各AudioStreamPlayer播放/暂停，Label显示当前状态和参数。
- __调试输出__：TextEdit显示音频总线信息，内存使用情况，播放统计。
- __场景文件__：scenes/debug/AudioDebugScene.tscn，脚本scenes/debug/AudioDebugScene.gd
- __文件依赖__：需要LayeredMusicSystem实例引用，调试时通过SceneTree切换
- __性能监控__：实时显示音频CPU使用率和内存占用

__代码结构__：

```gdscript
# AudioDebugScene.gd
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
```

##### 3. 场景音频集成实现补充

- __Portal节点音频__：在Portal.gd添加_audio_play()方法，穿越时调用AudioManager.sfx_manager.play_sfx("portal_enter", global_position)。支持不同界别音效变体（physical界门关闭音，mental界开放音）。

- __RegionArea音频__：扩展RegionArea.gd，进入区域时触发AudioManager.layered_music.switch_region_music(region_type)，使用Tween过渡到新音乐。退出时淡出当前音乐。

- __MentalEnergyOrb音频__：在MentalEnergyOrb.gd收集时播放"energy_collect"音效，音量基于收集能量量级（energy_amount * 0.1）。正面能量高音调，负面能量低音调。

- __环境音频触发__：为关键场景节点添加Area2D检测器，玩家接近时播放环境音效（如风声、水声、远处回音）。使用距离检测避免重复播放。

- __治愈场景音频__：在HealingSystem.gd开始治愈时生成个性化音乐序列（基于Personality参数选择音乐模板），结束时播放完成音效。集成EventBus信号触发。

- __文件修改清单__：

  - scripts/world/Portal.gd：添加_audio_play()方法
  - scripts/gameplay/RegionArea.gd：添加区域音乐切换
  - scripts/gameplay/MentalEnergyOrb.gd：添加收集音效
  - scripts/characters/HealingSystem.gd：添加治愈音乐序列

#### Git管理操作

音频系统相关文件创建后：

```bash
git add scripts/utils/AudioManager.gd
git add scripts/utils/LayeredMusicSystem.gd
git add scripts/utils/SFXManager.gd
git add scenes/ui/AudioSettingsUI.tscn
git add scenes/ui/AudioSettingsUI.gd
git add scenes/debug/AudioDebugScene.tscn
git add scenes/debug/AudioDebugScene.gd
git commit -m "Implement complete audio system with dynamic music and spatial SFX

- Add LayeredMusicSystem for psychological state-responsive music layers
- Add SFXManager for positional sound effects with object pooling
- Add AudioManager as central audio controller with bus management
- Add AudioSettingsUI for volume and effect controls
- Add AudioDebugScene for testing and monitoring
- Integrate audio triggers in Portal, RegionArea, MentalEnergyOrb, and HealingSystem"
```
