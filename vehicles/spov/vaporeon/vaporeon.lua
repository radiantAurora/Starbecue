--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")

--[[

vaporeon plan:

	state chart:
		0   *          sleep
		|   V            |
		0  idle - sit - lay - back
		|   :         \        :
		0   :   sleep - pin - bed - hug
		·   :            V         L
		1  idle - sit - lay - back
		|   :            |
		1   :          sleep
		·   :
		2  idle - sit - lay - sleep

	(struggling not included in chart, everything in full has it)

	todo:
	- pills to control the chance of entering/leaving a desired state (and states leading toward it)


	eventually if I can figure out how:
	- walk around
	- follow nearby player
	- eat automatically if low health, to protect (and heal w/ pill)
	- attack enemies
	- ride on back to control
	  - shlorp in from back -> control from inside?

]]--

function loadStoredData()
	vsoStorageSaveAndLoad( function()	--Get defaults from the item spawner itself
		if storage.colorReplaceMap ~= nil then
			vsoSetDirectives( vsoMakeColorReplaceDirectiveString( storage.colorReplaceMap ) );
		end
	end )
end

function showEmote( emotename )	--helper function to express a emotion particle	"emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if vsoTimeDelta( "emoteblock" ) > 0.2 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
	end
end

function escapePillChoice(list)
	if vsoPill( "easyescape" ) then return list[1] end
	if vsoPill( "antiescape" ) then return list[3] end
	return list[2]
end

local _qoccupants
function nextOccupants(occupants)
	_qoccupants = occupants
end

local _occupants = 0
function setOccupants(occupants)
	_occupants = occupants
	animator.setGlobalTag( "occupants", tostring(occupants) )
end

function getOccupants()
	return _occupants
end

local _qstate
function nextState(state, manual)
	_qstate = state
	vsoNext( "state_"..state )
end

local _qaction
function nextAction(func)
	_qaction = func
end

local _state
local _pstate
local _struggling
function updateState()
	if _struggling then
		_struggling = false
		vsoAnim( "bodyState", "look" )
		return false
	else
		vsoCounterReset( "struggleCount" )
	end
	if _qstate ~= nil then
		_pstate = _state
		_state = _qstate
		animator.setGlobalTag( "state", _qstate )
		_qstate = nil
	end
	if _qoccupants ~= nil then
		setOccupants(_qoccupants)
		_qoccupants = nil
	end
	if _qaction ~= nil then
		_qaction()
		_qaction = nil
	end
	return true
end

function resetState(state)
	_pstate = state
	_state = state
	animator.setGlobalTag( "state", state )
	vsoNext( "state_"..state )
end

function previousState()
	return _pstate
end

function stateQueued()
	return _struggling or _qstate ~= nil or _qoccupants ~= nil
end

local _controlmode = 0
function controlState()
	return _controlmode == 1
end

function updateControlMode()
	if vsoGetTargetId( "food" ) ~= nil then
		local inputs = vsoGetInput( "firstOccupant" )
		if inputs.fastA == 1 then
			_controlmode = 1
		end
		if inputs.fastB == 1 then
			_controlmode = 0
		end
	else
		_controlmode = 0
	end
end

function bellyEffects()
	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then
		vsoSound( "digest" )
	end
	vsoVictimAnimSetStatus( "firstOccupant", { "vsoindicatebelly" } )
	local effect = 0
	if vsoPill( "digest" ) or vsoPill( "softdigest" ) then
		effect = -1
	elseif vsoPill( "heal" ) then
		effect = 1
	end
	if getOccupants() > 1 then
		if effect ~= 0 then
			local health_change = effect * vsoDelta()
			local health = world.entityHealth( vsoGetTargetId("dessert") )
			if vsoPill("softdigest") and health[1]/health[2] <= -health_change then
				health_change = (1 - health[1]) / health[2]
			end
			vsoResourceAddPercent( vsoGetTargetId("dessert"), "health", health_change, function(still_alive)
				if not still_alive then
					vsoUneat( "secondOccupant" )
	
					vsoSetTarget( "dessert", nil )
					vsoUseLounge( false, "secondOccupant" )
					setOccupants(1)
				end
			end)
		end
	end
	if effect ~= 0 then
		local health_change = effect * vsoDelta()
		local health = world.entityHealth( vsoGetTargetId("food") )
		if vsoPill("softdigest") and health[1]/health[2] <= -health_change then
			health_change = (1 - health[1]) / health[2]
		end
		vsoResourceAddPercent( vsoGetTargetId("food"), "health", health_change, function(still_alive)
			if not still_alive then
				vsoUneat( "firstOccupant" )

				vsoSetTarget( "food", nil )
				vsoUseLounge( false, "firstOccupant" )
				setOccupants(0)
			end
		end)
	end
	updateControlMode()
