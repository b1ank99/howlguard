extends Control
signal cell_clicked(x: int, y: int)
const Rules = preload("res://scripts/rules.gd")
var state: Dictionary = {}
var selected = -1
var placement = ""
var hover = Vector2i(-1,-1)
var enemy_draw: Dictionary = {}
var time = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: hover = Vector2i(event.position / Rules.CELL)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell = Vector2i(event.position / Rules.CELL)
		if cell.x >= 0 and cell.x < Rules.COLS and cell.y >= 0 and cell.y < Rules.ROWS:
			cell_clicked.emit(cell.x,cell.y)
		accept_event()

func text_at(pos: Vector2, value: String, color: Color, size_value = 15) -> void:
	draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func _draw() -> void:
	draw_style_box(panel(Color("132e35")),Rect2(Vector2.ZERO,size))
	for y in Rules.ROWS:
		for x in Rules.COLS:
			var rect = Rect2(x*Rules.CELL+2,y*Rules.CELL+2,Rules.CELL-4,Rules.CELL-4)
			var tint = Color("183b3e") if (x+y)%2==0 else Color("17373b")
			draw_rect(rect,tint)
			if (x*7+y*3)%9==0 and Rules.buildable(x,y):
				draw_line(rect.position+Vector2(15,36),rect.position+Vector2(18,28),Color("2c5751"),2)
				draw_line(rect.position+Vector2(18,36),rect.position+Vector2(23,31),Color("2c5751"),2)
	var points = Rules.path_points()
	draw_polyline(points,Color("0b2027"),48,true)
	draw_polyline(points,Color("726d55"),38,true)
	draw_polyline(points,Color("8c8160"),26,true)
	for i in range(0,int(Rules.path_length()),36):
		draw_circle(Rules.path_position(i),2,Color("b1a274"))
	draw_circle(points[0],21,Color("b86f68"))
	text_at(points[0]+Vector2(-17,5),"IN",Color("ffe2b9"),17)
	draw_circle(points[-1],24,Color("69dabc"))
	draw_rect(Rect2(points[-1]-Vector2(13,9),Vector2(26,22)),Color("e9d6ae"))
	draw_colored_polygon(PackedVector2Array([points[-1]+Vector2(-18,-9),points[-1]+Vector2(0,-24),points[-1]+Vector2(18,-9)]),Color("e99c6f"))
	if not placement.is_empty() and hover.x >= 0 and hover.x < Rules.COLS and hover.y >= 0 and hover.y < Rules.ROWS:
		var center = (Vector2(hover)+Vector2(0.5,0.5))*Rules.CELL
		var valid = Rules.buildable(hover.x,hover.y)
		for t in state.get("towers",[]):
			if t.x==hover.x and t.y==hover.y: valid = false
		draw_rect(Rect2(Vector2(hover)*Rules.CELL,Vector2.ONE*Rules.CELL),Color(0.4,0.9,0.75,0.35) if valid else Color(0.9,0.3,0.3,0.4))
		draw_arc(center,Rules.DOGS[placement].range,0,TAU,64,Color(0.5,0.95,0.8,0.45),2,true)
	var active_ids: Dictionary = {}
	for e in state.get("enemies",[]):
		var id = int(e.id)
		active_ids[id] = true
		var target = Rules.path_position(e.distance)
		var pos: Vector2 = enemy_draw.get(id,target)
		pos = pos.lerp(target,0.28)
		enemy_draw[id] = pos
		draw_zombie(pos,e)
	for id in enemy_draw.keys():
		if not active_ids.has(id): enemy_draw.erase(id)
	for t in state.get("towers",[]):
		var pos = (Vector2(t.x,t.y)+Vector2(0.5,0.5))*Rules.CELL
		if t.id == selected:
			draw_arc(pos,Rules.DOGS[t.kind].range+16*(t.level-1),0,TAU,64,Color(0.5,0.95,0.8,0.35),2,true)
			draw_circle(pos,25,Color("fff1c9"),false,3,true)
		draw_dog(pos,t.kind)
		for level in int(t.level): draw_circle(pos+Vector2(-6+level*6,22),2,Color("ffda88"))
	for e in state.get("effects",[]):
		draw_line(Vector2(e.x,e.y),Vector2(e.tx,e.ty),Color(Rules.DOGS[e.kind].color,0.7),2,true)
		if e.kind == "frost": draw_arc(Vector2(e.tx,e.ty),38,0,TAU,32,Color(0.6,0.8,1,0.5),2,true)
	if state.get("phase","") in ["won","lost"]:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.06,0.09,0.82))
		var won = state.phase == "won"
		text_at(Vector2(180,245),"ORCHARD SAFE" if won else "THE TRAIL FELL",Color("75e1bc") if won else Color("f3a08e"),40)
		text_at(Vector2(185,286),"The whole pack wins together." if won else "Regroup. Try a different pack formation.",Color("e6e7d3"),21)
		text_at(Vector2(190,330),"Leave the room to start a fresh match.",Color("96b6b6"),18)

