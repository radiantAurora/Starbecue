local _scanHouseContents = scanHouseContents

function scanHouseContents(boundary)
	local returnValues = _scanHouseContents(boundary)

	for object, _ in pairs(returnValues.objects) do
		local name = world.entityName(object)
		if name == "sbqVoreColonyDeed" or name == "compactdeed" or name == "sbqVoreCompactDeed"then
			returnValues.otherDeed = true
			returnValues.objects[object] = nil
		end
	end

	return returnValues
end
