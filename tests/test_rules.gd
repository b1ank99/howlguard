extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Rooms = preload("res://scripts/rooms.gd")
var failures = 0
var checks = 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	var game = Rules.new()
	game.start()
	check(game.command("a",{"op":"place","kind":"zip","x":3,"y":4}) != "","Path placement rejected")
	check(game.command("a",{"op":"place","kind":"zip","x":-1,"y":0}) != "","Out of bounds rejected")
	check(game.command("a",{"op":"place","kind":"zip","x":1.5,"y":0}) != "","Fractional cell rejected")
	check(game.command("a",{"op":"place","kind":"zip","x":"1","y":0}) != "","String cell rejected")
	check(game.command("a",{"op":"place","kind":"fake","x":1,"y":0}) != "","Unknown class rejected")
	check(game.cash == 440,"Invalid actions preserve economy")
	check(game.command("a",{"op":"place","kind":"echo","x":4,"y":3}) == "","Valid placement accepted")
	var id = game.towers[0].id
	check(game.cash == 330,"Placement costs exactly once")
	check(game.command("b",{"op":"place","kind":"zip","x":4,"y":3}) != "","Atomic collision rejected")
	check(game.command("b",{"op":"sell","id":id}) != "","Foreign sale rejected")
	check(game.command("b",{"op":"upgrade","id":id}) != "","Foreign upgrade rejected")
	check(game.command("a",{"op":"upgrade","id":id}) == "","Upgrade accepted")
	check(game.towers[0].level == 2 and game.cash == 193,"Upgrade exact cost")
	check(game.command("a",{"op":"upgrade","id":id}) == "","Third level accepted")
	check(game.command("a",{"op":"upgrade","id":id}) != "","Level cap enforced")
	var spent = game.towers[0].spent
	var before = game.cash
	check(game.command("a",{"op":"sell","id":id}) == "","Sale accepted")
	check(game.cash == before + int(spent*0.65),"Sale uses total investment and floor refund")
	check(game.command("a",{"op":"sell","id":id}) != "","Repeated sale rejected")
	check(game.cash < 440,"Upgrade-sale cannot manufacture money")
	var broke = Rules.new()
	broke.start()
	broke.cash = 0
	check(broke.command("a",{"op":"place","kind":"echo","x":4,"y":3}) != "","Unaffordable action rejected")
	var service = Rooms.new()
	check(service.handle(1,{"op":"create","version":999}).has("error"),"Protocol mismatch rejected")
	var a = service.handle(1,{"op":"create","version":1,"name":"Alice"})
	var code = a.code
	check(service.handle(1,{"op":"start"}).has("error"),"Cannot start solo")
	var b = service.handle(2,{"op":"join","version":1,"code":code,"name":"Bob"})
	service.handle(3,{"op":"join","version":1,"code":code,"name":"C"})
	service.handle(4,{"op":"join","version":1,"code":code,"name":"D"})
	check(service.handle(5,{"op":"join","version":1,"code":code}).has("error"),"Four player cap")
	check(service.handle(2,{"op":"start"}).has("error"),"Captain authorization")
	check(not service.handle(1,{"op":"start"}).has("error"),"Two plus online can start")
	check(service.handle(6,{"op":"join","version":1,"code":code}).has("error"),"No new players mid-match")
	service.drop_peer(2)
	check(service.handle(7,{"op":"resume","version":1,"code":code,"token":"forged"}).has("error"),"Forged reconnect rejected")
	var resumed = service.handle(7,{"op":"resume","version":1,"code":code,"token":b.token})
	check(resumed.get("id") == b.id,"Reconnect preserves identity")
	check(service.handle(8,{"op":"resume","version":1,"code":code,"token":b.token}).has("error"),"Active token cannot be stolen")
	var snap = JSON.stringify(service.snapshot(code))
	check(not snap.contains(a.token) and not snap.contains(b.token),"Snapshots never expose session tokens")
	service.handle(7,{"op":"place","kind":"echo","x":4,"y":3})
	service.drop_peer(7)
	service.step(90.1)
	check(service.handle(8,{"op":"resume","version":1,"code":code,"token":b.token}).has("error"),"Expired reconnect rejected")
	check(service.rooms[code].game.towers[0].owner == "","Expired handler releases dog to pack")
	service.drop_peer(1)
	check(service.rooms[code].host != a.id,"Captain transfers on disconnect")
	service.drop_peer(3)
	service.drop_peer(4)
	var tick_before = service.rooms[code].game.tick
	service.step(1)
	check(service.rooms[code].game.tick == tick_before,"All-offline room pauses")
	service.step(100)
	check(not service.rooms.has(code),"Empty expired room cleaned up")
	var loss = Rules.new()
	loss.start()
	for i in 12000:
		loss.step(0.05)
		if loss.phase == "lost": break
	check(loss.phase == "lost" and loss.lives == 0,"Undefended match reaches shared loss")
	var win = Rules.new()
	win.start()
	# Combat fixture funds a fully upgraded pack; checks all ten actual waves.
	win.cash = 100000
	for y in Rules.ROWS:
		for x in Rules.COLS:
			if not Rules.buildable(x,y) or win.towers.size() >= 50: continue
			var kinds = ["echo","zip","frost"]
			win.command("a",{"op":"place","kind":kinds[(x+y)%3],"x":x,"y":y})
			var tower_id = win.towers[-1].id
			win.command("a",{"op":"upgrade","id":tower_id})
			win.command("a",{"op":"upgrade","id":tower_id})
	for i in 30000:
		win.step(0.05)
		if win.phase in ["won","lost"]: break
	check(win.phase == "won" and win.wave == 10,"Ten escalating waves can end in shared victory")
	var armor = {"kind":"brute","hp":100.0,"exposed":0.0}
	win.hit(armor,10.0)
	check(armor.hp == 95.0,"Brute armor reduces damage")
	armor.exposed = 1
	win.hit(armor,10.0)
	check(is_equal_approx(armor.hp,83.5),"Pack exposure strips armor and boosts damage")
	print("RULES: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
