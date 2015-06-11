return function()
	local emitter = cc.ParticleFire:createWithTotalParticles(150)
	emitter:setPositionType(2)
    -- emitter:setPosVar(cc.p(80,0))
 --    emitter:setAngleVar(45)
        emitter:setLife(2)
    -- emitter:setSpeed(100)
    emitter:setStartSize(60)
 --    emitter:setAngleVar(0)
 --    emitter:setEmissionRate(emitter:getTotalParticles()/emitter:getLife())
    -- emitter:setBlendFunc(gl.ONE, gl.ONE_MINUS_SRC_COLOR)
    emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("fire.png"))
    return emitter
end