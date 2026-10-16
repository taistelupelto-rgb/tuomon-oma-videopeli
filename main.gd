extends Node3D
# CATERPILLAR: Knife of the Mother 3D — Godot remake.
# Concept kept from bridge-runner.html: seeded cave rooms, modifiers,
# elites, spikes, permadeath, knife combat, crystals, exit, cave warden.
# Single scene, everything built in code. GDScript only, web-safe.

const TW := 20
const TH := 13
const CELL := 2.0
const WALL_H := 2.4
const EXIT_CELL := Vector2i(18, 6)
const WALK_SPEED := 5.2
const TURN_SPEED := 2.6
const KNIFE_RANGE := 3.0
const KNIFE_ARC := 1.0 # radians, half-angle

const ROOM_DEFS := [
	{"name": "ROOM A — SPAWN CAVE", "about": "Grab the crystal, find the glowing exit. Every run, a new cave.", "pillars": 2, "crys": 1, "en": 0, "spikes": 0, "elites": 0, "heart": false, "sharp": false},
	{"name": "ROOM B — THE BRIDGE", "about": "Daemons guard the pipe. Slash them: face them, hold KNIFE (SPACE).", "pillars": 4, "crys": 2, "en": 2, "spikes": 3, "elites": 1, "heart": true, "sharp": false},
	{"name": "ROOM C — THE AGENT THINKS", "about": "Crystals are context, the knife is the shell. Clear the room to open the exit.", "pillars": 5, "crys": 2, "en": 3, "spikes": 4, "elites": 1, "heart": true, "sharp": true},
	{"name": "ROOM D — DELIVERY", "about": "The CAVE WARDEN guards the exit: it charges and calls minions. Kill it.", "pillars": 4, "crys": 1, "en": 2, "spikes": 3, "elites": 1, "boss": true, "heart": false, "sharp": false},
]

const MODIFIERS := ["NONE", "NONE", "SWARM", "SWIFT", "FAMINE", "RICH"]

const SFX_SLASH := preload("res://assets/sfx/knifeSlice.ogg")
const SFX_SLASH2 := preload("res://assets/sfx/knifeSlice2.ogg")
const SFX_HIT := preload("res://assets/sfx/impactPunch_medium_000.ogg")
const SFX_HIT2 := preload("res://assets/sfx/impactPunch_heavy_000.ogg")
const SFX_COIN := preload("res://assets/sfx/handleCoins.ogg")
const SFX_DOOR := preload("res://assets/sfx/doorOpen_2.ogg")
const SFX_HURT := preload("res://assets/sfx/impactSoft_heavy_000.ogg")
const SFX_METAL := preload("res://assets/sfx/impactMetal_light_000.ogg")
const SFX_FIGHT := preload("res://assets/sfx/fight.ogg")
const SFX_ROUND2 := preload("res://assets/sfx/round_2.ogg")
const SFX_FINAL := preload("res://assets/sfx/final_round.ogg")
const SFX_WIN := preload("res://assets/sfx/you_win.ogg")
const SFX_DEATH := preload("res://assets/sfx/game_over.ogg")

var state := "title" # title | play | dead | win
var paused_game := false
var seed_value := 1
var modifier := "NONE"
var rng := RandomNumberGenerator.new()
var ri := 0
var hp := 3
var max_hp := 5
var score := 0
var kills := 0
var combo := 0
var combo_t := 0.0
var knife_dmg := 1
var speed_bonus := 0.0
var iframes := 0.0
var tick := 0

var grid: Array = []
var player_node: CharacterBody3D
var cam_rig: Node3D
var spring: SpringArm3D
var cam: Camera3D
var body_mesh: MeshInstance3D
var leg_l: Node3D
var leg_r: Node3D
var arm_r: Node3D
var knife_blade: MeshInstance3D
var yaw := 0.0
var cam_pitch := -0.25
var walk_phase := 0.0
var attack_t := 0.0
var attack_cd := 0.0
var swing_id := 0
var spike_cd := 0.0

var room_node: Node3D
var items: Array = []   # {cell, pos, taken, node, spin}
var extras: Array = []  # {cell, pos, kind, taken, node}
var enemies: Array = [] # {node, mesh, mat, pos(Vector3 x,z in y), hp, maxhp, sp, type, elite, boss, mode, t, st, vx, vz, cool, dead, hit_swing}
var exit_node: Area3D
var exit_light: OmniLight3D
var rain: GPUParticles3D

var hud_top: Label
var hud_cap: Label
var hud_room: Label
var hud_combo: Label
var cap_t := 0.0
var title_panel: PanelContainer
var dead_panel: PanelContainer
var win_panel: PanelContainer
var pause_label: Label
var minimap: Control
var sfx_players: Array = []
var sfx_i := 0
var autoplay := false
var auto_t := 0

