class_name BattleCombat
extends Node

var manager: BattleManager

func _init(p_manager: BattleManager):
	manager = p_manager

func execute_attack(attacker: Character, defender: Character):
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		push_error("Invalid attacker or defender!")
		return
	
	manager.show_select_buttons.emit(false)
	
	if is_instance_valid(attacker):
		attacker.battleAction.execute_attack()
		await manager.get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(defender):
		defender.battleAction.execute_take_damage(attacker)
		await manager.get_tree().create_timer(0.5).timeout
	
	if defender.state.isDead:
		manager.remove_ui_from_enemy.emit(defender)
