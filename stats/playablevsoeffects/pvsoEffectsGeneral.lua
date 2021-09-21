

function removeOtherBellyEffects(name)

	local bellyEffectList = root.assetJson("/pvso_general.config:bellyStatusEffects")
	for _, effect in ipairs(bellyEffectList) do
		if effect ~= name then
			status.removeEphemeralEffect(effect)
		end
	end
end
