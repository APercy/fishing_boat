fishing_boat.hud_list = {}

function fishing_boat.get_pointer_angle(value, maxvalue)
    local angle = value/maxvalue * 180
    --angle = angle - 90
    --angle = angle * -1
    return angle
end

function fishing_boat.animate_gauge(player, ids, prefix, x, y, angle)
    local angle_in_rad = math.rad(angle + 180)
    local dim = 10
    local pos_x = math.sin(angle_in_rad) * dim
    local pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "2"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 20
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "3"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 30
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "4"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 40
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "5"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 50
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "6"], "offset", {x = pos_x + x, y = pos_y + y})
    dim = 60
    pos_x = math.sin(angle_in_rad) * dim
    pos_y = math.cos(angle_in_rad) * dim
    player:hud_change(ids[prefix .. "7"], "offset", {x = pos_x + x, y = pos_y + y})
end

function fishing_boat.update_hud(self, player)
    if player == nil then return end
    local player_name = player:get_player_name()

    local screen_pos_y = -100
    local screen_pos_x = 10

    local power_gauge_x = screen_pos_x + 374
    local power_gauge_y = screen_pos_y
    local fuel_gauge_x = screen_pos_x + 266
    local fuel_gauge_y = power_gauge_y
    local throttle_x = screen_pos_x + 395
    local throttle_y = screen_pos_y + 45

    local ids = fishing_boat.hud_list[player_name]
    if ids then
        player:hud_change(ids["throttle"], "offset", {x = throttle_x, y = throttle_y - self._power_lever})

        local power  = fishing_boat.get_pointer_angle(self._energy, 100 )
        local fuel = fishing_boat.get_pointer_angle(self._energy, fishing_boat.MAX_FUEL )


        fishing_boat.animate_gauge(player, ids, "power_pt_", power_gauge_x, power_gauge_y, 150-(self._power_lever*1.5))
        fishing_boat.animate_gauge(player, ids, "fuel_pt_", fuel_gauge_x, fuel_gauge_y, 180-fuel)
    else
        ids = {}

        ids["title"] = player:hud_add({
            hud_elem_type = "text",
            position  = {x = 0, y = 1},
            offset    = {x = screen_pos_x + 240, y = screen_pos_y - 100},
            text      = "Boat engine state",
            alignment = 0,
            scale     = { x = 100, y = 30},
            number    = 0xFFFFFF,
        })

        ids["bg"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = screen_pos_x, y = screen_pos_y},
            text      = "fishing_boat_hud_panel.png",
            scale     = { x = 0.5, y = 0.5},
            alignment = { x = 1, y = 0 },
        })

        ids["throttle"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = throttle_x, y = throttle_y},
            text      = "fishing_boat_throttle.png",
            scale     = { x = 0.5, y = 0.5},
            alignment = { x = 1, y = 0 },
        })

        ids["power_pt_1"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })

        ids["power_pt_2"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["power_pt_3"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["power_pt_4"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["power_pt_5"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["power_pt_6"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["power_pt_7"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = power_gauge_x, y = power_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })

        ids["fuel_pt_1"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["fuel_pt_2"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["fuel_pt_3"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["fuel_pt_4"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["fuel_pt_5"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["fuel_pt_6"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })
        ids["fuel_pt_7"] = player:hud_add({
            hud_elem_type = "image",
            position  = {x = 0, y = 1},
            offset    = {x = fuel_gauge_x, y = fuel_gauge_y},
            text      = "fishing_boat_ind_box.png",
            scale     = { x = 6, y = 6},
            alignment = { x = 1, y = 0 },
        })

        fishing_boat.hud_list[player_name] = ids
    end
end


function fishing_boat.remove_hud(player)
    if player then
        local player_name = player:get_player_name()
        --minetest.chat_send_all(player_name)
        local ids = fishing_boat.hud_list[player_name]
        if ids then
            --player:hud_remove(ids["altitude"])
            --player:hud_remove(ids["time"])
            player:hud_remove(ids["title"])
            player:hud_remove(ids["bg"])
            player:hud_remove(ids["throttle"])
            player:hud_remove(ids["power_pt_7"])
            player:hud_remove(ids["power_pt_6"])
            player:hud_remove(ids["power_pt_5"])
            player:hud_remove(ids["power_pt_4"])
            player:hud_remove(ids["power_pt_3"])
            player:hud_remove(ids["power_pt_2"])
            player:hud_remove(ids["power_pt_1"])
            player:hud_remove(ids["fuel_pt_7"])
            player:hud_remove(ids["fuel_pt_6"])
            player:hud_remove(ids["fuel_pt_5"])
            player:hud_remove(ids["fuel_pt_4"])
            player:hud_remove(ids["fuel_pt_3"])
            player:hud_remove(ids["fuel_pt_2"])
            player:hud_remove(ids["fuel_pt_1"])
        end
        fishing_boat.hud_list[player_name] = nil
    end

end
