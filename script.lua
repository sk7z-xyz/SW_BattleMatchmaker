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
g_flag_radius=1000
-- WebMapAddon
g_has_webmap=false
g_webmap_bindings={}
g_tick_count=0
g_freq_force_timer=0
g_ready_remind_timer=0
g_pending_link_requests={} -- {{peer_id=number, vehicle_id=number, delay=number}, ...}
g_iff_vehicles={}
g_iff_freq={[1]=0,[2]=0,[3]=0}
g_group_parents={}  -- {[group_id]=parent_vehicle_id}
-- Airbase assignment state
g_flag_assignments = { RED = nil, BLUE = nil }
g_auto_battle_state=nil -- {phase='wait_shuffle'|'wait_teleport', timer=ticks}
-- finishGame now accepts an optional keep_airbase argument
-- airports: 複数の基地を設定できる構造化テーブル
-- 各エントリ: { tile = '<tile_name>', name = '<基地名>', x = <world_x>, y = <world_z> }
--0,0地点から50kmまでしか探索できないので、北極は無理です　それ以外ならOK
airports = {
	{ tile = 'mega_island_12_6', 			name = 'Oneill AirBase',   	    	x = 0, z = 0, y = 11 },
	{ tile = 'mega_island_2_6',     		name = 'Harrison AirBase',			x = 0, z = 0, y = 15},
	{ tile = 'island_15',					name = 'CoastGurd Outpost', 		x = 0, z = 0, y = 7},
	{ tile = 'island_34_military',			name = 'Military Base', 			x = 0, z = 0, y = 24},
	{ tile = 'island_33_tile_33',  			name = 'Donkk AirBase',         	x = -19100 , z = -4700, y = 10},
	{ tile = 'island_43_multiplayer_base',  name = 'Multiplayer Island Base',	x = 0, z = 0, y = 16},
	{ tile = 'arid_island_26_14',   		name = 'FJ Warner',          		x = 0, z = 0, y = 11 },
	{ tile = 'arid_island_19_11',   		name = 'Clarke Airfield',          	x = 0, z = 0, y = 21 },
	{ tile = 'arid_island_7_5',   			name = 'Ender Airfield',          	x = 0, z = 0, y = 177 },
}

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
		name='Auto battle after finish',
		key='auto_battle',
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
	{
		name='Auto Link on Spawn',
		key='auto_link_on_spawn',
		type='boolean',
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
	vehicle_hp			=property.slider("Vehicle HP", 50, 7000, 10, 50),
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
	auto_battle			=property.checkbox("Auto battle after finish", false),
	gc_vehicle			=property.checkbox("Auto vehicle cleanup", true),
	supply_vehicles		={},
	flag_vehicles		={},
	auto_auth			=property.checkbox("Auto Auth", true),
	sunk_depth			=property.slider("Sunk Depth", -100, 200, 1, 1),
	iff_vehicles		={},
	auto_link_on_spawn	=true,
	shuffle_history		={},
	shuffle_history_K	=4,
}

g_mag_names={}
for i=1,10 do g_mag_names[i]='magazine_'..tostring(i) end

-- Shuffle2 constants (: K=4, max_same ratio=0.4)
local SHUFFLE_HISTORY_K = 4
local MAX_SAME_RATIO = 0.4
local SHUFFLE_MAX_ENUM = 200000 --
local SHUFFLE_VIOLATION_WEIGHT = 10000 -- JS

--
local combos_cache = {}

local function ncr(n,k)
	if k < 0 or k > n then return 0 end
	if k > n - k then k = n - k end
	local num = 1
	for i=1,k do
		num = num * (n - k + i) / i
	end
	return math.floor(num + 0.5)
end

-- n choose k : 1..n
local function combinations(n,k)
	local res = {}
	if k < 0 or k > n then return res end
	local key = tostring(n) .. '#' .. tostring(k)
	if combos_cache[key] then return combos_cache[key] end
	local comb = {}
	for i=1,k do comb[i] = i end
	while true do
		local ccopy = {}
		for i=1,k do ccopy[i] = comb[i] end
		table.insert(res, ccopy)
		local i = k
		while i > 0 and comb[i] == n - k + i do i = i - 1 end
		if i == 0 then break end
		comb[i] = comb[i] + 1
		for j = i+1, k do comb[j] = comb[j-1] + 1 end
	end
	combos_cache[key] = res
	return res
end

local function combinations_from_list(list, k)
	local n = #list
	local idxs = combinations(n,k)
	local out = {}
	for _, combo in ipairs(idxs) do
		local row = {}
		for _, p in ipairs(combo) do table.insert(row, list[p]) end
		table.insert(out, row)
	end
	return out
end

local function assignment_count(n, teamSizes)
	local cnt = 1
	local rem = n
	for i=1,#teamSizes do
		local k = teamSizes[i]
		local c = ncr(rem, k)
		if c == 0 then return math.huge end
		cnt = cnt * c
		if cnt > SHUFFLE_MAX_ENUM then return cnt end
		rem = rem - k
	end
	return cnt
end

