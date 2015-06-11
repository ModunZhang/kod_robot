--
-- Author: Danny He
-- Date: 2015-04-23 21:16:47
--
local WidgetPushButton = import(".WidgetPushButton")
local WidgetChatSendPushButton = class("WidgetChatSendPushButton",WidgetPushButton)

function WidgetChatSendPushButton:ctor()
	WidgetChatSendPushButton.super.ctor(self,{
		normal = "chat_button_n_68x50.png",
        pressed= "chat_button_h_68x50.png",
	})
	self:setNodeEventEnabled(true)
end

function WidgetChatSendPushButton:onEnter()
	local sp = display.newSprite("chat_send_43x35.png",34,-25):addTo(self) 
	local progress = display.newProgressTimer("progress_bg_116x89.png", display.PROGRESS_TIMER_RADIAL):scale(43/116):hide()
    progress:setReverseDirection(true)
    progress:addTo(self):pos(34,-25)
    progress:setPercentage(0)
    progress:setTouchEnabled(true)
    self.progress = progress
end

function WidgetChatSendPushButton:StartTimer()
	if not self:CanSendChat() then return end
	self.progress:show()
	transition.execute(self.progress,cca.progressFromTo(2,100,0),{
	onComplete = function()
		self.progress:hide()
    end
	})
end

function WidgetChatSendPushButton:CanSendChat()
	return self.progress:getNumberOfRunningActions() == 0
end

return WidgetChatSendPushButton