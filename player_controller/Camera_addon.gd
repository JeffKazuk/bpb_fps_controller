extends Node3D

class_name BPB_Camera_addon

@export var follow_target: NodePath
@export var feat_head_bob: bool = true
@export var feat_lean: bool = true
@export var feat_lean_on_wallrun: bool = true
@export var feat_crouch_crawl: bool = true
@export var fov_default: float = 70
@export var head_bob: float = 0.026
@export var head_bob_speed: float = 8
@export var lean_angle: float = 6
@export var lean_pivot_move_speed: float = 12
@export var wallrun_lean_angle: float = 3

var physic_fps : float = 0.0

#SCREEN SHAKE
var trauma = 0.0
var max_x = 2
var max_y = 2
var max_r = 5
var time_scale = 150
var decay = 0.9
var time = 0
var noise : FastNoiseLite
var target : Node3D
var target_rotation_helper

#HEAD BOB
var hb_sin_speed = 60 * head_bob_speed
var hb_deg_sin_progress = 0
var hb_sin_progress = 0

#LEAN
var lean_speed = 6
var lean_target = 0
var lean_dir = 0
var lean_pivot_move_target = Vector3.ZERO


#CRAWL CROUCH
var crawl_crouch = 0
var crawl_crouch_speed = 6

#TWEEN FOV
var tween_fov_speed = 0.0
var tween_fov_target = 0.0
var tween_fov_back_to_default = false
var tween_wait_time = 0.0

@onready var camera_root = $bob_pivot/lean_pivot/rotation_helper_point/camera_root
@onready var bob_pivot = $bob_pivot
@onready var lean_pivot = $bob_pivot/lean_pivot
@onready var ray_crouch_point_L = $ray_crouch_point_L
@onready var ray_crouch_point_R = $ray_crouch_point_R
@onready var crouch_point = $bob_pivot/lean_pivot/rotation_helper_point/crouch_point
@onready var crawl_point = $bob_pivot/lean_pivot/rotation_helper_point/crawl_point
@onready var camera = $bob_pivot/lean_pivot/rotation_helper_point/camera_root/Camera3D
@onready var ray_lean = $bob_pivot/ray_lean
@onready var tween_fov = $Tween_fov


# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	camera.current = true
	camera.fov = fov_default
	noise = FastNoiseLite.new()
	#set_as_toplevel(true)
	target = get_node_or_null(follow_target)
	if target == null:
		target = get_parent()
	
	physic_fps = ProjectSettings.get_setting("physics/common/physics_ticks_per_second") - 0.5
	global_transform = target.global_transform
	
	ray_crouch_point_L.add_exception(target)
	ray_crouch_point_R.add_exception(target)
	ray_lean.add_exception(target)
	
	#DELAY PROCESS ONE FRAME
	set_process(false)
	call_deferred("activate_process")
	
func activate_process():
	#DELAY PROCESS ONE FRAME SO target.get_rotation_helper() DOESN'T RETURN NULL
	target_rotation_helper = target.get_rotation_helper()
	set_process(true)
	
func _process(delta):
	global_transform = global_transform.interpolate_with(target.global_transform, delta * physic_fps)
	camera_root.rotation.x = lerp_angle(camera_root.rotation.x, target_rotation_helper.rotation.x, delta * physic_fps)
	
	#HEAD BOB
	if feat_head_bob:
		do_headbob(delta)
		
	if feat_crouch_crawl:
		do_crouch_crawl(delta)
		
	if feat_lean or feat_lean_on_wallrun:
		if feat_lean_on_wallrun and target.state == target.STATELIST.WALLRUN:
			do_lean_on_wallrun(delta)
		elif feat_lean:
			do_lean(delta)
		lean_pivot.rotation.z = lerp_angle(lean_pivot.rotation.z, deg_to_rad(lean_target), delta * lean_speed)
		
	screen_shake(delta)
		
func _physics_process(_delta):
	user_input()
	
func user_input():
	lean_dir = 0
	if feat_lean:
		if Input.is_action_pressed("action_lean_left"):
			lean_dir += 1
		if Input.is_action_pressed("action_lean_right"):
			lean_dir -= 1
	
