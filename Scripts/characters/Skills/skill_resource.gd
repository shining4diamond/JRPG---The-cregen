class_name SkillResource
extends Resource

enum SkillType {
	PHYSICAL_ATTACK,
	MAGICAL_ATTACK,
	HEAL,
	BUFF,
	DEBUFF,
	SPECIAL,
	REVIVE
}

enum TargetType {
	SINGLE_ENEMY,
	ALL_ENEMIES,
	SINGLE_ALLY,
	ALL_ALLIES,
	SELF
}

@export_group("Skill Info")
@export var skill_name: String = "Attack"
@export var skill_description: String = ""
@export var skill_icon: Texture2D
@export var skill_type: SkillType = SkillType.PHYSICAL_ATTACK
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

@export_group("Costs")
@export var mp_cost: int = 0
@export var hp_cost: int = 0
@export var cooldown_turns: int = 0

@export_group("DamageHealing")
@export var base_power: int = 0
@export var power_scaling: float = 1.0  # Moltiplicatore per attack/m_attack
@export var can_crit: bool = true
@export var crit_chance: float = 0.1
@export var crit_multiplier: float = 1.5

@export_group("Effects")
@export var applies_status: bool = false
@export var status: StatusEffect
@export var status_effect: String = ""  # es: "poison", "stun", "burn"
@export var status_duration: int = 0
@export var status_chance: float = 0.0

@export_group("Animation")
@export var animation_name: String = "melee"  # melee, melee2, meleeRun, etc
@export var particle_effect: PackedScene
@export var sound_effect: AudioStream

# Funzione per calcolare il danno
func calculate_damage(attacker_stats: StatsResource, defender_stats: StatsResource) -> int:
	var base_stat: int
	var defense: int
	
	match skill_type:
		SkillType.PHYSICAL_ATTACK:
			base_stat = attacker_stats.attack
			defense = defender_stats.defense
		SkillType.MAGICAL_ATTACK:
			base_stat = attacker_stats.m_attack
			defense = defender_stats.m_defense
		_:
			return 0
	
	var damage = (base_power + (base_stat * power_scaling)) - defense
	
	# Critico
	if can_crit and randf() < crit_chance:
		damage = int(damage * crit_multiplier)
	
	return max(1, int(damage))  # Minimo 1 danno

# Funzione per calcolare la cura
func calculate_healing(caster_stats: StatsResource) -> int:
	if skill_type != SkillType.HEAL and skill_type != SkillType.REVIVE:
		return 0
	
	var healing = base_power + (caster_stats.m_attack * power_scaling)
	return max(1, int(healing))

# Verifica se la skill può essere usata
func can_use(user_stats: StatsResource, current_cooldown: int = 0) -> bool:
	if current_cooldown > 0:
		return false
	
	if user_stats.current_mp < mp_cost:
		return false
	
	if user_stats.current_hp <= hp_cost:
		return false
	
	return true

# Applica i costi
func apply_costs(user_stats: StatsResource):
	user_stats.current_mp = max(0, user_stats.current_mp - mp_cost)
	user_stats.current_hp = max(1, user_stats.current_hp - hp_cost)
