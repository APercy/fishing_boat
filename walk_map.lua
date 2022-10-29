function fishing_boat.clamp(value, min, max)
    local retVal = value
    if value < min then retVal = min end
    if value > max then retVal = max end
    --minetest.chat_send_all(value .. " - " ..retVal)
    return retVal
end

function fishing_boat.reclamp(value, min, max)
    local retVal = value
    local mid = (max-min)/2
    if value > min and value <= (min+mid) then retVal = min end
    if value < max and value > (max-mid) then retVal = max end
    --minetest.chat_send_all(value .. " - return: " ..retVal .. " - mid: " .. mid)
    return retVal
end

function fishing_boat.boat_deck_map(pos, dpos)
    local orig_pos = fishing_boat.copy_vector(pos)
    local position = fishing_boat.copy_vector(dpos)
    local new_pos = fishing_boat.copy_vector(dpos)
    new_pos.z = fishing_boat.clamp(new_pos.z, -29, 40)
    local limit = 0
    --minetest.chat_send_all(dump(new_pos))
    if position.z > -31 and position.z < -20 then
        new_pos.y = 0
        limit = 12
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)
        return new_pos
    end
    if position.z > -20 and position.z < -14 then
        new_pos.y = 0
        limit = 14
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)
        return new_pos
    end
    if position.z > -14 and position.z < -5 then
        new_pos.y = 0
        limit = 16
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)

        --test back cabin collision
        limit = 14.5
        if position.x > -limit and position.x <= limit and position.z > -6 then
            new_pos.y = 0
            if orig_pos.x < 1 or orig_pos.x > 8 then
                new_pos.z = fishing_boat.clamp(new_pos.z, -14, -6)
            end
        end

        return new_pos
    end

    if position.z > -5 and position.z < 10 then
        new_pos.y = 0
        limit = 16
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)
        if position.z > -4 then
            --internal wall
            limit = 14.5
            if orig_pos.x <= -limit or orig_pos.x >= limit then
                -- X
                new_pos.x = fishing_boat.reclamp(new_pos.x, -limit, limit)
            end
        end
        return new_pos
    end

    if position.z > 10 and position.z <= 24 then 
        new_pos.y = 0
        limit = 16
        new_pos.x = fishing_boat.clamp(position.x, -limit, limit)
        if position.z < 21 then
            --internal wall
            limit = 14.5
            if orig_pos.x <= -limit or orig_pos.x >= limit then
                -- X
                new_pos.x = fishing_boat.reclamp(new_pos.x, -limit, limit)
            end
        end
        return new_pos
    end

    if position.z > 24 and position.z <= 30 then
        new_pos.y = 0.0
        limit = 13
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)
        --test front cabin collision
        if position.x > -limit and position.x < limit and position.z < 25 then
            new_pos.y = 0
            new_pos.z = fishing_boat.clamp(new_pos.z, 25, 30)
        end
        return new_pos
    end

    if position.z > 30 and position.z <= 36 then
        new_pos.y = 3.0
        limit = 10
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)
        return new_pos
    end
    if position.z > 36 and position.z < 47 then
        new_pos.y = 3.0
        limit = 5
        new_pos.x = fishing_boat.clamp(new_pos.x, -limit, limit)
        return new_pos
    end
    return new_pos
end

function fishing_boat.cabin_map(pos, dpos)
    local orig_pos = fishing_boat.copy_vector(pos)
    local position = fishing_boat.copy_vector(dpos)
    local new_pos = fishing_boat.copy_vector(dpos)

    --trying to go out the cabin
    if new_pos.x < 6 and new_pos.x > 2 and position.z < 3 then
        return new_pos
    end

    --limit to the cabin
    new_pos.z = fishing_boat.clamp(new_pos.z, 3, 14)
    if position.z > -5 and position.z < 20 then --limit 10
        new_pos.x = fishing_boat.clamp(new_pos.x, -6, 6)
    end
    return new_pos
end

local function is_cabin_zone(pos)
    local cabin_zone = false
    if pos.z > 0 and pos.z <= 15 and pos.x > -6.5 and pos.x < 6.5 then cabin_zone = true end
    return cabin_zone
end

function fishing_boat.navigate_deck(pos, dpos, player)
    local pos_d = dpos
    local cabin_zone = is_cabin_zone(pos)
    if player then
        if cabin_zone then
            pos_d = fishing_boat.cabin_map(pos, dpos)
        else
            pos_d = fishing_boat.boat_deck_map(pos, dpos)
        end
    end

    return pos_d
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
            local time_correction = (self.dtime/fishing_boat.ideal_step)
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

function fishing_boat.move_persons(self)
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
                        local new_pos = fishing_boat.copy_vector(self._passengers_base_pos[i])
                        new_pos.x = new_pos.x - result_pos.z
                        new_pos.z = new_pos.z - result_pos.x
                        --minetest.chat_send_all(dump(new_pos))
                        --local pos_d = fishing_boat.boat_lower_deck_map(self._passengers_base_pos[i], new_pos)
                        local pos_d = fishing_boat.navigate_deck(self._passengers_base_pos[i], new_pos, player)
                        --minetest.chat_send_all(dump(height))
                        self._passengers_base_pos[i] = fishing_boat.copy_vector(pos_d)
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


