extends CanvasLayer

@onready var player_panels = {
	1: {
		"panel": $HPMP_Container/GridContainer/Player_Character_1/HPMP_Player1,
		"spacer": $HPMP_Container/GridContainer/Player_Character_1/Spacer_Player1
	},
	2: {
		"panel": $HPMP_Container/GridContainer/Player_Character_2/HPMP_Player2,
		"spacer": $HPMP_Container/GridContainer/Player_Character_2/Spacer_Player2
	},
	3: {
		"panel": $HPMP_Container/GridContainer/Player_Character_3/HPMP_Player3,
		"spacer": $HPMP_Container/GridContainer/Player_Character_3/Spacer_Player3
	}
}



func connect_signals():
	var players = ["Player1", "Player2", "Player3"]
	
	for player_name in players:
		var player = get_parent().get_node_or_null(player_name)
		var battleManager = get_parent()
		if player:
			var battle_action = player.battleAction
			if battle_action.has_signal("update_hpmp_ui"):
				battle_action.update_hpmp_ui.connect(_update_hp_ui)
				print("✅ battle_action Connesso: ", player_name)
			else:
				print("❌ battle_action Segnale mancante su: ", player_name)
			
			if battleManager.has_signal("toggle_focus_on_player"):
				battleManager.toggle_focus_on_player.connect(_toggle_focus_on_hpmp_player)
				print("✅ toggle_focus_on_player Connesso: ", player_name)
			else:
				print("❌ toggle_focus_on_player Segnale mancante su: ", player_name)

		else:
			print("⚠️ Player non trovato: ", player_name)
			



# Inizializza tutto
func initialize_player_ui(stats: StatsResource, party_member: int):
	if not player_panels.has(party_member):
		push_error("Party member non valido: " + str(party_member))
		return
	
	var panel_data = player_panels[party_member]
	var panel = panel_data.panel
	var spacer = panel_data.spacer
	
	# Nascondi spacer
	spacer.visible = true
	
	# Setup HP
	var hp_bar = panel.get_node("%HP_ProgressBar")
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.current_hp
	hp_bar.get_node("Current_HP_Label").text = "%d" % [stats.current_hp]
	
	_update_hp_bar_color(hp_bar, stats.current_hp)
	
	# Setup MP
	var mp_bar = panel.get_node("%MP_ProgressBar")
	mp_bar.max_value = stats.max_mp
	mp_bar.value = stats.current_mp
	mp_bar.get_node("Current_MP_Label").text = "%d" % [stats.current_mp]
	
	print("✅ UI inizializzata per party member %d" % [party_member])

# Update HP
func _update_hp_ui(current_hp: int, party_member: int):
	if not player_panels.has(party_member):
		return
	
	var panel = player_panels[party_member].panel
	var hp_bar = panel.get_node("%HP_ProgressBar")
	
	hp_bar.value = current_hp
	hp_bar.get_node("Current_HP_Label").text = "%d" % [current_hp]
	
	_update_hp_bar_color(hp_bar, current_hp)

func _update_hp_bar_color(hp_bar: ProgressBar, current_hp: int):
	# Color coding
	var hp_percent = float(current_hp) / hp_bar.max_value
	hp_bar["theme_override_styles/fill"] = hp_bar["theme_override_styles/fill"].duplicate()
	if hp_percent <= 0.25:
		hp_bar["theme_override_styles/fill"].bg_color = Color.RED
	elif hp_percent <= 0.5:
		hp_bar["theme_override_styles/fill"].bg_color = Color.YELLOW
	else:
		hp_bar["theme_override_styles/fill"].bg_color = Color.WEB_GREEN

func _toggle_focus_on_hpmp_player(party_member: int):
	print("_toggle_focus_on_hpmp_player called")
	if not player_panels.has(party_member):
		push_error("Party member non valido: " + str(party_member))
		return
	
	var panel_data = player_panels[party_member]
	var spacer = panel_data.spacer
	
	# Toggle show spacer spacer
	if(spacer.visible):
		spacer.hide()
	else:
		spacer.show()
