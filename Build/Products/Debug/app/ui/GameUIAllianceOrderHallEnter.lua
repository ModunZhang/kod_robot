--
-- Author: Danny He
-- Date: 2014-12-29 16:18:19
--
local UILib = import(".UILib")
local  GameUIAllianceOrderHallEnter = UIKit:createUIClass("GameUIAllianceOrderHallEnter","GameUIAllianceShrineEnter")
local Localize = import("..utils.Localize")

function GameUIAllianceOrderHallEnter:GetUIHeight()
	return 261
end

function GameUIAllianceOrderHallEnter:GetUITitle()
	return _("秩序大厅")
end

function GameUIAllianceOrderHallEnter:GetBuildingImage()
	return UILib.alliance_building.orderHall
end

function GameUIAllianceOrderHallEnter:GetBuildingType()
	return 'orderHall'
end

function GameUIAllianceOrderHallEnter:GetBuildingDesc()
	return Localize.building_description.orderHall
end

function GameUIAllianceOrderHallEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 0.6,97,self:GetUIHeight() - 90 
end

function GameUIAllianceOrderHallEnter:GetBuildingInfo()
	local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local village_count,current_collect_village = _("未知"),_("未知")
    if self:IsMyAlliance() then
    	village_count = 50
    	current_collect_village = _("暂无")
    end
    local label_2 = {
        {_("当前村落数量"),0x615b44},
        {village_count,0x403c2f},
    } 
    local label_3 = 
    {
	    {_("当前采集村落"),0x615b44},
        {current_collect_village,0x403c2f},
    }
  	return {location,label_2,label_3}
end

function GameUIAllianceOrderHallEnter:GetNormalButton()
    local info_button = self:BuildOneButton("icon_proficiency_78x56.png",_("熟练度")):onButtonClicked(function()
        UIKit:newGameUI('GameUIOrderHall',City,"proficiency",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)

    local village_button = self:BuildOneButton("village_manage_66x72.png",_("村落管理")):onButtonClicked(function()
         UIKit:newGameUI('GameUIOrderHall',City,"village",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    local upgrade_button = self:BuildOneButton("icon_upgrade_1.png",_("升级")):onButtonClicked(function()
         UIKit:newGameUI('GameUIOrderHall',City,"upgrade",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    return {info_button,village_button,upgrade_button}
end

return GameUIAllianceOrderHallEnter
