function phishing_boat.testDamage(self, velocity, position)
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
    local impact = math.abs(phishing_boat.get_hipotenuse_value(velocity, self._last_vel))
    if impact > 2 then
        if self.colinfo then
            collision = self.colinfo.collides
            --minetest.chat_send_all(impact)
        end
    end

    if collision then
        --self.object:set_velocity({x=0,y=0,z=0})
        local damage = impact -- / 2
        minetest.sound_play("phishing_boat_collision", {
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

        if self.driver_name then
            local player_name = self.driver_name

            local player = minetest.get_player_by_name(player_name)
            if player then
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

function phishing_boat.check_passenger_is_attached(self, name)
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
function phishing_boat.rescueConnectionFailedPassengers(self)
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
                            --phishing_boat.dettachPlayer(self, player)
		                end
                    end
                end
            end
        end
    end
end

-- attach passenger
function phishing_boat.attach_pax(self, player, slot)
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

function phishing_boat.dettach_pax(self, player, side)
    side = side or "r"
    if player then
        local name = player:get_player_name() --self._passenger
        phishing_boat.remove_hud(player)

        -- passenger clicked the object => driver gets off the vehicle
        for i = 5,1,-1 
        do 
            if self._passengers[i] == name then
                self._passengers[i] = nil
                self._passengers_base_pos[i] = phishing_boat.copy_vector(phishing_boat.passenger_pos[i])
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

function phishing_boat.textures_copy()
    local tablecopy = {}
    for k, v in pairs(phishing_boat.textures) do
      tablecopy[k] = v
    end
    return tablecopy
end

function phishing_boat.set_logo(self, texture_name)
    if texture_name == "" or texture_name == nil then
        self.logo = "phishing_boat_alpha_logo.png"
    elseif texture_name then
        self.logo = texture_name
    end
    --paint(self)
end

--painting
function phishing_boat.paint(self, tex, colstr)
    if colstr then
        self.color = colstr
        local l_textures = self.initial_properties.textures
        for _, texture in ipairs(l_textures) do
            local indx = texture:find(tex)
            if indx then
                l_textures[_] = tex.."^[multiply:".. colstr
            end
        end
	    self.object:set_properties({textures=l_textures})
    end
end

--painting
function phishing_boat.paint1(self, colstr)
    if colstr then
        self.color = colstr
        phishing_boat.paint(self, "phishing_boat_painting1.png", colstr)
    end
end
function phishing_boat.paint2(self, colstr)
    if colstr then
        self.color2 = colstr
        phishing_boat.paint(self, "phishing_boat_painting2.png", colstr)
    end
end

-- destroy the boat
function phishing_boat.destroy(self, overload)
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end

    local pos = self.object:get_pos()
    if self.fire then self.fire:remove() end
    if self._passengers_base[1] then self._passengers_base[1]:remove() end
    if self._passengers_base[2] then self._passengers_base[2]:remove() end
    if self._passengers_base[3] then self._passengers_base[3]:remove() end
    if self._passengers_base[4] then self._passengers_base[4]:remove() end
    if self._passengers_base[5] then self._passengers_base[5]:remove() end

    airutils.destroy_inventory(self)
    self.object:remove()

    pos.y=pos.y+2
    --[[for i=1,7 do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:steel_ingot')
    end

    for i=1,7 do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:mese_crystal')
    end]]--

    --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'phishing_boat:boat')
    --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:diamond')

    --[[local total_biofuel = math.floor(self._energy) - 1
    for i=0,total_biofuel do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'biofuel:biofuel')
    end]]--
    if overload then
        local stack = ItemStack(self.item)
        local item_def = stack:get_definition()
        
        if item_def.overload_drop then
            for _,item in pairs(item_def.overload_drop) do
                minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},item)
            end
            return
        end
    end
    local stack = ItemStack(self.item)
    local item_def = stack:get_definition()
    if self.hull_integrity then
        local boat_wear = math.floor(65535*(1-(self.hull_integrity/item_def.hull_integrity)))
        stack:set_wear(boat_wear)
    end
    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5}, stack)
end

--returns 0 for old, 1 for new
function phishing_boat.detect_player_api(player)
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

function phishing_boat.checkAttach(self, player)
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

