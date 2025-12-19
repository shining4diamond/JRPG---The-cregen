class_name CharacterSkillSystem
extends Node

signal skill_used(skill: SkillResource, user: Character, targets: Array)
signal skill_cannot_use(skill: SkillResource, reason: String)

var character: Character
var skill_cooldowns: Dictionary = {}  # skill_name -> turns_remaining

const MAX_EQUIPPED_SKILLS = 8

func _init(p_character: Character):
	character = p_character

# Equipaggia una skill
func equip_skill(skill: SkillResource) -> bool:
	if character.stats.equipped_skills.size() >= MAX_EQUIPPED_SKILLS:
		push_warning("Cannot equip more than %d skills" % MAX_EQUIPPED_SKILLS)
		return false
	
	if character.stats.equipped_skills.has(skill):
		push_warning("Skill already equipped")
		return false
	
	character.stats.equipped_skills.append(skill)
	skill_cooldowns[skill.skill_name] = 0
	return true

# Rimuove una skill
func unequip_skill(skill: SkillResource) -> bool:
	var idx = character.stats.equipped_skills.find(skill)
	if idx == -1:
		return false
	
	character.stats.equipped_skills.remove_at(idx)
	skill_cooldowns.erase(skill.skill_name)
	return true

# Usa una skill
func use_skill(skill: SkillResource, targets: Array[Character]) -> bool:
	# Verifica se la skill è equipaggiata
	if not character.stats.equipped_skills.has(skill):
		skill_cannot_use.emit(skill, "Skill not equipped")
		return false
	
	# Verifica cooldown
	var cooldown = skill_cooldowns.get(skill.skill_name, 0)
	if not skill.can_use(character.stats, cooldown):
		var reason = ""
		if cooldown > 0:
			reason = "Cooldown: %d turns" % cooldown
		elif character.stats.current_mp < skill.mp_cost:
			reason = "Not enough MP"
		elif character.stats.current_hp <= skill.hp_cost:
			reason = "Not enough HP"
		
		skill_cannot_use.emit(skill, reason)
		return false
	
	# Verifica target
	if not _validate_targets(skill, targets):
		skill_cannot_use.emit(skill, "Invalid targets")
		return false
	
	# Applica costi
	skill.apply_costs(character.stats)
	
	# Imposta cooldown
	if skill.cooldown_turns > 0:
		skill_cooldowns[skill.skill_name] = skill.cooldown_turns
	
	# Emetti segnale
	skill_used.emit(skill, character, targets)
	
	return true

# Riduce i cooldown (chiamare a fine turno)
func reduce_cooldowns():
	for skill_name in skill_cooldowns.keys():
		if skill_cooldowns[skill_name] > 0:
			skill_cooldowns[skill_name] -= 1

# Valida i target
func _validate_targets(skill: SkillResource, targets: Array[Character]) -> bool:
	if targets.is_empty():
		return false
	
	match skill.target_type:
		SkillResource.TargetType.SINGLE_ENEMY, \
		SkillResource.TargetType.SINGLE_ALLY, \
		SkillResource.TargetType.SELF:
			return targets.size() == 1
		SkillResource.TargetType.ALL_ENEMIES, \
		SkillResource.TargetType.ALL_ALLIES:
			return targets.size() >= 1
	
	return false

# Ottiene tutte le skill usabili
func get_usable_skills() -> Array[SkillResource]:
	var usable: Array[SkillResource] = []
	for skill in character.stats.equipped_skills:
		var cooldown = skill_cooldowns.get(skill.skill_name, 0)
		if skill.can_use(character.stats, cooldown):
			usable.append(skill)
	return usable

# Ottiene info cooldown
func get_cooldown(skill: SkillResource) -> int:
	return skill_cooldowns.get(skill.skill_name, 0)

# Resetta tutti i cooldown (es: dopo combattimento)
func reset_all_cooldowns():
	for skill_name in skill_cooldowns.keys():
		skill_cooldowns[skill_name] = 0