end

function handleStruggles(success_chances)
	local movetype, movedir = vso4DirectionInput( "firstOccupant" )
	local struggler = 1
	if movetype == 0 then
		movetype, movedir = vso4DirectionInput( "secondOccupant" )
		struggler = 2
		if movetype == 0 then return false end
	end

	local chance = escapePillChoice(success_chances)
	if chance ~= nil
	and vsoCounterValue( "struggleCount" ) >= chance[1]
	and vsoCounterChance( "struggleCount", chance[1], chance[2] ) then
		vsoCounterReset( "struggleCount" )
		return true, struggler, movedir
	end

	local anim = nil
	if movedir == "B" then anim = "s_left" end
	if movedir == "F" then anim = "s_right" end
	if movedir == "U" then anim = "s_up" end
	if movedir == "D" then anim = "s_down" end

	if anim ~= nil then
		vsoAnim( "bodyState", anim )
		vsoSound( "struggle" )
		vsoCounterAdd( "struggleCount", 1 )
		_struggling = true
	end

	return false
end

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	vsoAnimSpeed( 1.0 );
	vsoVictimAnimVisible( "firstOccupant", false )
	vsoUseLounge( false, "firstOccupant" )
	vsoVictimAnimVisible( "secondOccupant", false )
	vsoUseLounge( false, "secondOccupant" )
	vsoUseSolid( false )

	setOccupants(0)
	resetState( "stand" )
	vsoAnim( "bodyState", "idle" )

	vsoMakeInteractive( true )

	vsoTimeDelta( "emoteblock" ) -- without this, the first call to showEmote() does nothing
end

