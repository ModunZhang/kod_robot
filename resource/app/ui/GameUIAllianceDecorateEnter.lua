--
-- Author: Danny He
-- Date: 2014-12-29 17:09:39
--
local GameUIAllianceDecorateEnter = UIKit:createUIClass("GameUIAllianceDecorateEnter","GameUIAllianceEnterBase")
local buildingName = GameDatas.AllianceInitData.buildingName
local UILib = import(".UILib")
local DECORATOR_IMAGE = UILib.decorator_image
local Localize = import("..utils.Localize")

function GameUIAllianceDecorateEnter:GetUIHeight()
	return 242
end

function GameUIAllianceDecorateEnter:GetHonourLabelText()
    return GameUtils:formatNumber(self:GetMoveNeedHonour())
end
function GameUIAllianceDecorateEnter:GetMoveNeedHonour()
    if buildingName[self:GetBuilding():GetName()] then
        return buildingName[self:GetBuilding():GetName()].moveNeedHonour 
    end
    return 0
end

function GameUIAllianceDecorateEnter:FixedUI()
	self:GetLevelBg():show()
	self.process_bar_bg:hide()
end


function GameUIAllianceDecorateEnter:GetUITitle()
    local name = self:GetBuilding():GetName()
    local __,__,key = string.find(name,"(.+)_%d")
    return Localize.alliance_decorate_name[key]
end

function GameUIAllianceDecorateEnter:GetBuildImageSprite()
    return nil
end

function GameUIAllianceDecorateEnter:GetBuildingImage()
    return DECORATOR_IMAGE[self:GetTerrain()][self:GetBuilding():GetName()]
end

function GameUIAllianceDecorateEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 110/math.max(size.width,size.height),97,self:GetUIHeight() - 90 
end

function GameUIAllianceDecorateEnter:GetBuildingType()
	return 'decorate'
end

function GameUIAllianceDecorateEnter:GetBuildingDesc()
	return _("可拆除,需要职位在将军以上的玩家,并且花费一定的荣誉值")
end

function GameUIAllianceDecorateEnter:GetLocation()
    local building = self:GetBuilding()
    local x,y = building:GetMidLogicPosition()
    return string.format("%d,%d",x,y)
end

function GameUIAllianceDecorateEnter:GetBuildingInfo()
	local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local w,h = self:GetBuilding():GetSize()
    local occupy_str = string.format("%d x %d",w,h)
    local occupy = {
        {_("占地"),0x615b44},
        {occupy_str,0x403c2f},
    }
  	return {location,occupy}
end

function GameUIAllianceDecorateEnter:GetEnterButtons()
    
    local current_scene = display.getRunningScene()
    if current_scene.__cname == "AllianceScene" and current_scene.LoadEditModeWithAllianceObj then
    	local chai_button = self:BuildOneButton("icon_move_player_city.png",_("移动")):onButtonClicked(function()
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
                    obj = self:GetBuilding(),
                    honour = self:GetHonourLabelText(),
                    name = self:GetUITitle()
                })
            else
            	UIKit:showMessageDialog(nil, _("您没有此操作权限"),function()end)
            end
    		self:LeftButtonClicked()
    	end)
     	return {chai_button}
    else
        return {}
    end
end

return GameUIAllianceDecorateEnter
