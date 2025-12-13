class_name BattleCombat
extends Node


var parent_node: BattleManager

func _init(p_parent: BattleManager):
	parent_node = p_parent

func attack(attacking: Character, defender: Character):
	if not parent_node.ui:
		return
	
	parent_node.ui.show_select_button(false)
	attacking.battleAction.execute_attack()
	await parent_node.get_tree().create_timer(0.5).timeout
	defender.battleAction.execute_take_damage(attacking)
	await parent_node.get_tree().create_timer(0.5).timeout
