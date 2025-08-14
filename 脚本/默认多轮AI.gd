extends Node

var api_key = ""
var app_id = "76377a4cd30341c382c625b61cc8c3db"  # 替换为你的 App ID
var url = "https://dashscope.aliyuncs.com/api/v1/apps/%s/completion" % app_id

# 存储对话历史（多轮对话的核心）
var messages = []

@onready var http_request = $HTTPRequest
@onready var responsebox = $"../chat_panel/anwser"

func _ready():
	if http_request == null:
		print("http_request is null")
		return
	http_request.request_completed.connect(_on_request_completed)
	
	# 初始化系统消息（可选）
	messages.append({
		"role": "system",
		"content": "You are a helpful assistant."
	})

# 设置 API Key
func set_api_key(key: String):
	api_key = key
	print("key here: ", api_key)

# 发送用户消息（自动维护对话历史）
func send_message(user_input: String):
	# 1. 添加用户消息到历史
	messages.append({
		"role": "user",
		"content": user_input
	})
	
	# 2. 构建请求数据
	var headers = [
		"Authorization: Bearer " + api_key,
		"Content-Type: application/json"
	]
	
	var body = {
		"input": {
			"messages": messages  # 发送整个对话历史
		},
		"parameters": {},
		"debug": {}
	}

	var json_body = JSON.stringify(body)

	# 3. 发送请求
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	#print(url)
	if error != OK:
		print("HTTP 请求失败，错误码：", error)

# 处理 API 响应
func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("API 请求失败，状态码：", response_code)
		print("响应数据：", body.get_string_from_utf8())
		return
	
	var data = body.get_string_from_utf8()
	var response = JSON.parse_string(data)
	
	if response == null:
		print("JSON 解析失败")
		return
	
	# 提取 AI 回复
	var ai_response = response["output"]["text"]
	
	# 添加到对话历史
	messages.append({
		"role": "assistant",
		"content": ai_response
	})
	
	# 更新 UI
	responsebox.text = ai_response
	print(response)
