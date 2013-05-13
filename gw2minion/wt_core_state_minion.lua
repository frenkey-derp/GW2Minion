-- The Minion's Minion State ;)

wt_core_state_minion = inheritsFrom(wt_core_state)
wt_core_state_minion.name = "Minion"
wt_core_state_minion.kelement_list = { }
wt_core_state_minion.IdleTmr = 0
wt_core_state_minion.TaskChecks = {}

------------------------------------------------------------------------------
-- NoLeader Cause & Effect
local c_noleader = inheritsFrom( wt_cause )
local e_noleader = inheritsFrom( wt_effect )
c_noleader.throttle = math.random( 1000, 3000 )
function c_noleader:evaluate()
	if ( Settings.GW2MINION.gLeaderID ~= nil) then
		local party = Player:GetPartyMembers()
		if (party ~= nil) then
			local leader = party[tonumber(Settings.GW2MINION.gLeaderID)]
			if (leader ~= nil) then
				return false
			end		
		end	
	end
	return true
end
e_noleader.throttle = math.random( 1000, 3000 )
function e_noleader:execute()
	wt_debug( "Leader is gone? ..reseting state" )
	wt_core_controller.requestStateChange( wt_core_state_idle )
end


-- Aggro is in wt_common_causes

-- DepositItems is in wt_common_causes

-- Search for Reviveable Partymembers is in wt_common_causes
  
  
-- Search for Reviveable Targets is in wt_common_causes


-- Loot is in wt_common_causes


-- LootChest is in wt_common_causes


------------------------------------------------------------------------------
-- Kill FocusTarget Cause & Effect
local c_focus = inheritsFrom( wt_cause )
local e_focus = inheritsFrom( wt_effect )
function c_focus:evaluate()
	-- kill focus target
	if ( wt_global_information.FocusTarget ~= nil ) then
		local target = CharacterList:Get(tonumber(wt_global_information.FocusTarget))
		if ( target ~= nil and target.distance < 4000 and target.alive and target.onmesh) then
			return true
		end
	end
	wt_global_information.FocusTarget = nil
	return false
end
function e_focus:execute()
	if ( wt_global_information.FocusTarget ~= nil ) then
		local target = CharacterList:Get(tonumber(wt_global_information.FocusTarget))
		if ( target ~= nil and target.distance < 4000 and target.alive and target.onmesh) then
			wt_debug( "Attacking Focustarget" )
			wt_core_state_combat.setTarget( wt_global_information.FocusTarget )
			wt_core_controller.requestStateChange( wt_core_state_combat )
		end
	end
end

