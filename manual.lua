--------------
-- Manual --
--------------

function fishing_boat.manual_formspec(name)
    local basic_form = table.concat({
        "formspec_version[3]",
        "size[6,6]"
	}, "")

	basic_form = basic_form.."button[1,1.0;4,1;short;Shortcuts]"
	basic_form = basic_form.."button[1,2.5;4,1;fuel;Refueling]"
	basic_form = basic_form.."button[1,4.0;4,1;share;Sharing]"

    minetest.show_formspec(name, "fishing_boat:manual_main", basic_form)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "fishing_boat:manual_main" then
        local formspec_color = "#44444466"
		if fields.short then
			local text = {
				"Shortcuts \n\n",
                "* Right click: enter in / acess the internal menu \n",
                "* Punch with dye to paint the primary color\n",
                "* Punch a dye, but holding Aux (E) key to change the secondary color.\n",
                "* Forward or backward while in drive position: controls the power lever \n",
                "* Left or right while in drive position: controls the direction \n",
                "* Jump: boat horn \n",
                "* Aux (E) + right click while inside: access inventory \n",
                "* Aux (E) + backward, while in drive position: the machine does backward \n",
                "* Aux (E) + foward, while in drive position: extra power \n"
			}
			local shortcut_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
                "no_prepend[]",
                "bgcolor["..formspec_color..";false]",
				"label[1.0,2.0;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "fishing_boat:manual_shortcut", shortcut_form)
		end
		if fields.fuel then
			local text = {
				"Fuel \n\n",
				"It uses biofuel to get the engine worling. To supply it, \n",
				"be on board and punch the necessary fuel on the ship.\n"
			}
			local fuel_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
                "no_prepend[]",
                "bgcolor["..formspec_color..";false]",
				"label[1.0,2.0;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "fishing_boat:fuel", fuel_form)
		end
		if fields.share then
			local text = {
				"Sharing \n\n",
                "This vehicle was made to be shared with a team. So the owner can set more users to  \n",
                "operate it. Inside the boat, just use the command \""..core.colorize('#ffff00', "/fishing_boat_share <name>").."\" \n",
                "To remove someone from the sharing, \""..core.colorize('#ffff00', "/fishing_boat_remove <name>").."\" \n",
                "To list the owners, \""..core.colorize('#ffff00', "/fishing_boat_list").."\" \n",
                "Is possible to lock the boat access, so only the owners can enter: \""..core.colorize('#ffff00', "/fishing_boat_lock true").."\" \n",
                "To let anyone enter, \""..core.colorize('#ffff00', "/fishing_boat_lock false").."\" \n",
                "All shared owners can access the boat inventory"
			}
			local tips_form = table.concat({
				"formspec_version[3]",
				"size[16,10]",
                "no_prepend[]",
                "bgcolor["..formspec_color..";false]",
				"label[1,2;", table.concat(text, ""), "]",
			}, "")
			minetest.show_formspec(player:get_player_name(), "fishing_boat:share", tips_form)
		end
	end
end)

minetest.register_chatcommand("fishing_boat_manual", {
	params = "",
	description = "Boat manual",
	func = function(name, param)
        fishing_boat.manual_formspec(name)
	end
})