func _ready() -> void:
	autoplay = OS.get_cmdline_user_args().has("autoplay")
	_build_environment()
	_build_player()
	_build_hud()
	_build_audio()
	show_title()

# ---------------- run / rooms ----------------

func start_run(new_seed: int) -> void:
	seed_value = new_seed
	rng.seed = seed_value
	modifier = MODIFIERS[rng.randi_range(0, MODIFIERS.size() - 1)]
	ri = 0
	hp = 3
	score = 0
	kills = 0
	combo = 0
	knife_dmg = 1
	speed_bonus = 0.0
	_load_room(0)
	state = "play"
	paused_game = false
	_refresh_overlays()
	play_sfx(SFX_FIGHT)
	announce("FIGHT! Modifier: " + modifier)

func _load_room(idx: int) -> void:
	ri = idx
	_gen_grid()
	_build_room_nodes()
	_place_player_spawn()
	iframes = 1.0
	attack_t = 0.0
	_refresh_overlays()
	var d: Dictionary = ROOM_DEFS[idx]
	hud_room.text = d["name"]
	announce(d["name"] + " — " + d["about"])
	if idx == 1:
		play_sfx(SFX_ROUND2)
	if idx == 3:
		play_sfx(SFX_FINAL)
		announce("FINAL ROUND — " + d["about"])

func _gen_grid() -> void:
	var d: Dictionary = ROOM_DEFS[ri]
	grid.clear()
	for y in TH:
		var row: Array = []
		for x in TW:
			row.append("#" if (x == 0 or y == 0 or x == TW - 1 or y == TH - 1) else ".")
		grid.append(row)
	var taken: Array = []
	for k in int(d.get("pillars", 0)):
		var p := _free_cell(taken, 2.5)
		taken.append(p)
		grid[p.y][p.x] = "P"
	for k in int(d.get("spikes", 0)):
		var p := _free_cell(taken, 2.5)
		taken.append(p)
		grid[p.y][p.x] = "s"
	grid[EXIT_CELL.y][EXIT_CELL.x] = "E"
	grid[EXIT_CELL.y][EXIT_CELL.x - 1] = "."
	items.clear()
	extras.clear()
	enemies.clear()
	var ncrys: int = int(d.get("crys", 0)) + (1 if modifier == "RICH" else 0)
	for k in ncrys:
		var p := _free_cell(taken, 1.5)
		taken.append(p)
		items.append({"cell": p, "taken": false})
	var nen: int = int(d.get("en", 0)) + (1 if (modifier == "SWARM" and int(d.get("en", 0)) > 0) else 0)
	for k in nen:
		var p := _free_cell(taken, 3.0)
		taken.append(p)
		var roll := rng.randf()
		var etype := "chase"
		if roll < 0.32:
			etype = "dash"
		elif roll < 0.57:
			etype = "tuhkanaama" # soot-black lurker, fast and tough
		var fast := (0.8 if modifier == "SWIFT" else 0.0) + (0.5 if modifier == "RICH" else 0.0)
		enemies.append(_new_enemy(p, etype, k < int(d.get("elites", 0)), false, fast))
	if bool(d.get("boss", false)):
		var p := _free_cell(taken, 4.0)
		taken.append(p)
		enemies.append(_new_enemy(p, "boss", false, true, 0.0))
	if bool(d.get("heart", false)) and modifier != "FAMINE" and rng.randf() < 0.5:
		var p := _free_cell(taken, 1.5)
		taken.append(p)
		extras.append({"cell": p, "kind": "heart", "taken": false})
	if bool(d.get("sharp", false)) and rng.randf() < 0.65:
		var p := _free_cell(taken, 1.5)
		taken.append(p)
		extras.append({"cell": p, "kind": "sharp", "taken": false})
	if (ri == 1 or ri == 2) and rng.randf() < 0.5:
		var p := _free_cell(taken, 1.5)
		taken.append(p)
		extras.append({"cell": p, "kind": "boots", "taken": false})

func _new_enemy(p: Vector2i, etype: String, elite: bool, boss: bool, fast: float) -> Dictionary:
	var hpv := 2
	if elite:
		hpv = 4
	if boss:
		hpv = 20
	if etype == "tuhkanaama" and not boss:
		hpv = maxi(hpv, 3)
	return {"cell": p, "type": etype, "elite": elite, "boss": boss,
		"hp": hpv, "maxhp": hpv, "sp": 2.6 + rng.randf() * 1.2 + ri * 0.35 + fast + (0.8 if etype == "tuhkanaama" else 0.0),
		"mode": "stalk", "t": 3.0 + rng.randf() * 2.0, "st": 8.0,
		"vx": 0.0, "vz": 0.0, "cool": 0.0, "dead": false, "hit_swing": -1, "node": null}

