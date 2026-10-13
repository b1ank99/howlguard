extends RefCounted
## Pure authoritative simulation. No client-supplied money, damage or positions.
const COLS = 15
const ROWS = 10
const CELL = 52.0
const PATH = [Vector2(0,4), Vector2(3,4), Vector2(3,1), Vector2(7,1), Vector2(7,7), Vector2(11,7), Vector2(11,3), Vector2(14,3)]
const DOGS = {
	"echo": {"name":"Echo Hound", "cost":110, "range":205.0, "damage":22.0, "interval":1.2, "color":"eeb876", "role":"Long reach • strips armor for the pack"},
	"zip": {"name":"Zip Corgi", "cost":80, "range":120.0, "damage":6.0, "interval":0.24, "color":"64dfba", "role":"Quick shots • every third hit doubles"},
	"frost": {"name":"Frost Malamute", "cost":140, "range":145.0, "damage":11.0, "interval":1.1, "color":"80bcf7", "role":"Splash howl • slows a cluster"}
}
const ZOMBIES = {
	"shambler": {"hp":42.0, "speed":42.0, "armor":0.0, "reward":7, "leak":1},
	"runner": {"hp":30.0, "speed":76.0, "armor":0.0, "reward":8, "leak":1},
	"brute": {"hp":145.0, "speed":30.0, "armor":5.0, "reward":16, "leak":3}
}
var cash = 440
var lives = 24
var wave = 0
var phase = "lobby"
var towers: Array = []
var enemies: Array = []
var effects: Array = []
var spawn_queue: Array = []
var spawn_timer = 0.0
var intermission = 0.0
var next_id = 1
var tick = 0

static func path_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	for p in PATH: points.append((p + Vector2(0.5,0.5)) * CELL)
	return points

static func path_length() -> float:
	var points = path_points()
	var total = 0.0
	for i in range(1, points.size()): total += points[i-1].distance_to(points[i])
	return total

static func path_position(distance: float) -> Vector2:
	var points = path_points()
	for i in range(1, points.size()):
		var length = points[i-1].distance_to(points[i])
		if distance <= length: return points[i-1].lerp(points[i], maxf(0.0, distance / length))
		distance -= length
	return points[-1]

static func buildable(x: int, y: int) -> bool:
	if x < 0 or x >= COLS or y < 0 or y >= ROWS: return false
	var center = (Vector2(x,y) + Vector2(0.5,0.5)) * CELL
	var points = path_points()
	for i in range(1, points.size()):
		if Geometry2D.get_closest_point_to_segment(center, points[i-1], points[i]).distance_to(center) < CELL * 0.7: return false
	return true

func start() -> void:
	phase = "build"
	intermission = 12.0

func upgrade_cost(tower: Dictionary) -> int:
	return int(DOGS[tower.kind].cost * (0.75 + 0.5 * tower.level))

func command(player: String, message: Dictionary) -> String:
	if phase not in ["build", "wave"]: return "The match is not running."
	var op = message.get("op", "")
	if op == "place":
		var kind = message.get("kind", "")
		if not kind is String or not DOGS.has(kind): return "Unknown defender."
		if not message.get("x") is float and not message.get("x") is int: return "Invalid cell."
		if not message.get("y") is float and not message.get("y") is int: return "Invalid cell."
		var fx = float(message.x)
		var fy = float(message.y)
		if not is_finite(fx) or not is_finite(fy) or fx != floor(fx) or fy != floor(fy) or fx < 0 or fx >= COLS or fy < 0 or fy >= ROWS: return "Invalid cell."
		var x = int(fx)
		var y = int(fy)
		if not buildable(x,y): return "Keep the trail clear."
		for tower in towers:
			if tower.x == x and tower.y == y: return "That cell is occupied."
		if towers.size() >= 60: return "Defender limit reached."
		var cost = int(DOGS[kind].cost)
		if cash < cost: return "The pack needs more treats."
		cash -= cost
		towers.append({"id":next_id,"kind":kind,"x":x,"y":y,"level":1,"owner":player,"spent":cost,"cooldown":0.0,"shots":0})
		next_id += 1
		return ""
	if op in ["upgrade", "sell"]:
		for tower in towers:
			if tower.id != message.get("id",-1): continue
			if tower.owner != player and tower.owner != "": return "Only the handler can change this dog."
			if op == "sell":
				cash += int(tower.spent * 0.65)
				towers.erase(tower)
				return ""
			if tower.level >= 3: return "Already at maximum level."
			var cost = upgrade_cost(tower)
			if cash < cost: return "The pack needs more treats."
			cash -= cost
			tower.spent += cost
			tower.level += 1
			return ""
		return "Defender no longer exists."
	return "Unknown action."

