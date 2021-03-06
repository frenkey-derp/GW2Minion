gw2minion = {}
gw2minion.btreecontext = {}

function gw2minion.Init()
	-- Register Button 
	local gw2mainmenu = {
		header = { id = "GW2MINION##MENU_HEADER", expanded = false, name = "GW2Minion", texture = GetStartupPath().."\\GUI\\UI_Textures\\gw2minion.png"},
		members = {{ id = "GW2MINION##MENU_ADDONS", name = "Addons", tooltip = "Installed Lua Addons.", texture = GetStartupPath().."\\GUI\\UI_Textures\\addon.png"}	}
	} 
	ml_gui.ui_mgr:AddComponent(gw2mainmenu)
	
	-- Set UI / Options	 
	ToggleUIOption(1,true)	-- AOE Loot in interact
	ToggleUIOption(2,true)-- AOE Autoloot
	ToggleUIOption(36,false) -- Evade on double tab direction keys

	-- Setup GuestServerList
	gw2minion.RefreshGuestServers()	
	
	-- setup meshmanager
	if ( ml_mesh_mgr ) then 
		ml_mesh_mgr.GetMapID = function () return Player:GetLocalMapID() end
		ml_mesh_mgr.GetMapName = function () return gw2_datamanager.GetMapName(Player:GetLocalMapID())  end
		ml_mesh_mgr.GetPlayerPos = function () return Player.pos end

		-- Set worldnavigation data
		ml_mesh_mgr.navData = {} -- Holds the data for world navigation
		function ml_mesh_mgr.SetupNavNodes()
			ml_nav_manager.nodes = {}
			for id, neighbors in pairs(ml_mesh_mgr.navData) do
				local node = ml_node:Create()
				if (table.valid(node)) then
					node.id = id
					for nid, posTable in pairs(neighbors) do
						node:AddNeighbor(nid, posTable)
					end
					ml_nav_manager.AddNode(node)
				end
			end
		end
		ml_mesh_mgr.navData = persistence.load(GetLuaModsPath()..[[GW2Minion\]].."worldnav_data.lua")
		if ( not table.valid(ml_mesh_mgr.navData)) then 
			ml_mesh_mgr.navData = {} 
		else
			ml_mesh_mgr.SetupNavNodes()
		end
		
		-- Set default meshes SetDefaultMesh(mapid, filename)
		local enforce = false
		if(Settings.GW2Minion.newnav == nil) then
			Settings.GW2Minion.newnav = true
			enforce = true
		end
		
		ml_mesh_mgr.SetDefaultMesh(15,"Queensdale",enforce)
		ml_mesh_mgr.SetDefaultMesh(17,"Harathi Hinterlands",enforce)
		ml_mesh_mgr.SetDefaultMesh(19,"Plains of Ashford",enforce)
		ml_mesh_mgr.SetDefaultMesh(20,"Blazeridge Steppes",enforce)
		ml_mesh_mgr.SetDefaultMesh(21,"Fields of Ruin",enforce)
		ml_mesh_mgr.SetDefaultMesh(22,"Fireheart Rise",enforce)
		ml_mesh_mgr.SetDefaultMesh(23,"Kessex Hills",enforce)
		ml_mesh_mgr.SetDefaultMesh(24,"Gendarran Fields",enforce)
		ml_mesh_mgr.SetDefaultMesh(25,"Iron Marches",enforce)
		ml_mesh_mgr.SetDefaultMesh(26,"Dredgehaunt Cliffs",enforce)
		ml_mesh_mgr.SetDefaultMesh(27,"Lonar's Pass",enforce)
		ml_mesh_mgr.SetDefaultMesh(28,"Wayfarer Foothills",enforce)
		ml_mesh_mgr.SetDefaultMesh(29,"Timberline Falls",enforce)
		ml_mesh_mgr.SetDefaultMesh(30,"Frostgorge Sound",enforce)
		ml_mesh_mgr.SetDefaultMesh(31,"Snowden Drifts",enforce)
		ml_mesh_mgr.SetDefaultMesh(32,"Diessa Plateau",enforce)
		ml_mesh_mgr.SetDefaultMesh(34,"Caledon Forest",enforce)
		ml_mesh_mgr.SetDefaultMesh(35,"Metrica Province",enforce)
		ml_mesh_mgr.SetDefaultMesh(39,"Mount Maelstrom",enforce)
		
		ml_mesh_mgr.SetDefaultMesh(51,"Straits of Devastation",enforce)
		ml_mesh_mgr.SetDefaultMesh(53,"Sparkfly Fen",enforce)
		ml_mesh_mgr.SetDefaultMesh(54,"Brisban Wildlands",enforce)
		
		ml_mesh_mgr.SetDefaultMesh(62,"CursedShore",enforce)
		ml_mesh_mgr.SetDefaultMesh(65,"Malchor's Leap",enforce)
		ml_mesh_mgr.SetDefaultMesh(73,"Bloodtide Coast",enforce)
		
		-- Lions Arch
		ml_mesh_mgr.SetDefaultMesh(50,"Lion's Arch",enforce)
		-- Black Citadel
		ml_mesh_mgr.SetDefaultMesh(218,"Black Citadel",enforce)
		ml_mesh_mgr.SetDefaultMesh(371,"Hero's Canton (Home)",enforce)
		ml_mesh_mgr.SetDefaultMesh(833,"Ash Tribune Quarters",enforce)
		ml_mesh_mgr.SetDefaultMesh(460,"Citadel Stockade",enforce)
		ml_mesh_mgr.SetDefaultMesh(372,"Blood Tribune Quarters",enforce)
		ml_mesh_mgr.SetDefaultMesh(373,"The Command Core",enforce)
		-- Divitnity's Reach
		ml_mesh_mgr.SetDefaultMesh(18,"Divinity's Reach",enforce)
		ml_mesh_mgr.SetDefaultMesh(378,"Queen's Throne Room",enforce)
		ml_mesh_mgr.SetDefaultMesh(248,"Salma District (Home)",enforce)
		ml_mesh_mgr.SetDefaultMesh(914,"The Dead End",enforce)
		ml_mesh_mgr.SetDefaultMesh(330,"Seraph Headquarters",enforce)
		-- Hoelbrak
		ml_mesh_mgr.SetDefaultMesh(326,"Hoelbrak",enforce)
		ml_mesh_mgr.SetDefaultMesh(374,"Knut Whitebear's Loft",enforce)
		ml_mesh_mgr.SetDefaultMesh(375,"Hunter's Hearth (Home)",enforce)
		ml_mesh_mgr.SetDefaultMesh(376,"Stonewright's Steading",enforce)
		-- Rata Sum
		ml_mesh_mgr.SetDefaultMesh(139,"Rata Sum",enforce)
		ml_mesh_mgr.SetDefaultMesh(650,"Applied Development Lab (Home)",enforce)
		ml_mesh_mgr.SetDefaultMesh(651,"Council Level",enforce)
		ml_mesh_mgr.SetDefaultMesh(649,"Snaff Memorial Lab",enforce)
		-- The Grove
		ml_mesh_mgr.SetDefaultMesh(91,"The Grove",enforce)
		ml_mesh_mgr.SetDefaultMesh(647,"Dreamer's Terrace (Home)",enforce)
		ml_mesh_mgr.SetDefaultMesh(646,"The House of Caithe",enforce)
		ml_mesh_mgr.SetDefaultMesh(648,"The Omphalos Chamber",enforce)
				
		ml_mesh_mgr.SetDefaultMesh(350,"Heart of the Mists",enforce)
		ml_mesh_mgr.SetDefaultMesh(873,"Southsun Cove",enforce)
		ml_mesh_mgr.SetDefaultMesh(968,"Edge of the Mists",enforce)
		
		--LS2
		ml_mesh_mgr.SetDefaultMesh(988,"Dry Top",enforce)
		ml_mesh_mgr.SetDefaultMesh(1015,"The Silverwastes",enforce)
		
		--HoT
		ml_mesh_mgr.SetDefaultMesh(1052,"Verdant Brink",enforce)
		ml_mesh_mgr.SetDefaultMesh(1043,"Auric Basin",enforce)
		ml_mesh_mgr.SetDefaultMesh(1041,"Dragon's Stand",enforce)
		ml_mesh_mgr.SetDefaultMesh(1045,"Tangled Depths",enforce)
		ml_mesh_mgr.SetDefaultMesh(1155,"Lion's Arch Aerodrome",enforce)
		--ml_mesh_mgr.SetDefaultMesh(1154,"Special Forces Training Area",enforce)
		
		--LS3
		ml_mesh_mgr.SetDefaultMesh(1165,"Bloodstone Fen",enforce)
		ml_mesh_mgr.SetDefaultMesh(1175,"Ember Bay",enforce)
		ml_mesh_mgr.SetDefaultMesh(1178,"Bitterfrost Frontier",enforce)
		ml_mesh_mgr.SetDefaultMesh(1185,"Lake Doric",enforce)
		ml_mesh_mgr.SetDefaultMesh(1195,"Draconis Mons",enforce)
		ml_mesh_mgr.SetDefaultMesh(1203,"Siren's Landing",enforce)

		--sPVP
		ml_mesh_mgr.SetDefaultMesh(549,"Battle of Kyhlo",enforce)
		ml_mesh_mgr.SetDefaultMesh(554,"Forest of Niflhel",enforce)
		ml_mesh_mgr.SetDefaultMesh(795,"Legacy of the Foefire",enforce)
		ml_mesh_mgr.SetDefaultMesh(875,"Temple of the Silent Storm",enforce)
		ml_mesh_mgr.SetDefaultMesh(894,"Spirit Watch",enforce)
		ml_mesh_mgr.SetDefaultMesh(900,"Skyhammer",enforce)
		ml_mesh_mgr.SetDefaultMesh(984,"Courtyard",enforce)
		ml_mesh_mgr.SetDefaultMesh(1011,"Battle of Champion's Dusk",enforce)
		ml_mesh_mgr.SetDefaultMesh(1163,"Revenge of the Capricorn",enforce)
		ml_mesh_mgr.SetDefaultMesh(1171,"Eternal Coliseum",enforce)
		ml_mesh_mgr.SetDefaultMesh(1305,"Djinns Dominion",enforce)
		
		
		--PoF
		ml_mesh_mgr.SetDefaultMesh(1210,"Crystal Oasis",enforce)
		ml_mesh_mgr.SetDefaultMesh(1228,"Elon Riverlands",enforce)
		ml_mesh_mgr.SetDefaultMesh(1211,"Desert Highlands",enforce)
		ml_mesh_mgr.SetDefaultMesh(1226,"The Desolation",enforce)
		ml_mesh_mgr.SetDefaultMesh(1301,"Jahai Bluffs",enforce)
		ml_mesh_mgr.SetDefaultMesh(1263,"Domain of Istan",enforce)
		ml_mesh_mgr.SetDefaultMesh(1271,"Sandswept Isles",enforce)
		ml_mesh_mgr.SetDefaultMesh(1288,"Domain of Kourna",enforce)
		ml_mesh_mgr.SetDefaultMesh(1294,"Sun's Refuge",enforce)
		ml_mesh_mgr.SetDefaultMesh(1310,"Thunderhead Peaks",enforce)
		ml_mesh_mgr.SetDefaultMesh(1317,"Dragonfall",enforce)
		ml_mesh_mgr.SetDefaultMesh(1248,"Domain of Vabbi",enforce)
		ml_mesh_mgr.SetDefaultMesh(1330,"Grothmar Valley",enforce)
		
		--Instances
		ml_mesh_mgr.SetDefaultMesh(896,"North Nolan Hatchery",enforce) -- Diessa Plateau
		ml_mesh_mgr.SetDefaultMesh(866,"Mad King's Labyrinth",enforce)
		ml_mesh_mgr.SetDefaultMesh(881,"Bell Choir Ensemble",enforce)
		
		-- Wvwvw
		ml_mesh_mgr.SetDefaultMesh(95,"Alpine Borderlands",enforce)
		ml_mesh_mgr.SetDefaultMesh(96,"Alpine Borderlands",enforce)
		ml_mesh_mgr.SetDefaultMesh(1099,"Desert Borderlands",enforce)
		ml_mesh_mgr.SetDefaultMesh(38,"Eternal Battlegrounds",enforce)
		
		-- Fractals
		ml_mesh_mgr.SetDefaultMesh(872,"Mistlock Observatory",enforce)
		ml_mesh_mgr.SetDefaultMesh(956,"Aetherblade",enforce)
		ml_mesh_mgr.SetDefaultMesh(960,"Aetherblade Retreat",enforce)
		
						
	end
	