func _free_cell(taken: Array, min_spawn: float) -> Vector2i:
	for t in 120:
		var x := rng.randi_range(1, TW - 2)
		var y := rng.randi_range(1, TH - 2)
		if Vector2(x - 1.5, y - TH / 2.0).length() < min_spawn:
			continue
		if Vector2(x - EXIT_CELL.x, y - EXIT_CELL.y).length() < 2.2:
			continue
		var ok := true
		for p in taken:
			if Vector2(p - Vector2i(x, y)).length() < 1.6:
				ok = false
				break
		if ok:
			return Vector2i(x, y)
	return Vector2i(3, 3)

func room_clear() -> bool:
	for it in items:
		if not it["taken"]:
			return false
	for e in enemies:
		if not e["dead"]:
			return false
	return true

func cell_at_world(pos: Vector3) -> String:
	var mx := int(floor(pos.x / CELL))
	var my := int(floor(pos.z / CELL))
	if mx < 0 or my < 0 or mx >= TW or my >= TH:
		return "#"
	return grid[my][mx]

# ---------------- per-frame ----------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k == KEY_ENTER or k == KEY_KP_ENTER:
			if state == "title" or state == "dead" or state == "win":
				start_run(rng.randi() if state != "title" else int(Time.get_unix_time_from_system()) % 100000)
			elif state == "play" and paused_game:
				paused_game = false
				_refresh_overlays()
		elif k == KEY_R and state == "play":
			start_run(int(Time.get_unix_time_from_system()) % 100000)
		elif k == KEY_P and state == "play":
			paused_game = not paused_game
			_refresh_overlays()

func _process(delta: float) -> void:
	tick += 1
	if cap_t > 0.0:
		cap_t -= delta
		if cap_t <= 0.0:
			hud_cap.text = ""
	if autoplay:
		_autoplay(delta)

func _physics_process(delta: float) -> void:
	if state != "play" or paused_game:
		return
	# --- turn ---
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		turn += 1.0
	if autoplay:
		turn = 0.25
	yaw += turn * TURN_SPEED * delta
	if Input.is_physical_key_pressed(KEY_Q):
		cam_pitch = min(0.9, cam_pitch + 1.2 * delta)
	if Input.is_physical_key_pressed(KEY_E):
		cam_pitch = max(-0.9, cam_pitch - 1.2 * delta)
	# --- move ---
	var fwd := 0.0
	var strafe := 0.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		fwd += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		fwd -= 1.0
	if Input.is_physical_key_pressed(KEY_A):
		strafe -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		strafe += 1.0
	if autoplay:
		fwd = 1.0
	var mag := Vector2(fwd, strafe).length()
	if mag > 1.0:
		fwd /= mag
		strafe /= mag
	var sp := WALK_SPEED * (1.0 + speed_bonus * 0.12)
	var fx := -sin(yaw)
	var fz := -cos(yaw)
	var rx := cos(yaw)
	var rz := -sin(yaw)
	var vx := (fx * fwd + rx * strafe) * sp
	var vz := (fz * fwd + rz * strafe) * sp
	player_node.velocity.x = vx
	player_node.velocity.z = vz
	if not player_node.is_on_floor():
		player_node.velocity.y -= 22.0 * delta
	else:
		player_node.velocity.y = -0.5
	player_node.move_and_slide()
	player_node.rotation.y = yaw + PI # face away (back view)
	var moving := mag > 0.1
	if moving:
		walk_phase += 9.0 * delta
	leg_l.rotation.x = sin(walk_phase) * (0.7 if moving else 0.0)
	leg_r.rotation.x = -sin(walk_phase) * (0.7 if moving else 0.0)
	# --- camera rig follows ---
	cam_rig.position = cam_rig.position.lerp(player_node.position + Vector3(0, 1.7, 0), 0.35)
	cam_rig.rotation.y = yaw
	spring.rotation.x = cam_pitch
	rain.position = Vector3(player_node.position.x, 6.0, player_node.position.z)
	# --- timers ---
	if iframes > 0.0:
		iframes -= delta
	if attack_cd > 0.0:
		attack_cd -= delta
	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			combo = 0
	if spike_cd > 0.0:
		spike_cd -= delta
	# --- knife ---
	var slashing := Input.is_physical_key_pressed(KEY_SPACE) or autoplay
	if slashing and attack_cd <= 0.0:
		attack_t = 0.28
		attack_cd = 0.38
		swing_id += 1
		play_sfx(SFX_SLASH if swing_id % 2 == 0 else SFX_SLASH2)
	if attack_t > 0.0:
		attack_t -= delta
		arm_r.rotation.x = -1.9 + (0.28 - attack_t) / 0.28 * 1.4
		_knife_hits()
	else:
		arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, 0.2)
	# --- enemies, pickups, exit, spikes ---
	_enemy_update(delta)
	_pickup_update()
	_spike_update()
	_exit_update()
	_refresh_hud()

