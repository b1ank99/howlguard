extends SceneTree
## Visual regression fixture, uses the actual game UI; not evidence of online play.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var rules = load("res://scripts/rules.gd").new()
	rules.start()
	rules.cash = 2000
	for data in [["echo",4,3],["zip",5,5],["frost",8,4],["zip",10,5],["echo",12,5]]:
		rules.command("a",{"op":"place","kind":data[0],"x":data[1],"y":data[2]})
		rules.command("a",{"op":"upgrade","id":rules.towers[-1].id})
	rules.wave = 4
	rules.begin_wave()
	for i in 360: rules.step(0.05)
	scene.net.player_id = "a"
	scene.net.status = "Online"
	scene.net.code = "DEMO42"
	scene.net.state = rules.snapshot()
	scene.net.state.merge({"code":"DEMO42","host":"a","players":[{"id":"a","name":"Riley","online":true},{"id":"b","name":"Sam","online":true}]})
	scene.selected = int(rules.towers[0].id)
	scene.refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args = OS.get_cmdline_user_args()
	var output = args[0] if not args.is_empty() else "user://preview.png"
	var err = root.get_texture().get_image().save_png(output)
	print("VISUAL CAPTURE ",error_string(err))
	quit(0 if err == OK else 1)
