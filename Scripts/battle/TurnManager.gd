class_name TurnManager
extends Node

var current_battler: Character
var current_turn_index: int = 0
var battlers: Array = []
var player_battlers: Array = []
var enemy_battlers: Array = []
var dead_player_battlers: Array = []
var dead_enemy_battlers: Array = []

var manager: BattleManager
var is_processing_turn: bool = false  # Flag per prevenire operazioni durante save/load

func _init(p_manager: BattleManager):
	manager = p_manager

# ==============================================
# INITIALIZATION
# ==============================================
func initialize_battlers(players: Array, enemies: Array):
	player_battlers = players
	enemy_battlers = enemies
	battlers = players + enemies
	sort_battlers_by_speed()

func sort_battlers_by_speed():
	battlers.sort_custom(func(a, b): return a.stats.turn_speed > b.stats.turn_speed)

func start_first_turn():
	if battlers.size() > 0:
		current_battler = battlers[current_turn_index]
		_activate_battler(current_battler)
		_update_turn()

# ==============================================
# TURN MANAGEMENT
# ==============================================
func advance_turn(skip_timer: bool = false):
	# Previeni esecuzione durante save/load
	if is_processing_turn:
		return
	
	is_processing_turn = true
	
	# Verifica che il manager sia ancora valido
	if not is_instance_valid(manager):
		push_error("Manager is invalid! Cannot advance turn.")
		is_processing_turn = false
		return
	
	if is_instance_valid(current_battler) and not current_battler.state.isDead:
		var end_results = current_battler.trigger_status_effects(StatusEffect.TriggerTiming.END_OF_TURN)
		if end_results.size() > 0:
			await _process_status_results(current_battler, end_results)
			# Controlla di nuovo morte dopo END_OF_TURN effects
			if current_battler.state.isDead:
				manager.remove_ui_from_enemy.emit(current_battler)
				add_battler_to_dead_battlers(current_battler)

	
	# Salva i dati del battler corrente PRIMA di cambiare
	var last_battler_party_member = -999
	if is_instance_valid(current_battler):
		last_battler_party_member = current_battler.stats.party_member
		if current_battler.stats.character_type == StatsResource.CharacterType.PLAYER:
			current_battler.battleMovement.toggle_focus_movement()
	
	manager.ui._update_status_effect_ui(current_battler)
	# Avanza l'indice
	current_turn_index = (current_turn_index + 1) % battlers.size()
	current_battler = battlers[current_turn_index]
	
	manager.ui._update_status_effect_ui(current_battler)

	# Controlla fine battaglia
	if _check_for_battle_end():
		is_processing_turn = false
		return
	
	# Emetti segnale per il battler precedente (usando party_member salvato)
	if last_battler_party_member != -999 and is_instance_valid(manager) and last_battler_party_member > 0:
		manager.toggle_focus_on_player.emit(last_battler_party_member)
	
	# Salta battler morti
	if not is_instance_valid(current_battler) or current_battler.state.isDead:
		is_processing_turn = false
		advance_turn(skip_timer)
		return
	
	# Timer
	if not skip_timer:
		if is_instance_valid(manager):
			await manager.get_tree().create_timer(1.0).timeout
		else:
			is_processing_turn = false
			return
	
	# Controlla di nuovo la validità dopo l'await
	if not is_instance_valid(manager):
		is_processing_turn = false
		return

	
	# Attiva nuovo battler
	_activate_battler(current_battler)
	_update_turn()
	
	is_processing_turn = false

func _update_turn():
	if not is_instance_valid(manager):
		return
		
	if is_player_turn():
		manager.show_battle_hud.emit(true)
		manager.show_skill_hud.emit(false)
		manager.attack_button.grab_focus()
	else:
		manager.show_battle_hud.emit(false)
		manager.request_ai_target.emit()

func is_player_turn() -> bool:
	return is_instance_valid(current_battler) and \
		   current_battler.stats.character_type == StatsResource.CharacterType.PLAYER

# ==============================================
# BATTLER ACTIVATION
# ==============================================
func _activate_battler(battler: Character):
	if not is_instance_valid(battler) or not is_instance_valid(manager):
		return
	
	# Riduce cooldown dell'utilizzatore
	if battler.skillSystem:
		battler.skillSystem.reduce_cooldowns()
	
	# Aggiorna la turn order bar
	manager.battle_hud._set_current_turn_name(current_battler.stats.character_name)
	
	var start_results = battler.trigger_status_effects(StatusEffect.TriggerTiming.START_OF_TURN)
	
	if start_results.size() > 0:
		await _process_status_results(battler, start_results)
	
	if battler.is_stunned():
		print("%s is stunned and cannot act!" % battler.stats.character_name)
		# Salta il turno
		is_processing_turn = false
		advance_turn(false)
		return
	
	if battler.stats.character_type == StatsResource.CharacterType.PLAYER:
		battler.battleMovement.toggle_focus_movement()
	
	if battler.stats.party_member > 0:
		manager.toggle_focus_on_player.emit(battler.stats.party_member)

func _process_status_results(battler: Character, results: Array[Dictionary]):
	"""Processa i risultati degli status effects"""
	for result in results:
		if result.message != "":
			print(result.message)
		
		# Update UI per damage/healing
		if result.damage > 0 or result.healing > 0:
			battler.battleAction.emit_signal("update_hpmp_ui", battler)
		
		# Check morte da DoT
		if battler.state.isDead:
			manager.remove_ui_from_enemy.emit(battler)
			manager.turn_manager.add_battler_to_dead_battlers(battler)
		
		await manager.get_tree().create_timer(0.5).timeout

# ==============================================
# BATTLE END CHECK
# ==============================================
func _check_for_battle_end() -> bool:
	if not is_instance_valid(manager):
		return true  # Ferma il combattimento se manager è invalido
		
	var all_enemies_dead = enemy_battlers.all(
		func(e): return not is_instance_valid(e) or e.state.isDead
	)
	if all_enemies_dead:
		manager.battle_ended.emit("Victory")
		return true
	
	var all_players_dead = player_battlers.all(
		func(p): return not is_instance_valid(p) or p.state.isDead
	)
	if all_players_dead:
		manager.battle_ended.emit("Defeat")
		return true
	
	return false

# ==============================================
# GETTERS
# ==============================================
func get_all_battlers() -> Array:
	return battlers

func get_current_battler() -> Character:
	return current_battler

func get_current_turn_index() -> int:
	return current_turn_index

func set_current_turn_index(index: int):
	current_turn_index = index



# ==============================================
# BATTLERS MANAGER
# ==============================================
func add_battler_to_dead_battlers(target: Character):
	if player_battlers.has(target):
		var index = player_battlers.find(target)
		player_battlers.remove_at(index)
		dead_player_battlers.append(target)
	
	if enemy_battlers.has(target):
		var index = enemy_battlers.find(target)
		enemy_battlers.remove_at(index)
		dead_enemy_battlers.append(target)

func add_dead_battler_to_battlers(target: Character):
	if dead_player_battlers.has(target):
		var index = dead_player_battlers.find(target)
		dead_player_battlers.remove_at(index)
		player_battlers.append(target)
	
	if dead_enemy_battlers.has(target):
		var index = dead_enemy_battlers.find(target)
		dead_enemy_battlers.remove_at(index)
		enemy_battlers.append(target)
	
