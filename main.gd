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
var exit_cell: Vector2i = Vector2i(18, 6)
const SPAWN_CELL := Vector2i(1, 6)
const WALK_SPEED := 5.2
const TURN_SPEED := 2.1
const LOOK_YAW := 2.4 # right-stick max yaw rate, rad/s
const BUILD_TAG := "v0.61.3"
const LOOK_PITCH := 2.6 # right-stick max pitch rate, rad/s
const LOOK_EXPO := 1.35 # stick curve: fine aim center, fast edges
const LOOK_DEAD := 0.12 # stick deadzone
const KNIFE_RANGE := 3.0
const KNIFE_ARC := 1.0 # radians, half-angle
const CAM_PITCH_MIN := -0.35
const CAM_PITCH_MAX := 0.6
const FOLLOW_CAM := true
const SHITBOMB_MAX := 3
const SHITBOMB_REGEN := 8.0
const SHITBOMB_RADIUS := 4.5
const SHITBOMB_DMG := 2
const SHITBOMB_GRAV := 22.0

const ROOM_DEFS := [
	{"name": "ROOM A — SPAWN CAVE", "about": "Grab the crystal, find the glowing exit. Every run, a new cave.", "pillars": 2, "crys": 1, "en": 0, "spikes": 0, "elites": 0, "heart": false, "sharp": false},
	{"name": "ROOM B — THE BRIDGE", "about": "Daemons guard the pipe. Slash them: face them, hold KNIFE (SPACE).", "pillars": 4, "crys": 2, "en": 2, "spikes": 3, "elites": 1, "heart": true, "sharp": false},
	{"name": "ROOM C — THE AGENT THINKS", "about": "Crystals are context, the knife is the shell. Clear the room to open the exit.", "pillars": 5, "crys": 2, "en": 3, "spikes": 4, "elites": 1, "heart": true, "sharp": true},
	{"name": "ROOM D — DELIVERY", "about": "The CAVE WARDEN guards the exit: it charges and calls minions. Kill it.", "pillars": 4, "crys": 1, "en": 2, "spikes": 3, "elites": 1, "boss": true, "heart": false, "sharp": false},
]

const MODIFIERS := ["NONE", "NONE", "SWARM", "SWIFT", "FAMINE", "RICH"]

# ---------------- lore ----------------
# The cave remembers. The codex (key C) holds it all.
const LORE_INTRO := "Before the cave, there was the Mother: a caterpillar the size of a harvest moon, who ate the sky green and slept under the world. From her last egg hatched you — small, soft, and furious. The cave took your siblings. It left you one knife. No tears. Only knife."
const LORE_OUTRO := "DELIVERED. The knife returns to the Mother's egg-shell altar, and the cave, for one night, stops hungering. Somewhere below, a new egg cracks. The Mother provides."
const LORE_ROOMS := [
	"ROOM A — the Mother's throat. The walls here are warm. She swallowed this cave whole to hide it from the sky-eaters. The crystal is her milk-tooth. Take it.",
	"ROOM B — the Bridge. Long ago the caterpillar-folk strung a rope of spit and song across the dark so messages could travel: phone, bot, agent, phone. Daemons nest in the ropes now. They eat messengers.",
	"ROOM C — the Thinking Dark. The agent dreams here. Every crystal is a thought it almost finished. The knife is the only argument the dark respects. Elites are thoughts that learned to bite back.",
	"ROOM D — the Warden's gullet. The CAVE WARDEN was the Mother's guard-dog, fed on exit-doors until it forgot every door but hunger. Kill it kindly. It remembers being good.",
]
const LORE_ENEMIES := {
	"chase": "HOLLOW CHASER — a daemon that forgot its own name and chases yours instead. It runs at what it fears. It fears you rightly.",
	"dash": "LUNGE-MAW — it shows its white eyes before it strikes. Old miners say the flash is the last light its victims ever see. Sidestep the telegraph.",
	"tuhkanaama": "TUHKANAAMA — the Soot-Face. Once the Mother's chimney-sweep, black with honest ash. It fell into the Thinking Dark and now it hungers. It loves watermelons more than anything: each melon recalls the summer fields above. It eats to remember. Its teeth glow white with the memory of every seed it ever spat at the sun. Beat it to 1 HP and it remembers the collar: it kneels, and it is yours. The final exit opens only for masters.",
	"boss": "THE CAVE WARDEN — heap-big hunger, the Mother's firstborn guard. It charges what it cannot understand and summons the small hungers to its side. Under the gold hide, it still wears its puppy collar. You will not see it. It is there.",
	"irwin": "IRWIN — the wheelchair warrior. Beat him and he joins the haul, whooping WUHU WAKAWAKAWAKA and hurling shit at his old friends.",
}
const LORE_ITEMS := {
	"crys": "MILK-TOOTH CRYSTAL — a tooth the Mother shed while dreaming of you. The agent drinks these like context. Carry them out.",
	"heart": "BLOOD-APPLE HEART — not an apple, not a heart. It beats anyway. +1 HP. The cave grew it around a miner's lost wedding ring.",
	"sharp": "GRANDMOTHER'S EDGE — a whetstone that remembers every blade. Permanent double knife damage. It hums lullabies when swung.",
	"boots": "DANCER'S BOOTS — seven-league slippers, slightly used. The previous owner danced out of the cave and never stopped. Faster feet.",
	"melon": "SUN-MELON — a watermelon smuggled down from the summer fields. Sweet, heavy, green as envy. Heals. But beware: the Tuhkanaama smells it from three caves away, and it will cross the dark for a taste.",
}
const LORE_EXIT := "THE GLOWING EXIT — a door the Warden swallowed and could not digest. It opens only for the worthy: every crystal carried, every daemon answered. The final door demands more: a chained tuhkanaama at your heel. Green means go. Gold means master."
const LORE_GOAL := "GOAL: break a TUHKANAAMA with your knife (beat it to 1 HP and it kneels), chain it, and haul it through all four rooms to the final exit. The cave only releases masters."
const LORE_MODS := {
	"SWARM": "Omen SWARM — the dark is extra hungry tonight. More daemons.",
	"SWIFT": "Omen SWIFT — the daemons drank the underground river. They run fast.",
	"FAMINE": "Omen FAMINE — no hearts grow this run. The cave keeps them.",
	"RICH": "Omen RICH — the Mother's pockets are full. Extra crystals, quicker feet.",
	"NONE": "Omen NONE — a quiet night in the cave. Relatively.",
}

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
const SFX_CHAINED := preload("res://assets/sfx/chained.ogg")
const SFX_WARDEN := preload("res://assets/sfx/warden_down.ogg")
const VOICE_TEXT := preload("res://assets/voices/voices_text.gd")
# demo-scene grease: fullscreen grain+vignette+scanline post, flowing river
const POST_SHADER := """shader_type canvas_item;
uniform float grain_amt = 0.05;
uniform float vig_amt = 0.55;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }
void fragment() {
	vec2 d = UV - vec2(0.5);
	float edge = smoothstep(0.95, 0.25, length(d) * 1.7);
	float g = hash(UV * vec2(1920.0, 1080.0) + vec2(TIME * 61.7, -TIME * 43.3)) - 0.5;
	float scan = 0.965 + 0.035 * sin(UV.y * 700.0);
	COLOR = vec4(vec3(0.0), clamp((1.0 - edge) * vig_amt + g * grain_amt, 0.0, 1.0) * scan + g * 0.02);
}
"""
const RIVER_SHADER := """shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_schlick_ggx;
uniform vec4 deep : source_color = vec4(0.05, 0.2, 0.45, 0.8);
uniform vec4 foam : source_color = vec4(0.4, 0.8, 1.0, 0.8);
void fragment() {
	vec2 w = UV * 24.0;
	float flow = TIME * 1.2;
	float bands = sin(w.x * 1.7 + w.y * 3.1 - flow * 4.0) * 0.5 + 0.5;
	float bands2 = sin(w.x * 3.3 - w.y * 1.2 + flow * 2.0) * 0.5 + 0.5;
	vec2 cell = floor(w * 3.0);
	float spark = step(0.986, fract(sin(dot(cell + floor(vec2(flow * 6.0, -flow * 5.0)), vec2(12.9898, 78.233))) * 43758.55));
	vec3 col = mix(deep.rgb, foam.rgb, bands * bands2 * 0.55);
	ALBEDO = col;
	EMISSION = foam.rgb * (bands * bands2 * 0.5 + spark * 1.2);
	ALPHA = 0.8;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
}
"""
const SKY_SHADER := """shader_type sky;
void sky() {
	float h = clamp(EYEDIR.y, -1.0, 1.0);
	vec3 col = mix(vec3(0.10, 0.07, 0.06), vec3(0.005, 0.008, 0.03), smoothstep(-0.1, 0.6, h));
	vec2 sp = EYEDIR.xz / max(0.15, EYEDIR.y + 0.4);
	vec2 cell = floor(sp * 90.0);
	float star = step(0.992, fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.55));
	float tw = 0.5 + 0.5 * sin(TIME * (2.0 + fract(cell.x * 0.37) * 4.0) + cell.y);
	col += vec3(0.9, 0.95, 1.0) * star * tw * smoothstep(0.05, 0.4, h);
	vec3 md = normalize(vec3(-0.45, 0.55, -0.6));
	float m = dot(EYEDIR, md);
	col += vec3(0.95, 0.93, 0.8) * smoothstep(0.9992, 0.9997, m);
	col += vec3(0.4, 0.42, 0.35) * pow(max(m, 0.0), 60.0) * 0.4;
	float band = sin(EYEDIR.x * 4.0 + TIME * 0.35 + sin(EYEDIR.z * 3.0 + TIME * 0.22) * 1.5);
	float curt = smoothstep(0.1, 0.55, h) * smoothstep(0.95, 0.45, h);
	float rays = 0.6 + 0.4 * sin(EYEDIR.x * 40.0 + EYEDIR.z * 25.0 + TIME * 0.8);
	float a = curt * (0.5 + 0.5 * band) * rays;
	col += vec3(0.1, 0.9, 0.45) * a * 0.55;
	col += vec3(0.45, 0.2, 0.8) * a * a * 0.5;
	COLOR = col;
}
"""
const FLAME_SHADER := """shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 hot : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.4, 0.1, 1.0);
void vertex() {
	float sway = VERTEX.y + 0.35;
	VERTEX.x += sin(VERTEX.y * 9.0 + TIME * 13.0) * 0.10 * sway;
	VERTEX.z += cos(VERTEX.y * 7.0 + TIME * 11.0) * 0.10 * sway;
}
void fragment() {
	float h = clamp(UV.y, 0.0, 1.0);
	vec3 col = mix(mid.rgb, hot.rgb, h * h);
	float flick = 0.85 + 0.15 * sin(TIME * 23.0 + UV.y * 20.0);
	ALBEDO = col * flick;
}
"""
const BEAM_SHADER := """shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, unshaded, fog_disabled;
uniform vec4 glow : source_color = vec4(0.3, 1.0, 0.5, 1.0);
void fragment() {
	float flow = fract(UV.y * 2.0 - TIME * 0.7);
	float bands = smoothstep(0.0, 0.35, flow) * smoothstep(1.0, 0.55, flow);
	float edge = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.75, UV.x);
	ALBEDO = glow.rgb;
	ALPHA = (0.12 + bands * 0.35) * edge;
}
"""
const PLASMA_SHADER := """shader_type canvas_item;
void fragment() {
	vec2 p = UV * 6.0;
	float v = sin(p.x + TIME * 0.7) + sin(p.y * 1.3 - TIME * 0.9) + sin((p.x + p.y) * 0.8 + TIME * 0.5) + sin(length(p - 3.0) * 1.5 - TIME * 1.1);
	v *= 0.25;
	vec3 col = 0.5 + 0.5 * cos(TIME * 0.4 + vec3(v * 6.28, v * 6.28 + 2.1, v * 6.28 + 4.2));
	COLOR = vec4(col * 0.55, 1.0);
}
"""
const JOKER_BG := preload("res://assets/joker.jpg")
const SFX_SCREAM := preload("res://assets/sfx/death_scream.ogg")
const SFX_LAUGH := preload("res://assets/sfx/death_laugh.ogg")
const SFX_CHAIN := preload("res://assets/sfx/chain_rattle.ogg")
const SFX_THUNDER := preload("res://assets/sfx/thunder.ogg")
const SFX_PLOP := preload("res://assets/sfx/seed_plop.ogg")
const SEED_CD := 2.0
const SEED_RANGE := 16.0
const SEED_SPEED := 12.0
const MUSIC_STREAM := preload("res://assets/music.mp3")
const DMG_YELL := preload("res://assets/voices/dmg_yell_01.ogg")
const FOE_YELL := preload("res://assets/voices/foe_yell_01.ogg")
const ENEMY_LOOK := preload("res://assets/diarra.jpg")
const BOSS_LOOK := preload("res://assets/paleface.jpg")
const IRWIN_LOOK := preload("res://assets/irwin.jpg")
const PALEFACE_LINES := ["emme suostu pelkäämään", "vitun natsit!", "falafel pierettää vitusti"]

const VOICE_COUNTS := {"room_a": 8, "room_b": 8, "room_c": 8, "room_d": 8,
	"foe_chase": 8, "foe_dash": 8, "foe_tuhk": 8, "boss_see": 6,
	"pk_crys": 8, "pk_heart": 8, "pk_sharp": 6, "pk_boots": 6, "pk_melon": 8,
	"hurt": 10, "spike": 6, "kill": 12, "combo": 8, "chain": 8,
	"boss_taunt": 8, "boss_die": 4, "win": 6, "die": 8,
	"lowhp": 8, "idle": 16, "exit_need": 6, "exit_open": 4}
var voice_bank := {}
var voice_cache := {}
var tex_cache := {}
var voice_cd := 0.0
var exit_voiced := -1

var state := "title" # title | play | dead | win
var paused_game := false
var seed_value := 1
var modifier := "NONE"
var rng := RandomNumberGenerator.new()
var ri := 0
var hp := 3
var max_hp := 5
var score := 0
var best_score := 0
var kills := 0
var combo := 0
var combo_t := 0.0
var knife_dmg := 1
var speed_bonus := 0.0
var iframes := 0.0
var dmg_flash := 0.0
var dmg_rect: ColorRect
var tick := 0

var grid: Array = []
var player_node: CharacterBody3D
var cam_rig: Node3D
var spring: SpringArm3D
var cam: Camera3D
var hero_sprite: Sprite3D
var hero_tex1: Texture2D
var hero_tex2: Texture2D
var hero_tex_slash: Texture2D
var slash_arc: Sprite3D
var slash_arc_tex: Texture2D
var shadow_tex: Texture2D
var shadow_mat: StandardMaterial3D
var yaw := 0.0
var cam_yaw := 0.0
var cam_pitch := -0.2
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
var lantern: OmniLight3D
var river_mat: Material
var river_cells: Array = []
var torches: Array = []
var rain: CPUParticles3D
var dust: CPUParticles3D
var kill_flash := 0.0
var kill_rect: ColorRect
var hitstop_n := 0
var cave_env: Environment
var bolt_t := 12.0
var shake := 0.0
var rings: Array = []
var plasma: ColorRect
var last_combo := 0
var combo_pop := 0.0
var shit_trail: CPUParticles3D
var hero_moving := false
var shit_ammo := SHITBOMB_MAX
var shit_regen_t := 0.0
var shitbombs: Array = [] # flying turds: {node, vel, t}
var shitsplats: Array = [] # ground splats: {node, mat, t}
var chain_player: AudioStreamPlayer
var seeds: Array = [] # watermelon seeds: {node, vel, t}
var leash_mat: StandardMaterial3D
var seed_mat: StandardMaterial3D

var hud_top: Label
var hud_cap: Label
var hud_room: Label
var hud_combo: Label
var hud_inv: Label
var cap_t := 0.0
var cap_hist: Array = []
var r_arm_t := 0.0
var exit_nag_t := 0.0
var title_panel: PanelContainer
var ski_btn: Button
var dead_panel: PanelContainer
var dead_bg: TextureRect
var death_scream_player: AudioStreamPlayer
var death_laugh_player: AudioStreamPlayer
var death_laugh_t := -1.0
var cs_active := false
var cs_lines: Array = []
var cs_i := 0
var cs_t := 0.0
var cs_cache := {}
var cs_dim: ColorRect
var cs_panel: PanelContainer
var cs_title: Label
var cs_cap: Label
var cs_player: AudioStreamPlayer
var win_panel: PanelContainer
var codex_panel: PanelContainer
var seen := {}
var pause_label: Label
var minimap: Control
var sfx_players: Array = []
var sfx_i := 0
var music_player: AudioStreamPlayer
var dmg_yell_player: AudioStreamPlayer
var foe_yell_player: AudioStreamPlayer3D
var autoplay := false
var auto_t := 0
var inventory: Array = [] # slots: {kind, count}. persists rooms, dies on new run.
const INV_SLOTS := 8
var probe_swings := 0
var probe_hits := 0
var probe_calls := 0
var probe_min_arc := 99.0
var touch_move := Vector2.ZERO
var touch_slash := false
var joy_id := -1
var look_id := -1
var joy_origin := Vector2.ZERO
var joy_vec := Vector2.ZERO
var look_last := Vector2.ZERO
var joy_base: Panel
var joy_knob: Panel
var ball_id := -1
var ball_origin := Vector2.ZERO
var look_vec := Vector2.ZERO # right-stick deflection, -1..1 (x yaw, y pitch)
var look_sm := Vector2.ZERO # smoothed copy, applied as camera rate
var ball_base: Panel
var ball_knob: Panel
var touch_layer: CanvasLayer
var look_block: Array = [] # right-side controls the camera stick must not steal
var has_touch := false
var jump_node: Node2D