func begin_wave() -> void:
	wave += 1
	phase = "wave"
	spawn_timer = 0.0
	for i in range(9 + wave * 3):
		var kind = "shambler"
		if wave >= 3 and i % 3 == 1: kind = "runner"
		if wave >= 5 and i % 5 == 0: kind = "brute"
		spawn_queue.append(kind)

func step(dt: float) -> void:
	tick += 1
	effects.clear()
	if phase == "build":
		intermission -= dt
		if intermission <= 0: begin_wave()
		return
	if phase != "wave": return
	spawn_timer -= dt
	if not spawn_queue.is_empty() and spawn_timer <= 0:
		var kind = spawn_queue.pop_front()
		var spec = ZOMBIES[kind]
		var hp = spec.hp * (1.0 + (wave-1) * 0.12)
		enemies.append({"id":next_id,"kind":kind,"hp":hp,"max_hp":hp,"distance":0.0,"slow":0.0,"exposed":0.0})
		next_id += 1
		spawn_timer = maxf(0.35, 0.9 - wave * 0.045)
	for enemy in enemies.duplicate():
		var speed = ZOMBIES[enemy.kind].speed
		enemy.distance += speed * (0.58 if enemy.slow > 0 else 1.0) * dt
		enemy.slow = maxf(0.0, enemy.slow - dt)
		enemy.exposed = maxf(0.0, enemy.exposed - dt)
		if enemy.distance >= path_length():
			lives -= ZOMBIES[enemy.kind].leak
			enemies.erase(enemy)
	if lives <= 0:
		lives = 0
		phase = "lost"
		return
	for tower in towers:
		tower.cooldown -= dt
		if tower.cooldown > 0: continue
		var spec = DOGS[tower.kind]
		var pos = (Vector2(tower.x,tower.y) + Vector2(0.5,0.5)) * CELL
		var reach = spec.range + 16 * (tower.level-1)
		var target: Dictionary = {}
		for enemy in enemies:
			if enemy.hp > 0 and pos.distance_to(path_position(enemy.distance)) <= reach and (target.is_empty() or enemy.distance > target.distance): target = enemy
		if target.is_empty(): continue
		tower.shots += 1
		tower.cooldown = spec.interval / (1.0 + 0.18 * (tower.level-1))
		var damage = spec.damage * (1.0 + 0.65 * (tower.level-1))
		if tower.kind == "zip" and tower.shots % 3 == 0: damage *= 2
		if tower.kind == "echo": target.exposed = 2.5
		var target_pos = path_position(target.distance)
		effects.append({"x":pos.x,"y":pos.y,"tx":target_pos.x,"ty":target_pos.y,"kind":tower.kind})
		if tower.kind == "frost":
			for enemy in enemies:
				if path_position(enemy.distance).distance_to(target_pos) <= 62 + 8 * tower.level:
					enemy.slow = 1.6
					hit(enemy, damage)
		else: hit(target, damage)
	for enemy in enemies.duplicate():
		if enemy.hp <= 0:
			cash += ZOMBIES[enemy.kind].reward
			enemies.erase(enemy)
	if enemies.is_empty() and spawn_queue.is_empty():
		if wave >= 10: phase = "won"
		else:
			cash += 45 + wave * 8
			phase = "build"
			intermission = 10.0

func hit(enemy: Dictionary, damage: float) -> void:
	var armor = 0.0 if enemy.exposed > 0 else ZOMBIES[enemy.kind].armor
	var rally = 1.0
	# An exposed zombie takes 15% extra from every dog: a pack coordination mechanic.
	if enemy.exposed > 0: rally = 1.15
	enemy.hp -= maxf(1.0, damage * rally - armor)

func snapshot() -> Dictionary:
	var visible_towers: Array = []
	for t in towers:
		visible_towers.append({"id":t.id,"kind":t.kind,"x":t.x,"y":t.y,"level":t.level,"owner":t.owner,"spent":t.spent})
	return {"cash":cash,"lives":lives,"wave":wave,"phase":phase,"countdown":ceil(intermission),"towers":visible_towers,"enemies":enemies.duplicate(true),"effects":effects.duplicate(true),"tick":tick,"remaining":spawn_queue.size()+enemies.size()}
