local UILib = import("..ui.UILib")
local CityLayer = import("..layers.CityLayer")
local IsoMapAnchorBottomLeft = import("..map.IsoMapAnchorBottomLeft")
local MapScene = import(".MapScene")
local CityScene = class("CityScene", MapScene)

local app = app
local timer = app.timer
local DEBUG_LOCAL = false
function CityScene:ctor(city)
    self.city = city
    CityScene.super.ctor(self)
end
function CityScene:onEnter()
    CityScene.super.onEnter(self)
    self:GetSceneLayer():AddObserver(self)
    self:GetSceneLayer():InitWithCity(self:GetCity())
    self:PlayBackgroundMusic()
    self:GotoLogicPointInstant(5, 4)
    self:GetSceneLayer():ZoomTo(0.8)

    --  cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):pos(display.cx, display.cy + 300)
    -- :onButtonClicked(function()
    --     app:ReloadGame()
    -- end)
end
function CityScene:onExit()
    self:stopAllActions()
    --TODO:注意：这里因为主城现在播放两个音乐文件 所以这里要关掉鸟叫的sound音效
    audio.stopAllSounds()
    CityScene.super.onExit(self)
end
function CityScene:GetPreloadImages()
    return {
        {image = "animations/heihua_animation_0.pvr.ccz",list = "animations/heihua_animation_0.plist"},
        {image = "animations/heihua_animation_1.pvr.ccz",list = "animations/heihua_animation_1.plist"},
        {image = "animations/heihua_animation_2.pvr.ccz",list = "animations/heihua_animation_2.plist"},
        {image = "animations/building_animation.pvr.ccz",list = "animations/building_animation.plist"},
        {image = "city_png.pvr.ccz",list = "city_png.plist"},
        {image = "city_prv_0.pvr.ccz",list = "city_prv_0.plist"},
        {image = "city_prv_1.pvr.ccz",list = "city_prv_1.plist"},
        {image = "city_prv_2.pvr.ccz",list = "city_prv_2.plist"},
    }
end
function CityScene:GetCity()
    return self.city
end
function CityScene:CreateSceneLayer()
    local scene = CityLayer.new(self)
    local origin_point = scene:GetPositionIndex(0, 0)
    self.iso_map = IsoMapAnchorBottomLeft.new({
        tile_w = 80, tile_h = 56, map_width = 50, map_height = 50, base_x = origin_point.x, base_y = origin_point.y
    })
    return scene
