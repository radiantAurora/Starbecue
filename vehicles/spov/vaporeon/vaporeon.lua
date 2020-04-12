--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")

--[[

vaporeon plan:

	state chart:
	              sleep
	                |
	 *idle - sit - lay - back ·· bed - hug
	   :                                V
	  full - sit - lay - back <----- shlorp
	                |
	              sleep

	  *idle: start
	  (struggling not included in chart, everything in full has it)

	
	todo:
	- roll over on top of player, as alternative to hugging when you're laying on its belly
	- location dependent interaction
	  - in front -> eat, beside/behind -> pet
	- multiple prey?
	  - 2 max
	  - 2 bulges? struggle independently?
	    - split the sprite up into multiple components

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
	if vsoTimeDelta( "emoteblock" ) > 1 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
	end
end

function escapePillChoice(list)
	if vsoPill( "easyescape" ) then return list[1] end
	if vsoPill( "antiescape" ) then return list[3] end
	return list[2]
end

function bellyEffects(empty_state)
	local effect = 0
	if vsoPill( "digest" ) or vsoPill( "softdigest" ) then
		effect = -1
	elseif vsoPill( "heal" ) then
		effect = 1
	end
	if effect ~= 0 then
		effect = effect * vsoDelta()
		local health = world.entityHealth( vsoGetTargetId("food") )
		if vsoPill("softdigest") and health[1]/health[2] <= -effect then
			effect = (1 - health[1]) / health[2]
		end
		vsoResourceAddPercent( vsoGetTargetId("food"), "health", effect, function(still_alive)
			if not still_alive then
				vsoUneat( "drivingSeat" )

				vsoSetTarget( "food", nil )
				vsoUseLounge( false, "drivingSeat" )
				vsoNext( empty_state )
			end
		end)
	end
end

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	vsoAnimSpeed( 1.0 );
	vsoVictimAnimVisible( "drivingSeat", false )
	vsoUseLounge( false, "drivingSeat" )
	vsoUseSolid( false )

	vsoNext( "state_idle" )
	vsoAnim( "bodyState", "idle" )

	vsoMakeInteractive( true )
end

function onBegin()	--This sets up the VSO ONCE.

	vsoEffectWarpIn();	--Play warp in effect

	onForcedReset();	--Do a forced reset once.

	vsoStorageLoad( loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	vsoOnBegin( "state_idle", begin_state_idle )
	vsoOnInteract( "state_idle", interact_state_idle )

	vsoOnInteract( "state_idle_sit", interact_state_idle_sit )
	vsoOnInteract( "state_idle_lay", interact_state_idle_lay )
	vsoOnInteract( "state_idle_sleep", interact_state_idle_sleep )
	vsoOnInteract( "state_idle_back", interact_state_idle_back )

	vsoOnBegin( "state_eat", begin_state_eat )

	vsoOnBegin( "state_full", begin_state_full )

	vsoOnBegin( "state_release", begin_state_release )
	vsoOnEnd( "state_release", end_state_release )

	vsoOnBegin( "state_idle_walk", begin_state_idle_walk )
	vsoOnInteract( "state_idle_walk", interact_state_idle_walk )
	vsoOnEnd( "state_idle_walk", end_state_idle_walk )

end

function onEnd()

	vsoEffectWarpOut();

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function begin_state_idle()
	vsoUseLounge( false, "drivingSeat" )
	vsoAnim( "bodyState", "idle" )
	vsoMakeInteractive( true )

	wanderActionState = wanderNearActionEnterWith{ }
end

function state_idle()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "idle_sitdown" )
			vsoNext( "state_idle_sit" )
		-- elseif percent < 100 then
		-- 	vsoNext( "state_idle_walk")
		elseif percent < 5+15 then
			vsoAnim( "bodyState", "idle_tail_flick" )
		elseif percent < 5+15+15 then
			vsoAnim( "bodyState", "idle_blink" )
		else
			vsoAnim( "bodyState", "idle" )
		end
	end
end

function interact_state_idle( targetid )

	local anim = vsoAnimCurr( "bodyState" );

	showEmote("emotehappy")
	vsoSetTarget( "food", targetid )
	vsoNext( "state_eat" )

	-- vsoAnim( "bodyState", "idle_back" )
	-- vsoNext( "state_idle_back" ) -- jump to currently worked on state to test

end

-------------------------------------------------------------------------------

function state_idle_sit()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "idle_standup" )
			vsoNext( "state_idle" )
		elseif percent < 5+7 then
			vsoAnim( "bodyState", "idle_laydown" )
			vsoNext( "state_idle_lay" )
		elseif percent < 5+7+15 then
			vsoAnim( "bodyState", "idle_sit_tail_flick" )
		elseif percent < 5+7+15+15 then
			vsoAnim( "bodyState", "idle_sit_blink" )

		else
			vsoAnim( "bodyState", "idle_sit" )
		end
	end
end

function interact_state_idle_sit( targetid )

	local anim = vsoAnimCurr( "bodyState" );

	if vsoChance(20) then
		vsoAnim( "bodyState", "idle_standup" )
		vsoNext( "state_idle" )
	else
		showEmote("emotehappy");
		vsoAnim( "bodyState", "idle_sit_pet" )
	end

end

-------------------------------------------------------------------------------

function state_idle_lay()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "idle_situp" )
			vsoNext( "state_idle_sit" )
		elseif percent < 5+5 then
			vsoAnim( "bodyState", "idle_fallasleep" )
			vsoNext( "state_idle_sleep" )
		elseif percent < 5+5+10 then
			vsoAnim( "bodyState", "idle_lay_rollover" )
			vsoNext( "state_idle_back" )
		elseif percent < 5+5+10+15 then
			vsoAnim( "bodyState", "idle_lay_tail_flick" )
		elseif percent < 5+5+10+15+15 then
			vsoAnim( "bodyState", "idle_lay_blink" )
		else
			vsoAnim( "bodyState", "idle_lay" )
		end
	end
