extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const VERSION = 1
const RESERVE_SECONDS = 90.0
var rooms: Dictionary = {}
var sessions: Dictionary = {}
var clock = 0.0
var crypto = Crypto.new()

func random_key(bytes: int) -> String:
	return crypto.generate_random_bytes(bytes).hex_encode()

func handle(peer: int, msg: Dictionary) -> Dictionary:
	var op = msg.get("op", "")
	if not op is String: return {"error":"Invalid action."}
	if op == "hello":
		if msg.get("version") != VERSION: return {"error":"Version mismatch. Update your game."}
		return {"op":"hello","version":VERSION}
	if op in ["create", "join", "resume"]:
		if sessions.has(peer): return {"error":"Leave your current room first."}
		if msg.get("version") != VERSION: return {"error":"Version mismatch. Update your game."}
		var code = msg.get("code", "")
		if not code is String or code.length() > 8: return {"error":"Invalid room code."}
		code = code.to_upper()
		if op == "create":
			if rooms.size() >= 32: return {"error":"Server full. Try later."}
			code = random_key(3).to_upper()
			while rooms.has(code): code = random_key(3).to_upper()
			rooms[code] = {"game":Rules.new(),"players":{},"host":"","idle":clock}
		if not rooms.has(code): return {"error":"Room expired or code not found."}
		var room: Dictionary = rooms[code]
		if op == "resume":
			var token = msg.get("token", "")
			for id in room.players:
				var p: Dictionary = room.players[id]
				if p.token != token or p.peer != 0: continue
				if clock - p.offline >= RESERVE_SECONDS: return {"error":"Reconnect window expired."}
				p.peer = peer
				sessions[peer] = {"code":code,"id":id}
				room.idle = clock
				assign_host(room)
				return {"op":"joined","code":code,"id":id,"token":token}
			return {"error":"Reconnect token invalid or already active."}
		if room.game.phase != "lobby": return {"error":"Match started. Only reconnects can enter."}
		if room.players.size() >= 4: return {"error":"Room full (four players)."}
		var name_value = msg.get("name", "Handler")
		if not name_value is String: return {"error":"Invalid name."}
		var clean_name = name_value.strip_edges().substr(0,18)
		for i in range(clean_name.length()):
			if clean_name.unicode_at(i) < 32: return {"error":"Invalid name."}
		if clean_name.is_empty(): clean_name = "Handler"
		var id = random_key(4)
		var token = random_key(24)
		room.players[id] = {"name":clean_name,"token":token,"peer":peer,"offline":0.0}
		if room.host.is_empty(): room.host = id
		room.idle = clock
		sessions[peer] = {"code":code,"id":id}
		return {"op":"joined","code":code,"id":id,"token":token}
	if not sessions.has(peer): return {"error":"Join a room first."}
	var s: Dictionary = sessions[peer]
	var room: Dictionary = rooms[s.code]
	if op == "leave":
		remove_player(s.code, s.id)
		sessions.erase(peer)
		return {"op":"left"}
	if op == "start":
		if room.host != s.id: return {"error":"Only the room captain can start."}
		var online = 0
		for p in room.players.values():
			if p.peer != 0: online += 1
		if online < 2: return {"error":"Two connected players are needed."}
		if room.game.phase != "lobby": return {"error":"Already started."}
		room.game.start()
		return {"op":"ok"}
	var error: String = room.game.command(s.id,msg)
	return {"op":"ok"} if error.is_empty() else {"error":error}

func drop_peer(peer: int) -> void:
	if not sessions.has(peer): return
	var s: Dictionary = sessions[peer]
	var room: Dictionary = rooms[s.code]
	room.players[s.id].peer = 0
	room.players[s.id].offline = clock
	sessions.erase(peer)
	assign_host(room)

func assign_host(room: Dictionary) -> void:
	if room.players.has(room.host) and room.players[room.host].peer != 0: return
	room.host = ""
	for id in room.players:
		if room.players[id].peer != 0:
			room.host = id
			return

func remove_player(code: String, id: String) -> void:
	var room: Dictionary = rooms[code]
	room.players.erase(id)
	for t in room.game.towers:
		if t.owner == id: t.owner = ""
	assign_host(room)

func step(dt: float) -> void:
	clock += dt
	for code in rooms.keys():
		var room: Dictionary = rooms[code]
		var online = false
		for id in room.players.keys():
			var p: Dictionary = room.players[id]
			if p.peer != 0: online = true
			elif clock - p.offline >= RESERVE_SECONDS: remove_player(code,id)
		if online:
			room.idle = clock
			room.game.step(dt)
		elif clock - room.idle > 600 or room.players.is_empty(): rooms.erase(code)

func snapshot(code: String) -> Dictionary:
	var room: Dictionary = rooms[code]
	var state: Dictionary = room.game.snapshot()
	state["op"] = "state"
	state["code"] = code
	state["host"] = room.host
	state["paused"] = sessions.values().filter(func(s): return s.code == code).is_empty()
	state["players"] = []
	for id in room.players:
		var p: Dictionary = room.players[id]
		state.players.append({"id":id,"name":p.name,"online":p.peer != 0,"reserve":maxf(0,RESERVE_SECONDS-(clock-p.offline)) if p.peer == 0 else 0})
	return state
