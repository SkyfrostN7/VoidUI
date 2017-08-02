if RequiredScript == "lib/managers/hudmanager" then
	
	local load_hud = HUDManager.load_hud
	function HUDManager:load_hud(...)
		load_hud(self, ...)
		if self:alive("guis/mask_off_hud") then
			self:script("guis/mask_off_hud").mask_on_text:set_font_size(0)
		end
	end
	local sync_start_anticipation_music = HUDManager.sync_start_anticipation_music
	function HUDManager:sync_start_anticipation_music()
		sync_start_anticipation_music(self)
		managers.hud:assault_anticipation()
	end
	
	local add_waypoint = HUDManager.add_waypoint
	function HUDManager:add_waypoint(id, data)
		add_waypoint(self, id, data)
		
		if self._hud.waypoints[id] then
			local scale = HeistHUD.options.waypoint_scale
			local bitmap = self._hud.waypoints[id].bitmap
			local arrow = self._hud.waypoints[id].arrow
			local distance = self._hud.waypoints[id].distance
			local text = self._hud.waypoints[id].text
			local timer = self._hud.waypoints[id].timer_gui
			
			bitmap:set_size(bitmap:w() * scale, bitmap:h() * scale)
			arrow:set_size(arrow:w() * scale, arrow:h() * scale)
			text:set_font_size(text:font_size() * scale)
			text:set_size(text:w() * scale, text:h() * scale)
			self._hud.waypoints[id].size = Vector3(bitmap:w(), bitmap:h(), 0)
			self._hud.waypoints[id].radius = HeistHUD.options.waypoint_radius
			
			if data.distance then
				distance:set_font_size(distance:font_size() * scale)
				distance:set_size(distance:w() * scale, distance:h() * scale)
			end
			if data.timer then
				timer:set_size(timer:w() * scale, timer:h() * scale)
				timer:set_font_size(timer:font_size() * scale)
			end
		end
	end
	
	local change_waypoint_icon = HUDManager.change_waypoint_icon
	function HUDManager:change_waypoint_icon(id, icon)
		change_waypoint_icon(self, id, icon)
		
		if self._hud.waypoints[id] then
			local scale = HeistHUD.options.waypoint_scale
			local bitmap = self._hud.waypoints[id].bitmap
			bitmap:set_size(bitmap:w() * scale, bitmap:h() * scale)
			self._hud.waypoints[id].size = Vector3(bitmap:w(), bitmap:h(), 0)
		end
	end

	function HUDManager:update_name_label_by_peer(peer)
		for _, data in pairs(self._hud.name_labels) do
			if data.peer_id == peer:id() then
				local name = data.character_name
				local experience = ""
				if peer:level() then
					experience = (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "Ї" or "") .. peer:level() .. " "
					name =  experience .. name
				end
				data.text:set_text(name)
				data.text:set_range_color(0, utf8.len(experience), Color.white) 
				self:align_teammate_name_label(data.panel, data.interact)
			else
			end
		end
	end

	function HUDManager:update_vehicle_label_by_id(label_id, num_players)
		for _, data in pairs(self._hud.name_labels) do
			if data.id == label_id then
				local name = data.character_name
				data.text:set_text(name)
				self:align_teammate_name_label(data.panel, data.interact)
			else
			end
		end
	end
	
	local update_waypoints = HUDManager._update_waypoints
	function HUDManager:_update_waypoints(t, dt)
		update_waypoints(self, t, dt)
		local cam = managers.viewport:get_current_camera()
		if not cam then
			return
		end
		
		local wp_pos = Vector3()
		local wp_onscreen_direction = Vector3()
		
		for id, data in pairs(self._hud.waypoints) do
			if data.state == "offscreen" then
					local panel = data.bitmap:parent()
					mvector3.set(wp_pos, self._saferect:world_to_screen(cam, data.position))
					local show = HeistHUD.options.label_waypoint_offscreen
					data.bitmap:set_visible(show)
					data.arrow:set_visible(show)
					data.text:set_visible(show)
					
					local direction = wp_onscreen_direction
					local panel_center_x, panel_center_y = panel:center()
					local scale = HeistHUD.options.waypoint_scale
					mvector3.set_static(direction, wp_pos.x - panel_center_x, wp_pos.y - panel_center_y, 0)
					mvector3.normalize(direction)
					data.arrow:set_center(mvector3.x(data.current_position) + direction.x * (24 * scale), mvector3.y(data.current_position) + direction.y * (24 * scale))
			elseif data.state == "onscreen" and not HeistHUD.options.label_waypoint_offscreen then
				data.bitmap:set_visible(true)
				data.text:set_visible(true)
			end
		end
	end
	
	local update_name_labels = HUDManager._update_name_labels
	function HUDManager:_update_name_labels(t, dt)	
		local cam = managers.viewport:get_current_camera()
		if not cam then
			return
		end
		update_name_labels(self, t, dt)
		
		local nl_w_pos = Vector3()
		local nl_dir = Vector3()
		local nl_dir_normalized = Vector3()
		local nl_cam_forward = Vector3()
		local cam_pos = managers.viewport:get_current_camera_position()
		local cam_rot = managers.viewport:get_current_camera_rotation()
		mrotation.y(cam_rot, nl_cam_forward)
		
		for _, data in ipairs(self._hud.name_labels) do
			local pos
			if data.movement then
				if not alive(data.movement._unit) then
					label_panel:set_visible(false)
				else
					pos = data.movement:m_pos()
					mvector3.set(nl_w_pos, pos)
					mvector3.set_z(nl_w_pos, mvector3.z(data.movement:m_head_pos()) + 30)
				end
			elseif data.vehicle then
				if not alive(data.vehicle) then
					return
				end
				pos = data.vehicle:position()
				mvector3.set(nl_w_pos, pos)
				mvector3.set_z(nl_w_pos, pos.z + data.vehicle:vehicle_driving().hud_label_offset)
			end
			if HeistHUD.options.label_minmode and pos then
				mvector3.set(nl_dir, nl_w_pos)
				mvector3.subtract(nl_dir, cam_pos)
				mvector3.set(nl_dir_normalized, nl_dir)
				mvector3.normalize(nl_dir_normalized)
				
				local dot = mvector3.dot(nl_cam_forward, nl_dir_normalized)
				local unit = data.vehicle and data.vehicle or data.movement._unit and data.movement._unit
				local dis = alive(unit) and mvector3.distance(unit:position(), cam_pos) or 0
				local label_panel = data.panel
				if math.ceil(dis / 100) > HeistHUD.options.label_minmode_dist and math.clamp((1 - dot) * 100, 0, HeistHUD.options.label_minmode_dot) == HeistHUD.options.label_minmode_dot then
					label_panel:child("minmode_panel"):set_visible(true)
					label_panel:child("extended_panel"):set_visible(false)
				else
					label_panel:child("minmode_panel"):set_visible(false)
					label_panel:child("extended_panel"):set_visible(true)
				end
			else
				data.panel:child("minmode_panel"):set_visible(false)
				data.panel:child("extended_panel"):set_visible(true)
			end
		end
	end
	
