extends CharacterBody2D
class_name Player

# ==========================================
# 信号 (Signals)
# ==========================================
signal hp_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal radiation_changed(current: float, maximum: float)
signal player_died()

# ==========================================
# 节点引用
# ==========================================
@onready var animated_sprite = $AnimatedSprite2D
@onready var action_point = $ActionPoint

# ==========================================
# 基础属性配置
# ==========================================
@export var base_speed: float = 100.0  # 基础移动速度

# 准星距离玩家的像素距离 (Sprout Lands 的格子通常是 16x16)
const ACTION_DISTANCE: float = 16.0

# 预留给任务 1 的三个种族预设 (MVP 阶段先用 Enum 区分)
enum Species { CAT, BEAR, RABBIT }
@export var current_species: Species = Species.CAT

# ==========================================
# 生存属性
# ==========================================
@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var max_radiation: float = 100.0

var current_hp: float
var current_stamina: float
var current_radiation: float  # 0 = 健康，100 = 辐射病

# 每秒体力恢复速率
@export var stamina_regen_rate: float = 5.0
# 每秒体力消耗速率（跑步时）
@export var stamina_drain_rate: float = 10.0

# ==========================================
# 初始化
# ==========================================
func _ready() -> void:
    # 添加到 player 组，以便 HUD 可以找到
    add_to_group("player")
    
    # 初始化属性为最大值
    current_hp = max_hp
    current_stamina = max_stamina
    current_radiation = 0.0

# ==========================================
# 物理帧更新 (移动逻辑)
# ==========================================
func _physics_process(delta: float) -> void:
    # 获取键盘按键的方向 (使用自定义输入映射)
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    # 计算当前速度
    var current_speed = base_speed
    
    # 如果是猫科，移速基础增加
    if current_species == Species.CAT:
        current_speed *= 1.15 
    
    # 应用移动
    if input_dir != Vector2.ZERO:
        velocity = input_dir * current_speed
    else:
        # 如果没有按键，提供一个摩擦力平滑停止
        velocity = velocity.move_toward(Vector2.ZERO, current_speed)

    # Godot 4 专属移动函数，自带滑动检测
    move_and_slide()
    
    # 更新动画
    update_animation(input_dir)
    
    # 挖地/填地检测
    if Input.is_action_just_pressed("ui_accept"):
        dig_ground()
    if Input.is_key_pressed(KEY_B):
        build_ground()

# ==========================================
# 动画更新函数
# ==========================================
func update_animation(dir: Vector2) -> void:
    # 当 dir == Vector2.ZERO（松开键盘）时，不改变准星位置
    # 这样哪怕玩家停下来发呆，准星依然保留在最后面朝的方向
    if dir == Vector2.ZERO:
        animated_sprite.play("idle")
    else:
        if abs(dir.x) > abs(dir.y):
            # === 横向移动 ===
            if dir.x > 0:
                animated_sprite.play("walk_right")
                animated_sprite.flip_h = false
                # 面朝右，准星移到右边
                action_point.position = Vector2(ACTION_DISTANCE, 0)
            else:
                animated_sprite.play("walk_left")
                animated_sprite.flip_h = false
                # 面朝左，准星移到左边
                action_point.position = Vector2(-ACTION_DISTANCE, 0)
        else:
            # === 纵向移动 ===
            if dir.y > 0:
                animated_sprite.play("walk_down")
                # 面朝下，准星移到下边
                action_point.position = Vector2(0, ACTION_DISTANCE)
            else:
                animated_sprite.play("walk_up")
                # 面朝上，准星移到上边
                action_point.position = Vector2(0, -ACTION_DISTANCE)

# ==========================================
# 挖地功能 (将格子挖空)
# ==========================================
func dig_ground() -> void:
    var tilemap = get_parent().get_node_or_null("BaseLayer")
    if tilemap != null:
        var target_pos = action_point.global_position
        # 把绝对坐标转换成 TileMapLayer 自己的内部坐标
        var local_pos = tilemap.to_local(target_pos)
        var grid_pos = tilemap.local_to_map(local_pos)
        
        # 只要这里原本有东西（非空），就将其挖空 (-1)
        if tilemap.get_cell_source_id(grid_pos) != -1:
            tilemap.set_cell(grid_pos, -1)

# ==========================================
# 填地功能 (从空地恢复为地图原始形态)
# ==========================================
func build_ground() -> void:
    var tilemap = get_parent().get_node_or_null("BaseLayer")
    var map_root = get_parent()
    
    if tilemap != null and map_root.has_method("get_original_terrain"):
        var target_pos = action_point.global_position
        var local_pos = tilemap.to_local(target_pos)
        var grid_pos = tilemap.local_to_map(local_pos)
        
        # 只有在当前格子是空的时候，才允许填地恢复
        if tilemap.get_cell_source_id(grid_pos) == -1:
            # 向地图脚本请求该坐标最初的地形配置
            var original = map_root.get_original_terrain(grid_pos)
            if not original.is_empty():
                var source_id = original.get("source_id", -1)
                var atlas_coords = original.get("atlas_coords", Vector2i(0, 0))
                # 重新填回原始地形和对应的图集坐标
                tilemap.set_cell(grid_pos, source_id, atlas_coords)

# ==========================================
# 属性修改函数
# ==========================================

## 受到伤害
func take_damage(amount: float) -> void:
    current_hp = max(0.0, current_hp - amount)
    hp_changed.emit(current_hp, max_hp)
    
    if current_hp <= 0.0:
        player_died.emit()
        print("玩家死亡！")

## 恢复生命值
func heal(amount: float) -> void:
    current_hp = min(max_hp, current_hp + amount)
    hp_changed.emit(current_hp, max_hp)

## 消耗体力
func consume_stamina(amount: float) -> bool:
    if current_stamina < amount:
        return false  # 体力不足
    current_stamina = max(0.0, current_stamina - amount)
    stamina_changed.emit(current_stamina, max_stamina)
    return true

## 恢复体力
func recover_stamina(amount: float) -> void:
    current_stamina = min(max_stamina, current_stamina + amount)
    stamina_changed.emit(current_stamina, max_stamina)

## 自然恢复体力（每帧调用）
func _regen_stamina(delta: float) -> void:
    if current_stamina < max_stamina:
        recover_stamina(stamina_regen_rate * delta)

## 增加辐射值
func increase_radiation(amount: float) -> void:
    current_radiation = min(max_radiation, current_radiation + amount)
    radiation_changed.emit(current_radiation, max_radiation)
    
    # 辐射过高时扣除生命值
    if current_radiation >= max_radiation:
        take_damage(1.0 * get_physics_process_delta_time())

## 降低辐射值
func decrease_radiation(amount: float) -> void:
    current_radiation = max(0.0, current_radiation - amount)
    radiation_changed.emit(current_radiation, max_radiation)

## 获取当前属性比例 (0.0 - 1.0)
func get_hp_ratio() -> float:
    return current_hp / max_hp if max_hp > 0 else 0.0

func get_stamina_ratio() -> float:
    return current_stamina / max_stamina if max_stamina > 0 else 0.0

func get_radiation_ratio() -> float:
    return current_radiation / max_radiation if max_radiation > 0 else 0.0