end

function interact_state_idle_lay( targetid )

	local anim = vsoAnimCurr( "bodyState" );

	local percent = vsoRand(100)
	if percent < 10 then
		vsoAnim( "bodyState", "idle_situp" )
		vsoNext( "state_idle_sit" )
	-- elseif percent < 10+20 then
	-- 	vsoAnim( "bodyState", "idle_lay_rollover" )
	-- 	vsoNext( "state_idle_back" )
	else
		showEmote("emotehappy");
		vsoAnim( "bodyState", "idle_lay_pet" )
	end

end

-------------------------------------------------------------------------------

function state_idle_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "idle_wakeup" )
			vsoNext( "state_idle_lay" )
		-- elseif percent < 1+5 then
		-- 	vsoAnim( "bodyState", "idle_fallasleep" )
		-- 	vsoNext( "state_idle_sleep" )
		else
			vsoAnim( "bodyState", "idle_sleep" )
		end
	end
end

function interact_state_idle_sleep( targetid )

	local anim = vsoAnimCurr( "bodyState" );

	local percent = vsoRand(100)
	if percent < 5 then
		vsoAnim( "bodyState", "idle_wakeup" )
		vsoNext( "state_idle_lay" )
	else
		showEmote("emotehappy");
		-- vsoAnim( "bodyState", "idle_sleep_pet" )
	end

end

-------------------------------------------------------------------------------

function state_idle_back()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "idle_back_rollover" )
			vsoNext( "state_idle_lay" )
		-- elseif percent < 1+5 then
		-- 	vsoAnim( "bodyState", "idle_fallasleep" )
		-- 	vsoNext( "state_idle_sleep" )
		else
			vsoAnim( "bodyState", "idle_back" )
		end
	end
end

function interact_state_idle_back( targetid )

	local anim = vsoAnimCurr( "bodyState" );

	vsoUseLounge( true, "drivingSeat" )
	vsoEat( targetid, "drivingSeat" )
	vsoVictimAnimReplay( "drivingSeat", "bellybed", "bodyState")
	vsoVictimAnimSetStatus( "drivingSeat", {} );
	vsoNext( "state_idle_back_bed" )

end

-------------------------------------------------------------------------------

function state_idle_back_bed()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		local hugChance = escapePillChoice{5, 5, 20}
		if percent < hugChance then
			vsoAnim( "bodyState", "idle_back_grab" )
			vsoNext( "state_idle_back_hug" )
			vsoVictimAnimReplay( "drivingSeat", "bellyhug", "bodyState")
		-- elseif percent < 1+5 then
		-- 	vsoAnim( "bodyState", "idle_fallasleep" )
		-- 	vsoNext( "state_idle_sleep" )
		else
			vsoAnim( "bodyState", "idle_back" )
		end
	end

	if vsoHasAnySPOInputs( "drivingSeat" ) then
		vsoUneat( "drivingSeat" )
		vsoUseLounge( false, "drivingSeat" )
		vsoNext( "state_idle_back" )
	end
end

-------------------------------------------------------------------------------

