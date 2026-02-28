extends CharacterBody2D

# 别忘了在最上面声明你的 AnimatedSprite2D 节点！
@onready var animated_sprite = $AnimatedSprite2D
@onready var action_point = $ActionPoint

# 设定的速度
const SPEED = 100.0
# 常量，代表准星距离小猫的像素距离
# Sprout Lands 的格子通常是 16x16，如果格子更大，可以改成 32
const ACTION_DISTANCE = 16.0

func _physics_process(delta):
	# 1. 获取键盘按键的方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. 计算速度并移动小猫
	velocity = input_dir * SPEED
	move_and_slide()
	
	# 3. 调用动画更新函数
	update_animation(input_dir)
	
	# 4. 挖地/填地检测
	if Input.is_action_just_pressed("ui_accept"):
		dig_ground()
	if Input.is_key_pressed(KEY_B):
		build_ground()

# 专门负责判断方向、播放动画，并移动准星的函数
func update_animation(dir: Vector2):
	# 注意：当 dir == Vector2.ZERO（松开键盘）时，我们不改变准星位置
	# 这样哪怕小猫停下来发呆，准星依然会保留在它最后面朝的方向！
	if dir == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		if abs(dir.x) > abs(dir.y):
			# === 横向移动 ===
			if dir.x > 0:
				animated_sprite.play("walk_right")
				animated_sprite.flip_h = false 
				# 【新魔法】：面朝右，准星移到右边！
				action_point.position = Vector2(ACTION_DISTANCE, 0)
			else:
				animated_sprite.play("walk_left")
				# 【新魔法】：面朝左，准星移到左边！
				action_point.position = Vector2(-ACTION_DISTANCE, 0)
		else:
			# === 纵向移动 ===
			if dir.y > 0:
				animated_sprite.play("walk_down")
				# 【新魔法】：面朝下，准星移到下边！
				action_point.position = Vector2(0, ACTION_DISTANCE)
			else:
				animated_sprite.play("walk_up")
				# 【新魔法】：面朝上，准星移到上边！
				action_point.position = Vector2(0, -ACTION_DISTANCE)


func dig_ground():
	var tilemap = get_parent().get_node_or_null("TileMapLayer")
	if tilemap != null:
		var target_pos = action_point.global_position
		# 【补丁】：把绝对坐标转换成 TileMapLayer 自己的内部坐标，永不偏移！
		var local_pos = tilemap.to_local(target_pos) 
		var grid_pos = tilemap.local_to_map(local_pos)
		tilemap.set_cell(grid_pos, -1)

func build_ground():
	var tilemap = get_parent().get_node_or_null("TileMapLayer")
	if tilemap != null:
		var target_pos = action_point.global_position
		var local_pos = tilemap.to_local(target_pos)
		var grid_pos = tilemap.local_to_map(local_pos)
		
		# 使用 get_cell_source_id 检查该坐标有没有放东西
		# 如果返回值是 -1，说明这个格子是空的！
		if tilemap.get_cell_source_id(grid_pos) == -1:
			tilemap.set_cells_terrain_connect([grid_pos], 0, 0)
