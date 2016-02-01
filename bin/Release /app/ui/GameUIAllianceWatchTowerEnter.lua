--
-- Author: Kenny Dai
-- Date: 2015-10-19 11:23:09
--
local UILib = import(".UILib")
local  GameUIAllianceWatchTowerEnter = UIKit:createUIClass("GameUIAllianceWatchTowerEnter","GameUIAllianceShrineEnter")
local Localize = import("..utils.Localize")

function GameUIAllianceWatchTowerEnter:GetUIHeight()
	return 261
end

function GameUIAllianceWatchTowerEnter:GetUITitle()
	return _("巨石阵")
end

function GameUIAllianceWatchTowerEnter:GetBuildingImage()
    return self.isMyAlliance and UILib.alliance_building.watchTower or UILib.other_alliance_building.watchTower
end

function GameUIAllianceWatchTowerEnter:GetBuildingType()
	return 'watchTower'
end

function GameUIAllianceWatchTowerEnter:GetBuildingDesc()
	return Localize.building_description.watchTower
end

function GameUIAllianceWatchTowerEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 0.6,97,self:GetUIHeight() - 90 
end

function GameUIAllianceWatchTowerEnter:GetBuildingInfo()
	local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local beStrikeCount = _("未知")
    if self:IsMyAlliance() then
    	beStrikeCount = 11
    end
    local label_2 = {
        {_("来袭事件"),0x615b44},
        {beStrikeCount,0x403c2f},
    } 
  	return {location,label_2}
end

function GameUIAllianceWatchTowerEnter:GetNormalButton()
    local march_button = self:BuildOneButton("icon_march_50x54.png",_("行军")):onButtonClicked(function()
        UIKit:newGameUI('GameUIAllianceWatchTower',City,"march",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)

    local be_striked_button = self:BuildOneButton("icon_be_stirked_42x54.png",_("来袭")):onButtonClicked(function()
         UIKit:newGameUI('GameUIAllianceWatchTower',City,"beStriked",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    local upgrade_button = self:BuildOneButton("icon_upgrade_1.png",_("升级")):onButtonClicked(function()
         UIKit:newGameUI('GameUIAllianceWatchTower',City,"upgrade",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    return {march_button,be_striked_button,upgrade_button}
end

return GameUIAllianceWatchTowerEnter
