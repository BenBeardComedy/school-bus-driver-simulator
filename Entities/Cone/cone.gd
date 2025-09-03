extends RigidBody2D


signal cone_hit


func _on_area_2d_body_entered(body: Node2D) -> void:
	emit_signal("cone_hit")