func _hs_load() -> void:
	if not FileAccess.file_exists("user://best.cfg"): return
	var f := FileAccess.open("user://best.cfg", FileAccess.READ)
	if f == null: return
	var line := f.get_line()
	if line != "": best_score = maxi(0, int(line))
func _hs_save() -> void:
	var f := FileAccess.open("user://best.cfg", FileAccess.WRITE)
	if f == null: return
	f.store_line(str(best_score))
func _ready() -> void:
	autoplay = false
	for a in OS.get_cmdline_user_args():
		if String(a).trim_prefix("--") == "autoplay":
			autoplay = true
	_build_environment()
	_build_player()
	_build_hud()
	jump_node = (load("res://ski_jump.gd") as GDScript).new()
	jump_node.visible = false
	add_child(jump_node)
	_build_audio()
	_build_voice_bank()
	_hs_load()
	show_title()

func _build_voice_bank() -> void:
	for cat in VOICE_COUNTS:
		var arr: Array = []
		for i in range(1, int(VOICE_COUNTS[cat]) + 1):
			arr.append("%s_%02d.ogg" % [cat, i])
		voice_bank[cat] = arr

func say(cat: String, pos: Vector3 = Vector3.INF) -> void:
	if state != "play" or voice_cd > 0.0:
		return
	if not voice_bank.has(cat) or (voice_bank[cat] as Array).is_empty():
		return
	var bank: Array = voice_bank[cat]
	var f: String = bank[rng.randi_range(0, bank.size() - 1)]
	var stream: AudioStream
	if voice_cache.has(f):
		stream = voice_cache[f]
	else:
		stream = load("res://assets/voices/" + f) as AudioStream
		if stream == null:
			return
		voice_cache[f] = stream
	voice_cd = 5.0
	play_sfx(stream, pos)
	var sub: String = VOICE_TEXT.LINES.get(f, "")
	if sub != "" and cap_t <= 1.0:
		announce(sub)