end
RegisterEventHandler("Module.Initalize",gw2minion.Init, "gw2minion.Init")

-- Get's called internally in ml_bt_mgr.lua by the :run() of the gw2minion.mainbtreeinstance. This draws UI code for ther internal GW2_Main btree here.
-- This is to add always the same "core" functions and UI elements to the Main Menu
function gw2minion.DrawMenuCode()
	gw2minion.mainbtreeinstance:drawMenuElements()
end

-- Is called when the BTree is started. Allows us to supply a custom context table to the BTree
function gw2minion.LoadContext()
	return gw2minion.btreecontext
end

-- Gets called by the BT-Manager, after changes on the BT were saved. I'm just reloading the tree from the file here.
function gw2minion.ReloadBTree()
	if ( FileExists(GetLuaModsPath()  .. "\\\GW2Minion\\\GW2_Main.bt")) then 
		
		local btreeinfo = {
			filename = "GW2_Main.bt",
			filepath = GetLuaModsPath()  .. "\\\GW2Minion",
			
			LoadContext = function() return gw2minion.LoadContext() end,	-- Is called when the BTree is started. Allows us to supply a custom context table.
			Reload = function() gw2minion.ReloadBTree() end,			-- Called when the BTree was changed and saved in the BT-Editor
			
			internal = true,	-- if set, it will not be listed in the BotMode dropdown box
			DrawMenuCode = function() gw2minion.DrawMenuCode() end,	-- Draws UI Elements into the Main Menu from our internal BTree which is running inside this file.
			
			--private = false, -- if set, it will be treated as a private addon, loadble from a .paf file.
			--LoadSubTree = function(filename) d("IMPLEMENT ME to load "..filename) end,	-- Required for private addons with additional private sub-behavior trees
		}				
		d("Loading GW2 Main.bt")
		gw2minion.mainbtreeinstance = BehaviorManager:LoadBehavior( btreeinfo )
		if ( not table.valid(gw2minion.mainbtreeinstance)) then
			ml_error("[GW2Minion] - Failed to load core behaviortree")
		end
	end
