return function()
	local emitter = cc.ParticleSystemQuad:create("particles/BoilingFoam.plist")
	emitter:setPositionType(2)
	emitter:setPosVar(cc.p(0,0))
	emitter:setTangentialAccel(-10)
	emitter:setLife(2)
	emitter:setLifeVar(2)
    emitter:setBlendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA)
    emitter:setStartColor(cc.c4f(0.8, 0.8, 0.8, 0.5))
    emitter:setEndColor(cc.c4f(0.8, 0.8, 0.8, 0))
    emitter:setEmissionRate(emitter:getTotalParticles() / emitter:getLife())
    return emitter
end