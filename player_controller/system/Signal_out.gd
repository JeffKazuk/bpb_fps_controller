extends Area3D

@export var wind_force: float = 0
@export var ladder: bool = false
@export var gravity_sphere: bool = false
@export var gravity_local_down: bool = false
@export var swim_area: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if gravity_sphere:
		var area = Area3D.new()
		# area.space_override = SPACE_OVERRIDE_REPLACE
		area.gravity_point = true
		for o in get_children():
			if o is CollisionShape3D or o is CollisionPolygon3D:
				var dup = o.duplicate()
				area.add_child(dup)
				
		add_child(area)
		
	elif gravity_local_down:
		var area = Area3D.new()
		# area.space_override = SPACE_OVERRIDE_REPLACE
		area.gravity_direction = -global_transform.basis.y
		for o in get_children():
			if o is CollisionShape3D or o is CollisionPolygon3D:
				var dup = o.duplicate()
				area.add_child(dup)
				
		add_child(area)
		
	elif swim_area:
		var area = Area3D.new()
		# area.space_override = SPACE_OVERRIDE_REPLACE
		area.gravity = 1.0
		for o in get_children():
			if o is CollisionShape3D or o is CollisionPolygon3D:
				var dup = o.duplicate()
				area.add_child(dup)
				
		add_child(area)
		area.connect("body_entered", Callable(self, "swim_area_body_entered"))
	
func swim_area_body_entered(body):
	if body is RigidBody3D:
		body.linear_velocity *= 0.4
		body.angular_velocity *= 0.4
