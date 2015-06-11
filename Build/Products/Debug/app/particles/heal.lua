return function()
    local emitter = cc.ParticleSnow:createWithTotalParticles(10)
    emitter:setPositionType(2)
    emitter:setAngle(90)
    emitter:setPosVar(cc.p(60,0))
    emitter:setLife(3.0)
    emitter:setLifeVar(0)
    emitter:setGravity(cc.p(0,1))
    emitter:setSpeed(90)
    emitter:setSpeedVar(20)
    emitter:setStartColor(cc.c4f(1,1,1,1))
    emitter:setStartColorVar(cc.c4f(0,0,0,0.0))
    emitter:setEndColor(cc.c4f(1,1,1,0.1))
    emitter:setStartSize(30)
    emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("+_red.png"))
    emitter:setEmissionRate(emitter:getTotalParticles() / emitter:getLife())
    emitter:updateWithNoTime()
    return emitter
end