# ---------------- pixel sprites (hand-made, in code) ----------------
const HERO_BACK_1 := [
	"....XXXXXXXX....",
	"...XHHHHHHHHX...",
	"...XHwHHHHwHX...",
	"...XHwHHHHwHX...",
	"...XHHSSSSHHX...",
	".GG.XHHHHHHX....",
	".GGGXXHHHHXX....",
	".....XGGGGGX....",
	"....XGGGGGGGX...",
	"....XGgGGGGgX...",
	"....XGgGGGGgX...",
	"....XGGGGGGGX...",
	".....XGGGGGX....",
	".....XPPPPPX....",
	".....XPpPPpX....",
	".....XPpPPpX....",
	"....XPPX..XPPX..",
	"....XPPX..XPPX..",
	"....XBBX..XBBX..",
	"....XBBX..XBBX..",
]
const HERO_BACK_2 := [
	"....XXXXXXXX....",
	"...XHHHHHHHHX...",
	"...XHHHwHHwHX...",
	"...XHHHwHHwHX...",
	"...XHHSSSSHHX...",
	"....XHHHHHHX.GG.",
	"....XXHHHHXXGGG.",
	"....XGGGGGX.....",
	"...XGGGGGGGX....",
	"...XGgGGGGgX....",
	"...XGgGGGGgX....",
	"...XGGGGGGGX....",
	"....XGGGGGX.....",
	"....XPPPPPX.....",
	"....XPpPPpX.....",
	"....XPpPPpX.....",
	".....XPPPPX.....",
	".....XPPPPX.....",
	".....XPPPPX.....",
	".....XBBBBX.....",
]
const HERO_SLASH := [
	"....HHHHHHHH....",
	"...HHHHHHHHHH...",
	"...HhHHHHHHhH...",
	"...HhHHHHHHhH...",
	"...HHHSSSSHHH...",
	"....HHHHHHHH..W.",
	"....HHHHHHHH.WW.",
	".....GGGGGG.WW..",
	"....GGGGGGGGWW..",
	"....GgGGGGgGW...",
	".KKKGgGGGGgGW...",
	".KKKKGGGGGGGW...",
	"..NNGGGGGGGGW...",
	".....GGGGGG.W...",
	".....PPPPPP.....",
	".....PpPPpP.....",
	".....PpPPpP.....",
	"....PP....PP....",
	"....PP....PP....",
	"....BB....BB....",
]
const IMP_CHASE := [
	"...KK......KK...",
	"...KHHK..KHHK...",
	"...KHHK..KHHK...",
	"...KKRRRRRRKK...",
	"...KRRRRRRRRK...",
	"...KRWWRRWWRK...",
	"...KRWWRRWWRK...",
	"...KRRRrrRRRK...",
	"...KRRWWWWRRK...",
	"....KRRRRRRK....",
	"....KRrRRrRK....",
	"...KRRRRRRRRK...",
	"..KRRRRRRRRRRK..",
	"..KRrRK..KRrRK..",
	"...KRRK..KRRK...",
	"...KBBK..KBBK...",
]
const IMP_DASH := [
	"................",
	"..........PP....",
	".........PPPC...",
	"....P...PPPPP...",
	".....PPPPPPP....",
	".....WPPPPPC....",
	".....WPPPPPP....",
	"......pppPP.....",
	"...P..PPPpp.....",
	"....PPPPPP......",
	".....PPPP.......",
	"....PPP.PPP.....",
	"...PPP...PPP....",
	"...Pp.....Pp....",
	"....B.....B.....",
	"................",
]
const TUHK := [
	"................",
	"....KKKKKKKK....",
	"...KKKKkKKKKK...",
	"...KKWWKKWWKK...",
	"...KKWWKKWWKK...",
	"...KKkKKKKkKK...",
	"....KKKKKKKK....",
	"....KWWWWWWK....",
	"....KWKWWKWK....",
	"....KWWWWWWK....",
	"....KRKRRKRK....",
	"....KKKKKKKK....",
	"...KKkKKKKkKK...",
	"...KkKKKKKKkK...",
	"....KKK..KKK....",
	"....BB....BB....",
]
const BOSS := [
	"....K..K..K.....",
	"...KGK.KGK.KGK..",
	"..KGGGGGGGGGGK..",
	"..KGWGGGGGGWGK..",
	"..KGWGGGGGGWGK..",
	"..KGGGGGGGGGGK..",
	"...KGGGGGGGGK...",
	"....KCCCCCCK....",
	"...KCCWCCWCCK...",
	"..KGGGCWWCGGGK..",
	"..KGgGCWWCgGGK..",
	"..KGgGCWWCgGGK..",
	"..KGGGCWWCGGGK..",
	"...KGGK..KGGK...",
	"...KBBK..KBBK...",
	"...KBBK..KBBK...",
]
const CRYS := [
	"................",
	".......CC.......",
	"......CCCW......",
	".....CCCCW......",
	".....CcCCW......",
	"....CCcCCCW.....",
	"....CcCCCCC.....",
	"...CCcCCCCWC....",
	"...CcCCCCCC.....",
	"....CcCCCC......",
	"....CCcCC.......",
	".....CCC........",
	"......C.........",
	"................",
	"................",
	"................",
]
const HEART := [
	"................",
	"................",
	"...HHH..HHH.....",
	"..HWHH..HHHH....",
	"..HWHHHHHHHH....",
	"..HHHHHHHHHH....",
	"..HhHHHHHHH.....",
	"...hHHHHHH......",
	"....HHHHH.......",
	".....HHH........",
	"......H.........",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const SHARP := [
	"................",
	"................",
	"................",
	".....GGGGGG.....",
	"....GGGGGGWG....",
	"....GgGGGGGG....",
	"....GGgGGGgG....",
	"....GGGGGGGG....",
	".....gggggg.....",
	".....BBBBBB.....",
	".....BBBBBB.....",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const BOOTS := [
	"................",
	"................",
	"................",
	"................",
	"....BB...BB.....",
	"....BBW..BBW....",
	"....BB...BB.....",
	"....BBb..BBb....",
	"....BBb..BBb....",
	"....BBBBBBBB....",
	"....BBBBBBBB....",
	"....bbbbbbbb....",
	"................",
	"................",
	"................",
	"................",
]
const MELON := [
	"................",
	"................",
	"................",
	".....ggggg......",
	"....gGgGgGgW....",
	"...gGgGgGgGg....",
	"...gGgGgGgGgW...",
	"...gGgGgGgGg....",
	"...gGgGgGgGg....",
	"....gGgGgGg.....",
	".....ggggg......",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const ARC_SLASH := [
	"................",
	".........WW.....",
	".......WWWW.....",
	"......WWWW......",
	".....WWWW.......",
	"....WWWW...W....",
	"....WWW...WW....",
	"...WWWW..WW.....",
	"...WWWWWW.......",
	"....WWWWW.......",
	"....WWWW........",
	"....WWWWW.......",
	".....WWWWW......",
	"......WWWWW.....",
	".......WWWWW....",
	".........WW.....",
]
# ---------------- cool pixelart cave (no obloid blobs) ----------------
const CAVE_PAL := {
	"k": Color("0b0b10"), "d": Color("1c1826"), "s": Color("322b42"),
	"l": Color("574e6b"), "w": Color("8a80a0"), "g": Color("1e4423"),
	"m": Color("4caf3a"), "y": Color("7a6a3a"), "r": Color("5a2a22"),
	"o": Color("e08a2d"),
}
const FLOOR_A := [
	"kkkkkkkkkkkkkkkk",
	"kddssddssddssddk",
	"kdsdsdsdsdsdsdsk",
	"kssddssddrddssdk",
	"kddssddsrddssddk",
	"kdsgdsdsrsdsdsgk",
	"kssddssrslssddsk",
	"kddssdsrllssdddk",
	"kdsdssrrllssdmdk",
	"kssddsrrllssdmgk",
	"kddssdsrllssggmk",
	"kdsdsdsrslsggmsk",
	"kssddssddssddsdk",
	"kddssddssddssddk",
	"kdsdsdsdsdsdsdsk",
	"kkkkkkkkkkkkkkkk",
]
const FLOOR_B := [
	"kkkkkkkkkkkkkkkk",
	"kssddssddssddssk",
	"ksdsdsdsdsdsdsdk",
	"kddssddssddssddk",
	"kssddssddssddsdk",
	"kgmdsdsdsdsdssdk",
	"kggmdsrddssddsdk",
	"kddgmsrslssddssk",
	"kssddsrllssddssk",
	"kddssdrllssddssk",
	"kdsdsdrllssddssk",
	"kssddsrllsddrssk",
	"kddssdrllsddrssk",
	"kdsdsdsdsdsdrssk",
	"kssddssddssddssk",
	"kkkkkkkkkkkkkkkk",
]
const WALL_TEX := [
	"llllllllllllllll",
	"dddkdddkdddkdddk",
	"dwdksddkydkdddkd",
	"kkkkkkkkkkkkkkkk",
	"dkdddkdddkdddkdd",
	"dkdrdkdddkdddkdd",
	"skdddkdddkdddkdd",
	"kkkkkkkkkkkkkkkk",
	"dddkdddkdddkdddk",
	"dddkddokdddkdddk",
	"dddkdddkdddkdddk",
	"kkkkkkkkkkkkkkkk",
	"dkdddkdddkdddkdd",
	"dgddkgdddkdgdkdd",
	"ggmgkgggkgmgkggm",
	"kkkkkkkkkkkkkkkk",
]
const PILLAR_TEX := [
	"kkddddddddddddkk",
	"kkddssssssssddkk",
	"kkddsllssllsddkk",
	"kkddslwsswlsddkk",
	"kkddslwsswlsddkk",
	"kkddsllssllsddkk",
	"kkddssrssrssddkk",
	"kkddssrssrssddkk",
	"kkddssrssrssddkk",
	"kkddsllssllsddkk",
	"kkddslwsswloddkk",
	"kkddsllssllsddkk",
	"kkddssssssssddkk",
	"kkddgssssssgddkk",
	"kkdggggmggmggdkk",
	"kkddddddddddddkk",
]
const SPIKE_TEX := [
	"RRRRRRRRRRRRRRRR",
	"RWWRRRWWRRRWWRRR",
	"RRRRRRRRRRRRRRRR",
	"rRRRrRRRrRRRrRRR",
	"DDDDDDDDDDDDDDDD",
	"DdDdDdDdDdDdDdDd",
	"DDDDDDDDDDDDDDDD",
	"ssssssssssssssss",
	"ssssssssssssssss",
	"YDYDYDYDYDYDYDYD",
	"DYDDDDDDDDDDDDDY",
	"YDYDYDYDYDYDYDYD",
	"DDDDDDDDDDDDDDDD",
	"dDdDdDdDdDdDdDdD",
	"DDDDDDDDDDDDDDDD",
	"dDdDdDdDdDdDdDdD",
]
const EXIT_TEX := [
	"DDDDDDDDDDDDDDDD",
	"DDggggggggggggDD",
	"DggggGGGGGGggggD",
	"DggGGGLLGGGGGLgD",
	"DgGGGLWWLGGGGGGD",
	"DgGGLWWWWLGGGGgD",
	"DgGGLWWWWLGGGLgD",
	"DgGGGLWWWLGgGLgD",
	"DgGLGgWWWWLGGGgD",
	"DgGGGLWWWLGGGLgD",
	"DgGGGLWWLLGGGGgD",
	"DgGGGGLWLLGGGLgD",
	"DggGGGGLLLLGGGgD",
	"DggggGGGGGGGGggD",
	"DDggggggggggggDD",
	"DDDDDDDDDDDDDDDD",
]
const COLLAR_TEX := [
	"GgGgGgGgGgGgGgGg",
	"GWGgGWGgGWGgGWGg",
	"GgGGWRWRRRWGGGgG",
	"gggggggggggggggg",
]
const SHADOW_PX := [
	"................",
	"................",
	".....SSSSS......",
	"...SSSSSSSS.....",
	"..SSSSSSSSSS....",
	"..SSSSSSSSSS....",
	".SSSSSSSSSSSS...",
	".SSSSSSSSSSSS...",
	".SSSSSSSSSSSS...",
	"..SSSSSSSSSS....",
	"..SSSSSSSSSS....",
	"...SSSSSSSS.....",
	".....SSSSS......",
	"................",
	"................",
	"................",
]
const RAIN_PX := [
	".C.",
	".C.",
	".W.",
	".C.",
]

func _pixel_tex(rows: Array, pal: Dictionary) -> ImageTexture:
	var h := rows.size()
	var w: int = (rows[0] as String).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch := row.substr(x, 1)
			img.set_pixel(x, y, pal.get(ch, Color(0, 0, 0, 0)))
	var tex := ImageTexture.create_from_image(img)
	return tex

func _cached_tex(key: String, rows: Array, pal: Dictionary) -> ImageTexture:
	var t = tex_cache.get(key)
	if t != null:
		return t
	t = _pixel_tex(rows, pal)
	tex_cache[key] = t
	return t

func _hero_pal() -> Dictionary:
	return {
		"H": Color(1.0, 0.62, 0.72), "h": Color(0.78, 0.38, 0.52),
		"S": Color(1.0, 0.89, 0.78),
		"G": Color(0.16, 0.62, 0.56), "g": Color(0.09, 0.42, 0.38),
		"P": Color(0.25, 0.25, 0.38), "p": Color(0.15, 0.15, 0.24),
		"B": Color(0.35, 0.22, 0.12),
		"K": Color(0.85, 0.88, 0.95), "N": Color(0.35, 0.23, 0.11),
		"W": Color(1, 1, 1),
		"X": Color(0.05, 0.04, 0.07), "w": Color(1.0, 0.82, 0.88),
	}

func _sprite3d(tex: Texture2D, pixel_size: float, y: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.pixel_size = pixel_size
	s.position = Vector3(0, y, 0)
	return s

var halo_tex: Texture2D
var spike_glow_mat: StandardMaterial3D
var exit_glow_mat: StandardMaterial3D
var exit_halo: Sprite3D

func _halo_tex() -> Texture2D:
	# one shared soft radial glow, tinted per use via modulate
	if halo_tex != null:
		return halo_tex
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	halo_tex = ImageTexture.create_from_image(img)
	return halo_tex

func _add_halo(parent: Node3D, color: Color, size: float, y: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = _halo_tex()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	s.modulate = color
	s.pixel_size = size / 32.0
	s.position = Vector3(0, y, 0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.render_priority = -1
	parent.add_child(s)
	return s

func _halo_color(kind: String) -> Color:
	if kind == "heart":
		return Color(1.0, 0.25, 0.35, 0.45)
	if kind == "melon":
		return Color(0.85, 1.0, 0.3, 0.45)
	if kind == "sharp":
		return Color(1.0, 0.8, 0.25, 0.45)
	if kind == "boots":
		return Color(1.0, 0.55, 0.2, 0.45)
	return Color(0.3, 1.0, 0.45, 0.45) # crys + default green

func _get_shadow_tex() -> Texture2D:
	if shadow_tex != null:
		return shadow_tex
	shadow_tex = _pixel_tex(SHADOW_PX, {"S": Color(0, 0, 0, 1)})
	return shadow_tex

func _get_shadow_mat() -> StandardMaterial3D:
	if shadow_mat != null:
		return shadow_mat
	shadow_mat = StandardMaterial3D.new()
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow_mat.albedo_color = Color(0, 0, 0, 0.55)
	shadow_mat.albedo_texture = _get_shadow_tex()
	return shadow_mat

func _add_shadow(parent: Node3D, size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1) * size
	pm.material = _get_shadow_mat()
	mi.mesh = pm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, 0.03, 0)
	parent.add_child(mi)
	return mi

func _poof(pos: Vector3, color: Color) -> void:
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 45.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.4
	p.color_ramp = _poof_ramp(color)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.16, 0.16)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.albedo_color = color
	bm.material = m
	p.mesh = bm
	p.position = pos
	(room_node if room_node else self).add_child(p)
	p.emitting = true
	var tree := get_tree()
	if tree != null:
		tree.create_timer(1.2).timeout.connect(p.queue_free)

func _poof_ramp(color: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, color)
	g.add_point(0.49, Color(1, 1, 1, 1))
	g.add_point(0.51, color)
	return g

func _enemy_tex(etype: String, boss: bool) -> Array:
	if boss:
		return [BOSS, {"G": Color(1.0, 0.75, 0.15), "g": Color(0.6, 0.4, 0.08), "W": Color(1, 1, 1), "C": Color(0.8, 0.1, 0.1), "B": Color(0.15, 0.1, 0.08), "K": Color(0.05, 0.03, 0.03)}]
	if etype == "dash":
		return [IMP_DASH, {"P": Color(0.63, 0.15, 0.95), "p": Color(0.35, 0.05, 0.55), "W": Color(1, 1, 1), "C": Color(0.4, 0.9, 1.0), "B": Color(0.12, 0.08, 0.14)}]
	if etype == "tuhkanaama":
		return [TUHK, {"K": Color(0.07, 0.07, 0.09), "k": Color(0.16, 0.15, 0.17), "W": Color(1, 1, 1), "R": Color(0.5, 0.08, 0.06), "B": Color(0.05, 0.05, 0.06)}]
	return [IMP_CHASE, {"R": Color(0.85, 0.15, 0.12), "r": Color(0.5, 0.08, 0.08), "H": Color(1.0, 0.85, 0.4), "W": Color(1, 1, 1), "B": Color(0.15, 0.1, 0.12), "K": Color(0.03, 0.02, 0.03)}]

func _item_tex(kind: String) -> Array:
	if kind == "heart":
		return [HEART, {"H": Color(0.9, 0.1, 0.15), "h": Color(0.5, 0.05, 0.08), "W": Color(1, 1, 1)}]
	if kind == "sharp":
		return [SHARP, {"G": Color(0.95, 0.78, 0.3), "g": Color(0.55, 0.42, 0.15), "W": Color(1, 1, 1), "B": Color(0.3, 0.2, 0.1)}]
	if kind == "boots":
		return [BOOTS, {"B": Color(0.45, 0.28, 0.12), "b": Color(0.25, 0.15, 0.06), "W": Color(0.9, 0.85, 0.7)}]
	if kind == "melon":
		return [MELON, {"G": Color(0.05, 0.45, 0.15), "g": Color(0.3, 0.75, 0.3), "W": Color(0.9, 1.0, 0.9)}]
	return [CRYS, {"C": Color(0.1, 0.85, 0.4), "c": Color(0.03, 0.4, 0.18), "W": Color(0.9, 1.0, 0.95)}]

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
	seen = {}
	inventory.clear()
	voice_cd = 0.0
	exit_voiced = -1
	exit_nag_t = 0.0
	cap_hist.clear()
	touch_move = Vector2.ZERO
	touch_slash = false
	joy_id = -1
	look_id = -1
	ball_id = -1
	look_vec = Vector2.ZERO
	look_sm = Vector2.ZERO
	shit_ammo = SHITBOMB_MAX
	shit_regen_t = 0.0
	death_laugh_t = -1.0
	for b in shitbombs:
		if is_instance_valid(b.get("node") as Node3D):
			(b.get("node") as Node3D).queue_free()
	shitbombs.clear()
	for s in shitsplats:
		if is_instance_valid(s.get("node") as Node3D):
			(s.get("node") as Node3D).queue_free()
	shitsplats.clear()
	for sd in seeds:
		if is_instance_valid(sd.get("node") as Node3D):
			(sd.get("node") as Node3D).queue_free()
	seeds.clear()
	if chain_player != null and chain_player.playing:
		chain_player.stop()
	if is_instance_valid(ball_knob) and is_instance_valid(ball_base):
		ball_knob.position = (ball_base.size - ball_knob.size) * 0.5
	joy_vec = Vector2.ZERO
	_load_room(0, false) # permadeath: no chains survive a new run
	state = "play"
	paused_game = false
	_refresh_overlays()
	play_sfx(SFX_FIGHT)
	announce("FIGHT! " + String(LORE_MODS.get(modifier, "")))
	music_play()

func _load_room(idx: int, keep_chained := true) -> void:
	ri = idx
	var chained: Array = [] # the enslaved march with you
	if keep_chained:
		for x in enemies:
			if x.get("enslaved", false) and not x["dead"]:
				x["cell"] = Vector2i(2, TH / 2)
				x["hit_swing"] = -1
				x["mode"] = "stalk"
				x["t"] = 3.0
				chained.append(x)
	_gen_grid()
	for x in chained:
		enemies.append(x)
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
	_play_cutscene(idx)

func _pick_exit_cell() -> Vector2i:
	if rng.randf() < 0.6:
		return Vector2i(TW - 2, rng.randi_range(1, TH - 2))
	return Vector2i(rng.randi_range(10, TW - 2), 1)

func _clear_radius(c: Vector2i, r: float) -> void:
	for y in TH:
		for x in TW:
			if x <= 0 or y <= 0 or x >= TW - 1 or y >= TH - 1:
				continue
			if Vector2(x - c.x, y - c.y).length() <= r:
				if grid[y][x] == "#" or grid[y][x] == "P":
					grid[y][x] = "."

func _bfs_reachable(from: Vector2i) -> Dictionary:
	var seen := {}
	if grid[from.y][from.x] == "#" or grid[from.y][from.x] == "P":
		return seen
	var q: Array = [from]
	seen[from] = true
	var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		for d in dirs:
			var nx: int = cur.x + d.x
			var ny: int = cur.y + d.y
			if nx < 0 or ny < 0 or nx >= TW or ny >= TH:
				continue
			var ch: String = grid[ny][nx]
			if ch == "#" or ch == "P":
				continue
			var np := Vector2i(nx, ny)
			if seen.has(np):
				continue
			seen[np] = true
			q.append(np)
	return seen

func _carve_line(a: Vector2i, b: Vector2i) -> void:
	var x := a.x
	var y := a.y
	if rng.randf() < 0.5:
		while x != b.x:
			x += 1 if b.x > x else -1
			if x > 0 and y > 0 and x < TW - 1 and y < TH - 1:
				if grid[y][x] != "E":
					grid[y][x] = "."
		while y != b.y:
			y += 1 if b.y > y else -1
			if x > 0 and y > 0 and x < TW - 1 and y < TH - 1:
				if grid[y][x] != "E":
					grid[y][x] = "."
	else:
		while y != b.y:
			y += 1 if b.y > y else -1
			if x > 0 and y > 0 and x < TW - 1 and y < TH - 1:
				if grid[y][x] != "E":
					grid[y][x] = "."
		while x != b.x:
			x += 1 if b.x > x else -1
			if x > 0 and y > 0 and x < TW - 1 and y < TH - 1:
				if grid[y][x] != "E":
					grid[y][x] = "."

func _gen_grid() -> void:
	var d: Dictionary = ROOM_DEFS[ri]
	grid.clear()
	for y in TH:
		var row: Array = []
		for x in TW:
			row.append("#" if (x == 0 or y == 0 or x == TW - 1 or y == TH - 1) else ".")
		grid.append(row)
	exit_cell = _pick_exit_cell()
	var nblobs := rng.randi_range(2, 4)
	for b in nblobs:
		var cx := rng.randi_range(2, TW - 3)
		var cy := rng.randi_range(2, TH - 3)
		var blen := rng.randi_range(6, 12)
		for i in blen:
			if cx > 0 and cy > 0 and cx < TW - 1 and cy < TH - 1:
				if Vector2(cx - SPAWN_CELL.x, cy - SPAWN_CELL.y).length() > 2.5 and Vector2(cx - exit_cell.x, cy - exit_cell.y).length() > 2.5:
					grid[cy][cx] = "P"
			cx = clampi(cx + rng.randi_range(-1, 1), 1, TW - 2)
			cy = clampi(cy + rng.randi_range(-1, 1), 1, TH - 2)
	_clear_radius(SPAWN_CELL, 2.5)
	_clear_radius(exit_cell, 2.5)
	var river_y := TH / 2 + rng.randi_range(-2, 2)
	for x in range(1, TW - 1):
		var _rc := Vector2i(x, river_y)
		if _rc == exit_cell or _rc == SPAWN_CELL:
			continue
		if Vector2(x - SPAWN_CELL.x, river_y - SPAWN_CELL.y).length() < 2.5:
			continue
		if Vector2(x - exit_cell.x, river_y - exit_cell.y).length() < 2.5:
			continue
		if grid[river_y][x] == "E":
			continue
		grid[river_y][x] = "w"
	var bridge_x := 2 + rng.randi() % (TW - 4)
	grid[river_y][bridge_x] = "."
	grid[river_y][mini(bridge_x + 1, TW - 2)] = "."
	var taken: Array = [Vector2i(bridge_x, river_y), Vector2i(mini(bridge_x + 1, TW - 2), river_y)]
	for k in int(d.get("pillars", 0)):
		var p := _free_cell(taken, 2.5)
		taken.append(p)
		grid[p.y][p.x] = "P"
	for k in int(d.get("spikes", 0)):
		var sp := _free_cell(taken, 2.5)
		taken.append(sp)
		grid[sp.y][sp.x] = "s"
	grid[exit_cell.y][exit_cell.x] = "E"
	if exit_cell.x == TW - 2:
		grid[exit_cell.y][exit_cell.x - 1] = "."
	elif exit_cell.y == 1:
		grid[exit_cell.y + 1][exit_cell.x] = "."
	else:
		grid[exit_cell.y][exit_cell.x - 1] = "."
	if not _bfs_reachable(SPAWN_CELL).has(exit_cell):
		_carve_line(SPAWN_CELL, exit_cell)
		grid[exit_cell.y][exit_cell.x] = "E"
	items.clear()
	extras.clear()
	enemies.clear()
	var ncrys: int = int(d.get("crys", 0)) + (1 if modifier == "RICH" else 0)
	for k in ncrys:
		var cp := _free_cell(taken, 1.5)
		taken.append(cp)
		if not _bfs_reachable(SPAWN_CELL).has(cp):
			_carve_line(SPAWN_CELL, cp)
		items.append({"cell": cp, "taken": false})
	var nen: int = int(d.get("en", 0)) + (1 if (modifier == "SWARM" and int(d.get("en", 0)) > 0) else 0)
	for k in nen:
		var ep := _free_cell(taken, 3.0)
		taken.append(ep)
		if not _bfs_reachable(SPAWN_CELL).has(ep):
			_carve_line(SPAWN_CELL, ep)
		var roll := rng.randf()
		var etype := "chase"
		if roll < 0.32:
			etype = "dash"
		elif roll < 0.57:
			etype = "tuhkanaama" # soot-black lurker, fast and tough
		var fast := (0.8 if modifier == "SWIFT" else 0.0) + (0.5 if modifier == "RICH" else 0.0)
		enemies.append(_new_enemy(ep, etype, k < int(d.get("elites", 0)), false, fast))
	var bp := _free_cell(taken, 4.0)
	taken.append(bp)
	if not _bfs_reachable(SPAWN_CELL).has(bp):
		_carve_line(SPAWN_CELL, bp)
	enemies.append(_new_enemy(bp, "boss", false, true, 0.0))
	var ip := _free_cell(taken, 2.5)
	taken.append(ip)
	if not _bfs_reachable(SPAWN_CELL).has(ip):
		_carve_line(SPAWN_CELL, ip)
	enemies.append(_new_enemy(ip, "irwin", false, false, 0.0))
	# the run always offers a chain: rooms B-D guarantee one tuhkanaama
	if ri >= 1:
		var has_t := false
		for x in enemies:
			if x["type"] == "tuhkanaama":
				has_t = true
		if not has_t:
			for x in enemies:
				if not x["boss"]:
					x["type"] = "tuhkanaama"
					x["hp"] = 4 if x["elite"] else 3
					x["maxhp"] = x["hp"]
					x["sp"] = float(x["sp"]) + 0.8
					break
	if bool(d.get("heart", false)) and modifier != "FAMINE" and rng.randf() < 0.5:
		var hp2 := _free_cell(taken, 1.5)
		taken.append(hp2)
		if not _bfs_reachable(SPAWN_CELL).has(hp2):
			_carve_line(SPAWN_CELL, hp2)
		extras.append({"cell": hp2, "kind": "heart", "taken": false})
	if bool(d.get("sharp", false)) and rng.randf() < 0.65:
		var shp := _free_cell(taken, 1.5)
		taken.append(shp)
		if not _bfs_reachable(SPAWN_CELL).has(shp):
			_carve_line(SPAWN_CELL, shp)
		extras.append({"cell": shp, "kind": "sharp", "taken": false})
	if (ri == 1 or ri == 2) and rng.randf() < 0.5:
		var btp := _free_cell(taken, 1.5)
		taken.append(btp)
		if not _bfs_reachable(SPAWN_CELL).has(btp):
			_carve_line(SPAWN_CELL, btp)
		extras.append({"cell": btp, "kind": "boots", "taken": false})
	# sun-melons: the tuhkanaama's weakness. Grab them first.
	var nmelon := 0
	if ri >= 1 and rng.randf() < 0.7:
		nmelon = 1 + (1 if modifier == "RICH" else 0)
	for k in nmelon:
		var mp := _free_cell(taken, 1.5)
		taken.append(mp)
		if not _bfs_reachable(SPAWN_CELL).has(mp):
			_carve_line(SPAWN_CELL, mp)
		extras.append({"cell": mp, "kind": "melon", "taken": false})

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
		if grid[y][x] != ".":
			continue
		if Vector2(x - SPAWN_CELL.x, y - SPAWN_CELL.y).length() < min_spawn:
			continue
		if Vector2(x - exit_cell.x, y - exit_cell.y).length() < 2.2:
			continue
		var ok := true
		for p in taken:
			if Vector2(p - Vector2i(x, y)).length() < 1.6:
				ok = false
				break
		if ok:
			return Vector2i(x, y)
	for yy in range(1, TH - 1):
		for xx in range(1, TW - 1):
			if grid[yy][xx] != ".":
				continue
			if Vector2(xx - SPAWN_CELL.x, yy - SPAWN_CELL.y).length() < min_spawn:
				continue
			if Vector2(xx - exit_cell.x, yy - exit_cell.y).length() < 2.2:
				continue
			var ok2 := true
			for p in taken:
				if Vector2(p - Vector2i(xx, yy)).length() < 1.6:
					ok2 = false
					break
			if ok2:
				return Vector2i(xx, yy)
	for yy in range(1, TH - 1):
		for xx in range(1, TW - 1):
			if grid[yy][xx] == ".":
				return Vector2i(xx, yy)
	return Vector2i(3, 3)

func room_clear() -> bool:
	for it in items:
		if not it["taken"]:
			return false
	for e in enemies:
		if not e["dead"] and not e.get("enslaved", false):
			return false
	return true

func cell_at_world(pos: Vector3) -> String:
	var mx := int(floor(pos.x / CELL))
	var my := int(floor(pos.z / CELL))
	if mx < 0 or my < 0 or mx >= TW or my >= TH:
		return "#"
	return grid[my][mx]

# ---------------- per-frame ----------------

func _ball_rect() -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	return Rect2(vp.x - 216.0, vp.y - 472.0, 200.0, 200.0)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		has_touch = true
		if is_instance_valid(touch_layer) and state == "play":
			touch_layer.visible = true
	if event is InputEventScreenDrag:
		has_touch = true
		if is_instance_valid(touch_layer) and state == "play":
			touch_layer.visible = true
	if event is InputEventScreenTouch:
		var vp := get_viewport().get_visible_rect().size
		if event.pressed:
			if cs_active:
				_cs_end()
				return
			var pos0: Vector2 = event.position
			var on_btn0 := (pos0.x > vp.x * 0.62 and pos0.y > vp.y * 0.62) or (pos0.x > vp.x - 80.0 and pos0.y < 240.0)
			if is_instance_valid(jump_node) and jump_node.visible:
				return
			if state == "title" or state == "dead" or state == "win":
				if state == "title" and is_instance_valid(ski_btn) and ski_btn.is_visible_in_tree() and ski_btn.get_global_rect().has_point(pos0):
					return
				start_run(rng.randi() if state != "title" else int(Time.get_unix_time_from_system()) % 100000)
				return
			elif state == "play" and paused_game:
				if on_btn0:
					return # let the II button handle it
				paused_game = false
				_refresh_overlays()
				return
			var pos: Vector2 = event.position
			# Right-side HUD buttons keep their own touches; everything else
			# on the right half is camera stick.
			var on_buttons := false
			for b in look_block:
				if is_instance_valid(b) and (b as Control).get_global_rect().grow(8.0).has_point(pos):
					on_buttons = true
					break
			# right stick: floating origin anywhere on the right half,
			# deflection drives camera rate (dualsense-style)
			if state == "play" and not paused_game and ball_id == -1 and not on_buttons and pos.x > vp.x * 0.5 and pos.y > vp.y * 0.25:
				ball_id = event.index
				ball_origin = pos
				look_vec = Vector2.ZERO
				if is_instance_valid(ball_base):
					ball_base.set_anchors_preset(Control.PRESET_TOP_LEFT)
					ball_base.offset_left = pos.x - 100.0
					ball_base.offset_top = pos.y - 100.0
					ball_base.offset_right = pos.x + 100.0
					ball_base.offset_bottom = pos.y + 100.0
				return
			if state == "play" and not paused_game and pos.x < vp.x * 0.5 and pos.y > vp.y * 0.3 and joy_id == -1:
				joy_id = event.index
				joy_origin = pos
				if is_instance_valid(joy_base):
					joy_base.position = joy_origin - joy_base.size * 0.5
				joy_vec = Vector2.ZERO
				touch_move = Vector2.ZERO
		else:
			if event.index == ball_id:
				ball_id = -1
				look_vec = Vector2.ZERO
				look_sm = Vector2.ZERO
				if is_instance_valid(ball_base) and is_instance_valid(ball_knob):
					ball_knob.position = (ball_base.size - ball_knob.size) * 0.5
				return
			if event.index == joy_id:
				joy_id = -1
				joy_vec = Vector2.ZERO
				touch_move = Vector2.ZERO
				if is_instance_valid(joy_base):
					joy_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
					joy_base.offset_left = 24
					joy_base.offset_top = -284
					joy_base.offset_right = 284
					joy_base.offset_bottom = -24
			if event.index == look_id:
				look_id = -1
		return
	if event is InputEventScreenDrag:
		if event.index == ball_id:
			if state == "play" and not paused_game:
				var boff: Vector2 = (event.position - ball_origin) / 90.0
				if boff.length() > 1.0:
					boff = boff.normalized()
				look_vec = boff
			if is_instance_valid(ball_base) and is_instance_valid(ball_knob):
				var boff2: Vector2 = (event.position - ball_origin) / 90.0
				if boff2.length() > 1.0:
					boff2 = boff2.normalized()
				ball_knob.position = (ball_base.size - ball_knob.size) * 0.5 + boff2 * 52.0
			return
		if event.index == joy_id:
			var d: Vector2 = (event.position - joy_origin) / 85.0
			if d.length() > 1.0:
				d = d.normalized()
			joy_vec = d
			touch_move = d
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if cs_active:
			_cs_end()
			return
		if is_instance_valid(jump_node) and jump_node.visible:
			return
		if state == "title" or state == "dead" or state == "win":
			if state == "title" and is_instance_valid(ski_btn) and ski_btn.is_visible_in_tree() and ski_btn.get_global_rect().has_point(event.position):
				return
			start_run(rng.randi() if state != "title" else int(Time.get_unix_time_from_system()) % 100000)
			return
		elif state == "play" and paused_game:
			paused_game = false
			_refresh_overlays()
			return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if _ball_rect().has_point(event.position):
			if state == "play" and not paused_game:
				yaw -= event.relative.x * 0.006
				cam_pitch = clampf(cam_pitch + event.relative.y * 0.004, CAM_PITCH_MIN, CAM_PITCH_MAX)
			return
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		if state == "play" and not paused_game:
			yaw -= event.relative.x * 0.006
			cam_pitch = clampf(cam_pitch + event.relative.y * 0.004, CAM_PITCH_MIN, CAM_PITCH_MAX)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k == KEY_J and (state == "title" or state == "play" or state == "dead" or state == "win"):
			if is_instance_valid(jump_node):
				jump_node.visible = not jump_node.visible
			return
		if k == KEY_ENTER or k == KEY_KP_ENTER:
			if cs_active:
				_cs_end()
				return
			if is_instance_valid(jump_node) and jump_node.visible:
				return
			if state == "title" or state == "dead" or state == "win":
				start_run(rng.randi() if state != "title" else int(Time.get_unix_time_from_system()) % 100000)
			elif state == "play" and paused_game:
				paused_game = false
				_refresh_overlays()
		elif k == KEY_R and state == "play":
			if is_instance_valid(jump_node) and jump_node.visible:
				return
			if r_arm_t <= 0.0:
				r_arm_t = 2.0
				announce("Press R again to abandon run")
			else:
				r_arm_t = 0.0
				start_run(int(Time.get_unix_time_from_system()) % 100000)
		elif k == KEY_P and state == "play":
			paused_game = not paused_game
			_refresh_overlays()
		elif k == KEY_C and state == "play":
			codex_panel.visible = not codex_panel.visible
		elif k == KEY_M:
			AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
			announce("Muted" if AudioServer.is_bus_mute(0) else "Sound on")
		elif k == KEY_G and state == "play" and not paused_game:
			throw_shitbomb()
		elif k == KEY_SPACE and cs_active:
			_cs_end()
		elif state == "play" and not paused_game and k >= KEY_1 and k <= KEY_8:
			inv_use(k - KEY_1)

func _process(delta: float) -> void:
	tick += 1
	if dmg_flash > 0.0:
		dmg_flash = maxf(0.0, dmg_flash - delta * 2.0)
	if is_instance_valid(dmg_rect):
		dmg_rect.color = Color(1, 0.1, 0.1, 0.35 * clampf(dmg_flash, 0.0, 1.0))
	if kill_flash > 0.0:
		kill_flash = maxf(0.0, kill_flash - delta * 3.0)
	if is_instance_valid(kill_rect):
		kill_rect.color = Color(1, 0.95, 0.8, 0.4 * clampf(kill_flash, 0.0, 1.0))
	if is_instance_valid(hero_sprite):
		hero_sprite.modulate = Color(1, 1, 1).lerp(Color(1.4, 1.1, 0.55), clampf(float(combo) / 12.0, 0.0, 1.0))
	if combo != last_combo:
		if combo > last_combo:
			combo_pop = 1.0
		last_combo = combo
	if combo_pop > 0.0:
		combo_pop = maxf(0.0, combo_pop - delta * 4.0)
	if is_instance_valid(hud_combo):
		var cs := 1.0 + 0.45 * combo_pop
		hud_combo.scale = Vector2(cs, cs)
	_ring_update(delta)
	# cave lightning: white sky-split, rumble follows
	bolt_t -= delta
	if bolt_t <= 0.0:
		bolt_t = randf_range(9.0, 20.0)
		if cave_env != null:
			cave_env.ambient_light_energy = 2.6
		kill_flash = maxf(kill_flash, 0.7)
		play_sfx(SFX_THUNDER)
	if cave_env != null and cave_env.ambient_light_energy > 0.85:
		cave_env.ambient_light_energy = lerpf(cave_env.ambient_light_energy, 0.85, 1.0 - exp(-5.0 * delta))
	if tick % 60 == 0:
		var s := get_viewport().get_visible_rect().size
		cam.fov = 88.0 if s.y > s.x else 70.0
	if cap_t > 0.0:
		cap_t -= delta
		if cap_t <= 0.0:			hud_cap.text = ""
	if death_laugh_t >= 0.0:
		death_laugh_t -= delta
		if death_laugh_t < 0.0 and state == "dead" and death_laugh_player != null:
			death_laugh_player.play()
	if cs_active:
		cs_t -= delta
		if cs_t <= 0.0:
			_cs_next()
	if tick % 1800 == 0:
		say("idle")
	if autoplay:
		_autoplay(delta)

func _physics_process(delta: float) -> void:
	if state != "play" or paused_game or cs_active:
		return
	if is_instance_valid(jump_node) and jump_node.visible:
		return
	# --- turn ---
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		turn += 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		turn -= 1.0
	if autoplay:
		turn = 0.0
		var foe := _bot_nearest_foe()
		if not foe.is_empty():
			var fp: Vector3 = (foe["node"] as Node3D).position
			yaw = atan2(-(fp.x - player_node.position.x), -(fp.z - player_node.position.z))
	yaw += turn * TURN_SPEED * delta
	# right stick: smoothed expo rate, deadzone center, fast edges
	look_sm = look_sm.lerp(look_vec, 1.0 - exp(-14.0 * delta))
	var lx := look_sm.x
	var ly := look_sm.y
	if absf(lx) < LOOK_DEAD:
		lx = 0.0
	else:
		lx = signf(lx) * pow((absf(lx) - LOOK_DEAD) / (1.0 - LOOK_DEAD), LOOK_EXPO)
	if absf(ly) < LOOK_DEAD:
		ly = 0.0
	else:
		ly = signf(ly) * pow((absf(ly) - LOOK_DEAD) / (1.0 - LOOK_DEAD), LOOK_EXPO)
	yaw -= lx * LOOK_YAW * delta
	cam_pitch = clampf(cam_pitch + ly * LOOK_PITCH * delta, CAM_PITCH_MIN, CAM_PITCH_MAX)
	if Input.is_physical_key_pressed(KEY_Q):
		cam_pitch = min(CAM_PITCH_MAX, cam_pitch + 1.2 * delta)
	if Input.is_physical_key_pressed(KEY_E):
		cam_pitch = max(CAM_PITCH_MIN, cam_pitch - 1.2 * delta)
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
	fwd += -touch_move.y
	strafe += touch_move.x
	if autoplay:
		fwd = 1.0
		strafe = 0.0
	var mag := Vector2(fwd, strafe).length()
	if mag > 1.0:
		fwd /= mag
		strafe /= mag
	var sp := WALK_SPEED * (1.0 + speed_bonus * 0.12)
	var on_water := cell_at_world(player_node.position) == "w"
	if on_water:
		sp *= 0.55
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
	hero_moving = moving
	if moving:
		walk_phase += 9.0 * delta
	# --- camera rig follows ---
	cam_rig.position = cam_rig.position.lerp(player_node.position + Vector3(0, 1.7, 0), 0.35)
	if FOLLOW_CAM:
		cam_yaw = lerp_angle(cam_yaw, yaw, 1.0 - exp(-3.0 * delta))
	else:
		cam_yaw = yaw
	cam_rig.rotation.y = cam_yaw
	spring.rotation.x = cam_pitch
	if shake > 0.003:
		shake = lerpf(shake, 0.0, 1.0 - exp(-6.0 * delta))
		cam.position = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * shake * 0.35
	elif is_instance_valid(cam) and cam.position != Vector3.ZERO:
		cam.position = Vector3.ZERO
	rain.position = Vector3(player_node.position.x, 6.0, player_node.position.z)
	if is_instance_valid(dust):
		dust.position = player_node.position + Vector3(0, 2.0, 0)
	if is_instance_valid(shit_trail):
		shit_trail.position = player_node.position + Vector3(0, 0.12, 0)
		shit_trail.emitting = hero_moving and state == "play" and not paused_game
	if is_instance_valid(lantern):
		lantern.position = player_node.position + Vector3(0, 2.2, 0)
		lantern.light_energy = 1.15 + sin(tick * 0.11) * 0.08 + sin(tick * 0.043) * 0.06
	if is_instance_valid(exit_light):
		exit_light.light_energy = 1.4 + sin(tick * 0.05) * 0.4
	# throbbing trap teeth + breathing exit glow
	if spike_glow_mat != null:
		spike_glow_mat.emission_energy_multiplier = 1.3 + sin(tick * 0.09) * 0.7
	if exit_glow_mat != null:
		exit_glow_mat.emission_energy_multiplier = 1.1 + sin(tick * 0.07) * 0.5
	if is_instance_valid(exit_halo):
		var ehs := 4.0 + sin(tick * 0.07) * 0.5
		exit_halo.pixel_size = ehs / 32.0
	for t in torches:
		if is_instance_valid(t):
			t.light_energy = 0.9 + sin(tick * 0.09 + t.position.x * 1.7 + t.position.z) * 0.12
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
	if voice_cd > 0.0:
		voice_cd -= delta
	if exit_nag_t > 0.0:
		exit_nag_t -= delta
	if r_arm_t > 0.0:
		r_arm_t -= delta
	# --- knife ---
	var slashing := Input.is_physical_key_pressed(KEY_SPACE) or touch_slash or autoplay
	if slashing and attack_cd <= 0.0:
		attack_t = 0.28
		attack_cd = 0.38
		swing_id += 1
		probe_swings += 1
		play_sfx(SFX_SLASH if swing_id % 2 == 0 else SFX_SLASH2)
	if attack_t > 0.0:
		attack_t -= delta
		hero_sprite.texture = hero_tex_slash
		_knife_hits()
	else:
		if moving:
			hero_sprite.texture = hero_tex1 if int(walk_phase * 2.0) % 2 == 0 else hero_tex2
		else:
			hero_sprite.texture = hero_tex1
		hero_sprite.position.y = 0.75 + (sin(walk_phase * 2.0) * 0.03 if on_water else 0.0)
	if is_instance_valid(slash_arc):
		slash_arc.visible = attack_t > 0.0
		if slash_arc.visible:
			var face := Vector3(-sin(yaw), 0, -cos(yaw))
			slash_arc.position = player_node.position + face * 1.6 + Vector3(0, 1.0, 0)
			var sa := slash_arc.modulate
			sa.a = clampf(attack_t / 0.28, 0.0, 1.0)
			slash_arc.modulate = sa
	# --- enemies, pickups, exit, spikes ---
	_enemy_update(delta)
	_pickup_update()
	for it in items:
		if not it["taken"] and is_instance_valid(it["node"] as Node3D):
			(it["node"] as Node3D).position.y = 0.9 + sin(tick * 0.06 + (it["pos"] as Vector3).x * 2.0) * 0.08
	for ex in extras:
		if not ex["taken"] and is_instance_valid(ex["node"] as Node3D):
			(ex["node"] as Node3D).position.y = 0.9 + sin(tick * 0.06 + (ex["pos"] as Vector3).x * 2.0) * 0.08
	_spike_update()
	_exit_update()
	_shitbomb_update(delta)
	_seed_update(delta)
	_chained_guns(delta)
	_leash_update()
	_chain_rattle_update()
	_lore_sightings()
	_refresh_hud()

# ---------------- chained spitfires: watermelon seeds at quarter knife ----
func _seed_update(delta: float) -> void:
	for i in range(seeds.size() - 1, -1, -1):
		var s: Dictionary = seeds[i]
		if not is_instance_valid(s.get("node") as Node3D):
			seeds.remove_at(i)
			continue
		var n: Node3D = s["node"]
		var v: Vector3 = s["vel"]
		v.y -= 4.0 * delta
		n.position += v * delta
		s["vel"] = v
		s["t"] = float(s["t"]) + delta
		var done := n.position.y <= 0.05 or float(s["t"]) > 2.5
		if not done:
			for e in enemies:
				if e["dead"] or e.get("enslaved", false):
					continue
				if n.position.distance_to((e["node"] as Node3D).position + Vector3(0, 0.8, 0)) < 0.9:
					e["hp"] = float(e["hp"]) - float(knife_dmg) * 0.25
					e["cool"] = 0.35
					e["flash"] = 0.12
					play_sfx(SFX_HIT, (e["node"] as Node3D).position)
					foe_yell((e["node"] as Node3D).position)
					if e["type"] == "tuhkanaama" and float(e["hp"]) <= 0.0:
						_enslave(e)
						continue
					if String(e["type"]) == "irwin" and float(e["hp"]) <= 0.0:
						_enslave_irwin(e)
						continue
					if float(e["hp"]) <= 0.0:
						_kill_enemy(e)
					done = true
					break
		if done:
			n.queue_free()
			seeds.remove_at(i)

func _chained_guns(delta: float) -> void:
	if state != "play":
		return
	for e in enemies:
		if not e.get("enslaved", false) or e["dead"]:
			continue
		if not is_instance_valid(e.get("node") as Node3D):
			continue
		e["seed_cd"] = float(e.get("seed_cd", 0.5)) - delta
		if float(e["seed_cd"]) > 0.0:
			continue
		var from: Vector3 = (e["node"] as Node3D).position + Vector3(0, 1.0, 0)
		var best: Dictionary = {}
		var bd := SEED_RANGE
		for f in enemies:
			if f["dead"] or f.get("enslaved", false):
				continue
			var d: float = from.distance_to((f["node"] as Node3D).position)
			if d < bd:
				bd = d
				best = f
		e["seed_cd"] = SEED_CD
		if best.is_empty():
			continue
		var target: Vector3 = (best["node"] as Node3D).position + Vector3(0, 0.8, 0)
		var dir := (target - from).normalized()
		var n := MeshInstance3D.new()
		var bm := BoxMesh.new()
		if String(e["type"]) == "irwin":
			bm.size = Vector3(0.16, 0.16, 0.16)
			var shitm := StandardMaterial3D.new()
			shitm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			shitm.albedo_color = Color(0.35, 0.22, 0.1)
			bm.material = shitm
		else:
			bm.size = Vector3(0.1, 0.1, 0.22)
			bm.material = seed_mat
		n.mesh = bm
		n.position = from
		(room_node if room_node else self).add_child(n)
		seeds.append({"node": n, "vel": dir * SEED_SPEED + Vector3(0, 1.0, 0), "t": 0.0})
		play_sfx(SFX_PLOP, from) # plop!
# ---------------- shit bomb: arcing turd, radial splash, pooling splats ----
func _shit_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.35, 0.22, 0.1)
	return m

func throw_shitbomb() -> void:
	if state != "play" or paused_game or cs_active:
		return
	if shit_ammo <= 0:
		announce("Shit bomb reloading...")
		return
	shit_ammo -= 1
	var n := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	sm.material = _shit_mat()
	n.mesh = sm
	var pp := player_node.position
	n.position = pp + Vector3(0, 1.2, 0)
	(room_node if room_node else self).add_child(n)
	var fw := Vector2(-sin(yaw), -cos(yaw))
	shitbombs.append({"node": n, "vel": Vector3(fw.x * 14.0, 5.5, fw.y * 14.0), "t": 0.0})
	play_sfx(SFX_SLASH)
	_refresh_hud()

func _explode_shitbomb(p: Vector3) -> void:
	# splash: brown burst with gravity + drag reads as fluid spray
	_poof(p + Vector3(0, 0.4, 0), Color(0.4, 0.26, 0.12))
	_poof(p + Vector3(0, 0.2, 0), Color(0.25, 0.15, 0.07))
	play_sfx(SFX_HIT2, p)
	spawn_ring(p, Color(0.45, 0.3, 0.12))
	add_shake(0.5)
	var hit_any := false
	for e in enemies:
		if e["dead"] or e.get("enslaved", false):
			continue
		var ep: Vector3 = (e["node"] as Node3D).position
		if Vector2(ep.x - p.x, ep.z - p.z).length() > SHITBOMB_RADIUS:
			continue
		hit_any = true
		e["hp"] = int(e["hp"]) - SHITBOMB_DMG
		e["cool"] = 0.35
		e["flash"] = 0.12
		if e["type"] == "tuhkanaama" and int(e["hp"]) <= 0:
			_enslave(e) # the soot-face cannot die. It kneels.
			continue
		if String(e["type"]) == "irwin" and int(e["hp"]) <= 0:
			_enslave_irwin(e)
			continue
		if int(e["hp"]) <= 0:
			_kill_enemy(e)
	if hit_any:
		foe_yell(p)
	# pooling splat: spreads fast, then dries out and frees itself
	var splat := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.3
	cm.height = 0.05
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.35, 0.22, 0.1, 0.9)
	cm.material = mat
	splat.mesh = cm
	splat.position = Vector3(p.x, 0.06, p.z)
	(room_node if room_node else self).add_child(splat)
	shitsplats.append({"node": splat, "mat": mat, "t": 0.0})

func _shitbomb_update(delta: float) -> void:
	for i in range(shitbombs.size() - 1, -1, -1):
		var b: Dictionary = shitbombs[i]
		if not is_instance_valid(b.get("node") as Node3D):
			shitbombs.remove_at(i)
			continue
		var n: Node3D = b["node"]
		var v: Vector3 = b["vel"]
		v.y -= SHITBOMB_GRAV * delta
		n.position += v * delta
		b["vel"] = v
		b["t"] = float(b["t"]) + delta
		var boom := n.position.y <= 0.12 or float(b["t"]) > 3.0
		if not boom:
			for e in enemies:
				if e["dead"] or e.get("enslaved", false):
					continue
				if n.position.distance_to((e["node"] as Node3D).position + Vector3(0, 0.8, 0)) < 1.2:
					boom = true
					break
		if boom:
			_explode_shitbomb(n.position)
			n.queue_free()
			shitbombs.remove_at(i)
	if shit_ammo < SHITBOMB_MAX:
		shit_regen_t += delta
		if shit_regen_t >= SHITBOMB_REGEN:
			shit_regen_t = 0.0
			shit_ammo += 1
			_refresh_hud()
	for i in range(shitsplats.size() - 1, -1, -1):
		var s: Dictionary = shitsplats[i]
		if not is_instance_valid(s.get("node") as Node3D):
			shitsplats.remove_at(i)
			continue
		var t := float(s["t"]) + delta
		s["t"] = t
		var n2: Node3D = s["node"]
		var r := minf(1.4, 0.3 + t * 1.6) # fast spread, capped pool
		n2.scale = Vector3(r / 0.3, 1.0, r / 0.3)
		if t > 4.0:
			(s["mat"] as StandardMaterial3D).albedo_color.a = maxf(0.0, 0.9 - (t - 4.0) * 0.45)
		if t >= 6.0:
			n2.queue_free()
			shitsplats.remove_at(i)

func _hp_text(e: Dictionary) -> String:
	# seed chips leave fractional hp: show ints clean, fractions short
	var h := float(e.get("hp", 0))
	if absf(h - roundf(h)) < 0.001:
		return str(int(roundf(h)))
	return str(snappedf(h, 0.01))

func _chain_rattle_update() -> void:	# the chain sings only while the hero hauls a kneeling pet along
	if chain_player == null:
		return
	var want := state == "play" and not paused_game and hero_moving and _chained_count() > 0
	if want and not chain_player.playing:
		chain_player.play()
	elif not want and chain_player.playing:
		chain_player.stop()

func _knife_hits() -> void:
	probe_calls += 1
	var pp := player_node.position
	for e in enemies:
		if e["dead"] or e.get("enslaved", false) or e["hit_swing"] == swing_id:
			continue
		var ep: Vector3 = (e["node"] as Node3D).position
		var d := Vector2(ep.x - pp.x, ep.z - pp.z)
		if d.length() > KNIFE_RANGE:
			continue
		var ang: float = abs(wrapf(d.angle_to(Vector2(-sin(yaw), -cos(yaw))), -PI, PI))
		if ang < probe_min_arc:
			probe_min_arc = ang
		if ang > KNIFE_ARC:
			continue
		e["hit_swing"] = swing_id
		probe_hits += 1
		e["hp"] = int(e["hp"]) - knife_dmg
		e["cool"] = 0.35
		e["flash"] = 0.12
		combo += 1
		combo_t = 3.0
		play_sfx(SFX_HIT, ep)
		foe_yell(ep)
		if e["type"] == "tuhkanaama" and int(e["hp"]) <= 0:
			_enslave(e) # the soot-face cannot die. It kneels.
			continue
		if combo == 5:
			say("combo", ep)
		if String(e["type"]) == "irwin" and int(e["hp"]) <= 0:
			_enslave_irwin(e)
			continue
		if int(e["hp"]) <= 0:
			_kill_enemy(e)

func _enslave(e: Dictionary) -> void:
	e["enslaved"] = true
	e["hp"] = 1
	e["seed_cd"] = 0.5
	score += 200
	play_sfx(SFX_DOOR, (e["node"] as Node3D).position)
	play_sfx(SFX_CHAINED, (e["node"] as Node3D).position)
	_add_collar(e["node"] as Node3D)
	_add_leash(e)
	announce("CHAINED! The tuhkanaama kneels. Haul it to the final exit.")
	say("chain", (e["node"] as Node3D).position)

func _enslave_irwin(e: Dictionary) -> void:
	e["enslaved"] = true
	e["hp"] = 3
	e["seed_cd"] = 0.5
	score += 200
	play_sfx(SFX_DOOR, (e["node"] as Node3D).position)
	play_sfx(SFX_CHAINED, (e["node"] as Node3D).position)
	_add_collar(e["node"] as Node3D)
	_add_leash(e)
	announce("WUHU WAKAWAKAWAKA!! Irwin joins the haul in his wheelchair!")
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.albedo_color = Color(0.12, 0.12, 0.14)
	var seat := _box(Vector3(0.5, 0.1, 0.5), wm)
	seat.position = Vector3(0, 0.25, 0)
	(e["node"] as Node3D).add_child(seat)
	var wl := _box(Vector3(0.08, 0.4, 0.4), wm)
	wl.position = Vector3(-0.3, 0.2, 0)
	(e["node"] as Node3D).add_child(wl)
	var wr := _box(Vector3(0.08, 0.4, 0.4), wm)
	wr.position = Vector3(0.3, 0.2, 0)
	(e["node"] as Node3D).add_child(wr)

func _add_leash(e: Dictionary) -> void:
	# steel link from the hero femboy to his kneeling pet, restretched every frame
	if leash_mat == null:
		return
	var link := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.07, 1.0)
	bm.material = leash_mat
	link.mesh = bm
	(room_node if room_node else self).add_child(link)
	e["leash"] = link
	if not is_instance_valid(e.get("halo") as Node3D):
		e["halo"] = _add_halo(e["node"] as Node3D, Color(1.0, 0.8, 0.25, 0.55), 2.4, 0.9)

func _leash_update() -> void:
	if player_node == null:
		return
	var pp := player_node.position + Vector3(0, 1.0, 0)
	for e in enemies:
		if not e.get("enslaved", false) or e["dead"]:
			continue
		if not is_instance_valid(e.get("node") as Node3D):
			continue
		if not is_instance_valid(e.get("leash") as Node3D):
			_add_leash(e)
			if not is_instance_valid(e.get("leash") as Node3D):
				continue
		var link: Node3D = e["leash"]
		var fp: Vector3 = (e["node"] as Node3D).position + Vector3(0, 1.0, 0)
		var d := pp - fp
		var dist := d.length()
		if dist < 0.05:
			link.visible = false
			continue
		link.visible = true
		link.position = (pp + fp) * 0.5
		link.scale = Vector3(1, 1, dist)
		link.look_at(pp, Vector3.UP)

func _add_collar(n: Node3D) -> void:
	var collar := _box(Vector3(0.5, 0.12, 0.5), _tex_mat("collar", COLLAR_TEX, _collar_pal(), 0.6))
	collar.position = Vector3(0, 1.32, 0)
	n.add_child(collar)

func _chained_count() -> int:
	var n := 0
	for e in enemies:
		if e.get("enslaved", false) and not e["dead"]:
			n += 1
	return n

func _chained_near(pos: Vector3, r: float) -> bool:
	for e in enemies:
		if e.get("enslaved", false) and not e["dead"]:
			if ((e["node"] as Node3D).position.distance_to(pos)) < r:
				return true
	return false

func spawn_ring(p: Vector3, col: Color) -> void:
	for r in rings:
		if float(r["t"]) >= 1.0 and is_instance_valid(r["node"] as Node3D):
			r["t"] = 0.0
			var n: Node3D = r["node"]
			n.position = Vector3(p.x, 0.25, p.z)
			n.visible = true
			(r["mat"] as StandardMaterial3D).albedo_color = Color(col.r, col.g, col.b, 0.9)
			return

func add_shake(amount: float) -> void:
	shake = minf(1.2, shake + amount)

func _ring_update(delta: float) -> void:
	for r in rings:
		if float(r["t"]) >= 1.0:
			continue
		r["t"] = float(r["t"]) + delta * 2.2
		var t := float(r["t"])
		if t >= 1.0:
			(r["node"] as Node3D).visible = false
			continue
		var n: Node3D = r["node"]
		var s := 0.5 + t * 6.5
		n.scale = Vector3(s, s, s)
		var c: Color = (r["mat"] as StandardMaterial3D).albedo_color
		c.a = 0.9 * (1.0 - t)
		(r["mat"] as StandardMaterial3D).albedo_color = c

func _hitstop() -> void:
	# demo-scene impact freeze: 70ms of near-stillness on every kill, free juice
	hitstop_n += 1
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.07, true, false, true).timeout
	hitstop_n -= 1
	if hitstop_n <= 0:
		hitstop_n = 0
		Engine.time_scale = 1.0

