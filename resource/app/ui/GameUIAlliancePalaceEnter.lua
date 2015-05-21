--
-- Author: Danny He
-- Date: 2014-12-29 15:56:44
--
local UILib = import("..ui.UILib")
local GameUIAlliancePalaceEnter = UIKit:createUIClass("GameUIAlliancePalaceEnter","GameUIAllianceShrineEnter")
local Localize = import("..utils.Localize")

function GameUIAlliancePalaceEnter:GetUIHeight()
	return 261
end

function GameUIAlliancePalaceEnter:GetUITitle()
	return _("联盟宫殿")
end

function GameUIAlliancePalaceEnter:GetBuildingImage()
	return UILib.alliance_building.palace
end

function GameUIAlliancePalaceEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 110/math.max(size.width,size.height),97,self:GetUIHeight() - 90 
end

function GameUIAlliancePalaceEnter:GetBuildingType()
	return 'palace'
end

function GameUIAlliancePalaceEnter:GetBuildingDesc()
	return Localize.building_description.palace
end


function GameUIAlliancePalaceEnter:GetBuildingInfo()
	local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local member_count,cities = _("未知"),_("未知")
    if self:IsMyAlliance() then
    	local count,online,maxCount = self:GetMyAlliance():GetMembersCountInfo()
    	member_count = count.."/"..maxCount
    	cities = 10
    end
    local label_2 = {
        {_("成员"),0x615b44},
        {member_count,0x403c2f},
    } 
    local label_3 = 
    {
	    {_("占领城市"),0x615b44},
	    {cities,0x403c2f},
    }
  	return {location,label_2}
end

function GameUIAlliancePalaceEnter:GetNormalButton()
	local info_button = self:BuildOneButton("icon_info_56x56.png",_("信息")):onButtonClicked(function()
		UIKit:newGameUI('GameUIAlliancePalace',City,"info",self:GetBuilding()):AddToCurrentScene(true)
		self:LeftButtonClicked()
	end)
	local tax_button = self:BuildOneButton("icon_award_52x54.png",_("奖励")):onButtonClicked(function()
		 UIKit:newGameUI('GameUIAlliancePalace',City,"impose",self:GetBuilding()):AddToCurrentScene(true)
		self:LeftButtonClicked()
	end)
	local upgrade_button = self:BuildOneButton("icon_upgrade_1.png",_("升级")):onButtonClicked(function()
		UIKit:newGameUI('GameUIAlliancePalace',City,"upgrade",self:GetBuilding()):AddToCurrentScene(true)
		self:LeftButtonClicked()
	end)
	return {info_button,tax_button,upgrade_button}
end
return GameUIAlliancePalaceEnter
