-- Extends minionlib's ml_navigation.lua by adding the game specific navigation handler

-- Since we have different "types" of movement, add all types and assign a value to them. Make sure to include one entry for each of the 4 kinds below per movement type!
ml_navigation.NavPointReachedDistances = 			{ 	["Walk"] = 32,		["Diving"] = 48,	["Mounted"] = 100,}		-- Distance to the next node in the path at which the ml_navigation.pathindex is iterated
ml_navigation.PathDeviationDistances = 				{ 	["Walk"] = 50,		["Diving"] = 150, 	["Mounted"] = 150,}		-- The max. distance the playerposition can be away from the current path. (The Point-Line distance between player and the last & next pathnode)
ml_navigation.lastMount = 0

-- gw2_obstacle_manager has control over this now
ml_navigation.avoidanceareasize = 50
ml_navigation.avoidanceareas = { }	-- TODO: make a proper API in c++ for handling a list and accessing single entries



ml_navigation.GetMovementType = function() if ( Player.swimming ~= GW2.SWIMSTATE.Diving ) then if (Player.mounted) then return "Mounted" else return "Walk" end else return "Diving" end end	-- Return the EXACT NAMES you used above in the 4 tables for movement type keys
ml_navigation.StopMovement = function() Player:StopMovement() end

-- Main function to move the player. 'targetid' is optional but should be used as often as possible, if there is no target, use 0
function Player:MoveTo(x, y, z, targetid, stoppingdistance, randommovement, smoothturns, staymounted)
	ml_navigation.stoppingdistance = stoppingdistance or 154
	ml_navigation.randommovement = randommovement
	ml_navigation.smoothturns = smoothturns or true
	ml_navigation.targetid = targetid or 0
	ml_navigation.staymounted = staymounted or false
	ml_navigation.debug = nil

	ml_navigation.targetposition = { x=x, y=y, z=z }

	if( not ml_navigation.navconnection or ml_navigation.navconnection.type == 5) then	-- We are not currently handling a NavConnection / ignore MacroMesh Connections, these have to be replaced with a proper path by calling this exact function here
		if (ml_navigation.navconnection) then
			gw2_unstuck.Reset()
		end
		ml_navigation.navconnection = nil
		local status = ml_navigation:MoveTo(x, y, z, targetid)

		-- Handle stuck if we start off mesh
		if(status == -1 or status == -7) then
			-- We're starting off the mesh, so return 0 (valid) to let unstuck handle moving without failing the moveto
			gw2_unstuck.HandleStuck()
			return 0
		end
		return status
	else
		return table.size(ml_navigation.path)
	end
end

