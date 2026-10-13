extends SceneTree
## Exercises the shipped Network node, including its automatic resume path.
const Server = preload("res://scripts/server.gd")
const Network = preload("res://scripts/network.gd")
var failures = 0
var checks = 0
var server
var clients: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, reason: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + reason)

func until(predicate: Callable, seconds = 4.0) -> bool:
	var end = Time.get_ticks_msec() + int(seconds*1000)
	while Time.get_ticks_msec() < end:
		if predicate.call(): return true
		await create_timer(0.02).timeout
	return false

func run() -> void:
	OS.set_environment("PORT","19082")
	OS.set_environment("BIND_ADDRESS","127.0.0.1")
	server = Server.new()
	root.add_child(server)
	var a = Network.new()
	var b = Network.new()
	var c = Network.new()
	for n in [a,b,c]:
		root.add_child(n)
		clients.append(n)
	a.connect_room("ws://127.0.0.1:19082","Desktop","create","")
	check(await until(func(): return a.status == "Online" and not a.state.is_empty()),"Actual client creates room")
	if a.code.is_empty():
		finish()
		return
	b.connect_room("ws://127.0.0.1:19082","Phone A","join",a.code)
	c.connect_room("ws://127.0.0.1:19082","Phone B","join",a.code)
	check(await until(func(): return b.status == "Online" and c.status == "Online" and a.state.get("players",[]).size() == 3),"Three actual Network nodes join")
	a.send({"op":"start"})
	check(await until(func(): return c.state.get("phase") == "build"),"Started phase synchronized")
	b.send({"op":"place","kind":"echo","x":6,"y":4})
	check(await until(func(): return a.state.get("cash") == 330 and b.state.get("cash") == 330 and c.state.get("cash") == 330),"Real clients receive authoritative cash")
	var id: String = b.player_id
	var token: String = b.token
	b.ws.close()
	check(await until(func(): return b.status.begins_with("Reconnecting")),"Actual client enters auto-reconnect")
	check(await until(func(): return b.status == "Online",8.0),"Actual client automatically resumes")
	check(b.player_id == id and b.token == token,"Auto-resume preserves session identity")
	check(await until(func(): return not b.state.get("towers",[]).is_empty() and b.state.towers[0].owner == id),"Owned dog survives actual client resume")
	b.leave()
	check(await until(func(): return a.state.get("players",[]).size() == 2),"Explicit leave updates other clients")
	check(b.token == "" and b.code == "" and b.state.is_empty(),"Explicit leave clears reconnect credentials")
	finish()

func finish() -> void:
	for n in clients:
		n.leave()
		n.queue_free()
	server.queue_free()
	print("CLIENT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
