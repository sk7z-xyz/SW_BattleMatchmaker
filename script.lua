-- Battle Matchmaker
-- Version 1.6.3

g_players={}
g_popups={}
g_team_stats={}
g_vehicles={}
g_team_status_dirty=false
g_player_status_dirty=false
g_finish_dirty=false
g_in_game=false
g_in_countdown=false
g_pause=false
g_timer=0
g_remind_interval=3600
g_ui_reset_requested=false
g_flag_radius=300
-- WebMapAddon
g_has_webmap=false
g_webmap_bindings={}
g_tick_count=0
g_iff_vehicles={}
g_iff_freq={[1]=0,[2]=0,[3]=0}
g_group_parents={}  -- {[group_id]=parent_vehicle_id}

function generateIffFreqs()
	for i=1,3 do
		g_iff_freq[i]=math.random(10000,99999)*10+i
	end
	--server.announce('[IFF]','freq generated: '..g_iff_freq[1]..','..g_iff_freq[2]..','..g_iff_freq[3],-1)
end

g_ammo_supply_buttons={
	MG_K={42,50,'mg'},
	MG_AP={45,50,'mg'},
	MG_I={46,50,'mg'},

	LA_K={47,50,'la'},
	LA_HE={48,50,'la'},
	LA_F={49,50,'la'},
	LA_AP={50,50,'la'},
	LA_I={51,50,'la'},

	RA_K={52,25,'ra'},
	RA_HE={53,25,'ra'},
	RA_F={54,25,'ra'},
	RA_AP={55,25,'ra'},
	RA_I={56,25,'ra'},

	HA_K={57,10,'ha'},
	HA_HE={58,10,'ha'},
	HA_F={59,10,'ha'},
	HA_AP={60,10,'ha'},
	HA_I={61,10,'ha'},

	BS_K={62,1,'bs'},
	BS_HE={63,1,'bs'},
	BS_F={64,1,'bs'},
	BS_AP={65,1,'bs'},
	BS_I={66,1,'bs'},

	AS_HE={68,1,'as'},
	AS_F={66,1,'as'},
	AS_AP={70,1,'as'},
}

g_classes={
	ground_light	={hp=300},
	ground_medium	={hp=1200},
	ground_heavy	={hp=2400},
	ground_mega		={hp=3000},
	ground_boss		={hp=20000},
}

g_item_supply_buttons={
	['Take Extinguisher']	={1,10,0,  9},
	['Take Torch']			={1,27,0,400},
	['Take Welder']			={1,26,0,250},
	['Take FlashLight']		={2,15,0,100},
	['Take Binoculars']		={2, 6,0,  0},
	['Take NightVision']	={2,17,0,100},
	['Take Compass']		={2, 8,0,  0},
	['Take FirstAidKit']	={2,11,4,  0},
}

g_settings={
	{
		name='Vehicle HP',
		key='vehicle_hp',
		type='integer',
		min=1,
	},
	{
		name='Vehicle class Enabled',
		key='vehicle_class',
		type='boolean',
	},
	{
		name='Max Vehicle Damage',
		key='max_damage',
		type='integer',
		min=0,
	},
	{
		name='Ammo supply Enabled',
		key='ammo_supply',
		type='boolean',
	},
	{
		name='MG Ammo Count',
		key='ammo_mg',
		type='integer',
		min=-1,
	},
	{
		name='LA Ammo Count',
		key='ammo_la',
		type='integer',
		min=-1,
	},
	{
		name='RA Ammo Count',
		key='ammo_ra',
		type='integer',
		min=-1,
	},
	{
		name='HA Ammo Count',
		key='ammo_ha',
		type='integer',
		min=-1,
	},
	{
		name='BS Ammo Count',
		key='ammo_bs',
		type='integer',
		min=-1,
	},
	{
		name='AS Ammo Count',
		key='ammo_as',
		type='integer',
		min=-1,
	},
	{
		name='Game Time (min)',
		key='game_time',
		type='number',
		min=1,
	},
	{
		name='Order Command Enabled (in battle)',
		key='order_enabled',
		type='boolean',
	},
	{
		name='TPS Enabled (in battle)',
		key='tps_enabled',
		type='boolean',
	},
	{
		name='Nameplate Enabled (in battle)',
		key='nameplate_enabled',
		type='boolean',
	},
	{
		name='Player Damage (in battle)',
		key='player_damage',
		type='boolean',
	},
	{
		name='Show Friends on map',
		key='show_friends',
		type='boolean',
	},
	{
		name='Auto standby',
		key='auto_standby',
		type='boolean',
	},
	{
		name='Auto vehicle cleanup',
		key='gc_vehicle',
		type='boolean',
	},
	{
		name='Auto auth',
		key='auto_auth',
		type='boolean',
	},
	{
		name='Sunk Depth',
		key='sunk_depth',
		type='integer',
		min=0,
	},
}

g_default_teams={
	'RED',
	'BLUE',
	'PINK',
	'YLW',
}

g_temporary_team='Standby'

g_default_savedata={
	vehicle_hp			=property.slider("Vehicle HP", 50, 5000, 10, 50),
	vehicle_class		=property.checkbox("Vehicle class Enabled", false),
	max_damage			=1000,
	ammo_supply			=property.checkbox("Ammo supply Enabled", true),
	ammo_mg				=-1,
	ammo_la				=-1,
	ammo_ra				=-1,
	ammo_ha				=-1,
	ammo_bs				=-1,
	ammo_as				=-1,
	game_time			=property.slider("Game time (min)", 1, 60, 1, 15),
	order_enabled		=property.checkbox("Order Command Enabled (in battle)", true),
	tps_enabled			=property.checkbox("Third Person Enabled (in battle)", true),
	nameplate_enabled	=property.checkbox("Nameplate Enabled (in battle)", true),
	player_damage		=property.checkbox("Player Damage Enabled (in battle)", false),
	show_friends		=property.checkbox("Show Friends on map", true),
	auto_standby		=property.checkbox("Auto Standby after battle", true),
	gc_vehicle			=property.checkbox("Auto vehicle cleanup", true),
	supply_vehicles		={},
	flag_vehicles		={},
	auto_auth			=property.checkbox("Auto Auth", true),
	sunk_depth			=property.slider("Sunk Depth", 0, 200, 1, 1),
	iff_vehicles		={},
}

g_mag_names={}
for i=1,10 do g_mag_names[i]='magazine_'..tostring(i) end

-- Commands --

