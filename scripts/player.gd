extends CharacterBody3D

# Constants and Variables
@onready var neck = $neck
@onready var head = $neck/head
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var player_raycast_3d = $player_raycast_3d
@onready var camera_3d = $neck/head/Camera3D

const JUMP_VELOCITY = 4.5
const CROUCHING_SPEED = 3.0

var crouching_depth = -0.5
var sprinting_speed = 8.0
var walking_speed = 5.0
var current_speed = 5.0
var lerp_speed = 10.0
var free_look_tilt_amount = 8

var mouse_sensitivity = 0.25
var direction = Vector3.ZERO

var walking = false
var sprinting = false
var crouching = false
var sliding = false
var is_free_looking = false

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Ready
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
# Input	Events
func _input(event):
	# Mouse Motion Input Event
	if event is InputEventMouseMotion:
		if is_free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			neck.rotation.y = clamp(neck.rotation.y, 
			deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
			head.rotation.x = clamp(head.rotation.x, 
			deg_to_rad(-89), deg_to_rad(89))
		
	

# Physics Process
func _physics_process(delta):
	
	# Get the Input Direction
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Check if we're crouching, sprinting or walking
	
	# Crouching
	if Input.is_action_pressed("crouch") or sliding:
		current_speed = CROUCHING_SPEED
		head.position.y = lerp(head.position.y, 
		crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		# Sliding
		if sprinting and input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			is_free_looking = true
			print("Begin Slide")
		
		walking = false
		sprinting = false
		crouching = true
		
	# Standing	
	elif !player_raycast_3d.is_colliding():
		head.position.y = lerp(head.position.y, 
		0.0, delta * lerp_speed)
		crouching_collision_shape.disabled = true
		standing_collision_shape.disabled = false
		
		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = sprinting_speed
			walking = false
			sprinting = true
			crouching = false
		else:
			# Walking
			current_speed = walking_speed
			walking = true
			sprinting = false
			crouching = false
			
	# Handle Free Look
	if Input.is_action_pressed("free_look") or sliding:
		is_free_looking = true
		
		if sliding:
			camera_3d.rotation.z = lerp(
			camera_3d.rotation.z, -deg_to_rad(7.0),
			delta * lerp_speed)
		else:
			camera_3d.rotation.z = -deg_to_rad(
			neck.rotation.y * free_look_tilt_amount) 
	else:
		is_free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera_3d.rotation.z = lerp(neck.rotation.z, 0.0, delta * lerp_speed)
		
	# Handle Slide
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			is_free_looking = false
			print("End Slide")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle the movement/deceleration.
	direction = lerp(direction, 
	(transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	.normalized(), delta * lerp_speed)
	
	if sliding:
		direction = (transform.basis * 
		Vector3(slide_vector.x, 0, 
		input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * slide_timer * slide_speed
			velocity.z = direction.z * slide_timer * slide_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