func _kill_enemy(e: Dictionary) -> void:
	e["dead"] = true
	kills += 1
	kill_flash = 1.0
	_hitstop()
	var gain := 50
	if e["elite"]:
		gain = 150
	if e["type"] == "tuhkanaama" and not e["elite"]:
		gain = 75
	if e["boss"]:
		gain = 500
	score += gain + combo * 5
	play_sfx(SFX_HIT2, (e["node"] as Node3D).position)
	spawn_ring((e["node"] as Node3D).position, Color(1.0, 0.84, 0.0) if e["boss"] else Color(1.0, 0.5, 0.2))
	add_shake(1.0 if e["boss"] else 0.3)
	(e["node"] as Node3D).visible = false
	_poof((e["node"] as Node3D).position + Vector3(0, 0.8, 0), Color(1.0, 0.84, 0.0) if e["boss"] else Color(1.0, 0.35, 0.3))
	if e["boss"]:
		announce("WARDEN DOWN! Reach the glowing exit.")
		play_sfx(SFX_WARDEN, (e["node"] as Node3D).position)
		say("boss_die", (e["node"] as Node3D).position)
	else:
		say("kill", (e["node"] as Node3D).position)

func _enemy_update(delta: float) -> void:
	var pp := player_node.position
	for e in enemies:
		if e["dead"]:
			continue
		var n: CharacterBody3D = e["node"]
		if float(e.get("flash", 0.0)) > 0.0:
			e["flash"] = maxf(0.0, float(e.get("flash", 0.0)) - delta)
		if e.get("enslaved", false):
			_chain_follow(e, n, delta)
			continue
		var d := Vector2(pp.x - n.position.x, pp.z - n.position.z)
		var dist := d.length()
		var dir: Vector2 = d / maxf(dist, 0.001)
		var sp: float = e["sp"]
		if e["cool"] > 0.0:
			e["cool"] = float(e["cool"]) - delta
		if e["type"] == "boss":
			_boss_move(e, n, dir, dist, delta)
		elif e["type"] == "tuhkanaama":
			_tuhkanaama_move(e, n, dir, dist, sp)
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
				if e["t"] <= 0.0:
					e["mode"] = "lunge"
					e["t"] = 0.45
					e["vx"] = dir.x * sp * 3.2
					e["vz"] = dir.y * sp * 3.2
			else:
				n.velocity.x = float(e["vx"])
				n.velocity.z = float(e["vz"])
				if e["t"] <= 0.0:
					e["mode"] = "stalk"
					e["t"] = 2.0 + rng.randf() * 2.0
		else:
			n.velocity.x = dir.x * sp
			n.velocity.z = dir.y * sp
		if cell_at_world(n.position) == "w":
			n.velocity.x *= 0.55
			n.velocity.z *= 0.55
		var _spr: Sprite3D = e.get("sprite")
		if _spr != null:
			if float(e.get("flash", 0.0)) > 0.0:
				_spr.modulate = Color(4, 4, 4)
			elif String(e.get("mode", "stalk")) == "tele":
				_spr.modulate = Color(3, 3, 3)
			else:
				_spr.modulate = e.get("base_mod", Color(1, 1, 1))
		if not n.is_on_floor():
			n.velocity.y -= 22.0 * delta
		else:
			n.velocity.y = -0.5
		n.move_and_slide()
		if dist < 1.1 and iframes <= 0.0 and not e.get("enslaved", false):
			hurt("daemon")

