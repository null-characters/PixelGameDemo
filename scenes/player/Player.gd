extends CharacterBody2D
class_name Player

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
# 挖地功能
# ==========================================
func dig_ground() -> void:
    var tilemap = get_parent().get_node_or_null("TileMapLayer")
    if tilemap != null:
        var target_pos = action_point.global_position
        # 把绝对坐标转换成 TileMapLayer 自己的内部坐标
        var local_pos = tilemap.to_local(target_pos)
        var grid_pos = tilemap.local_to_map(local_pos)
        tilemap.set_cell(grid_pos, -1)

# ==========================================
# 填地功能
# ==========================================
func build_ground() -> void:
    var tilemap = get_parent().get_node_or_null("TileMapLayer")
    if tilemap != null:
        var target_pos = action_point.global_position
        var local_pos = tilemap.to_local(target_pos)
        var grid_pos = tilemap.local_to_map(local_pos)
        
        # 使用 get_cell_source_id 检查该坐标有没有放东西
        # 如果返回值是 -1，说明这个格子是空的
        if tilemap.get_cell_source_id(grid_pos) == -1:
            tilemap.set_cells_terrain_connect([grid_pos], 0, 0)