end

function gw2minion.LoadBehaviorFiles()
	-- Load all our local "bot/addon" BTree files 
	BehaviorManager:LoadBehaviorFromFolder(GetStartupPath()  .. "\\\LuaMods\\\GW2Minion\\\Behavior")

	--Load the "GW2 Main/Core tree" which is a local one and gets called from in here	
	gw2minion.ReloadBTree()
 end
RegisterEventHandler("RefreshBehaviorFiles", gw2minion.LoadBehaviorFiles, "gw2minion.LoadBehaviorFiles")


function gw2minion.DrawCall(event, ticks )
	-- Check for player name change and queue the gw2minion.PlayerChanged event
	gw2minion.PlayerChanged()
	-- Check for map change and queue the gw2minion.MapChanged event
	gw2minion.MapChanged()
	
	-- Version check, this will popup a window informing about the "might work, but can crash or worse" after a MINOR game update and when the bot auto updated
	if (not gw2minion.versionchecked) then
		local v1,v2 = GetGameVersion()
		if(v1 ~= v2) then
			if(not gw2minion.versioncheckqueued) then
				-- Only queue it once
				gw2minion.versioncheckqueued = true
				gw2_gui_manager.QueueMessage(gw2minion.DrawVersionChanged)
			end
		else
			gw2minion.versionchecked = true
		end			
	end
	
	if ( BehaviorManager:Ready() == true ) then
		if ( gw2minion.mainbtreeinstance ) then
			-- Run the local behaviortree
			gw2minion.mainbtreeinstance:run(gw2minion.btreecontext)
		end
	end
	
	-- Autostart once on loading ingame
	if ( not gw2minion.startedonce and Settings.GW2Minion.autostartbot == true and not BehaviorManager:Running() and GetGameState() == GW2.GAMESTATE.GAMEPLAY and NavigationManager:GetNavMeshState() == GLOBAL.MESHSTATE.MESHREADY) then
		gw2minion.startedonce = true
		BehaviorManager:Start()
		d("[GW2Minion] - Automatically starting bot")
	end
