extends Node
const Network = preload("res://scripts/network.gd")
const Board = preload("res://scripts/board.gd")
const Rules = preload("res://scripts/rules.gd")
var net
var root: Control
var lobby: Control
var game_ui: Control
var board
var address: LineEdit
var name_input: LineEdit
var code_input: LineEdit
var message: Label
var status_label: Label
var hud: Label
var roster: Label
var detail: Label
var captain_button: Button
var upgrade_button: Button
var sell_button: Button
var lobby_roster: Label
var selected = -1
var placement = ""
var dog_buttons: Dictionary = {}

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args() or OS.has_feature("dedicated_server"):
		var server = load("res://scripts/server.gd").new()
		add_child(server)
		return
	net = Network.new()
	add_child(net)
	net.changed.connect(refresh)
	net.notice.connect(show_notice)
	build_ui()
	refresh()

func label(parent: Node, text: String, pos: Vector2, dimensions: Vector2, font_size = 22, color = Color("e7ecdf")) -> Label:
	var item = Label.new()
	item.text = text
	item.position = pos
	item.size = dimensions
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	parent.add_child(item)
	return item

func button(parent: Node, text: String, pos: Vector2, dimensions: Vector2, action: Callable, accent = false) -> Button:
	var item = Button.new()
	item.text = text
	item.position = pos
	item.size = dimensions
	item.add_theme_font_size_override("font_size",20)
	for key in ["normal","hover","pressed","disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("24635a") if accent else Color("233e4a")
		if key == "hover": style.bg_color = style.bg_color.lightened(0.14)
		if key == "pressed": style.bg_color = style.bg_color.lightened(0.23)
		if key == "disabled": style.bg_color = Color("1b2c34")
		style.set_corner_radius_all(10)
		style.set_content_margin_all(12)
		item.add_theme_stylebox_override(key,style)
	item.pressed.connect(action)
	parent.add_child(item)
	return item

func field(parent: Node, value: String, placeholder: String, pos: Vector2, dimensions: Vector2) -> LineEdit:
	var item = LineEdit.new()
	item.text = value
	item.placeholder_text = placeholder
	item.position = pos
	item.size = dimensions
	item.add_theme_font_size_override("font_size",22)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("142d39")
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	item.add_theme_stylebox_override("normal",style)
	parent.add_child(item)
	return item

func build_ui() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	label(root,"HOWLGUARD",Vector2(28,14),Vector2(700,45),34,Color("7be0bc"))
	label(root,"N I G H T   O R C H A R D",Vector2(30,60),Vector2(680,30),15,Color("a6bebb"))
	status_label = label(root,"",Vector2(925,24),Vector2(320,40),19)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message = label(root,"",Vector2(30,742),Vector2(1220,44),19,Color("efc594"))
	lobby = Control.new()
	root.add_child(lobby)
	label(lobby,"A small pack. A long night.",Vector2(70,140),Vector2(760,62),40)
	label(lobby,"Defend the orchard with 2–4 friends.\nOne shared stash. Ten waves. Every dog has a job.",Vector2(74,216),Vector2(710,90),24,Color("a8c2bd"))
	label(lobby,"SERVER ADDRESS",Vector2(75,337),Vector2(720,30),15)
	address = field(lobby,net.endpoint,"wss://play.your-domain.example",Vector2(75,375),Vector2(690,54))
	label(lobby,"YOUR HANDLER NAME",Vector2(75,449),Vector2(350,30),15)
	name_input = field(lobby,net.player_name,"Handler name",Vector2(75,486),Vector2(330,54))
	name_input.max_length = 18
	label(lobby,"ROOM CODE",Vector2(430,449),Vector2(350,30),15)
	code_input = field(lobby,net.code,"Six characters",Vector2(430,486),Vector2(335,54))
	code_input.max_length = 6
	button(lobby,"Create room",Vector2(75,570),Vector2(215,58),func(): connect_room("create"),true)
	button(lobby,"Join room",Vector2(312,570),Vector2(215,58),func(): connect_room("join"))
	button(lobby,"Reconnect",Vector2(550,570),Vector2(215,58),func(): connect_room("resume"))
	label(lobby,"Local test: start the dedicated server first.\nFor phones, use the same hosted wss:// address.",Vector2(75,653),Vector2(700,65),18,Color("789c9b"))
	var preview = Board.new()
	preview.position = Vector2(855,174)
	preview.size = Vector2(780,520)
	preview.scale = Vector2(0.43,0.43)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.state = {"towers":[{"id":1,"x":4,"y":3,"kind":"echo","level":2},{"id":2,"x":8,"y":5,"kind":"frost","level":3},{"id":3,"x":10,"y":4,"kind":"zip","level":1}]}
	lobby.add_child(preview)
	label(lobby,"THE PACK",Vector2(860,431),Vector2(340,35),17,Color("7be0bc"))
	label(lobby,"Echo Hound  /  expose armor\nZip Corgi  /  rapid combos\nFrost Malamute  /  slow clusters",Vector2(860,480),Vector2(360,150),21)
	game_ui = Control.new()
	root.add_child(game_ui)
	hud = label(game_ui,"",Vector2(30,104),Vector2(1220,40),24)
	board = Board.new()
	board.position = Vector2(30,168)
	board.size = Vector2(780,520)
	board.cell_clicked.connect(on_cell)
	game_ui.add_child(board)
	var y = 164
	for kind in ["echo","zip","frost"]:
		var spec: Dictionary = Rules.DOGS[kind]
		var b = button(game_ui,"%s  ·  %d treats" % [spec.name,spec.cost],Vector2(844,y),Vector2(406,56),choose_dog.bind(kind))
		dog_buttons[kind] = b
		label(game_ui,spec.role,Vector2(850,y+59),Vector2(395,25),16,Color("99bab5"))
		y += 92
	detail = label(game_ui,"Tap a dog card, then a free grass cell.",Vector2(848,448),Vector2(405,86),19)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_button = button(game_ui,"Upgrade",Vector2(844,540),Vector2(195,54),func(): action("upgrade"),true)
	sell_button = button(game_ui,"Sell",Vector2(1055,540),Vector2(195,54),func(): action("sell"))
	roster = label(game_ui,"",Vector2(848,608),Vector2(406,78),17,Color("a6c1bc"))
	button(game_ui,"Cancel selection",Vector2(30,698),Vector2(216,46),func(): choose_dog(""))
	button(game_ui,"Leave room",Vector2(1080,698),Vector2(170,46),func(): net.leave())
	lobby_roster = label(game_ui,"",Vector2(50,229),Vector2(730,240),26)
	captain_button = button(game_ui,"Start night • 2 players minimum",Vector2(160,512),Vector2(510,66),func(): net.send({"op":"start"}),true)
	label(game_ui,"Tap / click grass to place. Tap a defender to inspect. Only its handler can upgrade or sell.",Vector2(264,706),Vector2(797,32),16,Color("789c9b"))

func connect_room(op: String) -> void:
	if op == "resume" and net.token.is_empty():
		show_notice("No saved reconnect session on this device.")
		return
	message.text = ""
	net.connect_room(address.text,name_input.text,op,code_input.text)

func choose_dog(kind: String) -> void:
	placement = kind
	selected = -1
	refresh()

func on_cell(x: int, y: int) -> void:
	if net.status != "Online":
		show_notice("Waiting for the server connection.")
		return
	for t in net.state.get("towers",[]):
		if t.x == x and t.y == y:
			selected = int(t.id)
			placement = ""
			refresh()
			return
	if not placement.is_empty():
		net.send({"op":"place","kind":placement,"x":x,"y":y})
	else:
		selected = -1
		refresh()

func action(op: String) -> void:
	if net.status == "Online" and selected >= 0: net.send({"op":op,"id":selected})

func show_notice(value: String) -> void:
	message.text = value

func refresh() -> void:
	if root == null: return
	status_label.text = net.status
	var in_room = not net.state.is_empty()
	lobby.visible = not in_room
	game_ui.visible = in_room
	if not in_room: return
	var s: Dictionary = net.state
	code_input.text = net.code
	board.state = s
	board.placement = placement
	board.selected = selected
	var phase_text = "Wave %d / 10 • %d incoming" % [s.wave,s.remaining]
	if s.phase == "build": phase_text = "Wave %d next • %ds to build" % [s.wave+1,s.countdown]
	if s.phase == "lobby": phase_text = "Waiting for the pack"
	if s.phase == "won": phase_text = "Victory • 10 waves cleared"
	if s.phase == "lost": phase_text = "Defeat • night %d" % s.wave
	hud.text = "ROOM %s     |     %d treats     |     %d shelter     |     %s" % [s.code,s.cash,s.lives,phase_text]
	var lines = PackedStringArray()
	var lobby_lines = PackedStringArray(["ROOM  %s  — share this code with friends" % s.code,""])
	var online = 0
	for p in s.players:
		var suffix = " • captain" if p.id == s.host else ""
		if not p.online: suffix = " • reconnect %ds" % p.reserve
		else: online += 1
		lines.append(p.name + suffix)
		lobby_lines.append(p.name + suffix)
	roster.text = "  /  ".join(lines)
	roster.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lobby_roster.text = "\n".join(lobby_lines)
	lobby_roster.visible = s.phase == "lobby"
	captain_button.visible = s.phase == "lobby"
	captain_button.disabled = s.host != net.player_id or online < 2 or net.status != "Online"
	board.visible = s.phase != "lobby"
	for kind in dog_buttons:
		dog_buttons[kind].disabled = s.phase not in ["build","wave"] or net.status != "Online"
		dog_buttons[kind].modulate = Color("7be0bc") if placement == kind else Color.WHITE
	var tower: Dictionary = {}
	for t in s.towers:
		if int(t.id) == selected: tower = t
	upgrade_button.disabled = true
	sell_button.disabled = true
	if tower.is_empty():
		detail.text = "Tap a dog card, then a free grass cell.\nThe pack shares all treats."
		if not placement.is_empty(): detail.text = "Deploy %s\nTap grass within reach of the trail." % Rules.DOGS[placement].name
	else:
		var cost = int(Rules.DOGS[tower.kind].cost*(0.75+0.5*tower.level))
		detail.text = "%s • Level %d / 3\n%s" % [Rules.DOGS[tower.kind].name,tower.level,Rules.DOGS[tower.kind].role]
		upgrade_button.text = "Upgrade · %d" % cost if tower.level<3 else "Max level"
		sell_button.text = "Sell · %d" % int(tower.spent*0.65)
		var owned = tower.owner == net.player_id or tower.owner == ""
		upgrade_button.disabled = not owned or tower.level>=3 or s.cash<cost or s.phase not in ["build","wave"] or net.status != "Online"
		sell_button.disabled = not owned or s.phase not in ["build","wave"] or net.status != "Online"
