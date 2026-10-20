class_name CatRig
extends Node2D

# A single set of isolated parts, continuously posed; no generated frame grid.
const ATLAS: Texture2D = preload("res://assets/cat_rig.png")
const REGIONS := {
	"body": Rect2(48, 174, 548, 286),
	"head": Rect2(656, 96, 324, 368),
	"tail": Rect2(1016, 190, 480, 306),
	"front": Rect2(214, 558, 208, 402),
	"hind": Rect2(660, 558, 236, 402),
	"closed": Rect2(1088, 576, 332, 370),
}
const MOUTH := Vector2(52.8, -47.7)
const BOWL_MOUTH := Vector2(105, -44)
const EXTENTS := Rect2(-220, -250, 390, 265)

var pose: Dictionary = {}
var facing_right := true

func _init() -> void:
	pose = _pose("sit", 0.0, 0.0)

func update_pose(action: String, clock: float, progress: float, delta: float) -> void:
	var wanted := _pose(action, clock, progress)
	var weight := 1.0 - exp(-delta * 14.0)
	for key in wanted:
		pose[key] = lerp(pose[key], wanted[key], weight)
	queue_redraw()

func _pose(action: String, clock: float, progress: float) -> Dictionary:
	var p := {
		"body": Vector2(-8, -98), "body_angle": 0.0, "body_scale": Vector2.ONE,
		"head": Vector2(48, -108), "head_angle": 0.0, "head_scale": Vector2.ONE,
		"tail": Vector2(-80, -112), "tail_angle": sin(clock * 1.6) * 0.07,
		"front_near": Vector2(49, -87), "front_far": Vector2(40, -89),
		"hind_near": Vector2(-62, -87), "hind_far": Vector2(-70, -89),
		"front_near_angle": 0.0, "front_far_angle": 0.0,
		"hind_near_angle": 0.0, "hind_far_angle": 0.0,
		"leg_scale": Vector2.ONE, "front_near_stretch": Vector2.ONE,
		"lift": 0.0, "closed": 0.0, "tongue": 0.0,
	}
	if action in ["walk", "run"]:
		var speed := 9.0 if action == "walk" else 15.0
		var stride := 0.40 if action == "walk" else 0.80
		var phase := clock * speed
		p.front_near_angle = sin(phase) * stride
		p.front_far_angle = sin(phase + PI) * stride
		p.hind_near_angle = sin(phase + PI * 0.6) * stride
		p.hind_far_angle = sin(phase + PI * 1.6) * stride
		p.lift = absf(sin(phase)) * (3.0 if action == "walk" else 10.0)
		p.head_angle = sin(phase) * 0.025
		p.tail_angle = sin(phase * 0.5) * 0.12
	elif action == "jump":
		p.lift = sin(clampf(progress, 0, 1) * PI) * 95.0
		p.front_near_angle = -sin(progress * PI) * 0.8
		p.front_far_angle = p.front_near_angle + 0.12
		p.hind_near_angle = sin(progress * PI) * 0.7
		p.hind_far_angle = p.hind_near_angle - 0.1
		p.tail_angle = -sin(progress * PI) * 0.25
	elif action in ["sit", "groom", "litter"]:
		p.body = Vector2(-26, -71)
		p.body_angle = -0.65
		p.body_scale = Vector2(0.75, 1.12)
		p.head = Vector2(17, -92)
		p.tail = Vector2(-60, -55)
		p.front_near = Vector2(35, -77)
		p.front_far = Vector2(26, -79)
		p.hind_near = Vector2(-50, -48)
		p.hind_far = Vector2(-60, -50)
		p.hind_near_angle = -1.07
		p.hind_far_angle = -1.0
		p.leg_scale = Vector2(1.0, 0.90)
		if action == "groom":
			p.front_near_angle = -1.55 + sin(clock * 7) * 0.06
			p.front_near_stretch = Vector2(1, 0.72)
			p.head_angle = 0.72 + sin(clock * 7) * 0.035
			p.tongue = maxf(0, sin(clock * 7))
		if action == "litter":
			p.body += Vector2(0, 13)
			p.head += Vector2(0, 13)
			p.tail_angle = -0.55
	elif action == "sleep":
		var breath := sin(clock * 1.8) * 0.012
		p.body = Vector2(-15, -42)
		p.body_scale = Vector2(1.02, 0.62 + breath)
		p.head = Vector2(43, -34)
		p.head_angle = 0.90
		p.head_scale = Vector2(0.82, 0.82)
		p.tail = Vector2(-78, -46)
		p.tail_angle = -0.22
		p.front_near = Vector2(34, -24)
		p.front_far = Vector2(20, -28)
		p.hind_near = Vector2(-53, -23)
		p.hind_far = Vector2(-66, -27)
		p.leg_scale = Vector2(0.90, 0.25)
		p.closed = 1.0
	elif action in ["eat", "drink"]:
		var nod := sin(clock * (8 if action == "eat" else 11)) * 0.035
		p.head_angle = 0.90 + nod
		# Anchor the muzzle on the existing station's rim, even during nodding.
		p.head = BOWL_MOUTH - MOUTH.rotated(p.head_angle)
		p.body = Vector2(-8, -86)
		p.body_angle = 0.14
		p.body_scale = Vector2(1.0, 0.90)
		p.tongue = maxf(0, sin(clock * 11)) if action == "drink" else 0.0
	return p

func _part(part: String, anchor: Vector2, rect: Rect2, angle: float = 0.0, stretch: Vector2 = Vector2.ONE, tint: Color = Color.WHITE) -> void:
	var mirror := 1.0 if facing_right else -1.0
	var origin := Vector2(anchor.x * mirror, anchor.y - float(pose.lift))
	draw_set_transform(origin, angle * mirror, Vector2(stretch.x * mirror, stretch.y))
	draw_texture_rect_region(ATLAS, rect, REGIONS[part], tint, false, true)

func _leg(part: String, key: String, far: bool) -> void:
	var color := Color(0.79, 0.79, 0.79) if far else Color.WHITE
	var stretch: Vector2 = pose.leg_scale
	if key == "front_near":
		stretch *= Vector2(pose.front_near_stretch)
	_part(part, pose[key], Rect2(-19, -7, 46, 99), float(pose[key + "_angle"]), stretch, color)

func _draw() -> void:
	_part("tail", pose.tail, Rect2(-11, -62, 132, 84), float(pose.tail_angle), Vector2(-1, 1))
	_leg("hind", "hind_far", true)
	_leg("front", "front_far", true)
	_part("body", pose.body, Rect2(-88, -44, 176, 92), float(pose.body_angle), pose.body_scale)
	_leg("hind", "hind_near", false)
	_leg("front", "front_near", false)
	var head_part := "closed" if float(pose.closed) > 0.5 else "head"
	_part(head_part, pose.head, Rect2(-30, -115, 110, 122), float(pose.head_angle), pose.head_scale)
	if float(pose.tongue) > 0.25:
		var mirror := 1.0 if facing_right else -1.0
		var tip: Vector2 = pose.head + (MOUTH * Vector2(pose.head_scale)).rotated(float(pose.head_angle))
		draw_set_transform(Vector2(tip.x * mirror, tip.y - float(pose.lift)), float(pose.head_angle) * mirror, Vector2(mirror, 1))
		draw_line(Vector2(-2, 1), Vector2(0, 2 + 5 * float(pose.tongue)), Color("df9ba6"), 4.0, true)
	draw_set_transform(Vector2.ZERO)