--  (g_savedata.shuffle_history)  pairCounts
local function build_pair_counts()
	local counts = {}
	local history = g_savedata.shuffle_history
	if not history then return counts end
	local limit = SHUFFLE_HISTORY_K
	for i = 1, math.min(#history, limit) do
		local round = history[i]
		if round then
			local teams = {}
			for pid, team in pairs(round) do
				teams[team] = teams[team] or {}
				table.insert(teams[team], pid)
			end
			for _, members in pairs(teams) do
				for a=1,#members-1 do
					for b=a+1,#members do
						local p1 = members[a] < members[b] and members[a] or members[b]
						local p2 = members[a] < members[b] and members[b] or members[a]
						local key = tostring(p1) .. '-' .. tostring(p2)
						counts[key] = (counts[key] or 0) + 1
					end
				end
			end
		end
	end
	return counts
end

local function pair_penalty_for_set(members, pairCounts)
	if not pairCounts then return 0 end
	local penalty = 0
	for i=1,#members-1 do
		for j=i+1,#members do
			local a = members[i]; local b = members[j]
			local p1 = a < b and a or b
			local p2 = a < b and b or a
			local key = tostring(p1) .. '-' .. tostring(p2)
			penalty = penalty + (pairCounts[key] or 0)
		end
	end
	return penalty
end

--  multi-team
local function generate_multiteam_assignments(list, teamSizes)
	local results = {}
	local function rec(remaining, idx, current)
		if idx > #teamSizes then
			-- copy current
			local copy = {}
			for t=1,#current do
				copy[t] = {}
				for i=1,#current[t] do copy[t][i] = current[t][i] end
			end
			table.insert(results, copy)
			return
		end
		local k = teamSizes[idx]
		local combos = combinations_from_list(remaining, k)
		for _, chosen in ipairs(combos) do
			local chosenSet = {}
			for _, v in ipairs(chosen) do chosenSet[v] = true end
			local nextRemaining = {}
			for _, v in ipairs(remaining) do if not chosenSet[v] then table.insert(nextRemaining, v) end end
			current[idx] = chosen
			rec(nextRemaining, idx+1, current)
			current[idx] = nil
		end
	end
	rec(list, 1, {})
	return results
end

local function evaluate_candidates(peer_list, prev_map, pairCounts, teamSizes, teamNames)
	local n = #peer_list
	local enumCnt = assignment_count(n, teamSizes)
	if enumCnt > SHUFFLE_MAX_ENUM then
		return nil, enumCnt
	end
	local candidates = {}
	local assignments = generate_multiteam_assignments(peer_list, teamSizes)
	for _, assignment in ipairs(assignments) do
		local sameCounts = {}
		local pairPenalty = 0
		for t=1,#assignment do
			local members = assignment[t]
			local same = 0
			for _, pid in ipairs(members) do
				if prev_map and prev_map[pid] and prev_map[pid] == teamNames[t] then same = same + 1 end
			end
			sameCounts[t] = same
			pairPenalty = pairPenalty + pair_penalty_for_set(members, pairCounts)
		end
		table.insert(candidates, {teams = assignment, sameCounts = sameCounts, pairPenalty = pairPenalty})
	end
	return candidates, enumCnt
end

--
local function heuristic_assign(peer_list, prev_map, pairCounts, teamSizes, teamNames, attempts)
	attempts = attempts or 12
	local n = #peer_list
	if n == 0 then return nil end
	-- precompute maxSame per team
	local maxSame = {}
	for i=1,#teamSizes do maxSame[i] = math.min(teamSizes[i], math.ceil(MAX_SAME_RATIO * teamSizes[i])) end

	local function calc_pair_inc(pid, members)
		local s = 0
		for _, m in ipairs(members) do
			local a = pid < m and pid or m
			local b = pid < m and m or pid
			local key = tostring(a) .. '-' .. tostring(b)
			s = s + (pairCounts[key] or 0)
		end
		return s
	end

	local function score_assignment(teams)
		local pair = 0
		local violation = 0
		for t=1,#teams do
			pair = pair + pair_penalty_for_set(teams[t], pairCounts)
			if prev_map then
				local same = 0
				for _, pid in ipairs(teams[t]) do if prev_map[pid] == teamNames[t] then same = same + 1 end end
				if same > maxSame[t] then violation = violation + (same - maxSame[t]) end
			end
		end
		local score = violation * SHUFFLE_VIOLATION_WEIGHT + pair
		return score, pair, violation
	end

	local function make_initial_assignment(order)
		local teams = {}
		local sameCounts = {}
		for i=1,#teamSizes do teams[i] = {}; sameCounts[i] = 0 end
		for _, pid in ipairs(order) do
			local bestT, bestCost = nil, math.huge
			for t=1,#teamSizes do
				if #teams[t] < teamSizes[t] then
					local inc = calc_pair_inc(pid, teams[t])
					local newSame = sameCounts[t] + (prev_map and prev_map[pid] == teamNames[t] and 1 or 0)
					local viol = 0
					if newSame > maxSame[t] then viol = newSame - maxSame[t] end
					local cost = inc + viol * SHUFFLE_VIOLATION_WEIGHT + math.random() * 1e-6
					if cost < bestCost then bestCost = cost; bestT = t end
				end
			end
			if not bestT then bestT = 1 end
			table.insert(teams[bestT], pid)
			if prev_map and prev_map[pid] == teamNames[bestT] then sameCounts[bestT] = sameCounts[bestT] + 1 end
		end
		return teams
	end

	local function local_search(teams, maxIter)
		local bestScore, bestPair, bestViol = score_assignment(teams)
		for iter=1,maxIter do
			-- random swap between different teams
			local t1 = math.random(1,#teams)
			local t2 = math.random(1,#teams)
			if t1 == t2 or #teams[t1] == 0 or #teams[t2] == 0 then goto cont end
			local i1 = math.random(1,#teams[t1])
			local i2 = math.random(1,#teams[t2])
			local p1 = teams[t1][i1]
			local p2 = teams[t2][i2]

			-- compute delta pair penalty
			local old_pair = 0
			for _, m in ipairs(teams[t1]) do if m ~= p1 then local a = p1 < m and p1 or m; local b = p1 < m and m or p1; old_pair = old_pair + (pairCounts[tostring(a)..'-'..tostring(b)] or 0) end end
			for _, m in ipairs(teams[t2]) do if m ~= p2 then local a = p2 < m and p2 or m; local b = p2 < m and m or p2; old_pair = old_pair + (pairCounts[tostring(a)..'-'..tostring(b)] or 0) end end

			local new_pair = 0
			for _, m in ipairs(teams[t1]) do if m ~= p1 then local a = p2 < m and p2 or m; local b = p2 < m and m or p2; new_pair = new_pair + (pairCounts[tostring(a)..'-'..tostring(b)] or 0) end end
			for _, m in ipairs(teams[t2]) do if m ~= p2 then local a = p1 < m and p1 or m; local b = p1 < m and m or p1; new_pair = new_pair + (pairCounts[tostring(a)..'-'..tostring(b)] or 0) end end

			local deltaPair = new_pair - old_pair

			-- compute violation delta
			local violDelta = 0
			if prev_map then
				local oldSame1 = 0; for _,m in ipairs(teams[t1]) do if m ~= p1 and prev_map[m] == teamNames[t1] then oldSame1 = oldSame1 + 1 end end
				local oldSame2 = 0; for _,m in ipairs(teams[t2]) do if m ~= p2 and prev_map[m] == teamNames[t2] then oldSame2 = oldSame2 + 1 end end
				local newSame1 = oldSame1 + (prev_map[p2] == teamNames[t1] and 1 or 0)
				local newSame2 = oldSame2 + (prev_map[p1] == teamNames[t2] and 1 or 0)
				local oldV = math.max(0, oldSame1 - maxSame[t1]) + math.max(0, oldSame2 - maxSame[t2])
				local newV = math.max(0, newSame1 - maxSame[t1]) + math.max(0, newSame2 - maxSame[t2])
				violDelta = (newV - oldV) * SHUFFLE_VIOLATION_WEIGHT
			end

			local delta = deltaPair + violDelta
			if delta < -1e-9 then
				-- perform swap
				teams[t1][i1] = p2
				teams[t2][i2] = p1
				local s,_,_ = score_assignment(teams)
				if s < bestScore then bestScore = s end
			end
			::cont::
		end
		return teams, bestScore
	end

	local bestAssign = nil
	local bestScore = math.huge
	for a=1,attempts do
		-- random order
		local order = {}
		for i=1,n do order[i] = peer_list[i] end
		for i=n,2,-1 do local j = math.random(i); order[i], order[j] = order[j], order[i] end
		local teams = make_initial_assignment(order)
		teams, localScore = local_search(teams, 300)
		if localScore < bestScore then bestScore = localScore; bestAssign = teams end
	end

	if not bestAssign then return nil end
	local sameCounts = {}
	for t=1,#bestAssign do
		local same = 0
		for _, pid in ipairs(bestAssign[t]) do if prev_map and prev_map[pid] == teamNames[t] then same = same + 1 end end
		sameCounts[t] = same
	end
	local pairPenalty = 0
	for t=1,#bestAssign do pairPenalty = pairPenalty + pair_penalty_for_set(bestAssign[t], pairCounts) end
	return {teams = bestAssign, sameCounts = sameCounts, pairPenalty = pairPenalty}
end

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
			if team_name == "r" or team_name == "R" or team_name == "red" then
				team_name = "RED"
			elseif team_name == "b" or team_name == "B" or team_name == "blue"then
				team_name = "BLUE"
			end
			if team_name then
				team_name = string.upper(team_name)
			else
				team_name = g_temporary_team
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
				-- call finishGame requesting to keep airbase assignments
				finishGame(true)
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
		action=function(peer_id, is_admin, is_auth, name, x, z, y)
			if not name or name=='' then
				announce('Flag name required.', peer_id)
				return
			end
			if name == "r" or name == "R" or name == "red" then
				name = "RED"
			elseif name == "b" or name == "B" or name == "blue"then
				name = "BLUE"
			end

			if x and z and y then
				x = tonumber(x)
				z = tonumber(z)
				--yはnilも許容するが、数値なら変換する
				if y ~= nil then
					y = tonumber(y)
				end
				if x and z then
					spawnFlagAt(peer_id, name, x, z, y )
					return
				end
			end
			-- fallback: spawn in front of player
			spawnFlag(peer_id, name)
		end,
		args={
			{name='name', type='string', require=true},
			{name='x', type='number', require=false},
			{name='z', type='number', require=false},
			{name='y', type='number', require=false},
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
			team_count=team_count or 2
			if team_count < 2 or team_count > #g_default_teams then
				announce('team_count must be between 2 and '..#g_default_teams, peer_id)
				return
			end
			shuffle(team_count)
		end,
		args={
			{name='team_count', type='integer', require=false, min=2, max=#g_default_teams},
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
			finishGame(false)
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
		name='iff create',
		desc='現在位置にIFF送信機を1機スポーンする',
		admin=false,
		action=function(peer_id, is_admin, is_auth)
			createIffSenderAt(peer_id)
		end,
	},
	{
		name='iff create all',
		desc='既存のIFF送信機を全削除し、固定4拠点に再スポーンする',
		admin=false,
		action=function(peer_id, is_admin, is_auth)
			createIffSender(peer_id)
		end,
	},
	{
		name='iff delete',
		desc='最寄りのIFF送信機を1機削除する',
		admin=false,
		action=function(peer_id, is_admin, is_auth)
			deleteIffSenderNearest(peer_id)
		end,
	},
	{
		name='iff delete all',
		desc='スポーン中のIFF送信機をすべて削除する',
		admin=false,
		action=function(peer_id, is_admin, is_auth)
			deleteIffSender(peer_id)
		end,
	},
	{
		name='iff list',
		desc='スポーン中のIFF送信機の一覧と座標を表示する',
		admin=false,
		action=function(peer_id, is_admin, is_auth)
			showIffList(peer_id)
		end,
	},
}

g_iff_spawn_positions={
	{2768,   5, -30222},
	{-20750, 5, -30100},
	{-18855, 5,  -5100},
	{10745,  5,  -8500},
}

-- Resolve airports coordinates from tile names.
-- If airport.x and airport.z are 0 or nil, try to get world coordinates using server.getTileTransform.
-- Returns number of resolved entries.
function resolveAirports(exec_peer_id)
	local resolved = 0
	for i, ap in ipairs(airports) do
		if ap then
			local need = (not ap.x or ap.x==0) and (not ap.z or ap.z==0)
			if need then
				local transform = matrix.translation(0,0,0)
				local tile_name = "data/tiles/"..tostring(ap.tile)..".xml"
				local transform_matrix, is_success = server.getTileTransform(transform, tile_name)
				if is_success then
					local tx, ty, tz = matrix.position(transform_matrix)
					ap.x = tx
					ap.z = tz
					resolved = resolved + 1
				else
					announce('Failed to resolve tile '..tostring(ap.tile), exec_peer_id)
				end
			end
		end
	end
	if exec_peer_id then
		announce('Airports resolved: '..tostring(resolved), exec_peer_id)
	end
	return resolved
end

-- Register commands for airports (resolve & list)
table.insert(g_commands, {
	name='airports_resolve',
	desc='Resolve airports coordinates from tile names)',
	admin=true,
	action=function(peer_id, is_admin, is_auth)
		resolveAirports(peer_id)
	end,
})


table.insert(g_commands, {
	name='airports_list',
	desc='List airports entries',
	auth=true,
	action=function(peer_id, is_admin, is_auth)
		local text='Airports ('..tostring(#airports)..'):\n'
		for i, ap in ipairs(airports) do
			text = text .. string.format(' #%d tile=%s name=%s x=%.0f z=%.0f\n', i, ap.tile or '', ap.name or '', ap.x or 0, ap.z or 0)
		end

		announce(text, peer_id)
	end,
})

-- Commands: shuffle_airbase (alias sa) and tp
table.insert(g_commands, {
	name='shuffle_airbase',
	desc='Select two nearby airbases and assign them to RED and BLUE (arg: range)',
	admin=true,
	action=function(peer_id, is_admin, is_auth, range)
		range = tonumber(range) or 20000
		assignAirbases(peer_id, range)
	end,
	args={
		{name='range', type='number', require=false},
	},
})

table.insert(g_commands, {
	name='tp',
	desc='Teleport to your team\'s assigned flag',
	auth=true,
	action=function(peer_id, is_admin, is_auth)
		teleportPlayerToAssignedFlag(peer_id)
	end,
})

-- Helper: compute 2D distance between airports (x,z)
local function _airbase_dist(ax, az, bx, bz)
	local dx = (tonumber(ax) or 0) - (tonumber(bx) or 0)
	local dz = (tonumber(az) or 0) - (tonumber(bz) or 0)
	return math.sqrt(dx*dx + dz*dz)
end

-- Choose a pair of airbases: pick A randomly, then pick B randomly among those within range.
-- If none within range, pick the nearest other airbase.
function chooseAirbasePair(range)
	range = tonumber(range) or 20000
	if not airports or #airports < 2 then return nil end
	local min_pair_dist = 5000
	local max_retry = 2
	-- find indices with valid coordinates
	local valid_idxs = {}
	for i, ap in ipairs(airports) do
		if ap and ap.x and ap.z and tonumber(ap.x) and tonumber(ap.z) then
			table.insert(valid_idxs, i)
		end
	end
	if #valid_idxs < 2 then return nil end

	local fallback_pair = nil
	local fallback_dist = -1
	for _=1,max_retry do
		local a_idx = valid_idxs[math.random(1, #valid_idxs)]
		local a = airports[a_idx]

		-- collect candidates within range
		local candidates = {}
		for _, j in ipairs(valid_idxs) do
			if j ~= a_idx then
				local ap = airports[j]
				local d = _airbase_dist(a.x, a.z, ap.x, ap.z)
				if d <= range then table.insert(candidates, j) end
			end
		end

		local b_idx = nil
		if #candidates > 0 then
			b_idx = candidates[math.random(1, #candidates)]
		else
			-- find nearest
			local bestd = math.huge
			for _, j in ipairs(valid_idxs) do
				if j ~= a_idx then
					local ap = airports[j]
					local d = _airbase_dist(a.x, a.z, ap.x, ap.z)
					if d < bestd then bestd = d; b_idx = j end
				end
			end
		end

		if b_idx then
			local dist = _airbase_dist(airports[a_idx].x, airports[a_idx].z, airports[b_idx].x, airports[b_idx].z)
			local pair = { a_idx = a_idx, a = airports[a_idx], b_idx = b_idx, b = airports[b_idx] }
			if dist > fallback_dist then
				fallback_dist = dist
				fallback_pair = pair
			end
			-- if within 5km, reshuffle
			if dist > min_pair_dist then
				return pair
			end
		end
	end

	-- all retries resulted in <=5km pairs; return the farthest fallback
	return fallback_pair
end

-- Assign airbases to RED/BLUE and spawn flags. This is the main function for shuffle_airbase.
function assignAirbases(peer_id, range)
	local pair = chooseAirbasePair(range)
	if not pair then
		announce('Failed to choose airbases. Check airports configuration.', peer_id)
		return false
	end

	-- spawn flags for teams (pass team name as requested, do NOT pass y)
	spawnFlagAt(peer_id, "RED", pair.a.x, pair.a.z, pair.a.y,true)
	spawnFlagAt(peer_id, "BLUE", pair.b.x, pair.b.z, pair.b.y,true)

	announce('Airbases assigned: RED='..tostring(pair.a.name)..' BLUE='..tostring(pair.b.name), -1)
	return true
end

-- Clear airbase assignments and remove flags (unless preserve==true)
function clearFlagAssignments(preserve, peer_id)
	if preserve then return end
	-- remove flag markers 'red' and 'blue' (use lower-case names to match spawn usage)
	despawnFlag(peer_id or -1, 'red')
	despawnFlag(peer_id or -1, 'blue')
	g_flag_assignments = { RED = nil, BLUE = nil }
end

-- Get assigned flag for a team (team may be 'RED'/'red'/'Red')
function getAssignedFlagForTeam(team)
	if not team then return nil end
	local t = string.upper(team)
	return g_flag_assignments[t]
end

-- Teleport a player to their team's assigned flag (y uses flag entry y if present, otherwise 20)
function teleportPlayerToAssignedFlag(peer_id)
	local player = g_players[peer_id]
	if not player then
		announce('Player not found.', peer_id)
		return false
	end
	local team = player.team
	if not team then
		announce('You are not assigned to a team.', peer_id)
		return false
	end
	local assigned = getAssignedFlagForTeam(team)
	if not assigned then
		announce('No flag assigned for your team.', peer_id)
		return false
	end
	local y = assigned.y or 20
	local pos = matrix.translation(assigned.x or 0, y, assigned.z or 0)
	server.setPlayerPos(peer_id, pos)
	announce('Teleported to your team flag: '..tostring(assigned.name), peer_id)
	return true
end

function createIffSenderAt(peer_id)
	local pos, is_success=server.getPlayerPos(peer_id)
	if not is_success then
		announce('Failed to get player position.', peer_id)
		return
	end
	local vehicle_id=spawnAddonVehicle('iff_sender', pos)
	if vehicle_id then
		table.insert(g_savedata.iff_vehicles, vehicle_id)
		announce('IFF sender spawned. vehicle_id='..vehicle_id, peer_id)
	else
		announce('IFF sender spawn failed.', peer_id)
	end
	showIffList(peer_id)
end

function createIffSender(peer_id)
	deleteIffSender()
	for _,p in ipairs(g_iff_spawn_positions) do
		local pos=matrix.translation(p[1], p[2], p[3])
		local vehicle_id=spawnAddonVehicle('iff_sender', pos)
		if vehicle_id then
			table.insert(g_savedata.iff_vehicles, vehicle_id)
			announce('IFF sender spawned. vehicle_id='..vehicle_id, peer_id)
		else
			announce('IFF sender spawn failed at '..p[1]..','..p[3], peer_id)
		end
	end
	if peer_id then showIffList(peer_id) end
end

function deleteIffSender(peer_id)
	if g_savedata.iff_vehicles and #g_savedata.iff_vehicles>0 then
		local to_despawn={}
		for _,vid in ipairs(g_savedata.iff_vehicles) do
			to_despawn[vid]=true
		end
		g_iff_vehicles={}
		g_savedata.iff_vehicles=g_iff_vehicles
		for vid in pairs(to_despawn) do
			server.despawnVehicle(vid, true)
		end
		announce('IFF senders despawned.', peer_id or -1)
	else
		if peer_id then
			announce('IFF sender not found.', peer_id)
		end
	end
	if peer_id then showIffList(peer_id) end
end

function deleteIffSenderNearest(peer_id)
	if not g_savedata.iff_vehicles or #g_savedata.iff_vehicles==0 then
		announce('IFF sender not found.', peer_id)
		showIffList(peer_id)
		return
	end
	local player_pos, is_success=server.getPlayerPos(peer_id)
	if not is_success then
		announce('Failed to get player position.', peer_id)
		return
	end
	local px,_,pz=matrix.position(player_pos)
	local nearest_vid=nil
	local nearest_dist=math.huge
	for _,vid in ipairs(g_savedata.iff_vehicles) do
		local vpos, ok=server.getVehiclePos(vid)
		if ok then
			local vx,_,vz=matrix.position(vpos)
			local dx=px-vx
			local dz=pz-vz
			local dist=dx*dx+dz*dz
			if dist<nearest_dist then
				nearest_dist=dist
				nearest_vid=vid
			end
		end
	end
	if nearest_vid then
		server.despawnVehicle(nearest_vid, true)
		for i=#g_savedata.iff_vehicles,1,-1 do
			if g_savedata.iff_vehicles[i]==nearest_vid then table.remove(g_savedata.iff_vehicles,i) end
		end
		announce('IFF sender despawned. vehicle_id='..nearest_vid, peer_id)
	else
		announce('IFF sender not found.', peer_id)
	end
	showIffList(peer_id)
end

function showIffList(peer_id)
	if not g_savedata.iff_vehicles or #g_savedata.iff_vehicles==0 then
		announce('IFF senders: none', peer_id)
		return
	end
	local text='IFF senders ('..#g_savedata.iff_vehicles..'):\n'
	for i,vid in ipairs(g_savedata.iff_vehicles) do
		local pos, ok=server.getVehiclePos(vid)
		if ok then
			local x,y,z=matrix.position(pos)
			text=text..string.format(' #%d vid=%d x=%.0f y=%.0f z=%.0f\n', i, vid, x, y, z)
		else
			text=text..string.format(' #%d vid=%d (invalid)\n', i, vid)
		end
	end
	announce(text, peer_id)
end

g_command_aliases={
	j='join',
	l='leave',
	r='ready',
	o='order',
	sh='shuffle',
	sh2='shuffle2',
	sa='shuffle_airbase',
}

-- shuffle2  shuffle
table.insert(g_commands, {
	name='shuffle2',
	desc='Shuffle players (alternate command, alias sh2)',
	admin=false,
	action=function(peer_id, is_admin, is_auth, ...)
		local args={...}
		local team_count = tonumber(args[1]) or 2
		shuffle2(team_count, peer_id)
	end,
})

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
			local desc_str=command_define.desc and '  -- '..command_define.desc or ''
			commands_help=commands_help..'  - ?mm '..command_define.name..args..desc_str..'\n'
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

function scheduleAutoBattle(peer_id)
	if not g_savedata.auto_battle then
		g_auto_battle_state=nil
		return
	end
	g_auto_battle_state={phase='wait_shuffle', timer=60*30, last_countdown=nil}
	announce('Auto battle queued: shuffle in 30 seconds.', peer_id or -1)
end

function processAutoBattle()
	local state=g_auto_battle_state
	if not state then return end
	if g_in_game or g_in_countdown then return end

	state.timer=state.timer-1
	local remain_sec=math.ceil(state.timer/60)
	if remain_sec<0 then remain_sec=0 end
	if (remain_sec%10==0 or remain_sec<=5) and state.last_countdown~=remain_sec then
		local phase_label = state.phase=='wait_shuffle' and 'shuffle' or 'teleport'
		announce('Auto battle countdown ('..phase_label..'): '..tostring(remain_sec), -1)
		state.last_countdown=remain_sec
	end
	if state.timer>0 then return end

	if state.phase=='wait_shuffle' then
		shuffle2(2, 0)
		assignAirbases(0, 20000)
		state.phase='wait_teleport'
		state.timer=60*10
		state.last_countdown=nil
		announce('Auto battle queued: teleport in 10 seconds.', -1)
		return
	end

	if state.phase=='wait_teleport' then
		for peer_id,player in pairs(g_players) do
			if player and player.team then
				local assigned=getAssignedFlagForTeam(player.team)
				if assigned then
					teleportPlayerToAssignedFlag(peer_id)
				end
			end
		end
		g_auto_battle_state=nil
	end
end

-- Callbacks --

function onCreate(is_world_create)
	for k,v in pairs(g_default_savedata) do
		if g_savedata[k]==nil then
			g_savedata[k]=v
		end
	end

	-- 互換性維持: 旧キー `auto_sit_on_spawn` を新キー `auto_link_on_spawn` に移行
	if g_savedata.auto_sit_on_spawn~=nil and g_savedata.auto_link_on_spawn==nil then
		g_savedata.auto_link_on_spawn = g_savedata.auto_sit_on_spawn
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
	if not g_has_webmap then
		announce('Webmap addon not detected. Map display on UI will not work.', 0)
	else
		announce('Webmap addon detected. Map display on UI is enabled.', 0)
	end

	-- OnCreate 時に airports テーブルの x,z が未設定（0）のものを解決する
	resolveAirports()
end

function onDestroy()
	clearPopups()
	clearSupplies()
	clearFlags()
end

function onTick()
	for i=#g_pending_link_requests,1,-1 do
		local req=g_pending_link_requests[i]
		req.delay=req.delay-1
		if req.delay<=0 then
			onPlayerSit_(req.peer_id, req.vehicle_id, '')
			table.remove(g_pending_link_requests, i)
		end
	end

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
			finishGame(false)
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

	-- チームビークル座標の収集（毎tick）
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
		-- 送信すべき値をまとめて計算（encodeCoords は1回のみ）
		local iff_writes={}  -- {{key, value}, ...}
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
					pos.f1,pos.f2=f1,f2
				end
				count=count+1
				iff_writes[tostring(base+count)]=f1
				count=count+1
				iff_writes[tostring(base+count)]=f2
			end
			for slot=count+1,20 do
				iff_writes[tostring(base+slot)]=0
			end
			iff_writes['mm_iff_freq_'..team_idx]=g_iff_freq[team_idx]
		end
		-- 差分のみ全 IFF ビークルに書き込み
		for _,iff_vid in ipairs(g_iff_vehicles) do
			for k,v in pairs(iff_writes) do
				if g_iff_keypad_cache[k]~=v then
					server.setVehicleKeypad(iff_vid,k,v)
				end
			end
		end
		-- キャッシュ更新（最後に1回）
		for k,v in pairs(iff_writes) do
			g_iff_keypad_cache[k]=v
		end
	end
	-- プレイヤービークルに周波数書込み（差分変化時 or 600tick毎に強制再送）
	for _,player in pairs(g_players) do
		if player.alive and player.vehicle_id>=0 then
			for team_idx,team_name in ipairs(g_default_teams) do
				if team_name==player.team and team_idx<=3 then
					local freq=g_iff_freq[team_idx]
					local ck='player_freq_'..player.vehicle_id
					if g_iff_keypad_cache[ck]~=freq or g_freq_force_timer==0 then
						server.setVehicleKeypad(player.vehicle_id,'mm_iff_freq',freq)
						g_iff_keypad_cache[ck]=freq
					end
					break
				end
			end
		end
	end
	g_freq_force_timer=g_freq_force_timer+1
	if g_freq_force_timer>=600 then g_freq_force_timer=0 end

	-- ready催促（20秒ごと、ゲーム開始前のみ）
	g_ready_remind_timer=g_ready_remind_timer+1
	if g_ready_remind_timer>=1200 then
		g_ready_remind_timer=0
		if not g_in_game and not g_in_countdown then
			-- チームごとにready率を集計
			local team_total={}
			local team_ready={}
			for _,player in pairs(g_players) do
				if player.alive and player.team then
					team_total[player.team]=(team_total[player.team] or 0)+1
					if player.ready then
						team_ready[player.team]=(team_ready[player.team] or 0)+1
					end
				end
			end
			-- 未readyプレイヤーへ催促DM
			for pid,player in pairs(g_players) do
				if player.alive and not player.ready and player.team then
					local total=team_total[player.team] or 0
					local rdy=team_ready[player.team] or 0
					if total>0 and rdy/total>=0.5 then
						announce(player.name..' are you ready? -> "?mm ready(?mm r)"',pid)
					end
				end
			end
		end
	end

	processAutoBattle()

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

function enqueueVehicleLinkRequest(peer_id, vehicle_id)
	table.insert(g_pending_link_requests, {
		peer_id=peer_id//1|0,
		vehicle_id=vehicle_id//1|0,
		delay=1,
	})
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
	g_iff_keypad_cache={}  -- IFF台数変化時はキャッシュをクリア
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost, group_id)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	local parent_id=getParentID(group_id, vehicle_id)
	if not g_group_parents[group_id] then
		g_group_parents[group_id]=parent_id
	end
	if vehicle_id==parent_id and g_savedata.auto_link_on_spawn then
		enqueueVehicleLinkRequest(peer_id, vehicle_id)
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

	local args={...}
	for i=#args,1,-1 do
		if args[i]=='' then args[i]=nil end
	end

	-- iff 複合コマンドの解決（"iff create all" など）
	local effective_sub=sub_command
	local arg_offset=0
	if sub_command=='iff' then
		local p1=args[1] or ''
		local p2=args[2] or ''
		if p1~='' and p2~='' and findCommand('iff '..p1..' '..p2) then
			effective_sub='iff '..p1..' '..p2
			arg_offset=2
		elseif p1~='' and findCommand('iff '..p1) then
			effective_sub='iff '..p1
			arg_offset=1
		end
	end

	local command_define=findCommand(effective_sub)
	if not command_define then
		announce('Command "'..effective_sub..'" not found.', peer_id)
		return
	end
	if not checkAuth(command_define, is_admin, is_auth) then
		announce('Permission denied.', peer_id)
		return
	end

	local cmd_args={}
	for i=arg_offset+1,#args do cmd_args[#cmd_args+1]=args[i] end
	if command_define.args and not validateArgs(command_define, cmd_args, peer_id) then
		return
	end
	command_define.action(peer_id, is_admin, is_auth, table.unpack(cmd_args))
end

-- Player Functions --

function join(peer_id, team, force)
	if g_in_game and not force then return end
	local name, is_success=server.getPlayerName(peer_id)
	if not is_success then return end
	local vehicle_id = -1
	if g_players[peer_id] and g_players[peer_id].vehicle_id > 0 then
		vehicle_id = g_players[peer_id].vehicle_id
		server.announce('Existing vehicle_id='..tostring(vehicle_id)..' for peer_id='..peer_id, peer_id)
	end

	local player={
		name=name,
		trimmed_name=trim(name),
		team=team,
		alive=true,
		ready=g_in_game,
		vehicle_id=vehicle_id,
		popup_name='player_status_'..(peer_id//1|0),
	}
	g_players[peer_id]=player

	local character_id=server.getPlayerCharacterID(peer_id)
	local sit_vehicle_id, is_success=server.getCharacterVehicle(character_id)
	if is_success then
		local vehicle=registerVehicle(sit_vehicle_id)
		if vehicle and vehicle.alive then
			player.vehicle_id=sit_vehicle_id
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

function shuffle2(team_count, exec_peer_id)
	-- Constrained shuffle with history and multi-team support
	local peer_list = {}
	for peer_id, player in pairs(g_players) do
		player.ready = false
		table.insert(peer_list, peer_id)
	end
	if #peer_list < 1 then
		announce('Player not enough.', exec_peer_id)
		return
	end
	table.sort(peer_list, function(a,b) return tostring(a) < tostring(b) end)

	team_count = tonumber(team_count) or 2
	if team_count < 2 then team_count = 2 end

	local n = #peer_list
	-- build team names (use g_default_teams when available)
	local teamNames = {}
	for i=1,team_count do teamNames[i] = g_default_teams[i] or ('TEAM'..tostring(i)) end
	-- compute team sizes fairly
	local base = math.floor(n / team_count)
	local r = n % team_count
	local teamSizes = {}
	for i=1,team_count do teamSizes[i] = base + (i <= r and 1 or 0) end

	-- prev map from latest saved history (peer_id -> teamName)
	local prev_map = {}
	if g_savedata.shuffle_history and #g_savedata.shuffle_history > 0 then
		local latest = g_savedata.shuffle_history[1]
		if latest then
			for pid, t in pairs(latest) do prev_map[pid] = t end
		end
	end

	local pairCounts = build_pair_counts()

	--
	local chosenCandidate = heuristic_assign(peer_list, prev_map, pairCounts, teamSizes, teamNames, 12)
	if not chosenCandidate then
		announce('shuffle2: heuristic fallback failed, falling back to simple shuffle.', exec_peer_id)
		shuffle(team_count, exec_peer_id)
		return
	end

	local stage = 'strict'
	local chosen = chosenCandidate
	if not chosenCandidate then
		-- compute maxSame per team (ceil(teamSize * 0.4))
		local maxSame = {}
		for i=1,#teamSizes do maxSame[i] = math.min(teamSizes[i], math.ceil(MAX_SAME_RATIO * teamSizes[i])) end

		-- find valids under strict limits
		local valids = {}
		for _, ci in ipairs(candidates) do
			local ok = true
			for t=1,#maxSame do if ci.sameCounts[t] > maxSame[t] then ok = false; break end end
			if ok then table.insert(valids, ci) end
		end

		local relaxLevel = 0
		local maxTeamSize = 0
		for i=1,#teamSizes do if teamSizes[i] > maxTeamSize then maxTeamSize = teamSizes[i] end end
		while #valids == 0 and relaxLevel <= maxTeamSize do
			relaxLevel = relaxLevel + 1
			local ms = {}
			for i=1,#maxSame do ms[i] = maxSame[i] + relaxLevel end
			for _, ci in ipairs(candidates) do
				local ok = true
				for t=1,#ms do if ci.sameCounts[t] > ms[t] then ok = false; break end end
				if ok then table.insert(valids, ci) end
			end
			if #valids > 0 then stage = 'relaxed+'..tostring(relaxLevel); break end
		end

		local function scoreOf(ci) return ci.pairPenalty end

		if #valids > 0 then
			local minScore = math.huge
			local bests = {}
			for _, ci in ipairs(valids) do
				local s = scoreOf(ci)
				if s < minScore then minScore = s; bests = {ci}
				elseif s == minScore then table.insert(bests, ci) end
			end
			chosen = bests[math.random(1, #bests)]
		else
			stage = 'minPenalty'
			local minScore = math.huge
			local bests = {}
			for _, ci in ipairs(candidates) do
				local violation = 0
				for t=1,#maxSame do
					local v = ci.sameCounts[t] - maxSame[t]
					if v > 0 then violation = violation + v end
				end
				local s = violation * SHUFFLE_VIOLATION_WEIGHT + scoreOf(ci)
				if s < minScore then minScore = s; bests = {ci}
				elseif s == minScore then table.insert(bests, ci) end
			end
			chosen = bests[math.random(1, #bests)]
		end
	else
		stage = 'heuristic'
	end

	-- apply assignment
	for t=1,#chosen.teams do
		local teamName = teamNames[t]
		for _, pid in ipairs(chosen.teams[t]) do
			g_players[pid].team = teamName
			announce('You joined to '..teamName..'.', pid)
			if g_has_webmap then
				local vehicle = findVehicle(g_players[pid].vehicle_id)
				if vehicle and vehicle.alive then
					bindVehicleTeamToWebMap(g_players[pid].vehicle_id, teamName)
				end
			end
		end
	end

	stopCountdown()
	g_team_status_dirty = true
	g_player_status_dirty = true

	-- save history ()
	g_savedata.shuffle_history = g_savedata.shuffle_history or {}
	local roundMap = {}
	for _, pid in ipairs(peer_list) do roundMap[pid] = g_players[pid].team end
	table.insert(g_savedata.shuffle_history, 1, roundMap)
	while #g_savedata.shuffle_history > SHUFFLE_HISTORY_K do table.remove(g_savedata.shuffle_history) end

	--全体にシャッフル完了を通知
	announce('Teams shuffled!', -1)
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
		-- チーム内の準備完了人数をカウント
		local team_ready_count=0
		local team_total_count=0
		for p_id,p in pairs(g_players) do
			if p.team==player.team and p.alive then
				team_total_count=team_total_count+1
				if p.ready then
					team_ready_count=team_ready_count+1
				end
			end
		end
		announce(player.name..' is ready! ('..team_ready_count..'/'..team_total_count..')', -1)
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
		gc_time=60,
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
	--server.announce("bindVehicleTeamToWebMap",0)
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
	--server.announce("cmd",cmd)
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
		finishGame(false)
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

	finishGame(false)
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
	g_auto_battle_state=nil
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

	if g_has_webmap then
		local cmd = '?wm max_hp ' .. tostring(g_savedata.vehicle_hp)
		server.command(cmd)
		cmd = "?wm max_damage " .. tostring(g_savedata.max_damage)
		server.command(cmd)
	end
end

function finishGame(keep_airbase)
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

	-- clear flag assignments unless caller requested to keep them
	if not keep_airbase then
		clearFlagAssignments(false)
		scheduleAutoBattle(-1)
	else
		g_auto_battle_state=nil
	end
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
		if string.lower(name) == 'red' then
			g_flag_assignments.RED = { idx = -1, name = name, x = tonumber(x), z = tonumber(z), y = y }
		elseif string.lower(name) == 'blue' then
			g_flag_assignments.BLUE = { idx = -1, name = name, x = tonumber(x), z = tonumber(z), y = y }
		end
	end
end

function spawnFlagAt(peer_id, name, x, z ,y, flag_under_spawn)
	if not x or not z then
		announce('Invalid coordinates for flag spawn.', peer_id)
		return
	end
	-- remove existing flag with same name
	despawnFlag(peer_id, name)
	--yが指定されていない場合は-100にする。これにより、地面に埋まる可能性があるが、少なくとも空中に浮かぶことはない。
	local altitude = 0
	if flag_under_spawn and y and y > 0 then
		altitude = -100
	else
		altitude = y
	end
	local vehicle_matrix = matrix.translation(tonumber(x) or 0, altitude, tonumber(z) or 0)
	local vehicle_id = spawnAddonVehicle('flag', vehicle_matrix)

	if vehicle_id then
		server.setVehicleTooltip(vehicle_id, name)
		local ui_id = server.getMapID()
		local r, g, b, a = getColor(name)
		server.addMapObject(-1, ui_id, 1, 9, x, z, 0, 0, vehicle_id, 0, name, g_flag_radius, name, r, g, b, a)
		g_savedata.flag_vehicles[name] = {
			vehicle_id = vehicle_id,
			ui_id = ui_id,
		}
		if string.lower(name) == 'red' then
			g_flag_assignments.RED = { idx = -1, name = name, x = tonumber(x), z = tonumber(z), y = y }
		elseif string.lower(name) == 'blue' then
			g_flag_assignments.BLUE = { idx = -1, name = name, x = tonumber(x), z = tonumber(z), y = y }
		end
	else
		announce('Failed to spawn flag "' .. name .. '"', peer_id)
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
	return table.unpack(g_colors[string.lower(name)] or g_color_default)
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
g_iff_keypad_cache={}  -- {[vid]={[key]=value}}
g_decoded_names={}