function state_idle_back_hug()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		local unhugChance = escapePillChoice{10, 5, 1}
		local absorbChance = escapePillChoice{1, 5, 10}
		if percent < unhugChance then
			vsoAnim( "bodyState", "idle_back_grab" )
			vsoNext( "state_idle_back_bed" )
			vsoVictimAnimReplay( "drivingSeat", "bellybed", "bodyState")
		elseif percent < unhugChance+absorbChance then
			vsoSound( "slurp" )
			vsoAnim( "bodyState", "absorb_back" )
			vsoVictimAnimReplay( "drivingSeat", "absorbback", "bodyState")
			vsoNext( "state_absorb_back" )
		else
			vsoAnim( "bodyState", "idle_back_hug" )
		end
	end

	if vsoHasAnySPOInputs( "drivingSeat" ) and vsoPill( "easyescape" ) then
		vsoAnim( "bodyState", "idle_back_grab" )
		vsoNext( "state_idle_back_bed" )
		vsoVictimAnimReplay( "drivingSeat", "bellybed", "bodyState")
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function begin_state_eat()

	vsoAnim( "bodyState", "eat"  )

	vsoMakeInteractive( false )
	vsoUseLounge( true, "drivingSeat" )
	vsoEat( vsoGetTargetId( "food" ), "drivingSeat" )
	vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatemaw" } );
	vsoVictimAnimReplay( "drivingSeat", "playereat", "bodyState")

end

function state_eat()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoMakeInteractive( true )
		vsoSound( "swallow" )
		vsoAnim( "bodyState", "full_look" )
		vsoNext( "state_full" )
	end
end

-------------------------------------------------------------------------------

local struggleType, struggleDir -- keep between functions

function struggle_generator(state, has_look)
	if state == nil then
		state = ""
	else
		state = "_"..state
	end
	local look_state
	if has_look == false then
		look_state = state
	else
		look_state = state.."_look"
	end

	return function()
		local movedir = struggleDir
		struggleDir = "-"
		local direction_name = nil
		if movedir == "B" then direction_name = "_left" end
		if movedir == "F" then direction_name = "_right" end
		if movedir == "U" then direction_name = "_up" end
		if movedir == "D" then direction_name = "_down" end

		if direction_name ~= nil then
			vsoAnim( "bodyState", "struggle"..state..direction_name )
			vsoSound( "struggle" )
			vsoCounterAdd( "struggleCount", 1 )
		elseif movedir ~= "-" then
			vsoNext( "state_full"..state )
		end

		local anim = vsoAnimCurr( "bodyState" );

		if vsoAnimEnd( "bodyState" ) then
			vsoAnim( "bodyState", "full"..look_state )
			vsoNext( "state_full"..state )
		end
	end
end

function struggle_handler(success_chances, struggle_state, success_state, success_anim)
	local movetype, movedir = vso4DirectionInput( "drivingSeat" )
	if movetype ~= 0 then
		local chance = escapePillChoice(success_chances)
		if chance ~= nil
		and vsoCounterValue( "struggleCount" ) >= chance[1]
		and vsoCounterChance( "struggleCount", chance[1], chance[2] )then
			vsoCounterReset( "struggleCount" )
			if success_anim ~= nil then
				vsoAnim( "bodyState", success_anim )
			end
			vsoNext( success_state )
		else
			struggleDir = movedir
			vsoNext( struggle_state )
		end
	end
end

function begin_state_full()

	vsoVictimAnimVisible( "drivingSeat", false )

	vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatebelly" } );

	vsoTimerSet( "gurgle", 1.0, 8.0 )	--For playing sounds

end

function state_full()

	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then	--play gurgle sounds <= "Play sound from list [soundlist] every [ 1 to 8 seconds ]"
		vsoSound( "digest" )
	end

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoCounterReset( "struggleCount" )
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "full_sitdown" )
			vsoNext( "state_full_sit" )
		-- elseif percent < 5+10 then
			-- vsoNext( "state_full_walk")
		elseif percent < 5+15 then
			vsoAnim( "bodyState", "full_tail_flick" )
		elseif percent < 5+15+15 then
			vsoAnim( "bodyState", "full_blink" )
		else
			vsoAnim( "bodyState", "full" )
		end
	end

	struggle_handler({{2, 5}, {5, 15}, {10, 20}}, "state_struggle", "state_release")
	bellyEffects( "state_idle" )
end

state_struggle = struggle_generator()

-------------------------------------------------------------------------------

function state_full_sit()

	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then	--play gurgle sounds <= "Play sound from list [soundlist] every [ 1 to 8 seconds ]"
		vsoSound( "digest" )
	end

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoCounterReset( "struggleCount" )
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "full_standup" )
			vsoNext( "state_full" )
		elseif percent < 5+25 then
			vsoAnim( "bodyState", "full_laydown" )
			vsoNext( "state_full_lay" )
		elseif percent < 5+25+15 then
			vsoAnim( "bodyState", "full_sit_blink" )
		elseif percent < 5+25+15+15 then
			vsoAnim( "bodyState", "full_sit_tail_flick" )
		else
			vsoAnim( "bodyState", "full_sit" )
		end
	end

	struggle_handler({{2, 5}, {5, 15}, {10, 20}}, "state_struggle_sit", "state_full", "full_standup")
	bellyEffects( "state_idle_sit" )
