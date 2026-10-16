extends Node2D

var state := "idle"
var score := 0.0
var best := 0.0
var speed := 0.0
var pos := Vector2(80, 420)
var vel := Vector2.ZERO
var angle := 0.0
var style := 0.0
var hud: Label
var drag_last_y := -1.0

const IN_A := Vector2(80, 420)
const IN_B := Vector2(520, 560)
const LAND_A := Vector2(560, 570)
const LAND_B := Vector2(1400, 900)

func _best_load() -> void:
	if not FileAccess.file_exists("user://ski_best.cfg"):
		return
	var f := FileAccess.open("user://ski_best.cfg", FileAccess.READ)
	if f == null:
		return
	best = maxf(0.0, float(f.get_line()))
	f.close()

func _best_save() -> void:
	var f := FileAccess.open("user://ski_best.cfg", FileAccess.WRITE)
	if f == null:
		return
	f.store_line(str(best))
	f.close()

func _ready() -> void:
	_best_load()
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_color", Color(0, 0, 0))
	hud.position = Vector2(16, 16)
	add_child(hud)
	visible = false

func _slope_y(x: float) -> float:
	if x <= IN_B.x:
		var t := clampf((x - IN_A.x) / (IN_B.x - IN_A.x), 0.0, 1.0)
		return lerpf(IN_A.y, IN_B.y, t)
	if x < LAND_A.x:
		var t2 := (x - IN_B.x) / (LAND_A.x - IN_B.x)
		return lerpf(IN_B.y, LAND_A.y, t2)
	var t3 := clampf((x - LAND_A.x) / (LAND_B.x - LAND_A.x), 0.0, 1.0)
	return lerpf(LAND_A.y, LAND_B.y, t3)

func _slope_angle_at(x: float) -> float:
	if x <= IN_B.x:
		return rad_to_deg(atan2(IN_B.y - IN_A.y, IN_B.x - IN_A.x))
	return rad_to_deg(atan2(LAND_B.y - LAND_A.y, LAND_B.x - LAND_A.x))

func _start_slide() -> void:
	pos = IN_A
	speed = 220.0
	angle = _slope_angle_at(IN_A.x)
	vel = Vector2.ZERO
	style = 0.0
	score = 0.0
	state = "slide"

func _do_jump() -> void:
	var dir := (IN_B - IN_A).normalized()
	vel = dir * speed + Vector2(0, -180)
	angle = -12.0
	state = "flight"

func _try_land() -> void:
	if pos.y < _slope_y(pos.x) - 60.0:
		return # still airborne, ignore early tap
	var sa := _slope_angle_at(pos.x)
	var err := absf(angle - sa)
	if err < 22.0 and vel.y < 750.0:
		style = maxf(0.0, 60.0 - err * 2.0 - vel.y * 0.05)
		var dist := maxf(0.0, (pos.x - IN_B.x) / 10.0)
		score = dist + style
		if score > best:
			best = score
			_best_save()
		state = "landed"
	else:
		score = maxf(0.0, (pos.x - IN_B.x) / 10.0)
		if score > best:
			best = score
			_best_save()
		state = "crashed"

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == "idle":
			_start_slide()
		elif state == "slide":
			_do_jump()
		elif state == "flight":
			_try_land()
		elif state == "landed" or state == "crashed":
			_start_slide()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed:
		if state == "idle":
			_start_slide()
		elif state == "slide":
			_do_jump()
		elif state == "flight":
			_try_land()
		elif state == "landed" or state == "crashed":
			_start_slide()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		if state == "flight":
			angle = clampf(angle + event.relative.y * 0.15, -30.0, 40.0)
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if state == "flight":
			angle = clampf(angle + event.relative.y * 0.15, -30.0, 40.0)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k == KEY_R:
			if state == "idle":
				visible = false
			else:
				state = "idle"
			get_viewport().set_input_as_handled()
		elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
			if state == "idle":
				_start_slide()
			elif state == "slide":
				_do_jump()
			elif state == "flight":
				_try_land()
			elif state == "landed" or state == "crashed":
				_start_slide()
			get_viewport().set_input_as_handled()
		elif k == KEY_UP and state == "flight":
			angle = clampf(angle - 4.0, -30.0, 40.0)
			get_viewport().set_input_as_handled()
		elif k == KEY_DOWN and state == "flight":
			angle = clampf(angle + 4.0, -30.0, 40.0)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return
	if state == "slide":
		var crouch := Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		speed += (260.0 + (120.0 if crouch else 0.0)) * delta
		var dir := (IN_B - IN_A).normalized()
		pos += dir * speed * delta
		angle = _slope_angle_at(pos.x)
		if pos.x >= IN_B.x:
			pos = IN_B
			_do_jump()
	elif state == "flight":
		if Input.is_physical_key_pressed(KEY_UP):
			angle = clampf(angle - 40.0 * delta, -30.0, 40.0)
		if Input.is_physical_key_pressed(KEY_DOWN):
			angle = clampf(angle + 40.0 * delta, -30.0, 40.0)
		vel.y += 900.0 * delta
		if vel.length() > 300.0:
			vel += Vector2(0, -1) * (140.0 * cos(deg_to_rad(angle))) * delta
		pos += vel * delta
		if pos.y >= _slope_y(pos.x):
			pos.y = _slope_y(pos.x)
			_try_land()
	position.x = minf(0.0, -(pos.x - 300.0))
	if is_instance_valid(hud):
		hud.position = Vector2(-position.x + 16.0, 16.0)
		var dist := maxf(0.0, (pos.x - IN_B.x) / 10.0)
		hud.text = "%s spd=%d dist=%.1fm ang=%.0f score=%.1f best=%.1f" % [state, int(speed if state == "slide" else vel.length()), dist, angle, score, best]
	queue_redraw()