function onBegin()	--This sets up the VSO ONCE.

	vsoEffectWarpIn();	--Play warp in effect

	onForcedReset();	--Do a forced reset once.

	vsoStorageLoad( loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	vsoOnInteract( "state_stand", interact_state_stand )
	vsoOnInteract( "state_sit", interact_state_sit )
	vsoOnInteract( "state_lay", interact_state_lay )
	vsoOnInteract( "state_sleep", interact_state_sleep )
	vsoOnInteract( "state_back", interact_state_back )
	vsoOnInteract( "state_pinned", interact_state_pinned )
	vsoOnInteract( "state_pinned_sleep", interact_state_pinned_sleep )

end

function onEnd()

	vsoEffectWarpOut();

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function state_stand()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		vsoMakeInteractive( true )
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then -- and previousState() ~= "sit" then -- needs a timer
				vsoAnim( "bodyState", "sitdown" )
				nextState( "sit" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if not controlState() then
				local escape, who = handleStruggles{ {2, 5}, {5, 15}, {10, 20} }
				if escape then
					if getOccupants() == 1 then
						vsoMakeInteractive( false )
						vsoVictimAnimSetStatus( "firstOccupant", { "vsoindicatemaw" } );
						vsoApplyStatus( "food", "droolsoaked", 5.0 );
						vsoAnim( "bodyState", "escape" )
						vsoVictimAnimReplay( "firstOccupant", "escape", "bodyState")
						nextOccupants( 0 )
						nextAction(function()
							vsoUneat( "firstOccupant" )
							vsoSetTarget( "food", nil )
							vsoUseLounge( false, "firstOccupant" )
						end)
					else
						if who == 1 then
							local food = vsoGetTargetId("food")
							vsoSetTarget( "food", vsoGetTargetId("dessert") )
							vsoSetTarget( "dessert", food )

							vsoUneat( "firstOccupant" )
							vsoUneat( "secondOccupant" )
							vsoEat( vsoGetTargetId("food"), "firstOccupant" )
							vsoEat( vsoGetTargetId("dessert"), "secondOccupant" )
						end
						vsoMakeInteractive( false )
						vsoVictimAnimSetStatus( "secondOccupant", { "vsoindicatemaw" } );
						vsoApplyStatus( "dessert", "droolsoaked", 5.0 );
						vsoAnim( "bodyState", "escape" )
						vsoVictimAnimReplay( "secondOccupant", "escape2", "bodyState")
						nextOccupants( 1 )
						nextAction(function()
							vsoUneat( "secondOccupant" )
							vsoSetTarget( "dessert", nil )
							vsoUseLounge( false, "secondOccupant" )
						end)
					end
				end
			else -- inspector
				local movetype, movedir = vso4DirectionInput( "firstOccupant" )
				if movetype > 0 then
					if movedir == "D" then
						vsoAnim( "bodyState", "sitdown" )
						nextState( "sit" )
					end
				end
			end
		end
	end
end

function interact_state_stand( targetid )
	if not stateQueued() then

		-- vsoAnim( "bodyState", "idle_back" )
		-- vsoNext( "state_idle_back" ) -- jump to currently worked on state to test
		-- return

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 2 then -- target in front
				vsoMakeInteractive( false )
				showEmote("emotehappy")
				vsoAnim( "bodyState", "eat" )
				vsoVictimAnimReplay( "firstOccupant", "playereat", "bodyState")
				nextOccupants( 1 )

				vsoSetTarget( "food", targetid )
				vsoUseLounge( true, "firstOccupant" )
				vsoEat( vsoGetTargetId( "food" ), "firstOccupant" )
				vsoVictimAnimSetStatus( "firstOccupant", { "vsoindicatemaw" } );
				vsoSound( "swallow" )
			else
				if vsoChance(20) then
					vsoAnim( "bodyState", "sitdown" )
					nextState( "sit" )
				else
					showEmote("emotehappy")
					vsoAnim( "bodyState", "pet" )
				end
			end
		elseif getOccupants() == 1 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 2 then -- target in front
				vsoMakeInteractive( false )
				showEmote("emotehappy")
				vsoAnim( "bodyState", "eat" )
				vsoVictimAnimReplay( "secondOccupant", "playereat2", "bodyState")
				nextOccupants( 2 )

				vsoSetTarget( "dessert", targetid )
				vsoUseLounge( true, "secondOccupant" )
				vsoEat( vsoGetTargetId( "dessert" ), "secondOccupant" )
				vsoVictimAnimSetStatus( "secondOccupant", { "vsoindicatemaw" } );
				vsoSound( "swallow" )
			else
				if vsoChance(20) then
					vsoAnim( "bodyState", "sitdown" )
					nextState( "sit" )
				else
					showEmote("emotehappy")
					vsoAnim( "bodyState", "pet" )
				end
			end
		else
			if vsoChance(20) then
				vsoAnim( "bodyState", "sitdown" )
				nextState( "sit" )
			else
				showEmote("emotehappy")
				vsoAnim( "bodyState", "pet" )
			end
		end

	end
end

-------------------------------------------------------------------------------

function state_sit()

	local pin_bounds = vsoRelativeRect( 2.75, -4, 3.5, -3.5 )
	vsoDebugRect( pin_bounds[1][1], pin_bounds[1][2], pin_bounds[2][1], pin_bounds[2][2] )

	if vsoAnimEnd( "bodyState" ) and updateState() then

		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "standup" )
				nextState( "stand" )
			elseif percent < 5+7 then
				local pinnable = {}
				if getOccupants() == 0 then
					pinnable = world.playerQuery( pin_bounds[1], pin_bounds[2] )
				end
				if #pinnable == 1 then
					vsoUseLounge( true, "firstOccupant" )
					vsoSetTarget( "food", pinnable[1] )
					vsoEat( pinnable[1], "firstOccupant" )
					vsoVictimAnimSetStatus( "firstOccupant", {} )
					vsoAnim( "bodyState", "pin" )
					vsoVictimAnimReplay( "firstOccupant", "sitpinned", "bodyState")
					nextState( "pinned" )
				else
					vsoAnim( "bodyState", "laydown" )
					nextState( "lay" )
				end
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if not controlState() then
				if handleStruggles{ {2, 5}, {5, 15}, {10, 20} } then
					vsoAnim( "bodyState", "standup" )
					nextState( "stand" )
				end
			else -- inspector
				local movetype, movedir = vso4DirectionInput( "firstOccupant" )
				if movetype > 0 then
					if movedir == "U" then
						vsoAnim( "bodyState", "standup" )
						nextState( "stand" )
					end
					if movedir == "D" then
						vsoAnim( "bodyState", "laydown" )
						nextState( "lay" )
					end
				end
			end
		end
	end
end

function interact_state_sit( targetid )
	if not stateQueued() then

		if vsoChance(20) then
			local relative = {0}
			if getOccupants() == 0 then
				local position = world.entityPosition( targetid )
				relative = vsoRelativePoint( position[1], position[2] )
			end
			if relative[1] > 2 then -- target in front
				vsoUseLounge( true, "firstOccupant" )
				vsoSetTarget( "food", tartetid )
				vsoEat( targetid, "firstOccupant" )
				vsoVictimAnimSetStatus( "firstOccupant", {} )
				vsoAnim( "bodyState", "pin" )
				vsoVictimAnimReplay( "firstOccupant", "sitpinned", "bodyState")
				nextState( "pinned" )
			else
				vsoAnim( "bodyState", "standup" )
				nextState( "stand" )
			end
		else
			showEmote("emotehappy");
			vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_lay()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "situp" )
				nextState( "sit" )
			elseif percent < 5+5 then
				vsoAnim( "bodyState", "fallasleep" )
				nextState( "sleep" )
			elseif percent < 5+5+10 and getOccupants() < 2 then
				vsoAnim( "bodyState", "rollover" )
				nextState( "back" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if not controlState() then
				if handleStruggles{ {2, 10}, {10, 20}, {20, 40} } then
					vsoAnim( "bodyState", "situp" )
					nextState( "sit" )
				end
			else -- inspector
				local movetype, movedir = vso4DirectionInput( "firstOccupant" )
				if movetype > 0 then
					if movedir == "U" then
						vsoAnim( "bodyState", "situp" )
						nextState( "sit" )
					end
					if movedir == "F" or movedir == "B" then
						vsoAnim( "bodyState", "rollover" )
						nextState( "back" )
					end
					if movedir == "D" then
						vsoAnim( "bodyState", "fallasleep" )
						nextState( "sleep" )
					end
				end
			end
		end
	end
end

function interact_state_lay( targetid )
	if not stateQueued() then

		local percent = vsoRand(100)
		if percent < 10 then
			vsoAnim( "bodyState", "situp" )
			nextState( "sit" )
		elseif percent < 10+10 and getOccupants() < 2 then
			vsoAnim( "bodyState", "rollover" )
			nextState( "back" )
		else
			showEmote("emotehappy");
			vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "lay" )
			else
				idle = true
			end
		end
		if idle then
			-- local percent = vsoRand(100)
			-- if percent < 15 then
			-- 	vsoAnim( "bodyState", "tail_flick" )
			-- elseif percent < 15+15 then
			-- 	vsoAnim( "bodyState", "blink" )
			-- else
				vsoAnim( "bodyState", "idle" )
			-- end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if not controlState() then
				if handleStruggles{ {5, 15}, {20, 40}, nil } then
					vsoAnim( "bodyState", "wakeup" )
					nextState( "lay" )
				end
			else -- inspector
				local movetype, movedir = vso4DirectionInput( "firstOccupant" )
				if movetype > 0 then
					if movedir == "U" then
						vsoAnim( "bodyState", "wakeup" )
						nextState( "lay" )
					end
				end
			end
		end
	end
