extends Node
signal changed
signal notice(text: String)
const VERSION = 1
var ws: WebSocketPeer
var endpoint = "ws://127.0.0.1:9080"
var player_name = "Handler"
var code = ""
var player_id = ""
var token = ""
var state: Dictionary = {}
var status = "Offline"
var intent: Dictionary = {}
var retry = 0.0
var attempts = 0
var ping_timer = 0.0
var connecting_age = 0.0
var last_receive = 0.0
var intentional = false

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("user://connection.cfg") == OK:
		endpoint = config.get_value("connection","endpoint",endpoint)
		player_name = config.get_value("connection","name",player_name)
		code = config.get_value("connection","code","")
		token = config.get_value("connection","token","")

func save() -> void:
	var config = ConfigFile.new()
	config.set_value("connection","endpoint",endpoint)
	config.set_value("connection","name",player_name)
	config.set_value("connection","code",code)
	config.set_value("connection","token",token)
	config.save("user://connection.cfg")

func connect_room(url: String, name_value: String, op: String, room_code: String) -> void:
	if ws != null: ws.close()
	endpoint = url.strip_edges()
	player_name = name_value.strip_edges()
	intent = {"op":op,"version":VERSION,"name":player_name,"code":room_code.strip_edges().to_upper()}
	if op == "resume": intent["token"] = token
	else:
		code = ""
		token = ""
		state = {}
	intentional = false
	attempts = 0
	open_socket()

func open_socket() -> void:
	ws = WebSocketPeer.new()
	ws.inbound_buffer_size = 262144
	ws.outbound_buffer_size = 8192
	ws.max_queued_packets = 32
	if not endpoint.begins_with("ws://") and not endpoint.begins_with("wss://"):
		notice.emit("Use a ws:// development or wss:// hosted address.")
		ws = null
		return
	var err = ws.connect_to_url(endpoint)
	if err != OK:
		notice.emit("Cannot connect: " + error_string(err))
		ws = null
		return
	status = "Connecting…"
	connecting_age = 0
	last_receive = 0
	ping_timer = 0
	changed.emit()

func send(message: Dictionary) -> void:
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(message))

func leave() -> void:
	send({"op":"leave"})
	intentional = true
	code = ""
	token = ""
	player_id = ""
	state = {}
	status = "Offline"
	retry = 0
	save()
	if ws != null: ws.close()
	changed.emit()

func _process(delta: float) -> void:
	if ws == null:
		if retry > 0:
			retry -= delta
			if retry <= 0: open_socket()
		return
	ws.poll()
	connecting_age += delta
	last_receive += delta
	var ready = ws.get_ready_state()
	if ready == WebSocketPeer.STATE_CONNECTING and connecting_age > 12: ws.close()
	if ready == WebSocketPeer.STATE_OPEN:
		if status == "Connecting…":
			status = "Connected"
			send(intent)
			changed.emit()
		ping_timer += delta
		if ping_timer >= 10:
			ping_timer = 0
			send({"op":"ping"})
		if last_receive > 25: ws.close()
		while ws.get_available_packet_count() > 0:
			var msg = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if not msg is Dictionary: continue
			last_receive = 0
			if msg.has("error"):
				notice.emit(msg.error)
				if intent.get("op") in ["create","join","resume"] and player_id.is_empty():
					intentional = true
					ws.close()
			elif msg.get("op") == "joined":
				code = msg.code
				player_id = msg.id
				token = msg.token
				attempts = 0
				status = "Online"
				save()
				changed.emit()
			elif msg.get("op") == "state":
				state = msg
				changed.emit()
	if ready == WebSocketPeer.STATE_CLOSED:
		ws = null
		player_id = ""
		if not intentional and not token.is_empty() and attempts < 12:
			attempts += 1
			intent = {"op":"resume","code":code,"token":token,"version":VERSION}
			retry = minf(5.0, attempts)
			status = "Reconnecting… %d/12" % attempts
		else:
			status = "Offline"
			if not intentional: notice.emit("Connection ended. Check server address or use Reconnect.")
		changed.emit()
