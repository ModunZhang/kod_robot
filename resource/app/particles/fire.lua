return function()
	local emitter = cc.ParticleSun:createWithTotalParticles(50)
	emitter:setPositionType(2)
    emitter:setPosVar(cc.p(40,0))
    emitter:setLife(2)
    emitter:setSpeed(50)
    emitter:setStartSize(60)
    emitter:setAngleVar(0)
    emitter:setEmissionRate(emitter:getTotalParticles()/emitter:getLife())
    emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("fire.png"))
    return emitter
end