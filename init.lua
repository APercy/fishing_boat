fishing_boat={}
fishing_boat.gravity = tonumber(minetest.settings:get("movement_gravity")) or 9.8
fishing_boat.trunk_slots = 50
fishing_boat.fuel = {['biofuel:biofuel'] = {amount=1},['biofuel:bottle_fuel'] = {amount=1},
        ['biofuel:phial_fuel'] = {amount=0.25}, ['biofuel:fuel_can'] = {amount=10}, ['airutils:biofuel'] = {amount=1}}
fishing_boat.ideal_step = 0.02
fishing_boat.rudder_limit = 30
fishing_boat.iddle_rotation = 0
fishing_boat.max_engine_acc = 3
fishing_boat.max_seats = 5
fishing_boat.pilot_base_pos = {x=0.0,y=0,z=12}
fishing_boat.passenger_pos = {
    [1] = {x=0.0,y=0,z=-20},
    [2] = {x=-11,y=0,z=-12},
    [3] = {x=11,y=0,z=-12},
    [4] = {x=-11,y=0,z=-20},
    [5] = {x=11,y=0,z=-20},
    }

fishing_boat.default_buoyancy = 0.24

fishing_boat.canvas_texture = "wool_white.png^[colorize:#f4e7c1:128"
fishing_boat.metal_texture = "default_clay.png^[colorize:#a3acac:128"
fishing_boat.black_texture = "default_clay.png^[colorize:#030303:200"
fishing_boat.wood_texture = "default_clay.png^[colorize:#3a270d:230"

fishing_boat.use_particles = false
if minetest.settings:get_bool('fishing_boat_enable_particles', false) then
    fishing_boat.use_particles = true
end

fishing_boat.textures = {
            "fishing_boat_white.png", -- faixa superior que envolve o casco
            "default_junglewood.png", --assoalho
            "default_wood.png", --paredes internas casco
            "fishing_boat_painting2.png^[multiply:#dc1818",
            "fishing_boat_black.png", --casco
            "fishing_boat_black.png", -- corpo bussola
            fishing_boat.metal_texture, -- seta da bussola
            fishing_boat.wood_texture, --timao
            "fishing_boat_black.png", --leme
            "fishing_boat_compass.png", -- bussola
            "default_junglewood.png", --mastro
            fishing_boat.metal_texture, --cornetas
            "fishing_boat_helice.png", --helice
            "fishing_boat_painting1.png^[multiply:#0063b0", --bordas casco
            "default_wood.png", --paredes internas
            "fishing_boat_painting1.png^[multiply:#0063b0", --teto
            "fishing_boat_glass.png", --vidros
            "fishing_boat_white.png", --cabine externo
            "fishing_boat_painting1.png^[multiply:#0063b0", --bordas janelas
            "default_wood.png", -- revestimento teto
            "fishing_boat_black.png", -- quilha
            "fishing_boat_black.png", -- suporte timao
            "nautilus_fff.png",
            "nautilus_red.png",
        }

fishing_boat.colors ={
    black='#2b2b2b',
    blue='#0063b0',
    brown='#8c5922',
    cyan='#07B6BC',
    dark_green='#567a42',
    dark_grey='#6d6d6d',
    green='#4ee34c',
    grey='#9f9f9f',
    magenta='#ff0098',
    orange='#ff8b0e',
    pink='#ff62c6',
    red='#dc1818',
    violet='#a437ff',
    white='#FFFFFF',
    yellow='#ffe400',
}

dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "walk_map.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "utilities.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "light.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "control.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "fuel_management.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "engine_management.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "custom_physics.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "hud.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "entities.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "forms.lua")
dofile(minetest.get_modpath("fishing_boat") .. DIR_DELIM .. "manual.lua")

--
-- helpers and co.
--

function fishing_boat.get_hipotenuse_value(point1, point2)
    return math.sqrt((point1.x - point2.x) ^ 2 + (point1.y - point2.y) ^ 2 + (point1.z - point2.z) ^ 2)
end

function fishing_boat.dot(v1,v2)
    return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z
end

function fishing_boat.sign(n)
    return n>=0 and 1 or -1
end

function fishing_boat.minmax(v,m)
    return math.min(math.abs(v),m)*fishing_boat.sign(v)
end

-----------
-- items
-----------

-- boat
minetest.register_craftitem("fishing_boat:boat", {
	description = "Fishing Boat",
	inventory_image = "fishing_boat_icon.png",
    liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
        
        local pointed_pos = pointed_thing.under
        local node_below = minetest.get_node(pointed_pos).name
        local nodedef = minetest.registered_nodes[node_below]
        

        if nodedef.liquidtype ~= "none" then
            -- minimum water depth has to be 2, for place the boat
            pointed_pos.y = pointed_pos.y - 2;
            node_below = minetest.get_node(pointed_pos).name
            nodedef = minetest.registered_nodes[node_below]
            if nodedef.liquidtype == "none" then
                minetest.chat_send_player(placer:get_player_name(), "The boat have to be placed on deeper water.")
                return
            end

		    pointed_pos.y=pointed_pos.y+3
		    local boat = minetest.add_entity(pointed_pos, "fishing_boat:boat")
		    if boat and placer then
                local ent = boat:get_luaentity()
                ent._passengers = fishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
                --minetest.chat_send_all('passengers: '.. dump(ent._passengers))
                local owner = placer:get_player_name()
                ent.owner = owner
			    boat:set_yaw(placer:get_look_horizontal())
			    itemstack:take_item()
                airutils.create_inventory(ent, fishing_boat.trunk_slots, owner)

                local properties = ent.object:get_properties()
                properties.infotext = owner .. " nice boat"
                boat:set_properties(properties)
                --fishing_boat.attach_pax(ent, placer)
		    end

		    return itemstack
        end
        return
	end,
})


--
-- crafting
--

if not minetest.settings:get_bool('fishing_boat.disable_craftitems') then
    -- engine
    minetest.register_craftitem("fishing_boat:hull",{
	    description = "Boat hull",
	    inventory_image = "phishing_boat_hull_icon.png",
    })
    -- hull
    minetest.register_craftitem("fishing_boat:cabin",{
	    description = "Boat cabin",
	    inventory_image = "phishing_boat_cabin_icon.png",
    })

	minetest.register_craft({
		output = "fishing_boat:hull",
		recipe = {
			{"group:wood",          "group:wood",          "group:wood"},
			{"group:wood",          "group:wood",          "default:mese_block"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		}
	})
	minetest.register_craft({
		output = "fishing_boat:cabin",
		recipe = {
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
			{"default:glass",       "default:glass",       "group:wood"},
			{"default:steel_ingot", "group:wood",          "group:wood"},
		}
	})
	minetest.register_craft({
		output = "fishing_boat:boat",
		recipe = {
			{"fishing_boat:hull", "fishing_boat:cabin"},
		}
	})
end