func do_headbob(delta):
	if target.velocity.length() > 1.0 and target.is_on_floor():
		hb_deg_sin_progress += deg_to_rad(delta * hb_sin_speed * target.sprint_modifier)
		if rad_to_deg(hb_deg_sin_progress) > 360:
			hb_deg_sin_progress = 0
		hb_sin_progress = sin(hb_deg_sin_progress)
	else:
		if hb_deg_sin_progress != 0:
			if rad_to_deg(hb_deg_sin_progress) < 180 and hb_deg_sin_progress != 0:
				hb_deg_sin_progress += deg_to_rad(delta * hb_sin_speed)
				if rad_to_deg(hb_deg_sin_progress) > 180:
					hb_deg_sin_progress = 0

			elif rad_to_deg(hb_deg_sin_progress) < 360 and hb_deg_sin_progress != 0:
				hb_deg_sin_progress += deg_to_rad(delta * hb_sin_speed)
				if rad_to_deg(hb_deg_sin_progress) > 360:
					hb_deg_sin_progress = 0
			
			hb_sin_progress = sin(hb_deg_sin_progress)
	
	if target.body_height == target.BODY_HEIGHT_LIST.CROUCH :
		bob_pivot.position.y = lerp(0, -int(head_bob/2), int(hb_sin_progress*2))
	else:
		print(hb_sin_progress)
		print(head_bob)
		bob_pivot.position.y = lerp(0, -int(head_bob), int(hb_sin_progress*2))


func do_lean(_delta):
	
	lean_pivot_move_target = Vector3.ZERO
	if lean_dir > 0:
		ray_lean.target_position = Vector3.LEFT
		lean_pivot_move_target = Vector3.LEFT
		ray_lean.force_raycast_update()
		if ray_lean.is_colliding():
			lean_pivot_move_target *= ray_lean.global_transform.origin.distance_to(ray_lean.get_collision_point()) * 0.5
	elif lean_dir < 0:
		ray_lean.target_position = Vector3.RIGHT
		lean_pivot_move_target = Vector3.RIGHT
		ray_lean.force_raycast_update()
		if ray_lean.is_colliding():
			lean_pivot_move_target *= ray_lean.global_transform.origin.distance_to(ray_lean.get_collision_point()) * 0.5
		
	lean_target = lean_angle * lean_dir
	lean_pivot.position = lean_pivot.position.lerp(lean_pivot_move_target, lean_pivot_move_speed * _delta)
	

func do_lean_on_wallrun(_delta):
	lean_target = 0
	if target.wallrun_left:
		lean_dir -= 1
	else:
		lean_dir += 1
	lean_target = wallrun_lean_angle * lean_dir
	
func do_crouch_crawl(delta):
	if target.body_height == target.BODY_HEIGHT_LIST.CROUCH :
		if ray_crouch_point_L.is_colliding() or ray_crouch_point_R.is_colliding():
			camera_root.position = crouch_point.position.lerp(crawl_point.position, crawl_crouch)
			crawl_crouch = clamp(crawl_crouch + (delta * crawl_crouch_speed), 0, 1)
		else:
			camera_root.position = crouch_point.position.lerp(crawl_point.position, crawl_crouch)
			crawl_crouch = clamp(crawl_crouch - (delta * crawl_crouch_speed), 0, 1)
	else:
		camera_root.position = crouch_point.position.lerp(crawl_point.position, crawl_crouch)
		crawl_crouch = clamp(crawl_crouch - (delta * crawl_crouch_speed), 0, 1)
	
func screen_shake(delta):
	time += delta
	
	var shake = pow(trauma, 2)
	camera.position.x = noise.get_noise_3d(time * time_scale, 0, 0) * max_x * shake
	camera.position.y = noise.get_noise_3d(0, time * time_scale, 0) * max_y * shake
	camera.rotation_degrees.z = noise.get_noise_3d(0, 0, time * time_scale) * max_r * shake
	
	if trauma > 0: trauma = clamp(trauma - (delta * decay), 0, 1)

func get_camera_root():
	return camera_root

func add_screen_shake(trauma_in):
	trauma = clamp(trauma + trauma_in, 0, 1)
	
func tween_fov_to(p_fov, p_tween_speed):
	tween_fov.interpolate_property(camera, "fov", fov_default, p_fov, p_tween_speed, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween_fov.start()

func tween_fov_to_default(p_fov, p_tween_speed):
	tween_fov.interpolate_property(camera, "fov", p_fov, fov_default, p_tween_speed, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween_fov.start()

func tween_fov_then_back_default(p_fov, p_tween_speed_in, p_tween_speed_out, wait_time):
	tween_fov.interpolate_property(camera, "fov", fov_default, p_fov, p_tween_speed_in, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween_fov.interpolate_property(camera, "fov", p_fov, fov_default, p_tween_speed_out, Tween.TRANS_BACK  , Tween.EASE_OUT, wait_time)
	tween_fov.start()
	
func get_fov():
	return camera.fov
