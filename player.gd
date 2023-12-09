extends CharacterBody2D

const WALL_X_JUMP_FORCE = 20.0
const X_FORCE_WHILE_HOVER = 5.0
const GRAVITY = 1000.0
const JUMP_FORCE = 400.0
const FRICTION = 0.9
const WALKING_MIN_SPEED = 20.0
const WALKING_SPEED = 50.0
const WALL_SLIDING_SPEED = 100.0
const MAX_JUMP_COUNT = 2

enum State {
	Idle, Walking, Jumping, Falling, WallSliding
}

var state2string = { State.Idle : "Idle", State.Walking : "Walking", State.Jumping : "Jumping", State.Falling : "Falling", State.WallSliding : "WallSliding" }
var acceleration = Vector2.ZERO
var direction = Vector2.RIGHT
var can_jump = true
var jump_count = 0
var last_state = State.Idle
var state = State.Idle
var dt = 0.0166666667

func _physics_process(delta):
	direction.x = Input.get_axis("ui_left", "ui_right")
	dt = delta
	match (state):
		State.Idle:
			Idle()
		State.Walking:
			Walk()
		State.Jumping:
			Jump()
		State.Falling:
			Fall()
		State.WallSliding:
			WallSlide()
	move_and_slide()
	$state_label.text = state2string[state]

func _apply_flip():
	if (direction.x < 0.0):
		$spr.flip_h = true
	elif (direction.x > 0.0):
		$spr.flip_h = false

func _apply_gravity():
	velocity.y += GRAVITY * dt

func _apply_wall_slide_gravity():
	velocity.y += WALL_SLIDING_SPEED * dt

func _apply_friction():
	if velocity.x != 0.0:
		velocity.x = int(velocity.x * FRICTION)

func _apply_acceleration():
	velocity += acceleration
	acceleration = Vector2.ZERO	

func _apply_x_movement():
	if (direction.x != 0.0):
		acceleration.x += direction.x * WALKING_SPEED
		_apply_acceleration()
		acceleration.x = 0.0

func Idle():
	$anim.play("idle")
	can_jump = true
	jump_count = 0
	_apply_flip()
	_apply_friction()
	if (is_on_floor() == false):
		last_state = State.Idle
		state = State.Falling
		return
	if (direction.x != 0.0):
		last_state = State.Idle
		state = State.Walking
	if (Input.is_action_just_pressed("ui_up") and can_jump == true):
		jump_count += 1
		if (jump_count == MAX_JUMP_COUNT):
			can_jump = false
		velocity.y = -JUMP_FORCE
		last_state = State.Idle
		state = State.Jumping
		return
	_apply_gravity()

func Walk():
	_apply_flip()
	_apply_x_movement()
	_apply_friction()
	if (Input.is_action_just_pressed("ui_up") and can_jump == true):
		jump_count += 1
		if (jump_count == MAX_JUMP_COUNT):
			can_jump = false
		velocity.y = -JUMP_FORCE
		last_state = State.Walking
		state = State.Jumping
		return
	if (abs(velocity.x) > WALKING_MIN_SPEED):
		$anim.play("walk")
	else:
		last_state = State.Walking
		state = State.Idle
		return
	_apply_gravity()
	
func Jump():
	if (jump_count > 1):
		$anim.play("double_jump")
	else:
		$anim.play("jump")
	if (last_state != State.WallSliding and is_on_wall_only() and $detect_botton.is_colliding() == false):
		velocity.y = 0.0
		last_state = State.Jumping
		state = State.WallSliding
		return
	if (last_state == State.WallSliding and direction.x != 0.0):
		acceleration.x = direction.x * WALL_X_JUMP_FORCE
		_apply_flip()
		_apply_acceleration()
		_apply_friction()
	if (Input.is_action_just_pressed("ui_up") and can_jump == true):
		jump_count += 1
		if (jump_count == MAX_JUMP_COUNT):
			can_jump = false
		velocity.y = -JUMP_FORCE
		return
	if (velocity.y > 0):
		last_state = State.Jumping
		state = State.Falling
	if (is_on_floor() == true):
		last_state = State.Jumping
		state = State.Idle
	_apply_gravity()

func Fall():
	if (direction.x != 0.0):
		acceleration.x = direction.x * X_FORCE_WHILE_HOVER
		_apply_acceleration()
		_apply_flip()
	if (Input.is_action_just_pressed("ui_up") and can_jump == true):
		jump_count += 1
		if (jump_count == MAX_JUMP_COUNT):
			can_jump = false
		velocity.y = -JUMP_FORCE
		last_state = State.Falling
		state = State.Jumping
		if (jump_count > 1):
			$anim.play("double_jump")
		else:
			$anim.play("jump")
		return
	else:
		$anim.play("fall")
	if (is_on_wall_only()):
		velocity.y = 0.0
		last_state = State.Falling
		state = State.WallSliding
		return
	if (is_on_floor() == true):
		can_jump = true
		jump_count = 0
		last_state = State.Falling
		state = State.Idle
	_apply_gravity()

func WallSlide():
	can_jump = true
	jump_count = 0
	$anim.play("wall_slide")
	if (is_on_wall_only() == false):
		last_state = State.WallSliding
		state = State.Falling
		return
	if (is_on_floor()):
		last_state = State.WallSliding
		state = State.Idle
	if (Input.is_action_just_pressed("ui_up")):
		velocity.y = -JUMP_FORCE
		if (direction.x != 0.0):
			acceleration.x = direction.x * X_FORCE_WHILE_HOVER
			_apply_acceleration()
			_apply_flip()
		last_state = State.WallSliding
		state = State.Jumping
		return
	_apply_wall_slide_gravity()
