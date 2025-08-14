extends CharacterBody2D

@export var pet_name: String = "GHOST"
@export var move_speed: float = 400.0#移动速度
@onready var pet_area=PackedVector2Array([Vector2(135,4),Vector2(270,4),Vector2(270,121),Vector2(135,121)])
@onready var menu_area=PackedVector2Array([Vector2(135,4),Vector2(392,4),Vector2(392,121),Vector2(135,121)])
@onready var API_area=PackedVector2Array([Vector2(75,4),Vector2(270,4),Vector2(270,107),Vector2(392,107),Vector2(392,204),Vector2(75,204)])
@onready var AI_area=PackedVector2Array([Vector2(75,4),Vector2(270,4),Vector2(270,107),Vector2(392,107),Vector2(392,380),Vector2(5,380),Vector2(5,74),Vector2(75,74)])
const win_size=Vector2(400,400)#窗口大小

@onready var body: Sprite2D = $body#_ready()函数启动时自动调用
@onready var inputbox = $"../chat_panel/input_box"
@onready var ai_chat = $"../AI"
@onready var responsebox =$"../chat_panel/anwser"
@onready var settings_panel = $"../Panel"
@onready var api_key_input= $"../Panel/API_KEY"
@onready var anim_tree: AnimationTree = $AnimationTree

var api_key:String=""
var playback#状态机
var is_moving:bool#宠物是否移动
var screen:Vector2#屏幕大小
var dragging:=false#拖拽初始为false
var win_pos:Vector2#窗口位置
var mouse_pos:Vector2#鼠标位置
var mouse_in_pos:Vector2#鼠标进入位置
var petting:bool#鼠标是否在下巴区域内
var ZhuangTai:String#动画状态
var random_value:int#播放动画的随机数
var dragable:bool
var free_time:float=3#自由活动的动画时间间隔
var time_count:float=free_time#计时器
var free_walk:bool=false
var direction:Vector2=Vector2.ZERO
var aaa

var area
var areas = []
var click_polygon: PackedVector2Array
var menu_open:bool=false

func _ready() -> void:
	load_settings()
	#print("API:",api_key_input.text)
	api_key = api_key_input.text
	settings_panel.settings_saved.connect(_on_settings_saved)
	# Load the initial values ​​of the settings panel
	settings_panel.load_settings()
	areas = [pet_area, menu_area,API_area,AI_area]
	area = pet_area
	
	if api_key == "":
		print("Has no api key.")
	else:
		ai_chat.set_api_key(api_key)
		
	
	
	win_pos=Vector2(get_tree().root.position)#窗口现在位置
	playback=anim_tree.get("parameters/playback")
	screen=DisplayServer.screen_get_size()
	get_tree().root.size=win_size#控制窗口大小
	get_tree().root.borderless=true#启用无边框
	get_tree().root.transparent=true#启用透明窗口
	get_tree().root.transparent_bg=true#启用透明背景
	
func _physics_process(delta: float) -> void:
	update_click_through()#背景穿透
	pass
	
func _input(event: InputEvent) -> void:
	#拖动
	if event is InputEventMouseButton and dragable==true:
		if event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
			dragging=true
			anim_tree.set("parameters/conditions/is_dragging", true)
			anim_tree.set("parameters/conditions/is_standing_3", false)
			ZhuangTai=playback.get_current_node()
			mouse_in_pos=get_viewport().get_mouse_position()
		else:
			dragging=false
			anim_tree.set("parameters/conditions/is_dragging", false)
			anim_tree.set("parameters/conditions/is_standing_3", true)
			ZhuangTai=playback.get_current_node()
	if event is InputEventMouseMotion and dragging==true:
		mouse_pos=get_viewport().get_mouse_position()
		get_tree().root.position=Vector2(get_tree().root.position)+mouse_pos-mouse_in_pos
		
	#打开菜单
	if event.is_action_pressed("开关菜单") and dragable==true:
		if menu_open==false:
			area = menu_area
			$"../menu".show()
			$"../chat_panel".hide()
			$"../Panel".hide()
			menu_open=true
		else:
			area = pet_area
			$"../menu".hide()
			menu_open=false
			
	#退出按键Ese
	if event is InputEventKey and event.is_action_pressed("quit"):
		get_tree().quit()
		
func _on_chin_mouse_entered() -> void:
	petting=1
	#print(petting)
	pass # Replace with function body.


func _on_chin_mouse_exited() -> void:
	petting=0
	#print(petting)
	pass # Replace with function body.

		
