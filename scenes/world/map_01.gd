extends Node2D
## 手搓 MVP 关卡地图脚本
## 负责地图初始化、净化翻转效果

@onready var base_layer: TileMapLayer = $BaseLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var purified_layer: TileMapLayer = $PurifiedLayer
@onready var purification_tree: Marker2D = $PurificationTree
@onready var player_spawn: Marker2D = $PlayerSpawn

# 地图配置
const TILE_SIZE := 16
const MAP_WIDTH := 40  # 横向40格 (640像素)
const MAP_HEIGHT := 24  # 纵向24格 (384像素)

# 区域划分 (横向)
const SHELTER_END_X := -15      # 庇护所结束位置 (左侧)
const FARM_START_X := -10       # 农田开始位置
const FARM_END_X := 5           # 农田结束位置
const PATH_END_X := 15          # 净化路径结束位置
const TREE_X := 18              # 净化树位置

# 地形类型
enum TerrainType {
	CORRUPT,     # 腐败土地
	FARM,        # 农田
	OBSTACLE,    # 障碍物
	PURIFIED     # 净化土地
}

# 农田地块记录 (用于后续种植系统)
var farm_plots: Dictionary = {}

func _ready() -> void:
	_generate_map()
	_setup_purification_tree()

## 生成地图
func _generate_map() -> void:
	# 生成基础地形
	for x in range(-MAP_WIDTH / 2, MAP_WIDTH / 2):
		for y in range(-MAP_HEIGHT / 2, MAP_HEIGHT / 2):
			var terrain = _get_terrain_at(x, y)
			_set_tile(x, y, terrain)

## 根据位置获取地形类型
func _get_terrain_at(x: int, y: int) -> int:
	# 庇护所区域 (左侧) - 较安全的腐败土地
	if x < SHELTER_END_X:
		return TerrainType.CORRUPT
	
	# 农田区域 (中间) - 可种植区域
	if x >= FARM_START_X and x <= FARM_END_X:
		# 预留一些通道
		if y >= -3 and y <= 3:
			return TerrainType.FARM
		return TerrainType.CORRUPT
	
	# 净化路径 (右侧) - 充满障碍
	if x > FARM_END_X and x < PATH_END_X:
		# 随机生成障碍物
		if _should_place_obstacle(x, y):
			return TerrainType.OBSTACLE
		return TerrainType.CORRUPT
	
	# 净化树区域
	if x >= PATH_END_X:
		return TerrainType.CORRUPT
	
	return TerrainType.CORRUPT

## 判断是否放置障碍物 (伪随机)
func _should_place_obstacle(x: int, y: int) -> bool:
	# 使用简单的伪随机，避免在中心通道放障碍
	if abs(y) <= 1:
		return false
	var seed_val = x * 7 + y * 13
	return (seed_val % 5) == 0

## 设置地块
func _set_tile(x: int, y: int, terrain: int) -> void:
	var base_coord := Vector2i(1, 1)  # 默认草地
	var obstacle_coord := Vector2i(-1, -1)  # 默认无障碍物
	
	match terrain:
		TerrainType.CORRUPT:
			base_coord = Vector2i(1, 1)
		TerrainType.FARM:
			base_coord = Vector2i(1, 1)  # 后续替换为耕地贴图
			farm_plots[Vector2i(x, y)] = {"tilled": false, "watered": false}
		TerrainType.OBSTACLE:
			base_coord = Vector2i(1, 1)  # 基础层仍为草地
			obstacle_coord = Vector2i(0, 0)  # 障碍物使用不同贴图
			# 为障碍物添加物理碰撞
			_set_obstacle_collision(x, y)
	
	# 设置基础层
	base_layer.set_cell(Vector2i(x, y), 0, base_coord)
	
	# 设置障碍物层
	if obstacle_coord.x >= 0:
		obstacle_layer.set_cell(Vector2i(x, y), 0, obstacle_coord)

## 设置障碍物碰撞
func _set_obstacle_collision(x: int, y: int) -> void:
	"""为障碍物设置物理碰撞，玩家无法通过"""
	var tile_data = PhysicsPointQueryParameters2D.new()
	# 障碍物会被 TileSet 的 physics_layer_0 自动处理
	# 这里只需要在 TileSet 中配置好物理层即可

## 设置净化树
func _setup_purification_tree() -> void:
	# 标记净化树位置
	purification_tree.set_meta("type", "purification_target")
	purification_tree.set_meta("active", false)

## 触发净化效果 (公开接口)
func trigger_purification() -> void:
	"""当净化树成熟时调用，触发全地图净化翻转"""
	print("🌍 净化效果触发！")
	
	# 显示净化层
	purified_layer.visible = true
	
	# 生成净化后的地形
	_generate_purified_layer()
	
	# 创建视觉过渡效果
	_create_purge_effect()

## 生成净化后的地形
func _generate_purified_layer() -> void:
	for x in range(-MAP_WIDTH / 2, MAP_WIDTH / 2):
		for y in range(-MAP_HEIGHT / 2, MAP_HEIGHT / 2):
			purified_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1))

## 创建净化视觉特效
func _create_purge_effect() -> void:
	"""创建 The Purge Moment 视觉演出"""
	# TODO: 添加 Tween 动画和粒子效果
	# 1. 冲击波从净化树向外扩散
	# 2. 地块颜色渐变翻转
	# 3. 粒子效果（花瓣飘落）
	pass

## 获取农田地块信息 (供种植系统调用)
func get_farm_plot(pos: Vector2i) -> Dictionary:
	return farm_plots.get(pos, {})

## 更新农田地块状态 (供种植系统调用)
func update_farm_plot(pos: Vector2i, key: String, value: Variant) -> void:
	if farm_plots.has(pos):
		farm_plots[pos][key] = value