end

state_struggle_sit = struggle_generator("sit")

-------------------------------------------------------------------------------

function state_full_lay()

	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then	--play gurgle sounds <= "Play sound from list [soundlist] every [ 1 to 8 seconds ]"
		vsoSound( "digest" )
	end

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoCounterReset( "struggleCount" )
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "full_situp" )
			vsoNext( "state_full_sit" )
		elseif percent < 5+10 then
			vsoAnim( "bodyState", "full_fallasleep" )
			vsoNext( "state_full_sleep" )
		elseif percent < 5+10+10 then
			vsoAnim( "bodyState", "full_lay_rollover" )
			vsoNext( "state_full_back" )
		elseif percent < 5+10+10+15 then
			vsoAnim( "bodyState", "full_lay_blink" )
		elseif percent < 5+10+10+15+15 then
			vsoAnim( "bodyState", "full_lay_tail_flick" )
		else
			vsoAnim( "bodyState", "full_lay" )
		end
	end

	struggle_handler({{2, 10}, {10, 20}, {20, 40}}, "state_struggle_lay", "state_full_sit", "full_situp")
	bellyEffects( "state_idle_lay" )
end

state_struggle_lay = struggle_generator("lay")

-------------------------------------------------------------------------------

function state_full_sleep()

	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then	--play gurgle sounds <= "Play sound from list [soundlist] every [ 1 to 8 seconds ]"
		vsoSound( "digest" )
	end

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoCounterReset( "struggleCount" )
		local percent = vsoRand(100)
		if percent < 15 then
			vsoAnim( "bodyState", "full_wakeup" )
			vsoNext( "state_full_lay" )
		--elseif percent < 15+15 then
		--	vsoAnim( "bodyState", "full_wakeup" )
		--	vsoAnim( "bodyState", "idle_lay_rollover" )
		--	vsoNext( "state_full_back" )
		-- elseif percent < 1+5 then
		-- 	vsoAnim( "bodyState", "full_fallasleep" )
		-- 	vsoNext( "state_full_sleep" )
		else
			vsoAnim( "bodyState", "full_sleep" )
		end
	end

	struggle_handler({{5, 15}, {20, 40}, nil}, "state_struggle_sleep", "state_full_lay", "full_wakeup")
	bellyEffects( "state_idle_sleep" )
end

state_struggle_sleep = struggle_generator("sleep", false)

-------------------------------------------------------------------------------

function state_absorb_back()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatebelly" } )
		vsoAnim( "bodyState", "full_back" )
		vsoNext( "state_full_back" )
	end
end

-------------------------------------------------------------------------------

function state_full_back()

	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then	--play gurgle sounds <= "Play sound from list [soundlist] every [ 1 to 8 seconds ]"
		vsoSound( "digest" )
	end

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) then
		vsoCounterReset( "struggleCount" )
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "full_back_rollover" )
			vsoNext( "state_full_lay" )
		-- elseif percent < 1+5 then
		-- 	vsoAnim( "bodyState", "full_fallasleep" )
		-- 	vsoNext( "state_full_sleep" )
		else
			vsoAnim( "bodyState", "full_back" )
		end
	end

	struggle_handler({{5, 15}, {20, 40}, nil}, "state_struggle_back", "state_full_back", "full_back_rollover")
	bellyEffects( "state_idle_back" )
end

state_struggle_back = struggle_generator("back", false)

-------------------------------------------------------------------------------

function begin_state_release()
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatemaw" } );
	vsoAnim( "bodyState", "escape" )
	vsoVictimAnimReplay( "drivingSeat", "escape", "bodyState")
end

function state_release()
	if vsoAnimEnd( "bodyState" ) then
		vsoMakeInteractive( true )
		vsoNext( "state_idle" )	--release
	end
end

function end_state_release()

	vsoUneat( "drivingSeat" )

	vsoApplyStatus( "food", "droolsoaked", 5.0 );	--Add status effect "droolsoaked"

	vsoSetTarget( "food", nil )
	vsoAnim( "bodyState", "idle" )
	vsoUseLounge( false, "drivingSeat" )
end

-------------------------------------------------------------------------------

function begin_state_idle_walk()
	vsoMotionParam( { walkSpeed=4, runSpeed=7 } )
	vsoActFollow( world.playerQuery(mcontroller.position(), 50)[1] )
end

function state_idle_walk()
	local anim = vsoAnimCurr( "bodyState" );
	if vsoAnimEnd( "bodyState" ) then
		local percent = vsoRand(100)
		if percent < 1 then
			vsoNext( "state_idle" )
		else
			vsoAnim( "bodyState", "idle_sit" )
		end
	end
end

function interact_state_idle_walk()
	vsoNext( "state_idle" )
end

function end_state_idle_walk()
	vsoActClear();
end