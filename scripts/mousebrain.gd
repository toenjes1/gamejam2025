extends Node

const card_prefab = preload("res://prefabs/card.tscn")
var hand
var drop_spots = []

var node_being_dragged: Node = null

func spawn_player_card() -> void:
	var new_card = card_prefab.instantiate()
	new_card.got_dropped.connect(hand.card_got_dropped)
	new_card.got_drop_spotted.connect(hand.remove_card)
	for drop_spot in drop_spots:
		new_card.got_dropped.connect(drop_spot.card_got_dropped)
	get_tree().get_root().get_child(0).add_child(new_card)
	new_card.global_position = Vector2(0,0)
	hand.add_card(new_card)
