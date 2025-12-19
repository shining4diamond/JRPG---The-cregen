class_name BattleUI
extends Node

const ENEMY_HP_BAR_SCENE = "res://Scenes/ui/HP_ProgressBar_Enemy.tscn"
const ENEMY_HP_BAR_SCENE_NAME = "HP_ProgressBar_Enemy"

var manager: BattleManager

func _init(p_manager: BattleManager):
	manager = p_manager


func show_battle_hud(show: bool):
	if is_instance_valid(manager.battle_hud):
		var container = manager.battle_hud.get_node_or_null("%BattleOptions_Container")
		if container:
			container.visible = show
		
		# Nascondi menu skill quando nascondi HUD
		if not show:
			hide_skill_menu()

func show_skill_hud(show: bool):
	if is_instance_valid(manager.battle_hud):
		var container = manager.battle_hud.get_node_or_null("%SkillButtons_VBoxContainer")
		if container:
			container.visible = show
		
		# Nascondi menu skill quando nascondi HUD
		if not show:
			hide_skill_menu()

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
	
	# Rimuovi dal dictionary dei bottoni
	manager.remove_enemy_select_button(entity.stats.party_member)

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
	
	# Qui puoi creare un pannello UI dinamico
	# Per ora stampiamo le skill disponibili
	#print("Available skills for %s:" % character.stats.character_name)
	#for i in skills.size():
		#var skill = skills[i]
		#var cooldown = character.skillSystem.get_cooldown(skill)
		#print("%d. %s (MP: %d, CD: %d)" % [i+1, skill.skill_name, skill.mp_cost, cooldown])
	
	# TODO: Implementare UI completa con pulsanti
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
		
		var CD_Label = skill_hbox.get_node_or_null("CD_Label")
		if button.disabled and cooldown > 0:
			CD_Label.text = "Cooldown: %d turns" % cooldown
		else:
			CD_Label.text = ""
		
		
		# Connetti segnale
		button.pressed.connect(func(): _on_skill_button_pressed(skill))
		
		skill_container.add_child(skill_hbox)
		skill_hbox.show()
	
	# Mostra container
	skill_container.visible = true

func _on_skill_button_pressed(skill: SkillResource):
	"""Callback quando una skill viene premuta"""
	manager.skill_selected.emit(skill)

func hide_skill_menu():
	"""Nascondi il menu skill"""
	var skill_container = manager.battle_hud.get_node_or_null("%SkillButtons_Container")
	if skill_container:
		skill_container.visible = false
