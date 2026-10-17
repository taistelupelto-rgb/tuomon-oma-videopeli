extends Node2D
## Ski jump minigame, golden edition: inrun tuck, takeoff timing at the
## edge, V-style flight with wind, telemark landing, judges + K-point.

var state := "idle"
var score := 0.0
var best := 0.0
var speed := 0.0
var pos := Vector2(80, 420)
var vel := Vector2.ZERO
var angle := 0.0
var style := 0.0
var dist_pts := 0.0
var judges := [0.0, 0.0, 0.0]
var wind := 0.0
var takeoff_t := 0.0
var takeoff_q := 0.0
var telemark := false
var crash_spin := 0.0
var tick := 0
var hud: Label

const IN_A := Vector2(80, 420)
const IN_B := Vector2(520, 560)
const LAND_A := Vector2(560, 570)
const LAND_B := Vector2(1400, 900)
const K_PT := 60.0 # K-point in meters
const TAKEOFF_WINDOW := 0.35
const GRAV := 900.0

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

func _meters() -> float:
	return maxf(0.0, (pos.x - IN_B.x) / 10.0)

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
	dist_pts = 0.0
	judges = [0.0, 0.0, 0.0]
	telemark = false
	takeoff_q = 0.0
	wind = randf_range(-2.0, 2.0) # + headwind lifts, - tailwind sinks
	score = 0.0
	state = "slide"

# quality 0..1: 1.0 is the perfect edge hit, early or late loses power
func _do_jump(q: float) -> void:
	takeoff_q = clampf(q, 0.0, 1.0)
	var dir := (IN_B - IN_A).normalized()
	vel = dir * speed * (0.9 + 0.1 * takeoff_q) + Vector2(0, -(140.0 + 150.0 * takeoff_q))
	angle = -12.0
	state = "flight"

func _press_jump() -> void:
	if state == "slide":
		# early jump: quality fades with distance left to the edge
		_do_jump(1.0 - clampf((IN_B.x - pos.x) / 300.0, 0.0, 1.0))
	elif state == "takeoff":
		_do_jump(1.0 - takeoff_t / TAKEOFF_WINDOW)

func _judge(total_style: float) -> void:
	for i in 3:
		judges[i] = clampf(total_style / 3.0 + randf_range(-1.5, 1.5), 0.0, 20.0)
	style = judges[0] + judges[1] + judges[2]

func _finish_landing(err: float, sweet: bool) -> void:
	var dist := _meters()
	dist_pts = 60.0 + 2.0 * (dist - K_PT)
	var base := 60.0 - err * 2.0 - vel.y * 0.05 + (6.0 if sweet else 0.0)
	_judge(maxf(0.0, base))
	score = dist_pts + style
	if score > best:
		best = score
		_best_save()
	state = "landed"

func _finish_crash() -> void:
	score = maxf(0.0, dist_pts if dist_pts > 0.0 else _meters())
	if score > best:
		best = score
		_best_save()
	crash_spin = 0.0
	state = "crashed"

func _try_land() -> void:
	var h := _slope_y(pos.x) - pos.y
	if h > 60.0:
		return # still airborne, ignore early tap
	var sa := _slope_angle_at(pos.x)
	var err := absf(angle - sa)
	telemark = h > 8.0 and h <= 34.0 # telemark: committed late, skis split
	if err < 22.0 and vel.y < 750.0:
		_finish_landing(err, telemark)
	else:
		_finish_crash()

func _press_action() -> void:
	if state == "idle":
		_start_slide()
	elif state == "slide" or state == "takeoff":
		_press_jump()
	elif state == "flight":
		_try_land()
	elif state == "landed" or state == "crashed":
		_start_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press_action()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed:
		_press_action()
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
			_press_action()
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
	tick += 1
	if state == "slide":
		var crouch := Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		speed += (260.0 + (120.0 if crouch else 0.0)) * delta
		var dir := (IN_B - IN_A).normalized()
		pos += dir * speed * delta
		angle = _slope_angle_at(pos.x)
		if pos.x >= IN_B.x:
			pos = IN_B
			takeoff_t = 0.0
			state = "takeoff"
	elif state == "takeoff":
		takeoff_t += delta
		if takeoff_t >= TAKEOFF_WINDOW:
			_do_jump(0.25) # late: the table throws you off weak
	elif state == "flight":
		if Input.is_physical_key_pressed(KEY_UP):
			angle = clampf(angle - 40.0 * delta, -30.0, 40.0)
		if Input.is_physical_key_pressed(KEY_DOWN):
			angle = clampf(angle + 40.0 * delta, -30.0, 40.0)
		var v := vel.length()
		# V-style: flat body (angle near -10) maximizes lift, steep kills it
		var lift := 200.0 * cos(deg_to_rad(angle + 10.0)) * clampf(v / 600.0, 0.0, 1.5)
		lift *= 1.0 + wind * 0.12 # headwind lifts, tailwind sinks
		vel.y += (GRAV - lift) * delta
		vel.x += wind * 14.0 * delta
		var drag := 0.12 + 0.55 * absf(sin(deg_to_rad(angle + 10.0)))
		vel *= maxf(0.0, 1.0 - drag * delta)
		pos += vel * delta
		if pos.y >= _slope_y(pos.x):
			pos.y = _slope_y(pos.x)
			var sa := _slope_angle_at(pos.x)
			var err := absf(angle - sa)
			if err < 22.0 and vel.y < 750.0:
				_finish_landing(err, false)
			else:
				_finish_crash()
	elif state == "crashed":
		crash_spin += delta * 9.0
	position.x = minf(0.0, -(pos.x - 300.0))
	if is_instance_valid(hud):
		hud.position = Vector2(-position.x + 16.0, 16.0)
		var warrow := ">>" if wind > 0.7 else ("<<" if wind < -0.7 else "--")
		hud.text = "%s spd=%d dist=%.1fm wind=%s%.1f ang=%.0f score=%.1f best=%.1f" % [state, int(speed if state == "slide" or state == "takeoff" else vel.length()), _meters(), warrow, absf(wind), angle, score, best]
	queue_redraw()

