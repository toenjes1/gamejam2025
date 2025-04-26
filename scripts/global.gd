extends Node

var player_rng = RandomNumberGenerator.new()
var enemy_rng = RandomNumberGenerator.new()

const card_base_path = 'res://assets/images/cards/'

var card_props = {
	'1': {'name': "One", 'is_number': true, 'value': 1},
	'2': {'name': "Two", 'is_number': true, 'value': 2},
	'3': {'name': "Three", 'is_number': true, 'value': 3},
	'4': {'name': "Four", 'is_number': true, 'value': 4, 'texture': '4_card.png'},
	'5': {'name': "Five", 'is_number': true, 'value': 5, 'texture': '5_card.png'},
	'6': {'name': "Six", 'is_number': true, 'value': 6, 'texture': '6_card.png'},
	'7': {'name': "Seven", 'is_number': true, 'value': 7, 'texture': '7_card.png'},
	'8': {'name': "Eight", 'is_number': true, 'value': 8, 'texture': '8_card.png'},
	'9': {'name': "Nine", 'is_number': true, 'value': 9, 'texture': '9_card.png'},
	'jok': {'name': "Joker", 'is_number': false, 'texture': 'joker_card.png'},
	'blo': {'name': "Block", 'is_number': false},
	'rig': {'name': "Right", 'is_number': false},
	'lef': {'name': "Left", 'is_number': false},
	'mov': {'name': "Move", 'is_number': false},
	'rev': {'name': "Reverse", 'is_number': false},
	'nul': {'name': "Nullify", 'is_number': false},
	'gen': {'name': "Genesis", 'is_number': false},
	'hal': {'name': "Half", 'is_number': false},
}

var numb_card_ids = []
var spec_card_ids = []

const card_prefab = preload("res://prefabs/card.tscn")
var hand
var enemy_hand
var drop_spots = []

var node_being_dragged: Node = null

func _ready() -> void:
	for card_id in card_props:
		if card_props[card_id].is_number:
			if card_props[card_id].value > 3:
				numb_card_ids.append(card_id)
		else:
			spec_card_ids.append(card_id)
		if card_props[card_id].has('texture'):
			card_props[card_id].texture = load(card_base_path + card_props[card_id].texture)

func random_numb_card_id(rng: RandomNumberGenerator) -> String:
	return numb_card_ids[rng.randi_range(0, numb_card_ids.size() - 1)]

func spawn_card(card_id: String, show_front: bool = false) -> Node:
	var new_card = card_prefab.instantiate()
	new_card.set_card_id(card_id)
	new_card.show_front = show_front
	if card_props[card_id].has('texture'):
		new_card.set_sprite_texture(card_props[card_id].texture)
	get_tree().get_root().get_child(0).add_child(new_card)
	new_card.global_position = Vector2(0,0)
	return new_card

func spawn_cards() -> void:
	spawn_player_card()
	spawn_enemy_card()

func spawn_player_card() -> void:
	var new_card = spawn_card(random_numb_card_id(player_rng), true)
	new_card.got_dropped.connect(hand.card_got_dropped)
	new_card.got_drop_spotted.connect(hand.remove_card)
	for drop_spot in drop_spots:
		new_card.got_dropped.connect(drop_spot.card_got_dropped)
	hand.add_card(new_card)

func spawn_enemy_card() -> void:
	var new_card = spawn_card(random_numb_card_id(player_rng), false)
	enemy_hand.add_card(new_card)
