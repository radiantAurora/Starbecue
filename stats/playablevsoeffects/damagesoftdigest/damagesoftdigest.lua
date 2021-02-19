function init()
  script.setUpdateDelta(5)

end

function update(dt)
  local health = world.entityHealth(entity.id())
  if health[1] > ( 1 * dt ) then
    status.modifyResourcePercentage("health", -1 * dt)
  end
end

function uninit()

end
