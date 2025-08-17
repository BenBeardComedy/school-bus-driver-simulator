extends Camera2D


@export var target:Node2D

@onready var rotation_offset:float = deg_to_rad(90)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if target:
		self.transform = target.transform
		self.position = target.get_target_marker()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target:
		self.rotation = target.rotation + rotation_offset
		var target_marker_position = target.get_target_marker()
		self.position = lerp(self.position, target_marker_position, 0.1)
