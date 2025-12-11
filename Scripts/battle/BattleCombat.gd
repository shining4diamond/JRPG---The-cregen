class_name BattleCombat
extends Node2D

var parent_node : Node2D

func _init(p_parent: Node2D):
	parent_node = p_parent
	

func attack(attacking: Character, defender: Character):
	parent_node.ui.show_select_button(false)
	attacking.battleAction.execute_attack()
	await parent_node.get_tree().create_timer(0.5).timeout
	defender.battleAction.execute_take_damage(attacking)
	await parent_node.get_tree().create_timer(0.5).timeout
	