end
function CityScene:GotoLogicPointInstant(x, y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function CityScene:GotoLogicPoint(x, y, speed)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    return self:GetSceneLayer():PromiseOfMove(point.x, point.y, speed)
end
function CityScene:PlayBackgroundMusic()
    app:GetAudioManager():PlayGameMusicOnSceneEnter('MyCityScene',false)
    -- self:performWithDelay(function()
    --     self:PlayBackgroundMusic()
    -- end, 113 + 30)
end
function CityScene:ChangeTerrain()
    -- self:GetSceneLayer():ChangeTerrain()
    -- self:PlayEffectIf()
end
function CityScene:EnterEditMode()
    self:GetSceneLayer():EnterEditMode()
end
function CityScene:LeaveEditMode()
    self:GetSceneLayer():LeaveEditMode()
end
function CityScene:IsEditMode()
    return self:GetSceneLayer():IsEditMode()
end
--- callback override
function CityScene:OnTilesChanged(tiles)
end
function CityScene:OnTouchBegan(pre_x, pre_y, x, y)
    if not DEBUG_LOCAL then return end
    local citynode = self:GetSceneLayer():GetCityNode()
    local point = citynode:convertToNodeSpace(cc.p(x, y))
    local tx, ty = self.iso_map:ConvertToLogicPosition(point.x, point.y)
    if not self.building then
        local building = self:GetSceneLayer():GetClickedObject(x, y)
        if building then
            local lx, ly = building:GetLogicPosition()
            building._shiftx = lx - tx
            building._shifty = ly - ty
            building:zorder(99999999)
            self.building = building
        end
    end
end
function CityScene:OnTouchEnd(pre_x, pre_y, x, y, speed)
    CityScene.super.OnTouchEnd(self, pre_x, pre_y, x, y, speed)
    if not DEBUG_LOCAL then return end
    local citynode = self:GetSceneLayer():GetCityNode()
    local point = citynode:convertToNodeSpace(cc.p(x, y))
    local tx, ty = self.iso_map:ConvertToLogicPosition(point.x, point.y)
    if self.building then
        local lx, ly = self.building:GetLogicPosition()
        self.building:zorder(self:GetSceneLayer():GetZOrderBy(self.building, lx, ly))
        if self.building._shiftx + tx == lx and
            self.building._shifty + ty == ly then
        end
    end
    self.building = nil
end
function CityScene:OnTouchCancelled(pre_x, pre_y, x, y)

end
function CityScene:OnTouchMove(pre_x, pre_y, x, y)
    if DEBUG_LOCAL then
        if self.building then
            local citynode = self:GetSceneLayer():GetCityNode()
            local point = citynode:convertToNodeSpace(cc.p(x, y))
            local lx, ly = self.iso_map:ConvertToLogicPosition(point.x, point.y)
            local bx, by = self.building:GetLogicPosition()
            local is_moved_one_more = lx ~= bx or ly ~= by
            if is_moved_one_more then
                self.building:SetLogicPosition(lx + self.building._shiftx, ly + self.building._shifty)
            end
            return
        end
    end
    CityScene.super.OnTouchMove(self, pre_x, pre_y, x, y)
end

function CityScene:CollectBuildings(building_sprite)
    local r = {}
    if building_sprite:GetEntity():GetType() == "wall" then
        for _,v in ipairs(self:GetSceneLayer():GetWalls()) do
            table.insert(r, v)
        end
        for _,v in ipairs(self:GetSceneLayer():GetTowers()) do
            table.insert(r, v)
        end
    elseif building_sprite:GetEntity():GetType() == "tower" then
        r = {unpack(self:GetSceneLayer():GetTowers())}
    else
        r = {building_sprite}
    end
    return r
end

function CityScene:onEnterTransitionFinish()
    CityScene.super.onEnterTransitionFinish(self)
    self:GetScreenLayer():performWithDelay(function()
        self:PlayEffectIf()
    end, math.random(3))
end


local EFFECT_TAG = 12321
function CityScene:PlayEffectIf()
    if math.floor(app.timer:GetServerTime()) % 2 == 1 then return end
    self:GetScreenLayer():removeAllChildren()
    local terrain = self:GetCity():GetUser():Terrain()
    if terrain == "iceField" then
        local emitter = cc.ParticleRain:createWithTotalParticles(100)
            :addTo(self:GetScreenLayer(), 1, EFFECT_TAG):pos(display.cx-80, display.height)
        emitter:setLife(7)
        emitter:setStartSize(10)
        emitter:setStartSizeVar(10)
        emitter:setRadialAccel(10)
        emitter:setRadialAccelVar(50)
        emitter:setRotationIsDir(true)
        emitter:setStartSpinVar(1000)
        emitter:setEndSpinVar(1000)
        emitter:setStartColor(cc.c4f(1,1,1,0.8))
        emitter:setStartColorVar(cc.c4f(0,0,0,0.2))
        emitter:setEndColor(cc.c4f(1,1,1,0))
        emitter:setEmissionRate(emitter:getTotalParticles() / emitter:getLife())
        emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("snow.png"))
        emitter:updateWithNoTime()
    elseif terrain == "grassLand" then
        local emitter = cc.ParticleRain:createWithTotalParticles(100)
            :addTo(self:GetScreenLayer(), 1, EFFECT_TAG):pos(display.cx + 80, display.height)
        emitter:setPosVar(cc.p(display.cx,0))
        emitter:setGravity(cc.p(-10,-10))
        emitter:setStartSize(30)
        emitter:setStartSizeVar(30)
        emitter:setEndSize(30)
        emitter:setEndSizeVar(30)
        emitter:setLife(0.5)
        emitter:setSpeed(1800)
        emitter:setSpeedVar(100)
        emitter:setAngle(-100)
        emitter:setAngleVar(0)
        emitter:setRadialAccel(100)
        emitter:setRadialAccelVar(0)
        emitter:setTangentialAccel(0)
        emitter:setTangentialAccelVar(0)
        emitter:setRotationIsDir(false)
        emitter:setStartSpin(10)
        emitter:setEndSpin(10)
        emitter:setStartColor(cc.c4f(1,1,1,0.9))
        emitter:setStartColorVar(cc.c4f(0,0,0,0.1))
        emitter:setEndColor(cc.c4f(1,1,1,0.5))
        emitter:setEmissionRate(emitter:getTotalParticles() / emitter:getLife())
        emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("rain.png"))
        emitter:updateWithNoTime()
    end
end

return CityScene










