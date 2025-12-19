class_name BattleTargetSelection
extends Node

var manager: BattleManager

# Dictionary per mappare party_member -> Button
var enemy_select_buttons: Dictionary = {}
var player_select_buttons: Dictionary = {}
var enemy_select_buttons_active: bool = false
var player_select_buttons_active: bool = false

func _init(p_manager: BattleManager):
	manager = p_manager

func show_select_button(show: bool, target: String = "ALL"):
	var turn_mgr = manager.turn_manager
	if not turn_mgr:
		return
	
	var first_button_focused = false
	var targets
	if target == "ALL":
		targets = turn_mgr.battlers
		if show:
			enemy_select_buttons_active = true
			player_select_buttons_active = true
		else:
			enemy_select_buttons_active = false
			player_select_buttons_active = false
			
	elif target== "ENEMY":
		targets = turn_mgr.enemy_battlers
		if show:
			enemy_select_buttons_active = true
		else:
			enemy_select_buttons_active = false
	elif target == "ALLY":
		targets = turn_mgr.player_battlers
		if show:
			player_select_buttons_active = true
		else:
			player_select_buttons_active = false
			
	else:
		targets = null
	
	for character in targets:
		if is_instance_valid(character) and not character.state.isDead:
			var button = character.get_node_or_null("Sprite2D/Select_Button")
			if button:
				button.visible = show
				manager.commands_label.visible = show
				if button.visible:
					manager.target_selection.enemy_select_buttons_active = true
				else:
					manager.target_selection.enemy_select_buttons_active = false
			
			# Grab focus sul primo bottone disponibile
			if show and not first_button_focused:
				var enemy_select_button = manager.target_selection.get_battler_select_button(character.stats.party_member)
				if enemy_select_button:
					enemy_select_button.grab_focus()
					first_button_focused = true

func _toggle_select_button_battler(entity: Character, visible: bool = true):
	if not is_instance_valid(entity):
		return
	
	var enemy_select_button = manager.target_selection.get_battler_select_button(entity.stats.party_member)
	if enemy_select_button:
		enemy_select_button.visible = visible

func _return_battler_on_party_member(party_member: int):
	var turn_mgr = manager.turn_manager
	if not turn_mgr:
		return null
	
	for character in turn_mgr.battlers:
		if character.stats.party_member == party_member:
			return character
	return null

func setup_select_buttons(characters: Array[Character]):
	"""Setup dinamico di tutti i bottoni nemici"""
	for character in characters:
		if not is_instance_valid(character):
			continue
		
		var button = character.get_node_or_null("Sprite2D/Select_Button")
		if button:
			manager.target_selection.setup_select_button(character.stats.party_member, button)

# ==============================================
# GETTER
# ==============================================
func get_battler_select_button(party_member: int) -> Button:
	"""Ottiene il bottone di selezione per un party_member specifico"""
	var button = enemy_select_buttons.get(party_member, null)
	if button != null:
		return button
	
	button = player_select_buttons.get(party_member, null)
	return button

# ==============================================
# DYNAMIC ENEMY SELECTION HANDLERS
# ==============================================
func setup_select_button(party_member: int, button: Button):
	"""Configura dinamicamente un bottone di selezione nemico"""
	
	# Salva riferimento
	if party_member > 0:
		player_select_buttons[party_member] = button
	else:
		enemy_select_buttons[party_member] = button
	
	# Connetti segnali con closures
	button.focus_entered.connect(func(): _on_battler_focus(party_member))
	button.focus_exited.connect(func(): _on_battler_unfocus(party_member))
	button.mouse_entered.connect(func(): _on_battler_focus(party_member))
	button.pressed.connect(func(): _on_battler_pressed(party_member))
	
	# Setup focus navigation
	if party_member > 0:
		_setup_focus_navigation(button, player_select_buttons)
	else:
		_setup_focus_navigation(button, enemy_select_buttons)

func _setup_focus_navigation(button: Button, select_buttons: Dictionary):
	"""Configura la navigazione tra i bottoni"""
	var indices = select_buttons.keys()
	if select_buttons == player_select_buttons:
		indices.sort_custom(_sort_desc)
	else:
		indices.sort()
	
	if indices.size() > 1:
		var prev_button = select_buttons[indices[1]]
		prev_button.focus_neighbor_bottom = button.get_path()
		button.focus_neighbor_top = prev_button.get_path()

func _sort_desc(a,b):
	return a>b
func _on_battler_focus(party_member: int):
	"""Handler per quando un bottone nemico riceve il focus"""
	var character = _return_battler_on_party_member(party_member)
	if character:
		manager.selected_character = character
		character.battleAction._on_select_button_mouse_entered()
		
		# Assicura che il bottone abbia il focus
		if enemy_select_buttons.has(party_member):
			enemy_select_buttons[party_member].grab_focus()
		if player_select_buttons.has(party_member):
			player_select_buttons[party_member].grab_focus()

func _on_battler_unfocus(party_member: int):
	"""Handler per quando un bottone nemico perde il focus"""
	var character = _return_battler_on_party_member(party_member)
	if character:
		character.battleAction._on_select_button_mouse_exited()

func _on_battler_pressed(party_member: int):
	"""Handler per quando un bottone nemico viene premuto"""
	_on_battler_unfocus(party_member)
	if manager.selected_character:
		manager._on_select_enemy_pressed(manager.selected_character)

func _focus_battler(party_member: int):
	var character = _return_battler_on_party_member(party_member)
	if character:
		character.battleAction._on_select_button_mouse_entered()
		
		var button = manager.get_battler_select_button(party_member)
		if button:
			button.grab_focus()
	return character

func _unfocus_battler(party_member: int):
	var character = _return_battler_on_party_member(party_member)
	if character:
		character.battleAction._on_select_button_mouse_exited()

func remove_battler_select_button(party_member: int):
	"""Rimuove un bottone dalla lista (quando il nemico muore)"""
	if enemy_select_buttons.has(party_member):
		enemy_select_buttons.erase(party_member)
		# Aggiorna la navigazione focus per i bottoni rimanenti
		_update_all_focus_navigation()

func _update_all_focus_navigation():
	"""Aggiorna la navigazione focus per tutti i bottoni rimasti"""
	for party_member in enemy_select_buttons.keys():
		var button = enemy_select_buttons[party_member]
		_setup_focus_navigation(button, enemy_select_buttons)
	
	for party_member in player_select_buttons.keys():
		var button = player_select_buttons[party_member]
		_setup_focus_navigation(button, player_select_buttons)
