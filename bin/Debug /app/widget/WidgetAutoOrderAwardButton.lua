--
-- Author: Danny He
-- Date: 2015-05-13 15:32:17
--
local WidgetAutoOrderAwardButton = class("WidgetAutoOrderAwardButton",cc.ui.UIPushButton)
local config_online = GameDatas.Activities.online
local UILib = import("..ui.UILib")
local WidgetNumberTips = import(".WidgetNumberTips")

function WidgetAutoOrderAwardButton:ctor()
	WidgetAutoOrderAwardButton.super.ctor(self,{normal = "activity_68x78.png"})
	self:setNodeEventEnabled(true)
	self:onButtonClicked(handler(self, self.OnAwradButtonClicked))
end


function WidgetAutoOrderAwardButton:OnAwradButtonClicked(event)
	UIKit:newGameUI("GameUIActivityRewardNew",2):AddToCurrentScene(true)
end


function WidgetAutoOrderAwardButton:SetTimeInfo(time) 
	if self.time_bg then
		if math.floor(time) > 0 then
			self.time_label:setString(os.date("!%H:%M:%S",time))
			self.time_bg:show()
		else
			self.time_bg:hide()
		end
	else
		local label = UIKit:ttfLabel({
			text = os.date("!%H:%M:%S",time),
			size = 20,
			align = cc.TEXT_ALIGNMENT_CENTER,
		})
		local time_bg = display.newSprite("online_time_bg_96x36.png"):addTo(self):align(display.CENTER,0,-55):scale(0.7)
		label:addTo(time_bg):align(display.CENTER,48,18)
		self.time_bg = time_bg
		self.time_label = label
		self.time_bg:setVisible(time > 0)
	end
end

function WidgetAutoOrderAwardButton:onEnter()
	local countInfo = User:GetCountInfo()
    local onlineTime = (countInfo.todayOnLineTime - countInfo.lastLoginTime)/1000
	self.online_time = onlineTime
	self.can_receive_num = WidgetNumberTips.new():addTo(self):pos(24,-24):hide()
	app.timer:AddListener(self)
end

function WidgetAutoOrderAwardButton:onCleanup()
	app.timer:RemoveListener(self)
end

function WidgetAutoOrderAwardButton:OnTimer(dt)
	if not self.can_get and self.timePoint then
		local time = self.online_time + dt
		local diff_time = config_online[self.timePoint].onLineMinutes * 60 - time
		if  math.floor(diff_time) > 0 then
			self:SetTimeInfo(diff_time)
		else
			self:CheckState()
			self:SetTimeInfo(diff_time)
		end
		self.can_receive_num:hide()
	else
		self.can_receive_num:show()
		self.can_receive_num:SetNumber(self:GetCanReceiveOnLineNum())
	end
end
function WidgetAutoOrderAwardButton:GetCanReceiveOnLineNum()
    local on_line_time = DataUtils:getPlayerOnlineTimeMinutes()
    local count = 0
    for __,v in pairs(config_online) do
        if v.onLineMinutes <= on_line_time then
            if not self:IsTimePointRewarded(v.timePoint) then
            	count = count + 1
            end
        end
    end
    return count
end
function WidgetAutoOrderAwardButton:IsTimePointRewarded(timepoint)
    local countInfo = User:GetCountInfo()
    for __,v in ipairs(countInfo.todayOnLineTimeRewards) do
        if v == timepoint then
            return true
        end
    end
    return false
end
function WidgetAutoOrderAwardButton:StarAction()
	self:StopAction()
	self.sprite_[1]:runAction(self:GetShakeAction())
end

function WidgetAutoOrderAwardButton:StopAction()
	self.sprite_[1]:stopAllActions()
	self.sprite_[1]:setRotation(0)
	
end

function WidgetAutoOrderAwardButton:GetShakeAction()
    local t = 0.05
    local r = 12
    local action = transition.sequence({
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cca.delay(1),
    })
    return cca.repeatForever(action)
end

-- For WidgetAutoOrder
function WidgetAutoOrderAwardButton:CheckVisible()
	local countInfo = User:GetCountInfo()
    local onlineTime = (countInfo.todayOnLineTime - countInfo.lastLoginTime)/1000
    print("CheckVisible------>",onlineTime)
	self.online_time = onlineTime
	self:CheckState()
	return self.visible___ 
end

function WidgetAutoOrderAwardButton:GetElementSize()
	return {width = 68, height = 100}
end
-- For Data
function WidgetAutoOrderAwardButton:GetNextTimePoint()
	local onlineTime = DataUtils:getPlayerOnlineTimeMinutes()
	for __,v in ipairs(config_online) do
		if v.onLineMinutes <= onlineTime then
			if not self:IsTimePointRewarded(v.timePoint) then
				return v.timePoint,true
			end
		else
			return v.timePoint,false
		end
	end
	return nil,nil
end

function WidgetAutoOrderAwardButton:CheckState()
	local timePoint,animation = self:GetNextTimePoint()
	if timePoint ~= nil then
		self.visible___ = true
		self.timePoint = timePoint

		if animation then
			self:StarAction()
			self.can_get = true
		else
			self:StopAction()
			self.can_get = false
		end
	else
		self.visible___ = false 
	end
end

function WidgetAutoOrderAwardButton:IsTimePointRewarded(timepoint)
	local countInfo = User:GetCountInfo()
	for __,v in ipairs(countInfo.todayOnLineTimeRewards) do
		if v == timepoint then
			return true
		end
	end
	return false 
end
return WidgetAutoOrderAwardButton