func _knife_hits() -> void:
	var pp := player_node.position
	for e in enemies:
		if e["dead"] or e["hit_swing"] == swing_id:
			continue
		var ep: Vector3 = (e["node"] as Node3D).position
		var d := Vector2(ep.x - pp.x, ep.z - pp.z)
		if d.length() > KNIFE_RANGE:
			continue
		var ang: float = abs(wrapf(d.angle_to(Vector2(-sin(yaw), -cos(yaw))), -PI, PI))
		if ang > KNIFE_ARC:
			continue
		e["hit_swing"] = swing_id
		e["hp"] = int(e["hp"]) - knife_dmg
		e["cool"] = 0.35
		combo += 1
		combo_t = 3.0
		play_sfx(SFX_HIT)
		if int(e["hp"]) <= 0:
			_kill_enemy(e)

func _kill_enemy(e: Dictionary) -> void:
	e["dead"] = true
	kills += 1
	var gain := 50
	if e["elite"]:
		gain = 150
	if e["type"] == "tuhkanaama" and not e["elite"]:
		gain = 75
	if e["boss"]:
		gain = 500
	score += gain + combo * 5
	play_sfx(SFX_HIT2)
	(e["node"] as Node3D).visible = false
	if e["boss"]:
		announce("WARDEN DOWN! Reach the glowing exit.")

func _enemy_update(delta: float) -> void:
	var pp := player_node.position
	for e in enemies:
		if e["dead"]:
			continue
		var n: CharacterBody3D = e["node"]
		var d := Vector2(pp.x - n.position.x, pp.z - n.position.z)
		var dist := d.length()
		var dir: Vector2 = d / maxf(dist, 0.001)
		var sp: float = e["sp"]
		if e["cool"] > 0.0:
			e["cool"] = float(e["cool"]) - delta
		if e["type"] == "boss":
			_boss_move(e, n, dir, dist, delta)
		elif e["type"] == "dash":
			e["t"] = float(e["t"]) - delta
			if e["mode"] == "stalk":
				n.velocity.x = dir.x * sp
				n.velocity.z = dir.y * sp
				if e["t"] <= 0.0:
					e["mode"] = "tele"
					e["t"] = 0.6
			elif e["mode"] == "tele":
				n.velocity.x = 0.0
				n.velocity.z = 0.0
				e["mat"].emission_enabled = true
				if e["t"] <= 0.0:
					e["mode"] = "lunge"
					e["t"] = 0.45
					e["vx"] = dir.x * sp * 3.2
					e["vz"] = dir.y * sp * 3.2
					e["mat"].emission_enabled = false
			else:
				n.velocity.x = float(e["vx"])
				n.velocity.z = float(e["vz"])
				if e["t"] <= 0.0:
					e["mode"] = "stalk"
					e["t"] = 2.0 + rng.randf() * 2.0
		else:
			n.velocity.x = dir.x * sp
			n.velocity.z = dir.y * sp
		if not n.is_on_floor():
			n.velocity.y -= 22.0 * delta
		else:
			n.velocity.y = -0.5
		n.move_and_slide()
		if dist < 1.1 and iframes <= 0.0:
			hurt("daemon")

func _boss_move(e: Dictionary, n: CharacterBody3D, dir: Vector2, dist: float, delta: float) -> void:
	e["t"] = float(e["t"]) - delta
	if e["mode"] == "stalk":
		n.velocity.x = dir.x * float(e["sp"])
		n.velocity.z = dir.y * float(e["sp"])
		if e["t"] <= 0.0:
			e["mode"] = "tele"
			e["t"] = 0.7
	elif e["mode"] == "tele":
		n.velocity.x = 0.0
		n.velocity.z = 0.0
		e["mat"].emission_enabled = true
		if e["t"] <= 0.0:
			e["mode"] = "charge"
			e["t"] = 0.8
			e["vx"] = dir.x * 9.0
			e["vz"] = dir.y * 9.0
			e["mat"].emission_enabled = false
	else:
		n.velocity.x = float(e["vx"])
		n.velocity.z = float(e["vz"])
		if e["t"] <= 0.0:
			e["mode"] = "stalk"
			e["t"] = 3.0 + rng.randf() * 2.0
	e["st"] = float(e["st"]) - delta
	if e["st"] <= 0.0:
		e["st"] = 9.0
		var alive := 0
		for x in enemies:
			if not x["dead"]:
				alive += 1
		if alive < 6:
			_spawn_minion(n.position)

