extends Node
# 注册为全局类，方便其他脚本在代码提示中看到它
class_name TimeManager_Global 

# ==========================================
# 信号 (Signals) - 游戏的心跳
# 其他节点（如UI、光照、怪物管理器）只需监听这些信号即可
# ==========================================
signal time_tick(hour: int, minute: int)  # 时间每次变动时触发（用于刷新UI）
signal day_advanced(new_day: int)         # 跨天时触发（用于植物结算生长进度）
signal time_of_day_changed(is_night: bool)# 昼夜交替时触发（用于变暗天色和刷出狂暴怪物）

# ==========================================
# 配置参数 (可直接在检查器面板调节)
# ==========================================
@export var day_length_seconds: float = 600.0  # 现实中的10分钟(600秒) = 游戏里的一天
@export var start_hour: int = 8                # 每天早上 8 点主角起床

# ==========================================
# 运行时变量
# ==========================================
var current_day: int = 1
# 时间比例：0.0 代表 00:00， 0.5 代表 12:00， 1.0 代表 24:00
var time_of_day: float = 0.0
var is_night: bool = false

func _ready():
	# 游戏启动时，把时间拨到早晨
	time_of_day = float(start_hour) / 24.0
	_check_day_night_transition()

func _process(delta: float):
	var previous_minute = get_minute()
	
	# 让时间流逝
	time_of_day += delta / day_length_seconds
	
	# 午夜零点，新的一天到来！
	if time_of_day >= 1.0:
		time_of_day -= 1.0  # 扣除一天的时间，保留零头
		current_day += 1
		day_advanced.emit(current_day)
		print("🌅 新的一天开始了！今天是第 ", current_day, " 天")
		
	# 只有当分钟真正发生变化时，才发送 UI 更新信号，节省性能
	if get_minute() != previous_minute:
		time_tick.emit(get_hour(), get_minute())
		_check_day_night_transition()

# ==========================================
# 辅助函数 (供外部随时调用)
# ==========================================
func get_hour() -> int:
	return int(time_of_day * 24.0)

func get_minute() -> int:
	var total_minutes = time_of_day * 24.0 * 60.0
	return int(total_minutes) % 60

# 返回格式化的字符串，例如 "08:30"
func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]

# 检查并触发昼夜交替
func _check_day_night_transition():
	var hour = get_hour()
	# 设定废土的夜晚是 18:00 到次日早上 06:00
	var currently_is_night = hour >= 18 or hour < 6
	
	if currently_is_night != is_night:
		is_night = currently_is_night
		time_of_day_changed.emit(is_night)
		if is_night:
			print("🌙 夜幕降临，辐射怪物开始活跃...")
		else:
			print("☀️ 太阳升起，安全区恢复平静。")