-- Handles the Navigation along the current Path. Is not supposed to be called manually.
function ml_navigation.Navigate(event, ticks )

	if ((ticks - (ml_navigation.lastupdate or 0)) > 10) then
		ml_navigation.lastupdate = ticks

		if(ml_navigation.forcereset) then
			ml_navigation.forcereset = nil
			Player:StopMovement()
			return
		end

		if ( GetGameState() == GW2.GAMESTATE.GAMEPLAY and not ml_navigation.debug) then
			local playerpos = Player.pos
			ml_navigation.pathindex = NavigationManager.NavPathNode	-- gets the current path index which is saved in c++ ( and changed there on updating / adjusting the path, which happens each time MoveTo() is called. Index starts at 1 and 'usually' is 2 whne running

			local pathsize = table.size(ml_navigation.path)
			if ( pathsize > 0 ) then
				if ( ml_navigation.pathindex <= pathsize ) then
					local lastnode =  ml_navigation.pathindex > 1 and ml_navigation.path[ ml_navigation.pathindex - 1] or nil
					local nextnode = ml_navigation.path[ ml_navigation.pathindex ]
					local nextnextnode = ml_navigation.path[ ml_navigation.pathindex + 1]
					local totalpathdistance = ml_navigation.path[1].pathdistance or 0

					-- Ensure Position: Takes a second to make sure the player is really stopped at the wanted position (used for precise OMC bunnyhopping)
					if ( table.valid (ml_navigation.ensureposition) and ml_navigation:EnsurePosition(playerpos) ) then

						return
					end


					-- Handle Current NavConnections
					if( ml_navigation.navconnection ) then

						-- Temp solution to cancel navcon handling after 10 sec
						if ( ml_navigation.navconnection_start_tmr and ( ml_global_information.Now - ml_navigation.navconnection_start_tmr > 10000)) then
							d("[Navigation] - We did not complete the Navconnection handling in 10 seconds, something went wrong ?...Resetting Path..")
							Player:StopMovement()
							return
						end


						--d("ml_navigation.navconnection ID " ..tostring(ml_navigation.navconnection.id))
						--CubeCube & PolyPoly && Floor-Cube -> go straight to the end node
						if(ml_navigation.navconnection.type == 1 or ml_navigation.navconnection.type == 2 or ml_navigation.navconnection.type == 3) then
							lastnode = nextnode
							nextnode = ml_navigation.path[ ml_navigation.pathindex + 1]

						-- Custom OMC
						elseif(ml_navigation.navconnection.type == 4) then

							local ncsubtype
							local ncradius
							local ncdirectionFromA
							if (ml_navigation.navconnection.details) then
								ncsubtype = ml_navigation.navconnection.details.subtype
								if(nextnode.navconnectionsideA == true) then
									ncradius = ml_navigation.navconnection.sideB.radius -- yes , B , not A
									ncdirectionFromA =  true
								else
									ncradius = ml_navigation.navconnection.sideA.radius
									ncdirectionFromA =  false
								end
							end
							if(ncsubtype == 1 ) then
								-- JUMP
								if(Player.mounted)then
									Player:Dismount()
									ml_navigation.lastMount = ml_global_information.Now - 5000
								end
								lastnode = nextnode
								nextnode = ml_navigation.path[ ml_navigation.pathindex + 1]
								local movementstate = Player:GetMovementState()
								if ( movementstate == GW2.MOVEMENTSTATE.Jumping) then
									if ( not ml_navigation.omc_startheight ) then ml_navigation.omc_startheight = playerpos.z end
									-- Additionally check if we are "above" the target point already, in that case, stop moving forward
									local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(playerpos,nextnode)
									if ( (nodedist)  < ml_navigation.NavPointReachedDistances["Walk"] or (playerpos.z < nextnode.z and (math.distance2d(playerpos,nextnode)-ncradius*32) < ml_navigation.NavPointReachedDistances["Walk"]) ) then
										d("[Navigation] - We are above the OMC_END Node, stopping movement. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances["Walk"])..")")
										Player:Stop()
										if ( ncradius < 1.0  ) then
											ml_navigation:SetEnsureEndPosition(nextnode, nextnextnode, playerpos)
										end
									else
										Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
									end
									Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)

								elseif ( movementstate == GW2.MOVEMENTSTATE.Falling and ml_navigation.omc_startheight) then
									-- If Playerheight is lower than 4*omcreached dist AND Playerheight is lower than 4* our Startposition -> we fell below the OMC START & END Point
									if (( playerpos.z > (nextnode.z + 4*ml_navigation.NavPointReachedDistances["Walk"])) and ( playerpos.z > ( ml_navigation.omc_startheight + 4*ml_navigation.NavPointReachedDistances["Walk"]))) then
										if ( ml_navigation.omcteleportallowed and math.distance3d(playerpos,nextnode) < ml_navigation.NavPointReachedDistances["Walk"]*10) then
											if ( ncradius < 1.0  ) then
												ml_navigation:SetEnsureEndPosition(nextnode, nextnextnode, playerpos)
											end
										else
											d("[Navigation] - We felt below the OMC start & END height, missed our goal...")
											ml_navigation.StopMovement()
										end
									else
										-- Additionally check if we are "above" the target point already, in that case, stop moving forward
										local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(playerpos,nextnode)
										if ( (nodedist)  < ml_navigation.NavPointReachedDistances["Walk"] or (playerpos.z < nextnode.z and (math.distance2d(playerpos,nextnode)-ncradius*32) < ml_navigation.NavPointReachedDistances["Walk"])) then
											d("[Navigation] - We are above the OMC END Node, stopping movement. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances["Walk"])..")")
											Player:Stop()
											if ( ncradius < 1.0  ) then
												ml_navigation:SetEnsureEndPosition(nextnode, nextnextnode, playerpos)
											end
										else
											Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
											Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)
										end
									end

								else
									-- We are still before our Jump
									if ( not ml_navigation.omc_startheight ) then
										if ( Player:CanMove() and ml_navigation.omc_starttimer == 0 ) then
											ml_navigation.omc_starttimer = ticks
											Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
											Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)
										elseif ( Player:IsMoving() and ticks - ml_navigation.omc_starttimer > 100 ) then
											Player:Jump()
										end

									else
										-- We are after the Jump and landed already
										local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(playerpos,nextnode)
										if ( (nodedist - ncradius*32 ) < ml_navigation.NavPointReachedDistances["Walk"]) then
											d("[Navigation] - We reached the OMC END Node (Jump). ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances["Walk"])..")")
											local nextnode = nextnextnode
											local nextnextnode = ml_navigation.path[ ml_navigation.pathindex + 2]
											if ( ncradius < 1.0  ) then
												ml_navigation:SetEnsureEndPosition(nextnode, nextnextnode, playerpos)
											end
											ml_navigation.pathindex = ml_navigation.pathindex + 1
											NavigationManager.NavPathNode = ml_navigation.pathindex
											ml_navigation.navconnection = nil

										else
											Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
											Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)
										end
									end
								end
								return


							elseif(ncsubtype == 2 ) then
								-- WALK
								lastnode = nextnode		-- OMC start
								nextnode = ml_navigation.path[ ml_navigation.pathindex + 1]	-- OMC end

								local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(playerpos,nextnode)
								local enddist = nodedist - ncradius*32
								if (enddist < ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()]) then
									d("[Navigation] - We reached the OMC END Node (Walk). ("..tostring(math.round(enddist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")
									ml_navigation.pathindex = ml_navigation.pathindex + 1
									NavigationManager.NavPathNode = ml_navigation.pathindex
									ml_navigation.navconnection = nil
								end
							elseif(ncsubtype == 3 ) then
								-- TELEPORT
								nextnode = ml_navigation.path[ ml_navigation.pathindex + 1]
								HackManager:Teleport(nextnode.x,nextnode.y,nextnode.z)
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation.navconnection = nil
								return

							elseif(ncsubtype == 4 ) then
								-- INTERACT
								local movementstate = Player:GetMovementState()
								Player:Stop()
								-- delay getting on mount, this can cancel whatever interacter needs to take place
								ml_navigation.lastMount = ml_global_information.Now - 2000
								if (not Player.mounted and movementstate ~= GW2.MOVEMENTSTATE.Jumping and movementstate ~= GW2.MOVEMENTSTATE.Falling) then
									Player:Interact()
									ml_navigation.lastupdate = ml_navigation.lastupdate + 1000
									ml_navigation.pathindex = ml_navigation.pathindex + 1
									NavigationManager.NavPathNode = ml_navigation.pathindex
									ml_navigation.navconnection = nil
								elseif (Player.mounted) then
									Player:Dismount()
									-- ml_navigation.lastMount = ml_global_information.Now - 3000
									-- Player:Stop()
								end
								return

							elseif(ncsubtype == 5 ) then
								-- PORTAL
								-- Check if we have reached the portal end position
								local portalend = ml_navigation.path[ ml_navigation.pathindex + 1]
								if (ml_navigation:NextNodeReached( playerpos, portalend, nextnextnode ) )then
									ml_navigation.pathindex = ml_navigation.pathindex + 1
									NavigationManager.NavPathNode = ml_navigation.pathindex
									ml_navigation.navconnection = nil

								else
									-- We need to face and move
									if(nextnode.navconnectionsideA == true) then
										Player:SetFacingH(ml_navigation.navconnection.details.headingA_x, ml_navigation.navconnection.details.headingA_y, ml_navigation.navconnection.details.headingA_z)
									else
										Player:SetFacingH(ml_navigation.navconnection.details.headingB_x, ml_navigation.navconnection.details.headingB_y, ml_navigation.navconnection.details.headingB_z)
									end
								end
								return

							elseif(ncsubtype == 6 ) then
								-- Custom Lua Code
								lastnode = nextnode		-- OMC start
								nextnode = nextnextnode	-- OMC end
								local result
								
								if ( ml_navigation.navconnection.details.luacode and ml_navigation.navconnection.details.luacode and ml_navigation.navconnection.details.luacode ~= "" and ml_navigation.navconnection.details.luacode ~= " " ) then

									if ( not ml_navigation.navconnection.luacode_compiled and not ml_navigation.navconnection.luacode_bugged ) then
										local execstring = 'return function(self,startnode,endnode) '..ml_navigation.navconnection.details.luacode..' end'
										local func = loadstring(execstring)
										if ( func ) then
											result = func()(ml_navigation.navconnection, lastnode, nextnode)
											if ( ml_navigation.navconnection ) then -- yeah happens, crazy, riught ?
												ml_navigation.navconnection.luacode_compiled = func
											else
												--ml_error("[Navigation] - Cannot set luacode_compiled, ml_navigation.navconnection is nil !?")
											end
										else
											ml_navigation.navconnection.luacode_compiled = nil
											ml_navigation.navconnection.luacode_bugged = true
											ml_error("[Navigation] - The Mesh Connection Lua Code has a BUG !!")
											assert(loadstring(execstring)) -- print out the actual error
										end
									else
										--executing the already loaded function
										if(ml_navigation.navconnection.luacode_compiled) then
											result = ml_navigation.navconnection.luacode_compiled()(ml_navigation.navconnection, lastnode, nextnode)
										end
									end

								else
									d("[Navigation] - ERROR: A 'Custom Lua Code' MeshConnection has NO lua code!...")
								end

								-- continue to walk to the omc end
								if ( result ) then
									-- moving on to the omc end
								else
									-- keep calling the MeshConnection
									return
								end
							end


						-- Macromesh node
						elseif(ml_navigation.navconnection.type == 5) then
							-- we should not be here in the first place..c++ should have replaced any macromesh node with walkable paths. But since this is on a lot faster timer than the main bot pulse, it can happen that 4-5 pathnodes are "reached" and then a macronode appears.
							d("[Navigation] - Reached a Macromesh node... waiting for a path update...")
							Player:Stop()
							return

						else
							d("[Navigation] - OMC BUT UNKNOWN TYPE !? WE SHOULD NOT BE HERE!!!")
						end

					else
						-- TODO: check if water surface node, dont try to mount if so.
						if((Settings.GW2Minion.usemount == nil or Settings.GW2Minion.usemount) and not Player.mounted and Player.canmount and ml_global_information.Now - ml_navigation.lastMount > 5000)then
							local remainingPathLenght = ml_navigation:GetRemainingPathLenght()
							if(remainingPathLenght ~= 0 and remainingPathLenght > 800)then
								local allowMount = true
								local distanceToNextNode = math.distance3d(playerpos, {x = nextnode.x, y = nextnode.y, z = nextnode.z,})

								if (lastnode and lastnode.navconnectionid ~= 0 and nextnode and nextnode.navconnectionid ~= 0) then
									allowMount = false
								end
								if (ml_navigation:DistanceToNextNavConnection() < 1000) then
									allowMount = false
								end
								
								local mountDisableingBuffs = {[57576] = true, [43406] = true}
								if (Player.buffs and gw2_common_functions.HasBuffs(Player, mountDisableingBuffs)) then
									allowMount = false
								end

								if (allowMount) then
									local anglediffPlayerNextNode = math.angle({x = playerpos.hx, y = playerpos.hy,  z = 0}, {x = nextnode.x-playerpos.x, y = nextnode.y-playerpos.y, z = 0,})
									local anglediffNextNodeNextNextNode = nextnextnode and math.angle({x = nextnode.x-playerpos.x, y = nextnode.y-playerpos.y, z = 0}, {x = nextnextnode.x-nextnode.x, y = nextnextnode.y-nextnode.y, z = 0,}) or 0

									if (distanceToNextNode >= 500) then
										if (anglediffPlayerNextNode < 30) then
											gw2_common_functions.NecroLeaveDeathshroud()
											Player:Mount()
											ml_navigation.lastMount = ml_global_information.Now
										end

									else
										if (anglediffPlayerNextNode < 30 and anglediffNextNodeNextNextNode < 45) then
											gw2_common_functions.NecroLeaveDeathshroud()
											Player:Mount()
											ml_navigation.lastMount = ml_global_information.Now
										end
									end
								end
							end
						end
					end

					-- update last time we were mounted. If navigation dismounts, this is resets.
					-- if we leave our mount for any other reason, like unstuck or falling into water, we wait 5 seconds before we mount again.
					if (Player.mounted) then
						ml_navigation.lastMount = ml_global_information.Now
					elseif (Player.swimming == GW2.SWIMSTATE.Diving or Player.swimming == GW2.SWIMSTATE.Swimming) then
						ml_navigation.lastMount = ml_global_information.Now - 2000
					end

					-- Move to next node in our path
					if (ml_navigation:NextNodeReached( playerpos, nextnode ,nextnextnode) )then
						ml_navigation.pathindex = ml_navigation.pathindex + 1
						NavigationManager.NavPathNode = ml_navigation.pathindex
					else
						-- Dismount when we are close to our target position, so we can get to the actual point and not overshooting it or similiar unprecise stuff
						-- if (pathsize - ml_navigation.pathindex < 5 and Player.mounted and ml_navigation.staymounted == false)then
						if (Player.mounted and ml_navigation.staymounted == false)then
							local remainingPathLenght = ml_navigation:GetRemainingPathLenght()
							if(remainingPathLenght ~= 0 and remainingPathLenght < 400)then
								Player:Dismount()
								ml_navigation.lastMount = ml_global_information.Now - 5000
							end
						end
						ml_navigation:MoveToNextNode(playerpos, lastnode, nextnode )
					end
					return
				else
					d("[Navigation] - Path end reached.")
					if(Player.mounted and ml_navigation.staymounted == false) then
						Player:Dismount()
						ml_navigation.lastMount = ml_global_information.Now - 5000
					end
					Player:StopMovement()
					gw2_unstuck.Reset()

				end
			end
		end

		-- stoopid case catch
		if( ml_navigation.navconnection ) then
			ml_error("[Navigation] - Breaking out of not handled NavConnection.")
			Player:StopMovement()
		end
	end
end
RegisterEventHandler("Gameloop.Draw", ml_navigation.Navigate, "ml_navigation.Navigate") -- TODO: navigate on draw loop?

-- Checks if the next node in our path was reached, takes differen movements into account ( swimming, walking, riding etc. )
function ml_navigation:NextNodeReached( playerpos, nextnode , nextnextnode)

		-- take into account navconnection radius, to randomize the movement on places where precision is not needed
		local navcon = nil
		local navconradius = 0
		if( nextnode.navconnectionid and nextnode.navconnectionid ~= 0) then
			navcon = NavigationManager:GetNavConnection(nextnode.navconnectionid)
			if ( navcon ) then
				if(nextnode.navconnectionsideA == true) then
					navconradius = navcon.sideA.radius -- meshspace to gamespace is *32 in GW2
				else
					navconradius = navcon.sideB.radius -- meshspace to gamespace is *32 in GW2
				end
			end
		end

		if (Player.swimming ~= GW2.SWIMSTATE.Diving) then
			local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(playerpos,nextnode)
			-- local nodedist = math.distance3d(playerpos,nextnode)
			local movementstate = Player.movementstate
			local nodeReachedDistance = (movementstate == GW2.MOVEMENTSTATE.Jumping or movementstate == GW2.MOVEMENTSTATE.Falling) and ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] * 2 or ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()]
			if ( (nodedist - navconradius*32) < nodeReachedDistance) then
				-- d("[Navigation] - Node reached. ("..tostring(math.round(nodedist - navconradius*32,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")
				-- We arrived at a NavConnection Node
				if( navcon) then
					d("[Navigation] -  Arrived at NavConnection ID: "..tostring(nextnode.navconnectionid))
					ml_navigation:ResetOMCHandler()
					gw2_unstuck.SoftReset()
					ml_navigation.navconnection = navcon
					if( not ml_navigation.navconnection ) then
						ml_error("[Navigation] -  No NavConnection Data found for ID: "..tostring(nextnode.navconnectionid))
						return false
					end
					if ( navconradius > 0 and navconradius < 1.0 ) then	-- kinda shitfix for the conversion of the old OMCs to the new NavCons, I set all precise connections to have a radius of 0.5
						ml_navigation:SetEnsureStartPosition(nextnode, nextnextnode, playerpos, ml_navigation.navconnection)
					end
					-- Add for now a timer to cancel the shit after 10 seconds if something really went crazy wrong
					ml_navigation.navconnection_start_tmr = ml_global_information.Now

				else
					if (ml_navigation.navconnection) then
						gw2_unstuck.Reset()
					end
					ml_navigation.navconnection = nil
					return true
				end

			else
				-- Still walking towards the nextnode...
				--d("nodedist  - navconradius "..tostring(nodedist).. " - " ..tostring(navconradius))

			end

		else
		-- Handle underwater movement
			-- Check if the next Cubenode is reached:
			local dist3D = math.distance3d(nextnode,playerpos)
			if ( (dist3D - navconradius*32) < ml_navigation.NavPointReachedDistances["Diving"]) then
				-- We reached the node
				-- d("[Navigation] - Cube Node reached. ("..tostring(math.round(dist3D - navconradius*32,2)).." < "..tostring(ml_navigation.NavPointReachedDistances["Diving"])..")")

				-- We arrived at a NavConnection Node
				if( navcon) then
					d("[Navigation] -  Arrived at NavConnection ID: "..tostring(nextnode.navconnectionid))
					ml_navigation:ResetOMCHandler()
					gw2_unstuck.SoftReset()
					ml_navigation.navconnection = navcon
					if( not ml_navigation.navconnection ) then
						ml_error("[Navigation] -  No NavConnection Data found for ID: "..tostring(nextnode.navconnectionid))
						return false
					end
					if ( navconradius > 0 and navconradius < 1.0 ) then	-- kinda shitfix for the conversion of the old OMCs to the new NavCons, I set all precise connections to have a radius of 0.5
						ml_navigation:SetEnsureStartPosition(nextnode, nextnextnode, playerpos, ml_navigation.navconnection)
					end

				else
					if (ml_navigation.navconnection) then
						gw2_unstuck.Reset()
					end
					ml_navigation.navconnection = nil
					return true
				end
			end
		end
	return false
end

function ml_navigation:MoveToNextNode( playerpos, lastnode, nextnode, overridefacing )
	self.turningOnMount = nil
	-- Only check unstuck when we are not handling a navconnection
	if ( ml_navigation.navconnection or ( not ml_navigation.navconnection and not gw2_unstuck.HandleStuck())) then

		if ( Player.swimming ~= GW2.SWIMSTATE.Diving ) then
			-- We have not yet reached our next node
			if( not overridefacing ) then
				local anglediff = math.angle({x = playerpos.hx, y = playerpos.hy,  z = 0}, {x = nextnode.x-playerpos.x, y = nextnode.y-playerpos.y, z = 0})
				local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(playerpos,nextnode)
				if ( ml_navigation.smoothturns and anglediff < 75 and nodedist > 2*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
					Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
				else
					Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)
				end
			end

			-- Make sure we are not strafing away (happens sometimes after being dead + movement was set)
			local movdirs = Player:GetMovement()
			if (movdirs.backward) then Player:UnSetMovement(1) end
			if (movdirs.left) then Player:UnSetMovement(2) end
			if (movdirs.right) then Player:UnSetMovement(3) end

			if(Player.mounted)then
				-- Calc heading difference between player and next node
				local ppos = Player.pos
				local radianA = math.atan2(ppos.hx, ppos.hy)
				local radianB = math.atan2(nextnode.x-ppos.x, nextnode.y - ppos.y)
				local twoPi = 2 * math.pi
				local diff = (radianB - radianA) % twoPi
				local s = diff < 0 and -1.0 or 1.0
				local res =  diff * s < math.pi and diff or (diff - s * twoPi)

				if(res > 0.75 or res < -0.75)then
					self.turningOnMount = true
					local mountSpeed = HackManager:GetSpeed()
					if (mountSpeed > 450) then
						Player:SetMovement(GW2.MOVEMENTTYPE.Backward)
					elseif (mountSpeed > 400) then
						Player:UnSetMovement(GW2.MOVEMENTTYPE.Forward) -- stopping forward movement until we are facing the node
						Player:UnSetMovement(GW2.MOVEMENTTYPE.Backward)
					elseif (mountSpeed > 350) then
						Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
					end
					--d("TURNING : "..tostring(res))
					gw2_unstuck.stucktick = ml_global_information.Now + 500 -- the unstuck kicks in too often when we are still turning on our sluggish slow mount...
				else
					Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
					self:IsStillOnPath(playerpos, lastnode, nextnode, ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()])
				end
			else
				Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
				self:IsStillOnPath(playerpos, lastnode, nextnode, ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()])
			end

		else
			-- Handle underwater movement

			-- We have not yet reached our node
			local dist2D = math.distance2d(nextnode,playerpos)
			if (dist2D < ml_navigation.NavPointReachedDistances["Diving"] ) then
				-- We are on the correct horizontal position, but our goal is now either above or below us
				-- compensate for the fact that the char is always swimming on the surface between 0 - 50 @height
				local pHeight = playerpos.z
				if ( nextnode.z < 20 ) then pHeight = nextnode.z end -- if the node is in shallow water (<50) , fix the playerheight at this pos. Else it gets super wonky at this point.
				local distH = math.abs(math.abs(pHeight) - math.abs(nextnode.z))

				if ( distH > ml_navigation.NavPointReachedDistances["Diving"]) then
					-- Move Up / Down only until we reached the node
					Player:StopHorizontalMovement()
					if ( pHeight > nextnode.z ) then	-- minus is "up" in gw2
						Player:SetMovement(GW2.MOVEMENTTYPE.SwimUp)
					else
						Player:SetMovement(GW2.MOVEMENTTYPE.SwimDown)
					end

				else
					-- We have a good "height" position already, let's move a bit more towards the node on the horizontal plane
					Player:StopVerticalMovement()
					if( not overridefacing ) then
						Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)
					end
					Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
				end

			else
				Player:StopVerticalMovement()
				if( not overridefacing ) then
					Player:SetFacingExact(nextnode.x,nextnode.y,nextnode.z,true)
				end
				Player:SetMovement(GW2.MOVEMENTTYPE.Forward)
			end
			self:IsStillOnPath(playerpos, lastnode, nextnode, ml_navigation.PathDeviationDistances["Diving"])

		end

	else
		--d("[ml_navigation:MoveToNextNode] - Unstuck ...")
	end
	return false
end

function ml_navigation:GetRemainingPathLenght()
	local pathLength = 0
	local pathNodeCount = #self.path
	local lastNodePosition = Player.pos

	if(self.pathindex < pathNodeCount) then
		for pathNodeID = self.pathindex+1, pathNodeCount do
			local pathNode = self.path[pathNodeID]
			pathLength = pathLength + math.distance3d(lastNodePosition,pathNode)
			lastNodePosition = pathNode
		end

	else
		if (self.pathindex == pathNodeCount)then
			pathLength = math.distance3d(lastNodePosition,self.path[pathNodeCount])
		end
	end

	return pathLength
end

function ml_navigation:DistanceToNextNavConnection()
	local pathLength = 0
	local pathNodeCount = #self.path
	local lastNodePosition = Player.pos

	if(self.pathindex < pathNodeCount) then
		for pathNodeID = self.pathindex+1, pathNodeCount do
			local pathNode = self.path[pathNodeID]
			pathLength = pathLength + math.distance3d(lastNodePosition,pathNode)
			lastNodePosition = pathNode
			if (pathNode.navconnectionid ~= 0) then
				return pathLength
			end
		end
	end

	return 999999
end


-- Calculates the Point-Line-Distance between the PlayerPosition and the last and the next PathNode. If it is larger than the treshold, it returns false, we left our path.
function ml_navigation:IsStillOnPath(ppos, lastnode, nextnode, deviationthreshold)
	if ( lastnode ) then
		-- Dont use this when we crossed / crossing a navcon
		if (lastnode.navconnectionid == 0 ) then

			local movstate = Player:GetMovementState()
			if( Player.swimming ~= GW2.SWIMSTATE.Diving2 ) then
				-- Ignoring up vector, since recast's string pulling ignores that as well
				local from = { x=lastnode.x, y = lastnode.y, z = 0 }
				local to = { x=nextnode.x, y = nextnode.y, z = 0 }
				local playerpos = { x=ppos.x, y = ppos.y, z = 0 }
				if (movstate ~= GW2.MOVEMENTSTATE.Jumping and movstate ~= GW2.MOVEMENTSTATE.Falling and math.distancepointline(from, to, playerpos) > deviationthreshold) then
					d("[Navigation] - Player left the path - 2D-Distance to Path: "..tostring(math.distancepointline(from, to, playerpos)).." > "..tostring(deviationthreshold))
					--NavigationManager:UpdatePathStart()  -- this seems to cause some weird twitching loops sometimes..not sure why
					NavigationManager:ResetPath()
					ml_navigation:MoveTo(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, ml_navigation.targetid)
					return false
				end

			else
				-- Under water, using 3D
				if (movstate ~= GW2.MOVEMENTSTATE.Jumping and movstate ~= GW2.MOVEMENTSTATE.Falling and math.distancepointline(lastnode, nextnode, ppos) > deviationthreshold) then
					d("[Navigation] - Player not on Path anymore. - Distance to Path: "..tostring(math.distancepointline(lastnode,nextnode,ppos)).." > "..tostring(deviationthreshold))
					--NavigationManager:UpdatePathStart()
					NavigationManager:ResetPath()
					ml_navigation:MoveTo(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, ml_navigation.targetid)
					return false
				end
			end
		end
	end
	return true
end

-- Tries to use RayCast to determine the exact floor height from Player and Node, and uses that to calculate the correct distance.
function ml_navigation:GetRaycast_Player_Node_Distance(ppos,node)
	-- Raycast from "top to bottom" @PlayerPos and @NodePos
	local P_hit, P_hitx, P_hity, P_hitz = RayCast(ppos.x,ppos.y,ppos.z-120,ppos.x,ppos.y,ppos.z+250)
	local N_hit, N_hitx, N_hity, N_hitz = RayCast(node.x-25,node.y-25,node.z-120,node.x,node.y,node.z+250)
	local dist = math.distance3d(ppos,node)

	-- To prevent spinny dancing when we are unable to reach the 3D targetposition due to whatever reason , a little safety check here
	if ( not self.lastpathnode or self.lastpathnode.x ~= node.x or self.lastpathnode.y ~= node.y or self.lastpathnode.z ~= node.z ) then
		self.lastpathnode = node
		self.lastpathnodedist = nil
		self.lastpathnodecloser = 0
		self.lastpathnodefar = 0
	else

		if ( Player:IsMoving () and Player.swimming ~= GW2.SWIMSTATE.Diving and not Player.mounted) then
			-- we are still moving towards the same node
			local dist2d = math.distance2d(ppos,node)
			if ( dist2d < 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
				-- count / record if we are getting closer to it or if we are spinning around
				if( self.lastpathnodedist ) then
					if( dist2d <= self.lastpathnodedist ) then
						self.lastpathnodecloser = self.lastpathnodecloser + 1
					else
						if ( self.lastpathnodecloser > 1 ) then -- start counting after we actually started moving closer, else turns or at start of moving fucks the logic
							self.lastpathnodefar = self.lastpathnodefar + 1
						end
					end
				end
				self.lastpathnodedist = dist2d
			end

			if(self.lastpathnodefar > 3) then
				d("[Navigation] - Loop detected, going back and forth too often - reset navigation.. "..tostring(dist2d).. " ---- ".. tostring(self.lastpathnodefar))
				ml_navigation.forcereset = true
				return 0 -- should make the calling logic "arrive" at the node
			end
		end
	end


	if (P_hit and N_hit ) then
		local raydist = math.distance3d(P_hitx, P_hity, P_hitz , N_hitx, N_hity, N_hitz)
		if (raydist < dist) then
			-- d("return ray dist")
			return raydist
		end
	end
	-- d("return dist")
	return dist
end

-- Sets the position and heading which the main call will make sure that it has before continuing the movement. Used for NavConnections / OMC
function ml_navigation:SetEnsureStartPosition(currentnode, nextnode, playerpos, navconnection)
	Player:Stop()
	self.ensureposition = {x = currentnode.x, y = currentnode.y, z = currentnode.z}

	if(navconnection.details) then
		if(currentnode.navconnectionsideA == true) then
			self.ensureheading = {hx = navconnection.details.headingA_x, hy = navconnection.details.headingA_y, hz = navconnection.details.headingA_z}
		else
			self.ensureheading = {hx = navconnection.details.headingB_x, hy = navconnection.details.headingB_y, hz = navconnection.details.headingB_z}
		end
		self.ensureheadingtargetpos =  nil

	else
		-- this still a thing ?
		-- TODO: Is this ever showing up? if so, then leave it. probs old nav crap
		ml_error("DO NOT REMOVE ME!!!")
		if(currentnode.navconnectionsideA == true) then
			self.ensureheadingtargetpos = {x = navconnection.sideA.x, y = navconnection.sideA.y, z = navconnection.sideA.z}
		else
			self.ensureheadingtargetpos = {x = navconnection.sideB.x, y = navconnection.sideB.y, z = navconnection.sideB.z}
		end
		self.ensureheading = nil
	end

	self:EnsurePosition(playerpos)
end
function ml_navigation:SetEnsureEndPosition(currentnode, nextnode, playerpos)
	Player:Stop()
	self.ensureposition = {x = currentnode.x, y = currentnode.y, z = currentnode.z}
	if (nextnode) then
		self.ensureheadingtargetpos = {x = nextnode.x, y = nextnode.y, z = nextnode.z}
	end
	self:EnsurePosition(playerpos)
end


-- Ensures that the player is really at a specific position, stopped and facing correctly. Used for NavConnections / OMC
function ml_navigation:EnsurePosition(playerpos)
	if(Player.mounted)then
		Player:Dismount()
		ml_navigation.lastMount = ml_global_information.Now - 5000
	end
	if ( not self.ensurepositionstarttime ) then self.ensurepositionstarttime = ml_global_information.Now end

	local dist = self:GetRaycast_Player_Node_Distance(playerpos,self.ensureposition)
	if ( dist > 15 ) then
		HackManager:Teleport(self.ensureposition.x,self.ensureposition.y,self.ensureposition.z)
	end

	if ( (ml_global_information.Now - self.ensurepositionstarttime) < 750 and ((self.ensureheading and Player:IsFacingH(self.ensureheading.hx,self.ensureheading.hy,self.ensureheading.hz) ~= 0)  or  (self.ensureheadingtargetpos and Player:IsFacing(self.ensureheadingtargetpos.x,self.ensureheadingtargetpos.y,self.ensureheadingtargetpos.z)~= 0)) )then

		if ( Player:IsMoving () ) then Player:Stop() end
		local dist = self:GetRaycast_Player_Node_Distance(playerpos,self.ensureposition)

		if ( dist > 15 ) then
			HackManager:Teleport(self.ensureposition.x,self.ensureposition.y,self.ensureposition.z)
		end

		if ( self.ensureheading ) then
			Player:SetFacingH(self.ensureheading.hx,self.ensureheading.hy,self.ensureheading.hz)

		elseif (self.ensureheadingtargetpos) then
			Player:SetFacingExact(self.ensureheadingtargetpos.x,self.ensureheadingtargetpos.y,self.ensureheadingtargetpos.z,true)
		end

		return true

	else	-- We waited long enough
		self.ensureposition = nil
		self.ensureheading = nil
		self.ensureheadingtargetpos = nil
		self.ensurepositionstarttime = nil
	end
	return false
end

-- lookahead, number of nodes to look ahead for an omc
-- returns true if there is an omc on our path
function ml_navigation:OMCOnPath(lookahead)
	lookahead = lookahead or 3

	local pathsize = table.size(ml_navigation.path)

	lookahead = lookahead > pathsize and pathsize or lookahead

	if(pathsize > 0) then
		for i=1,lookahead do
			local node = ml_navigation.path[i]
			if(node.navconnectionid ~= 0) then return true end
		end
	end

	return false
end


-- param = {mindist, raycast, path, startpos}
-- mindist, minimum distance to get a position
-- raycast, set to false to disable los checks
-- path, provide an alternate path then the current navigation path
-- startpos, provide an alternate starting position. player position by default
-- returns a pos nearest to the minimum distance or nil
function ml_navigation:GetPointOnPath(param)
	local startpos = param.startpos ~= nil and param.startpos or ml_global_information.Player_Position

	local raycast = true
	if(param.raycast ~= nil) then raycast = param.raycast end

	local mindist = param.mindist ~= nil and param.mindist or 0
	local path = param.path ~= nil and param.path or ml_navigation.path
	local pathsize = table.size(path)
	local prevnode = Player.pos

	if(pathsize > 0 and mindist > 0) then
		local traversed
		for i=1,pathsize do
			local node = path[i]
			local dist = math.distance3d(node,startpos)

			if(dist >= mindist) then
				local disttoprev = math.distance3d(prevnode,node)
				local newpos = {
					x = prevnode.x + (traversed/disttoprev) * (node.x - prevnode.x);
					y = prevnode.y + (traversed/disttoprev) * (node.y - prevnode.y);
					z = prevnode.z + (traversed/disttoprev) * (node.z - prevnode.z);
				}

				if(not raycast) then return newpos end

				local hit, hitx, hity, hitz = RayCast(startpos.x,startpos.y,startpos.z, newpos.x, newpos.y, newpos.z)
				if(not hit) then return newpos end
			end

			prevnode = node
			traversed = mindist - dist
		end
	end

	return nil
end

-- Get a node that is further away then min distance
function ml_navigation:GetNearestNodeToDistance(mindist,startpos)
	startpos = startpos or ml_global_information.Player_Position

	local pathsize = table.size(ml_navigation.path)

	if(pathsize > 0) then
		for i=1,pathsize do
			local node = ml_navigation.path[i]
			local pos = {x = node.x, y = node.y, z = node.z}
			if(math.distance3d(startpos,pos) >= mindist) then
				return pos,i
			end
		end
	end

	return nil
end


-- Resets all OMC related variables
function ml_navigation:ResetOMCHandler()
	self.omc_id = nil
	self.omc_traveltimer = nil
	self.ensureposition = nil
	self.ensureheading = nil
	self.ensureheadingtargetpos = nil
	self.ensurepositionstarttime = nil
	self.omc_starttimer = 0
	self.omc_startheight = nil
	self.navconnection = nil
	self.turningOnMount = nil
end

-- Resets Path and Stops the Player Movement
function Player:StopMovement()
	ml_navigation.navconnection = nil
	ml_navigation.navconnection_start_tmr = nil
	ml_navigation.pathindex = 0
	ml_navigation.turningOnMount = nil
	ml_navigation:ResetCurrentPath()
	ml_navigation:ResetOMCHandler()
	gw2_unstuck.SoftReset()
	Player:Stop()
	NavigationManager:ResetPath()
	gw2_combat_movement:StopCombatMovement()
end