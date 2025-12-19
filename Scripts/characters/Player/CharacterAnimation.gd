class_name CharacterAnimation
extends Node

var animation_tree: AnimationTree
var sprite_2d: Sprite2D
var state: CharacterState
var base_path: String

# Texture cache
var textures = {}

func _init(p_anim_tree: AnimationTree, p_sprite: Sprite2D, p_state: CharacterState, p_basePath: String):
	animation_tree = p_anim_tree
	sprite_2d = p_sprite
	state = p_state
	base_path = p_basePath
	load_textures()

func load_textures(path:String = base_path):
	textures = {
		"idle": load(path + "Idle.png"),
		"walk": load(path + "Walk.png"),
		"run": load(path + "Run.png"),
		"melee": load(path + "Melee.png"),
		"melee2": load(path + "Melee2.png"),
		"meleerun": load(path + "MeleeRun.png"),
		"crouch_idle": load(path + "CrouchIdle.png"),
		"crouch_run": load(path + "CrouchRun.png"),
		"take_damage": load(path + "TakeDamage.png"),
		"die": load(path + "Die.png")
	}

func update_movement_animation():
	# Reset tutte le conditions
	reset_movement_conditions()
	
	if state.isAttacking:
		return

	if not state.is_moving():
		# Fermo
		if state.isCrouching:
			set_condition("crouchIdle", true)
		else:
			set_condition("idle", true)
	else:
		# In movimento
		if Input.is_action_pressed("run") or state.combatMode:
			# Corsa (disabilita crouch)
			set_condition("run", true)
			state.isRunning = true
			state.isCrouching = false
		elif state.isCrouching:
			# Movimento abbassato
			set_condition("crouchRun", true)
			state.isRunning = false
		else:
			# Camminata normale
			set_condition("walk", true)
			state.isRunning = false


func update_sprite_texture():
	if state.isDead: 
		sprite_2d.texture = textures["die"]
		return
	
	# Set default sprite
	sprite_2d.texture = textures["idle"]
	
	# Set sprite based on state
	if animation_tree["parameters/conditions/walk"] == true: sprite_2d.texture = textures["walk"]
	elif animation_tree["parameters/conditions/run"] == true: sprite_2d.texture = textures["run"]
	elif animation_tree["parameters/conditions/crouchIdle"] == true: sprite_2d.texture = textures["crouch_idle"]
	elif animation_tree["parameters/conditions/crouchRun"] == true: sprite_2d.texture = textures["crouch_run"]
	elif state.isAttacking and state.isAttackingMeleeRun: sprite_2d.texture = textures["meleerun"]
	elif state.isAttacking and state.isAttackingMelee: sprite_2d.texture = textures["melee"]
	elif state.isAttacking and state.isAttackingMelee2: sprite_2d.texture = textures["melee2"]
	elif state.isAttacking and state.isBeingAttacked: sprite_2d.texture = textures["take_damage"]
	


func update_blend_positions():
	if state.input_direction != Vector2.ZERO:
		var blend_trees = [
			"Idle", "Walk", "Run", "Melee", "Melee2", "MeleeRun", "CrouchIdle",
			"CrouchRun", "TakeDamage", "Die"
		]
		for tree in blend_trees:
			animation_tree["parameters/" + tree + "/blend_position"] = state.input_direction

func set_blend_positions(direction:Vector2):
	if direction != Vector2.ZERO:
		var blend_trees = [
			"Idle", "Walk", "Run", "Melee", "Melee2", "MeleeRun", "CrouchIdle",
			"CrouchRun", "TakeDamage", "Die"
		]
		for tree in blend_trees:
			animation_tree["parameters/" + tree + "/blend_position"] = direction

func reset_movement_conditions():
	var conditions = ["idle", "walk", "run", "crouchIdle", "crouchRun"]
	for cond in conditions:
		set_condition(cond, false)
		
func set_condition(condition: String, value: bool):
	animation_tree["parameters/conditions/" + condition] = value

func get_condition(condition: String) -> bool:
	return animation_tree["parameters/conditions/" + condition]