func _spawn_minion(at: Vector3) -> void:
	var cell := Vector2i(clampi(int(at.x / CELL), 1, TW - 2), clampi(int(at.z / CELL), 1, TH - 2))
	var e := _new_enemy(cell, "chase", false, false, 0.0)
	e["cell"] = cell
	enemies.append(e)
	_build_enemy_node(e)
	announce("The warden calls a minion!")

func _pickup_update() -> void:
	var pp := player_node.position
	for it in items:
		if it["taken"]:
			continue
		if pp.distance_to(it["pos"]) < 1.4:
			it["taken"] = true
			(it["node"] as Node3D).visible = false
			score += 100
			play_sfx(SFX_COIN)
			announce("Crystal taken (%d left)." % _crystals_left())
	for ex in extras:
		if ex["taken"]:
			continue
		if pp.distance_to(ex["pos"]) < 1.4:
			ex["taken"] = true
			(ex["node"] as Node3D).visible = false
			if ex["kind"] == "heart":
				hp = mini(max_hp, hp + 1)
				announce("Heart: +1 HP.")
			elif ex["kind"] == "sharp":
				knife_dmg = 2
				announce("Sharp knife: double damage.")
			else:
				speed_bonus += 1.0
				announce("Boots: faster.")
			play_sfx(SFX_COIN)

func _crystals_left() -> int:
	var n := 0
	for it in items:
		if not it["taken"]:
			n += 1
	return n

func _spike_update() -> void:
	if spike_cd > 0.0 or iframes > 0.0:
		return
	if cell_at_world(player_node.position) == "s":
		spike_cd = 1.0
		hurt("spike")

func _exit_update() -> void:
	var open := room_clear()
	exit_light.light_color = Color(0.1, 1.0, 0.35) if open else Color(0.15, 0.25, 0.4)
	(exit_node.get_child(0) as MeshInstance3D).visible = true
	if open and player_node.position.distance_to(exit_node.position) < 2.0:
		play_sfx(SFX_DOOR)
		if ri < ROOM_DEFS.size() - 1:
			score += 250
			_load_room(ri + 1)
		else:
			_win()

func hurt(src: String) -> void:
	if iframes > 0.0 or state != "play":
		return
	hp -= 1
	iframes = 1.2
	combo = 0
	play_sfx(SFX_HURT)
	if src == "spike":
		announce("Spikes! Watch the floor.")
	if hp <= 0:
		state = "dead"
		play_sfx(SFX_DEATH)
		_refresh_overlays()

func _win() -> void:
	state = "win"
	play_sfx(SFX_WIN)
	_refresh_overlays()

# ---------------- builders ----------------

