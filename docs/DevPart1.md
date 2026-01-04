## 项目结构规划详细执行计划

### 阶段1: 项目初始化（预计时间：30分钟）

__1.1 Godot项目创建__

- 使用Godot编辑器创建新项目
- 项目名："MindBeacon"
- 位置：d:/Learing/X-MindBeacon
- 渲染器：2D
- 启用高级选项

__1.2 项目设置配置__

- Application/Config/Name: "MindBeacon"
- Application/Config/Version: "0.1.0"
- Display/Window/Size/Width: 1280
- Display/Window/Size/Height: 720
- Display/Window/Size/Resizable: false
- Physics/2D/Default_Gravity: 0
- Physics/2D/Default_Linear_Damp: 0.1
- Physics/2D/Default_Angular_Damp: 0.1

__1.3 project.godot文件验证__

- 确认config_version=5
- 确认project_name="MindBeacon"
- 准备Autoload配置

### 阶段2: 目录结构搭建（预计时间：20分钟）

__2.1 根目录文件创建__

- 创建.gitignore：

  ```javascript
  # Godot
  .godot/
  *.tmp
  *.import
  # Saves
  saves/
  *.save
  # Logs
  *.log
  ```

- 创建LICENSE（MIT）

- 创建.gdignore（空文件）

__2.2 assets/目录结构__

```javascript
assets/
├── sprites/
│   ├── characters/
│   ├── environments/
│   └── ui/
├── audio/
│   ├── music/
│   ├── sfx/
│   └── ambient/
├── fonts/
└── ui/
    ├── themes/
    └── icons/
```

__2.3 scenes/目录结构__

```javascript
scenes/
├── main/
│   ├── Main.tscn
│   ├── Menu.tscn
│   └── Loading.tscn
├── characters/
│   ├── Player.tscn
│   ├── NPC.tscn
│   └── Boss.tscn
├── environments/
│   ├── City.tscn
│   ├── MindSpace.tscn
│   └── Ruins.tscn
└── ui/
    ├── HUD.tscn
    ├── Dialog.tscn
    └── Menus.tscn
```

__2.4 scripts/目录结构__

```javascript
scripts/
├── core/
│   ├── GameManager.gd
│   ├── SaveSystem.gd
│   └── EventBus.gd
├── characters/
│   ├── Character.gd
│   ├── NPCController.gd
│   └── PlayerController.gd
├── gameplay/
│   ├── PsychologyModel.gd
│   ├── WorldManager.gd
│   └── HealingSystem.gd
├── ui/
│   ├── UIManager.gd
│   ├── MenuController.gd
│   └── DialogSystem.gd
└── utils/
    ├── MathUtils.gd
    ├── AudioManager.gd
    └── ConfigLoader.gd
```

__2.5 data/目录结构__

```javascript
data/
├── configs/
│   ├── game_config.json
│   ├── character_data.json
│   └── level_data.json
└── saves/
    ├── save_01.save
    └── metadata.json
```

__2.6 docs/目录结构__

```javascript
docs/
├── DevPlan.md
├── Architecture.md
├── ArtBible.md
└── SoundDesign.md
```

### 阶段3: 基础配置设置（预计时间：40分钟）

__3.1 输入映射配置__

- move_up: W
- move_down: S
- move_left: A
- move_right: D
- interact: E
- open_menu: Escape
- quick_save: F5

__3.2 渲染设置__

- Rendering/2D/Snap/Pixel_Snap: true
- Rendering/Anti_Aliasing/Quality/MSAA: 2
- Rendering/Viewport/Default_Clear_Color: Color(0.1, 0.1, 0.15, 1)

__3.3 Autoload单例配置__

- GameManager: res://scripts/core/GameManager.gd
- EventBus: res://scripts/core/EventBus.gd
- AudioManager: res://scripts/utils/AudioManager.gd

### 阶段4: 基础场景创建（预计时间：30分钟）

__4.1 Main.tscn场景__

- 根节点：Node2D，命名"Main"
- 添加CanvasLayer，命名"UI"
- 添加Node2D，命名"GameWorld"
- 添加Camera2D，命名"Camera"，设置current=true

__4.2 基础脚本创建__

- GameManager.gd：

  ```gdscript
  extends Node

  signal game_state_changed(new_state)
  enum GameState {MENU, PLAYING, PAUSED}

  var current_state = GameState.MENU

  func _ready():
      pass
  ```

- EventBus.gd：

  ```gdscript
  extends Node

  # 事件信号定义
  signal npc_healed(npc_id, amount)
  signal energy_collected(amount, type)
  signal area_unlocked(area_id)
  ```

- AudioManager.gd：

  ```gdscript
  extends Node

  var music_player: AudioStreamPlayer
  var sfx_players: Array = []

  func _ready():
      music_player = AudioStreamPlayer.new()
      add_child(music_player)
  ```

### 阶段5: 验证和测试（预计时间：20分钟）

__5.1 项目运行测试__

- 打开Main.tscn确保无错误
- 验证单例加载正常
- 检查控制台无警告

__5.2 Git仓库初始化__

- 执行git init
- 添加所有文件到暂存区
- 提交初始版本
