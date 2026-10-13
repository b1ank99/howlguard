extends SceneTree
const Rules = preload("res://scripts/rules.gd")
## A reproducible legal spending strategy with the standard 440-treat budget.
## It is a baseline, not proof every strategy wins or a substitute for playtests.
func _initialize() -> void:
	var game = Rules.new()
	game.start()
	var plans = [["echo",6,4],["frost",8,5],["echo",10,5],["zip",5,3],["echo",5,6],["frost",6,6],["echo",9,4],["zip",8,2],["echo",12,5],["frost",2,2],["echo",4,5],["zip",10,2]]
	var next = 0
	var count = 0
	for frame in 36000:
		# Spend only while building; no manipulation of money or combat state.
		if game.phase == "build":
			if next < plans.size():
				var p = plans[next]
				var result = game.command("pack",{"op":"place","kind":p[0],"x":p[1],"y":p[2]})
				if result == "": next += 1
			elif not game.towers.is_empty():
				for t in game.towers:
					if t.level<3:
						game.command("pack",{"op":"upgrade","id":t.id})
		game.step(0.05)
		count = frame
		if game.phase in ["won","lost"]: break
	print("BALANCE: %s, wave %d, shelter %d, treats %d, defenders %d, elapsed %.1fs" % [game.phase,game.wave,game.lives,game.cash,game.towers.size(),count*0.05])
	quit(0 if game.phase == "won" else 1)
