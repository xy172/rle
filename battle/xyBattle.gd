extends "res://battle/Battle.gd"

var scenes:Dictionary

func setup():
	scenes.DroppedMenu = load("res://menus/loot/DroppedMenu.tscn")

func end(winning_team):
	battle_ending = true
	
	var trigger = 0
	if winning_team == null:
		trigger = 4
	elif winning_team == 0:
		trigger = 1
	else :
		trigger = 2
	
	exp_yield = exp_multiplier.to_int(exp_yield)
	if suppress_exp:
		exp_yield = 0
	
	if net_closed_reason == 1:
		camera_set_state("dialog", [])
		yield (show_message("BATTLE_NET_CLOSED_1", true), "completed")
	
	elif net_closed_reason == 2:
		camera_set_state("dialog", [])
		if net_closed_by_remote:
			yield (show_message("BATTLE_NET_CLOSED_2_REMOTE", true), "completed")
		else :
			yield (show_message("BATTLE_NET_CLOSED_2_LOCAL", true), "completed")
	
	elif winning_team == null and not is_net_game:
		assert ( not is_net_game)
		camera_set_state("flee", [])
		yield (show_message("BATTLE_FLED", true), "completed")
		if fast_travel_flee:
			if not DLC.mods_by_id.xy_nolosses.setting_nolosses_mod_status:
				yield (MenuHelper.drop_random_items(), "completed")
			else:
				yield (xy_drop_random_items(),'completed')
	
	elif winning_team == 0:
		camera_set_state("win", [])
		music.track = victory_music
		
		var victory_splash = preload("res://battle/ui/VictorySplash.tscn").instance()
		canvas_layer.add_child(victory_splash)
		yield (victory_splash, "closed")
		canvas_layer.remove_child(victory_splash)
		victory_splash.queue_free()
		
		get_fusion_meter().won_battle()
		
		for tape in deferred_recordings:
			yield (MenuHelper.give_tape(tape, false, self), "completed")
		
		if exp_yield != 0:
			var loot_rand = Random.new(loot_rand_seed)
			var loot_table = preload("res://data/loot_tables/battle_misc.tres")
			if loot_table_override != null:
				loot_table = loot_table_override
			elif loot_tables.size() > 0:
				loot_table = loot_rand.choice(loot_tables)
			yield (MenuHelper.show_exp_screen(self, exp_yield, loot_table, loot_rand, extra_loot + participation_loot), "completed")
		elif extra_loot.size() + participation_loot.size() != 0:
			yield (MenuHelper.give_items(extra_loot + participation_loot), "completed")
	else :
		camera_set_state("lose", [])
		yield (show_message("BATTLE_LOST", true), "completed")
		if not is_net_game:
			if  not DLC.mods_by_id.xy_nolosses.setting_nolosses_mod_status:
				yield (MenuHelper.drop_random_items(), "completed")
		elif winning_team != null and participation_loot.size() != 0:
			yield (MenuHelper.give_items(participation_loot), "completed")
		else:
			yield (xy_drop_random_items(),'completed')
	music.track = null
	
	var stat_key = "fled"
	if winning_team == 0:
		stat_key = "player"
	elif winning_team != null:
		stat_key = "enemy"
	if is_net_game:
		SaveState.stats.get_stat("net_battle_finished").report_event(stat_key)
	else :
		SaveState.stats.get_stat("battle_finished").report_event(stat_key)
	
	if winning_team == 0:
		var status_tags = {}
		for fighter in get_teams(false, false)[0]:
			for tag in fighter.status.get_tags():
				status_tags[tag] = true
		for key in status_tags.keys():
			SaveState.stats.get_stat("status_wins").report_event(key)
		
	for child in get_children():
		if child is BattleEndCutscene and (child.triggers & trigger) != 0:
			var result = child.run()
			if result is GDScriptFunctionState:
				result = yield (result, "completed")
	
	if SaveState.party.HEAL_TAPES_AFTER_BATTLE:
		for tape in SaveState.party.get_tapes():
			if not tape.is_broken():
				tape.hp.set_to(1, 1)
	
	var net = get_net_request()
	if net:
		net.battle_finished(winning_team)

	if not is_net_game and fast_travel_flee:
		SceneManager.clear_stack()
		WorldSystem.default_warp(true)
	elif not is_net_game and winning_team != 0 and winning_team != null and game_over_on_lose:
		SceneManager.clear_stack()
		WorldSystem.game_over()
	else :
		if winning_team_override != null:
			winning_team = winning_team_override
		if winning_team == 0 and stamina_increase_on_win > 0.0:
			if not SceneManager.transitioned_out:
				yield (SceneManager.transition_out(), "completed")
			yield (increase_stamina(), "completed")
		SceneManager.pop_scene(winning_team)

func xy_drop_random_items():
	var resources = SaveState.inventory.get_category("resources")
	var items = []
	for item_node in resources.get_children():
		if item_node.is_discardable():
			var num = randi() % int(max(1, item_node.amount / 10))
			if DLC.mods_by_id.xy_rle.setting_rle_mod_status:
				num = num * DLC.mods_by_id.xy_rle.setting_rle_modifier_value
			if num > 0:
				var rec = LootRecord.new()
				rec.item = item_node.item
				rec.amount = num
				rec.dropped = true
				items.push_back(rec)
				item_node.consume(num)
	
	if items.size() == 0:
		return Co.pass()
	
	WorldSystem.push_flags(0)
	
	var menu = scenes.DroppedMenu.instance()
	menu.items = items
	add_child(menu)
	yield (menu.run_menu(), "completed")
	menu.queue_free()
	
	WorldSystem.pop_flags()