func _boss_move(e: Dictionary, n: CharacterBody3D, dir: Vector2, dist: float, delta: float) -> void:
	e["yell_t"] = float(e.get("yell_t", 3.0)) - delta
	if float(e["yell_t"]) <= 0.0:
		e["yell_t"] = 5.0 + rng.randf() * 2.0
		var yi := int(e.get("yell_i", 0)) % PALEFACE_LINES.size()
		e["yell_i"] = int(e.get("yell_i", 0)) + 1
		say("boss_taunt", n.position)
		announce(PALEFACE_LINES[yi])
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
		if e["t"] <= 0.0:
			e["mode"] = "charge"
			e["t"] = 0.8
			e["vx"] = dir.x * 9.0
			e["vz"] = dir.y * 9.0
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
			say("boss_taunt", n.position)

func _nearest_melon(from: Vector3) -> Dictionary:
	var best := {}
	var bd := 10.0
	for ex in extras:
		if ex["taken"] or ex["kind"] != "melon":
			continue
		var d: float = from.distance_to(ex["pos"])
		if d < bd:
			bd = d
			best = ex
	return best

func _tuhkanaama_move(e: Dictionary, n: CharacterBody3D, dir: Vector2, dist: float, sp: float) -> void:
	# The soot-face smells sun-melon within 10m and will cross the dark for it.
	var meal := _nearest_melon(n.position)
	if meal.is_empty():
		n.velocity.x = dir.x * sp
		n.velocity.z = dir.y * sp
		return
	var mp: Vector3 = meal["pos"]
	var md := Vector2(mp.x - n.position.x, mp.z - n.position.z)
	if md.length() < 1.2:
		meal["taken"] = true
		(meal["node"] as Node3D).visible = false
		e["hp"] = e["maxhp"]
		e["sp"] = float(e["sp"]) + 0.4
		n.scale *= 1.08
		announce("Tuhkanaama devours a sun-melon. Its teeth glow brighter.")
		play_sfx(SFX_COIN, (meal["node"] as Node3D).position)
		n.velocity.x = 0.0
		n.velocity.z = 0.0
	else:
		var mdir: Vector2 = md / maxf(md.length(), 0.001)
		n.velocity.x = mdir.x * sp * 1.15
		n.velocity.z = mdir.y * sp * 1.15