function phishing_boat.clamp(value, min, max)
    local retVal = value
    if value < min then retVal = min end
    if value > max then retVal = max end
    --minetest.chat_send_all(value .. " - " ..retVal)
    return retVal
end

function phishing_boat.reclamp(value, min, max)
    local retVal = value
    local mid = (max-min)/2
    if value > min and value <= (min+mid) then retVal = min end
    if value < max and value > (max-mid) then retVal = max end
    minetest.chat_send_all(value .. " - return: " ..retVal .. " - mid: " .. mid)
    return retVal
end

function phishing_boat.engineSoundPlay(self)
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

function phishing_boat.engine_set_sound_and_animation(self)
    if self._last_applied_power ~= self._power_lever then
        --minetest.chat_send_all('test2')
        self._last_applied_power = self._power_lever
        self.object:set_animation_frame_speed(phishing_boat.iddle_rotation + (self._power_lever))
        if self._last_sound_update == nil then self._last_sound_update = self._power_lever end
        if math.abs(self._last_sound_update - self._power_lever) > 5 then
            self._last_sound_update = self._power_lever
            phishing_boat.engineSoundPlay(self)
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


function phishing_boat.boat_deck_map(pos, dpos)
    local orig_pos = phishing_boat.copy_vector(pos)
    local position = phishing_boat.copy_vector(dpos)
    local new_pos = phishing_boat.copy_vector(dpos)
    new_pos.z = phishing_boat.clamp(new_pos.z, -29, 40)
    --minetest.chat_send_all(dump(new_pos))
    if position.z > -31 and position.z < -20 then --limit 10
        new_pos.y = 0
        new_pos.x = phishing_boat.clamp(new_pos.x, -12, 12)
        return new_pos
    end
    if position.z > -20 and position.z < -14 then --limit 10
        new_pos.y = 0
        new_pos.x = phishing_boat.clamp(new_pos.x, -14, 14)
        return new_pos
    end
    if position.z > -14 and position.z < -5 then --limit 10
        new_pos.y = 0
        new_pos.x = phishing_boat.clamp(new_pos.x, -16, 16)
        return new_pos
    end

    if position.z > -5 and position.z < 10 then --limit 10
        new_pos.y = 0
        new_pos.x = phishing_boat.clamp(new_pos.x, -14.5, 14.5)
        if position.z > -2 then
            if orig_pos.x <= -14.5 or orig_pos.x >= 14.5 then
                -- X
                new_pos.x = phishing_boat.reclamp(new_pos.x, -14.5, 14.5)
            else
                -- Z
                new_pos.z = phishing_boat.reclamp(new_pos.z, -3, 10)
            end
        end
        return new_pos
    end

    if position.z > 10 and position.z <= 22 then --limit 11
        new_pos.y = 0
        new_pos.x = phishing_boat.clamp(position.x, -15, 15)
        if position.z < 21 then
            if orig_pos.x <= -14.5 or orig_pos.x >= 14.5 then
                -- X
                new_pos.x = phishing_boat.reclamp(new_pos.x, -14.5, 14.5)
            else
                -- Z
                new_pos.z = phishing_boat.reclamp(new_pos.z, 10, 20)
            end
        end
        return new_pos
    end

    if position.z > 22 and position.z <= 30 then --limit 7
        new_pos.y = 0.0
        new_pos.x = phishing_boat.clamp(new_pos.x, -13, 13)
        return new_pos
    end
    if position.z > 30 and position.z <= 36 then --limit 5
        new_pos.y = 3.0
        new_pos.x = phishing_boat.clamp(new_pos.x, -10, 10)
        return new_pos
    end
    if position.z > 36 and position.z < 47 then --limit 1
        new_pos.y = 3.0
        new_pos.x = phishing_boat.clamp(new_pos.x, -5, 5)
        return new_pos
    end
    return new_pos
end

function phishing_boat.play_rope_sound(self)
    minetest.sound_play({name = "phishing_boat_rope"},
                {object = self.object, gain = 1,
                    max_hear_distance = 5,
                    ephemeral = true,})
end

