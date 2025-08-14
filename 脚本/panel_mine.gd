extends Panel


@onready var api_key_input= $API_KEY
@onready var save_btn = $Button_save
@onready var back_btn = $Button_quit


signal settings_saved(api_key: String, is_muted: bool)
signal back_pressed()

func _ready():
	#api_key_input.text = "请输入API KEY"
	load_settings()

func set_initial_values(api_key: String):
	api_key_input.text = api_key
	load_settings()

#退出按钮
func _on_button_pressed() -> void:
	hide()
	pass # Replace with function body.


func _on_button_save_pressed() -> void:
	var key = api_key_input.text.strip_edges()
	if key != "":
		print(key)
		print('保存成功')
		save_settings(key)
		hide()
	pass # Replace with function body.


# Save API key and mute setting to local config file
func save_settings(key: String):
	var config = ConfigFile.new()
	config.set_value("auth", "api_key", key)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	# macos path: /Users/<你的用户名>/Library/Application Support/Godot/app_userdata/deskpet-seiko/settings.cfg
	# win path: C:\Users\<你的用户名>\AppData\Roaming\Godot\app_userdata\deskpet-seiko\settings.cfg
	# linux path: /home/<你的用户名>/.local/share/godot/app_userdata/deskpet-seiko/settings.cfg
	
	if err != OK :
		print("配置文件不存在")
		#api_key_input.text = ""
		return
	else :
		if api_key_input != null:	
			var key = config.get_value("auth", "api_key", "")
			api_key_input.text = str(key)

func get_api_key() -> String:
	return api_key_input.text.strip_edges()

#聊天界面的退出按钮
func _on_button_quit_pressed() -> void:
	$"../chat_panel".hide()
	pass # Replace with function body.