func _chain_follow(e: Dictionary, n: CharacterBody3D, delta: float) -> void:
	# Broken, collared, loyal. Heels 1.6m behind the hero. Hurts no one.
	var pp := player_node.position
	var tx := pp.x + sin(yaw) * 1.6
	var tz := pp.z + cos(yaw) * 1.6
	var d := Vector2(tx - n.position.x, tz - n.position.z)
	if d.length() > 0.5:
		var step: Vector2 = d / maxf(d.length(), 0.001) * minf(6.0, d.length() * 4.0)
		n.velocity.x = step.x
		n.velocity.z = step.y
	else:
		n.velocity.x = 0.0
		n.velocity.z = 0.0
	var npos := n.position + Vector3(n.velocity.x * delta, 0.0, n.velocity.z * delta)
	var nc := cell_at_world(npos)
	if nc == "#" or nc == "P":
		n.velocity.x = 0.0
		n.velocity.z = 0.0
	if cell_at_world(n.position) == "w":
		n.velocity.x *= 0.55
		n.velocity.z *= 0.55
	if not n.is_on_floor():
		n.velocity.y -= 22.0 * delta
	else:
		n.velocity.y = -0.5
	n.move_and_slide()
	n.rotation.y = atan2(-(pp.x - n.position.x), -(pp.z - n.position.z))

func _spawn_minion(at: Vector3) -> void:
	var cell := Vector2i(clampi(int(at.x / CELL), 1, TW - 2), clampi(int(at.z / CELL), 1, TH - 2))
	var e := _new_enemy(cell, "chase", false, false, 0.0)
	e["cell"] = cell
	enemies.append(e)
	_build_enemy_node(e)
	announce("The warden calls a minion!")

func inv_add(kind: String) -> bool:
	if kind != "melon": # teeth-food is bulky: every melon takes its own slot
		for s in inventory:
			if s["kind"] == kind and int(s["count"]) < 99:
				s["count"] = int(s["count"]) + 1
				return true
	if inventory.size() >= INV_SLOTS:
		return false
	inventory.append({"kind": kind, "count": 1})
	return true

func inv_use(slot: int) -> void:
	if state != "play" or paused_game:
		return
	if slot < 0 or slot >= inventory.size():
		return
	var s: Dictionary = inventory[slot]
	if s["kind"] == "melon" or s["kind"] == "heart":
		if hp >= max_hp:
			announce("HP full. Save it for the dark.")
			return
		hp = mini(max_hp, hp + 1)
		s["count"] = int(s["count"]) - 1
		play_sfx(SFX_COIN)
		announce("Ate sun-melon." if s["kind"] == "melon" else "Heart consumed. +1 HP.")
		if int(s["count"]) <= 0:
			inventory.remove_at(slot)
	elif s["kind"] == "crys":
		announce("Milk-teeth are for the exit, not for eating.")
	_refresh_hud()

func _inv_text() -> String:
	var parts: Array = []
	for i in inventory.size():
		parts.append("%d:%s x%d" % [i + 1, String(inventory[i]["kind"]), int(inventory[i]["count"])])
	while parts.size() < INV_SLOTS:
		parts.append("%d:--" % (parts.size() + 1))
	return "PACK [" + "  ".join(parts) + "]  (1-8 use)  SHIT %d/%d (G)" % [shit_ammo, SHITBOMB_MAX]

func _melon_slot() -> int:
	for i in inventory.size():
		if inventory[i]["kind"] == "melon":
			return i + 1
	return 0

func _pickup_update() -> void:
	var pp := player_node.position
	for it in items:
		if it["taken"]:
			continue
		if pp.distance_to(it["pos"]) < 1.4:
			if not inv_add("crys"):
				announce("Pack full! Milk-tooth left on the floor.")
				continue
			it["taken"] = true
			(it["node"] as Node3D).visible = false
			score += 100
			play_sfx(SFX_COIN, (it["node"] as Node3D).position)
			announce("Crystal packed (%d left out there)." % _crystals_left())
			say("pk_crys", (it["node"] as Node3D).position)
	for ex in extras:
		if ex["taken"]:
			continue
		if pp.distance_to(ex["pos"]) < 1.4:
			if ex["kind"] == "heart":
				if hp < max_hp:
					hp = mini(max_hp, hp + 1)
					ex["taken"] = true
					(ex["node"] as Node3D).visible = false
					announce("Heart: +1 HP.")
				elif inv_add("heart"):
					ex["taken"] = true
					(ex["node"] as Node3D).visible = false
					announce("Heart packed for later.")
				else:
					announce("Pack full! Left the heart.")
					continue
				say("pk_heart")
			elif ex["kind"] == "melon":
				if inv_add("melon"):
					ex["taken"] = true
					(ex["node"] as Node3D).visible = false
					score += 10
					announce("Sun-melon packed. Tuhkanaama-free calories (press %d to eat)." % _melon_slot())
					say("pk_melon")
				else:
					announce("Pack full! The melon sits there, smelling.")
					continue
			elif ex["kind"] == "sharp":
				knife_dmg = 2
				ex["taken"] = true
				(ex["node"] as Node3D).visible = false
				announce("Sharp knife: double damage.")
				say("pk_sharp", (ex["node"] as Node3D).position)
			else:
				speed_bonus += 1.0
				ex["taken"] = true
				(ex["node"] as Node3D).visible = false
				announce("Boots: faster.")
				say("pk_boots", (ex["node"] as Node3D).position)
			play_sfx(SFX_COIN, (ex["node"] as Node3D).position)

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
		if ri < ROOM_DEFS.size() - 1:
			play_sfx(SFX_DOOR, exit_node.position)
			score += 250
			if exit_voiced != ri:
				exit_voiced = ri
				say("exit_open")
			_load_room(ri + 1)
		elif _chained_near(exit_node.position, 8.0):
			play_sfx(SFX_DOOR, exit_node.position)
			_win()
		elif open:
			if exit_nag_t <= 0.0:
				exit_nag_t = 3.0
				announce("The final door wants your chained tuhkanaama at heel. Break one: knife it to 1 HP.")
				say("exit_need")

func hurt(src: String) -> void:
	if iframes > 0.0 or state != "play":
		return
	if autoplay:
		hp = maxi(hp, 2) # smoke hook: the bot must survive to prove the win path
	hp -= 1
	iframes = 1.2
	dmg_flash = 1.0
	cam_pitch = clampf(cam_pitch + 0.02, CAM_PITCH_MIN, CAM_PITCH_MAX)
	combo = 0
	play_sfx(SFX_HURT)
	damage_yell()
	add_shake(0.6)
	if hp <= 0:
		say("die")
		state = "dead"
		play_sfx(SFX_DEATH)
		if death_scream_player != null:
			death_scream_player.play()
		death_laugh_t = 1.1 # the Joker starts laughing right after the scream
		if score > best_score: best_score = score; _hs_save()
		_refresh_overlays()
		return
	if src == "spike":
		announce("Spikes! Watch the floor.")
	if hp == 1:
		say("lowhp")
	elif src == "spike":
		say("spike")
	else:
		say("hurt")

func _win() -> void:
	say("win")
	state = "win"
	play_sfx(SFX_WIN)
	if score > best_score: best_score = score; _hs_save()
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

func _pixel_mat(rows: Array, pal: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _pixel_tex(rows, pal)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m

func _spike_pal() -> Dictionary:
	return {
		"W": Color(0.95, 0.97, 1.0), "S": Color(0.62, 0.66, 0.72),
		"s": Color(0.32, 0.35, 0.42), "R": Color(1.0, 0.12, 0.08),
		"r": Color(0.45, 0.05, 0.05), "D": Color(0.07, 0.07, 0.10),
		"d": Color(0.16, 0.16, 0.20), "Y": Color(0.9, 0.75, 0.1),
	}

func _exit_pal() -> Dictionary:
	return {
		"D": Color(0.04, 0.08, 0.06), "g": Color(0.05, 0.35, 0.16),
		"G": Color(0.10, 0.75, 0.30), "L": Color(0.45, 1.0, 0.60),
		"W": Color(1, 1, 1),
	}

func _collar_pal() -> Dictionary:
	return {
		"G": Color(1.0, 0.78, 0.18), "g": Color(0.55, 0.38, 0.08),
		"W": Color(1, 1, 1), "R": Color(0.9, 0.08, 0.12),
	}

func _tex_mat(key: String, rows: Array, pal: Dictionary, emit_e: float) -> StandardMaterial3D:
	var tex := _cached_tex(key, rows, pal)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.9
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = emit_e
	return m

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var skysh := Shader.new()
	skysh.code = SKY_SHADER
	var skym := ShaderMaterial.new()
	skym.shader = skysh
	sky.sky_material = skym
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.04, 0.08)
	env.fog_density = 0.03
	cave_env = env
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.78)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	if OS.has_feature("web"):
		sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-48, -35, 0)
	add_child(sun)
	# rain streaks falling around the player
	rain = CPUParticles3D.new()
	rain.amount = 80 if OS.has_feature("web") else 160
	rain.lifetime = 1.1
	rain.preprocess = 1.1
	rain.direction = Vector3(0.1, -1, 0)
	rain.spread = 6.0
	rain.initial_velocity_min = 14.0
	rain.initial_velocity_max = 22.0
	rain.gravity = Vector3(0, -4, 0)
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(14, 1, 14)
	var streak_tex: Texture2D = _cached_tex("rain", RAIN_PX, {
		"W": Color(0.85, 0.93, 1.0, 1.0),
		"C": Color(0.6, 0.7, 0.85, 1.0),
	})
	var streak := QuadMesh.new()
	streak.size = Vector2(0.12, 0.6)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	smat.albedo_texture = streak_tex
	smat.albedo_color = Color(1, 1, 1, 0.9)
	streak.material = smat
	rain.mesh = streak
	rain.visibility_aabb = AABB(Vector3(-16, -8, -16), Vector3(32, 16, 32))
	add_child(rain)
	# cave dust motes drifting around the hero, basically free
	dust = CPUParticles3D.new()
	dust.amount = 60
	dust.lifetime = 5.0
	dust.preprocess = 5.0
	dust.local_coords = false
	dust.direction = Vector3(0.3, 0.1, 0.0)
	dust.spread = 90.0
	dust.initial_velocity_min = 0.2
	dust.initial_velocity_max = 0.7
	dust.gravity = Vector3.ZERO
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.2
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(9, 2.5, 9)
	var mote := SphereMesh.new()
	mote.radius = 0.035
	mote.height = 0.07
	var mmat := StandardMaterial3D.new()
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmat.albedo_color = Color(1.0, 0.88, 0.65, 0.5)
	mmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote.material = mmat
	dust.mesh = mote
	dust.visibility_aabb = AABB(Vector3(-10, -3, -10), Vector3(20, 8, 20))
	add_child(dust)
	# hero shit trail: brown lumps drop at the hero's heels and linger behind
	shit_trail = CPUParticles3D.new()
	shit_trail.amount = 48
	shit_trail.lifetime = 1.6
	shit_trail.local_coords = false
	shit_trail.direction = Vector3(0, 1, 0)
	shit_trail.spread = 25.0
	shit_trail.initial_velocity_min = 0.2
	shit_trail.initial_velocity_max = 0.8
	shit_trail.gravity = Vector3(0, -3, 0)
	shit_trail.scale_amount_min = 0.7
	shit_trail.scale_amount_max = 1.3
	shit_trail.color = Color(0.35, 0.22, 0.1)
	var turd := BoxMesh.new()
	turd.size = Vector3(0.16, 0.13, 0.16)
	var tmat := StandardMaterial3D.new()
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.albedo_color = Color(0.35, 0.22, 0.1)
	turd.material = tmat
	shit_trail.mesh = turd
	shit_trail.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 4, 16))
	add_child(shit_trail)
	lantern = OmniLight3D.new()
	lantern.name = "lantern"
	lantern.light_color = Color(1.0, 0.85, 0.6)
	lantern.light_energy = 1.2
	lantern.omni_range = 9.0
	lantern.shadow_enabled = false
	add_child(lantern)

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
	var pal := _hero_pal()
	if hero_tex1 == null:
		hero_tex1 = _pixel_tex(HERO_BACK_1, pal)
	if hero_tex2 == null:
		hero_tex2 = _pixel_tex(HERO_BACK_2, pal)
	if hero_tex_slash == null:
		hero_tex_slash = _pixel_tex(HERO_SLASH, pal)
	hero_sprite = _sprite3d(hero_tex1, 0.08, 0.75)
	player_node.add_child(hero_sprite)
	var psh := _add_shadow(player_node, 1.2)
	psh.position = Vector3(0, -0.05, 0)
	if slash_arc_tex == null:
		slash_arc_tex = _pixel_tex(ARC_SLASH, {"W": Color(1, 1, 1)})
	slash_arc = _sprite3d(slash_arc_tex, 0.09, 0.0)
	slash_arc.visible = false
	add_child(slash_arc)
	add_child(player_node)
	# chase camera rig: yaw + shoulder offset, spring arm pulls in on walls
	cam_rig = Node3D.new()
	add_child(cam_rig)
	spring = SpringArm3D.new()
	spring.position = Vector3(0.55, 0.5, 0)
	spring.spring_length = 5.4
	spring.margin = 0.3
	spring.collision_mask = 1
	cam_rig.add_child(spring)
	spring.add_excluded_object(player_node.get_rid())
	cam = Camera3D.new()
	cam.fov = 70.0
	var vs := get_viewport().get_visible_rect().size
	if vs.y > vs.x:
		cam.fov = 88.0
	spring.add_child(cam)

