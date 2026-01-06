extends Node

const SAVE_PATH = "user://saves/game_save.cfg"
const SAVE_VERSION = 1

# 改进加密模式使用CBC
const KEY = "your_32_byte_key_here123456789012"  # 32字节密钥
const IV = "your_16_byte_iv12"  # 16字节初始化向量

class SaveData:
    var version: int = SAVE_VERSION
    var player_data: Dictionary
    var game_progress: Dictionary
    var timestamp: int

    func to_dict() -> Dictionary:
        return {
            "version": version,
            "player": player_data,
            "game": game_progress,
            "timestamp": timestamp
        }

    func migrate_from_old_version(old_data: Dictionary) -> SaveData:
        var new_save = SaveData.new()
        # 迁移逻辑
        if old_data.has("version") and old_data.version < SAVE_VERSION:
            # 执行迁移
            pass
        return new_save

func _ready():
    # 确保保存目录存在
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("saves"):
        dir.make_dir("saves")

func save_game(slot: int = 0):
    var save_data = _collect_save_data()

    # 序列化数据
    var json_data = JSON.stringify(save_data.to_dict())

    # AES加密
    var encrypted_data = encrypt_data(json_data.to_utf8())

    # 保存到文件
    var file_path = SAVE_PATH + str(slot)
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_buffer(encrypted_data)
        file.close()

        # 创建备份
        _create_backup(file_path)
        print("Game saved to slot: ", slot)
    else:
        print("Failed to save game: ", FileAccess.get_open_error())

func load_game(slot: int = 0) -> SaveData:
    return load_game_with_backup(slot)

func load_game_with_backup(slot: int = 0) -> SaveData:
    var primary_path = SAVE_PATH + str(slot)
    var backup_path = primary_path + ".bak"

    # 尝试加载主存档
    var data = _load_from_file(primary_path)
    if data == null and FileAccess.file_exists(backup_path):
        # 加载备份
        data = _load_from_file(backup_path)
        if data:
            print("Loaded from backup for slot: ", slot)

    return data

func _load_from_file(file_path: String) -> SaveData:
    if not FileAccess.file_exists(file_path):
        return null

    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        return null

    var encrypted_data = file.get_buffer(file.get_length())
    file.close()

    # AES解密
    var decrypted_data = decrypt_data(encrypted_data)
    if decrypted_data.is_empty():
        return null

    var json_string = decrypted_data.get_string_from_utf8()
    var parsed_data = JSON.parse_string(json_string)

    if parsed_data == null:
        return null

    return _dict_to_save_data(parsed_data)

func encrypt_data(data: PackedByteArray) -> PackedByteArray:
    var crypto = Crypto.new()
    return crypto.encrypt(Crypto.AES_MODE_CBC, KEY.to_utf8(), IV.to_utf8(), data)

func decrypt_data(encrypted: PackedByteArray) -> PackedByteArray:
    var crypto = Crypto.new()
    return crypto.decrypt(Crypto.AES_MODE_CBC, KEY.to_utf8(), IV.to_utf8(), encrypted)

func save_game_async(slot: int = 0) -> void:
    var thread = Thread.new()
    thread.start(Callable(self, "_save_worker").bind(slot))

func _save_worker(slot: int):
    save_game(slot)
    call_deferred("_on_save_completed", slot)

func _on_save_completed(slot: int):
    print("Async save completed for slot: ", slot)

func setup_auto_save():
    var timer = Timer.new()
    timer.name = "AutoSaveTimer"
    timer.wait_time = ConfigManager.instance.get_int("system_config", "save_system/auto_save_interval", 900)  # 15分钟
    timer.one_shot = false
    timer.connect("timeout", Callable(self, "_on_auto_save_timeout"))
    add_child(timer)
    timer.start()

func _on_auto_save_timeout():
    if GameManager.instance and GameManager.instance.current_state == GameManager.GameState.PLAYING:
        save_game_async()

func get_available_slots() -> Array:
    var slots = []
    for i in range(3):  # 3个存档槽位
        var path = SAVE_PATH + str(i)
        if FileAccess.file_exists(path):
            slots.append({
                "slot": i,
                "exists": true,
                "timestamp": _get_save_timestamp(path)
            })
        else:
            slots.append({"slot": i, "exists": false})
    return slots

func _get_save_timestamp(file_path: String) -> int:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        # 这里可以从文件头读取时间戳，或者使用文件修改时间
        return FileAccess.get_modified_time(file_path)
    return 0

func _collect_save_data() -> SaveData:
    var save_data = SaveData.new()
    save_data.timestamp = Time.get_unix_time_from_system()

    # 收集玩家数据（需要根据实际游戏数据调整）
    save_data.player_data = {
        "health": 100,
        "energy": 50,
        "level": 1
    }

    # 收集游戏进度
    save_data.game_progress = {
        "last_save_time": save_data.timestamp,
        "areas_unlocked": [],
        "buildings": []
    }

    return save_data

func _dict_to_save_data(data: Dictionary) -> SaveData:
    var save_data = SaveData.new()
    save_data.version = data.get("version", 1)
    save_data.player_data = data.get("player", {})
    save_data.game_progress = data.get("game", {})
    save_data.timestamp = data.get("timestamp", 0)

    # 版本迁移
    if save_data.version < SAVE_VERSION:
        save_data = save_data.migrate_from_old_version(data)

    return save_data

func _create_backup(file_path: String):
    var backup_path = file_path + ".bak"
    var dir = DirAccess.open("user://")
    dir.copy(file_path, backup_path)

# 辅助方法（供其他系统调用）
func get_player_stat(stat_name: String):
    # 从当前存档获取玩家数据
    var current_save = load_game()
    if current_save:
        return current_save.player_data.get(stat_name, 0)
    return 0

func get_buildings():
    # 获取建筑数据
    var current_save = load_game()
    if current_save:
        return current_save.game_progress.get("buildings", [])
    return []
