--
-- Author: Kenny Dai
-- Date: 2015-01-14 20:37:32
--
local UILib = import(".UILib")
local  GameUIAllianceMoonGateEnter = UIKit:createUIClass("GameUIAllianceMoonGateEnter","GameUIAllianceShrineEnter")
local Localize = import("..utils.Localize")

function GameUIAllianceMoonGateEnter:GetUIHeight()
	return 282
end

function GameUIAllianceMoonGateEnter:GetUITitle()
	return _("月门")
end

function GameUIAllianceMoonGateEnter:GetBuildingImage()
    return UILib.alliance_building.moonGate
end

function GameUIAllianceMoonGateEnter:GetBuildingType()
	return 'moonGate'
end

function GameUIAllianceMoonGateEnter:GetBuildingDesc()
	return Localize.building_description.moonGate
end


function GameUIAllianceMoonGateEnter:GetBuildingInfo()
	local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local label_2 = {
        {_("开战的王城"),0x615b44},
        {_("未知"),0x403c2f},
    } 
    local label_3 = {
        {_("占领者"),0x615b44},
        {_("未知"),0x403c2f},
    } 
    local label_4 = 
    {
	    {_("状态"),0x615b44},
        {_("未开启"),0x403c2f},
    }
  	return {location,label_2,label_3,label_4}
end

function GameUIAllianceMoonGateEnter:GetNormalButton()
    local village_button = self:BuildOneButton("icon_king_city_70x58.png",_("王城")):onButtonClicked(function()
         UIKit:newGameUI('GameUIMoonGate',City,"",self:GetBuilding()):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    return {village_button}
end

return GameUIAllianceMoonGateEnter
