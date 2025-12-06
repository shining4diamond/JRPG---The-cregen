extends CharacterBody2D


var SPEED = 130.0
const JUMP_VELOCITY = -300.0
var direction:String = "down"
var animation:String = "idle_"


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up", "move_down")
	var directionv = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = get_direction(directionv.x, directionv.y)
	
	animation = get_animation()
	
	$AnimatedSprite2D.play(animation+direction)

	if direction_x:
		velocity.x = direction_x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction_y:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	
	move_and_slide()



func get_direction(direction_x:float, direction_y:float):
	if direction_x > 0 and direction_y == 0:
		return "right"
	elif direction_x < 0 and direction_y == 0:
		return "left"
	elif direction_x == 0 and direction_y > 0:
		return "down"
	elif direction_x == 0 and direction_y < 0:
		return "up"
	elif direction_x > 0 and direction_y > 0:
		return "down_right"
	elif direction_x < 0 and direction_y > 0:
		return "down_left"
	elif direction_x > 0 and direction_y < 0:
		return "up_right"
	elif direction_x < 0 and direction_y < 0:
		return "up_left"
	return direction


func get_animation():
	if velocity.x == 0.0 and velocity.y == 0.0:
		return "idle_"
	else:
		return "walk_"