end
RegisterEventHandler("Gameloop.Draw", gw2minion.DrawCall, "gw2minion.DrawCall")

function gw2minion.DrawVersionChanged()
	if(not GUI:IsPopupOpen(GetString("Bot Update Required"))) then
		GUI:OpenPopup(GetString("Bot Update Required"))
	end
	
	GUI:SetNextWindowSize(600,200)
	if (GUI:BeginPopupModal("Bot Update Required",true,GUI.WindowFlags_NoResize+GUI.WindowFlags_NoMove+GUI.WindowFlags_ShowBorders)) then
		GUI:Spacing()
		GUI:SameLine(25)
		GUI:Text(GetString("GW2 was updated and we need to update GW2Minion as well."))
		GUI:Spacing()
		GUI:SameLine(25)
		GUI:Text(GetString("Until that happens, GW2Minion 'can' continue to work."))
		GUI:Spacing()
		GUI:SameLine(25)
		GUI:Text(GetString("Some features are NOT available in this mode ( No Hacks.. )."))
		GUI:Spacing()
		GUI:SameLine(25)
		GUI:Text(GetString("Be aware that in this mode the game MAY CRASH at any given time !"))
		GUI:Spacing()
		GUI:SameLine(25)
		GUI:Text(GetString("If that happens, there is nothing you can do but to wait for the Bot update."))
		GUI:Spacing()
		GUI:SameLine(25)
		GUI:SetWindowFontScale(0.8)
		GUI:Text("Enjoy the No-Downtime-Mode ;)")
		GUI:SetWindowFontScale(1)
		
		GUI:Spacing()
		GUI:Separator()
		GUI:Dummy(100,10)
		GUI:Spacing()
		GUI:SameLine(80)
		if (GUI:Button(GetString("I UNDERSTAND THE TEXT ABOVE AND WANT TO CONTINUE"),450,30)) then
			GUI:CloseCurrentPopup()
			gw2minion.versionchecked = true
		end
		GUI:EndPopup()
	end
	return gw2minion.versionchecked ~= true
