local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local WithInfoSprite = import(".WithInfoSprite")
local AllianceBuildingSprite = class("AllianceBuildingSprite", WithInfoSprite)

local building_map = {
    palace = {UILib.alliance_building.palace, 1},
    shrine = {UILib.alliance_building.shrine, 1.2},
    shop = {UILib.alliance_building.shop, 1},
    orderHall = {UILib.alliance_building.orderHall, 1.1},
    moonGate = {UILib.alliance_building.moonGate, 1.2},
}
local other_building_map = {
    palace = {UILib.other_alliance_building.palace, 1},
    shrine = {UILib.other_alliance_building.shrine, 1.2},
    shop = {UILib.other_alliance_building.shop, 1},
    orderHall = {UILib.other_alliance_building.orderHall, 1.1},
    moonGate = {UILib.other_alliance_building.moonGate, 1.2},
}
function AllianceBuildingSprite:ctor(...)
    AllianceBuildingSprite.super.ctor(self, ...)   
    -- self:CheckEventIf(true)
end
function AllianceBuildingSprite:CheckEventIf(yesOrno)
    if not self.alliance:IsDefault() and self:GetBuildingInfo().name == "shrine" then
    end
end
function AllianceBuildingSprite:onExit()
    -- self:CheckEventIf(false)
    AllianceBuildingSprite.super.onExit(self)
end
function AllianceBuildingSprite:GetSpriteFile()
    if self.is_my_alliance then
        return unpack(building_map[self:GetBuildingInfo().name])
    else
        return unpack(other_building_map[self:GetBuildingInfo().name])
    end
end
function AllianceBuildingSprite:GetSpriteOffset()
    return 0, -60
end
function AllianceBuildingSprite:RefreshSprite()
    AllianceBuildingSprite.super.RefreshSprite(self)
    self:GetSprite():align(display.BOTTOM_CENTER)
end
function AllianceBuildingSprite:GetInfo()
    local info = self:GetBuildingInfo()
    return info.level, string.format("[%s]%s", self.alliance.basicInfo.tag, Localize.alliance_buildings[info.name])
end



local ANI_TAG = 110
function AllianceBuildingSprite:CheckEvent()
    if self:GetBuildingInfo().name == "shrine" then
        --     local armature = self:getChildByTag(ANI_TAG)
        --     if not armature then
        --         self:PlayAni()
        --     end
    end
end
function AllianceBuildingSprite:PlayAni()
    if self:GetBuildingInfo().name == "shrine" then
        local armature = ccs.Armature:create("shengdi")
            :addTo(self, 1, ANI_TAG):pos(self:GetSpriteOffset())
        local bone = armature:getBone("Layer1")
        bone:addDisplay(display.newNode(), 0)
        bone:changeDisplayWithIndex(0, true)
        armature:setAnchorPoint(cc.p(0.5, 0.1))
        armature:getAnimation():playWithIndex(0, -1, -1)
    end
end
function AllianceBuildingSprite:StopAni()
    self:removeChildByTag(ANI_TAG)
end
function AllianceBuildingSprite:GetBuildingInfo()
    return self.alliance:FindAllianceBuildingInfoByObjects(self:GetEntity())
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







