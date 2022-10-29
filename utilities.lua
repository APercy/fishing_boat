function fishing_boat.getRepairTax(self)
    local difference = self.buoyancy - fishing_boat.default_buoyancy
    local tax = 0.02
    local steel = difference / tax
    return steel
end

function fishing_boat.testDamage(self, velocity, position)
    if self._last_accell == nil then return end
    local p = position --self.object:get_pos()
    local collision = false
    local low_node_pos = -2.5
    if self._last_vel == nil then return end
    --lets calculate the vertical speed, to avoid the bug on colliding on floor with hard lag
    if math.abs(velocity.y - self._last_vel.y) > 2 then
		local noded = airutils.nodeatpos(airutils.pos_shift(p,{y=low_node_pos}))
	    if (noded and noded.drawtype ~= 'airlike') then
		    collision = true
	    else
            self.object:set_velocity(self._last_vel)
            --self.object:set_acceleration(self._last_accell)
            self.object:set_velocity(vector.add(velocity, vector.multiply(self._last_accell, self.dtime/8)))
        end
    end
    local impact = math.abs(fishing_boat.get_hipotenuse_value(velocity, self._last_vel))
    if impact > 2 then
        if self.colinfo then
            collision = self.colinfo.collides
            --minetest.chat_send_all(impact)
        end
    end

    if collision then
        --self.object:set_velocity({x=0,y=0,z=0})
        local damage = impact -- / 2
        minetest.sound_play("fishing_boat_collision", {
            --to_player = self.driver_name,
            object = self.object,
            max_hear_distance = 15,
            gain = 1.0,
            fade = 0.0,
            pitch = 1.0,
        }, true)
        if damage > 5 then
            self._power_lever = 0
        end
        self.buoyancy = self.buoyancy + (damage/100)

        if self.driver_name then
            local player_name = self.driver_name

            local player = minetest.get_player_by_name(player_name)
            if player then
                minetest.chat_send_player(self.driver_name,core.colorize('#ff0000', " >>> The boat was damaged, repair it, please."))
		        if player:get_hp() > 0 then
			        player:set_hp(player:get_hp()-(damage/2))
		        end
            end
            if self._passenger ~= nil then
                local passenger = minetest.get_player_by_name(self._passenger)
                if passenger then
		            if passenger:get_hp() > 0 then
			            passenger:set_hp(passenger:get_hp()-(damage/2))
		            end
                end
            end
        end

    end
end

