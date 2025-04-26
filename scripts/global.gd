extends Node

var player_seed = 69
var enemy_seed = 456

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

const no_card_texture = preload(card_base_path + "no_card.png")

var numb_card_ids = []
var spec_card_ids = []

var player_bag = []
var enemy_bag = []

const card_prefab = preload("res://prefabs/card.tscn")
var hand = null
var enemy_hand = null
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

func switch_to_scene(scene_name: String) -> void:
	if scene_name != "world":
		hand.empty_card_refs()
		enemy_hand.empty_card_refs()
		for drop_spot in drop_spots:
			drop_spot.empty_card_refs()
		hand = null
		enemy_hand = null
		drop_spots = []
	get_tree().change_scene_to_file("res://scenes/" + scene_name + ".tscn")

func end_game() -> void:
	get_tree().quit()

func random_numb_card_id(rng: RandomNumberGenerator) -> String:
	return numb_card_ids[rng.randi_range(0, numb_card_ids.size() - 1)]

func random_spec_card_id(rng: RandomNumberGenerator) -> String:
	return spec_card_ids[rng.randi_range(0, spec_card_ids.size() - 1)]

func spawn_card(card_id: String, show_front: bool = false) -> Node:
	var new_card = card_prefab.instantiate()
	new_card.set_card_id(card_id)
	new_card.show_front = show_front
	if card_props[card_id].has('texture'):
		new_card.set_sprite_texture(card_props[card_id].texture)
	else:
		new_card.set_sprite_texture(no_card_texture)
	get_tree().get_root().get_child(0).add_child(new_card)
	new_card.global_position = Vector2(0,0)
	return new_card

func spawn_cards() -> void:
	spawn_player_card()
	spawn_enemy_card()

func create_bag(seed: int) -> Array:
	var bag = []
	var rng = RandomNumberGenerator.new()
	rng.set_seed(seed)
	for i in range(2):
		bag.append(random_spec_card_id(rng))
	for i in range(5):
		bag.append(random_numb_card_id(rng))
	seed(seed)
	bag.shuffle()
	return bag

func spawn_player_card() -> void:
	if player_bag.is_empty():
		player_bag = create_bag(player_seed)
	var new_card = spawn_card(player_bag[0], true)
	player_bag.remove_at(0)
	new_card.got_dropped.connect(hand.card_got_dropped)
	new_card.got_drop_spotted.connect(hand.remove_card)
	for drop_spot in drop_spots:
		new_card.got_dropped.connect(drop_spot.card_got_dropped)
	hand.add_card(new_card)

func spawn_enemy_card() -> void:
	if enemy_bag.is_empty():
		enemy_bag = create_bag(enemy_seed)
	var new_card = spawn_card(enemy_bag[0], true)
	enemy_bag.remove_at(0)
	enemy_hand.add_card(new_card)
