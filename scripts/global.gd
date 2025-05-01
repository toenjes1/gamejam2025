extends Node

var player_seed = randi()
var enemy_seed = 457

var drop_dict: Dictionary

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
const drop_point_prefab = preload("res://prefabs/drop_spot.tscn")

var numb_card_ids = []
var spec_card_ids = []

var player_bag = ['jok']
var enemy_bag = ['swa', 'jok']

const card_prefab = preload("res://prefabs/card.tscn")
var hand = null
var enemy_hand = null
var drop_spots = []
var enemy_played_cards = []
var menu = null

var chrono_point_max = 12
var chrono_point_current = 12

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

var global_count = 0
# for random stuff

# time stuff
var deck_previewed = []
var moves_previewed = []
var past_states = []

func _ready() -> void:
	for card_id in card_props:
		if card_props[card_id].is_number:
			if card_props[card_id].value > 3:
				numb_card_ids.append(card_id)
		else:
			spec_card_ids.append(card_id)
		if card_props[card_id].has('texture'):
			card_props[card_id].texture = load(card_base_path + card_props[card_id].texture)

func save_state() -> void:
	var spot_contents = []
	for i in range(drop_spots.size()):
		var spot = drop_dict[i]
		var player_cards = []
		var enemy_cards = []
		for card in spot.cards:
			player_cards.append(card.card_id)
		for card in spot.enemy_cards:
			enemy_cards.append(card.card_id)
		spot_contents.append([player_cards, enemy_cards, spot.base_value, spot.is_reversed, spot.global_position])
	var hand_cards = []
	for card in hand.cards:
		hand_cards.append(card.card_id)
	var player_hand = [hand_cards, hand.health]
	var enemy_hand_cards = []
	for card in enemy_hand.cards:
		enemy_hand_cards.append(card.card_id)
	var enemy_hand = [enemy_hand_cards, enemy_hand.health]
	
	past_states.append([spot_contents, player_hand, enemy_hand, game_phase, phase_one_player])
	if past_states.size() > 5:
		past_states.remove_at(0)

func reset_to_state():
	if past_states.is_empty():
		return
	
	clear_slots()
	
	for card in hand.cards:
		hand.cards.erase(card)
		card.queue_free()
	if not hand.cards.is_empty():
		var last_card = hand.cards[0]
		hand.cards.erase(last_card)
		last_card.queue_free()
	for card in enemy_hand.cards:
		enemy_hand.cards.erase(card)
		card.queue_free()
	if not enemy_hand.cards.is_empty():
		var last_card = enemy_hand.cards[0]
		enemy_hand.cards.erase(last_card)
		last_card.queue_free()
	### clearing done hopefully :c
	
	var last_state
	if past_states.size() < 2:
		last_state = past_states[0]
	last_state = past_states[past_states.size() - 2]
	
	for i in range(last_state[0].size()):
		var spot_data = last_state[0][i]
		var target_spot = Global.drop_spots[i]
		for player_card in spot_data[0]:
			var added_card = spawn_card(player_card, true)
			target_spot.cards.append(added_card)
		for enemy_card in spot_data[1]:
			var added_card = spawn_card(enemy_card, true)
			target_spot.enemy_cards.append(added_card)
		target_spot.base_value = spot_data[2]
		target_spot.set_type_display()
		target_spot.recalc_player_sum()
		target_spot.recalc_enemy_sum()
		target_spot.is_reversed = spot_data[3]
	### drop spots resest
	
	while not hand.cards.is_empty():
		hand.cards[hand.cards.size() - 1].queue_free()
		hand.cards.remove_at(hand.cards.size() - 1)
		
	for id in last_state[1][0]:
		print(id)
		var added_card = spawn_player_card_from_id(id)
	hand.update_card_z_values()
	hand.set_health(last_state[1][1])
	### player hand done
	
	while not enemy_hand.cards.is_empty():
		enemy_hand.cards[enemy_hand.cards.size() - 1].queue_free()
		enemy_hand.cards.remove_at(enemy_hand.cards.size() - 1)
	
	for id in last_state[2][0]:
		var added_card = spawn_enemy_card_from_id(id)
	enemy_hand.update_card_z_values()
	enemy_hand.set_health(last_state[2][1])
	### enemy hand resetted
	
	game_phase = last_state[3]
	phase_one_player = last_state[4]
	### maybe done resetting?
	
	past_states.remove_at(past_states.size() - 1)
	

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
	new_card.global_position = Vector2(152,248)
	return new_card

func spawn_cards() -> void:
	spawn_player_card()
	spawn_enemy_card()

func create_bag(seed: int) -> Array:
	var bag = []
	var rng = RandomNumberGenerator.new()
	rng.set_seed(seed+global_count*9)
	global_count += 8
	for i in range(2):
		bag.append(random_spec_card_id(rng))
	for i in range(5):
		bag.append(random_numb_card_id(rng))
	seed(seed)
	bag.shuffle()
	return bag

func spawn_player_card() -> Node:
	if not deck_previewed.is_empty():
		spawn_player_card_from_id(deck_previewed[0])
		deck_previewed.remove_at(0)
	
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

func spawn_player_card_from_id(id) -> Node:
	var new_card = spawn_card(id, true)
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

func spawn_enemy_card_from_id(id) -> Node:
	var new_card = spawn_card(id, false)
	new_card.is_player_card = false
	enemy_hand.add_card(new_card)
	return new_card

func enemy_play(card, spot) -> Node:
	spot.add_enemy_card(card)
	spot.enemy_stack_z_index_update()
	enemy_hand.cards.erase(card)
	print(enemy_hand.cards.size())
	enemy_played_cards.append(card)
	return spot

func card_played(player_card, card_drop) -> void:
	var enemy_play
	var drop_spot
	if game_phase == 0:
		if not moves_previewed.is_empty():
			enemy_play = moves_previewed[0]
			moves_previewed.remove_at(0)
		else:
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
	
	save_state()

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
		clear_slots()
		
		for i in range(5):
			Global.spawn_player_card()
			Global.spawn_enemy_card()
		hand.update_card_z_values()
		enemy_hand.update_card_z_values()
		
		cycle_phase('game')

func clear_slots():
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
