--
-- Author: Danny He
-- Date: 2014-12-29 11:32:56
--
local UILib = import(".UILib")
local GameUIAllianceShrineEnter = UIKit:createUIClass("GameUIAllianceShrineEnter","GameUIAllianceEnterBase")
local buildingName = GameDatas.AllianceInitData.buildingName

function GameUIAllianceShrineEnter:ctor(building,isMyAlliance,alliance,enemy_alliance)
	GameUIAllianceShrineEnter.super.ctor(self,building,isMyAlliance,alliance,enemy_alliance)
	self.building = building:GetAllianceBuildingInfo()
end

function GameUIAllianceShrineEnter:GetLocation()
	local mapObject
	if self:IsMyAlliance() then
		mapObject = self:GetMyAlliance():GetAllianceMap():FindMapObjectById(self:GetBuilding().id)
	else
		mapObject = self:GetEnemyAlliance():GetAllianceMap():FindMapObjectById(self:GetBuilding().id)
	end
	return mapObject.location.x .. "," .. mapObject.location.y
end

function GameUIAllianceShrineEnter:GetLogicPosition()
	local mapObject
	if self:IsMyAlliance() then
		mapObject = self:GetMyAlliance():GetAllianceMap():FindMapObjectById(self:GetBuilding().id)
	else
		mapObject = self:GetEnemyAlliance():GetAllianceMap():FindMapObjectById(self:GetBuilding().id)
	end
	return {x = mapObject.location.x,y = mapObject.location.y}
end

function GameUIAllianceShrineEnter:GetMapObject()
	local mapObject
	if self:IsMyAlliance() then
		mapObject = self:GetMyAlliance():GetAllianceMap():FindMapObjectById(self:GetBuilding().id)
	else
		mapObject = self:GetEnemyAlliance():GetAllianceMap():FindMapObjectById(self:GetBuilding().id)
	end
	return mapObject
end

function GameUIAllianceShrineEnter:GetMoveNeedHonour()
	local mapObject = self:GetMapObject()
	if buildingName[mapObject.name] then
		return buildingName[mapObject.name].moveNeedHonour
	end
	return 0
end

function GameUIAllianceShrineEnter:GetUIHeight()
	return 261
end

function GameUIAllianceShrineEnter:GetUITitle()
	return _("圣地")
end

function GameUIAllianceShrineEnter:GetBuildingImage()
	return UILib.alliance_building.shrine
end

function GameUIAllianceShrineEnter:GetBuildImageSprite()
    return nil
end

function GameUIAllianceShrineEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 110/math.max(size.width,size.height),97,self:GetUIHeight() - 90 
end

function GameUIAllianceShrineEnter:GetBuildingType()
	return 'shrine'
end

function GameUIAllianceShrineEnter:GetBuildingDesc()
	return "本地化缺失"
end

function GameUIAllianceShrineEnter:FixedUI()
	self:GetHonourIcon():hide()
	self:GetHonourLabel():hide()
	self.process_bar_bg:hide()
end

function GameUIAllianceShrineEnter:GetBuildingInfo()
	local events = _("未知")
    local running_event = _("未知")
    local people_count =   _("未知")
    if self:IsMyAlliance() then
	 	events = self:GetMyAlliance():GetAllianceShrine():GetShrineEvents()
		running_event = #events > 0 and events[1]:StageName() or _("暂无")
		people_count =   #events > 0 and  #events[1]:PlayerTroops() .. "/" .. events[1]:Stage():SuggestPlayer() or _("暂无")
	end
	local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local doing_event = {
        {_("正在进行的事件"),0x615b44},
        {running_event,0x403c2f},
    } 
    local join_people = 
    {
	    {_("参与部队"),0x615b44},
	    {people_count,0x403c2f},
    }
  	return {location,doing_event,join_people}
end

function GameUIAllianceShrineEnter:GetEnterButtons()
	if self:IsMyAlliance() then
	 	return self:GetReallyButtons()
	else
		return {}
	end

end

function GameUIAllianceShrineEnter:GetReallyButtons()
	local buttons = self:GetNormalButton()
	local current_scene = display.getRunningScene()
	if self:AllianceBuildingMoveIsOpen() and  current_scene.__cname == "AllianceScene" then
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
	        else
	        	UIKit:showMessageDialog(nil, _("您没有此操作权限"),function()end)
	        end
            self:LeftButtonClicked()
        end)
		table.insert(buttons,move_building_button)
	end
	return buttons
end

function GameUIAllianceShrineEnter:GetNormalButton()
	local fight_event_button = self:BuildOneButton("icon_war_48x54.png",_("战争事件")):onButtonClicked(function()
			UIKit:newGameUI('GameUIAllianceShrine',City,"fight_event",self:GetBuilding()):AddToCurrentScene(true)
			self:LeftButtonClicked()
	end)
	local alliance_shirine_event_button = self:BuildOneButton("icon_alliance_crisis.png",_("联盟危机")):onButtonClicked(function()
		 UIKit:newGameUI('GameUIAllianceShrine',City,"stage",self:GetBuilding()):AddToCurrentScene(true)
		self:LeftButtonClicked()
	end)
	local upgrade_button = self:BuildOneButton("icon_upgrade_1.png",_("升级")):onButtonClicked(function()
		UIKit:newGameUI('GameUIAllianceShrine',City,"upgrade",self:GetBuilding()):AddToCurrentScene(true)
		self:LeftButtonClicked()
	end)
	return {fight_event_button,alliance_shirine_event_button,upgrade_button}
end

--是否开启移动联盟建筑功能
function GameUIAllianceShrineEnter:AllianceBuildingMoveIsOpen()
	return false
end
return GameUIAllianceShrineEnter
