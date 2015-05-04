--
-- Author: Kenny Dai
-- Date: 2015-01-14 20:37:32
--
local UILib = import(".UILib")
local  GameUIAllianceMoonGateEnter = UIKit:createUIClass("GameUIAllianceMoonGateEnter","GameUIAllianceShrineEnter")


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
	return "本地化缺失"
end


function GameUIAllianceMoonGateEnter:GetBuildingInfo()
	local location = {
        {_("坐标"),0x797154},
        {self:GetLocation(),0x403c2f},
    }
    local label_2 = {
        {_("开战的王城"),0x797154},
        {_("未知"),0x403c2f},
    } 
    local label_3 = {
        {_("占领者"),0x797154},
        {_("未知"),0x403c2f},
    } 
    local label_4 = 
    {
	    {_("状态"),0x797154},
        {_("未开启"),0x403c2f},
    }
  	return {location,label_2,label_3,label_4}
end

function GameUIAllianceMoonGateEnter:GetEnterButtons()
	if self:IsMyAlliance() then
		local village_button = self:BuildOneButton("icon_king_city_70x58.png",_("王城")):onButtonClicked(function()
			 UIKit:newGameUI('GameUIMoonGate',City,"",self:GetBuilding()):AddToCurrentScene(true)
			self:LeftButtonClicked()
		end)
        local current_scene = display.getRunningScene()
        if current_scene.__cname == "AllianceScene" and self:AllianceBuildingMoveIsOpen() then
            local move_building_button = self:BuildOneButton("icon_move_alliance_building.png",_("移动")):onButtonClicked(function()
            if self:GetMyAlliance():Status() == 'fight' then
                    UIKit:showMessageDialog(nil, _("战争期不能移动"),function()end)
                    return
            end
            local alliacne =  self:GetMyAlliance()
            local isEqualOrGreater = alliacne:GetSelf():CanEditAllianceObject()
            if isEqualOrGreater then
                if self:GetMyAlliance():Honour() < self:GetMoveNeedHonour() then 
                    UIKit:showMessageDialog(nil, _("联盟荣耀值不足"),function()end)
                    return 
                end
                current_scene:LoadEditModeWithAllianceObj({
                    obj = self:GetMapObject(),
                    honour = self:GetMoveNeedHonour(),
                    name = self:GetUITitle()
                })
                self:LeftButtonClicked()
            else
                UIKit:showMessageDialog(nil, _("您没有此操作权限"),function()end)
            end
            end)
            return {move_building_button,village_button}
        end
    	return {village_button}
    else
    	return {}
    end
end


return GameUIAllianceMoonGateEnter
