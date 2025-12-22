class_name CharacterStatusManager
extends Node

signal status_applied(effect: StatusEffect)
signal status_triggered(effect: StatusEffect, result: Dictionary)
signal status_expired(effect: StatusEffect)

var character: Character
var active_effects: Array[StatusEffect] = []

func _init(p_character: Character):
	character = p_character

# ==============================================
# APPLICARE STATUS EFFECTS
# ==============================================

func apply_status(effect_resource: StatusEffect, stacks: int = 1) -> bool:
	"""Applica un nuovo status effect al personaggio"""
	if not effect_resource:
		return false
	
	# Controlla se l'effetto è già presente
	var existing = _find_effect_by_name(effect_resource.effect_name)
	
	if existing:
		if effect_resource.can_stack:
			# Aggiungi stack
			existing.add_stack()
			print("%s gained a stack of %s (now %d)" % [character.stats.character_name, effect_resource.effect_name, existing.current_stacks])
			return true
		elif effect_resource.stack_refresh_duration:
			# Refresh durata
			existing.remaining_turns = effect_resource.duration_turns
			print("%s's %s duration refreshed" % [character.stats.character_name, effect_resource.effect_name])
			return true
		else:
			# Non stacka e non refresha, ignora
			return false
	
	# Crea nuova istanza dell'effetto
	var new_effect = effect_resource.duplicate_instance()
	new_effect.initialize(character, stacks)
	active_effects.append(new_effect)
	
	# Applica modificatori stat se necessario
	_apply_stat_modifiers(new_effect)
	
	# Visual effects
	_play_status_visual(new_effect)
	
	status_applied.emit(new_effect)
	print("%s is now affected by %s (%d turns)" % [character.stats.character_name, new_effect.effect_name, new_effect.remaining_turns])
	
	return true

func remove_status(effect_name: String) -> bool:
	"""Rimuove uno status effect specifico"""
	var effect = _find_effect_by_name(effect_name)
	if not effect:
		return false
	
	_remove_stat_modifiers(effect)
	active_effects.erase(effect)
	status_expired.emit(effect)
	
	print("%s is no longer affected by %s" % [character.stats.character_name, effect_name])
	return true

func clear_all_status():
	"""Rimuove tutti gli status effects"""
	for effect in active_effects.duplicate():
		remove_status(effect.effect_name)

# ==============================================
# TRIGGER STATUS EFFECTS
# ==============================================

func trigger_effects(timing: StatusEffect.TriggerTiming) -> Array[Dictionary]:
	"""Triggera tutti gli effetti con un certo timing"""
	var results: Array[Dictionary] = []
	
	for effect in active_effects.duplicate():  # Duplicate per evitare issues durante rimozione
		if effect.trigger_timing == timing:
			var result = effect.apply_effect()
			
			if result.damage > 0 or result.healing > 0 or result.blocked_action:
				results.append(result)
				status_triggered.emit(effect, result)
				
				# Update UI se necessario
				if result.damage > 0 or result.healing > 0:
					character.battleAction.emit_signal("update_hpmp_ui", character)
			
			# Riduci durata
			if effect.reduce_duration():
				remove_status(effect.effect_name)
	
	return results

func is_stunned() -> bool:
	"""Controlla se il personaggio è stunnato"""
	for effect in active_effects:
		if effect.effect_type == StatusEffect.EffectType.STUN:
			return true
	return false

func can_act() -> bool:
	"""Controlla se il personaggio può agire (non stunnato)"""
	return not is_stunned()

# ==============================================
# STAT MODIFIERS
# ==============================================

func _apply_stat_modifiers(effect: StatusEffect):
	"""Applica i modificatori di stat dell'effetto"""
	if effect.effect_type != StatusEffect.EffectType.STAT_MODIFIER:
		return
	
	character.stats.attack += effect.get_stat_modifier("attack")
	character.stats.defense += effect.get_stat_modifier("defense")
	character.stats.m_attack += effect.get_stat_modifier("m_attack")
	character.stats.m_defense += effect.get_stat_modifier("m_defense")
	character.stats.turn_speed += effect.get_stat_modifier("turn_speed")

func _remove_stat_modifiers(effect: StatusEffect):
	"""Rimuove i modificatori di stat dell'effetto"""
	if effect.effect_type != StatusEffect.EffectType.STAT_MODIFIER:
		return
	
	character.stats.attack -= effect.get_stat_modifier("attack")
	character.stats.defense -= effect.get_stat_modifier("defense")
	character.stats.m_attack -= effect.get_stat_modifier("m_attack")
	character.stats.m_defense -= effect.get_stat_modifier("m_defense")
	character.stats.turn_speed -= effect.get_stat_modifier("turn_speed")

func get_total_stat_modifier(stat_name: String) -> int:
	"""Ottiene il modificatore totale per una stat da tutti gli effetti attivi"""
	var total = 0
	for effect in active_effects:
		if effect.effect_type == StatusEffect.EffectType.STAT_MODIFIER:
			total += effect.get_stat_modifier(stat_name)
	return total

# ==============================================
# VISUAL EFFECTS
# ==============================================

func _play_status_visual(effect: StatusEffect):
	"""Riproduce effetti visivi per lo status"""
	# Tint del personaggio
	if effect.tint_color != Color.WHITE:
		_apply_tint(effect.tint_color)
	
	# Particle effect
	if effect.particle_effect:
		var particles = effect.particle_effect.instantiate()
		character.add_child(particles)
		# TODO: Auto-cleanup particles

func _apply_tint(color: Color):
	"""Applica un tint al personaggio"""
	if character.has_node("Sprite2D"):
		var sprite = character.get_node("Sprite2D")
		var tween = character.get_tree().create_tween()
		tween.tween_property(sprite, "modulate", color, 0.3)

func _remove_tint():
	"""Rimuove il tint dal personaggio"""
	if character.has_node("Sprite2D"):
		var sprite = character.get_node("Sprite2D")
		var tween = character.get_tree().create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

# ==============================================
# QUERY
# ==============================================

func has_effect(effect_name: String) -> bool:
	"""Controlla se ha un effetto specifico"""
	return _find_effect_by_name(effect_name) != null

func get_effect(effect_name: String) -> StatusEffect:
	"""Ottiene un effetto specifico"""
	return _find_effect_by_name(effect_name)

func get_all_effects() -> Array[StatusEffect]:
	"""Ottiene tutti gli effetti attivi"""
	return active_effects.duplicate()

func _find_effect_by_name(effect_name: String) -> StatusEffect:
	"""Trova un effetto per nome"""
	for effect in active_effects:
		if effect.effect_name == effect_name:
			return effect
	return null

# ==============================================
# SAVE/LOAD
# ==============================================

func get_save_data() -> Dictionary:
	"""Ottiene dati per il salvataggio"""
	var data = {
		"effects": []
	}
	
	for effect in active_effects:
		data.effects.append({
			"name": effect.effect_name,
			"remaining_turns": effect.remaining_turns,
			"stacks": effect.current_stacks
		})
	
	return data

func load_save_data(data: Dictionary, effect_database: Dictionary):
	"""Carica dati dal salvataggio"""
	if not data.has("effects"):
		return
	
	clear_all_status()
	
	for effect_data in data.effects:
		if effect_database.has(effect_data.name):
			var effect_resource = effect_database[effect_data.name]
			var new_effect = effect_resource.duplicate_instance()
			new_effect.initialize(character, effect_data.stacks)
			new_effect.remaining_turns = effect_data.remaining_turns
			active_effects.append(new_effect)
			_apply_stat_modifiers(new_effect)
