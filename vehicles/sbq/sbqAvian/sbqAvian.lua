
require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
	smol = {}
}
-------------------------------------------------------------------------------

function sbq.init()
	getColors()
	checkPartsEnabled()
end

function sbq.update(dt)
	sbq.changeSize()
	sbq.armRotationUpdate()
	sbq.setGrabTarget()
end

function sbq.setItemActionColorReplaceDirectives()
	local colorReplaceString = sbq.sbqData.itemActionDirectives or ""

	if sbq.sbqData.replaceColors ~= nil then
		local i = 1
		local basePalette = { "4cc1c9", "39979e", "23646a", "154247" }
		local replacePalette = sbq.sbqData.replaceColors[i][((sbq.settings.replaceColors or {})[i] or (sbq.sbqData.defaultSettings.replaceColors or {})[i] or 1) + 1]
		local fullbright = (sbq.settings.fullbright or {})[i]

		if sbq.settings.replaceColorTable and sbq.settings.replaceColorTable[i] then
			replacePalette = sbq.settings.replaceColorTable[i]
		end

		for j, color in ipairs(basePalette) do
			color = replacePalette[j]
			if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
				color = color.."fb"
			end
							colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")

		end
	end

	sbq.itemActionDirectives = colorReplaceString
end

function sbq.otherLocationEffects(i, eid, health, bellyEffect, location )
	if (sbq.settings.penisCumTF and location == "shaft" and (sbq.occupant[i].progressBar <= 0))
	or (sbq.settings.ballsCumTF and ( location == "balls" or location == "ballsR" or location == "ballsL" ) and (sbq.occupant[i].progressBar <= 0))
	then
		sbq.loopedMessage("CumTF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
			if not immune then
				transformMessageHandler( eid , 3, sbq.config.victimTransformPresets.cumBlob )
			end
		end)
	end
end

function sbq.changeSize()
	if sbq.tapControl( sbq.driverSeat, "special1" ) and sbq.totalTimeAlive > 0.5 and not sbq.transitionLock then
		local changeSize = "smol"
		if sbq.state == changeSize then
			changeSize = "stand"
		end
		sbq.warpInEffect() --Play warp in effect
		sbq.setState( changeSize )
	end
end

function sbq.settingsMenuUpdated()
	checkPartsEnabled()
end

