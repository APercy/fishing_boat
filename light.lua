function fishing_boat.remove_light(self)
    if self._light_old_pos then
        --force the remotion of the last light
        minetest.add_node(self._light_old_pos, {name="air"})
        self._light_old_pos = nil
    end
end

function fishing_boat.swap_node(self, pos)
    local target_pos = pos
    local have_air = false
    local node = nil
    local count = 0
    while have_air == false and count <= 3 do
        node = minetest.get_node(target_pos)
        if node.name == "air" then
            have_air = true
            break
        end
        count = count + 1
        target_pos.y = target_pos.y + 1
    end
    
    if have_air then
        minetest.set_node(target_pos, {name='fishing_boat:light'})
        fishing_boat.remove_light(self)
        self._light_old_pos = target_pos
        --remove after one second
        --[[minetest.after(1,function(target_pos)
            local node = minetest.get_node_or_nil(target_pos)
            if node and node.name == "fishing_boat:light" then
                minetest.swap_node(target_pos, {name="air"})
            end
        end, target_pos)]]--

        return true
    end
    return false
end

function fishing_boat.put_light(self)
    local pos = self.object:get_pos()
    pos.y = pos.y + 3
    local light_pos = pos

    local n = minetest.get_node_or_nil(light_pos)
    if n and n.name == 'air' then
        fishing_boat.swap_node(self, light_pos)
    end

end

minetest.register_node("fishing_boat:light", {
	drawtype = "airlike",
	--tile_images = {"automobiles_light.png"},
	inventory_image = minetest.inventorycube("fishing_boat_light.png"),
	paramtype = "light",
	walkable = false,
	is_ground_content = true,
	light_propagates = true,
	sunlight_propagates = true,
	light_source = 14,
	selection_box = {
		type = "fixed",
		fixed = {0, 0, 0, 0, 0, 0},
	},
})