end

function interact_state_sleep( targetid )
	if not stateQueued() then

		local percent = vsoRand(100)
		if percent < 15 then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "lay" )
		else
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_back()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "rollover" )
				nextState( "lay" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if not controlState() then
				if handleStruggles{ {5, 15}, {20, 40}, nil } then
					vsoAnim( "bodyState", "rollover" )
					nextState( "lay" )
				end
			else -- inspector
				local movetype, movedir = vso4DirectionInput( "firstOccupant" )
				if movetype > 0 then
					if movedir == "F" or movedir == "B" then
						vsoAnim( "bodyState", "rollover" )
						nextState( "lay" )
					end
				end
			end
		end
	end
end

function interact_state_back( targetid )
	if not stateQueued() then

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 3 then -- target in front
				showEmote("emotehappy");
				vsoAnim( "bodyState", "pet" )
			else
				nextState( "bed" )
				updateState()
				vsoAnim( "bodyState", "idle" )
				vsoUseLounge( true, "firstOccupant" )
				vsoSetTarget( "food", targetid )
				vsoEat( targetid, "firstOccupant" )
				vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
				vsoVictimAnimSetStatus( "firstOccupant", {} );
			end
		else
			showEmote("emotehappy");
			vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_bed() -- only accessible with no occupants

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			local hugChance = escapePillChoice{5, 5, 20}
			if percent < hugChance then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellyhug", "bodyState")
				nextState( "hug" )
			elseif percent < hugChance+hugChance then
				vsoAnim( "bodyState", "rollover" )
				vsoVictimAnimReplay( "firstOccupant", "pinned", "bodyState")
				nextState( "pinned" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	updateControlMode()
	if not controlState() then
		if vsoHasAnySPOInputs( "firstOccupant" ) then
			nextState( "back" )
			updateState()
			vsoAnim( "bodyState", "idle" )
			vsoUneat( "firstOccupant" )
			vsoUseLounge( false, "firstOccupant" )
		end
	else -- inspector
		local movetype, movedir = vso4DirectionInput( "firstOccupant" )
		if movetype > 0 then
			if movedir == "D" then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellyhug", "bodyState")
				nextState( "hug" )
			end
			if movedir == "F" or movedir == "B" then
				vsoAnim( "bodyState", "rollover" )
				vsoVictimAnimReplay( "firstOccupant", "pinned", "bodyState")
				nextState( "pinned" )
			end
		end
	end
end

function interact_state_bed( targetid )
	if not stateQueued() then

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 3 then -- target in front
				showEmote("emotehappy");
				vsoAnim( "bodyState", "pet" )
			end
		end

	end
end

-------------------------------------------------------------------------------

function state_hug()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			local unhugChance = escapePillChoice{10, 5, 1}
			local absorbChance = escapePillChoice{1, 5, 10}
			if percent < unhugChance then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
				nextState( "bed" )
			elseif percent < unhugChance+absorbChance then
				vsoSound( "slurp" )
				vsoAnim( "bodyState", "absorb" )
				vsoVictimAnimReplay( "firstOccupant", "absorbback", "bodyState")
				nextOccupants( 1 )
				nextState( "back" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			-- elseif percent < 15+15 then
			-- 	vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	updateControlMode()
	if not controlState() then
		if vsoHasAnySPOInputs( "firstOccupant" ) and vsoPill( "easyescape" ) then
			vsoAnim( "bodyState", "grab" )
			vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
			nextState( "bed" )
		end
	else -- inspector
		local movetype, movedir = vso4DirectionInput( "firstOccupant" )
		if movetype > 0 then
			if movedir == "U" then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
				nextState( "bed" )
			end
			if movedir == "J" then
				vsoSound( "slurp" )
				vsoAnim( "bodyState", "absorb" )
				vsoVictimAnimReplay( "firstOccupant", "absorbback", "bodyState")
				nextOccupants( 1 )
				nextState( "back" )
			end
		end
	end
end

function interact_state_hug( targetid )
	if not stateQueued() then

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 3 then -- target in front
				showEmote("emotehappy");
				-- vsoAnim( "bodyState", "pet" )
			end
		end

	end
end

-------------------------------------------------------------------------------

function state_pinned()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			local unpinChance = escapePillChoice{5, 3, 1}
			local absorbChance = escapePillChoice{1, 3, 5}
			if percent < unpinChance then
				vsoAnim( "bodyState", "rollover" )
				vsoVictimAnimReplay( "firstOccupant", "unpin", "bodyState")
				nextState( "bed" )
			elseif percent < unpinChance+absorbChance then
				vsoSound( "slurp" )
				vsoAnim( "bodyState", "absorb" )
				vsoVictimAnimReplay( "firstOccupant", "absorbpinned", "bodyState")
				nextOccupants( 1 )
				nextState( "lay" )
			elseif percent < unpinChance+absorbChance+3 then
				vsoAnim( "bodyState", "fallasleep")
				nextState( "pinned_sleep")
			elseif percent < unpinChance+absorbChance+3+40+3 then
				vsoAnim( "bodyState", "situp" )
				vsoVictimAnimReplay( "firstOccupant", "situnpin", "bodyState")
				nextState( "sit" )
				nextAction(function()
					vsoUneat( "firstOccupant" )
					vsoSetTarget( "food", nil )
					vsoUseLounge( false, "firstOccupant" )
				end)
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			elseif percent < 15+15+50 then
				vsoAnim( "bodyState", "lick")
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	updateControlMode()
	if not controlState() then
		if vsoHasAnySPOInputs( "firstOccupant" ) and vsoPill( "easyescape" ) then
			vsoAnim( "bodyState", "situp" )
			vsoVictimAnimReplay( "firstOccupant", "situnpin", "bodyState")
			nextState( "sit" )
		end
	else -- inspector
		local movetype, movedir = vso4DirectionInput( "firstOccupant" )
		if movetype > 0 then
			if movedir == "U" then
				vsoAnim( "bodyState", "situp" )
				vsoVictimAnimReplay( "firstOccupant", "situnpin", "bodyState")
				nextState( "sit" )
				nextAction(function()
					vsoUneat( "firstOccupant" )
					vsoSetTarget( "food", nil )
					vsoUseLounge( false, "firstOccupant" )
				end)
			end
			if movedir == "D" then
				vsoAnim( "bodyState", "fallasleep")
				nextState( "pinned_sleep")
			end
			if movedir == "F" or movedir == "B" then
				vsoAnim( "bodyState", "rollover" )
				vsoVictimAnimReplay( "firstOccupant", "unpin", "bodyState")
				nextState( "bed" )
			end
			if movedir == "J" then
				vsoSound( "slurp" )
				vsoAnim( "bodyState", "absorb" )
				vsoVictimAnimReplay( "firstOccupant", "absorbpinned", "bodyState")
				nextOccupants( 1 )
				nextState( "lay" )
			end
		end
	end
end

function interact_state_pinned( targetid )
	if not stateQueued() then

		showEmote("emotehappy");
		vsoAnim( "bodyState", "pet" )

	end
end

-------------------------------------------------------------------------------

function state_pinned_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "pinned" )
			else
				idle = true
			end
		end
		if idle then
			-- local percent = vsoRand(100)
			-- if percent < 15 then
			-- 	vsoAnim( "bodyState", "tail_flick" )
			-- elseif percent < 15+15 then
			-- 	vsoAnim( "bodyState", "blink" )
			-- else
				vsoAnim( "bodyState", "idle" )
			-- end
		end
	end

	updateControlMode()
	if not controlState() then
		if vsoHasAnySPOInputs( "firstOccupant" ) and vsoPill( "easyescape" ) then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "pinned" )
		end
	else -- inspector
		local movetype, movedir = vso4DirectionInput( "firstOccupant" )
		if movetype > 0 then
			if movedir == "U" then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "pinned" )
			end
		end
	end
end

function interact_state_pinned_sleep( targetid )
	if not stateQueued() then

		local percent = vsoRand(100)
		if percent < 15 then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "pinned" )
		else
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		end

	end
end