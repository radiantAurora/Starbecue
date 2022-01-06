
function sbq.letout(id, i)
	world.sendEntityMessage( player.loungingIn(), "letout", id )
end

function sbq.turboDigest(id, i)
	world.sendEntityMessage( id, "sbqTurboDigest" )
end

function sbq.transform(id, i)
	world.sendEntityMessage( player.loungingIn(), "transform", id, 3 )
end

function sbq.xeroEggify(id, i)
	if sbq.occupant[i].location ~= "belly" then return end
	world.sendEntityMessage( player.loungingIn(), "transform", id, 3, {
		barColor = {"aa720a", "e4a126", "ffb62e", "ffca69"},
		forceSettings = true,
		layer = true,
		state = "smol",
		species = "sbqEgg",
		layerLocation = "egg",
		settings = {
			cracks = 0,
			bellyEffect = "sbqHeal",
			escapeDifficulty = sbq.sbqSettings.global.escapeDifficulty,
			skinNames = {
				head = "xeronious",
				body = "xeronious"
			}
		}
	})
end