func _snow(camx: float) -> void:
	for i in 24:
		var sx := camx + fmod(float(i * 173 + tick * (2 + i % 5)), 1400.0)
		var sy := fmod(float(i * 311 + tick * (6 + i % 7)), 1000.0) - 100.0
		draw_circle(Vector2(sx, sy), 2.0 + float(i % 3), Color(1, 1, 1, 0.8))

func _pines() -> void:
	for i in 12:
		var px := 620.0 + float(i) * 68.0
		var py := _slope_y(px) + 26.0
		var s := 14.0 + fmod(float(i * 37), 10.0)
		draw_colored_polygon([Vector2(px, py - s * 2.2), Vector2(px - s * 0.7, py - s), Vector2(px + s * 0.7, py - s)], Color(0.08, 0.35, 0.15))
		draw_colored_polygon([Vector2(px, py - s * 1.6), Vector2(px - s * 0.9, py - s * 0.2), Vector2(px + s * 0.9, py - s * 0.2)], Color(0.1, 0.42, 0.18))
		draw_line(Vector2(px, py - s * 0.2), Vector2(px, py), Color(0.3, 0.2, 0.1), 3.0)

func _draw() -> void:
	var camx := -position.x
	# sky gradient bands + sun + clouds
	for b in 6:
		var bc := Color(0.35 + 0.035 * b, 0.68 + 0.02 * b, 0.95)
		draw_rect(Rect2(camx - 500.0, -500.0 + b * 260.0, 3000.0, 260.0), bc)
	draw_circle(Vector2(camx + 1150.0, -260.0), 60.0, Color(1, 1, 0.85))
	for c in 3:
		var cx := camx + 250.0 + c * 420.0
		var cy := -300.0 + c * 60.0
		draw_circle(Vector2(cx, cy), 34.0, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(cx + 34.0, cy + 8.0), 26.0, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(cx - 34.0, cy + 10.0), 24.0, Color(1, 1, 1, 0.9))
	# hills behind
	draw_colored_polygon([Vector2(camx - 500, 700), Vector2(camx + 400, 250), Vector2(camx + 1300, 700)], Color(0.75, 0.85, 0.9))
	draw_colored_polygon([Vector2(camx + 800, 700), Vector2(camx + 1700, 180), Vector2(camx + 2500, 700)], Color(0.7, 0.82, 0.88))
	# inrun + landing slopes
	draw_colored_polygon([Vector2(80, 420), Vector2(520, 560), Vector2(520, 590), Vector2(80, 450)], Color(1, 1, 1))
	draw_colored_polygon([Vector2(560, 570), Vector2(1400, 900), Vector2(1400, 930), Vector2(560, 600)], Color(1, 1, 1))
	draw_line(Vector2(80, 420), Vector2(520, 560), Color(0.2, 0.2, 0.2), 2.0)
	draw_line(Vector2(560, 570), Vector2(1400, 900), Color(0.2, 0.2, 0.2), 2.0)
	# takeoff edge marker (red = jump zone)
	draw_line(Vector2(520, 560), Vector2(520 + 18.0 * cos(deg_to_rad(-12.0)), 560 + 18.0 * sin(deg_to_rad(-12.0))), Color(1, 0, 0), 5.0)
	# K-point line + 50m board
	var kx := IN_B.x + K_PT * 10.0
	draw_line(Vector2(kx, _slope_y(kx) - 46.0), Vector2(kx, _slope_y(kx) + 6.0), Color(1, 0, 0), 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(kx - 22.0, _slope_y(kx) - 52.0), "K-60", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0, 0))
	var bx := IN_B.x + 500.0
	draw_string(font, Vector2(bx - 20.0, _slope_y(bx) - 40.0), "50m", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
	_pines()
	if state == "flight" or state == "takeoff":
		_snow(camx)
	# takeoff timing bar
	if state == "takeoff":
		var frac := 1.0 - takeoff_t / TAKEOFF_WINDOW
		var bc2 := Color(0.1, 0.8, 0.1) if frac > 0.5 else (Color(0.9, 0.8, 0.1) if frac > 0.25 else Color(0.9, 0.1, 0.1))
		draw_rect(Rect2(camx + 120.0, 300.0, 300.0 * frac, 24.0), bc2)
		draw_string(font, Vector2(camx + 120.0, 290.0), "JUMP NOW!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0, 0, 0))
	# wind arrow
	var wx := camx + 120.0
	var wy := 340.0
	var wdir := 1.0 if wind >= 0.0 else -1.0
	draw_line(Vector2(wx, wy), Vector2(wx + wdir * (20.0 + absf(wind) * 30.0), wy), Color(0.1, 0.1, 0.8), 4.0)
	draw_string(font, Vector2(wx, wy + 26.0), "wind %.1f" % wind, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0))
	if state == "idle":
		draw_string(font, Vector2(camx + 120.0, 200.0), "SKI JUMP GOLD - CLICK OR ENTER TO START", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0, 0, 0))
		draw_string(font, Vector2(camx + 120.0, 240.0), "HOLD DOWN TO TUCK - HIT EDGE AT FULL BAR - LEAN IN AIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
		draw_string(font, Vector2(camx + 120.0, 270.0), "TAP LATE FOR TELEMARK - R RESETS - BEST %.1f" % best, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
	# jumper
	var ski_ang := angle if state == "flight" or state == "takeoff" else _slope_angle_at(pos.x)
	var sd := Vector2.RIGHT.rotated(deg_to_rad(ski_ang))
	if state == "crashed":
		var rc := pos + Vector2(0, -20)
		var r1 := sd.rotated(crash_spin) * 22.0
		var r2 := sd.rotated(-crash_spin * 1.3) * 22.0
		draw_line(rc - r1, rc + r1, Color(0.8, 0.1, 0.1), 4.0)
		draw_line(rc - r2, rc + r2, Color(0.8, 0.1, 0.1), 4.0)
		draw_circle(pos + Vector2(0, -58), 7.0, Color(1.0, 0.85, 0.7))
		draw_line(pos + Vector2(-4, -61), pos + Vector2(0, -57), Color(0, 0, 0), 2.0)
		draw_line(pos + Vector2(-4, -57), pos + Vector2(0, -61), Color(0, 0, 0), 2.0)
		draw_line(pos + Vector2(1, -61), pos + Vector2(5, -57), Color(0, 0, 0), 2.0)
		draw_line(pos + Vector2(1, -57), pos + Vector2(5, -61), Color(0, 0, 0), 2.0)
	else:
		if state == "flight" and absf(angle + 10.0) < 12.0:
			# V-style: skis split open at the tips
			var tip := pos + sd * 30.0
			draw_line(pos - sd * 16.0, tip + sd.rotated(1.2) * 8.0, Color(0.8, 0.1, 0.1), 4.0)
			draw_line(pos - sd * 16.0, tip + sd.rotated(-1.2) * 8.0, Color(0.8, 0.1, 0.1), 4.0)
		elif telemark and state == "landed":
			# telemark: one ski forward, one back, knees bent
			draw_line(pos - sd * 26.0, pos + sd * 30.0, Color(0.8, 0.1, 0.1), 4.0)
			draw_line(pos - sd * 34.0, pos + sd * 12.0, Color(0.6, 0.08, 0.08), 4.0)
		else:
			draw_line(pos - sd * 22.0, pos + sd * 22.0, Color(0.8, 0.1, 0.1), 4.0)
		draw_line(pos, pos + Vector2(-6, -28), Color(0, 0, 0), 3.0)
		draw_circle(pos + Vector2(-8, -34), 7.0, Color(1.0, 0.85, 0.7))
	if state == "landed" or state == "crashed":
		var msg := "%.1fm DIST %.1f STYLE %.1f (%.1f %.1f %.1f) TOTAL %.1f BEST %.1f" % [_meters(), dist_pts, style, judges[0], judges[1], judges[2], score, best] if state == "landed" else "CRASHED %.1fm BEST %.1f" % [score, best]
		draw_string(font, Vector2(camx + 120.0, 200.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0, 0, 0))
		draw_string(font, Vector2(camx + 120.0, 240.0), "CLICK OR ENTER TO JUMP AGAIN - R TITLE - J EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0))