func _build_room_nodes() -> void:
	torches.clear()
	if room_node:
		room_node.queue_free()
	room_node = Node3D.new()
	room_node.name = "Room"
	add_child(room_node)
	var floor_mats: Array = [
		_pixel_mat(FLOOR_A, CAVE_PAL),
		_pixel_mat(FLOOR_B, CAVE_PAL),
		_pixel_mat(FLOOR_B, CAVE_PAL),
		_pixel_mat(FLOOR_A, CAVE_PAL),
	]
	var wall_m := _pixel_mat(WALL_TEX, CAVE_PAL)
	var pillar_m := _pixel_mat(PILLAR_TEX, CAVE_PAL)
	var spike_m := _tex_mat("spike", SPIKE_TEX, _spike_pal(), 1.6)
	spike_glow_mat = spike_m
	var rsh := Shader.new()
	rsh.code = RIVER_SHADER
	river_mat = ShaderMaterial.new()
	(river_mat as ShaderMaterial).shader = rsh
	river_cells.clear()
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
	# checker floor tiles (visual); no ceiling: open sky keeps the view and rain clear
	for my in TH:
		for mx in TW:
			var wx := mx * CELL
			var wz := my * CELL
			var fidx := ((mx + my) % 2) * 2 + ((mx * 7 + my * 13) % 2)
			var t := _box(Vector3(CELL * 0.98, 0.08, CELL * 0.98), floor_mats[fidx])
			t.position = Vector3(wx, -0.04, wz)
			room_node.add_child(t)
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
				# a trap that reads as a trap: hazard plate + four red-hot teeth
				var plate := _box(Vector3(CELL * 0.98, 0.1, CELL * 0.98), spike_m)
				plate.position = Vector3(wx, 0.05, wz)
				room_node.add_child(plate)
				for ox in [-CELL * 0.22, CELL * 0.22]:
					for oz in [-CELL * 0.22, CELL * 0.22]:
						var tooth := _box(Vector3(0.5, 1.1, 0.5), spike_m)
						tooth.position = Vector3(wx + ox, 0.65, wz + oz)
						room_node.add_child(tooth)
			elif ch == "w":
				river_cells.append(Vector2i(mx, my))
				var wplane := _box(Vector3(CELL * 0.98, 0.06, CELL * 0.98), river_mat)
				wplane.position = Vector3(wx, 0.03, wz)
				room_node.add_child(wplane)
			elif ch == "E":
				exit_node = Area3D.new()
				exit_node.position = Vector3(wx, 0.0, wz)
				var emat := _tex_mat("exit", EXIT_TEX, _exit_pal(), 1.2)
				exit_glow_mat = emat
				var pillar := _box(Vector3(1.0, WALL_H, 1.0), emat)
				pillar.position = Vector3(0, WALL_H / 2.0, 0)
				exit_node.add_child(pillar)
				exit_halo = _add_halo(exit_node, Color(0.3, 1.0, 0.45, 0.5), 4.0, 1.2)
				exit_light = OmniLight3D.new()
				exit_light.position = Vector3(0, 2.0, 0)
				exit_light.omni_range = 7.0
				exit_light.light_color = Color(0.15, 0.25, 0.4)
				exit_node.add_child(exit_light)
				# embers rising off the glowing exit
				var emb := CPUParticles3D.new()
				emb.amount = 24
				emb.lifetime = 1.6
				emb.preprocess = 1.6
				emb.local_coords = false
				emb.direction = Vector3(0, 1, 0)
				emb.spread = 18.0
				emb.initial_velocity_min = 1.0
				emb.initial_velocity_max = 2.5
				emb.gravity = Vector3(0, 1.0, 0)
				emb.scale_amount_min = 0.6
				emb.scale_amount_max = 1.2
				var spark := BoxMesh.new()
				spark.size = Vector3(0.09, 0.09, 0.09)
				var smat := StandardMaterial3D.new()
				smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				smat.albedo_color = Color(1.0, 0.55, 0.15)
				spark.material = smat
				emb.mesh = spark
				emb.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
				emb.position = Vector3(0, 0.3, 0)
				exit_node.add_child(emb)
				# light beam shooting skyward off the exit
				var beam := MeshInstance3D.new()
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.5
				cyl.bottom_radius = 0.7
				cyl.height = 9.0
				var bsh := Shader.new()
				bsh.code = BEAM_SHADER
				var bmat := ShaderMaterial.new()
				bmat.shader = bsh
				cyl.material = bmat
				beam.mesh = cyl
				beam.position = Vector3(0, 4.5, 0)
				beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				exit_node.add_child(beam)
				room_node.add_child(exit_node)
	var torch_spots: Array = []
	for base in [SPAWN_CELL, exit_cell]:
		var found := Vector2i(-1, -1)
		for r in 3:
			for yy in range(maxi(1, base.y - r), mini(TH - 1, base.y + r + 1)):
				for xx in range(maxi(1, base.x - r), mini(TW - 1, base.x + r + 1)):
					if grid[yy][xx] == ".":
						found = Vector2i(xx, yy)
						break
				if found.x >= 0:
					break
			if found.x >= 0:
				break
		if found.x >= 0:
			var dup := false
			for t in torch_spots:
				if t == found:
					dup = true
			if not dup:
				torch_spots.append(found)
	for tp in torch_spots.slice(0, 2):
		var torch := OmniLight3D.new()
		torch.light_color = Color(1.0, 0.6, 0.25)
		torch.omni_range = 6.0
		torch.light_energy = 0.9
		torch.shadow_enabled = false
		torch.position = Vector3(tp.x * CELL, 1.6, tp.y * CELL)
		torch.add_to_group("torch")
		room_node.add_child(torch)
		torches.append(torch)
		# living flame cone over every torch
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.03
		cone.bottom_radius = 0.22
		cone.height = 0.7
		var fsh := Shader.new()
		fsh.code = FLAME_SHADER
		var fmat := ShaderMaterial.new()
		fmat.shader = fsh
		cone.material = fmat
		flame.mesh = cone
		flame.position = Vector3(tp.x * CELL, 2.1, tp.y * CELL)
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		room_node.add_child(flame)
	# pickups + enemies
	for it in items:
		var p: Vector2i = it["cell"]
		var cpair: Array = _item_tex("crys")
		var cnode := _sprite3d(_cached_tex("item_crys", cpair[0], cpair[1]), 0.09, 0.9)
		cnode.position = Vector3(p.x * CELL, 0.9, p.y * CELL)
		room_node.add_child(cnode)
		_add_halo(cnode, _halo_color("crys"), 1.8, 0.0)
		it["pos"] = Vector3(p.x * CELL, 0.0, p.y * CELL)
		it["node"] = cnode
		it["taken"] = false
		var ish := _add_shadow(room_node, 0.7)
		ish.position = Vector3(p.x * CELL, 0.03, p.y * CELL)
	for ex in extras:
		var p: Vector2i = ex["cell"]
		var xpair: Array = _item_tex(String(ex["kind"]))
		var node := _sprite3d(_cached_tex("item_" + String(ex["kind"]), xpair[0], xpair[1]), 0.09, 0.9)
		node.position = Vector3(p.x * CELL, 0.9, p.y * CELL)
		room_node.add_child(node)
		_add_halo(node, _halo_color(String(ex["kind"])), 1.8, 0.0)
		ex["pos"] = Vector3(p.x * CELL, 0.0, p.y * CELL)
		ex["node"] = node
		ex["taken"] = false
		var xsh := _add_shadow(room_node, 0.7)
		xsh.position = Vector3(p.x * CELL, 0.03, p.y * CELL)
	for e in enemies:
		_build_enemy_node(e)

func _build_enemy_node(e: Dictionary) -> void:
	var p: Vector2i = e["cell"]
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
	var pair: Array = _enemy_tex(String(e["type"]), bool(e["boss"]))
	var ekey := "boss" if bool(e["boss"]) else "enemy_" + String(e["type"])
	# every daemon wears the Mother's chosen face (assets/diarra.jpg): the photo as a
	# billboard, sized to roughly the height the old pixel sprite used
	var sprite: Sprite3D
	if bool(e["boss"]) and BOSS_LOOK != null:
		var blook: Texture2D = BOSS_LOOK
		sprite = _sprite3d(blook, 1.4 / float(maxi(1, blook.get_height())), 0.7 * scale_f)
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	elif String(e["type"]) == "irwin" and IRWIN_LOOK != null:
		var ilook: Texture2D = IRWIN_LOOK
		sprite = _sprite3d(ilook, 1.4 / float(maxi(1, ilook.get_height())), 0.7 * scale_f)
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	elif ENEMY_LOOK != null:
		var look: Texture2D = ENEMY_LOOK
		sprite = _sprite3d(look, 1.4 / float(maxi(1, look.get_height())), 0.7 * scale_f)
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	else:
		sprite = _sprite3d(_cached_tex(ekey, pair[0], pair[1]), 0.09, 0.8 * scale_f)
	sprite.scale = Vector3.ONE * scale_f
	n.add_child(sprite)
	if e["boss"]:
		_add_halo(n, Color(1.0, 0.2, 0.15, 0.55), 3.4, 0.9 * scale_f)
	var base_mod := Color(1, 1, 1)
	if e["elite"]:
		base_mod = Color(1.5, 0.9, 0.5)
	sprite.modulate = base_mod
	var esh := _add_shadow(n, 1.0 * scale_f)
	esh.position = Vector3(0, -0.05, 0)
	if e.get("enslaved", false):
		_add_collar(n) # chains travel between rooms
		_add_leash(e)
		if not e.has("seed_cd"):
			e["seed_cd"] = 0.5
	n.position = Vector3(p.x * CELL, 0.1, p.y * CELL)
	(room_node if room_node else self).add_child(n)
	e["node"] = n
	e["mesh"] = sprite
	e["sprite"] = sprite
	e["base_mod"] = base_mod

func _place_player_spawn() -> void:
	player_node.position = Vector3(1.5 * CELL, 0.1, TH * CELL / 2.0 - CELL / 2.0)
	yaw = -PI / 2.0 # face +X down the cave
	cam_yaw = yaw
	cam_rig.position = player_node.position + Vector3(0, 1.7, 0)
	cam_rig.rotation.y = yaw

# ---------------- HUD / audio ----------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# plasma demo backdrop, title screen only
	var plsh := Shader.new()
	plsh.code = PLASMA_SHADER
	plasma = ColorRect.new()
	plasma.name = "PlasmaTitle"
	plasma.set_anchors_preset(Control.PRESET_FULL_RECT)
	plasma.color = Color(1, 1, 1, 1)
	plasma.material = ShaderMaterial.new()
	(plasma.material as ShaderMaterial).shader = plsh
	plasma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plasma.visible = false
	layer.add_child(plasma)
	# shockwave ring pool: flat gold hoops that blast outward on kills
	for i in 4:
		var ring := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 0.92
		tor.outer_radius = 1.0
		var rmat := StandardMaterial3D.new()
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.albedo_color = Color(1.0, 0.85, 0.4, 0.0)
		tor.material = rmat
		ring.mesh = tor
		ring.rotation.x = PI / 2.0
		ring.visible = false
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		rings.append({"node": ring, "mat": rmat, "t": 1.0})
	hud_top = Label.new()
	hud_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_top.offset_left = 12
	hud_top.offset_top = 8
	hud_top.offset_right = -12
	hud_top.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud_top)
	hud_room = Label.new()
	hud_room.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_room.offset_left = 12
	hud_room.offset_top = 34
	hud_room.offset_right = -12
	hud_room.add_theme_font_size_override("font_size", 16)
	hud_room.add_theme_color_override("font_color", Color(1, 1, 0))
	layer.add_child(hud_room)
	hud_combo = Label.new()
	hud_combo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_combo.offset_left = 12
	hud_combo.offset_top = 58
	hud_combo.offset_right = -12
	hud_combo.add_theme_font_size_override("font_size", 16)
	hud_combo.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	hud_combo.pivot_offset = Vector2(200, 20)
	layer.add_child(hud_combo)
	hud_cap = Label.new()
	hud_cap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_cap.offset_left = 12
	hud_cap.offset_top = 84
	hud_cap.offset_right = -200
	hud_cap.offset_bottom = 130
	hud_cap.add_theme_font_size_override("font_size", 17)
	hud_cap.add_theme_color_override("font_color", Color(1, 1, 0.4))
	hud_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(hud_cap)
	hud_inv = Label.new()
	hud_inv.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud_inv.offset_left = 12
	hud_inv.offset_top = -170
	hud_inv.offset_right = -170
	hud_inv.offset_bottom = -12
	hud_inv.add_theme_font_size_override("font_size", 18)
	hud_inv.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	hud_inv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(hud_inv)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/femboy.png") as Texture2D
	portrait.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait.offset_left = 12
	portrait.offset_top = -330
	portrait.offset_right = 76
	portrait.offset_bottom = -258
	portrait.custom_minimum_size = Vector2(64, 72)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(portrait)
	minimap = preload("res://minimap.gd").new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -196
	minimap.offset_top = 44
	minimap.offset_right = -12
	minimap.offset_bottom = 156
	layer.add_child(minimap)
	minimap.game = self
	title_panel = _overlay(layer, "CATERPILLAR: KNIFE OF THE MOTHER 3D  [" + BUILD_TAG + "]", LORE_GOAL + "\n\n" + LORE_INTRO + "\n\nTap or ENTER to spawn. ENTER/tap cave | SKI JUMP button or J. Left thumb move, right stick to look, KNIFE hold to slash, G shit bomb, M mute.")
	var title_tex := TextureRect.new()
	title_tex.texture = load("res://assets/caterpillar.png") as Texture2D
	title_tex.custom_minimum_size = Vector2(560, 180)
	title_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	title_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var title_vb := title_panel.get_child(0) as VBoxContainer
	title_vb.add_child(title_tex)
	title_vb.move_child(title_tex, 0)
	ski_btn = Button.new()
	ski_btn.text = "SKI JUMP"
	ski_btn.add_theme_font_size_override("font_size", 22)
	ski_btn.focus_mode = Control.FOCUS_NONE
	ski_btn.pressed.connect(_on_ski_button)
	title_vb.add_child(ski_btn)
	dead_panel = _overlay(layer, "YOU DIED", "The cave keeps the knife.\nTap or ENTER for a new cave.")
	# Joker laughs at your death: full-screen meme behind the panel
	dead_bg = TextureRect.new()
	dead_bg.texture = JOKER_BG
	dead_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dead_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	dead_bg.visible = false
	layer.add_child(dead_bg)
	layer.move_child(dead_bg, 0)
	death_scream_player = AudioStreamPlayer.new()
	death_scream_player.stream = SFX_SCREAM
	death_scream_player.volume_db = -4.0
	add_child(death_scream_player)
	death_laugh_player = AudioStreamPlayer.new()
	death_laugh_player.stream = SFX_LAUGH
	death_laugh_player.volume_db = -4.0
	add_child(death_laugh_player)
	win_panel = _overlay(layer, "ENSLAVED AND DELIVERED!", "A chained tuhkanaama kneels at the glowing exit. The cave releases its master.\n\n" + LORE_OUTRO + "\nTap or ENTER for a new cave.")
	codex_panel = _overlay(layer, "THE CAVE REMEMBERS", _codex_text(), "CLOSE")
	# cutscene stage: dim + card + faces + caption + skip, raised on every level change
	cs_dim = ColorRect.new()
	cs_dim.color = Color(0, 0, 0, 0.6)
	cs_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	cs_dim.visible = false
	layer.add_child(cs_dim)
	cs_panel = PanelContainer.new()
	cs_panel.set_anchors_preset(Control.PRESET_CENTER)
	cs_panel.offset_left = -330
	cs_panel.offset_top = -250
	cs_panel.offset_right = 330
	cs_panel.offset_bottom = 250
	cs_panel.custom_minimum_size = Vector2(660, 420)
	var cs_vb := VBoxContainer.new()
	cs_panel.add_child(cs_vb)
	cs_title = Label.new()
	cs_title.add_theme_font_size_override("font_size", 28)
	cs_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	cs_vb.add_child(cs_title)
	var cs_faces := HBoxContainer.new()
	cs_faces.alignment = BoxContainer.ALIGNMENT_CENTER
	cs_faces.add_theme_constant_override("separation", 24)
	cs_vb.add_child(cs_faces)
	var cs_mom := TextureRect.new()
	cs_mom.texture = load("res://assets/caterpillar.png") as Texture2D
	cs_mom.custom_minimum_size = Vector2(140, 110)
	cs_mom.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cs_mom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cs_faces.add_child(cs_mom)
	var cs_hero := TextureRect.new()
	cs_hero.texture = load("res://assets/femboy.png") as Texture2D
	cs_hero.custom_minimum_size = Vector2(110, 110)
	cs_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cs_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cs_faces.add_child(cs_hero)
	cs_cap = Label.new()
	cs_cap.add_theme_font_size_override("font_size", 20)
	cs_cap.add_theme_color_override("font_color", Color(1, 1, 0.85))
	cs_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cs_cap.custom_minimum_size = Vector2(600, 90)
	cs_vb.add_child(cs_cap)
	var cs_skip := Button.new()
	cs_skip.text = "SKIP >>"
	cs_skip.add_theme_font_size_override("font_size", 22)
	cs_skip.focus_mode = Control.FOCUS_NONE
	cs_skip.pressed.connect(_cs_end)
	cs_vb.add_child(cs_skip)
	cs_panel.visible = false
	layer.add_child(cs_panel)
	cs_player = AudioStreamPlayer.new()
	cs_player.volume_db = -4.0
	add_child(cs_player)
	pause_label = Label.new()
	pause_label.text = "PAUSED — TAP, ENTER or P to resume"
	pause_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_label.offset_left = -220
	pause_label.offset_top = -20
	pause_label.offset_right = 220
	pause_label.offset_bottom = 20
	pause_label.add_theme_font_size_override("font_size", 28)
	pause_label.visible = false
	layer.add_child(pause_label)
	var _dmg := ColorRect.new()
	_dmg.name = "DmgFlash"
	_dmg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dmg.color = Color(1, 0.1, 0.1, 0)
	_dmg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_dmg)
	dmg_rect = _dmg
	var _kill := ColorRect.new()
	_kill.name = "KillFlash"
	_kill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kill.color = Color(1, 0.95, 0.8, 0)
	_kill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_kill)
	kill_rect = _kill
	# demo-scene post: grain + vignette + scanlines over everything, one draw
	var psh := Shader.new()
	psh.code = POST_SHADER
	var post := ColorRect.new()
	post.name = "PostGrease"
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.color = Color(1, 1, 1, 1)
	post.material = ShaderMaterial.new()
	(post.material as ShaderMaterial).shader = psh
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(post)
	_build_touch()

func _cs_clip(idx: int, n: int) -> String:
	return "cs_%s_%02d.ogg" % [["a", "b", "c", "d"][idx], n]

func _play_cutscene(idx: int) -> void:
	# two bangers per level: mother, then hero. World waits, skip always works.
	cs_lines = [
		{"file": _cs_clip(idx, 1), "who": "MOTHER"},
		{"file": _cs_clip(idx, 2), "who": "HERO"},
	]
	cs_i = -1
	var d: Dictionary = ROOM_DEFS[idx]
	cs_title.text = "LEVEL %d — %s" % [idx + 1, String(d.get("name", "???"))]
	cs_dim.visible = true
	cs_panel.visible = true
	cs_active = true
	_cs_next()

func _cs_next() -> void:
	cs_i += 1
	if cs_i >= cs_lines.size():
		_cs_end()
		return
	var f: String = cs_lines[cs_i]["file"]
	var stream: AudioStream = cs_cache.get(f)
	if stream == null:
		stream = load("res://assets/voices/" + f) as AudioStream
		if stream == null:
			_cs_next()
			return
		cs_cache[f] = stream
	cs_cap.text = "%s: %s" % [String(cs_lines[cs_i]["who"]), String(VOICE_TEXT.LINES.get(f, "..."))]
	cs_player.stream = stream
	cs_player.play()
	cs_t = stream.get_length() + 1.0

