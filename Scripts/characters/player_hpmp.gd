extends Label

var stats:StatsResource = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if stats:
		text = "HP: %d / %d\nMP: %d / %d" % [stats.current_hp, stats.max_mp, stats.current_mp, stats.max_mp]
