extends CanvasLayer

@onready var text : Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	text.text = 'w: '+str(get_parent().get_node('MultiMeshInstance3D').obW)
