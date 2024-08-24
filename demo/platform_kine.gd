extends CharacterBody3D

var fwd = true
var target = Vector3(0,0,-6)
var speed_in_sec = 4
var lerp_val = 0
var start_pos : Vector3 = Vector3.ZERO
# Called when the node enters the scene tree for the first time.
func _ready():
	start_pos = position

func set_target(par):
	target = par

func _physics_process(delta):
	
	lerp_val += delta / speed_in_sec
	
	if lerp_val > 1:
		fwd = not fwd
		lerp_val = 0
		
	if fwd:
		position = start_pos.lerp(target, lerp_val)
	else:
		position = target.lerp(start_pos, lerp_val)
