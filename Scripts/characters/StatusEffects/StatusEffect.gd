class_name StatusEffect
extends Resource

enum EffectType {
	DAMAGE_OVER_TIME,  # Burn, Poison
	STUN,              # Impedisce azione
	STAT_MODIFIER,     # Buff/Debuff stats
	HEALING_OVER_TIME, # Rigenerazione
	IMMUNITY           # Immune a certi status
}

enum TriggerTiming {
	START_OF_TURN,     # Si attiva all'inizio del turno
	END_OF_TURN,       # Si attiva alla fine del turno
	ON_DAMAGE_TAKEN,   # Si attiva quando prendi danno
	ON_DAMAGE_DEALT    # Si attiva quando infliggi danno
}

@export_group("Status Info")
@export var effect_name: String = "Burn"
@export var effect_description: String = "Takes damage each turn"
@export var effect_icon: Texture2D
@export var effect_type: EffectType = EffectType.DAMAGE_OVER_TIME
@export var trigger_timing: TriggerTiming = TriggerTiming.END_OF_TURN

@export_group("Duration")
@export var duration_turns: int = 3
@export var is_permanent: bool = false  # Per buff permanenti

@export_group("Effect Values")
@export var damage_per_turn: int = 0
@export var healing_per_turn: int = 0
@export var is_percentage: bool = false  # Se true, usa % di max_hp
@export var percentage_value: float = 0.0  # Es: 0.05 = 5% max HP

@export_group("Stat Modifiers")
@export var attack_modifier: int = 0
@export var defense_modifier: int = 0
@export var m_attack_modifier: int = 0
@export var m_defense_modifier: int = 0
@export var turn_speed_modifier: int = 0

@export_group("Visual")
@export var particle_effect: PackedScene
@export var tint_color: Color = Color.WHITE
@export var show_floating_text: bool = true

@export_group("Stacking")
@export var can_stack: bool = false
@export var max_stacks: int = 1
@export var stack_refresh_duration: bool = true  # Se true, riapplica resetta durata

# Instance data (non salvato nella risorsa)
var remaining_turns: int = 0
var current_stacks: int = 1
var affected_character: Character = null

func initialize(character: Character, stacks: int = 1):
	"""Inizializza l'effetto su un personaggio"""
	affected_character = character
	remaining_turns = duration_turns
	current_stacks = min(stacks, max_stacks)

func apply_effect() -> Dictionary:
	"""Applica l'effetto e ritorna info sui risultati"""
	var result = {
		"damage": 0,
		"healing": 0,
		"blocked_action": false,
		"message": ""
	}
	
	if not is_instance_valid(affected_character):
		return result
	
	match effect_type:
		EffectType.DAMAGE_OVER_TIME:
			result.damage = _calculate_dot_damage()
			affected_character.stats.current_hp = max(0, affected_character.stats.current_hp - result.damage)
			result.message = "%s takes %d damage from %s!" % [affected_character.stats.character_name, result.damage, effect_name]
			
			# Check morte
			if affected_character.stats.current_hp <= 0:
				affected_character.battleAction.execute_death()
		
		EffectType.HEALING_OVER_TIME:
			result.healing = _calculate_hot_healing()
			affected_character.stats.current_hp = min(affected_character.stats.max_hp, affected_character.stats.current_hp + result.healing)
			result.message = "%s heals %d HP from %s!" % [affected_character.stats.character_name, result.healing, effect_name]
		
		EffectType.STUN:
			result.blocked_action = true
			result.message = "%s is stunned and cannot act!" % affected_character.stats.character_name
	
	return result

func _calculate_dot_damage() -> int:
	"""Calcola danno per damage over time"""
	var damage = damage_per_turn * current_stacks
	
	if is_percentage:
		damage = int(affected_character.stats.max_hp * percentage_value * current_stacks)
	
	return max(1, damage)

func _calculate_hot_healing() -> int:
	"""Calcola cura per healing over time"""
	var healing = healing_per_turn * current_stacks
	
	if is_percentage:
		healing = int(affected_character.stats.max_hp * percentage_value * current_stacks)
	
	return max(1, healing)

func reduce_duration() -> bool:
	"""Riduce la durata e ritorna true se è scaduto"""
	if is_permanent:
		return false
	
	remaining_turns -= 1
	return remaining_turns <= 0

func add_stack():
	"""Aggiunge uno stack se possibile"""
	if can_stack and current_stacks < max_stacks:
		current_stacks += 1
		
		if stack_refresh_duration:
			remaining_turns = duration_turns

func get_stat_modifier(stat_name: String) -> int:
	"""Ottiene il modificatore per una stat specifica"""
	match stat_name:
		"attack": return attack_modifier * current_stacks
		"defense": return defense_modifier * current_stacks
		"m_attack": return m_attack_modifier * current_stacks
		"m_defense": return m_defense_modifier * current_stacks
		"turn_speed": return turn_speed_modifier * current_stacks
		_: return 0

func duplicate_instance() -> StatusEffect:
	"""Crea una copia dell'effetto per una nuova istanza"""
	var new_effect = self.duplicate()
	new_effect.remaining_turns = 0
	new_effect.current_stacks = 1
	new_effect.affected_character = null
	return new_effect