func _draw() -> void:
	var camx := -position.x
	draw_rect(Rect2(camx - 500.0, -500.0, 3000.0, 2000.0), Color(0.55, 0.8, 0.95))
	draw_colored_polygon([Vector2(80, 420), Vector2(520, 560), Vector2(520, 590), Vector2(80, 450)], Color(1, 1, 1))
	draw_colored_polygon([Vector2(560, 570), Vector2(1400, 900), Vector2(1400, 930), Vector2(560, 600)], Color(1, 1, 1))
	draw_line(Vector2(520, 560), Vector2(520 + 18.0 * cos(deg_to_rad(-12.0)), 560 + 18.0 * sin(deg_to_rad(-12.0))), Color(1, 0, 0), 5.0)
	draw_line(Vector2(80, 420), Vector2(520, 560), Color(0.2, 0.2, 0.2), 2.0)
	draw_line(Vector2(560, 570), Vector2(1400, 900), Color(0.2, 0.2, 0.2), 2.0)
	var font := ThemeDB.fallback_font
	if state == "idle":
		draw_string(font, Vector2(camx + 120.0, 200.0), "SKI JUMP - CLICK OR ENTER TO START", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0, 0, 0))
		draw_string(font, Vector2(camx + 120.0, 240.0), "HOLD DOWN TO CROUCH - SPACE TO JUMP AND LAND", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
		draw_string(font, Vector2(camx + 120.0, 270.0), "R RESETS - BEST %.1f" % best, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
	var ski_ang := angle if state == "flight" else _slope_angle_at(pos.x)
	var sd := Vector2.RIGHT.rotated(deg_to_rad(ski_ang))
	if state == "crashed":
		draw_line(pos + Vector2(-20, -14), pos + Vector2(20, 6), Color(0.7, 0.1, 0.1), 4.0)
		draw_line(pos + Vector2(-20, 6), pos + Vector2(20, -14), Color(0.7, 0.1, 0.1), 4.0)
		draw_line(pos + Vector2(-6, -52), pos + Vector2(6, -28), Color(0, 0, 0), 3.0)
		draw_circle(pos + Vector2(0, -58), 7.0, Color(1.0, 0.85, 0.7))
		draw_line(pos + Vector2(-4, -61), pos + Vector2(0, -57), Color(0, 0, 0), 2.0)
		draw_line(pos + Vector2(-4, -57), pos + Vector2(0, -61), Color(0, 0, 0), 2.0)
		draw_line(pos + Vector2(1, -61), pos + Vector2(5, -57), Color(0, 0, 0), 2.0)
		draw_line(pos + Vector2(1, -57), pos + Vector2(5, -61), Color(0, 0, 0), 2.0)
	else:
		draw_line(pos - sd * 22.0, pos + sd * 22.0, Color(0.8, 0.1, 0.1), 4.0)
		draw_line(pos, pos + Vector2(-6, -28), Color(0, 0, 0), 3.0)
		draw_circle(pos + Vector2(-8, -34), 7.0, Color(1.0, 0.85, 0.7))
	if state == "landed" or state == "crashed":
		var msg := "LANDED %.1f (STYLE %.1f) BEST %.1f" % [score, style, best] if state == "landed" else "CRASHED %.1fM BEST %.1f" % [score, best]
		draw_string(font, Vector2(camx + 120.0, 200.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0, 0, 0))
		draw_string(font, Vector2(camx + 120.0, 240.0), "CLICK OR ENTER TO JUMP AGAIN - R TITLE - J EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
