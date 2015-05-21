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
    self:LoadAnimation()
    CityScene.super.onEnter(self)
    self:GetSceneLayer():AddObserver(self)
    self:GetSceneLayer():InitWithCity(self:GetCity())
    self:PlayBackgroundMusic()
    self:GotoLogicPointInstant(6, 4)
    self:GetSceneLayer():ZoomTo(1)

    --  cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):pos(display.cx, display.cy + 300)
    -- :onButtonClicked(function()
    --     app:ReloadGame()
    -- end)
end
function CityScene:onExit()
    UILib.unLoadBuildingAnimation()
    self:stopAllActions()
    --TODO:注意：这里因为主城现在播放两个音乐文件 所以这里要关掉鸟叫的sound音效
    audio.stopAllSounds()
    CityScene.super.onExit(self)
end
-- init ui
function CityScene:LoadAnimation()
    UILib.loadSolidersAnimation()
    UILib.loadBuildingAnimation()
    UILib.loadDragonAnimation()
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
    app:GetAudioManager():PlayGameMusic()
    -- self:performWithDelay(function()
    --     self:PlayBackgroundMusic()
    -- end, 113 + 30)
end
function CityScene:ChangeTerrain()
    self:GetSceneLayer():ChangeTerrain()
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
end

return CityScene









