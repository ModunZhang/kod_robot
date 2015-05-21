local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local Sprite = import(".Sprite")
local AllianceBuildingSprite = class("AllianceBuildingSprite", Sprite)

local building_map = {
    palace = {UILib.alliance_building.palace, 1},
    shrine = {UILib.alliance_building.shrine, 1},
    shop = {UILib.alliance_building.shop, 1},
    orderHall = {UILib.alliance_building.orderHall, 1},
    moonGate = {UILib.alliance_building.moonGate, 1},
}
local other_building_map = {
    palace = {UILib.other_alliance_building.palace, 1},
    shrine = {UILib.other_alliance_building.shrine, 1},
    shop = {UILib.other_alliance_building.shop, 1},
    orderHall = {UILib.other_alliance_building.orderHall, 1},
    moonGate = {UILib.other_alliance_building.moonGate, 1},
}
function AllianceBuildingSprite:ctor(city_layer, entity, is_my_alliance)
    self:setNodeEventEnabled(true)
    self.is_my_alliance = is_my_alliance
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    AllianceBuildingSprite.super.ctor(self, city_layer, entity, x, y)   
    self:CheckEventIf(true)
    -- self:CreateBase()
end

function AllianceBuildingSprite:CheckEventIf(yesOrno)
    local entity = self:GetEntity()
    if not entity:GetAlliance():IsDefault() and 
    entity:GetAllianceBuildingInfo().name == "shrine" then
        local alliance_shirine = entity:GetAlliance():GetAllianceShrine()
        if not alliance_shirine then return end
        if yesOrno then
            self:CheckEvent()
            alliance_shirine:AddListenOnType(self,alliance_shirine.LISTEN_TYPE.OnShrineEventsChanged)
            alliance_shirine:AddListenOnType(self,alliance_shirine.LISTEN_TYPE.OnShrineEventsRefresh)
        else
            alliance_shirine:RemoveListenerOnType(self,alliance_shirine.LISTEN_TYPE.OnShrineEventsChanged)
            alliance_shirine:RemoveListenerOnType(self,alliance_shirine.LISTEN_TYPE.OnShrineEventsRefresh) 
        end
    end
end

function AllianceBuildingSprite:OnShrineEventsChanged()
    self:CheckEvent()
end
function AllianceBuildingSprite:OnShrineEventsRefresh()
    self:CheckEvent()
end
function AllianceBuildingSprite:onExit()
    self:CheckEventIf(false)
    if self.info then
        self.info:removeFromParent()
    end
end
function AllianceBuildingSprite:GetSpriteFile()
    if self.is_my_alliance then
        return unpack(building_map[self:GetEntity():GetAllianceBuildingInfo().name])
    else
        return unpack(other_building_map[self:GetEntity():GetAllianceBuildingInfo().name])
    end
end
function AllianceBuildingSprite:GetSpriteOffset()
    return self:GetLogicMap():ConvertToLocalPosition(0, 0)
end
function AllianceBuildingSprite:RefreshSprite()
    AllianceBuildingSprite.super.RefreshSprite(self)
    if self.info then
        self.info:removeFromParent()
        self.info = nil
    end
    local map_layer = self:GetMapLayer()
    local x,y = map_layer:GetLogicMap():ConvertToMapPosition(self:GetEntity():GetLogicPosition())
    self.info = display.newNode():addTo(map_layer:GetInfoNode()):pos(x, y - 50):scale(0.8):zorder(x * y)


    local banners = self.is_my_alliance and UILib.my_city_banner or UILib.enemy_city_banner
    self.banner = display.newSprite(banners[0]):addTo(self.info):align(display.CENTER_TOP)
    self.level = UIKit:ttfLabel({
        size = 22,
        color = 0xffedae,
    }):addTo(self.banner):align(display.CENTER, 30, 30)
    self.name = UIKit:ttfLabel({
        size = 20,
        color = 0xffedae,
    }):addTo(self.banner):align(display.LEFT_CENTER, 60, 32)
    self:RefreshInfo()
end
function AllianceBuildingSprite:RefreshInfo()
    local entity = self:GetEntity()
    local info = entity:GetAllianceBuildingInfo()
    self.level:setString(info.level)
    self.name:setString(string.format("[%s]%s", entity:GetAlliance():Tag(), Localize.alliance_buildings[info.name]))
end
local ANI_TAG = 110
function AllianceBuildingSprite:CheckEvent()
    if self:GetEntity():GetAllianceBuildingInfo().name == "shrine" then
        if self:GetEntity():GetAllianceMap():GetAlliance():GetAllianceShrine():HaveEvent() then
            local armature = self:getChildByTag(ANI_TAG)
            if not armature then
                self:PlayAni()
            end
        else
            self:StopAni()
        end
    end
end
function AllianceBuildingSprite:PlayAni()
    if self:GetEntity():GetAllianceBuildingInfo().name == "shrine" then
        local armature = ccs.Armature:create("shengdi")
            :addTo(self, 1, ANI_TAG):pos(self:GetSpriteOffset())
        local bone = armature:getBone("Layer1")
        bone:addDisplay(display.newNode(), 0)
        bone:changeDisplayWithIndex(0, true)
        armature:setAnchorPoint(cc.p(0.5, 0.33))
        armature:getAnimation():playWithIndex(0, -1, -1)
    end
end
function AllianceBuildingSprite:StopAni()
    self:removeChildByTag(ANI_TAG)
end




---
function AllianceBuildingSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
function AllianceBuildingSprite:newBatchNode(w, h)
    local start_x, end_x, start_y, end_y = self:GetLocalRegion(w, h)
    local base_node = display.newBatchNode("grass_80x80_.png", 10)
    local map = self:GetLogicMap()
    for ix = start_x, end_x do
        for iy = start_y, end_y do
            display.newSprite(base_node:getTexture()):addTo(base_node):pos(map:ConvertToLocalPosition(ix, iy)):scale(2)
        end
    end
    return base_node
end
return AllianceBuildingSprite