func _mat(color: Color, emission: Color = Color(0, 0, 0), e_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if e_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = e_energy
	return m

func _box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	return mi

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.02, 0.02, 0.07)
	sm.sky_horizon_color = Color(0.25, 0.2, 0.15)
	sm.ground_bottom_color = Color(0.01, 0.01, 0.02)
	sm.ground_horizon_color = Color(0.12, 0.09, 0.07)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.04, 0.08)
	env.fog_density = 0.03
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.78)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48, -35, 0)
	add_child(sun)
	# rain streaks falling around the player
	rain = GPUParticles3D.new()
	rain.amount = 160
	rain.lifetime = 1.1
	rain.preprocess = 1.1
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.1, -1, 0)
	pm.spread = 6.0
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 22.0
	pm.gravity = Vector3(0, -4, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(14, 1, 14)
	rain.process_material = pm
	var streak := BoxMesh.new()
	streak.size = Vector3(0.03, 0.5, 0.03)
	streak.material = _mat(Color(0.6, 0.7, 0.85, 0.6))
	rain.draw_pass_1 = streak
	rain.visibility_aabb = AABB(Vector3(-16, -8, -16), Vector3(32, 16, 32))
	add_child(rain)

func _build_player() -> void:
	player_node = CharacterBody3D.new()
	player_node.collision_layer = 2
	player_node.collision_mask = 1
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	player_node.add_child(col)
	var skin := _mat(Color(1.0, 0.89, 0.78))
	var hoodie := _mat(Color(0.16, 0.62, 0.56))
	var hair_m := _mat(Color(1.0, 0.7, 0.78))
	var hair_d := _mat(Color(0.88, 0.5, 0.64))
	var shoe_m := _mat(Color(0.23, 0.16, 0.23))
	body_mesh = MeshInstance3D.new()
	var torso := CapsuleMesh.new()
	torso.radius = 0.34
	torso.height = 1.0
	torso.material = hoodie
	body_mesh.mesh = torso
	body_mesh.position = Vector3(0, 1.05, 0)
	player_node.add_child(body_mesh)
	# head + hair + ears (back view: hair covers)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.26
	hs.height = 0.52
	hs.material = skin
	head.mesh = hs
	head.position = Vector3(0, 1.78, 0)
	player_node.add_child(head)
	var hair := _box(Vector3(0.56, 0.5, 0.3), hair_m)
	hair.position = Vector3(0, 1.82, 0.14)
	player_node.add_child(hair)
	for ex in [-0.18, 0.18]:
		var ear := _box(Vector3(0.12, 0.2, 0.1), hair_m)
		ear.position = Vector3(ex, 2.1, 0.1)
		player_node.add_child(ear)
		var inner := _box(Vector3(0.06, 0.1, 0.05), _mat(Color(0.79, 0.34, 0.42)))
		inner.position = Vector3(ex, 2.1, 0.05)
		player_node.add_child(inner)
	# legs on hip pivots
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.16, 0.78, 0)
		var leg := _box(Vector3(0.2, 0.72, 0.22), skin)
		leg.position = Vector3(0, -0.36, 0)
		pivot.add_child(leg)
		var shoe := _box(Vector3(0.24, 0.14, 0.34), shoe_m)
		shoe.position = Vector3(0, -0.7, -0.04)
		pivot.add_child(shoe)
		player_node.add_child(pivot)
		if side < 0.0:
			leg_l = pivot
		else:
			leg_r = pivot
	# right arm pivot + knife
	arm_r = Node3D.new()
	arm_r.position = Vector3(0.48, 1.35, 0)
	var arm := _box(Vector3(0.16, 0.55, 0.18), hoodie)
	arm.position = Vector3(0, -0.25, 0)
	arm_r.add_child(arm)
	var grip := _box(Vector3(0.09, 0.22, 0.09), _mat(Color(0.35, 0.23, 0.11)))
	grip.position = Vector3(0, -0.55, -0.1)
	arm_r.add_child(grip)
	knife_blade = _box(Vector3(0.07, 0.09, 0.75), _mat(Color(0.85, 0.88, 0.95), Color(0.9, 0.95, 1.0), 0.6))
	knife_blade.position = Vector3(0, -0.55, -0.55)
	arm_r.add_child(knife_blade)
	player_node.add_child(arm_r)
	var arm_l := _box(Vector3(0.16, 0.55, 0.18), hoodie)
	arm_l.position = Vector3(-0.48, 1.1, 0)
	player_node.add_child(arm_l)
	add_child(player_node)
	# chase camera rig: yaw + shoulder offset, spring arm pulls in on walls
	cam_rig = Node3D.new()
	add_child(cam_rig)
	spring = SpringArm3D.new()
	spring.position = Vector3(0.9, 0.5, 0)
	spring.spring_length = 4.6
	spring.margin = 0.3
	spring.collision_mask = 1
	cam_rig.add_child(spring)
	spring.add_excluded_object(player_node.get_rid())
	cam = Camera3D.new()
	cam.fov = 70.0
	spring.add_child(cam)