func panel(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(16)
	return style

func draw_dog(pos: Vector2, kind: String) -> void:
	var color = Color(Rules.DOGS[kind].color)
	draw_circle(pos+Vector2(0,4),20,Color("0c232b"))
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-20,-19),pos+Vector2(-7,-13),pos+Vector2(-16,5)]),color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([pos+Vector2(20,-19),pos+Vector2(7,-13),pos+Vector2(16,5)]),color.darkened(0.3))
	draw_circle(pos,17,color)
	draw_circle(pos+Vector2(0,7),10,Color("ffdfad") if kind != "frost" else Color("dfedee"))
	draw_circle(pos+Vector2(-6,-3),2.5,Color("142832"))
	draw_circle(pos+Vector2(6,-3),2.5,Color("142832"))
	draw_colored_polygon(PackedVector2Array([pos+Vector2(-4,4),pos+Vector2(4,4),pos+Vector2(0,9)]),Color("142832"))
	draw_line(pos+Vector2(-10,16),pos+Vector2(10,16),Color("3f6578"),4)
	if kind == "echo": draw_arc(pos+Vector2(0,-3),9,PI,TAU,16,Color("724f4b"),3,true)
	if kind == "zip": draw_line(pos+Vector2(-12,-10),pos+Vector2(9,-10),Color("f5eee0"),4)
	if kind == "frost": draw_colored_polygon(PackedVector2Array([pos+Vector2(-5,-15),pos+Vector2(0,-5),pos+Vector2(5,-15)]),Color("f0f5eb"))

func draw_zombie(pos: Vector2, e: Dictionary) -> void:
	var brute = e.kind == "brute"
	var radius = 16 if brute else 11
	var color = Color("aca89b") if brute else (Color("dab97b") if e.kind == "runner" else Color("93b887"))
	draw_circle(pos+Vector2(1,4),radius+2,Color("132732"))
	draw_rect(Rect2(pos+Vector2(-radius,-radius+3),Vector2(radius*2,radius*2)),color)
	draw_line(pos+Vector2(-radius-3,3),pos+Vector2(radius+3,3),color,4)
	draw_circle(pos+Vector2(-4,-3),2,Color("613f55"))
	draw_circle(pos+Vector2(4,-3),2,Color("613f55"))
	draw_line(pos+Vector2(-4,5),pos+Vector2(4,5),Color("613f55"),2)
	if e.exposed>0: draw_arc(pos,radius+5,0,TAU,16,Color("f4bd76"),2,true)
	if e.slow>0: draw_arc(pos,radius+7,0,TAU,16,Color("82c3ff"),2,true)
	draw_rect(Rect2(pos+Vector2(-14,-radius-8),Vector2(28,3)),Color("142832"))
	draw_rect(Rect2(pos+Vector2(-14,-radius-8),Vector2(28*maxf(0,e.hp/e.max_hp),3)),Color("ee9d8b"))
