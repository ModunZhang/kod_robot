return function()
    local emitter = cc.ParticleSystemQuad:createWithTotalParticles(2)
    emitter:setDuration(-1)
    emitter:setEmitterMode(0)
    emitter:setPositionType(2)
    emitter:setAngle(45)
    emitter:setPosVar(cc.p(0,0))
    emitter:setLife(3)
    emitter:setLifeVar(0)
    emitter:setStartSize(35)
    emitter:setEndSize(45)
    emitter:setGravity(cc.p(0,0))
    emitter:setSpeed(25)
    emitter:setSpeedVar(0)
    emitter:setStartColor(cc.c4f(1))
    emitter:setEndColor(cc.c4f(1,1,1,0))
    emitter:setEmissionRate(0.65)
    emitter:setBlendAdditive(false)
    emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("z.png"))
    emitter:updateWithNoTime()
    return emitter
end


