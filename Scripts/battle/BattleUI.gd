class_name BattleUI
extends Node

const ENEMY_HP_BAR_SCENE = "res://Scenes/ui/HP_ProgressBar_Enemy.tscn"
const ENEMY_HP_BAR_SCENE_NAME = "HP_ProgressBar_Enemy"

var manager: BattleManager

func _init(p_manager: BattleManager):
	manager = p_manager


func show_battle_hud(show: bool):
	if is_instance_valid(manager.battle_hud):
		manager.battle_hud.get_node_or_null("%BattleOptions_Container").visible = show

func show_skill_hud(show: bool):
	if is_instance_valid(manager.battle_hud):
		manager.battle_hud.get_node_or_null("%SkillButtons_VBoxContainer").visible = show
		manager.battle_hud.get_node_or_null("%SkillDescription_VBoxContainer").visible = show
		manager.skill_button.disabled = show
		manager.commands_label.visible = show

func _show_battle_end_hud(message: String):
	if is_instance_valid(manager.battleend_hud) and \
	   is_instance_valid(manager.battleend_label):
		manager.battleend_hud.show()
		manager.battleend_label.text = message
		show_battle_hud(false)
		manager.target_selection.show_select_button(false)

func _toggle_combat_options_buttons():
	if is_instance_valid(manager.attack_button):
		manager.attack_button.disabled = not manager.attack_button.disabled

	if is_instance_valid(manager.skip_button):
		manager.skip_button.disabled = not manager.skip_button.disabled

func _remove_ui_from_enemy(entity: Character):
	if not is_instance_valid(entity):
		return
	
	# Rimuovi HP bar
	if entity.has_node(ENEMY_HP_BAR_SCENE_NAME):
		var hpbar = entity.get_node(ENEMY_HP_BAR_SCENE_NAME)
		entity.remove_child(hpbar)
		hpbar.queue_free()
	
	# Nascondi bottone
	manager.target_selection._toggle_select_button_battler(entity, false)
	
	# Update della navigazione dei selection button
	manager.target_selection._update_all_focus_navigation()

func _add_ui_to_enemy(entity: Character):
	_add_hp_bar_to_enemy(entity)

func _add_hp_bar_to_enemy(entity: Character):
	if not is_instance_valid(entity):
		return

	var ui_scene = load(ENEMY_HP_BAR_SCENE) as PackedScene
	if not ui_scene:
		push_error("Cannot load enemy HP bar scene!")
		return
	
	var hp_bar = ui_scene.instantiate()
	entity.add_child(hp_bar)
	hp_bar.max_value = entity.stats.max_hp
	hp_bar.value = entity.stats.current_hp

# ==============================================
# SKILL MENU - Nuovo metodo
# ==============================================
func show_skill_menu(character: Character):
	"""Mostra il menu delle skill per un personaggio"""
	if not is_instance_valid(character):
		return
	
	var skills = character.get_equipped_skills()
	
	if skills.is_empty():
		print("No equipped skills available")
		return
	
	manager.battle_hud.get_node_or_null("%SkillDescription_VBoxContainer").show()
	manager.skill_button.disabled = true
	manager.commands_label.show()
	
	_create_skill_buttons(skills, character)

func _create_skill_buttons(skills: Array[SkillResource], character: Character):
	"""Crea bottoni per ogni skill"""
	# Ottieni container per skill buttons dalla UI
	var skill_container = manager.battle_hud.get_node_or_null("%SkillButtons_VBoxContainer")
	
	if not skill_container:
		push_warning("Skill container not found in UI")
		return
	
	var skill_hbox_duplicate = skill_container.get_child(0).duplicate()
	# Pulisci bottoni precedenti
	for child in skill_container.get_children():
		child.queue_free()
	
	# Crea bottone per ogni skill
	for skill in skills:
		var skill_hbox = skill_hbox_duplicate.duplicate()
		var button = skill_hbox.get_node_or_null("Button")
		button.text = skill.skill_name
		button.get_node_or_null("MarginContainer").get_node_or_null("SkillCost_Label").text = "MP: %d" % skill.mp_cost
		
		# Disabilita se non può essere usata
		var cooldown = character.skillSystem.get_cooldown(skill)
		button.disabled = not skill.can_use(character.stats, cooldown)
		
		# Connetti segnale
		button.pressed.connect(func(): _on_skill_button_pressed(skill))
		button.focus_entered.connect(func(): _on_skill_button_focus_entered(skill))
		button.mouse_entered.connect(func(): _on_skill_button_mouse_entered(button))
		
		skill_container.add_child(skill_hbox)
		skill_hbox.show()
		
		button.grab_focus()
	
	# Mostra container
	skill_container.visible = true

func _on_skill_button_pressed(skill: SkillResource):
	"""Callback quando una skill viene premuta"""
	manager.skill_selected.emit(skill)

