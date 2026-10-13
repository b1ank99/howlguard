extends SceneTree
## Real TCP/WebSocket transport: four independent clients and authoritative server.
const Server = preload("res://scripts/server.gd")
var clients: Array = []
var server
var failures = 0
var checks = 0
var sequence = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func make_client() -> WebSocketPeer:
	var ws = WebSocketPeer.new()
	ws.inbound_buffer_size = 262144
	ws.max_queued_packets = 64
	ws.connect_to_url("ws://127.0.0.1:19080")
	clients.append(ws)
	return ws

func wait_open(ws: WebSocketPeer) -> bool:
	for i in 300:
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN: return true
		await create_timer(0.01).timeout
	return false

func request(ws: WebSocketPeer, msg: Dictionary, expected: String) -> Dictionary:
	ws.send_text(JSON.stringify(msg))
	return await receive(ws,expected)

func receive(ws: WebSocketPeer, expected: String) -> Dictionary:
	for i in 300:
		ws.poll()
		while ws.get_available_packet_count() > 0:
			var value = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if value is Dictionary and (value.get("op") == expected or value.has("error")): return value
		await create_timer(0.01).timeout
	return {"error":"timeout"}

func drain(ws: WebSocketPeer) -> void:
	ws.poll()
	while ws.get_available_packet_count()>0: ws.get_packet()

func run() -> void:
	OS.set_environment("PORT","19080")
	OS.set_environment("BIND_ADDRESS","127.0.0.1")
	server = Server.new()
	root.add_child(server)
	var a = make_client()
	check(await wait_open(a),"WebSocket handshake")
	var owner = await request(a,{"op":"create","version":1,"name":"Desktop"},"joined")
	check(owner.has("code"),"Room created over socket")
	if not owner.has("code"):
		finish()
		return
	var code = owner.code
	var b = make_client()
	await wait_open(b)
	var friend = await request(b,{"op":"join","version":1,"name":"Phone A","code":code},"joined")
	var c = make_client()
	await wait_open(c)
	var third = await request(c,{"op":"join","version":1,"name":"Phone B","code":code},"joined")
	var d = make_client()
	await wait_open(d)
	var fourth = await request(d,{"op":"join","version":1,"name":"Fourth","code":code},"joined")
	check(friend.has("id") and third.has("id") and fourth.has("id"),"Four independent sockets share one room")
	var started = await request(a,{"op":"start"},"ok")
	check(not started.has("error"),"Captain starts authoritative match")
	drain(a)
	drain(b)
	var placed = await request(a,{"op":"place","kind":"echo","x":4,"y":3},"ok")
	check(not placed.has("error"),"Placement accepted over transport")
	# Wait past the next broadcast, then compare same state on two clients.
	await create_timer(0.25).timeout
	drain(a)
	drain(b)
	var snap_a = await receive(a,"state")
	var snap_b = await receive(b,"state")
	check(snap_a.get("cash") == 330 and snap_b.get("cash") == 330,"Shared authoritative economy broadcast")
	check(snap_a.get("towers",[]).size() == 1 and snap_b.get("towers",[]).size() == 1,"Tower synchronized to other client")
	var removed_id = friend.get("id","")
	b.close()
	for i in 30:
		b.poll()
		await create_timer(0.01).timeout
	var reconnect = make_client()
	await wait_open(reconnect)
	var resume = await request(reconnect,{"op":"resume","version":1,"code":code,"token":friend.get("token","")},"joined")
	check(resume.get("id") == removed_id,"Reconnect over a fresh TCP connection preserves identity")
	var resumed_state = await receive(reconnect,"state")
	check(resumed_state.get("cash") == 330 and resumed_state.get("towers",[]).size() == 1,"Reconnect receives full snapshot")
	var bad = make_client()
	await wait_open(bad)
	bad.send_text("[]")
	var invalid = await receive(bad,"error")
	check(invalid.has("error") and invalid.error != "timeout","Malformed message rejected safely")
	finish()

func finish() -> void:
	for ws in clients:
		ws.close()
		ws.poll()
	server.queue_free()
	print("TRANSPORT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