function getColors()
	if not sbq.settings.firstLoadDone then
		if world.entitySpecies(sbq.spawner) == "avian" then
			-- get the directives for color here if you are an avian
			local portrait = world.entityPortrait(sbq.spawner, "full")
			for _, part in ipairs(portrait) do
				local imageString = part.image
				-- check for doing an emote animation
				local found1, found2 = imageString:find("/emote.png:")
				if found1 ~= nil then
					local found3, found4 = imageString:find(".1", found2, found2+10 )
					if found3 ~= nil then
						local directives = imageString:sub(found4+1)
						sbq.settings.directives = directives
						sbq.settings.replaceColorTable[1] = directives
					end
				end
				--get personality values
				found1, found2 = imageString:find("body.png:idle.")
				if found1 ~= nil then
					sbq.setPartTag( "global", "bodyPersonality", imageString:sub(found2+1, found2+1) )
				end
				found1, found2 = imageString:find("backarm.png:idle.")
				if found1 ~= nil then
					sbq.setPartTag( "global", "backarmPersonality", imageString:sub(found2+1, found2+1) )
				end
				found1, found2 = imageString:find("frontarm.png:idle.")
				if found1 ~= nil then
					sbq.setPartTag( "global", "frontarmPersonality", imageString:sub(found2+1, found2+1) )
				end

				getPlayerInitialCustomize( imageString, "fluff/", "fluff" )
				getPlayerInitialCustomize( imageString, "beaks/", "beak" )
				getPlayerInitialCustomize( imageString, "hair/", "hair" )
			end
		else
			-- get random directives for anyone thats not an avian
			for i = 1, #sbq.sbqData.replaceColors do
				sbq.settings.replaceColors[i] = math.random( #sbq.sbqData.replaceColors[i] - 1 )
			end
			for skin, data in pairs(sbq.sbqData.replaceSkin) do
				local result = data.skins[math.random(#data.skins)]
				for i, partname in ipairs(data.parts) do
					sbq.settings.skinNames[partname] = result
				end
			end
		end

		local waist = "default"
		local gender = world.entityGender(sbq.spawner)
		if (gender == "female") or ( (gender == nil) and (math.random() > 0.5) ) then
			sbq.settings.breasts = true
			waist = "thin_waist"
		end

		for i, partname in ipairs(sbq.sbqData.replaceSkin.body.parts) do
			sbq.settings.skinNames[partname] = waist
		end

		sbq.settings.firstLoadDone = true
		sbq.setColorReplaceDirectives()
		sbq.setSkinPartTags()
		world.sendEntityMessage(sbq.spawner, "sbqSaveSettings", sbq.settings, "sbqAvian")
	end
end

function getPlayerInitialCustomize( imageString, name, skin )
	found1, found2 = imageString:find(name)
	if found1 ~= nil then
		local result = imageString:sub(found2+1, found2+2)

		if result:sub(-1) == "." then
			result = result:sub(1,1)
		end

		if result == "1" then
			result = "default"
		end

		for i, partname in ipairs(sbq.sbqData.replaceSkin[skin].parts) do
			sbq.settings.skinNames[partname] = result
		end
	end
end

function checkPartsEnabled()
	local defaultSbqData = config.getParameter("sbqData")
	if sbq.settings.penis then
		sbq.setPartTag("global", "cockVisible", "")
		sbq.sbqData.locations.shaft.max = defaultSbqData.locations.shaft.max
	else
		sbq.setPartTag("global", "cockVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.shaft.max = 0
	end
	if sbq.settings.balls then
		sbq.setPartTag("global", "ballsVisible", "")
		sbq.sbqData.locations.ballsL.max = defaultSbqData.locations.balls.max
		sbq.sbqData.locations.ballsR.max = defaultSbqData.locations.balls.max
	else
		sbq.setPartTag("global", "ballsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.ballsL.max = 0
		sbq.sbqData.locations.ballsR.max = 0
	end
	if sbq.settings.breasts then
		sbq.setPartTag("global", "breastsVisible", "")
		sbq.sbqData.locations.breastsL.max = defaultSbqData.locations.breasts.max
		sbq.sbqData.locations.breastsR.max = defaultSbqData.locations.breasts.max
	else
		sbq.setPartTag("global", "breastsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.breastsL.max = 0
		sbq.sbqData.locations.breastsR.max = 0
	end
end

function sbq.letout(id)
	local id = id or sbq.getRecentPrey()
	if not id then return false end

	local location = sbq.lounging[id].location

	if location == "belly" then
		--if p.heldControl(p.driverSeat, "down") or p.lounging[id].species == "sbqEgg" then
		--	return p.doTransition("analEscale", {id = id})
		--else
			return sbq.doTransition("oralEscape", {id = id})
		--end
	elseif location == "hug" then
		sbq.grabbing = nil
		return sbq.uneat(id)
	elseif location == "shaft" then
		return sbq.doTransition("cockEscape", {id = id})
	elseif location == "ballsL" or location == "ballsR" then
		return sbq.ballsToShaft({id = id})
	end
end

function grab()
	sbq.grab("hug")
end

function cockVore(args, tconfig)
	return sbq.doVore(args, "shaft", {}, "swallow", tconfig.voreType)
end

function cockEscape(args, tconfig)
	return sbq.doEscape(args, {glueslow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {}, tconfig.voreType )
end

function oralVore(args, tconfig)
	sbq.grabbing = args.id
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function oralEscape(args, tconfig)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
end

function checkOralVore()
	return sbq.checkEatPosition(sbq.localToGlobal( {0, 0} ), 5, "belly", "oralVore")
end

function checkCockVore()
	if sbq.checkEatPosition(sbq.localToGlobal( {0, -3} ), 4, "shaft", "cockVore") then return true
	else
		sbq.shaftToBalls({id = sbq.findFirstOccupantIdForLocation("shaft")})
	end
end

-------------------------------------------------------------------------------
function state.stand.begin()
	sbq.setMovementParams( "default" )
	sbq.resolvePosition(5)
end

state.stand.oralVore = oralVore
state.stand.cockVore = cockVore
state.stand.oralEscape = oralEscape
state.stand.cockEscape = cockEscape

state.stand.checkCockVore = checkCockVore
state.stand.checkOralVore = checkOralVore

state.stand.shaftToBalls = sbq.shaftToBalls
state.stand.ballsToShaft = sbq.ballsToShaft
state.stand.switchBalls = sbq.switchBalls

state.stand.grab = grab

-------------------------------------------------------------------------------

function state.smol.begin()
	sbq.setMovementParams( "smol" )
	sbq.letGrabGo("hug")
	sbq.resolvePosition(3)
end

-------------------------------------------------------------------------------
