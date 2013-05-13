-- The Idle State- For solo botting

-- We inherit from wt_core_state, which gives us: function wt_core_state:run(), function wt_core_state:add( kelement ) and function wt_core_state:register()
wt_core_state_idle = inheritsFrom( wt_core_state )
wt_core_state_idle.name = "Idle"
wt_core_state_idle.kelement_list = { }
wt_core_state_idle.TaskChecks = {}

------------------------------------------------------------------------------
-- MultiBotComServerConnect Cause & Effect
local c_iamminion = inheritsFrom( wt_cause )
local e_iamminion = inheritsFrom( wt_effect )
function c_iamminion:evaluate()
	if (gMinionEnabled == "1" and MultiBotIsConnected( )) then		
		return true
	end	
	return false
end
function e_iamminion:execute()
	if ( Player:GetRole() == 1) then
		if (tonumber(Player.characterID) ~= nil) then
			MultiBotSend( "1;"..tonumber(Player.characterID),"gw2minion" ) -- Spam send who is the Leader
		end
		wt_debug( "Switching to - LEADER" )
		wt_core_controller.requestStateChange( wt_core_state_leader )
	else
		local party = Player:GetPartyMembers()
		if (party ~= nil) then
			if ( Settings.GW2MINION.gLeaderID == nil or party[tonumber(Settings.GW2MINION.gLeaderID)] == nil ) then				
				MultiBotJoinChannel("gw2minion")
				MultiBotSend( "2;none","gw2minion" )				
			end
		end
		wt_debug( "Switching to - MINION" )
		wt_core_controller.requestStateChange( wt_core_state_minion )
	end
end


------------------------------------------------------------------------------
-- DepositItems Cause & Effect
local c_deposit = inheritsFrom( wt_cause )
local e_deposit = inheritsFrom( wt_effect )
function c_deposit:evaluate()
	if ( ItemList.freeSlotCount <= 2 ) then
		if ( wt_global_information.InventoryFull == 0 ) then
			return true
		else
			return false -- already tried to deposit stuff, still have 0 space in inventory -> vendoringcheck will jump in
		end
	else
		wt_global_information.InventoryFull = 0
	end
	return false
end
e_deposit.throttle = 500
function e_deposit:execute()
	wt_debug( "Idle: Deposing Collectables.." )
	wt_global_information.InventoryFull = 1
	Inventory:DepositCollectables()
end


------------------------------------------------------------------------------
-- Gatherbale Cause & Effect
local c_check_gatherable = inheritsFrom( wt_cause )
local e_gather = inheritsFrom( wt_effect )
c_check_gatherable.throttle = 1000
function c_check_gatherable:evaluate()
	if ( gDoGathering == "0" ) then
		return false
	end
	if ( ItemList.freeSlotCount > 0 ) then		
		c_check_gatherable.EList = GadgetList( "onmesh,shortestpath,gatherable,maxdistance="..wt_global_information.MaxGatherDistance )
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


function wt_core_state_idle:initialize()

	local ke_died = wt_kelement:create( "Died", c_died, e_died, wt_effect.priorities.interrupt )
	wt_core_state_idle:add( ke_died )
	
	local ke_iamminion = wt_kelement:create( "MultiBotServerCheck", c_iamminion, e_iamminion, 250 )
	wt_core_state_idle:add( ke_iamminion )	
	
	local ke_quickloot = wt_kelement:create( "QuickLoot", c_quickloot, e_quickloot, 110 )
	wt_core_state_idle:add( ke_quickloot )
	
	--local ke_quicklootchest = wt_kelement:create( "QuickLootChest", c_quicklootchest, e_quicklootchest, 105 )
	--wt_core_state_idle:add( ke_quicklootchest )
	
	local ke_lootchests = wt_kelement:create("LootChest", c_lootchest, e_lootchest, 104 )
	wt_core_state_idle:add( ke_lootchests )
	
	local ke_doemertasks = wt_kelement:create( "EmergencyTask", c_doemergencytask, e_doemergencytask, 103 )
	wt_core_state_idle:add( ke_doemertasks )

	local ke_deposit = wt_kelement:create( "DepositItems", c_deposit, e_deposit, 95 )
	wt_core_state_idle:add( ke_deposit )

	local ke_loot = wt_kelement:create("Loot", c_check_loot, e_loot, 90 )
	wt_core_state_idle:add( ke_loot )
	
	--89 salvage
	
	local ke_revive_players = wt_kelement:create( "RevivePlayers", c_check_revive_players, e_revive_players, 88 )
	wt_core_state_idle:add( ke_revive_players )
	
	local ke_dopriotasks = wt_kelement:create( "PrioTask", c_dopriotask, e_dopriotask, 87 )
	wt_core_state_idle:add( ke_dopriotasks )
	
	local ke_switchmesh = wt_kelement:create( "SwitchNavMesh", c_navswitch, e_navswitch, 86 )
	wt_core_state_idle:add( ke_switchmesh )
	
	local ke_revive = wt_kelement:create( "Revive", c_check_revive, e_revive, 80 )
	wt_core_state_idle:add( ke_revive )
	
	--leave shroud from necro , prio 76
	local ke_rest = wt_kelement:create( "Rest", c_rest, e_rest, 75 )
	wt_core_state_idle:add( ke_rest )

	local ke_gather = wt_kelement:create( "Gather", c_check_gatherable, e_gather, 40 )
	wt_core_state_idle:add( ke_gather )

	local ke_dotasks = wt_kelement:create( "DoTask", c_dotask, e_dotask, 35 )
	wt_core_state_idle:add( ke_dotasks )

