class_name CharacterState
extends Resource

# Stati booleani
var combatMode: bool = false

var isAttacking: bool = false
var isAttackingMelee: bool = false
var isAttackingMelee2: bool = false
var isAttackingMeleeRun: bool = false
var isBeingAttacked: bool = false
var isRunning: bool = false
var isCrouching: bool = false
var isDead: bool = false

# Combo
var melee_combo: bool = true

# Direzione
var input_direction: Vector2 = Vector2.ZERO

func reset_attack_flags():
	isAttackingMelee = false
	isAttackingMelee2 = false
	isAttackingMeleeRun = false
	isBeingAttacked = false

func is_moving() -> bool:
	return input_direction != Vector2.ZERO and not isAttacking
