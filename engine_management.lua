function phishing_boat.engineSoundPlay(self)
    --sound
    if self.sound_handle then minetest.sound_stop(self.sound_handle) end
    if self.object then
        self.sound_handle = minetest.sound_play({name = "phishing_boat_engine"},
            {object = self.object, gain = 1.0,
                pitch = 0.5 + ((math.abs(self._power_lever)/100)/2),
                max_hear_distance = 32,
                loop = true,})
    end
end

function phishing_boat.engine_set_sound_and_animation(self)
    --minetest.chat_send_all('test1 ' .. dump(self._engine_running) )
    if self._engine_running then
        if self._last_applied_power ~= self._power_lever then
            if self._last_applied_power == -100 then
                phishing_boat.engineSoundPlay(self)
            end
            --minetest.chat_send_all('test2')
            local factor = 0.5
            if (math.abs(self._power_lever) > math.abs(self._last_applied_power) + factor) or (math.abs(self._power_lever) + factor < math.abs(self._last_applied_power)) then
                phishing_boat.engineSoundPlay(self)
            end
            self._last_applied_power = self._power_lever
        end
        self.object:set_animation_frame_speed(self._power_lever * 2)

        -- calculate energy consumption --
        ----------------------------------
        if self._energy > 0 and self._last_accell then
            local zero_reference = vector.new()
            local acceleration = phishing_boat.get_hipotenuse_value(self._last_accell, zero_reference)
            local consumed_power = acceleration/6000
            self._energy = self._energy - consumed_power;
        end
        if self._energy <= 0 and self._engine_running then
            self._engine_running = false
            if self.sound_handle then minetest.sound_stop(self.sound_handle) end
		    self.object:set_animation_frame_speed(0)
        end
        ----------------------------
        -- end energy consumption --
    else
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end
        self._last_applied_power = -100 --to force the sound to start when activated again
        self._power_lever = 0
        self.object:set_animation_frame_speed(0)
    end
end


