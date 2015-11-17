local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local Orient = import("..entity.Orient")
local Observer = import("..entity.Observer")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local Sprite = class("Sprite", function(...)
    return Observer.extend(display.newNode(), ...)
end)

local fmod = math.fmod
local SPRITE = 0
function Sprite:GetWorldPosition()
    return self:getParent():convertToWorldSpace(cc.p(self:GetCenterPosition()))
end
function Sprite:GetCenterPosition()
    return self:getPosition()
end
-- 委托
function Sprite:IsContainPointWithFullCheck(x, y, world_x, world_y)
    return { logic_clicked = self:IsContainPoint(x, y), sprite_clicked = self:IsContainWorldPoint(world_x, world_y)}
end
function Sprite:IsContainPoint(x, y)
    return self:GetEntity():IsContainPoint(x, y)
end
function Sprite:IsContainWorldPoint(world_x, world_y)
    return cc.rectContainsPoint(self:GetSprite():getBoundingBox(), self:convertToNodeSpace(cc.p(world_x, world_y)))
end
function Sprite:SetLogicPosition(logic_x, logic_y)
    self:GetEntity():SetLogicPosition(logic_x, logic_y)
end
function Sprite:GetLogicPosition()
    return self:GetEntity():GetLogicPosition()
end
function Sprite:GetMidLogicPosition()
    return self:GetEntity():GetMidLogicPosition()
end
function Sprite:GetSize()
    return self:GetEntity():GetSize()
end
-- function Sprite:GetOrient()
--     return self:GetEntity():GetOrient()
-- end
-- function Sprite:SetOrient(orient)
--     self:GetEntity():SetOrient(orient)
-- end
-----position
function Sprite:SetPositionWithZOrder(x, y)
    self:setPosition(x, y)
end
function Sprite:setPosition(x, y)
    assert(getmetatable(self).setPosition)
    getmetatable(self).setPosition(self, x, y)
    self:setLocalZOrder(self:GetLogicZorder())
end
function Sprite:GetLogicZorder()
    local x, y = self:GetMidLogicPosition()
    return self:GetMapLayer():GetZOrderBy(self, x, y)
end
---- 功能
function Sprite:ctor(city_layer, entity, x, y)
    if city_layer then
        self.city_layer = city_layer
        self.logic_map = city_layer:GetLogicMap()
    end
    self.entity = entity
    self:RefreshSprite()
    self:SetPositionWithZOrder(x, y)
    self:setCascadeOpacityEnabled(true)
    self:setCascadeColorEnabled(true)
    -- self:CreateBase()
end
function Sprite:ReloadSpriteCauseTerrainChanged()
-- print("你应该在子类实现切换地形的功能")
end
-- function Sprite:GetShadow()
--     return self.shadow
-- end
-- function Sprite:CreateShadow(shadow)
--     local x, y = self:GetCenterPosition()
--     self.shadow = self.city_layer:CreateShadow(shadow, x, y, self:getLocalZOrder())
-- end
-- function Sprite:DestoryShadow()
--     self.city_layer:DestoryShadow(self.shadow)
-- end
-- function Sprite:GetShadowConfig()
--     return nil
-- end
-- function Sprite:RefreshShadow()
--     local shadow = self:GetShadowConfig()
--     if shadow and self:GetEntity():IsUnlocked() then
--         self:DestoryShadow()
--         self:CreateShadow(shadow)
--     end
-- end
function Sprite:RefreshSprite()
    if self.sprite then
        self.sprite:removeFromParent()
    end
    self.sprite = self:CreateSprite():addTo(self, SPRITE):pos(self:GetSpriteOffset())
end
function Sprite:CreateSprite()
    local sprite_file, scale = self:GetSpriteFile()
    return display.newSprite(sprite_file, nil, nil, {class=cc.FilteredSpriteWithOne})
        :scale(scale == nil and 1 or scale)
        :flipX(self:GetFlipX())
end
function Sprite:CreateBase()
    if self:GetEntity() and self:GetEntity().GetSize then
        self:GenerateBaseTiles(self:GetSize())
    end
end
function Sprite:GetMapLayer()
    return self.city_layer
end
function Sprite:GetSpriteFile()
    assert(false)
end
function Sprite:GetSpriteOffset()
    return 0, 0
end
function Sprite:GetSpriteTopPosition()
    local offset_x, offset_y = self:GetSpriteOffset()
    return offset_x, offset_y + (self:GetSprite():getContentSize().height/2) * self:GetSprite():getScale()
end
function Sprite:GetSpriteButtomPosition()
    local offset_x, offset_y = self:GetSpriteOffset()
    return offset_x, offset_y - (self:GetSprite():getContentSize().height/2) * self:GetSprite():getScale()
end
function Sprite:GetFlipX()
    return false
end
function Sprite:GetSprite()
    return self.sprite
end
function Sprite:GetEntity()
    return self.entity
end
function Sprite:GetLogicMap()
    return self.logic_map
end

--- effects
local FLASH_TIME = 0.3
function Sprite:PromiseOfFlash(...)
    local sprites = {...}
    local director = cc.Director:getInstance()
    for _,v in ipairs(sprites) do
        v:Flash(FLASH_TIME)
    end
    return cocos_promise.Delay(FLASH_TIME)
end
function Sprite:Flash(time)
    self:ResetFlashStatus()
    self:BeginFlash(time)
end
function Sprite:ResetFlashStatus()
    self:GetSprite():removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
    self:GetSprite():unscheduleUpdate()
    self:GetSprite():clearFilter()
end
function Sprite:BeginFlash(lastTime)
    self.time = 0
    local ratio = fmod(self.time, lastTime)  / lastTime
    self:GetSprite():setFilter(filter.newFilter("CUSTOM", json.encode({
        frag = "shaders/flash.fs",
        shaderName = "flash",
        ratio = ratio,
    })))
    self:GetSprite():addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        self.time = self.time + dt
        if self.time > lastTime then
            self:ResetFlashStatus()
        else
            self:GetSprite():getFilter():getGLProgramState():setUniformFloat("ratio", fmod(self.time, lastTime) / lastTime)
        end
    end)
    self:GetSprite():scheduleUpdate()
end

----------base
function Sprite:GenerateBaseTiles(w, h)
    self:newBatchNode(w, h):addTo(self, -1)
end
function Sprite:newBatchNode(w, h)
    local start_x, end_x, start_y, end_y = self:GetLocalRegion(w, h)
    local base_node = display.newBatchNode("tmxmaps/tile.png", 10)
    local map = self:GetLogicMap()
    for ix = start_x, end_x do
        for iy = start_y, end_y do
            local sprite = display.newSprite(base_node:getTexture(), cc.rect(0, 0, 51, 31))
            sprite:setPosition(cc.p(map:ConvertToLocalPosition(ix, iy)))
            base_node:addChild(sprite)
        end
    end
    return base_node
end
function Sprite:GetLocalRegion(w, h)
    local start_x, end_x, start_y, end_y
    local is_orient_x = w > 0
    local is_orient_neg_x = not is_orient_x
    local is_orient_y = h > 0
    local is_orient_neg_y = not is_orient_y
    if is_orient_x then
        start_x, end_x = 0, w - 1
    elseif is_orient_neg_x then
        start_x, end_x = w + 1, 0
    end
    if is_orient_y then
        start_y, end_y = 0, h - 1
    elseif is_orient_neg_y then
        start_y, end_y = h + 1, 0
    end
    return start_x, end_x, start_y, end_y
end

return Sprite





