end

-- setup kelements for the state
wt_core_state_idle:initialize()
-- register the State with the system
wt_core_state_idle:register()

--Only put tasks here which are solo bot specific...any other tasks that are shared
--should go in wt_core_taskmanager:Update_Tasks()

--UID = "REPAIR"
--Throttle = 2500
function wt_core_state_idle.repairCheck()
	--wt_debug("repairCheck")
	if ( gEnableRepair == "1" and NeedRepair() and not wt_core_taskmanager:CheckTaskQueue("REPAIR")) then
		local repairList = MapObjectList( "onmesh,nearest,type="..GW2.MAPOBJECTTYPE.RepairMerchant )
		if ( TableSize( repairList ) > 0 ) then
			local nextTarget
			nextTarget, E = next( repairList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then
				wt_core_taskmanager:addRepairTask(4500)
			end
		end
	end	
end
table.insert(wt_core_state_idle.TaskChecks,{["func"]=wt_core_state_idle.repairCheck,["throttle"]=2500})

--UID = "VENDORSELL"
--Throttle = 2500
function wt_core_state_idle.vendorSellCheck()
	--wt_debug("vendorSellCheck")
	if ( ItemList.freeSlotCount <= 3 and wt_global_information.InventoryFull == 1 and not wt_core_taskmanager:CheckTaskQueue("VENDORSELL")) then
	local vendorList = MapObjectList( "onmesh,nearest,type="..GW2.MAPOBJECTTYPE.Merchant )
		if ( TableSize( vendorList ) > 0 ) then
			local nextTarget
			nextTarget, E = next( vendorList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then
				wt_core_taskmanager:addVendorTask(5000)
			end
		end
	end
end
table.insert(wt_core_state_idle.TaskChecks,{["func"]=wt_core_state_idle.vendorSellCheck,["throttle"]=2500})

--UID = "VENDORBUY..."
--Throttle = 2500
function wt_core_state_idle.vendorBuyCheck()
	--wt_debug("vendorBuyCheck")
	if 	(gBuyGatheringTools == "1" and wt_core_items:NeedGatheringTools() and ItemList.freeSlotCount > tonumber(gGatheringToolStock)) or
		(gBuySalvageKits == "1" and wt_core_items:NeedSalvageKits() and ItemList.freeSlotCount > tonumber(gSalvageKitStock)) and
		(not wt_core_taskmanager:CheckTaskQueue("VENDORBUY")) 
	then	
		local vendorList = MapObjectList( "onmesh,nearest,type="..GW2.MAPOBJECTTYPE.Merchant )
		if ( TableSize( vendorList ) > 0 ) then
			local nextTarget
			nextTarget, E = next( vendorList )
			if ( nextTarget ~= nil and nextTarget ~= 0 ) then
				if (wt_core_items:NeedGatheringTools() and gBuyGatheringTools == "1") then
					wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.ftool, tonumber(gGatheringToolStock),gGatheringToolQuality)
					wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.ltool, tonumber(gGatheringToolStock),gGatheringToolQuality)
					wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.mtool, tonumber(gGatheringToolStock),gGatheringToolQuality)
				end
				if (wt_core_items:NeedSalvageKits() and gBuySalvageKits == "1") then
					wt_core_taskmanager:addVendorBuyTask(4750, wt_core_items.skit, tonumber(gSalvageKitStock),gSalvageKitQuality)
				end
			end
		end
	end
end
table.insert(wt_core_state_idle.TaskChecks,{["func"]=wt_core_state_idle.vendorBuyCheck,["throttle"]=2500})

--Throttle = 500
function wt_core_state_idle.aggroCheck()
	--wt_debug("aggroCheck")
	if ( Player.inCombat ) then
		local TList = ( CharacterList( "attackable,alive,noCritter,nearest,los,incombat,onmesh,maxdistance="..wt_global_information.MaxAggroDistanceFar ) )
		if ( TableSize( TList ) > 0 ) then
			local id, E  = next( TList )
			if ( id ~= nil and id ~= 0 and E ~= nil) then
				wt_core_taskmanager:addKillTask( id, E, 3000 )
				return false
			end		
		end
	end
	
	local TList = ( CharacterList( "nearest,attackable,alive,noCritter,onmesh,maxdistance="..wt_global_information.MaxAggroDistanceClose ) )
	if ( TableSize( TList ) > 0 ) then
		local id, E  = next( TList )
		if ( id ~= nil and id ~= 0 and E ~= nil) then
			wt_core_taskmanager:addKillTask( id, E, 2500 )
			return false
		end		
	end	
	return false
end
table.insert(wt_core_state_idle.TaskChecks,{["func"]=wt_core_state_idle.aggroCheck,["throttle"]=500})