elseif RequiredScript == "lib/managers/hudmanagerpd2" then

	function HUDManager:_create_teammates_panel(hud)
		hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		self._hud.teammate_panels_data = self._hud.teammate_panels_data or {}
		self._teammate_panels = {}
		if hud.panel:child("teammates_panel") then
			hud.panel:remove(hud.panel:child("teammates_panel"))
		end
		local h = self:teampanels_height() * 2
		self._main_scale = HeistHUD.options.hud_main_scale and HeistHUD.options.hud_main_scale or 1
		self._mate_scale = HeistHUD.options.hud_mate_scale and HeistHUD.options.hud_mate_scale or 1
		local teammates_panel = hud.panel:panel({
			name = "teammates_panel",
			h = h,
			y = hud.panel:h() - h,
			halign = "grow",
			valign = "bottom"
		})
		for i = 1, 4 do
			local is_player = i == HUDManager.PLAYER_PANEL
			self._hud.teammate_panels_data[i] = {
				taken = false,
				special_equipments = {}
			}

			local teammate = HUDTeammate:new(i, teammates_panel, is_player, teammates_panel:w())
			if is_player then
				teammate._panel:set_w(220 * self._main_scale)
				teammate._panel:set_right(teammates_panel:right())
			else
				teammate._panel:set_w(154 * self._mate_scale)
				teammate._panel:set_left(teammates_panel:left() + ((i - 1) * teammate._panel:w()) + (2 * (i - 1))* self._mate_scale)
			end
			table.insert(self._teammate_panels, teammate)
			if is_player then
				teammate:add_panel()
			end
		end
		
	end
	
	HUDManager.align_teammate_panels = HUDManager.align_teammate_panels or function(self)
		for i, data in ipairs(self._hud.teammate_panels_data) do
			if i ~= HUDManager.PLAYER_PANEL then
				local panel = self._teammate_panels[i]
				if panel:ai() or panel:peer_id() then panel._panel:set_w((panel:ai() and 51 or 154) * self._mate_scale)
				else panel._panel:set_w(0) end
				if i ~= 1 then
					panel._panel:set_x(self._teammate_panels[i - 1]._panel:right() + 2 * self._mate_scale)
				end
			end
		end
	end

	function HUDManager:teammate_progress(peer_id, type_index, enabled, tweak_data_id, timer, success)
		local name_label = self:_name_label_by_peer_id(peer_id)
		if name_label then
			name_label.interact:set_visible(enabled)
			name_label.panel:child("extended_panel"):child("action"):set_visible(enabled)
			name_label.panel:child("extended_panel"):child("interact_bg"):set_visible(enabled)
			name_label.panel:child("minmode_panel"):child("min_interact"):set_visible(enabled)
			name_label.panel:child("minmode_panel"):child("min_interact_bg"):set_visible(enabled)
			local action_text = ""
			if type_index == 1 then
				action_text = managers.localization:text(tweak_data.interaction[tweak_data_id].action_text_id or "hud_action_generic")
			elseif type_index == 2 then
				if enabled then
					local equipment_name = managers.localization:text(tweak_data.equipments[tweak_data_id].text_id)
					local deploying_text = tweak_data.equipments[tweak_data_id].deploying_text_id and managers.localization:text(tweak_data.equipments[tweak_data_id].deploying_text_id) or false
					action_text = deploying_text or managers.localization:text("hud_deploying_equipment", {EQUIPMENT = equipment_name})
				end
			elseif type_index == 3 then
				action_text = managers.localization:text("hud_starting_heist")
			end
			name_label.panel:child("extended_panel"):child("action"):set_text(action_text .. string.format(" (%.1fs)", timer))
			name_label.panel:child("extended_panel"):stop()
			if enabled then
				name_label.panel:animate(callback(self, self, "_animate_label_interact"), name_label.interact, name_label.panel:child("minmode_panel"):child("min_interact"), name_label.panel:child("extended_panel"):child("interact_bg"), name_label.panel:child("minmode_panel"):child("min_interact_bg"), name_label.panel:child("extended_panel"):child("action"), action_text, timer)
			end
		end
		local character_data = managers.criminals:character_data_by_peer_id(peer_id)
		if character_data then
			self._teammate_panels[character_data.panel_id]:teammate_progress(enabled, type_index, tweak_data_id, timer, success)
		end
	end

	function HUDManager:_animate_label_interact(panel, interact, minmode_interact, interact_bg, minmode_bg, action, action_text, timer)
		local t = 0
		interact:set_x(interact_bg:x())
		while timer >= t do
			local dt = coroutine.yield()
			t = t + dt
			interact:set_w(math.lerp(0, interact_bg:w(), t / timer))
			minmode_interact:set_w(math.lerp(0, minmode_bg:w(), t / timer))
			action:set_text(action_text .. string.format(" (%.1fs)", math.clamp(timer - t, 0, timer)))
		end
		interact:set_w(interact_bg:w())
	end
	function HUDManager:set_ai_stopped(ai_id, stopped)
		local teammate_panel = self._teammate_panels[ai_id]
		if not teammate_panel or stopped and not teammate_panel._ai then
			return
		end
		local panel = teammate_panel._panel:child("custom_player_panel"):child("health_panel")
		local name = teammate_panel._panel:child("custom_player_panel"):child("name") and string.gsub(teammate_panel._panel:child("custom_player_panel"):child("name"):text(), "%W", "")
		local label
		for _, lbl in ipairs(self._hud.name_labels) do
			if string.gsub(lbl.character_name, "%W", "") == name then
				label = lbl
			else
			end
		end
		if stopped then
			local downs_value = panel:child("downs_value")
			local stop_icon = panel:bitmap({
				name = "stopped",
				texture = tweak_data.hud_icons.ai_stopped.texture,
				texture_rect = tweak_data.hud_icons.ai_stopped.texture_rect,
				layer = 6
			})
			stop_icon:set_w(downs_value:w() / 2.2)
			stop_icon:set_h(downs_value:h() / 1.3)
			stop_icon:set_center_x(downs_value:center_x())
			stop_icon:set_top(downs_value:top())
			if label then
				local label_stop_icon = label.panel:child("extended_panel"):bitmap({
					name = "stopped",
					texture = tweak_data.hud_icons.ai_stopped.texture,
					texture_rect = tweak_data.hud_icons.ai_stopped.texture_rect,
					rotation = 360
				})
				label_stop_icon:set_right(label.text:left())
				label_stop_icon:set_center_y(label.text:center_y())
			end
		else
			if panel:child("stopped") then
				panel:remove(panel:child("stopped"))
			end
			if label and label.panel:child("extended_panel"):child("stopped") then
				label.panel:child("extended_panel"):remove(label.panel:child("extended_panel"):child("stopped"))
			end
		end
	end

	function HUDManager:_add_name_label(data)
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)		
		local last_id = self._hud.name_labels[#self._hud.name_labels] and self._hud.name_labels[#self._hud.name_labels].id or 0
		local id = last_id + 1
		local large_scale = HeistHUD.options.label_scale
		local min_scale = HeistHUD.options.label_minscale
		local character_name = data.name
		local rank = 0
		local peer_id
		local is_husk_player = data.unit:base().is_husk_player
		local experience = ""
		local color_id = managers.criminals:character_color_id_by_unit(data.owner_unit and data.owner_unit or data.unit)
		local crim_color = tweak_data.chat_colors[color_id] or tweak_data.chat_colors[#tweak_data.chat_colors]
		if is_husk_player then
			peer_id = data.unit:network():peer():id()
			local level = data.unit:network():peer():level()
			rank = data.unit:network():peer():rank()
			if level then
				experience = (rank > 0 and managers.experience:rank_string(rank) .. "Ї" or "") .. level .. " "
				data.name = experience .. data.name
			end
		end
		local panel = hud.panel:panel({
			name = "name_label" .. id
		})
		panel:text({
			name = "cheater",
			text = managers.localization:text("menu_hud_cheater"),
			font = tweak_data.hud.medium_font,
			font_size = tweak_data.hud.name_label_font_size / 1.3,
			color = tweak_data.screen_colors.pro_color,
			align = "center",
			layer = -1,
			visible = false,
			w = 256,
			h = 18
		})
		local extended_panel = panel:panel({
			name = "extended_panel"
		})
		local interact = extended_panel:bitmap({
			h = 2 * large_scale,
			layer = 0,
			visible = false,
			color = crim_color
		})
		local interact_bg = extended_panel:bitmap({
			name = "interact_bg",
			h = 2 * large_scale,
			color = Color.black,
			visible = false,
			layer = -1
		})
		local text = extended_panel:text({
			name = "text",
			text = data.name,
			font = tweak_data.hud.medium_font,
			font_size = (tweak_data.hud.name_label_font_size / 1.2) * large_scale,
			color = crim_color,
			align = "center",
			vertical = "top",
			layer = -1,
			w = 256 * large_scale,
			h = 18 * large_scale
		})
		text:set_range_color(0, utf8.len(experience), Color.white) 
		local text_shadow = extended_panel:text({
			name = "text_shadow",
			text = data.name,
			font = tweak_data.hud.medium_font,
			font_size = (tweak_data.hud.name_label_font_size / 1.2) * large_scale,
			color = Color.black,
			align = "center",
			vertical = "top",
			layer = -2,
			w = 256,
			h = 18,
			x = 1,
			y = 1,
		})
		
		local bag = extended_panel:bitmap({
			name = "bag",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = {2, 34, 20, 17},
			layer = 0,
			color = crim_color,
			visible = false,
			x = 1,
			y = 1,
			rotation = 360
		})
		extended_panel:text({
			name = "action",
			rotation = 360,
			text = "Fixing",
			font = "fonts/font_medium_shadow_mf",
			font_size = (tweak_data.hud.name_label_font_size / 1.3) * large_scale,
			color = crim_color,
			align = "center",
			vertical = "bottom",
			layer = -1,
			visible = false,
			w = 256,
			h = 18
		})
		local minmode_panel = panel:panel({
			name = "minmode_panel"
		})
		local min_text = minmode_panel:text({
			name = "text",
			text = HeistHUD.options.label_minrank and data.name or character_name,
			font = tweak_data.hud.medium_font,
			font_size = (tweak_data.hud.name_label_font_size / 2) * min_scale,
			color = crim_color,
			align = "center",
			vertical = "top",
			layer = -1,
			w = 100,
			h = 18
		})
		min_text:set_range_color(0, HeistHUD.options.label_minrank and utf8.len(experience) or 0, Color.white) 
		local min_text_shadow = minmode_panel:text({
			name = "text_shadow",
			text = HeistHUD.options.label_minrank and data.name or character_name,
			font = tweak_data.hud.medium_font,
			font_size = (tweak_data.hud.name_label_font_size / 2) * min_scale,
			color = Color.black,
			align = "center",
			vertical = "top",
			layer = -2,
			w = 100,
			h = 18,
			x = 1,
			y = 1,
		})
		local min_interact = minmode_panel:bitmap({
			name = "min_interact",
			h = 2 * min_scale,
			layer = 0,
			visible = false,
			color = crim_color
		})
		local min_interact_bg = minmode_panel:bitmap({
			name = "min_interact_bg",
			h = 2 * min_scale,
			color = Color.black,
			visible = false,
			layer = -1,
			rotation = 360
		})
		local min_bag = minmode_panel:bitmap({
			name = "min_bag",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = {2, 34, 20, 17},
			layer = 0,
			color = crim_color,
			visible = false,
			x = 1,
			y = 1,
			rotation = 360
		})
		
		self:align_teammate_name_label(panel, interact)
		table.insert(self._hud.name_labels, {
			movement = data.unit:movement(),
			panel = panel,
			minmode_panel = minmode_panel,
			text = text,
			id = id,
			peer_id = peer_id,
			character_name = character_name,
			experience = experience,
			interact = interact,
			interact_bg = interact_bg,
			bag = bag
		})
		return id
	end

	function HUDManager:align_teammate_name_label(panel, interact, experience)
		local minmode_panel = panel:child("minmode_panel")
		local extended_panel = panel:child("extended_panel")
		local min_text = minmode_panel:child("text")
		local min_text_shadow = minmode_panel:child("text_shadow")
		local text = extended_panel:child("text")
		local text_shadow = extended_panel:child("text_shadow")
		local action = extended_panel:child("action")
		local bag = extended_panel:child("bag")
		local min_bag = minmode_panel:child("min_bag")
		local bag_number = extended_panel:child("bag_number")
		local min_bag_number = minmode_panel:child("min_bag_number")
		local cheater = panel:child("cheater")
		local interact_bg = extended_panel:child("interact_bg")
		local min_interact = minmode_panel:child("min_interact")
		local min_interact_bg = minmode_panel:child("min_interact_bg")
		local _, _, tw, th = text:text_rect()
		local _, _, aw, ah = action:text_rect()
		local _, _, cw, ch = cheater:text_rect()
		local _, _, mtw, mth = min_text:text_rect()
		
		panel:set_size(math.max(tw, cw, aw), th + ah + ch)
		cheater:set_size(panel:w(), ch)
		cheater:set_position(0, 0)
				
		extended_panel:set_size(panel:w(), panel:h())
		text:set_size(panel:w(), th)
		text_shadow:set_size(panel:w(), th)
		text_shadow:set_x(1)
		text:set_top(cheater:bottom())
		text_shadow:set_y(text:y() + 1)
		interact:set_w(tw)
		interact_bg:set_w(interact:w())
		interact:set_center_x(text:center_x())
		interact_bg:set_center_x(interact:center_x())
		interact:set_bottom(text_shadow:bottom())
		interact_bg:set_y(interact:y())
		action:set_size(panel:w(), ah)
		action:set_y(interact:bottom())
		bag:set_size(th, th * 0.8)
		bag:set_right(panel:left() - 2)
		bag:set_center_y(text:center_y())
		if bag_number then
			bag_number:set_size(bag:w(), bag:h())
			bag_number:set_center(bag:center())
		end
		
		minmode_panel:set_size(panel:w(), mth)
		minmode_panel:set_bottom(text:bottom())
		min_text:set_size(mtw, mth)
		min_text_shadow:set_size(mtw, mth)
		min_text:set_center_x(minmode_panel:center_x())
		min_text_shadow:set_x(min_text:x() + 1)
		min_text:set_y(0)
		min_text_shadow:set_y(1)
		min_interact:set_w(mtw)
		min_interact_bg:set_w(min_interact:w())
		min_interact:set_center_x(min_text:center_x())
		min_interact_bg:set_center_x(interact:center_x())
		min_interact:set_bottom(min_text:bottom())
		min_interact_bg:set_y(min_interact:y())
		min_bag:set_size(mth, mth * 0.8)
		min_bag:set_right(min_text:left() - 2)
		min_bag:set_center_y(min_text:center_y())
		if min_bag_number then
			min_bag_number:set_size(min_bag:w(), min_bag:h())
			min_bag_number:set_center(min_bag:center())
		end
	end

	function HUDManager:add_vehicle_name_label(data)
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
		local last_id = self._hud.name_labels[#self._hud.name_labels] and self._hud.name_labels[#self._hud.name_labels].id or 0
		local id = last_id + 1
		local vehicle_name = data.name
		local crim_color = tweak_data.chat_colors[#tweak_data.chat_colors]
		local panel = hud.panel:panel({
			name = "name_label" .. id
		})
		panel:text({
			name = "cheater",
			text = managers.localization:text("menu_hud_cheater"),
			font = tweak_data.hud.medium_font,
			font_size = tweak_data.hud.name_label_font_size / 1.3,
			color = tweak_data.screen_colors.pro_color,
			align = "center",
			layer = -1,
			visible = false,
			w = 256,
			h = 18
		})
		local extended_panel = panel:panel({
			name = "extended_panel"
		})
		local interact = extended_panel:bitmap({
			h = 2,
			layer = 0,
			visible = false,
			color = crim_color
		})
		local interact_bg = extended_panel:bitmap({
			name = "interact_bg",
			h = 2,
			color = Color.black,
			visible = false,
			layer = -1
		})
		local text = extended_panel:text({
			name = "text",
			text = vehicle_name,
			font = tweak_data.hud.medium_font,
			font_size = tweak_data.hud.name_label_font_size / 1.2,
			color = crim_color,
			align = "center",
			vertical = "top",
			layer = -1,
			w = 256,
			h = 18
		})
		text:set_range_color(0, utf8.len(experience), Color.white) 
		local text_shadow = extended_panel:text({
			name = "text_shadow",
			text = vehicle_name,
			font = tweak_data.hud.medium_font,
			font_size = tweak_data.hud.name_label_font_size / 1.2,
			color = Color.black,
			align = "center",
			vertical = "top",
			layer = -2,
			w = 256,
			h = 18,
			x = 1,
			y = 1,
		})
		
		local bag = extended_panel:bitmap({
			name = "bag",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = {2, 34, 20, 17},
			layer = 0,
			color = crim_color,
			visible = false,
			x = 1,
			y = 1,
			alpha = 0.5,
			rotation = 360
		})
		local bag_number = extended_panel:text({
			name = "bag_number",
			visible = false,
			text = utf8.to_upper(""),
			font = "fonts/font_medium_shadow_mf",
			font_size = tweak_data.hud.small_name_label_font_size,
			color = Color.white,
			align = "center",
			vertical = "center",
			layer = 1,
			w = bag:w(),
			h = bag:h(),
			rotation = 360
		})
		extended_panel:text({
			name = "action",
			rotation = 360,
			text = "Fixing",
			font = "fonts/font_medium_shadow_mf",
			font_size = tweak_data.hud.name_label_font_size / 1.3,
			color = crim_color,
			align = "center",
			vertical = "bottom",
			layer = -1,
			visible = false,
			w = 256,
			h = 18
		})
		local minmode_panel = panel:panel({
			name = "minmode_panel"
		})
		local min_text = minmode_panel:text({
			name = "text",
			text = vehicle_name,
			font = tweak_data.hud.medium_font,
			font_size = tweak_data.hud.name_label_font_size / 2,
			color = crim_color,
			align = "center",
			vertical = "top",
			layer = -1,
			w = 100,
			h = 18
		})
		local min_text_shadow = minmode_panel:text({
			name = "text_shadow",
			text = vehicle_name,
			font = tweak_data.hud.medium_font,
			font_size = tweak_data.hud.name_label_font_size / 2,
			color = Color.black,
			align = "center",
			vertical = "top",
			layer = -2,
			w = 100,
			h = 18,
			x = 1,
			y = 1,
		})
		local min_interact = minmode_panel:bitmap({
			name = "min_interact",
			h = 1,
			layer = 0,
			visible = false,
			color = crim_color
		})
		local min_interact_bg = minmode_panel:bitmap({
			name = "min_interact_bg",
			h = 1,
			color = Color.black,
			visible = false,
			layer = -1
		})
		local min_bag = minmode_panel:bitmap({
			name = "min_bag",
			texture = "guis/textures/pd2/hud_tabs",
			texture_rect = {2, 34, 20, 17},
			layer = 0,
			color = crim_color,
			visible = false,
			x = 1,
			y = 1,
			alpha = 0.5,
			rotation = 360
		})
		local min_bag_number = minmode_panel:text({
			name = "min_bag_number",
			visible = false,
			text = utf8.to_upper(""),
			font = "fonts/font_medium_shadow_mf",
			font_size = tweak_data.hud.small_name_label_font_size / 1.5,
			color = Color.white,
			align = "center",
			vertical = "center",
			layer = 1,
			w = min_bag:w(),
			h = min_bag:h(),
			rotation = 360
		})
		self:align_teammate_name_label(panel, interact)
		table.insert(self._hud.name_labels, {
			vehicle = data.unit,
			panel = panel,
			text = text,
			id = id,
			character_name = vehicle_name,
			interact = interact,
			bag = bag,
			bag_number = bag_number
		})
		return id
	end

	
	function HUDManager:set_name_label_carry_info(peer_id, carry_id, value)
		local name_label = self:_name_label_by_peer_id(peer_id)
		if name_label then
			name_label.panel:child("extended_panel"):child("bag"):set_visible(true)
			name_label.panel:child("minmode_panel"):child("min_bag"):set_visible(true)
		end
	end
	function HUDManager:set_vehicle_label_carry_info(label_id, value, number)
		local name_label = self:_get_name_label(label_id)
		if name_label then
			name_label.panel:child("extended_panel"):child("bag"):set_visible(value)
			name_label.panel:child("minmode_panel"):child("min_bag"):set_visible(value)
			name_label.panel:child("extended_panel"):child("bag_number"):set_visible(value)
			name_label.panel:child("minmode_panel"):child("min_bag_number"):set_visible(value)
			name_label.panel:child("extended_panel"):child("bag_number"):set_text(number)
			name_label.panel:child("minmode_panel"):child("min_bag_number"):set_text(number)
		end
	end
	function HUDManager:remove_name_label_carry_info(peer_id)
		local name_label = self:_name_label_by_peer_id(peer_id)
		if name_label then
			name_label.panel:child("extended_panel"):child("bag"):set_visible(false)
			name_label.panel:child("minmode_panel"):child("min_bag"):set_visible(false)
		end
	end
	
	local loot_value = HUDManager.loot_value_updated
	function HUDManager:loot_value_updated(...)
		if self._hud_heist_timer then
			self._hud_heist_timer:loot_value_changed()
		end
		return loot_value(self, ...)
	end

	local ext_inventory_changed = HUDManager.on_ext_inventory_changed
	function HUDManager:on_ext_inventory_changed()
		if self._teammate_panels[HUDManager.PLAYER_PANEL] then
			self._teammate_panels[HUDManager.PLAYER_PANEL]:set_bodybags()
			self._teammate_panels[HUDManager.PLAYER_PANEL]:set_info_visible()
		end
		return ext_inventory_changed(self)
	end

	function HUDManager:show_local_player_gear()
		self:show_player_gear(HUDManager.PLAYER_PANEL)
	end

	function HUDManager:hide_player_gear(panel_id)
		if self._teammate_panels[panel_id] and self._teammate_panels[panel_id]:panel() and self._teammate_panels[panel_id]:panel():child("player") then
			local player_panel = self._teammate_panels[panel_id]:panel():child("custom_player_panel")
			player_panel:child("weapons_panel"):set_visible(false)
		end
	end
	function HUDManager:show_player_gear(panel_id)
		if self._teammate_panels[panel_id] and self._teammate_panels[panel_id]:panel() and self._teammate_panels[panel_id]:panel():child("player") then
			local player_panel = self._teammate_panels[panel_id]:panel():child("custom_player_panel")
			player_panel:child("weapons_panel"):set_visible(true)
		end
	end

	HUDManager.assault_anticipation = HUDManager.assault_anticipation or function(self)
		if self._hud_assault_corner then
			self._hud_assault_corner:set_assault_phase()
		end
	end
	
	HUDManager.add_ecm_timer = HUDManager.add_ecm_timer or function(self, unit)
		if unit and unit:base():battery_life() then
			self._jammers = self._jammers or {}
			table.insert(self._jammers, unit)
			self:start_ecm_timer()
		end
	end
	
	HUDManager.start_ecm_timer = HUDManager.start_ecm_timer or function(self)		
		if self._hud_assault_corner and self._jammers and #self._jammers > 0 then
			self._hud_assault_corner:ecm_timer(self._jammers[1]:base():battery_life())
		end
	end
	
	HUDManager.player_downed = HUDManager.player_downed or function(self, i)
		self._teammate_panels[i]:downed()
	end

	HUDManager.player_reset_downs = HUDManager.player_reset_downs or function(self, i)
		self._teammate_panels[i]:reset_downs()
	end

	HUDManager.pager_used = HUDManager.pager_used or function(self)
		if self._hud_assault_corner then
			self._hud_assault_corner:pager_used()
		end
	end
	
elseif RequiredScript == "lib/units/player_team/teamaidamage" then
	
	local apply_damage_orig = TeamAIDamage._apply_damage
	function TeamAIDamage:_apply_damage(attack_data, result)
		local damage_percent, health_subtracted = apply_damage_orig(self, attack_data, result)
		local char_name = managers.criminals:character_name_by_unit(self._unit)
		local i = managers.criminals:character_data_by_name(char_name).panel_id
		managers.hud:set_teammate_health(i, {current = self._health, total = self._HEALTH_INIT})
		return damage_percent, health_subtracted
	end	
	
	local regenerated = TeamAIDamage._regenerated
	function TeamAIDamage:_regenerated()
		regenerated(self)
		local char_name = managers.criminals:character_name_by_unit(self._unit)
		local i = managers.criminals:character_data_by_name(char_name).panel_id
		managers.hud:set_teammate_health(i, {current = self._health, total = self._HEALTH_INIT})
	end

elseif RequiredScript == "core/lib/managers/subtitle/coresubtitlepresenter" then
	
	core:module("CoreSubtitlePresenter")
	function OverlayPresenter:show_text(text, duration)
		local label = self.__subtitle_panel:child("label") or self.__subtitle_panel:text({
			name = "label",
			x = 1,
			y = 1,
			font = self.__font_name,
			font_size = self.__font_size / 1.1,
			color = Color.white,
			align = "center",
			vertical = "bottom",
			layer = 1,
			wrap = true,
			word_wrap = true
		})
		local shadow = self.__subtitle_panel:child("shadow") or self.__subtitle_panel:text({
			name = "shadow",
			x = 2,
			y = 2,
			font = self.__font_name,
			font_size = self.__font_size / 1.1,
			color = Color.black:with_alpha(1),
			align = "center",
			vertical = "bottom",
			layer = 0,
			wrap = true,
			word_wrap = true
		})
		label:set_text(text)
		shadow:set_text(text)		
	end
end