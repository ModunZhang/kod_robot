return function(size)
	local w, h = size.width, size.height
	local node = display.newNode()
	local emitter = cc.ParticleSystemQuad:create("particles/fire_wall.plist")
    emitter:setPositionType(2)
    emitter:setPosVar(cc.p(0, h/2 * 0.8))
    emitter:setTotalParticles(40)
    emitter:setEmissionRate(emitter:getTotalParticles()/emitter:getLife())
    emitter:addTo(node):pos(w/2, 0)

    local emitter = cc.ParticleSystemQuad:create("particles/fire_wall.plist")
    emitter:setPositionType(2)
    emitter:setPosVar(cc.p(0, h/2 * 0.8))
    emitter:setScaleX(-1)
    emitter:setTotalParticles(40)
    emitter:setEmissionRate(emitter:getTotalParticles()/emitter:getLife())
    emitter:addTo(node):pos(-w/2, 0)

    local emitter = cc.ParticleSystemQuad:create("particles/fire_wall.plist")
    emitter:setPositionType(2)
    emitter:setPosVar(cc.p(w/2, 5))
    emitter:addTo(node):pos(0, h/2)

    -- local emitter = cc.ParticleSystemQuad:create("particles/fire_wall.plist")
    -- emitter:setPosVar(cc.p(w/2, 5))
    -- emitter:addTo(node):pos(0, -h/2+10)

    local emitter = cc.ParticleSystemQuad:create("particles/fire_wall.plist")
    emitter:setPositionType(2)
    emitter:setPosVar(cc.p(w/2-5, 0))
    emitter:setGravity(cc.p(0, -100))
    emitter:addTo(node):pos(0, -h/2+5):rotation(180)

    return node
end