------------------------------------------------------------------------------
-- Gatherable Cause & Effect
local c_check_gatherable = inheritsFrom( wt_cause )
local e_gather = inheritsFrom( wt_effect )
c_check_gatherable.throttle = 1000
function c_check_gatherable:evaluate()
	if ( gDoGathering == "0" ) then
		return false
	end
	if ( ItemList.freeSlotCount > 0 ) then		
		c_check_gatherable.EList = GadgetList( "onmesh,shortestpath,gatherable,maxdistance=1200")
		if ( TableSize( c_check_gatherable.EList ) > 0 ) then
			local nextTarget
			nextTarget, GatherTarget = next( c_check_gatherable.EList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then
				return true
			end
		end
	end
	return false
end
function e_gather:execute()
	if ( TableSize( c_check_gatherable.EList ) > 0 ) then
		local nextTarget
		nextTarget, E  = next( c_check_gatherable.EList )
		if ( nextTarget ~= nil and nextTarget ~= 0 ) then
			wt_debug( "Gatherable Target found.." )
			wt_core_state_gathering.setTarget( nextTarget )
			wt_core_controller.requestStateChange( wt_core_state_gathering )
		end
	end
end

------------------------------------------------------------------------------
-- Follow Leader Cause & Effect
local c_followLead = inheritsFrom( wt_cause )
local e_followLead = inheritsFrom( wt_effect )
function c_followLead:evaluate()
	if (Player:GetRole() ~= 1 and Settings.GW2MINION.gLeaderID ~= nil) then
		local party = Player:GetPartyMembers()
		if (party ~= nil) then
			local leader = party[tonumber(Settings.GW2MINION.gLeaderID)]
			if (leader ~= nil) then
				if ((leader.distance > math.random(100,400) or leader.los~=true) and leader.onmesh) then
					return true
				end		
				-- TIMER for random movement when leader is standing on a spot too long, this should go in a seperate C&E ..but I'm lazy
				if ( Player.movementstate == GW2.MOVEMENTSTATE.GroundNotMoving and wt_global_information.Now - wt_core_state_minion.IdleTmr > math.random(5000,30000) ) then
					return true					
				end
			else
				return true
			end		
		end
	end
	return false
end
e_followLead.throttle = math.random( 400, 1000 )
function e_followLead:execute()
	local party = Player:GetPartyMembers()
	if (party ~= nil and Settings.GW2MINION.gLeaderID ~= nil) then
		local leader = party[tonumber(Settings.GW2MINION.gLeaderID)]
		if (leader ~= nil) then
			if ((leader.distance > math.random(100,400) or leader.los~=true) and leader.onmesh) then
				local pos = leader.pos
				if (leader.movementstate == GW2.MOVEMENTSTATE.GroundMoving) then
					--wt_debug("PREDICT")
					--Player:MoveToPredict(pos.x,pos.y,pos.z,pos.hx,pos.hy,pos.hz);
					Player:MoveToRandom(pos.x,pos.y,pos.z,350);
				else				
					Player:MoveToRandomPointAroundCircle(pos.x,pos.y,pos.z,550);
				end
				wt_core_state_minion.IdleTmr = wt_global_information.Now
				return
			end
			
			if ( Player.movementstate == GW2.MOVEMENTSTATE.GroundNotMoving and wt_global_information.Now - wt_core_state_minion.IdleTmr > math.random(5000,30000) ) then
				wt_core_state_minion.IdleTmr = wt_global_information.Now
				wt_core_state_minion.IdleTmr = wt_core_state_minion.IdleTmr + math.random(5000,10000)
				local pos = leader.pos
				Player:MoveToRandomPointAroundCircle(pos.x,pos.y,pos.z,550);
			end
		else
			wt_debug( "Leader is not in our map or there is no leader anymore?" )
			wt_debug( "Asking for leader.." )				
			wt_core_controller.requestStateChange( wt_core_state_idle )
		end
	end
end
 
 
function wt_core_state_minion:initialize()

		
	-- State C&E
	local ke_died = wt_kelement:create( "Died", c_died, e_died, wt_effect.priorities.interrupt )
	wt_core_state_minion:add( ke_died )
			
	local ke_quickloot = wt_kelement:create( "QuickLoot", c_quickloot, e_quickloot, 110 )
	wt_core_state_minion:add( ke_quickloot )
	
	--local ke_quicklootchest = wt_kelement:create( "QuickLootChest", c_quicklootchest, e_quicklootchest, 105 )
	--wt_core_state_minion:add( ke_quicklootchest )
		
	local ke_lootchests = wt_kelement:create("LootChest", c_lootchest, e_lootchest, 105 )
	wt_core_state_minion:add( ke_lootchests )

	local ke_switchmesh = wt_kelement:create( "SwitchNavMesh", c_navswitch, e_navswitch, 104)
	wt_core_state_minion:add( ke_switchmesh )
	
	local ke_doemertasks = wt_kelement:create( "EmergencyTask", c_doemergencytask, e_doemergencytask, 103 )
	wt_core_state_minion:add( ke_doemertasks )
	
	local ke_noleader = wt_kelement:create( "NoLeader", c_noleader, e_noleader, 102 )
	wt_core_state_minion:add( ke_noleader )	

	local ke_revparty = wt_kelement:create( "ReviveParty", c_revivep, e_revivep, 101 )
	wt_core_state_minion:add( ke_revparty )
	
	local ke_deposit = wt_kelement:create( "DepositItems", c_deposit, e_deposit, 90 )
	wt_core_state_minion:add( ke_deposit )
	--salvaging 89

	
	local ke_loot = wt_kelement:create("Loot", c_check_loot, e_loot, 89 )
	wt_core_state_minion:add( ke_loot )
	
	local ke_revive_players = wt_kelement:create( "RevivePlayers", c_check_revive_players, e_revive_players, 88 )
	wt_core_state_minion:add( ke_revive_players )
	
	local ke_dopriotasks = wt_kelement:create( "PrioTask", c_dopriotask, e_dopriotask, 85 )
	wt_core_state_minion:add( ke_dopriotasks )
		
	local ke_revive = wt_kelement:create( "Revive", c_check_revive, e_revive, 80 )
	wt_core_state_minion:add( ke_revive )

	local ke_rest = wt_kelement:create( "Rest", c_rest, e_rest, 75 )
	wt_core_state_minion:add( ke_rest )
	
	local ke_atkfocus = wt_kelement:create("FocusAtk", c_focus, e_focus, 45 )
	wt_core_state_minion:add( ke_atkfocus )
	
	local ke_gather = wt_kelement:create( "Gather", c_check_gatherable, e_gather, 40 )
	wt_core_state_minion:add( ke_gather )
	
	local ke_sticktoleader = wt_kelement:create( "Follow Leader", c_followLead, e_followLead, 20 )
	wt_core_state_minion:add( ke_sticktoleader )
		
end

wt_core_state_minion:initialize()
wt_core_state_minion:register()

--Only put tasks here which are solo bot specific...any other tasks that are shared
--should go in wt_core_taskmanager:Update_Tasks()

--UID = "REPAIR"
--Throttle = 2500
function wt_core_state_minion:repairCheck()
	if ( gEnableRepair == "1" and NeedRepair() and wt_core_taskmanager:CheckTaskQueue("REPAIR") == nil) then
		local repairList = MapObjectList( "onmesh,maxdistance=5000,type="..GW2.MAPOBJECTTYPE.RepairMerchant )
		if ( TableSize( repairList ) > 0 ) then
			local nextTarget
			nextTarget, E = next( repairList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then
				wt_core_taskmanager:addRepairTask(4500)
			end
		elseif ( gMinionEnabled == "1" and MultiBotIsConnected( ) ) then
			MultiBotSend( "15;0","gw2minion" )
		end
	end
end
table.insert(wt_core_state_minion.TaskChecks,{["func"]=wt_core_state_minion.repairCheck, ["throttle"]=2500})

--UID = "VENDORSELL"
--Throttle = 2500
function wt_core_state_minion:vendorSellCheck()
	if ( ItemList.freeSlotCount <= 3 and wt_global_information.InventoryFull == 1 and wt_core_taskmanager:CheckTaskQueue("VENDORSELL") == nil) then
		local vendorList = MapObjectList( "onmesh,maxdistance=5000,type="..GW2.MAPOBJECTTYPE.Merchant )
		if ( TableSize( vendorList ) > 0 ) then
			local nextTarget
			nextTarget, E = next( vendorList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then				
				wt_core_taskmanager:addVendorTask(5000)
			end
		elseif ( gMinionEnabled == "1" and MultiBotIsConnected( ) ) then
			MultiBotSend( "10;0","gw2minion" )
		end
	end
end
table.insert(wt_core_state_minion.TaskChecks,{["func"]=wt_core_state_minion.vendorSellCheck, ["throttle"]=2500})

--UID = "VENDORBUY..."
--Throttle = 2500
function wt_core_state_minion:vendorBuyCheck()
	if 	(gBuyGatheringTools == "1" and wt_core_items:NeedGatheringTools() and ItemList.freeSlotCount > tonumber(gGatheringToolStock)) or
		(gBuySalvageKits == "1" and wt_core_items:NeedSalvageKits() and ItemList.freeSlotCount > tonumber(gSalvageKitStock)) and
		(wt_core_taskmanager:CheckTaskQueue("VENDORBUY") == nil) 
	then	
		local vendorList = MapObjectList( "onmesh,maxdistance=5000,type="..GW2.MAPOBJECTTYPE.Merchant )
		if ( TableSize( vendorList ) > 0 ) then
			local nextTarget
			nextTarget, E = next( vendorList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then				
				if (wt_core_items:NeedGatheringTools()) then
				wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.ftool, tonumber(gGatheringToolStock),gGatheringToolQuality)
				wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.ltool, tonumber(gGatheringToolStock),gGatheringToolQuality)
				wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.mtool, tonumber(gGatheringToolStock),gGatheringToolQuality)
				end
				if (wt_core_items:NeedSalvageKits()) then
					wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.skit, tonumber(gSalvageKitStock),gSalvageKitQuality)
				end
			end
		elseif ( gMinionEnabled == "1" and MultiBotIsConnected( ) ) then
			MultiBotSend( "12;0","gw2minion" )
		end
	end
end
table.insert(wt_core_state_minion.TaskChecks,{["func"]=wt_core_state_minion.vendorBuyCheck, ["throttle"]=2500})

--Throttle = 500
function wt_core_state_minion:aggroCheck()
	local TList = ( CharacterList( "nearest,los,incombat,attackable,alive,noCritter,onmesh,maxdistance="..wt_global_information.MaxAggroDistanceClose ) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil) then
			wt_core_taskmanager:addKillTask( id, E, 3000 )
			MultiBotSend( "6;"..tonumber(id),"gw2minion" )	-- Inform leader about our aggro target
			return false
		end		
	end
end
table.insert(wt_core_state_minion.TaskChecks,{["func"]=wt_core_state_minion.aggroCheck, ["throttle"]=500})