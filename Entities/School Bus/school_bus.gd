extends CharacterBody2D


enum Gear {
	REVERSE,
	NEUTRAL,
	DRIVE
}


var wheel_base:float = 70  # Distance from front to rear wheel
var steering_angle:float = 20  # Amount that front wheel turns, in degrees

var engine_power:float = 900  # Forward acceleration force.
var reverse_engine_power:float = -400
var service_brake_power:float = -450
var parking_brake_power:float = -1500

var friction:float = -55 # Ground friction
var drag:float = -0.06 # Wind friction

var current_gear:Gear = Gear.NEUTRAL

var acceleration:Vector2
var engine:float
var braking:float
var is_service_brake:bool
var is_parking_brake:bool = true
var steer_direction:float

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("steer_left") or event.is_action_pressed('steer_right'):
		var turn:float = Input.get_axis("steer_left", "steer_right")
		steer_direction = turn * deg_to_rad(steering_angle)
		return
	
	if event.is_action_released("steer_left") or event.is_action_released('steer_right'):
		steer_direction = 0.0
		return
	
	if event.is_action_pressed('accelerate'):
		if current_gear == Gear.DRIVE:
			engine = engine_power
		elif current_gear == Gear.REVERSE:
			engine = reverse_engine_power
		return
	
	if event.is_action_released('accelerate'):
		engine = 0.0
		return
	
	if event.is_action_pressed("service_brake"):
		is_service_brake = true
		return
	
	if event.is_action_released('service_brake'):
		is_service_brake = false
		return
	
	if event.is_action_pressed('toggle_parking_brake'):
		is_parking_brake = !is_parking_brake
	
	if event.is_action_pressed('shift_gear_up'):
		var next_gear:int = current_gear + 1
		if next_gear < Gear.size():
			current_gear = next_gear
	
	if event.is_action_pressed('shift_gear_down'):
		var next_gear:int = current_gear - 1
		if next_gear >= 0:
			current_gear = next_gear

func _physics_process(delta: float) -> void:
	calculate_acceleration()
	apply_friction(delta)
	calculate_steering(delta)
	
	velocity += acceleration * delta
	
	# Fix service brake from rolling the vehicle back
	if (is_service_brake or is_parking_brake) and velocity.length() < 50:
		velocity = Vector2.ZERO
	
	move_and_slide()

func calculate_acceleration() -> void:
	# Reset and recalculate the brake power
	braking = 0.0
	
	var brake_modifier := 1.0
	if current_gear == Gear.REVERSE:
		brake_modifier = -1.0
	
	if is_service_brake:
		braking += service_brake_power * brake_modifier
	
	if is_parking_brake:
		braking += parking_brake_power * brake_modifier
	
	acceleration = transform.x * (braking + engine)

func apply_friction(delta: float) -> void:
	# Friction is the force applied by the ground and is proportional to velocity
	var friction_force:Vector2 = velocity * friction * delta
	# Drag force is the force applied by wind resistance and is proportinal to velocity squared
	var drag_force:Vector2 = velocity * velocity.length() * drag * delta
	
	acceleration += drag_force + friction_force

func calculate_steering(delta: float) -> void:
	# Find the wheel positions
	var rear_wheel:Vector2 = position - transform.x * wheel_base / 2.0
	var front_wheel:Vector2 = position + transform.x * wheel_base / 2.0
	
	# Move the wheels forward
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_direction) * delta
	
	# Find the new direction vector
	var new_heading:Vector2 = (front_wheel - rear_wheel).normalized()
	var d:float = new_heading.dot(velocity.normalized())
	
	# Set the velocity and rotation to the new direction
	if d > 0:
		velocity = new_heading * velocity.length()
	if d < 0:
		velocity = -new_heading * velocity.length()
	rotation = new_heading.angle()
