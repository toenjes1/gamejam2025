extends Node

var player_seed = 69
var enemy_seed = 457

const card_base_path = 'res://assets/images/cards/'

var card_props = {
	'0': {'name': "Zero", 'is_number': true, 'value': 0, 'texture': '0_card.png', 'description': "I'm really sorry for you... This must be hard."},
	'1': {'name': "One", 'is_number': true, 'value': 1, 'texture': '1_card.png', 'description': "How did you get hear?!"},
	'2': {'name': "Two", 'is_number': true, 'value': 2, 'texture': '2_card.png', 'description': "This hasn't a lot of value, now, has it?"},
	'3': {'name': "Three", 'is_number': true, 'value': 3, 'texture': '3_card.png', 'description': "Trinity."},
	'4': {'name': "Four", 'is_number': true, 'value': 4, 'texture': '4_card.png', 'description': "Möm."},
	'5': {'name': "Five", 'is_number': true, 'value': 5, 'texture': '5_card.png', 'description': "Yay, primes!"},
	'6': {'name': "Six", 'is_number': true, 'value': 6, 'texture': '6_card.png', 'description': "Why is 6 afraid of 7?"},
	'7': {'name': "Seven", 'is_number': true, 'value': 7, 'texture': '7_card.png', 'description': "Because 7 8 9."},
	'8': {'name': "Eight", 'is_number': true, 'value': 8, 'texture': '8_card.png', 'description': "Infinity's idiotic cousin."},
	'9': {'name': "Nine", 'is_number': true, 'value': 9, 'texture': '9_card.png', 'description': "Trinity squared."},
	'jok': {'name': "Joker", 'is_number': false, 'texture': 'joker_card.png', 'description': "Can be played on top of another number and counts as it."},
	'blo': {'name': "Block", 'is_number': false, 'texture': 'block_card.png', 'description': "Once played, no one can play on this lane anymore."},
	'rig': {'name': "Right", 'is_number': false, 'texture': 'right_union_card.png', 'description': "Push your stack on top of the one to its right."},
	'lef': {'name': "Left", 'is_number': false, 'texture': 'left_union_card.png', 'description': "Push your stack on top of the one to its left."},
	'swa': {'name': "Swap", 'is_number': false, 'texture': 'swap_card.png', 'description': "Swap this stack with another one that has the lowest sum."},
	'rev': {'name': "Reverse", 'is_number': false, 'texture': 'reverse_card.png', 'description': "The objective is now switched! Get the lowest points?"},
	'nul': {'name': "Nullify", 'is_number': false, 'texture': 'empty_card.png', 'description': "Nullify all numbered cards in the lane."},
	'gen': {'name': "Genesis", 'is_number': false, 'texture': 'genesis_card.png', 'description': "Delete EVERYTHING in this lane. Draw each a card to put here."},
	'hal': {'name': "Half", 'is_number': false, 'texture': 'half_card.png', 'description': "Half the value of all numbered cards."},
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
var enemy_played_cards = []
var menu = null

var game_phase = 0
# 0 := normales Kartenlegen beidseitig
# 1 := einer hat gepasst, anderer darf eine Karte legen
# 2 := Runde vorbei, Vergleich wird durchgeführt
var phase_one_player
# 0 := player
# 1 := enemy

var node_being_dragged: Node = null
var node_being_dragged_is_player: int = -1
# -1 := no card being dragged
# 0 := enemy card being dragged
# 1 := player card being dragged

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

func get_card_val(card) -> int:
	var card_id = card.card_id
	if card_props[card_id].is_number:
		return card_props[card_id].value
	return -1

func is_card_num(card) -> bool:
	return card_props[card.card_id].is_number

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

func spawn_player_card() -> Node:
	if player_bag.is_empty():
		player_bag = create_bag(player_seed)
	var new_card = spawn_card(player_bag[0], true)
	player_bag.remove_at(0)
	new_card.is_player_card = true
	new_card.got_dropped.connect(hand.card_got_dropped)
	new_card.got_drop_spotted.connect(hand.remove_card)
	for drop_spot in drop_spots:
		new_card.got_dropped.connect(drop_spot.card_got_dropped)
	hand.add_card(new_card)
	return new_card

func spawn_enemy_card() -> Node:
	if enemy_bag.is_empty():
		enemy_bag = create_bag(enemy_seed)
	var new_card = spawn_card(enemy_bag[0], false)
	enemy_bag.remove_at(0)
	new_card.is_player_card = false
	enemy_hand.add_card(new_card)
	return new_card

func enemy_play(card, spot) -> Node:
	spot.add_enemy_card(card)
	spot.enemy_stack_z_index_update()
	enemy_hand.cards.erase(card)
	enemy_played_cards.append(card)
	return spot

func card_played(player_card, card_drop) -> void:
	var enemy_play
	var drop_spot
	if game_phase == 0:
		enemy_play = enemy_hand.choose_move(drop_spots, hand.cards)
		if enemy_play[0] == null and enemy_play[1] == null:
			cycle_phase('enemy')
		else:
			drop_spot = enemy_play(enemy_play[0], enemy_play[1])
			enemy_play[0].is_drop_spotted = true
	
	await get_tree().create_timer(1).timeout
	
	player_card.turn_to_front()
	var blockage = card_drop.activate_trap_card(player_card, 'player')
	enemy_played_cards[enemy_played_cards.size() - 1].turn_to_front()
	if not blockage:
		player_card.dropped_location.calculate_sum(player_card.card_id)
		player_card.dropped_location.set_type_display()
	
	if game_phase == 0 and not blockage:
		drop_spot.calculate_enemy_sum(enemy_play[0].card_id)
		drop_spot.activate_trap_card(enemy_play[0], 'enemy')
	
	if game_phase == 1:
		cycle_phase('player')

func menu_open(text):
	menu.set_text(text)
	menu.is_open = true
	menu.anim_player.play("fade_in")
	menu.visible = true

func cycle_phase(caller) -> void:
	game_phase = (game_phase + 1) % 3
	
	if game_phase == 1 and caller == 'player':
		phase_one_player = 1
	elif game_phase == 1 and caller != 'player':
		phase_one_player = 0
	if game_phase == 1 and phase_one_player == 1:
		var enemy_play = enemy_hand.choose_move(drop_spots, hand.cards)
		if not (enemy_play[0] == null and enemy_play[1] == null):
			var drop_spot = enemy_play(enemy_play[0], enemy_play[1])
			enemy_play[0].is_drop_spotted = true
			await get_tree().create_timer(1).timeout
			enemy_played_cards[enemy_played_cards.size() - 1].turn_to_front()
			drop_spot.calculate_enemy_sum(enemy_play[0].card_id)
			drop_spot.activate_trap_card(enemy_play[0], 'enemy')
		cycle_phase('enemy')
		return
	
	if game_phase == 2:
		await get_tree().create_timer(1).timeout
		var dmgs = await accumulate_damages()
		if hand.health == 0 and enemy_hand.health == 0:
			if dmgs[0] < dmgs[1]:
				menu_open("You win")
			else:
				menu_open("You lose")
			return
		if hand.health == 0:
			menu_open("You lose")
			return
		if enemy_hand.health == 0:
			menu_open("You win")
			return
		await get_tree().create_timer(0.5).timeout
		for spot in drop_spots:
			for card in spot.cards:
				spot.cards.erase(card)
				card.queue_free()
			if not spot.cards.is_empty():
				var last_card = spot.cards[0]
				spot.cards.erase(last_card)
				last_card.queue_free()
			
			for card in spot.enemy_cards:
				spot.enemy_cards.erase(card)
				card.queue_free()
			if not spot.enemy_cards.is_empty():
				var last_card = spot.enemy_cards[0]
				spot.enemy_cards.erase(last_card)
				last_card.queue_free()
			
			spot.player_cards_sum = 0
			spot.set_sum_display('0')
			spot.enemy_cards_sum = 0
			spot.set_enemy_sum_display('0')
			spot.base_value = 0
			spot.set_type_display()
			spot.is_reversed = false
		
		for i in range(5):
			Global.spawn_player_card()
			Global.spawn_enemy_card()
		hand.update_card_z_values()
		enemy_hand.update_card_z_values()
		
		cycle_phase('game')

func accumulate_damages():
	var dmgPlayer = 0
	var dmgEnemy = 0
	for drop_spot in drop_spots:
		if not drop_spot.is_reversed:
			if drop_spot.player_cards_sum > drop_spot.enemy_cards_sum:
				dmgEnemy += (drop_spot.player_cards_sum - drop_spot.enemy_cards_sum)
			else:
				dmgPlayer += (drop_spot.enemy_cards_sum - drop_spot.player_cards_sum)
		else:
			if drop_spot.player_cards_sum < drop_spot.enemy_cards_sum:
				dmgEnemy += (drop_spot.enemy_cards_sum - drop_spot.player_cards_sum)
			else:
				dmgPlayer += (drop_spot.player_cards_sum -  drop_spot.enemy_cards_sum)
	
	await enemy_hand.damage_enemy(dmgEnemy)
	await get_tree().create_timer(0.3).timeout
	await hand.damage_player(dmgPlayer)
	
	return [dmgPlayer, dmgEnemy]
