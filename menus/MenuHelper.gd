extends "res://menus/MenuHelper.gd"

func drop_random_items():
	if not DLC.mods_by_id.xy_rle.setting_rle_mod_status:
		return .drop_random_items()
	var resources = SaveState.inventory.get_category("resources")
	var items = []
	for item_node in resources.get_children():
		if item_node.is_discardable():
			var num = randi() % int(max(1, item_node.amount / 10))
			if num > 0:
				num = num * DLC.mods_by_id.xy_rle.setting_rle_modifier_value
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
