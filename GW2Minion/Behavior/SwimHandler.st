local tbl = 
{
	class = "SubTree",
	nodes = 
	{
		
		{
			class = "Throttle",
			nodes = 
			{
				
				{
					class = "Action",
					nodes = 
					{
					},
					settings = 
					{
					},
					variables = 
					{
						finishcode = "",
						info = "",
						monitorcode = "GUI:Text('Last State: '..tostring(self:getState()))",
						runcode = "if ( ml_global_information.Player_SwimState == GW2.SWIMSTATE.Diving and ml_global_information.Player_OnMesh == false and BehaviorManager:CurrentBTreeName() ~= GetString(\"AssistMode\")) then\n\t\tml_global_information.swimUp = true\n\t\tPlayer:SetMovement(GW2.MOVEMENTTYPE.SwimUp)\n\t\tself:fail()\n\t\treturn\nelseif( ml_global_information.swimUp == true ) then\n\t\tml_global_information.swimUp = false\n\t\tPlayer:UnSetMovement(GW2.MOVEMENTTYPE.SwimUp)\n\t\tself:fail()\n\t\treturn\nend\n\nlocal skill = Player:GetSpellInfo(GW2.SKILLBARSLOT.Slot_1)\n--Dont swim on the surface where we cannot fight\nlocal target = Player:GetTarget()\nif ( ml_global_information.Player_SwimState == GW2.SWIMSTATE.Swimming and ml_global_information.Player_OnMesh and (ml_global_information.Player_InCombat and not table.valid(skill)) and target and target.pos.z > 0) then\n\t\tml_global_information.swimDown = true\n\t\tPlayer:SetMovement(GW2.MOVEMENTTYPE.SwimDown)\n\t\tself:fail()\n\t\treturn\nelseif( ml_global_information.swimDown == true ) then\n\t\tml_global_information.swimDown = false\n\t\tPlayer:UnSetMovement(GW2.MOVEMENTTYPE.SwimDown)\n\t\tself:fail()\n\t\treturn\nend\t\nself:fail()",
						startcode = "",
					},
				},
			},
			settings = 
			{
				duration = 1100,
			},
			variables = 
			{
				info = "",
				monitorcode = "GUI:Text('Last State: '..tostring(self:getState())) \nif ( self.lastrun ) then\n\t\tlocal tmr = self.settings.duration/1000 - (GetTickCount() - self.lastrun) \n\t\tif ( tmr < 0 ) then tmr = 0 end \n\t\tGUI:Text('Runs again in: '..tostring(math.round(tmr,2 ))..' s')\nelse\n\t\tGUI:Text('Runs again in: '..tostring(math.round(self.settings.duration/1000))..' s')\nend",
			},
		},
	},
	settings = 
	{
	},
	variables = 
	{
		filename = "SwimHandler.st",
		finishcode = "",
		info = "Swim handler",
		menucode = "",
		monitorcode = "GUI:Text('Last State: '..tostring(self:getState())) GUI:Text('Filename: '..self.variables.filename) GUI:Text('Filepath: '..self.filepath)",
		runcode = "",
		startcode = "",
		subtreeuicode = "",
	},
}



return tbl