func _cs_end() -> void:
	cs_active = false
	cs_lines = []
	cs_i = 0
	if cs_player != null and cs_player.playing:
		cs_player.stop()
	if is_instance_valid(cs_dim):
		cs_dim.visible = false
	if is_instance_valid(cs_panel):
		cs_panel.visible = false

func _overlay(layer: CanvasLayer, title: String, body: String, btn_text: String = "TAP TO START / CONTINUE") -> PanelContainer:
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.offset_left = -310
	pc.offset_top = -230
	pc.offset_right = 310
	pc.offset_bottom = 230
	pc.custom_minimum_size = Vector2(620, 380)
	var vb := VBoxContainer.new()
	pc.add_child(vb)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	var b := Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 16)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(560, 0)
	scroll.add_child(b)
	var btn := Button.new()
	btn.text = btn_text
	btn.add_theme_font_size_override("font_size", 22)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_on_overlay_button)
	vb.add_child(btn)
	pc.visible = false
	layer.add_child(pc)
	return pc

func _on_ski_button() -> void:
	if is_instance_valid(jump_node) and not jump_node.visible:
		jump_node.visible = true

func _on_overlay_button() -> void:
	if state == "title" or state == "dead" or state == "win":
		start_run(rng.randi() if state != "title" else int(Time.get_unix_time_from_system()) % 100000)
	elif state == "play" and paused_game:
		paused_game = false
		_refresh_overlays()
	else:
		if is_instance_valid(codex_panel):
			codex_panel.visible = false

func _build_touch() -> void:
	touch_layer = CanvasLayer.new()
	touch_layer.layer = 10
	add_child(touch_layer)
	touch_layer.visible = false
	var circle := func(c: Color, radius: int, bw: int) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = c
		sb.border_color = Color(0, 1, 0, 0.8)
		sb.set_border_width_all(bw)
		sb.set_corner_radius_all(radius)
		return sb
	joy_base = Panel.new()
	joy_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joy_base.offset_left = 24
	joy_base.offset_top = -284
	joy_base.offset_right = 284
	joy_base.offset_bottom = -24
	joy_base.add_theme_stylebox_override("panel", circle.call(Color(0, 1, 0, 0.15), 110, 3))
	joy_base.mouse_filter = Control.MOUSE_FILTER_STOP
	joy_base.visible = true
	touch_layer.add_child(joy_base)
	joy_knob = Panel.new()
	joy_knob.offset_left = 62
	joy_knob.offset_top = 62
	joy_knob.offset_right = 158
	joy_knob.offset_bottom = 158
	joy_knob.add_theme_stylebox_override("panel", circle.call(Color(0, 1, 0, 0.35), 48, 2))
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.add_child(joy_knob)
	var knife := Button.new()
	knife.text = "KNIFE"
	knife.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	knife.offset_left = -176
	knife.offset_top = -152
	knife.offset_right = -24
	knife.offset_bottom = -24
	knife.add_theme_font_size_override("font_size", 28)
	knife.focus_mode = Control.FOCUS_NONE
	knife.mouse_filter = Control.MOUSE_FILTER_STOP
	knife.button_down.connect(func() -> void: touch_slash = true)
	knife.button_up.connect(func() -> void: touch_slash = false)
	knife.mouse_exited.connect(func() -> void: touch_slash = false)
	touch_layer.add_child(knife)
	look_block.append(knife)
	var eat := Button.new()
	eat.text = "EAT"
	eat.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	eat.offset_left = -156
	eat.offset_top = -252
	eat.offset_right = -44
	eat.offset_bottom = -164
	eat.custom_minimum_size = Vector2(128, 88)
	eat.add_theme_font_size_override("font_size", 20)
	eat.focus_mode = Control.FOCUS_NONE
	eat.mouse_filter = Control.MOUSE_FILTER_STOP
	eat.pressed.connect(_on_eat_button)
	touch_layer.add_child(eat)
	look_block.append(eat)
	var shit := Button.new()
	shit.text = "SHIT"
	shit.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	shit.offset_left = -336
	shit.offset_top = -152
	shit.offset_right = -200
	shit.offset_bottom = -24
	shit.add_theme_font_size_override("font_size", 28)
	shit.focus_mode = Control.FOCUS_NONE
	shit.mouse_filter = Control.MOUSE_FILTER_STOP
	shit.pressed.connect(throw_shitbomb)
	touch_layer.add_child(shit)
	look_block.append(shit)
	ball_base = Panel.new()
	ball_base.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ball_base.offset_left = -216
	ball_base.offset_top = -472
	ball_base.offset_right = -16
	ball_base.offset_bottom = -272
	ball_base.add_theme_stylebox_override("panel", circle.call(Color(0, 1, 0, 0.15), 100, 3))
	ball_base.mouse_filter = Control.MOUSE_FILTER_STOP
	touch_layer.add_child(ball_base)
	ball_knob = Panel.new()
	ball_knob.offset_left = 52
	ball_knob.offset_top = 52
	ball_knob.offset_right = 148
	ball_knob.offset_bottom = 148
	ball_knob.add_theme_stylebox_override("panel", circle.call(Color(0, 1, 0, 0.35), 48, 2))
	ball_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball_base.add_child(ball_knob)
	var ball_label := Label.new()
	ball_label.text = "LOOK"
	ball_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	ball_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ball_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ball_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball_base.add_child(ball_label)
	var pausb := Button.new()
	pausb.text = "II"
	pausb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pausb.offset_left = -84
	pausb.offset_top = 170
	pausb.offset_right = -12
	pausb.offset_bottom = 242
	pausb.add_theme_font_size_override("font_size", 22)
	pausb.focus_mode = Control.FOCUS_NONE
	pausb.mouse_filter = Control.MOUSE_FILTER_STOP
	pausb.pressed.connect(_on_pause_button)
	touch_layer.add_child(pausb)
	look_block.append(pausb)
	var codex := Button.new()
	codex.text = "?"
	codex.set_anchors_preset(Control.PRESET_TOP_LEFT)
	codex.offset_left = 12
	codex.offset_top = 170
	codex.offset_right = 76
	codex.offset_bottom = 234
	codex.add_theme_font_size_override("font_size", 22)
	codex.focus_mode = Control.FOCUS_NONE
	codex.mouse_filter = Control.MOUSE_FILTER_STOP
	codex.pressed.connect(_on_codex_button)
	touch_layer.add_child(codex)
	var newb := Button.new()
	newb.text = "NEW"
	newb.set_anchors_preset(Control.PRESET_TOP_LEFT)
	newb.offset_left = 12
	newb.offset_top = 242
	newb.offset_right = 76
	newb.offset_bottom = 282
	newb.add_theme_font_size_override("font_size", 16)
	newb.focus_mode = Control.FOCUS_NONE
	newb.mouse_filter = Control.MOUSE_FILTER_STOP
	newb.pressed.connect(_on_new_button)
	touch_layer.add_child(newb)
	if DisplayServer.is_touchscreen_available():
		touch_layer.visible = true
		has_touch = true

func _on_eat_button() -> void:
	if state != "play" or paused_game:
		return
	for i in inventory.size():
		if inventory[i]["kind"] == "melon" or inventory[i]["kind"] == "heart":
			inv_use(i)
			return

func _on_pause_button() -> void:
	if state == "play":
		paused_game = not paused_game
		_refresh_overlays()

func _on_codex_button() -> void:
	if state == "play":
		codex_panel.visible = not codex_panel.visible

func _on_new_button() -> void:
	if state != "play":
		return
	if paused_game:
		start_run(int(Time.get_unix_time_from_system()) % 100000)
	else:
		announce("Pause first: II, then NEW.")

func _refresh_hud() -> void:
	var hearts := ""
	for i in max_hp:
		hearts += "H" if i < hp else "-"
	hud_top.text = "LV %02d  HP %s %d/%d  SCORE %06d  CHAIN %d BEST %06d" % [ri + 1, hearts, hp, max_hp, score, _chained_count(), best_score]
	hud_combo.text = ("COMBO x%d" % combo) if combo > 1 else ""
	var _foe := _bot_nearest_foe()
	if not _foe.is_empty():
		var _fl := "FOE %s %s/%s" % [str(_foe.get("type", "?")), _hp_text(_foe), str(_foe.get("maxhp", "?"))]
		hud_combo.text = (hud_combo.text + "\n" + _fl) if hud_combo.text != "" else _fl
	hud_inv.text = _inv_text()
	if is_instance_valid(joy_knob):
		var off := joy_vec * 62.0
		joy_knob.position = (joy_base.size - joy_knob.size) * 0.5 + off

func _refresh_overlays() -> void:
	title_panel.visible = state == "title"
	if is_instance_valid(plasma):
		plasma.visible = state == "title"
	dead_panel.visible = state == "dead"
	if is_instance_valid(dead_bg):
		dead_bg.visible = state == "dead"
	win_panel.visible = state == "win"
	if state != "play":
		codex_panel.visible = false
	pause_label.visible = state == "play" and paused_game
	if is_instance_valid(touch_layer):
		touch_layer.visible = (state == "play") and (has_touch or DisplayServer.is_touchscreen_available())
	_refresh_hud()

func _codex_text() -> String:
	var t := "=== goal ===\n" + LORE_GOAL + "\n\n=== creation ===\n" + LORE_INTRO + "\n\n=== rooms ===\n"
	for i in LORE_ROOMS.size():
		t += LORE_ROOMS[i] + "\n\n"
	t += "=== daemons ===\n"
	for k in ["chase", "dash", "tuhkanaama", "boss"]:
		t += String(LORE_ENEMIES[k]) + "\n\n"
	t += "=== findings ===\n"
	for k in ["crys", "heart", "sharp", "boots", "melon"]:
		t += String(LORE_ITEMS[k]) + "\n\n"
	t += "=== exit ===\n" + LORE_EXIT + "\n"
	return t

func _lore_sightings() -> void:
	var pp := player_node.position
	for e in enemies:
		if e["dead"]:
			continue
		var ep: Vector3 = (e["node"] as Node3D).position
		if pp.distance_to(ep) > 7.0:
			continue
		var key := "seen_" + String(e["type"])
		if not seen.get(key, false):
			seen[key] = true
			announce(String(LORE_ENEMIES[e["type"]]))
			if e["type"] == "chase":
				say("foe_chase", ep)
			elif e["type"] == "dash":
				say("foe_dash", ep)
			elif e["type"] == "tuhkanaama":
				say("foe_tuhk", ep)
			elif e["type"] == "boss":
				say("boss_see", ep)
			return
	for ex in extras:
		if ex["taken"] or ex["kind"] != "melon":
			continue
		if pp.distance_to(ex["pos"]) < 4.0 and not seen.get("seen_melon", false):
			seen["seen_melon"] = true
			announce(LORE_ITEMS["melon"])
			return

func show_title() -> void:
	state = "title"
	music_stop()
	_refresh_overlays()
	hud_room.text = "The hero waits in the dark."
	hud_cap.text = ""

func announce(text: String) -> void:
	cap_hist.append(text)
	while cap_hist.size() > 2:
		cap_hist.remove_at(0)
	hud_cap.text = "\n".join(cap_hist)
	cap_t = 5.0

func _build_audio() -> void:
	for i in 8:
		var p := AudioStreamPlayer3D.new()
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		p.unit_size = 3.5
		p.max_distance = 60.0
		add_child(p)
		sfx_players.append(p)
	# the cave itself: a breath of reverb on everything
	var rev := AudioEffectReverb.new()
	rev.room_size = 0.85
	rev.wet = 0.22
	rev.predelay_msec = 25.0
	AudioServer.add_bus_effect(0, rev)
	# the Indian-song track loops for the whole run
	music_player = AudioStreamPlayer.new()
	var music: AudioStream = MUSIC_STREAM
	if music is AudioStreamMP3:
		(music as AudioStreamMP3).loop = true
	elif music is AudioStreamOggVorbis:
		(music as AudioStreamOggVorbis).loop = true
	music_player.stream = music
	music_player.volume_db = -10.0
	add_child(music_player)
	# the hero's pain cry: one dedicated voice, replayed on EVERY hit
	dmg_yell_player = AudioStreamPlayer.new()
	dmg_yell_player.stream = DMG_YELL
	dmg_yell_player.volume_db = -4.0
	add_child(dmg_yell_player)
	# the foe's cry when knifed: positional, every landed hit
	foe_yell_player = AudioStreamPlayer3D.new()
	foe_yell_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	foe_yell_player.unit_size = 3.5
	foe_yell_player.max_distance = 60.0
	foe_yell_player.stream = FOE_YELL
	foe_yell_player.volume_db = -4.0
	add_child(foe_yell_player)
	# chain rattle: looped while the hero drags a chained foe along
	chain_player = AudioStreamPlayer.new()
	var chain: AudioStream = SFX_CHAIN
	if chain is AudioStreamOggVorbis:
		(chain as AudioStreamOggVorbis).loop = true
	chain_player.stream = chain
	chain_player.volume_db = -12.0
	add_child(chain_player)
	leash_mat = StandardMaterial3D.new()
	leash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leash_mat.albedo_color = Color(0.55, 0.56, 0.6)
	leash_mat.metallic = 0.7
	leash_mat.roughness = 0.35
	seed_mat = StandardMaterial3D.new()
	seed_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	seed_mat.albedo_color = Color(0.08, 0.25, 0.08)

func music_play() -> void:
	if music_player != null and not music_player.playing:
		music_player.play()

func music_stop() -> void:
	if music_player != null:
		music_player.stop()

func damage_yell() -> void:
	if state != "play" or dmg_yell_player == null:
		return
	dmg_yell_player.play()

func foe_yell(pos: Vector3 = Vector3.INF) -> void:
	if state != "play" or foe_yell_player == null:
		return
	if pos == Vector3.INF:
		pos = player_node.position if is_instance_valid(player_node) else Vector3.ZERO
	foe_yell_player.position = pos
	foe_yell_player.play()

func play_sfx(stream: AudioStream, pos: Vector3 = Vector3.INF) -> void:
	var p: AudioStreamPlayer3D = sfx_players[sfx_i]
	sfx_i = (sfx_i + 1) % sfx_players.size()
	p.stream = stream
	p.volume_db = -6.0
	if pos == Vector3.INF:
		pos = player_node.position if is_instance_valid(player_node) else Vector3.ZERO
	p.position = pos
	p.play()

# ---------------- autoplay smoke hook ----------------

func _bot_nearest_foe() -> Dictionary:
	var best := {}
	var bd := 1e9
	for e in enemies:
		if e["dead"] or e.get("enslaved", false):
			continue
		var d: float = player_node.position.distance_to((e["node"] as Node3D).position)
		if d < bd:
			bd = d
			best = e
	return best

func _autoplay(delta: float) -> void:
	auto_t += 1
	if cs_active:
		_cs_end() # smoke hook watches gameplay, not cinema
		return
	if auto_t % 600 == 0:
		print("[autoplay] t=%d state=%s room=%d hp=%d chain=%d score=%d foes=%d swings=%d calls=%d minarc=%.2f hits=%d inv=%s yaw=%.2f" % [auto_t, state, ri, hp, _chained_count(), score, enemies.size(), probe_swings, probe_calls, probe_min_arc, probe_hits, _inv_text(), yaw])
		for e in enemies:
			var ep: Vector3 = (e["node"] as Node3D).position
			print("  foe type=%s hp=%s dead=%s ensl=%s d=%.1f" % [e["type"], e["hp"], e["dead"], e.get("enslaved", false), player_node.position.distance_to(ep)])
	if auto_t == 30:
		start_run(1234)
		return
	if state == "dead" or state == "win":
		start_run(1234 + auto_t) # smoke hook keeps exercising
		return
	if hp < max_hp: # smoke hook eats from the pack
		for i in inventory.size():
			if inventory[i]["kind"] == "melon" or inventory[i]["kind"] == "heart":
				inv_use(i)
				break
	if state != "play" or auto_t < 30:
		return
	# cheat-walk the critical path: fight every 4th cycle, melons even, else crystals, else exit
	if auto_t % 240 == 0:
		var target := Vector3(exit_cell.x * CELL, 0, exit_cell.y * CELL)
		var best := 1e9
		if (auto_t / 240) % 4 == 3:
			for e in enemies:
				if e["dead"] or e.get("enslaved", false):
					continue
				var d: float = player_node.position.distance_to((e["node"] as Node3D).position)
				if d < best:
					best = d
					target = (e["node"] as Node3D).position
		if best > 1e8 and (auto_t / 240) % 2 == 0:
			for ex in extras:
				if ex["taken"] or ex["kind"] != "melon":
					continue
				var d: float = player_node.position.distance_to(ex["pos"])
				if d < best:
					best = d
					target = ex["pos"]
		if best > 1e8:
			for it in items:
				if it["taken"]:
					continue
				var d: float = player_node.position.distance_to(it["pos"])
				if d < best:
					best = d
					target = it["pos"]
		if room_clear():
			target = Vector3(exit_cell.x * CELL, 0, exit_cell.y * CELL)
		player_node.position = target + Vector3(0.5, 0.1, 0.0)
		for e in enemies: # the chained march with the smoke-test too
			if e.get("enslaved", false) and not e["dead"]:
				(e["node"] as Node3D).position = player_node.position + Vector3(-0.5, 0.1, 0.5)