local function do_attach(self, player, slot)
    if slot == 0 then return end
    if self._passengers[slot] == nil then
        local name = player:get_player_name()
        --minetest.chat_send_all(self.driver_name)
        self._passengers[slot] = name
        player:set_attach(self._passengers_base[slot], "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player_api.player_attached[name] = true
    end
end

function fishing_boat.check_passenger_is_attached(self, name)
    local is_attached = false
    if is_attached == false then
        for i = 5,1,-1 
        do 
            if self._passengers[i] == name then
                is_attached = true
                break
            end
        end
    end
    return is_attached
end

--this method checks each 1 second for a disconected player who comes back
function fishing_boat.rescueConnectionFailedPassengers(self)
    self._disconnection_check_time = self._disconnection_check_time + self.dtime
    if self._disconnection_check_time > 1 then
        --minetest.chat_send_all(dump(self._passengers))
        self._disconnection_check_time = 0
        for i = 5,1,-1 
        do 
            if self._passengers[i] then
                local player = minetest.get_player_by_name(self._passengers[i])
                if player then --we have a player!
                    if player_api.player_attached[self._passengers[i]] == nil then --but isn't attached?
                        --minetest.chat_send_all("okay")
		                if player:get_hp() > 0 then
                            self._passengers[i] = nil --clear the slot first
                            do_attach(self, player, i) --attach
                        else
                            --fishing_boat.dettachPlayer(self, player)
		                end
                    end
                end
            end
        end
    end
end

-- attach passenger
function fishing_boat.attach_pax(self, player, slot)
    slot = slot or 0

    --verify if is locked to non-owners
    if self._passengers_locked == true then
        local name = player:get_player_name()
        local can_bypass = minetest.check_player_privs(player, {protection_bypass=true})
        local is_shared = false
        if name == self.owner or can_bypass then is_shared = true end
        for k, v in pairs(self._shared_owners) do
            if v == name then
                is_shared = true
                break
            end
        end
        if is_shared == false then
            minetest.chat_send_player(name,core.colorize('#ff0000', " >>> This boat is currently locked for non-owners"))
            return
        end
    end


    if slot > 0 then
        do_attach(self, player, slot)
        return
    end
    --minetest.chat_send_all(dump(self._passengers))

    --now yes, lets attach the player
    --randomize the seat
    local t = {1,2,3,4,5}
    for i = 1, #t*2 do
        local a = math.random(#t)
        local b = math.random(#t)
        t[a],t[b] = t[b],t[a]
    end

    --minetest.chat_send_all(dump(t))

    local i=0
    for k,v in ipairs(t) do
        i = t[k]
        if self._passengers[i] == nil then
            do_attach(self, player, i)
            break
        end
    end
end

function fishing_boat.dettach_pax(self, player, side)
    side = side or "r"
    if player then
        local name = player:get_player_name() --self._passenger
        fishing_boat.remove_hud(player)

        -- passenger clicked the object => driver gets off the vehicle
        for i = 5,1,-1 
        do 
            if self._passengers[i] == name then
                self._passengers[i] = nil
                self._passengers_base_pos[i] = fishing_boat.copy_vector(fishing_boat.passenger_pos[i])
                --break
            end
        end

        -- detach the player
        player:set_detach()
        player_api.player_attached[name] = nil
        player_api.set_animation(player, "stand")

        -- move player down
        minetest.after(0.1, function(pos)
            local rotation = self.object:get_rotation()
            local direction = rotation.y

            if side == "l" then
                direction = direction - math.rad(180)
            end

            local move = 5
            pos.x = pos.x + move * math.cos(direction)
            pos.z = pos.z + move * math.sin(direction)
            if self.isinliquid then
                pos.y = pos.y + 1
            else
                pos.y = pos.y - 2.5
            end
            player:set_pos(pos)
        end, player:get_pos())
    end
end

function fishing_boat.textures_copy()
    local tablecopy = {}
    for k, v in pairs(fishing_boat.textures) do
      tablecopy[k] = v
    end
    return tablecopy
end

function fishing_boat.set_logo(self, texture_name)
    if texture_name == "" or texture_name == nil then
        self.logo = "fishing_boat_alpha_logo.png"
    elseif texture_name then
        self.logo = texture_name
    end
    --paint(self)
end

function fishing_boat.textures_copy()
    local tablecopy = {}
    for k, v in pairs(fishing_boat.textures) do
      tablecopy[k] = v
    end
    return tablecopy
end

--painting
function fishing_boat.paint(self)
    --self.color = colstr
    local l_textures = fishing_boat.textures_copy() --self.initial_properties.textures
    for _, texture in ipairs(l_textures) do
        local tex = "fishing_boat_painting1.png"
        local indx = texture:find(tex)
        if indx then
            l_textures[_] = tex.."^[multiply:".. self.color
        end
        tex = "fishing_boat_painting2.png"
        indx = texture:find(tex)
        if indx then
            l_textures[_] = tex.."^[multiply:".. self.color2
        end
    end
    self.object:set_properties({textures=l_textures})
end

--painting
function fishing_boat.paint1(self, colstr)
    if colstr then
        self.color = colstr
        fishing_boat.paint(self)
    end
end
function fishing_boat.paint2(self, colstr)
    if colstr then
        self.color2 = colstr
        fishing_boat.paint(self)
    end
end

-- destroy the boat
function fishing_boat.destroy(self, overload)
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end

    fishing_boat.remove_light(self)

    local pos = self.object:get_pos()
    if self._light then self._light:remove() end
    if self._passengers_base[1] then self._passengers_base[1]:remove() end
    if self._passengers_base[2] then self._passengers_base[2]:remove() end
    if self._passengers_base[3] then self._passengers_base[3]:remove() end
    if self._passengers_base[4] then self._passengers_base[4]:remove() end
    if self._passengers_base[5] then self._passengers_base[5]:remove() end

    airutils.destroy_inventory(self)
    self.object:remove()

    pos.y=pos.y+2
    for i=1,8 do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:wood')
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:mese_crystal')
    end

    for i=1,4 do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:steel_ingot')
    end

    --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5}, "fishing_boat:boat")
end

--returns 0 for old, 1 for new
function fishing_boat.detect_player_api(player)
    local player_proterties = player:get_properties()
    local mesh = "character.b3d"
    if player_proterties.mesh == mesh then
        local models = player_api.registered_models
        local character = models[mesh]
        if character then
            if character.animations.sit.eye_height then
                return 1
            else
                return 0
            end
        end
    end

    return 0
end

function fishing_boat.checkAttach(self, player)
    local retVal = false
    if player then
        local player_attach = player:get_attach()
        if player_attach then
            for i = 5,1,-1 
            do 
                if player_attach == self._passengers_base[i] then
                    retVal = true
                    break
                end
            end
        end
    end
    return retVal
end

function fishing_boat.engineSoundPlay(self)
    --sound
    if self.sound_handle then minetest.sound_stop(self.sound_handle) end
    if self.sound_handle_pistons then minetest.sound_stop(self.sound_handle_pistons) end
    if self.object then
        self.sound_handle = minetest.sound_play({name = "default_furnace_active"},
            {object = self.object, gain = 0.2,
                max_hear_distance = 5,
                loop = true,})

        self.sound_handle_pistons = minetest.sound_play({name = "default_cool_lava"},--"default_item_smoke"},
            {object = self.object, gain = 0.05,
                pitch = 0.4+((math.abs(self._power_lever)/100)/2),
                max_hear_distance = 32,
                loop = true,})
    end
end

function fishing_boat.engine_set_sound_and_animation(self)
    if self._last_applied_power ~= self._power_lever then
        --minetest.chat_send_all('test2')
        self._last_applied_power = self._power_lever
        self.object:set_animation_frame_speed(fishing_boat.iddle_rotation + (self._power_lever))
        if self._last_sound_update == nil then self._last_sound_update = self._power_lever end
        if math.abs(self._last_sound_update - self._power_lever) > 5 then
            self._last_sound_update = self._power_lever
            fishing_boat.engineSoundPlay(self)
        end
    end
    if self._engine_running == false then
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
            --self.object:set_animation_frame_speed(0)
        end
    end
end


function fishing_boat.play_rope_sound(self)
    minetest.sound_play({name = "fishing_boat_rope"},
                {object = self.object, gain = 1,
                    max_hear_distance = 5,
                    ephemeral = true,})
end

function fishing_boat.copy_vector(original_vector)
    local tablecopy = {}
    for k, v in pairs(original_vector) do
      tablecopy[k] = v
    end
    return tablecopy
end
