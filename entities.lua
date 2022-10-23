--
-- constants
--
local LONGIT_DRAG_FACTOR = 0.13*0.13
local LATER_DRAG_FACTOR = 2.0

--
-- seat pivot
--
minetest.register_entity('phishing_boat:stand_base',{
    initial_properties = {
	    physical = true,
	    collide_with_objects=true,
        collisionbox = {-2, -2, -2, 2, 0, 2},
	    pointable=false,
	    visual = "mesh",
	    mesh = "phishing_boat_stand_base.b3d",
        textures = {"phishing_boat_alpha.png",},
	},
    dist_moved = 0,
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
})

minetest.register_entity("phishing_boat:boat", {
    initial_properties = {
        physical = true,
        collide_with_objects = true, --true,
        collisionbox = {-2, -2.5, -2, 2, 6, 2}, --{-1,0,-1, 1,0.3,1},
        --selectionbox = {-0.6,0.6,-0.6, 0.6,1,0.6},
        visual = "mesh",
        backface_culling = false,
        mesh = "phishing_boat.b3d",
        textures = phishing_boat.textures_copy(),
    },
    textures = {},
    driver_name = nil,
    sound_handle = nil,
    static_save = true,
    infotext = "A nice phishing boat",
    lastvelocity = vector.new(),
    hp = 50,
    color = "blue",
    color2 = "white",
    logo = "phishing_boat_alpha_logo.png",
    timeout = 0;
    buoyancy = 0.24,
    max_hp = 50,
    anchored = false,
    physics = phishing_boat.physics,
    hull_integrity = nil,
    owner = "",
    _shared_owners = {},
    _engine_running = false,
    _power_lever = 0,
    _last_applied_power = -100,
    _at_control = false,
    _rudder_angle = 0,
    _show_hud = true,
    _energy = 1.0,--0.001,
    _passengers = {}, --passengers list
    _passengers_base = {}, --obj id
    _passengers_base_pos = phishing_boat.copy_vector({}),
    _passengers_locked = false,
    _disconnection_check_time = 0,
    _inv = nil,
    _inv_id = "",
    item = "phishing_boat:boat",

    get_staticdata = function(self) -- unloaded/unloads ... is now saved
        return minetest.serialize({
            stored_is_running = self._engine_running,
            stored_energy = self._energy,
            stored_owner = self.owner,
            stored_shared_owners = self._shared_owners,
            stored_hp = self.hp,
            stored_color = self.color,
            stored_color2 = self.color2,
            stored_anchor = self.anchored,
            stored_hull_integrity = self.hull_integrity,
            stored_item = self.item,
            stored_inv_id = self._inv_id,
            stored_passengers = self._passengers, --passengers list
            stored_passengers_locked = self._passengers_locked,
        })
    end,

	on_deactivate = function(self)
        airutils.save_inventory(self)
        if self.sound_handle then minetest.sound_stop(self.sound_handle) end
        if self.sound_handle_pistons then minetest.sound_stop(self.sound_handle_pistons) end
	end,

    on_activate = function(self, staticdata, dtime_s)
        --minetest.chat_send_all('passengers: '.. dump(self._passengers))
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.deserialize(staticdata) or {}
            self._engine_running = data.stored_is_running or false
            self._energy = data.stored_energy or 0
            self.owner = data.stored_owner or ""
            self._shared_owners = data.stored_shared_owners or {}
            self.hp = data.stored_hp or 50
            self.color = data.stored_color or "blue"
            self.color2 = data.stored_color2 or "white"
            self.logo = data.stored_logo or "phishing_boat_alpha_logo.png"
            self.anchored = data.stored_anchor or false
            self.hull_integrity = data.stored_hull_integrity
            self.item = data.stored_item
            self._inv_id = data.stored_inv_id
            self._passengers = data.stored_passengers or phishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
            self._passengers_locked = data.stored_passengers_locked
            --minetest.debug("loaded: ", self._energy)
            local properties = self.object:get_properties()
            properties.infotext = data.stored_owner .. " nice phishing boat"
            self.object:set_properties(properties)
        end

        local colstr = phishing_boat.colors[self.color]
        if not colstr then
            colstr = "blue"
            self.color = colstr
        end
        phishing_boat.paint(self, self.color)
        phishing_boat.paint2(self, self.color2)
        local pos = self.object:get_pos()

        self._passengers_base = phishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
        self._passengers_base_pos = phishing_boat.copy_vector({[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,})
        self._passengers_base_pos = {
                [1]=phishing_boat.copy_vector(phishing_boat.passenger_pos[1]),
                [2]=phishing_boat.copy_vector(phishing_boat.passenger_pos[2]),
                [3]=phishing_boat.copy_vector(phishing_boat.passenger_pos[3]),
                [4]=phishing_boat.copy_vector(phishing_boat.passenger_pos[4]),
                [5]=phishing_boat.copy_vector(phishing_boat.passenger_pos[5]),} --curr pos
        --self._passengers = {[1]=nil, [2]=nil, [3]=nil, [4]=nil, [5]=nil,} --passenger names

        self._passengers_base[1]=minetest.add_entity(pos,'phishing_boat:stand_base')
        self._passengers_base[1]:set_attach(self.object,'',self._passengers_base_pos[1],{x=0,y=0,z=0})

        self._passengers_base[2]=minetest.add_entity(pos,'phishing_boat:stand_base')
        self._passengers_base[2]:set_attach(self.object,'',self._passengers_base_pos[2],{x=0,y=0,z=0})

        self._passengers_base[3]=minetest.add_entity(pos,'phishing_boat:stand_base')
        self._passengers_base[3]:set_attach(self.object,'',self._passengers_base_pos[3],{x=0,y=0,z=0})

        self._passengers_base[4]=minetest.add_entity(pos,'phishing_boat:stand_base')
        self._passengers_base[4]:set_attach(self.object,'',self._passengers_base_pos[4],{x=0,y=0,z=0})

        self._passengers_base[5]=minetest.add_entity(pos,'phishing_boat:stand_base')
        self._passengers_base[5]:set_attach(self.object,'',self._passengers_base_pos[5],{x=0,y=0,z=0})

        --animation load - stoped
        self.object:set_animation({x = 1, y = 47}, 0, 0, true)

        self.object:set_bone_position("low_rudder_a", {x=0,y=-23,z=-27}, {x=-0,y=0,z=0})

        self.object:set_armor_groups({immortal=1})

        airutils.actfunc(self, staticdata, dtime_s)

        self.object:set_armor_groups({immortal=1})        

		local inv = minetest.get_inventory({type = "detached", name = self._inv_id})

        phishing_boat.engine_set_sound_and_animation(self)

		-- if the game was closed the inventories have to be made anew, instead of just reattached
		if not inv then
            airutils.create_inventory(self, phishing_boat.trunk_slots)
		else
		    self.inv = inv
        end
    end,

    on_step = function(self,dtime,colinfo)
	    self.dtime = math.min(dtime,0.2)
	    self.colinfo = colinfo
	    self.height = airutils.get_box_height(self)
	    
    --  physics comes first
	    local vel = self.object:get_velocity()
	    
	    if colinfo then 
		    self.isonground = colinfo.touching_ground
	    else
		    if self.lastvelocity.y==0 and vel.y==0 then
			    self.isonground = true
		    else
			    self.isonground = false
		    end
	    end
	    
	    self:physics()

	    if self.logic then
		    self:logic()
	    end
	    
	    self.lastvelocity = self.object:get_velocity()
	    self.time_total=self.time_total+self.dtime
    end,
    logic = function(self)
        
        local accel_y = self.object:get_acceleration().y
        local rotation = self.object:get_rotation()
        local yaw = rotation.y
        local newyaw=yaw
        local pitch = rotation.x
        local newpitch = pitch
        local roll = rotation.z

        local hull_direction = minetest.yaw_to_dir(yaw)
        local nhdir = {x=hull_direction.z,y=0,z=-hull_direction.x}        -- lateral unit vector
        local velocity = self.object:get_velocity()

        local longit_speed = phishing_boat.dot(velocity,hull_direction)
        self._longit_speed = longit_speed --for anchor verify
        local longit_drag = vector.multiply(hull_direction,longit_speed*
                longit_speed*LONGIT_DRAG_FACTOR*-1*phishing_boat.sign(longit_speed))
        local later_speed = phishing_boat.dot(velocity,nhdir)
        local later_drag = vector.multiply(nhdir,later_speed*later_speed*
                LATER_DRAG_FACTOR*-1*phishing_boat.sign(later_speed))
        local accel = vector.add(longit_drag,later_drag)

        local vel = self.object:get_velocity()
        local curr_pos = self.object:get_pos()
        self._last_pos = curr_pos
        self.object:move_to(curr_pos)

        --minetest.chat_send_all(self._energy)
        --local node_bellow = airutils.nodeatpos(airutils.pos_shift(curr_pos,{y=-2.8}))
        --[[local is_flying = true
        if node_bellow and node_bellow.drawtype ~= 'airlike' then is_flying = false end]]--

        local is_attached = false
        local player = nil
        if self.driver_name then
            player = minetest.get_player_by_name(self.driver_name)
            
            if player then
                is_attached = phishing_boat.checkAttach(self, player)
            end
        end

        if self.owner == "" then return end

        --detect collision
        phishing_boat.testDamage(self, vel, curr_pos)

        accel = phishing_boat.control(self, self.dtime, hull_direction, longit_speed, accel) or vel

        --get disconnected players
        phishing_boat.rescueConnectionFailedPassengers(self)

        local turn_rate = math.rad(18)
        newyaw = yaw + self.dtime*(1 - 1 / (math.abs(longit_speed) + 1)) *
            self._rudder_angle / 30 * turn_rate * phishing_boat.sign(longit_speed)



        --roll adjust
        ---------------------------------
        local sdir = minetest.yaw_to_dir(newyaw)
        local snormal = {x=sdir.z,y=0,z=-sdir.x}    -- rightside, dot is negative
        local prsr = phishing_boat.dot(snormal,nhdir)
        local rollfactor = -15
        local newroll = 0
        if self._last_roll ~= nil then newroll = self._last_roll end
        --oscilation when stoped
        if longit_speed == 0 then
            local time_correction = (self.dtime/phishing_boat.ideal_step)
            --stoped
            if self._roll_state == nil then
                self._roll_state = math.floor(math.random(-1,1))
                if self._roll_state == 0 then self._roll_state = 1 end
                self._last_roll = newroll
            end
            local max_roll_bob = 2
            if math.deg(newroll) >= max_roll_bob and self._roll_state == 1 then
                self._roll_state = -1
                phishing_boat.play_rope_sound(self);
            end
            if math.deg(newroll) <= -max_roll_bob and self._roll_state == -1 then
                self._roll_state = 1
                phishing_boat.play_rope_sound(self);
            end
            local roll_factor = (self._roll_state * 0.01) * time_correction
            self._last_roll = self._last_roll + math.rad(roll_factor)
        else
            --in movement
            self._roll_state = nil
            newroll = (prsr*math.rad(rollfactor))*later_speed
            if self._last_roll ~= nil then 
                if math.sign(newroll) ~= math.sign(self._last_roll) then
                    phishing_boat.play_rope_sound(self)
                end
            end
            self._last_roll = newroll
        end
        --minetest.chat_send_all('newroll: '.. newroll)
        ---------------------------------
        -- end roll

        accel.y = accel_y
        newpitch = velocity.y * math.rad(1.5)

        --lets do some bob and set acceleration
		local bob = phishing_boat.minmax(phishing_boat.dot(accel,hull_direction),0.5)	-- vertical bobbing
		if self.isinliquid then
            if self._last_rnd == nil then self._last_rnd = math.random(1, 3) end
            if self._last_water_touch == nil then self._last_water_touch = self._last_rnd end
            if self._last_water_touch <= self._last_rnd then
                self._last_water_touch = self._last_water_touch + self.dtime
            end
            if math.abs(bob) > 0.1 and self._last_water_touch >=self._last_rnd then
                self._last_rnd = math.random(1, 3)
                self._last_water_touch = 0
                minetest.sound_play("default_water_footstep", {
                    --to_player = self.driver_name,
                    object = self.object,
                    max_hear_distance = 15,
                    gain = 0.07,
                    fade = 0.0,
                    pitch = 1.0,
                }, true)
            end

			accel.y = accel_y + bob
			newpitch = velocity.y * math.rad(6)

            self.object:set_acceleration(accel)
		end

        phishing_boat.engine_set_sound_and_animation(self)

        --time for rotations
        self.object:set_rotation({x=newpitch,y=newyaw,z=newroll})

        self.object:set_bone_position("rudder", {x=0,y=0,z=0}, {x=0,y=self._rudder_angle,z=0})
        self.object:set_bone_position("timao", {x=0,y=7.06,z=15}, {x=0,y=0,z=self._rudder_angle*8})

        local N_angle = math.deg(newyaw)
        local S_angle = N_angle + 180

        self.object:set_bone_position("compass_axis", {x=0,y=11.3,z=19.2}, {x=0, y=S_angle, z=0}) -- y 19.24    z 11.262

        --saves last velocy for collision detection (abrupt stop)
        self._last_vel = self.object:get_velocity()
        self._last_accell = accel

        phishing_boat.move_persons(self)
    end,

    on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
        if not puncher or not puncher:is_player() then
            return
        end
        local is_admin = false
        is_admin = minetest.check_player_privs(puncher, {server=true})
		local name = puncher:get_player_name()
        if self.owner and self.owner ~= name and self.owner ~= "" then
            if is_admin == false then return end
        end
        if self.owner == nil then
            self.owner = name
        end
            
        if self.driver_name and self.driver_name ~= name then
            -- do not allow other players to remove the object while there is a driver
            return
        end
        
        local is_attached = phishing_boat.checkAttach(self, puncher)

        local itmstck=puncher:get_wielded_item()
        local item_name = ""
        if itmstck then item_name = itmstck:get_name() end

        if is_attached == true then
            --refuel
            phishing_boat.load_fuel(self, puncher)
        end

        -- deal with painting or destroying
        if itmstck then
            local _,indx = item_name:find('dye:')
            if indx then

                --lets paint!!!!
                local color = item_name:sub(indx+1)
                local colstr = phishing_boat.colors[color]
                --minetest.chat_send_all(color ..' '.. dump(colstr))
                if colstr and (name == self.owner or minetest.check_player_privs(puncher, {protection_bypass=true})) then
                    local ctrl = puncher:get_player_control()
                    if ctrl.aux1 then
                        phishing_boat.paint2(self, colstr)
                    else
                        phishing_boat.paint1(self, colstr)
                    end
                    itmstck:set_count(itmstck:get_count()-1)
                    puncher:set_wielded_item(itmstck)
                end
                return
                -- end painting
            end
        end

        if is_attached == false then
            local i = 0
            local has_passengers = false
            for i = phishing_boat.max_seats,1,-1 
            do 
                if self._passengers[i] ~= nil then
                    has_passengers = true
                    break
                end
            end


            if not has_passengers and toolcaps and toolcaps.damage_groups and
                    toolcaps.damage_groups.fleshy then
                --airutils.hurt(self,toolcaps.damage_groups.fleshy - 1)
                --airutils.make_sound(self,'hit')
                self.hp = self.hp - 10
                minetest.sound_play("collision", {
                    object = self.object,
                    max_hear_distance = 5,
                    gain = 1.0,
                    fade = 0.0,
                    pitch = 1.0,
                })
            end

            if self.hp <= 0 then
                phishing_boat.destroy(self, false)
            end

        end
        
    end,

    on_rightclick = function(self, clicker)
        local message = ""
		if not clicker or not clicker:is_player() then
			return
		end

        local name = clicker:get_player_name()

        if self.owner == "" then
            self.owner = name
        end

        local touching_ground, liquid_below = airutils.check_node_below(self.object, 2.5)
        local is_on_ground = self.isinliquid or touching_ground or liquid_below
        local is_under_water = airutils.check_is_under_water(self.object)

        --minetest.chat_send_all('passengers: '.. dump(self._passengers))
        --=========================
        --  form to pilot
        --=========================
        local is_attached = false
        local seat = clicker:get_attach()
        if seat then
            local plane = seat:get_attach()
            if plane == self.object then is_attached = true end
        end

        --check error after being shot for any other mod
        if is_attached == false then
            for i = phishing_boat.max_seats,1,-1 
            do 
                if self._passengers[i] == name then
                    self._passengers[i] = nil --clear the wrong information
                    break
                end
            end
        end

        --shows pilot formspec
        if name == self.driver_name then
            if is_attached then
                phishing_boat.pilot_formspec(name)
            else
                self.driver_name = nil
            end
        --=========================
        --  attach passenger
        --=========================
        else
            local pass_is_attached = phishing_boat.check_passenger_is_attached(self, name)

            if pass_is_attached then
                local can_bypass = minetest.check_player_privs(clicker, {protection_bypass=true})
                if clicker:get_player_control().aux1 == true then --lets see the inventory
                    local is_shared = false
                    if name == self.owner or can_bypass then is_shared = true end
                    for k, v in pairs(self._shared_owners) do
                        if v == name then
                            is_shared = true
                            break
                        end
                    end
                    if is_shared then
                        airutils.show_vehicle_trunk_formspec(self, clicker, phishing_boat.trunk_slots)
                    end
                else
                    if self.driver_name ~= nil and self.driver_name ~= "" then
                        --lets take the control by force
                        if name == self.owner or can_bypass then
                            --require the pilot position now
                            phishing_boat.owner_formspec(name)
                        else
                            phishing_boat.pax_formspec(name)
                        end
                    else
                        --check if is on owner list
                        local is_shared = false
                        if name == self.owner or can_bypass then is_shared = true end
                        for k, v in pairs(self._shared_owners) do
                            if v == name then
                                is_shared = true
                                break
                            end
                        end
                        --normal user
                        if is_shared == false then
                            phishing_boat.pax_formspec(name)
                        else
                            --owners
                            phishing_boat.pilot_formspec(name)
                        end
                    end
                end
            else
                --first lets clean the boat slots
                --note that when it happens, the "rescue" function will lost the historic
                for i = phishing_boat.max_seats,1,-1 
                do 
                    if self._passengers[i] ~= nil then
                        local old_player = minetest.get_player_by_name(self._passengers[i])
                        if not old_player then self._passengers[i] = nil end
                    end
                end
                --attach normal passenger
                --if self._door_closed == false then
                    phishing_boat.attach_pax(self, clicker)
                --end
            end
        end

    end,
})
