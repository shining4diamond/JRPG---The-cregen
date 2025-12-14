class_name CharacterBattleAction
extends Node

var animation_tree: AnimationTree
var state: CharacterState
var animation: CharacterAnimation
var attack_timer: Timer
var character: Character
var tween

signal update_hpmp_ui(character: Character)

func _init(p_anim_tree: AnimationTree, \
p_state: CharacterState, \
p_timer: Timer, \
p_animation: CharacterAnimation, \
p_character: Character):
	animation_tree = p_anim_tree
	state = p_state
	attack_timer = p_timer
	animation = p_animation
	character = p_character
	attack_timer.timeout.connect(_on_attack_timeout)


func execute_attack():
	set_condition("melee", true)
	state.isAttackingMelee = true
		
	start_attack()

func execute_take_damage(attacker: Character):
	set_condition("takeDamage", true)
	state.isBeingAttacked = true
	start_attack()
	
	var damage = attacker.stats.attack - character.stats.defense
	if damage > 0:
		character.stats.current_hp -= damage
		if character.stats.current_hp < 1:
			character.stats.current_hp = 0
			execute_death()
		
		emit_signal("update_hpmp_ui", character)
		

func execute_death():
	set_condition("die", true)
	state.isDead = true

func start_attack():
	state.isAttacking = true
	attack_timer.start()

func reset_attack_conditions():
	var conditions = ["melee", "melee2", "meleeRun", "takeDamage"]
	for cond in conditions:
		set_condition(cond, false)
		
func set_condition(condition: String, value: bool):
	animation_tree["parameters/conditions/" + condition] = value

func get_condition(condition: String) -> bool:
	return animation_tree["parameters/conditions/" + condition]

func _on_attack_timeout():
	state.isAttacking = false
	state.reset_attack_flags()
	reset_attack_conditions()



func _on_select_button_mouse_entered() -> void:
	if tween:
		tween.kill()
	set_tween()
	tween.set_loops()
	await tween.tween_property(character.get_node("Sprite2D"), "modulate", Color(1.0, 1.0, 1.0, 0.4), 0.5)
	await tween.tween_property(character.get_node("Sprite2D"), "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _on_select_button_mouse_exited() -> void:
	if tween:
		tween.kill()
	character.get_node("Sprite2D").modulate = Color.WHITE

func set_tween():
	tween = character.get_parent().get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)


func _process(_delta: float) -> void:
	var button = character.get_node_or_null("%Select_Button")
	
	if button and button.visible == false and tween:
		_on_select_button_mouse_exited()

	if character.state.isDead and button and button.visible:
		button.visible = false
