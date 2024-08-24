extends CharacterBody3D

var speed = 2400
var life = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)
	pass # Replace with function body.


func _physics_process(delta):
	set_velocity(-global_transform.basis.z * speed * delta)
	move_and_slide()
	var _ret = velocity
	if get_slide_collision_count() > 0:
		queue_free()
		
	if life > 0:
		life -= delta
	else:
		queue_free()