func _build_room_nodes() -> void:
	if room_node:
		room_node.queue_free()
	room_node = Node3D.new()
	room_node.name = "Room"
	add_child(room_node)
	var floor_a := _mat(Color(0.23, 0.18, 0.15))
	var floor_b := _mat(Color(0.17, 0.14, 0.11))
	var ceil_m := _mat(Color(0.04, 0.04, 0.09))
	var wall_m := _mat(Color(0.42, 0.35, 0.28))
	var pillar_m := _mat(Color(0.35, 0.35, 0.4))
	var spike_m := _mat(Color(0.24, 0.24, 0.29), Color(0.8, 0.1, 0.1), 0.8)
	# one big floor slab for collision
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	var fcol := CollisionShape3D.new()
	var fshape := BoxShape3D.new()
	fshape.size = Vector3(TW * CELL + 4, 1.0, TH * CELL + 4)
	fcol.shape = fshape
	fcol.position = Vector3(TW * CELL / 2.0 - CELL / 2.0, -0.5, TH * CELL / 2.0 - CELL / 2.0)
	static_body.add_child(fcol)
	room_node.add_child(static_body)
	# checker floor tiles (visual) + ceiling
	for my in TH:
		for mx in TW:
			var wx := mx * CELL
			var wz := my * CELL
			var t := _box(Vector3(CELL * 0.98, 0.08, CELL * 0.98), floor_a if (mx + my) % 2 == 0 else floor_b)
			t.position = Vector3(wx, -0.04, wz)
			room_node.add_child(t)
			var c := _box(Vector3(CELL * 0.98, 0.08, CELL * 0.98), ceil_m)
			c.position = Vector3(wx, WALL_H + 0.6, wz)
			room_node.add_child(c)
	# walls / pillars / spikes / exit
	for my in TH:
		for mx in TW:
			var ch: String = grid[my][mx]
			var wx := mx * CELL
			var wz := my * CELL
			if ch == "#" or ch == "P":
				var h := WALL_H
				var b := StaticBody3D.new()
				b.collision_layer = 1
				b.collision_mask = 0
				var cs := CollisionShape3D.new()
				var bs := BoxShape3D.new()
				bs.size = Vector3(CELL, h, CELL)
				cs.shape = bs
				cs.position = Vector3(wx, h / 2.0, wz)
				b.add_child(cs)
				var mi := _box(Vector3(CELL, h, CELL), pillar_m if ch == "P" else wall_m)
				mi.position = Vector3(wx, h / 2.0, wz)
				b.add_child(mi)
				room_node.add_child(b)
			elif ch == "s":
				var s := _box(Vector3(CELL * 0.9, 0.34, CELL * 0.9), spike_m)
				s.position = Vector3(wx, 0.17, wz)
				room_node.add_child(s)
			elif ch == "E":
				exit_node = Area3D.new()
				exit_node.position = Vector3(wx, 0.0, wz)
				var pillar := _box(Vector3(1.0, WALL_H, 1.0), _mat(Color(0.1, 0.5, 0.3), Color(0.1, 1.0, 0.4), 1.2))
				pillar.position = Vector3(0, WALL_H / 2.0, 0)
				exit_node.add_child(pillar)
				exit_light = OmniLight3D.new()
				exit_light.position = Vector3(0, 2.0, 0)
				exit_light.omni_range = 7.0
				exit_light.light_color = Color(0.15, 0.25, 0.4)
				exit_node.add_child(exit_light)
				room_node.add_child(exit_node)
	# pickups + enemies
	for it in items:
		var p: Vector2i = it["cell"]
		var node := _box(Vector3(0.5, 0.8, 0.5), _mat(Color(0.05, 0.6, 0.25), Color(0.0, 0.8, 0.4), 1.0))
		node.position = Vector3(p.x * CELL, 1.0, p.y * CELL)
		node.rotation.y = 0.6
		room_node.add_child(node)
		it["pos"] = Vector3(p.x * CELL, 0.0, p.y * CELL)
		it["node"] = node
		it["taken"] = false
	for ex in extras:
		var p: Vector2i = ex["cell"]
		var col := Color(1, 0, 0)
		if ex["kind"] == "sharp":
			col = Color(1.0, 0.84, 0.0)
		elif ex["kind"] == "boots":
			col = Color(0.29, 0.17, 0.07)
		var node := _box(Vector3(0.45, 0.45, 0.45), _mat(col, col, 0.8))
		node.position = Vector3(p.x * CELL, 0.9, p.y * CELL)
		room_node.add_child(node)
		ex["pos"] = Vector3(p.x * CELL, 0.0, p.y * CELL)
		ex["node"] = node
		ex["taken"] = false
	for e in enemies:
		_build_enemy_node(e)

func _build_enemy_node(e: Dictionary) -> void:
	var p: Vector2i = e["cell"]
	var body_col := Color(1, 0, 0)
	if e["type"] == "dash":
		body_col = Color(0.63, 0.0, 1.0)
	if e["elite"]:
		body_col = Color(1.0, 0.53, 0.0)
	if e["boss"]:
		body_col = Color(1.0, 0.75, 0.0)
	if e["type"] == "tuhkanaama":
		body_col = Color(0.04, 0.04, 0.05) # soot-black, eyes glow out
	var scale_f := 1.0
	if e["elite"]:
		scale_f = 1.35
	if e["boss"]:
		scale_f = 1.9
	var n := CharacterBody3D.new()
	n.collision_layer = 4
	n.collision_mask = 1
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4 * scale_f
	cap.height = 1.4 * scale_f
	col.shape = cap
	col.position = Vector3(0, 0.8 * scale_f, 0)
	n.add_child(col)
	var mat := _mat(body_col)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4 * scale_f
	cm.height = 1.4 * scale_f
	cm.material = mat
	mi.mesh = cm
	mi.position = Vector3(0, 0.8 * scale_f, 0)
	n.add_child(mi)
	var eyes := _box(Vector3(0.5 * scale_f, 0.16 * scale_f, 0.1), _mat(Color(1, 1, 1), Color(1, 1, 1), 0.7))
	eyes.position = Vector3(0, 1.15 * scale_f, -0.32 * scale_f)
	n.add_child(eyes)
	n.position = Vector3(p.x * CELL, 0.1, p.y * CELL)
	(room_node if room_node else self).add_child(n)
	e["node"] = n
	e["mesh"] = mi
	e["mat"] = mat