g_commands={
	{
		name='join',
		auth=true,
		action=function(peer_id, is_admin, is_auth, team_name, target_peer_id)
			if g_in_game and not is_admin then
				announce('Cannot join after game start..', peer_id)
				return
			end
			if not team_name then
				team_name=g_temporary_team
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			join(target_peer_id or peer_id, team_name, is_admin)
		end,
		args={
			{name='team_name', type='string', require=false},
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='leave',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			leave(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='die',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if not g_in_game then
				announce('Cannot die before game start.', peer_id)
				return
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			kill(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='ready',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if g_in_game then
				announce('Cannot ready after game start.', peer_id)
				return
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			ready(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='wait',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if g_in_game then
				announce('Cannot wait after game start.', peer_id)
				return
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			wait(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='order',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			if g_in_game and not g_pause and not g_savedata.order_enabled then
				announce('Cannot order after game start.', peer_id)
				return
			end
			local player=g_players[peer_id]
			if not player then
				announce('Joind player not found. peer_id:'..tostring(peer_id), peer_id)
				return
			end
			if not player.alive then
				announce('Dead player cannot order vehicle.', peer_id)
				return
			end
			local vehicle=findVehicle(player.vehicle_id)
			if not vehicle then
				announce('Vehicle not found.', peer_id)
				return
			end

			server.setGroupPos(vehicle.group_id, getAheadMatrix(peer_id, 2, 8))
			announce('Vehicle orderd.', peer_id)
		end,
	},
	{
		name='start',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			readyAll(peer_id)
		end,
	},
	{
		name='abort',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			if g_in_countdown then
				stopCountdown()
			elseif g_in_game then
				finishGame()
				notify('Game Aborted', 'Game has been aborted by admin.', 6, -1)
			end
		end,
	},
	{
		name='supply',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			if g_in_game and not is_admin then
				announce('Cannot call supply after game start.', peer_id)
				return
			end
			spawnSupply(peer_id)
			announce('supply object deployed.', peer_id)
		end,
	},
	{
		name='delete_supply',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			despawnSupply(peer_id)
		end,
	},
	{
		name='clear_supply',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			clearSupplies()
			clearFlags()
			announce('All supplies cleared.', -1)
		end,
	},
	{
		name='flag',
		admin=true,
		action=function(peer_id, is_admin, is_auth, name)
			spawnFlag(peer_id, name:lower())
		end,
		args={
			{name='name', type='string', require=true},
		},
	},
	{
		name='delete_flag',
		admin=true,
		action=function(peer_id, is_admin, is_auth, name)
			despawnFlag(peer_id, name:lower())
		end,
		args={
			{name='name', type='string', require=true},
		},
	},
	{
		name='clear_flag',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			clearFlags()
			announce('All flags cleared.', -1)
		end,
	},
	{
		name='pause',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			if not g_in_game then
				announce('Cannot pause before game start.', peer_id)
				return
			end
			if g_pause then return end
			g_pause=true
			notify('Timer Operation', 'Game is paused.', 1, -1)
		end,
	},
	{
		name='resume',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			if not g_pause then
				announce('Cannot resume when not in pause.', peer_id)
				return
			end
			g_pause=false
			notify('Timer Operation', 'Game is resumed.', 1, -1)
		end,
	},
	{
		name='add_time',
		admin=true,
		action=function(peer_id, is_admin, is_auth, minute)
			if not g_in_game then
				announce('Cannot add time before game start.', peer_id)
				return
			end
			g_timer=g_timer+(minute*60*60//1|0)
			if g_timer>0 then
				local timerMin=g_timer//3600
				notify('Timer Updated', 'The remaining time has been changed to '..tostring(timerMin)..' minutes', 1, -1)
			end
		end,
		args={
			{name='minute', type='number', require=true},
		},
	},
	{
		name='shuffle',
		admin=true,
		action=function(peer_id, is_admin, is_auth, team_count)
			if g_in_game or g_in_countdown then
				announce('Cannot shuffle after game start.', peer_id)
				return
			end
			shuffle(team_count)
		end,
		args={
			{name='team_count', type='integer', require=true, min=2, max=#g_default_teams},
		},
	},
	{
		name='reset',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			for i,player in pairs(g_players) do
				unregisterPopup(player.popup_name)
			end
			g_players={}
			g_vehicles={}
			g_team_status_dirty=true
			g_player_status_dirty=true
			clearSupplies()
			clearFlags()
			finishGame()
			announce('Reset game.', -1)
		end,
	},
	{
		name='reset_ui',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			renewUiIds()
			announce('Refresh ui ids.', -1)
		end,
	},
	{
		name='set',
		admin=true,
		action=function(peer_id, is_admin, is_auth, key, value)
			if not key then
				showSettingsHelp(peer_id)
				return
			end
			local setting_define=findSetting(key)
			if not setting_define then
				announce('Setting "'..key..'" not found.', peer_id)
				return
			end
			if not value then
				announce('Argument not enough. Except ['..setting_define.type..'].', peer_id)
				return
			end
			local value, is_success=validateArg(setting_define, value, peer_id)
			if not is_success then return end
			g_savedata[setting_define.key]=value
			announce(setting_define.name..' set to '..tostring(value), -1)
		end,
		args={
			{name='key', type='string', require=false},
			{name='value', type='string', require=false},
		},
	},
	{
		name='dismiss',
		admin=true,
		action=function(peer_id, is_admin, is_auth, team_name)
			dismiss(team_name, peer_id)
		end,
		args={
			{name='team_name', type='string', require=true},
		},
	},
	{
		name='iff_create',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			createIffSender(peer_id)
		end,
	},
	{
		name='iff_delete',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			deleteIffSender(peer_id)
		end,
	},
}

g_iff_spawn_positions={
	{2768,   5, -30222},
	{-20750, 5, -30100},
	{-18855, 5,  -5100},
	{10745,  5,  -8500},
}

function createIffSender(peer_id)
	deleteIffSender()
	for _,p in ipairs(g_iff_spawn_positions) do
		local pos=matrix.translation(p[1], p[2], p[3])
		local vehicle_id=spawnAddonVehicle('iff_sender', pos)
		if vehicle_id then
			table.insert(g_iff_vehicles, vehicle_id)
			table.insert(g_savedata.iff_vehicles, vehicle_id)
			announce('IFF sender spawned. vehicle_id='..vehicle_id, peer_id)
		else
			announce('IFF sender spawn failed at '..p[1]..','..p[3], peer_id)
		end
	end
end

function deleteIffSender(peer_id)
	if g_savedata.iff_vehicles and #g_savedata.iff_vehicles>0 then
		for _,vid in ipairs(g_savedata.iff_vehicles) do
			server.despawnVehicle(vid, true)
			for i=#g_iff_vehicles,1,-1 do
				if g_iff_vehicles[i]==vid then table.remove(g_iff_vehicles,i) end
			end
		end
		announce('IFF senders despawned.', peer_id or -1)
		g_savedata.iff_vehicles={}
	else
		if peer_id then
			announce('IFF sender not found.', peer_id)
		end
	end
end

g_command_aliases={
	j='join',
	l='leave',
	r='ready',
	o='order',
}

function findCommand(command)
	command=g_command_aliases[command] or command
	for i,command_define in ipairs(g_commands) do
		if command_define.name==command then
			return command_define
		end
	end
end

function findSetting(key)
	for i,setting_define in ipairs(g_settings) do
		if setting_define.key==key then
			return setting_define
		end
	end
end


function showHelp(peer_id, is_admin, is_auth)
	local commands_help='Commands:\n'
	local any_commands=false
	for i,command_define in ipairs(g_commands) do
		if checkAuth(command_define, is_admin, is_auth) then
			local args=''
			if command_define.args then
				for i,arg in ipairs(command_define.args) do
					if arg.require then
						args=args..' ['..arg.name..']'
					else
						args=args..' ('..arg.name..')'
					end
				end
			end
			commands_help=commands_help..'  - ?mm '..command_define.name..args..'\n'
			any_commands=true
		end
	end
	if any_commands then
		announce(commands_help, peer_id)
	else
		announce('Permitted command is not found.', peer_id)
	end
end

function showSettings(peer_id)
	local settings_help='Settings:\n'
	for i,setting_define in ipairs(g_settings) do
		local value=g_savedata[setting_define.key]
		settings_help=settings_help..'  - '..setting_define.name..': '..tostring(value)..'\n'
	end
	announce(settings_help, peer_id)
end

function showSettingsHelp(peer_id)
	local settings_help='Setting commands:\n'
	for i,setting_define in ipairs(g_settings) do
		settings_help=settings_help..'  - ?mm set '..setting_define.key..': ['..setting_define.type..']\n'
	end
	announce(settings_help, peer_id)
end

function checkAuth(command, is_admin, is_auth)
	return is_admin or (not command.admin and (is_auth or not command.auth))
end

function checkTargetPeerId(target_peer_id, peer_id, is_admin)
	if not target_peer_id then return true end
	if not is_admin then
		announce('Permission denied. Only admin can specify target_peer_id.', peer_id)
		return false
	end
	local _, is_success=server.getPlayerName(target_peer_id)
	if not is_success then
		announce('Invalid peer_id.', peer_id)
		return false
	end
	return true
end

-- Callbacks --

function onCreate(is_world_create)
	for k,v in pairs(g_default_savedata) do
		if g_savedata[k]==nil then
			g_savedata[k]=v
		end
	end

	g_iff_vehicles=g_savedata.iff_vehicles

	if is_world_create then
		createIffSender(0)
	end

	clearSupplies()
	clearFlags()
	generateIffFreqs()

	registerPopup('countdown', 0, 0.6)
	registerPopup('game_time', -0.9, -0.9)

	setSettingsToStandby()
	

	-- WebMapAddonDetectCheck
	local addon_count = server.getAddonCount()
	for addon_index=0,addon_count-1 do
		local addon_data = server.getAddonData(addon_index)
		local addon_name = string.lower(addon_data.name)
		if addon_name == 'webmap' then
			g_has_webmap=true
			announce('Webmap addon detected!', 0)
			break
		end
	end
end

function onDestroy()
	clearPopups()
	clearSupplies()
	clearFlags()
end

function onTick()
	if g_ui_reset_requested then
		g_ui_reset_requested=false
		renewUiIds()
	end

	for i=#g_vehicles,1,-1 do
		updateVehicle(g_vehicles[i])
	end

	if g_in_countdown then
		if g_timer>0 then
			local sec=g_timer//60
			g_timer=g_timer-1
			g_countdown_text=string.format('Start in\n%.0f', sec)
			setPopup('countdown', true, string.format('Start in\n%.0f', sec))
		else
			startGame()
			local sec=g_timer//60
			local time_text=string.format('%02.f:%02.f left.', sec//60,sec%60)
			notify('Game Start', time_text, 9, -1)
		end
	end
	if g_in_game then
		if g_pause then
		elseif g_timer>0 then
			local sec=g_timer//60
			g_timer=g_timer-1
			local time_text=string.format('%02.f:%02.f', sec//60,sec%60)
			setPopup('game_time', true, time_text)

			if g_timer>0 and g_timer%g_remind_interval==0 then
				server.notify(-1, 'Time Reminder', time_text..' left.', 1)
			end
		else
			finishGame()
			notify('Game End', 'Timeup!', 9, -1)
		end
	end

	if g_finish_dirty then
		g_finish_dirty=false
		checkFinish()
	end

	if g_team_status_dirty then
		g_team_status_dirty=false
		updateTeamStatus()
	end

	if g_player_status_dirty then
		g_player_status_dirty=false
		updatePlayerStatus()
		updatePlayerMapObject()
	end

	updatePopups()

	-- チームビークル座標の収集（毎tick）・出力（60tickに1回）
	local team_vehicle_positions={}
	for peer_id,player in pairs(g_players) do
		if player.alive and player.vehicle_id>=0 then
			local team=player.team
			if not team_vehicle_positions[team] then
				team_vehicle_positions[team]={}
			end
			if #team_vehicle_positions[team]<10 then
				local vehicle_trans,is_success=server.getVehiclePos(player.vehicle_id)
				if is_success then
					local x,h,y=matrix.position(vehicle_trans)
					table.insert(team_vehicle_positions[team],{vehicle_id=player.vehicle_id,x=x,h=h,y=y})
				end
			end
		end
	end

	-- 名前トークン送受信（毎tick）
	for _,positions in pairs(team_vehicle_positions) do
		for _,pos in ipairs(positions) do
			local vid=pos.vehicle_id
			local name_token=NAME_PAD
			local tx=g_name_tx[vid]
			if tx then
				name_token=tx.tokens[tx.idx] or NAME_PAD
				tx.idx=tx.idx+1
			end
			local f1,f2=encodeCoords(pos.x,pos.h,pos.y,name_token)
			pos.f1,pos.f2=f1,f2
			local ok,dx,dh,dy,dt=decodeCoords(f1,f2)
			if ok then
				pos.dx,pos.dh,pos.dy=dx,dh,dy
				local rx=g_name_rx[vid]
				if not rx then rx={state='idle',buf={}} g_name_rx[vid]=rx end
				if dt==NAME_START then
					rx.state='recv'
					rx.buf={}
				elseif dt==NAME_END then
					if rx.state=='recv' then
						g_decoded_names[vid]=table.concat(rx.buf)
					end
					rx.state='idle'
				elseif dt~=NAME_PAD and rx.state=='recv' then
					local ch=tokenToNameChar(dt)
					if ch then rx.buf[#rx.buf+1]=ch end
				end
			end
		end
	end

	-- IFF キーパッド更新（毎tick）
	if #g_iff_vehicles>0 then
		for _,iff_vid in ipairs(g_iff_vehicles) do
			for team_idx,team_name in ipairs(g_default_teams) do
				if team_idx>3 then break end
				local base=(team_idx-1)*100
				local positions=team_vehicle_positions[team_name] or {}
				local count=0
				for i=1,math.min(#positions,10) do
					local pos=positions[i]
					local f1,f2=pos.f1,pos.f2
					if not f1 then
						f1,f2=encodeCoords(pos.x,pos.h,pos.y)
					end
					count=count+1
					server.setVehicleKeypad(iff_vid,tostring(base+count),f1)
					count=count+1
					server.setVehicleKeypad(iff_vid,tostring(base+count),f2)
				end
				for slot=count+1,20 do
					server.setVehicleKeypad(iff_vid,tostring(base+slot),0)
				end
				server.setVehicleKeypad(iff_vid,'mm_iff_freq_'..team_idx,g_iff_freq[team_idx])

			end
		end
	end
	-- プレイヤービークルに周波数書込み（毎tick）
	for _,player in pairs(g_players) do
		if player.alive and player.vehicle_id>=0 then
			for team_idx,team_name in ipairs(g_default_teams) do
				if team_name==player.team and team_idx<=3 then
					server.setVehicleKeypad(player.vehicle_id,'mm_iff_freq',g_iff_freq[team_idx])
					break
				end
			end
		end
	end

	g_tick_count=g_tick_count+1
	if g_tick_count>=60 then
		g_tick_count=0
		for team,positions in pairs(team_vehicle_positions) do
			local text='['..team..']\n'
			for i,pos in ipairs(positions) do
				text=text..string.format(' #%d vid=%d\n  raw  x=%.0f h=%.0f y=%.0f\n',i,pos.vehicle_id,pos.x,pos.h,pos.y)
				if pos.dx then
					text=text..string.format('  dec  x=%.0f h=%.0f y=%.0f\n  f1=%g f2=%g\n',pos.dx,pos.dh,pos.dy,pos.f1,pos.f2)
				else
					text=text..'  decode failed\n'
				end
				local dname=g_decoded_names[pos.vehicle_id]
				if dname then
					text=text..'  name='..dname..'\n'
				end
			end
			--server.announce('[VehiclePos]',text,-1)
		end
		-- 次サイクルのTXキュー構築
		g_name_tx={}
		for peer_id,player in pairs(g_players) do
			if player.alive and player.vehicle_id>=0 then
				local tokens=buildNameTokens(player.name)
				g_name_tx[player.vehicle_id]={tokens=tokens,idx=1}
			end
		end
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	g_ui_reset_requested=true

	if not is_auth and g_savedata.auto_auth then
		server.addAuth(peer_id)
	end
end

function onPlayerLeave(steam_id, name, peer_id, admin, auth)
	peer_id=peer_id//1|0
	leave(peer_id)
	despawnSupply(peer_id)
end

function onPlayerDie(steam_id, name, peer_id, is_admin, is_auth)
	peer_id=peer_id//1|0
	kill(peer_id)
end

function onButtonPress(vehicle_id, peer_id, button_name)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	if not peer_id or peer_id<0 then return end
	local character_id, is_success=server.getPlayerCharacterID(peer_id)
	if not is_success then return end

	if button_name=='?mm die' then
		kill(peer_id)
		return
	elseif button_name=='?mm ready' then
		ready(peer_id)
		return
	end

	if isSupply(vehicle_id) then
		if not server.getVehicleButton(vehicle_id, button_name).on then return end
		local item_supply=g_item_supply_buttons[button_name]
		if item_supply then
			local slot,equipment_id,v1,v2=table.unpack(item_supply)
			slot=findEmptySlot(character_id, slot)
			if not slot then
				announce('Inventory is full.', peer_id)
				return
			end
			server.setCharacterItem(character_id, slot, equipment_id, false, v1, v2)
		elseif button_name=='Join RED' then
			join(peer_id, 'RED')
		elseif button_name=='Join BLUE' then
			join(peer_id, 'BLUE')
		elseif button_name=='Join PINK' then
			join(peer_id, 'PINK')
		elseif button_name=='Join YLW' then
			join(peer_id, 'YLW')
		elseif button_name=='Leave' then
			leave(peer_id)
		elseif button_name=='Clear Large Equipment' then
			server.setCharacterItem(character_id, 1, 0, false)
		elseif button_name=='Clear Small Equipments' then
			for i=2,9 do
				server.setCharacterItem(character_id, i, 0, false)
			end
		elseif button_name=='Clear Outfit' then
			server.setCharacterItem(character_id, 10, 0, false)
		end
		return
	end

	if not g_savedata.ammo_supply then return end

	local equipment_data=g_ammo_supply_buttons[button_name]
	if not equipment_data then return end
	local equipment_id,amount,ammo_type=table.unpack(equipment_data)

	local current_equipment_id=server.getCharacterItem(character_id, 1)
	if current_equipment_id>0 then
		if current_equipment_id~=equipment_id then
			announce('Your large inventory is full.', peer_id)
		end
		return
	end

	local vehicle=findVehicle(vehicle_id)
	if vehicle and vehicle.ammo[ammo_type]==0 then
		announce('Out of ammo.', peer_id)
		return
	end

	server.setCharacterItem(character_id, 1, equipment_id, true, amount)

	if vehicle then
		local remain_ammo=vehicle.ammo[ammo_type]-1
		if remain_ammo>=0 then
			vehicle.ammo[ammo_type]=remain_ammo
			announce('Ammo here! (Remain:'..tostring(remain_ammo)..')', peer_id)
			return
		end
	end
	announce('Ammo here!', peer_id)
end

function onPlayerSit_(peer_id, vehicle_id, seat_name)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	local player=g_players[peer_id]
	if not player or not player.alive then
		return
	end

	local vehicle=registerVehicle(vehicle_id)
	if vehicle and vehicle.alive then
		player.vehicle_id=vehicle_id
		-- WebMapAddon
		if g_has_webmap then
			bindVehicleTeamToWebMap(vehicle_id, player.team)
		end
	end
	g_player_status_dirty=true
end
function onCharacterSit(object_id, vehicle_id, seat_name)
	local peer_id=findPeerIdByCharacterId(object_id)
	onPlayerSit_(peer_id, vehicle_id, seat_name)
end
function findPeerIdByCharacterId(object_id)
	for i,p in ipairs(server.getPlayers()) do
		if object_id==server.getPlayerCharacterID(p.id) then
			return p.id
		end
	end
end


function getParentID(group_id, vehicle_id)
	return g_group_parents[group_id] or vehicle_id
end

function onVehicleDespawn(vehicle_id, peer_id)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	unregisterVehicle(vehicle_id)
	for i=#g_iff_vehicles,1,-1 do
		if g_iff_vehicles[i]==vehicle_id then
			table.remove(g_iff_vehicles,i)
		end
	end
	if g_savedata.iff_vehicles then
		for i=#g_savedata.iff_vehicles,1,-1 do
			if g_savedata.iff_vehicles[i]==vehicle_id then
				table.remove(g_savedata.iff_vehicles,i)
			end
		end
	end
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost, group_id)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	local parent_id=getParentID(group_id, vehicle_id)
	if not g_group_parents[group_id] then
		g_group_parents[group_id]=parent_id
	end
	if vehicle_id==parent_id then
		onPlayerSit_(peer_id, vehicle_id, '')
	end
end

function onVehicleDamaged(vehicle_id, damage_amount, voxel_x, voxel_y, voxel_z, body_index)
	vehicle_id=vehicle_id//1|0
	if not g_in_game then return end
	if damage_amount<=0 then return end

	local vehicle=findVehicle(vehicle_id)
	if not vehicle then return end

	if vehicle.hp then
		vehicle.damage_in_frame=vehicle.damage_in_frame+damage_amount
		g_player_status_dirty=true
	end
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth, command, sub_command, ...)
	peer_id=peer_id//1|0
	if command~='?mm' then return end

	if not sub_command or sub_command=='' then
		showHelp(peer_id, is_admin, is_auth)
		showSettings(peer_id)
		return
	end

	local command_define=findCommand(sub_command)
	if not command_define then
		announce('Command "'..sub_command..'" not found.', peer_id)
		return
	end
	if not checkAuth(command_define, is_admin, is_auth) then
		announce('Permission denied.', peer_id)
		return
	end

	local args={...}
	for i=#args,1,-1 do
		if args[i]=='' then args[i]=nil end
	end
	if command_define.args and not validateArgs(command_define, args, peer_id) then
		return
	end
	command_define.action(peer_id, is_admin, is_auth, table.unpack(args))
end

-- Player Functions --

function join(peer_id, team, force)
	if g_in_game and not force then return end
	local name, is_success=server.getPlayerName(peer_id)
	if not is_success then return end
	local player={
		name=name,
		trimmed_name=trim(name),
		team=team,
		alive=true,
		ready=g_in_game,
		vehicle_id=-1,
		popup_name='player_status_'..(peer_id//1|0),
	}
	g_players[peer_id]=player

	local character_id=server.getPlayerCharacterID(peer_id)
	local vehicle_id, is_success=server.getCharacterVehicle(character_id)
	if is_success then
		local vehicle=registerVehicle(vehicle_id)
		if vehicle and vehicle.alive then
			player.vehicle_id=vehicle_id
			-- WebMapAddon
			if g_has_webmap then
				bindVehicleTeamToWebMap(vehicle_id, team)
			end
		end
	else
		-- WebMapAddon
		-- Currently, it does not work because player.vehicle_id = -1 is set.
		local vehicle=findVehicle(player.vehicle_id)
		if vehicle and vehicle.alive then
			if g_has_webmap then
				bindVehicleTeamToWebMap(vehicle_id, team)
			end
		end
	end

	g_team_status_dirty=true
	g_player_status_dirty=true

	announce('You joined to '..team..'.', peer_id)

	stopCountdown()
end

function leave(peer_id)
	local player=g_players[peer_id]
	if not player then return end
	unregisterPopup(player.popup_name)
	g_players[peer_id]=nil
	g_team_status_dirty=true
	g_player_status_dirty=true

	announce('You leaved from '..player.team..'.', peer_id)

	if g_in_game then
		g_finish_dirty=true
	else
		if player.ready then
			stopCountdown()
		else
			startCountdown()
		end
	end
end

function shuffle(team_count, exec_peer_id)
	local peer_ids={}
	for peer_id,player in pairs(g_players) do
		player.ready=false
		table.insert(peer_ids, peer_id)
	end

	if #peer_ids<1 then
		announce('Player not enough.', exec_peer_id)
		return
	end

	for i=1,#peer_ids do
		local pick=math.random(1, #peer_ids)
		local peer_id=peer_ids[pick]
		local team=g_default_teams[1+(i-1)%team_count]
		g_players[peer_id].team=team
		announce('You joined to '..team..'.', peer_id)
		-- WebMapAddon
		if g_has_webmap then
			local vehicle=findVehicle(g_players[peer_id].vehicle_id)
			if vehicle and vehicle.alive then
				bindVehicleTeamToWebMap(g_players[peer_id].vehicle_id, team)
			end
		end
		table.remove(peer_ids, pick)
	end

	stopCountdown()
	g_team_status_dirty=true
	g_player_status_dirty=true
end

function dismiss(team, peer_id)
	if g_in_game or g_in_countdown then return end

	local remove_peer_ids={}
	for peer_id,p in pairs(g_players) do
		if p.team==team then
			unregisterPopup(p.popup_name)
			table.insert(remove_peer_ids, peer_id)
		end
	end

	if #remove_peer_ids>0 then
		for i=1,#remove_peer_ids do
			g_players[remove_peer_ids[i]]=nil
		end
		g_team_status_dirty=true
		g_player_status_dirty=true
		announce('Team '..team..' dismissed.', peer_id)
	else
		announce('Team '..team..' not found.', peer_id)
	end
end

function kill(peer_id)
	if not g_in_game then return end
	local player=g_players[peer_id]
	if not player or not player.alive then return end
	local vehicle_id=player.vehicle_id
	player.alive=false
	player.vehicle_id=-1
	g_player_status_dirty=true

	if vehicle_id>=0 then
		for _,p in pairs(g_players) do
			if p.alive and p.vehicle_id==vehicle_id then
				vehicle_id=-1
				break
			end
		end
		if vehicle_id>=0 then
			findVehicle(vehicle_id).alive=false
		end
	end

	notify('Kill Log', player.name..' is dead.', 9, -1)
	g_finish_dirty=true
end

function ready(peer_id)
	if g_in_game then return end
	local player=g_players[peer_id]
	if not player then return end
	if not player.alive then
		player.alive=true
		g_player_status_dirty=true
	end
	if not player.ready then
		player.ready=true
		startCountdown()
		g_player_status_dirty=true
	end
end

function readyAll(peer_id)
	if g_in_game then return end
	for peer_id,player in pairs(g_players) do
		if player.alive and not player.ready then
			player.ready=true
		end
	end
	startCountdown(true, peer_id)
	g_player_status_dirty=true
end

function wait(peer_id)
	if g_in_game then return end
	local player=g_players[peer_id]
	if not player then return end
	if not player.alive then
		player.alive=true
		g_player_status_dirty=true
	end
	if player.ready then
		player.ready=false
		g_player_status_dirty=true
		stopCountdown()
	end
end

-- Vehicle Functions --

function findVehicle(vehicle_id)
	for i=1,#g_vehicles do
		local vehicle=g_vehicles[i]
		if vehicle.vehicle_id==vehicle_id then
			return vehicle,i
		end
	end
end

function registerVehicle(vehicle_id)
	local vehicle=findVehicle(vehicle_id)
	if vehicle then return vehicle end

	local data,is_success=server.getVehicleData(vehicle_id)
	if not is_success then return end

	local name=data.name=='' and 'Vehicle' or data.name
	vehicle={
		vehicle_id=vehicle_id,
		group_id=data.group_id,
		alive=true,
		ammo={
			mg=g_savedata.ammo_mg//1|0,
			la=g_savedata.ammo_la//1|0,
			ra=g_savedata.ammo_ra//1|0,
			ha=g_savedata.ammo_ha//1|0,
			bs=g_savedata.ammo_bs//1|0,
			as=g_savedata.ammo_as//1|0,
		},
		gc_time=600,
		damage_in_frame=0,
		name=name,
		trimmed_name=trim(name),
	}

	local vehicle_hp
	if g_savedata.vehicle_class then
		for class_name,class in pairs(g_classes) do
			local sign_data, is_success = server.getVehicleSign(vehicle_id, class_name)
			if is_success then
				vehicle_hp=class.hp
				break
			end
		end
	else
		vehicle_hp=g_savedata.vehicle_hp
	end

	if vehicle_hp then
		vehicle.hp=math.max(vehicle_hp//1|0,1)
		table.insert(g_vehicles, vehicle)
		return vehicle
	end
end

function unregisterVehicle(vehicle_id)
	local vehicle,index=findVehicle(vehicle_id)
	if not vehicle then return end
	table.remove(g_vehicles,index)

	-- WebMapAddon
	if g_has_webmap then
		g_webmap_bindings[vehicle_id]=nil
	end

	for peer_id,player in pairs(g_players) do
		if player.vehicle_id==vehicle_id then
			player.vehicle_id=-1
			if g_in_game then
				kill(peer_id)
			end
		end
	end

	g_player_status_dirty=true
end

function reregisterVehicles()
	for i=1,#g_vehicles do
		local vehicle=g_vehicles[i]
		if vehicle.alive then
			vehicle.hp=nil
			local vehicle_hp=g_savedata.vehicle_hp
			if vehicle_hp and vehicle_hp>0 then
				vehicle.hp=math.max(vehicle_hp//1|0,1)
			end

			vehicle.remain_ammo=g_savedata.supply_ammo//1|0

			g_player_status_dirty=true
		end
	end
end

function updateVehicle(vehicle)
	if not vehicle.alive then
		if vehicle.gc_time>0 then
			vehicle.gc_time=vehicle.gc_time-1
		elseif g_savedata.gc_vehicle then
			server.despawnVehicleGroup(vehicle.group_id, true)
		end
		return
	end

	local vehicle_id=vehicle.vehicle_id

	if vehicle.hp and vehicle.damage_in_frame>0 then
		local damage_in_frame=math.min(vehicle.damage_in_frame, g_savedata.max_damage)//1|0
		vehicle.hp=math.max(vehicle.hp-damage_in_frame, 0)

		if vehicle.hp==0 then
			vehicle.alive=false
		end
	end

	if vehicle.damage_in_frame>0 then
		for peer_id,player in pairs(g_players) do
			if player.vehicle_id==vehicle_id then
				local popup=findPopup(player.popup_name)
				if popup then
					popup.shake=17
				end
			end
		end
	end

	vehicle.damage_in_frame=0

	if g_savedata.sunk_depth>0 then
		local vehicle_trans=server.getVehiclePos(vehicle_id)
		local x,y,z=matrix.position(vehicle_trans)
		if y<-g_savedata.sunk_depth then
			vehicle.alive=false
		end
	end

	if vehicle.alive then
		return
	end

	-- explode
	local vehicle_matrix, is_success=server.getVehiclePos(vehicle_id)
	if is_success then
		server.spawnExplosion(vehicle_matrix, 0.17)
	end

	-- kill
	for peer_id,player in pairs(g_players) do
		if player.vehicle_id==vehicle_id then
			-- force getout
			local player_matrix, is_success=server.getPlayerPos(peer_id)
			if is_success then
				server.setPlayerPos(peer_id, player_matrix)
			end

			player.vehicle_id=-1
			kill(peer_id)
		end
	end

	server.setVehicleTooltip(vehicle_id, 'Destroyed')
	g_player_status_dirty=true
end

-- WebMapAddon(Called from the Join/Shuffle/Sit event.)
function bindVehicleTeamToWebMap(vehicle_id, team)
	if g_has_webmap==false then
		return
	end

	if not vehicle_id or vehicle_id<0 then
		return
	end

	local TEAM_COLOR_MAP = {
		red = "RED",
		blue = "BLUE",
		pink = "PINK",
		ylw = "YELLOW",
		standby = "YELLOW"
	}
	team = string.lower(team)
	local color = TEAM_COLOR_MAP[team]
	if not color then return end

	if g_webmap_bindings[vehicle_id]==color then return end
	g_webmap_bindings[vehicle_id]=color
	-- ?wm ct(WebMap_ChangeTeam)command
	local cmd = '?wm ct ' .. vehicle_id .. ' ' .. color
	server.command(cmd)
end

-- System Functions --

function updateTeamStatus()
	-- gen map
	local team_map={}
	for _,player in pairs(g_players) do
		local team_list=team_map[player.team]
		if not team_list then
			team_list={player}
			team_map[player.team]=team_list
		else
			table.insert(team_list, player)
		end
	end

	-- remove
	local i=#g_team_stats
	while i>0 do
		local team_status=g_team_stats[i]
		if not team_map[team_status.name] then
			unregisterPopup(team_status.popup_name)
			table.remove(g_team_stats, i)
		end
		i=i-1
	end

	-- add
	for team_name,player_list in pairs(team_map) do
		local team_status,idx=registerTeamStatus(team_name)

		local popup_x=-1.04+idx*0.18
		local popup_y=0.9
		registerPopup(team_status.popup_name, popup_x, popup_y)

		for i,player in ipairs(player_list) do
			local player_popup_y=popup_y-i*0.19
			registerPopup(player.popup_name, popup_x, player_popup_y)
		end
	end
end

function registerTeamStatus(name)
	for i,team_status in ipairs(g_team_stats) do
		if team_status.name==name then
			return team_status,i
		end
	end
	local popup_name='team_status_'..name
	registerPopup(popup_name, 0, 0)
	setPopup(popup_name, true, trim(name))
	local team_status={
		name=name,
		popup_name=popup_name,
	}
	table.insert(g_team_stats, team_status)
	return team_status,#g_team_stats
end

function updatePlayerStatus()
	for _,player in pairs(g_players) do
		local vehicle
		if player.vehicle_id>=0 then
			vehicle=findVehicle(player.vehicle_id)
		end

		setPopup(player.popup_name, true, playerToString(player.trimmed_name,player.alive,player.ready,vehicle))
	end
end

function playerToString(name, alive, ready, vehicle)
	local stat_text=alive and (g_in_game and 'Alive' or (ready and 'Ready' or 'Wait')) or 'Dead'
	local vehicle_text=vehicle and string.format('\n%s\nHP:%.0f',vehicle.trimmed_name,vehicle.hp) or ''
	return name..'\nStat:'..stat_text..vehicle_text
end

function startCountdown(force, peer_id)
	if g_in_game or g_in_countdown then return end
	local ready=true
	local teams={}
	for peer_id,player in pairs(g_players) do
		ready=ready and player.ready
		teams[player.team]=true
	end
	if not ready then
		if force then
			announce('There is unready player(s).', peer_id)
		end
		return
	end

	local team_count=getTableCount(teams)
	if team_count<1 or (team_count<2 and not force) then
		if force then
			announce('There are not enough registered teams.', peer_id)
		end
		return
	end
	announce('Countdown start.', -1)
	g_timer=300
	g_in_countdown=true
	g_player_status_dirty=true
end

function stopCountdown()
	if g_in_game or not g_in_countdown then return end
	announce('Countdown stop.', -1)
	setPopup('countdown', false)
	g_in_countdown=false
	g_player_status_dirty=true
end

function checkFinish()
	if not g_in_game then return end
	local team_aliver_counts={}
	local any=false
	for _,player in pairs(g_players) do
		local add=player.alive and 1 or 0
		local count=team_aliver_counts[player.team]
		team_aliver_counts[player.team]=count and (count+add) or add
		any=true
	end
	if not any then
		finishGame()
		notify('Game End', 'No player. Game is interrupted.', 6, -1)
		return
	end
	local alive_team_count=0
	local alive_team_name=''
	for team_name,team_aliver_count in pairs(team_aliver_counts) do
		if team_aliver_count>0 then
			alive_team_count=alive_team_count+1
			alive_team_name=team_name
		end
	end
	if alive_team_count>1 then return end

	finishGame()
	if alive_team_count==1 then
		notify('Game End', 'Team '..alive_team_name..' Win!', 9, -1)
	else
		notify('Game End', 'Draw Game!', 9, -1)
	end
end

function startGame()
	g_in_game=true
	g_in_countdown=false
	g_pause=false
	g_player_status_dirty=true
	g_timer=g_savedata.game_time*60*60//1|0
	g_remind_interval=g_timer//4

	for _,player in pairs(g_players) do
		player.ready=false
	end

	setPopup('countdown', false)
	clearSupplies()
	setSettingsToBattle()
	generateIffFreqs()

	local settings=server.getGameSettings()
	announce('- Infinitie Electric:'..tostring(settings.infinite_batteries), -1)
	announce('- Infinitie Fuel:'..tostring(settings.infinite_fuel), -1)
	announce('- Infinitie Ammo:'..tostring(settings.infinite_ammo), -1)
	announce('- Player Damage:'..tostring(settings.player_damage), -1)
	announce('- Disable Weapons:'..tostring(settings.ceasefire), -1)
end

function finishGame()
	g_in_game=false
	g_in_countdown=false
	g_pause=false
	g_player_status_dirty=true
	setPopup('game_time', false)

	for i,player in pairs(server.getPlayers()) do
		local peer_id=player.id
		local object_id, is_success=server.getPlayerCharacterID(peer_id)
		if is_success then
			server.reviveCharacter(object_id)
			server.setCharacterData(object_id, 100, false, false)
		end
	end

	if g_savedata.auto_standby then
		for _,p in pairs(g_players) do
			p.alive=true
			p.ready=false
		end
	end

	setSettingsToStandby()
end

function setSettingsToBattle()
	server.setGameSetting('third_person', g_savedata.tps_enabled)
	server.setGameSetting('third_person_vehicle', g_savedata.tps_enabled)
	server.setGameSetting('show_name_plates', g_savedata.nameplate_enabled)
	server.setGameSetting('vehicle_damage', true)
	server.setGameSetting('player_damage', g_savedata.player_damage)
	server.setGameSetting('map_show_players', false)
	server.setGameSetting('map_show_vehicles', false)
end

function setSettingsToStandby()
	server.setGameSetting('third_person', true)
	server.setGameSetting('third_person_vehicle', true)
	server.setGameSetting('show_name_plates', true)
	server.setGameSetting('vehicle_damage', false)
	server.setGameSetting('player_damage', false)
	server.setGameSetting('map_show_players', true)
	server.setGameSetting('map_show_vehicles', true)
end

-- UI

function registerPopup(name, x, y)
	local popup=findPopup(name)
	if popup then
		popup.x=x
		popup.y=y
		popup.is_dirty=true
		return
	end
	table.insert(g_popups, {
		name=name,
		x=x,
		y=y,
		ox=0,
		oy=0,
		shake=-1,
		ui_id=server.getMapID(),
		is_show=false,
		text='',
		is_dirty=true,
	})
end

function unregisterPopup(name)
	for i,popup in ipairs(g_popups) do
		if popup.name==name then
			server.removeMapID(-1, popup.ui_id)
			table.remove(g_popups, i)
			return
		end
	end
end

function findPopup(name)
	for i,popup in ipairs(g_popups) do
		if popup.name==name then
			return popup
		end
	end
end

function setPopup(name, is_show, text)
	local popup=findPopup(name)
	if not popup then return end
	if popup.is_show~=is_show then
		popup.is_show=is_show
		popup.is_dirty=true
	end
	if popup.text~=text then
		popup.text=text
		popup.is_dirty=true
	end
end

function updatePopups()
	for i,popup in ipairs(g_popups) do
		local shake=popup.shake
		if shake>=0 then
			popup.shake=shake-1
			if shake%4==0 then
				popup.ox=(math.random()-0.5)*0.002*shake
				popup.oy=(math.random()-0.5)*0.002*shake
				popup.is_dirty=true
			end
		end
		if popup.is_dirty then
			popup.is_dirty=false
			server.setPopupScreen(-1, popup.ui_id, popup.name, popup.is_show, popup.text, popup.x+popup.ox, popup.y+popup.oy)
		end
	end
end

function clearPopups()
	for i,popup in ipairs(g_popups) do
		server.removeMapID(-1, popup.ui_id)
	end
	g_popups={}
end

function renewUiIds()
	for i,popup in ipairs(g_popups) do
		server.removeMapID(-1, popup.ui_id)
		popup.ui_id=server.getMapID()
		popup.is_dirty=true
	end

	for peer_id,supply in pairs(g_savedata.supply_vehicles) do
		local vehicle_matrix, is_success = server.getVehiclePos(supply.vehicle_id)
		if is_success then
			server.removeMapID(-1, supply.ui_id)
			supply.ui_id=server.getMapID()
			local x,y,z = matrix.position(vehicle_matrix)
			server.addMapLabel(-1, supply.ui_id, 1, 'supply', x, z)
		end
	end

	for name,flag in pairs(g_savedata.flag_vehicles) do
		local vehicle_matrix, is_success = server.getVehiclePos(flag.vehicle_id)
		if is_success then
			server.removeMapID(-1, flag.ui_id)
			flag.ui_id=server.getMapID()
			local x,y,z = matrix.position(vehicle_matrix)
			local r,g,b,a=getColor(name)
			server.addMapObject(-1, flag.ui_id, 1, 9, x, z, 0, 0, flag.vehicle_id, 0, name, g_flag_radius, name, r, g, b, a)
		end
	end

	g_player_status_dirty=true
end

function updatePlayerMapObject()
	local sv_players=server.getPlayers()

	for peer_id,player in pairs(g_players) do
		local ui_id=findPopup(player.popup_name).ui_id
		local r,g,b,a=getColor(player.team:lower())
		local vehicle=findVehicle(player.vehicle_id)
		local object_id=server.getPlayerCharacterID(peer_id)

		server.removeMapObject(-1, ui_id)

		if g_savedata.show_friends and player.alive then
			for i,sv_player in ipairs(sv_players) do
				local other=g_players[sv_player.id]
				if not other or other.team==player.team then
					local a2=sv_player.id==peer_id and a or a//2
					if vehicle then
						server.addMapObject(sv_player.id, ui_id, 1, 2, 0, 0, 0, 0, vehicle.vehicle_id, -1, player.name, 0, vehicle.name, r, g, b, a2)
					else
						server.addMapObject(sv_player.id, ui_id, 2, 1, 0, 0, 0, 0, -1, object_id, player.name, 0, player.name, r, g, b, a2)
					end
				end
			end
		end
	end
end

-- Support vehicle

function spawnSupply(peer_id)
	despawnSupply(peer_id)
	local vehicle_matrix=getAheadMatrix(peer_id, 1, 8)
	local vehicle_id=spawnAddonVehicle('supply', vehicle_matrix)
	if vehicle_id then
		local ui_id=server.getMapID()
		local x,y,z=matrix.position(vehicle_matrix)
		server.addMapLabel(-1, ui_id, 1, 'supply', x, z)
		g_savedata.supply_vehicles[peer_id]={
			vehicle_id=vehicle_id,
			ui_id=ui_id,
		}
	end
end

function despawnSupply(peer_id)
	local supply=g_savedata.supply_vehicles[peer_id]
	if supply then
		server.despawnVehicle(supply.vehicle_id, true)
		server.removeMapID(-1, supply.ui_id)
		g_savedata.supply_vehicles[peer_id]=nil
	end
end

function clearSupplies()
	for peer_id,supply in pairs(g_savedata.supply_vehicles) do
		if type(supply)=='table' then
			server.despawnVehicle(supply.vehicle_id, true)
			server.removeMapID(-1, supply.ui_id)
		else
			-- for backward compertibility
			server.despawnVehicle(supply, true)
		end
	end
	g_savedata.supply_vehicles={}
end

function isSupply(vehicle_id)
	for peer_id,supply in pairs(g_savedata.supply_vehicles) do
		if supply.vehicle_id==vehicle_id then
			return true
		end
	end
	return false
end

function spawnFlag(peer_id, name)
	despawnFlag(peer_id, name)
	local vehicle_matrix=getAheadMatrix(peer_id, 9, 8)
	local vehicle_id=spawnAddonVehicle('flag', vehicle_matrix)

	if vehicle_id then
		server.setVehicleTooltip(vehicle_id, name)
		local ui_id=server.getMapID()
		local x,y,z=matrix.position(vehicle_matrix)
		local r,g,b,a=getColor(name)
		server.addMapObject(-1, ui_id, 1, 9, x, z, 0, 0, vehicle_id, 0, name, g_flag_radius, name, r, g, b, a)
		g_savedata.flag_vehicles[name]={
			vehicle_id=vehicle_id,
			ui_id=ui_id,
		}
	end
end

function despawnFlag(peer_id, name)
	local flag=g_savedata.flag_vehicles[name]
	if flag then
		server.despawnVehicle(flag.vehicle_id, true)
		server.removeMapID(-1, flag.ui_id)
		g_savedata.flag_vehicles[name]=nil
	end
end

function clearFlags()
	for name,flag in pairs(g_savedata.flag_vehicles) do
		server.despawnVehicle(flag.vehicle_id, true)
		server.removeMapID(-1, flag.ui_id)
	end
	g_savedata.flag_vehicles={}
end

-- Utility Functions --

function announce(text, peer_id)
	server.announce('[Matchmaker]', text, peer_id)
end

function notify(title, text, type, peer_id)
	server.notify(-1, title, text, type)
	announce(title..'\n'..text, peer_id)
end

function getTableCount(table)
	local count=0
	for idx,p in pairs(table) do
		count=count+1
	end
	return count
end

function clamp(x,a,b)
	return x<a and a or x>b and b or x
end

function convert(value, type)
	local converter=g_converters[type]
	if converter then
		return converter(value)
	end
	return value
end

g_converters={
	integer=function(v)
		v=tonumber(v)
		return v and v//1|0
	end,
	number=function(v)
		return tonumber(v)
	end,
	boolean=function(v)
		if v=='true' then return true end
		if v=='false' then return false end
	end,
}

function getAheadMatrix(peer_id, y, z)
	local look_x, look_y, look_z=server.getPlayerLookDirection(peer_id)
	local position=server.getPlayerPos(peer_id)
	local offset=matrix.translation(0, y, -z)
	local rotation=matrix.rotationToFaceXZ(-look_x, -look_z)
	return matrix.multiply(position, matrix.multiply(rotation, offset))
end


function spawnAddonVehicle(name, transform_matrix)
	local addon_index, is_success = server.getAddonIndex()
	if not is_success then return end

	local search_tag='name='..name
	local addon_data=server.getAddonData(addon_index)
	for location_index=0,addon_data.location_count-1 do
		local location_data=server.getLocationData(addon_index, location_index)
		for component_index=0,location_data.component_count-1 do
			local component_data= server.getLocationComponentData(addon_index, location_index, component_index)
			if component_data.type=='vehicle' then
				for _,tag_pair in pairs(component_data.tags) do
					if tag_pair==search_tag then
						return server.spawnAddonVehicle(transform_matrix, addon_index, component_data.id)
					end
				end
			end
		end
	end
end

function findEmptySlot(object_id, slot)
	local equipment_id=server.getCharacterItem(object_id, slot)
	if equipment_id==0 then
		return slot
	end
	if slot>=2 and slot<9 then
		return findEmptySlot(object_id, slot+1)
	end
end

function getColor(name)
	return table.unpack(g_colors[name] or g_color_default)
end

g_colors={
	red		={255,0  ,0,  255},
	green	={0,  255,0,  255},
	blue	={0,  0,  255,255},
	yellow	={255,255,0,  255},
	ylw		={255,255,0,  255},
	pink	={255,0,  255,255},
	cyan	={0,  255,255,255},
	white	={225,225,225,255},
	black	={30, 30, 30, 255},
}
g_color_default={255,127,39,255}

function validateArgs(command_define, args, peer_id)
	if command_define.args then
		for i,arg_define in ipairs(command_define.args) do
			if #args < i then
				if arg_define.require then
					announce('Argument not enough. Except ['..arg_define.name..'].', peer_id)
					return false
				end
				break
			end
			local value, is_success=validateArg(arg_define, args[i])
			if not is_success then return false end
			args[i]=value
		end
	end
	return true
end

function validateArg(arg_define, arg, peer_id)
	local value=convert(arg, arg_define.type)
	if value==nil then
		announce('Except '..arg_define.type..' to ['..arg_define.name..'].', peer_id)
		return nil, false
	end
	if arg_define.type=='integer' or arg_define.type=='number' then
		if arg_define.min and value<arg_define.min then
			announce(arg_define.name ..'cannot be set to less than '..tostring(arg_define.min), peer_id)
			return nil, false
		end
		if arg_define.max and value>arg_define.max then
			announce(arg_define.name ..'cannot be set to greater than '..tostring(arg_define.max), peer_id)
			return nil, false
		end
	end
	return value, true
end

----

function trim(str)
	local w=0
	for i=1,#str do
		w=w+getWidth(str:byte(i))
		if w>1000 then
			return str:sub(1,i-1)
		end
	end
	return str
end
function getWidth(char_byte)
	local idx=char_byte-31
	return idx>0 and idx<=#cwl and cwl[idx] or cwl[1]
end

cwl={
	41,40,60,95,85,123,108,34,45,45,81,85,40,48,40,55,85,85,85,85,85,85,85,85,85,85,40,40,85,85,
	85,64,133,94,94,93,108,82,77,108,109,50,41,92,78,134,112,115,89,115,92,81,82,108,89,137,
	87,84,85,49,55,49,85,66,86,83,91,71,91,83,51,91,91,38,38,79,38,138,91,89,91,91,61,71,54,91,
	75,116,78,75,70,56,81,56,85
}

-- ============================================================
--  座標エンコード / デコード (encode_position 方式)
--  x, h, y: -128000 ~ 128000 → 0 ~ 256000 (各18bit)
--  float1 (30bit): x(18bit)      | y_upper12(12bit)
--  float2 (30bit): y_lower6(6bit) | h(18bit) | name_token(6bit)
-- ============================================================
local function _enc30(n)
	local b=n & 0xFFFFFF
	local hi6=(n>>24) & 63
	local q=((hi6>>5)&1)<<7 | (hi6&31)
	return ('f'):unpack(('I3B'):pack(b, q+66))
end

local function _dec30(x)
	local b,a=('I3B'):unpack(('f'):pack(x))
	if not((66<=a and a<=126) or (194<=a and a<=254)) then return false,0 end
	local n=(a-66>>2&32 | a-66&31)<<24 | b
	return true,n
end

function encodeCoords(x,h,y,name_token)
	name_token=name_token or 0
	local xe=math.max(0,math.min(256000, (x//1|0)+128000))
	local he=math.max(0,math.min(256000, (h//1|0)+128000))
	local ye=math.max(0,math.min(256000, (y//1|0)+128000))
	local n1=(ye>>6)<<18 | xe
	local n2=(ye & 63)<<24 | he<<6 | (name_token & 63)
	return _enc30(n1),_enc30(n2)
end

function decodeCoords(f1,f2)
	local ok1,n1=_dec30(f1)
	local ok2,n2=_dec30(f2)
	if not ok1 or not ok2 then return false,0,0,0,0 end
	local xe=n1 & 262143
	local yhi=(n1>>18) & 4095
	local name_token=n2 & 63
	local he=(n2>>6) & 262143
	local ye=yhi<<6 | (n2>>24) & 63
	return true, xe-128000, he-128000, ye-128000, name_token
end

-- ============================================================
--  名前エンコード / デコード (6bitスロット使用)
--  0=PAD, 1=START, 2=END
--  3~12='0'~'9', 13~38='a'~'z', 39='_'
--  使用可能: 0-9 a-z _  大文字は小文字変換、その他リジェクト
-- ============================================================
NAME_PAD   = 0
NAME_START = 1
NAME_END   = 2

function nameCharToToken(c)
	local b=c:byte()
	if b>=48 and b<=57  then return b-48+3  end
	if b>=97 and b<=122 then return b-97+13 end
	if b==95             then return 39      end
	return nil
end

function tokenToNameChar(t)
	if t>=3  and t<=12 then return string.char(t-3+48)  end
	if t>=13 and t<=38 then return string.char(t-13+97) end
	if t==39            then return '_'                 end
	return nil
end

function buildNameTokens(name)
	name=name:lower()
	local tokens={NAME_START}
	local count=0
	for i=1,#name do
		if count>=10 then break end
		local t=nameCharToToken(name:sub(i,i))
		if t then
			tokens[#tokens+1]=t
			count=count+1
		end
	end
	tokens[#tokens+1]=NAME_END
	return tokens
end

g_name_tx={}
g_name_rx={}
g_decoded_names={}