func _process(delta):
	#direction=Vector2(1,1).normalized() * move_speed
	#get_tree().root.position=Vector2(get_tree().root.position) + direction * delta
	# 玩家输入的移动的向量
	var velocity = Vector2.ZERO 
	if Input.is_action_pressed("向右走"):
		velocity.x += 1
	if Input.is_action_pressed("向左走"):
		velocity.x -= 1
	if Input.is_action_pressed("向上走"):
		velocity.y -= 1
	if Input.is_action_pressed("向下走"):
		velocity.y += 1
	if !dragging:
		#播放走路动画
		if velocity.length() > 0:
			is_moving=true
			velocity = velocity.normalized() * move_speed
			anim_tree.set("parameters/conditions/is_walking", true)
			anim_tree.set("parameters/conditions/is_standing_1", false)
			ZhuangTai=playback.get_current_node()
			#print("is_walking 状态: ", anim_tree.get("parameters/conditions/is_walking"))
		else:
			is_moving=false
			ZhuangTai="stand"
			anim_tree.set("parameters/conditions/is_walking", false)
			anim_tree.set("parameters/conditions/is_standing_1", true)
			ZhuangTai=playback.get_current_node()
			#print("is_walking 状态: ", anim_tree.get("parameters/conditions/is_walking"))
		#通过改变velocity改变position玩家位置，使得玩家可动
		get_tree().root.position=Vector2(get_tree().root.position) + velocity * delta
		get_tree().root.size=win_size#控制窗口大小
		#向右走翻转
		if velocity.x != 0:
			$body.flip_h = (velocity.x > 0)
			# 根据朝向调整碰撞体位置
			if velocity.x > 0:
				$chin/col_chin.position.x = 16.5  # 朝右时的偏移
			else:
				$chin/col_chin.position.x = -16.5  # 朝左时的偏移
	
	if petting:
		if ZhuangTai=="stand":
			if Input.is_action_pressed("对话开始"):
				#print("FuMo")
				anim_tree.set("parameters/conditions/is_standing_2", false)
				anim_tree.set("parameters/conditions/is_FuMoing", true)
				ZhuangTai=playback.get_current_node()
	else :
		anim_tree.set("parameters/conditions/is_FuMoing", false)
		anim_tree.set("parameters/conditions/is_standing_2", true)
		ZhuangTai=playback.get_current_node()
	pass
	
	if Input.is_action_pressed("发送") and area == AI_area and inputbox.text != "":
		var message = inputbox.text
		if message != "":
			#append_to_chat("你: " + message)
			ai_chat.send_message(message) 
			inputbox.clear()  
	#——————————————————————————————————————————————————————————————————————
	#自由活动
	#if free_walk==true:
		#time_count -= delta
		#if direction == Vector2.ZERO:
			## 随机方向（8方向）
			#direction = Vector2(randi_range(-1, 1),randi_range(-1, 1)).normalized() 
		#if time_count <= 0:
			#direction = Vector2.ZERO  # 重置速度触发下次随机
			#time_count = free_time
			## 移动
		#get_tree().root.position=Vector2(get_tree().root.position) + direction.normalized() * delta
			## 计时器
		#aaa= direction * delta
		##向右走翻转
		#if direction.x != 0:
			#$body.flip_h = (velocity.x > 0)
			## 根据朝向调整碰撞体位置
			#if direction.x > 0:
				#$chin/col_chin.position.x = 16.5  # 朝右时的偏移
			#else:
				#$chin/col_chin.position.x = -16.5  # 朝左时的偏移
		#
	#if dragging or ZhuangTai=="wow":
		#free_walk=false
	#print(direction)
	##print(time_count)
	#print(aaa)
#————————————————————————————————————————————————————————————————————————————————
		
#检测到动画结束发射信号，随机播放伸懒腰、寻找、睡觉的动画
func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name=="stand":
		ZhuangTai=playback.get_current_node()
		if ZhuangTai=="stand" and !is_moving:
			#print("动画结束")
			random_value = randf() * 100
			#print(random_value)
			if random_value < 70:#70%
				#print("LanYao") 
				playback.travel("LanYao")
				ZhuangTai=playback.get_current_node()
			#elif random_value < 70:	#30#
				#print("find")
				#playback.travel("find")
				#ZhuangTai=playback.get_current_node()
			else:	#30%
				#print("sleep")
				playback.travel("sleep")
				ZhuangTai=playback.get_current_node()
	pass # Replace with function body.

#背景穿透
func update_click_through():
	
	DisplayServer.window_set_mouse_passthrough(area)



func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	#print("状态：",ZhuangTai)
	#print(area)
	pass # Replace with function body.


func _on_drag_area_mouse_entered() -> void:
	dragable=1
	pass # Replace with function body.
	
func _on_drag_area_mouse_exited() -> void:
	dragable=0
	pass # Replace with function body.
	


func _on_free_walk_pressed() -> void:#名字懒得改了，功能改成输入API KEY
	#关闭菜单
	area = pet_area
	menu_open=false
	area=API_area
	$"../menu".hide()
	$"../Panel".show()
	#随机动画
	#free_walk=true
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	#关闭菜单
	area = pet_area
	$"../menu".hide()
	menu_open=false
	#退出
	get_tree().quit()
	pass # Replace with function body.


func _on_button_send_pressed() -> void:
	var message = inputbox.text
	if message != "":
		#append_to_chat("你: " + message)
		ai_chat.send_message(message) 
		inputbox.clear()  
	
	pass # Replace with function body.


func _on_chat_pressed() -> void:
	#关闭菜单
	area = pet_area
	menu_open=false
	$"../menu".hide()
	$"../chat_panel".show()
	area=AI_area
	pass # Replace with function body.

func _on_settings_saved(new_api_key: String, muted: bool):
	api_key = new_api_key
	print("新 API Key: ", api_key)
	settings_panel.hide()
	
func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		print("配置文件不存在")
		api_key_input.text = ""
		return
	else :
		var key = config.get_value("auth", "api_key", "")
		api_key_input.text = str(key)


func _on_gold_miner_pressed() -> void:
	print("打开黄金矿工")
	var exe_path = OS.get_executable_path().get_base_dir().path_join("gold miner/黄金矿工.exe")
	if FileAccess.file_exists(exe_path):
		OS.shell_open(exe_path)
	else:
		print("找不到黄金矿工.exe")
	pass # Replace with function body.
