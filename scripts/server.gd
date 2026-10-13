extends Node
const Rooms = preload("res://scripts/rooms.gd")
var service = Rooms.new()
var tcp = TCPServer.new()
var peers: Dictionary = {}
var next_peer = 1
var accumulator = 0.0
var broadcast_timer = 0.0

func _ready() -> void:
	var port = int(OS.get_environment("PORT")) if OS.has_environment("PORT") else 9080
	var bind_address = OS.get_environment("BIND_ADDRESS") if OS.has_environment("BIND_ADDRESS") else "127.0.0.1"
	var err = tcp.listen(port,bind_address)
	if err != OK:
		push_error("Cannot listen: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("HOWLGUARD SERVER listening %s:%d protocol %d" % [bind_address,port,Rooms.VERSION])

func _process(delta: float) -> void:
	while tcp.is_connection_available():
		var stream = tcp.take_connection()
		if peers.size() >= 128:
			stream.disconnect_from_host()
			continue
		var ws = WebSocketPeer.new()
		ws.inbound_buffer_size = 8192
		ws.outbound_buffer_size = 262144
		ws.max_queued_packets = 16
		ws.accept_stream(stream)
		peers[next_peer] = {"ws":ws,"age":0.0,"last":0.0,"tokens":20.0}
		next_peer += 1
	for id in peers.keys():
		var p: Dictionary = peers[id]
		p.age += delta
		p.tokens = minf(20.0,p.tokens+delta*8.0)
		p.ws.poll()
		var state = p.ws.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			service.drop_peer(id)
			peers.erase(id)
			continue
		if state != WebSocketPeer.STATE_OPEN:
			if p.age > 10: p.ws.close()
			continue
		if p.age-p.last > 45:
			p.ws.close(1000,"Idle timeout")
			continue
		while p.ws.get_available_packet_count() > 0:
			var packet: PackedByteArray = p.ws.get_packet()
			if packet.size() > 4096 or not p.ws.was_string_packet():
				p.ws.close(1009,"Invalid payload")
				break
			p.tokens -= 1
			if p.tokens < 0:
				p.ws.close(1008,"Too many commands")
				break
			var msg = JSON.parse_string(packet.get_string_from_utf8())
			if not msg is Dictionary:
				send(id,{"error":"Expected JSON object."})
				continue
			p.last = p.age
			if msg.get("op") == "ping": send(id,{"op":"pong"})
			else: send(id,service.handle(id,msg))
	accumulator += minf(delta,0.25)
	while accumulator >= 0.05:
		service.step(0.05)
		accumulator -= 0.05
	broadcast_timer += delta
	if broadcast_timer >= 0.1:
		broadcast_timer = 0.0
		var cache: Dictionary = {}
		for id in service.sessions:
			var code: String = service.sessions[id].code
			if not cache.has(code): cache[code] = service.snapshot(code)
			send(id,cache[code])

func send(id: int, msg: Dictionary) -> void:
	if not peers.has(id): return
	var ws: WebSocketPeer = peers[id].ws
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN: return
	if ws.get_current_outbound_buffered_amount() > 131072:
		ws.close(1008,"Slow connection")
		return
	ws.send_text(JSON.stringify(msg))
