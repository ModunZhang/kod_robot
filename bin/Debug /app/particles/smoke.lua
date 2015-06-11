return function()
	local emitter = cc.ParticleSystemQuad:create("particles/BoilingFoam.plist")
	emitter:setPositionType(2)
    emitter:setBlendFunc(gl.ONE, gl.ONE_MINUS_SRC_COLOR)
    emitter:setStartColor(cc.c4f(0.5, 0.5, 0.5, 0.5))
    emitter:setEndColor(cc.c4f(0.5, 0.5, 0.5, 0))
    return emitter
end