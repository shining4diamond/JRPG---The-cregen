class_name BattleSkillExecutor
extends Node

var manager: BattleManager

func _init(p_manager: BattleManager):
	manager = p_manager

# Esegue una skill in battaglia
func execute_skill(skill: SkillResource, user: Character, targets: Array[Character]):
	if not is_instance_valid(user):
		push_error("Invalid user!")
		return
	
	user.skillSystem.use_skill(skill,targets)
	
	# Nascondi pulsanti selezione
	manager.show_select_buttons.emit(false)
	manager.show_battle_hud.emit(false)
	
	# Animazione attaccante
	if is_instance_valid(user):
		_play_skill_animation(user, skill)
		await manager.get_tree().create_timer(0.5).timeout
	
	# Applica effetti su tutti i target
	for target in targets:
		if is_instance_valid(target):
			await _apply_skill_effect(skill, user, target)
			await manager.get_tree().create_timer(0.3).timeout
	
	
	manager.battle_hud._update_player_mp(user.stats.current_mp, user.stats.party_member)
	manager.battle_hud._update_player_hp(user.stats.current_hp, user.stats.party_member)

# Applica l'effetto della skill su un target
func _apply_skill_effect(skill: SkillResource, user: Character, target: Character):
	match skill.skill_type:
		SkillResource.SkillType.PHYSICAL_ATTACK, \
		SkillResource.SkillType.MAGICAL_ATTACK:
			await _apply_damage(skill, user, target)
		
		SkillResource.SkillType.HEAL:
			await _apply_healing(skill, user, target)
		
		SkillResource.SkillType.REVIVE:
			await _apply_revive(target)
			await _apply_healing(skill, user, target)
		
		SkillResource.SkillType.BUFF:
			await _apply_buff(skill, target)
		
		SkillResource.SkillType.DEBUFF:
			await _apply_debuff(skill, target)

# Applica danno
func _apply_damage(skill: SkillResource, user: Character, target: Character):
	# Animazione difensore
	target.battleAction.set_condition("takeDamage", true)
	target.state.isBeingAttacked = true
	target.battleAction.start_attack()
	
	# Calcola danno
	var damage = skill.calculate_damage(user.stats, target.stats)
	target.stats.current_hp = max(0, target.stats.current_hp - damage)
	
	# Mostra danno (puoi aggiungere un label floating)
	_show_damage_number(user, target, damage)
	
	# Applica status effect
	if skill.applies_status and skill.status_effect != "":
		var should_apply = randf() < skill.status_chance if skill.status_chance > 0 else true
		if should_apply:
			_apply_status_effect(user, target, skill)
	
	# Update UI
	target.battleAction.emit_signal("update_hpmp_ui", target)
	
	# Check morte
	if target.stats.current_hp <= 0:
		target.battleAction.execute_death()
		manager.remove_ui_from_enemy.emit(target)
		manager.turn_manager.add_battler_to_dead_battlers(target)


# Applica cura
func _apply_healing(skill: SkillResource, user: Character, target: Character):
	var healing = skill.calculate_healing(user.stats)
	target.stats.current_hp = min(target.stats.max_hp, target.stats.current_hp + healing)
	
	# Mostra cura
	_show_healing_number(target, healing)
	
	# Update UI
	target.battleAction.emit_signal("update_hpmp_ui", target)
	
# Applica revive
func _apply_revive(target: Character):
	target.state.isDead = false
	manager.turn_manager.add_dead_battler_to_battlers(target)

# Applica buff (da implementare secondo le tue necessità)
func _apply_buff(skill: SkillResource, target: Character):
	print("Applying buff: %s to %s" % [skill.skill_name, target.name])
	# TODO: Implementa sistema di buff/debuff permanenti

# Applica debuff
func _apply_debuff(skill: SkillResource, target: Character):
	print("Applying debuff: %s to %s" % [skill.skill_name, target.name])
	# TODO: Implementa sistema di buff/debuff permanenti

# Applica status effect
func _apply_status_effect(user: Character, target: Character, skill: SkillResource):
	var effect = skill.status
	if effect:
		var applied = target.apply_status_effect(effect, 1)
		if applied:
			print("%s applied %s to %s for %d turns!" % [user.stats.character_name, effect.effect_name, target.stats.character_name, effect.duration_turns])
			manager.ui._update_status_effect_ui(target)


# Mostra numero danno (placeholder)
func _show_damage_number(executor: Character, target: Character, damage: int):
	print("%s takes %d damage from %s" % [target.stats.character_name, damage, executor.stats.character_name])
	# TODO: Crea label floating per mostrare danno

# Mostra numero cura (placeholder)
func _show_healing_number(target: Character, healing: int):
	print("%s heals %d HP!" % [target.stats.character_name, healing])
	# TODO: Crea label floating per mostrare cura

# Riproduce animazione skill
func _play_skill_animation(character: Character, skill: SkillResource):
	# Mappa animazioni
	match skill.animation_name:
		"melee":
			character.battleAction.set_condition("melee", true)
			character.state.isAttackingMelee = true
		"melee2":
			character.battleAction.set_condition("melee2", true)
			character.state.isAttackingMelee2 = true
		"meleeRun":
			character.battleAction.set_condition("meleeRun", true)
			character.state.isAttackingMeleeRun = true
		_:
			# Animazione default
			character.battleAction.set_condition("melee", true)
			character.state.isAttackingMelee = true
	
	character.battleAction.start_attack()
	
	# Riproduce particle effect se presente
	if skill.particle_effect:
		_spawn_particle_effect(character, skill.particle_effect)
	
	# Riproduce sound effect se presente
	if skill.sound_effect:
		_play_sound_effect(skill.sound_effect)

# Spawna particle effect
func _spawn_particle_effect(character: Character, effect_scene: PackedScene):
	var effect = effect_scene.instantiate()
	character.add_child(effect)
	# Auto-cleanup dopo animazione
	await manager.get_tree().create_timer(2.0).timeout
	if is_instance_valid(effect):
		effect.queue_free()

# Riproduce suono
func _play_sound_effect(sound: AudioStream):
	var player = AudioStreamPlayer.new()
	manager.add_child(player)
	player.stream = sound
	player.play()
	# Auto-cleanup
	await player.finished
	player.queue_free()