end

-- Queue an event when the player name changes
gw2minion.e_currentplayer = nil
function gw2minion.PlayerChanged()
	if(gw2minion.e_currentplayer ~= ml_global_information.Player_Name) then
		QueueEvent("gw2minion.PlayerChanged","")
		gw2minion.e_currentplayer = ml_global_information.Player_Name
	end
end

-- Queue an event when the map changes
gw2minion.e_currentmap = nil
function gw2minion.MapChanged()
	if(gw2minion.e_currentmap ~= ml_global_information.CurrentMapID) then
		local meshstate = NavigationManager:GetNavMeshState()
		if(ml_global_information.CurrentMapID == nil or meshstate == GLOBAL.MESHSTATE.MESHREADY or meshstate == GLOBAL.MESHSTATE.MESHEMPTY) then
			QueueEvent("gw2minion.MapChanged","")
			gw2minion.e_currentmap = ml_global_information.CurrentMapID
		end
	end
end

function gw2minion.RefreshGuestServers()
	ml_global_information.GuestServerList = { [0] = "None" }
	local homeserverid = GetHomeServer()	
	-- US Servers
	if ( homeserverid > 1000 and homeserverid < 2000 ) then
		ml_global_information.GuestServerList = {
			[0]="None",
			[1010]="Ehmry Bay",
			[1018]="Northern Shiverpeaks",
			[1002]="Borlis Pass",
			[1008]="Jade Quarry",
			[1005]="Maguuma",
			[1015]="Isle of Janthir",
			[1009]="Fort Aspenwood",
			[1013]="Sanctum of Rall",
			[1007]="Gate of Madness",
			[1006]="Sorrow's Furnace",
			[1019]="Blackgate",
			[1021]="Dragonbrand",
			[1012]="Darkhaven",
			[1003]="Yak's Bend",
			[1014]="Crystal Desert",
			[1001]="Anvil Rock",
			[1011]="Stormbluff Isle",
			[1020]="Ferguson's Crossing",
			[1016]="Sea of Sorrows",
			[1022]="Kaineng",
			[1023]="Devona's Rest",
			[1017]="Tarnished Coast",
			[1024]="Eredon Terrace",
			[1004]="Henge of Denravi",
		}	
	elseif ( homeserverid > 2000 and homeserverid < 3000 ) then
		-- EU Servers
		ml_global_information.GuestServerList = {
			[0]="None",
			[2012]="Piken Square",
			[2003]="Gandara",
			[2007]="Far Shiverpeaks",
			[2204]="Abaddon's Mouth [DE]",
			[2201]="Kodash [DE]",
			[2010]="Seafarer's Rest",
			[2301]="Baruch Bay [SP]",
			[2205]="Drakkar Lake [DE]",
			[2002]="Desolation",
			[2202]="Riverside [DE]",
			[2008]="Whiteside Ridge",
			[2203]="Elona Reach [DE]",
			[2206]="Miller's Sound [DE]",
			[2004]="Blacktide",
			[2207]="Dzagonur [DE]",
			[2105]="Arborstone [FR]",
			[2101]="Jade Sea [FR]",
			[2013]="Aurora Glade",
			[2103]="Augury Rock [FR]",
			[2102]="Fort Ranik [FR]",
			[2104]="Vizunah Square [FR]",
			[2009]="Ruins of Surmia",
			[2014]="Gunnar's Hold",
			[2005]="Ring of Fire",
			[2006]="Underworld",
			[2011]="Vabbi",
			[2001]="Fissure of Woe",
		}
	end
end