--note: index variable just for the walk
local function get_result_pos(self, player, index)
    local pos = nil
    if player then
        local direction = player:get_look_horizontal()
        local rotation = self.object:get_rotation()
        direction = direction - rotation.y
        local y_rot = -math.deg(direction)
        local ctrl = player:get_player_control()
        pos = vector.new()
        pos.y = y_rot --okay, this is strange to keep here, but as I dont use it anyway...
        if ctrl.up or ctrl.down or ctrl.left or ctrl.right then
            player_api.set_animation(player, "walk", 30)
            local dir = 0
            if ctrl.up then dir = -1 end
            if ctrl.down then dir = 1 end
            if ctrl.left then
                direction = direction - math.rad(90)
                dir = 1
            end
            if ctrl.right then
                direction = direction + math.rad(90)
                dir = 1
            end
            local time_correction = (self.dtime/phishing_boat.ideal_step)
            local move = 0.3 * dir * time_correction
            pos.x = move * math.cos(-direction)
            pos.z = move * math.sin(-direction)

            --lets fake walk sound
            if self._passengers_base_pos[index].dist_moved == nil then self._passengers_base_pos[index].dist_moved = 0 end
            self._passengers_base_pos[index].dist_moved = self._passengers_base_pos[index].dist_moved + move;
            if math.abs(self._passengers_base_pos[index].dist_moved) > 5 then
                self._passengers_base_pos[index].dist_moved = 0
                minetest.sound_play({name = "default_wood_footstep"},
                    {object = self._passengers_base_pos[index].object, gain = 0.1,
                        max_hear_distance = 5,
                        ephemeral = true,})
            end

            --[[
            sin(theta) = opposite/hypotenuse
            cos(theta) = adjacent/hypotenuse
            For X "Distance * COS ( Angle )"
            For Y "Distance * SIN ( Angle )"
            ]]--
        else
            player_api.set_animation(player, "stand")
        end
    end
    return pos
end

function phishing_boat.navigate_deck(pos, dpos, player)
    local pos_d = dpos
    if player then
        if pos.y <= 8.5 and pos.y >= 0 then
            pos_d = phishing_boat.boat_deck_map(pos, dpos)
        end

        local ctrl = player:get_player_control()
        if ctrl.jump or ctrl.sneak then --ladder
            if ladder_zone then

            end
        end
    end

    return pos_d
end

function phishing_boat.move_persons(self)
    --self._passenger = nil
    if self.object == nil then return end
    for i = 5,1,-1 
    do
        local player = nil
        if self._passengers[i] then player = minetest.get_player_by_name(self._passengers[i]) end

        if self.driver_name and self._passengers[i] == self.driver_name then
            --clean driver if it's nil
            if player == nil then
                self._passengers[i] = nil
                self.driver_name = nil
            end
        else
            if self._passengers[i] ~= nil then
                --minetest.chat_send_all("pass: "..dump(self._passengers[i]))
                --the rest of the passengers
                if player then
                    local result_pos = get_result_pos(self, player, i)
                    local y_rot = 0
                    if result_pos then
                        y_rot = result_pos.y -- the only field that returns a rotation
                        local new_pos = phishing_boat.copy_vector(self._passengers_base_pos[i])
                        new_pos.x = new_pos.x - result_pos.z
                        new_pos.z = new_pos.z - result_pos.x
                        --minetest.chat_send_all(dump(new_pos))
                        --local pos_d = phishing_boat.boat_lower_deck_map(self._passengers_base_pos[i], new_pos)
                        local pos_d = phishing_boat.navigate_deck(self._passengers_base_pos[i], new_pos, player)
                        --minetest.chat_send_all(dump(height))
                        self._passengers_base_pos[i] = phishing_boat.copy_vector(pos_d)
                        self._passengers_base[i]:set_attach(self.object,'',self._passengers_base_pos[i],{x=0,y=0,z=0})
                    end
                    --minetest.chat_send_all(dump(self._passengers_base_pos[i]))
                    player:set_attach(self._passengers_base[i], "", {x = 0, y = 0, z = 0}, {x = 0, y = y_rot, z = 0})
                else
                    --self._passengers[i] = nil
                end
            end
        end
    end
end

function phishing_boat.copy_vector(original_vector)
    local tablecopy = {}
    for k, v in pairs(original_vector) do
      tablecopy[k] = v
    end
    return tablecopy
end