func _on_skill_button_focus_entered(skill: SkillResource):
	var label = manager.battle_hud.get_node_or_null("%SkillDescription_Label")
	var text = _set_skill_description_variables(skill.skill_description, skill, manager.turn_manager.current_battler)
	label.text = text
	_update_skill_cooldown_label(manager.turn_manager.current_battler, skill)


func _on_skill_button_mouse_entered(button: Button):
	button.grab_focus()

func _update_skill_cooldown_label(user, skill):
	var cooldown = user.skillSystem.get_cooldown(skill)
	var CD_Label = manager.battle_hud.get_node_or_null("%CD_Label")
	if cooldown > 0:
		CD_Label.show()
		CD_Label.text = "Cooldown: %d turns" % cooldown
	else:
		CD_Label.hide()

func _set_skill_description_variables(skill_description: String, skill: SkillResource, user: Character):
	
	if skill_description.find("%COST_AMOUNT") > 0:
		var cost = skill.hp_cost if skill.hp_cost > 0 else skill.mp_cost
		skill_description = skill_description.replace("%COST_AMOUNT", str(cost))
		
	if skill_description.find("%HPMP_COST") > 0:
		var hpmp = "HP" if skill.hp_cost > 0 else "MP"
		skill_description = skill_description.replace("%HPMP_COST", hpmp)
		
	if skill_description.find("%TURN_COOLDOWN") > 0:
		var cooldown = skill.cooldown_turns
		skill_description = skill_description.replace("%TURN_COOLDOWN", str(cooldown))
		
	if skill_description.find("%PHYSICAL_DAMAGE") > 0:
		var damage = int(skill.base_power + (user.stats.attack * skill.power_scaling))
		skill_description = skill_description.replace("%PHYSICAL_DAMAGE", str(damage))
	
	if skill_description.find("%MAGICAL_DAMAGE") > 0:
		var damage = int(skill.base_power + (user.stats.m_attack * skill.power_scaling))
		skill_description = skill_description.replace("%MAGICAL_DAMAGE", str(damage))
	
	if skill_description.find("%HEAL_AMOUNT") > 0:
		var heal = int(skill.base_power + (user.stats.m_attack * skill.power_scaling))
		skill_description = skill_description.replace("%HEAL_AMOUNT", str(heal))
	
	if skill_description.find("%STATUS_PERCENTEAGE_APPLY") > 0:
		var percenteage = str(skill.status_chance * 100) + "%"
		skill_description = skill_description.replace("%STATUS_PERCENTEAGE_APPLY", percenteage)
	
	if skill_description.find("%STATUS_DURATION") > 0:
		var duration = skill.status.duration_turns
		skill_description = skill_description.replace("%STATUS_DURATION", str(duration))
	
	if skill_description.find("%STATUS_DAMAGE") > 0:
		var status_damage = skill.status.damage_per_turn
		skill_description = skill_description.replace("%STATUS_DAMAGE", str(status_damage))
	
	if skill_description.find("%STATUS_STACK_MAX") > 0:
		var stack_max = skill.status.max_stacks
		skill_description = skill_description.replace("%STATUS_STACK_MAX", str(stack_max))
	
	if skill_description.find("%ATTACK_MODIFIER") > 0:
		var attack_modifier = skill.status.attack_modifier
		skill_description = skill_description.replace("%ATTACK_MODIFIER", str(attack_modifier))
	
	if skill_description.find("%DEFENSE_MODIFIER") > 0:
		var defense_modifier = skill.status.defense_modifier
		skill_description = skill_description.replace("%DEFENSE_MODIFIER", str(defense_modifier))
		
		
	
	return skill_description


func _update_status_effect_ui(target: Character):
	if target in manager.turn_manager.enemy_battlers:
		_update_status_effect_ui_enemy(target)
	
	if target in manager.turn_manager.player_battlers:
		_update_status_effect_ui_player(target)

func _update_status_effect_ui_enemy(target: Character):
	var container = target.get_node_or_null("HP_ProgressBar_Enemy").get_node_or_null("%StatusEffect_HBox_Container")
	if container:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
		
		for active_effect in target.get_active_status_effects():
			var label = Label.new()
			label.text = active_effect.effect_name + str(active_effect.current_stacks) + " " + str(active_effect.remaining_turns)
			container.add_child(label)

func _update_status_effect_ui_player(target: Character):
	var HPMP_Tab_Grid_Container = manager.battle_hud.get_node_or_null("%HPMP_Tab_Grid_Container")
	var player_tab = HPMP_Tab_Grid_Container.get_node_or_null(str(target.stats.party_member))
	var container = player_tab.get_node_or_null("Status_Effects")
	if container:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
		
		for active_effect in target.get_active_status_effects():
			var label = Label.new()
			label.text = active_effect.effect_name + str(active_effect.current_stacks) + " " + str(active_effect.remaining_turns)
			container.add_child(label)