func _place_player_spawn() -> void:
	player_node.position = Vector3(1.5 * CELL, 0.1, TH * CELL / 2.0 - CELL / 2.0)
	yaw = -PI / 2.0 # face +X down the cave
	cam_rig.position = player_node.position + Vector3(0, 1.7, 0)
	cam_rig.rotation.y = yaw

# ---------------- HUD / audio ----------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_top = Label.new()
	hud_top.position = Vector2(12, 8)
	hud_top.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud_top)
	hud_room = Label.new()
	hud_room.position = Vector2(12, 32)
	hud_room.add_theme_font_size_override("font_size", 14)
	hud_room.add_theme_color_override("font_color", Color(1, 1, 0))
	layer.add_child(hud_room)
	hud_combo = Label.new()
	hud_combo.position = Vector2(12, 54)
	hud_combo.add_theme_font_size_override("font_size", 14)
	hud_combo.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	layer.add_child(hud_combo)
	hud_cap = Label.new()
	hud_cap.position = Vector2(12, 80)
	hud_cap.size = Vector2(1100, 40)
	hud_cap.add_theme_font_size_override("font_size", 15)
	hud_cap.add_theme_color_override("font_color", Color(1, 1, 0.4))
	layer.add_child(hud_cap)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/femboy.png") as Texture2D
	portrait.position = Vector2(12, 560)
	portrait.custom_minimum_size = Vector2(96, 108)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(portrait)
	minimap = preload("res://minimap.gd").new()
	minimap.position = Vector2(1152 - 20 * 8 - 24, 44)
	layer.add_child(minimap)
	minimap.game = self
	title_panel = _overlay(layer, "CATERPILLAR: KNIFE OF THE MOTHER 3D", "Seeded caves. Modifiers. Permadeath.\nNo tears. Only knife.\n\nWASD move | Arrows turn | SPACE slash | R reroll | P pause\n\nPress ENTER to spawn")
	dead_panel = _overlay(layer, "YOU DIED", "The cave keeps the knife.\nPress ENTER for a new cave.")
	win_panel = _overlay(layer, "DELIVERED!", "The caterpillar crawls home.\nPress ENTER for a new cave.")
	pause_label = Label.new()
	pause_label.text = "PAUSED — ENTER or P to resume"
	pause_label.position = Vector2(400, 300)
	pause_label.add_theme_font_size_override("font_size", 28)
	pause_label.visible = false
	layer.add_child(pause_label)

func _overlay(layer: CanvasLayer, title: String, body: String) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.position = Vector2(276, 150)
	pc.custom_minimum_size = Vector2(600, 300)
	var vb := VBoxContainer.new()
	pc.add_child(vb)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	vb.add_child(t)
	var b := Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 16)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(b)
	pc.visible = false
	layer.add_child(pc)
	return pc

func _refresh_hud() -> void:
	var hearts := ""
	for i in max_hp:
		hearts += "H" if i < hp else "-"
	hud_top.text = "LV %02d  HP %s %d/%d  SCORE %06d" % [ri + 1, hearts, hp, max_hp, score]
	hud_combo.text = ("COMBO x%d" % combo) if combo > 1 else ""

func _refresh_overlays() -> void:
	title_panel.visible = state == "title"
	dead_panel.visible = state == "dead"
	win_panel.visible = state == "win"
	pause_label.visible = state == "play" and paused_game
	_refresh_hud()

func show_title() -> void:
	state = "title"
	_refresh_overlays()
	hud_room.text = "The hero waits in the dark."
	hud_cap.text = ""

func announce(text: String) -> void:
	hud_cap.text = text
	cap_t = 5.0

func _build_audio() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)

func play_sfx(stream: AudioStream) -> void:
	var p: AudioStreamPlayer = sfx_players[sfx_i]
	sfx_i = (sfx_i + 1) % sfx_players.size()
	p.stream = stream
	p.volume_db = -6.0
	p.play()

# ---------------- autoplay smoke hook ----------------

func _autoplay(delta: float) -> void:
	auto_t += 1
	if auto_t == 30:
		start_run(1234)
		return
	if state == "dead" or state == "win":
		start_run(1234 + auto_t) # smoke hook keeps exercising
		return
	if state != "play" or auto_t < 30:
		return
	# cheat-walk the critical path: nearest crystal, else exit
	if auto_t % 240 == 0:
		var target := Vector3(EXIT_CELL.x * CELL, 0, EXIT_CELL.y * CELL)
		var best := 1e9
		for it in items:
			if it["taken"]:
				continue
			var d: float = player_node.position.distance_to(it["pos"])
			if d < best:
				best = d
				target = it["pos"]
		if room_clear():
			target = Vector3(EXIT_CELL.x * CELL, 0, EXIT_CELL.y * CELL)
		player_node.position = target + Vector3(0.5, 0.1, 0.0)
