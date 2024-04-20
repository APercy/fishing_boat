--
-- fuel
--
fishing_boat.MAX_FUEL = minetest.settings:get("fishing_boat_max_fuel") or 30
fishing_boat.FUEL_CONSUMPTION = minetest.settings:get("fishing_boat_fuel_consumption") or 6000

function fishing_boat.contains(table, val)
    for k,v in pairs(table) do
        if k == val then
            return v
        end
    end
    return false
end

function fishing_boat.load_fuel(self, player)
    local inv = player:get_inventory()

    local itmstck=player:get_wielded_item()
    local item_name = ""
    if itmstck then item_name = itmstck:get_name() end

    --minetest.chat_send_all("fuel: ".. dump(item_name))
    local fuel = fishing_boat.contains(fishing_boat.fuel, item_name)
    if fuel ~= false then
        local stack = ItemStack(item_name .. " 1")

        if self._energy < fishing_boat.MAX_FUEL then
            inv:remove_item("main", stack)
            self._energy = self._energy + fuel.amount
            if self._energy > fishing_boat.MAX_FUEL then self._energy = fishing_boat.MAX_FUEL end
            --minetest.chat_send_all(self.energy)

            --local energy_indicator_angle = fishing_boat.get_pointer_angle(self._energy, fishing_boat.MAX_FUEL)
        else
            if player then
                local player_name = player:get_player_name()
                minetest.chat_send_player(player_name, "Full tank!")
            end
        end
        
        return true
    end

    return false
end

