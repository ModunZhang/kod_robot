local SpriteUINode = import(".SpriteUINode")
local BuildingLevelUpUINode = class("BuildingLevelUpUINode", SpriteUINode)

function BuildingLevelUpUINode:OnCheckUpgradingCondition(sprite)
    self:OnBuildingUpgradeFinished(sprite:GetEntity())
end
function BuildingLevelUpUINode:OnBuildingUpgradingBegin(building, time)
    self:OnBuildingUpgradeFinished(building)
end
function BuildingLevelUpUINode:OnBuildingUpgradeFinished(building)
    local city = building:BelongCity()
    building = building:GetType() == "tower" and city:GetTower() or building
    self:setVisible(building:GetLevel() > 0)
    self:SetCanUpgrade(building:CanUpgrade())
    self:SetLevel(building:GetLevel())
end
function BuildingLevelUpUINode:OnPositionChanged(x, y, bottom_x, bottom_y)
    self:setPosition(self:GetPositionFromWorld(bottom_x, bottom_y))
end
function BuildingLevelUpUINode:SetCanUpgrade(b)
    self.can_level_up:setVisible(b)
    self.can_not_level_up:setVisible(not b)
end
function BuildingLevelUpUINode:SetLevel(level)
    self.text_field:setString(level)
end
function BuildingLevelUpUINode:ctor()
    BuildingLevelUpUINode.super.ctor(self)
    self:zorder(0)
    self:setCascadeOpacityEnabled(true)
end
function BuildingLevelUpUINode:InitWidget()
    self.level_bg = display.newNode():addTo(self)
    self.level_bg:setCascadeOpacityEnabled(true)
    self.can_level_up = cc.ui.UIImage.new("can_level_up.png"):addTo(self.level_bg):hide()
    self.can_not_level_up = cc.ui.UIImage.new("can_not_level_up.png"):addTo(self.level_bg):pos(0,-10):hide()
    self.text_field = cc.ui.UILabel.new({
        size = 16,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xfff1cc)
    }):addTo(self):align(display.CENTER, 10, 18)
    self.text_field:setSkewY(-30)
end



return BuildingLevelUpUINode



