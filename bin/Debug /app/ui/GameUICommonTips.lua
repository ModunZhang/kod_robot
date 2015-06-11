--需要有入场动画
local GameUICommonTips = UIKit:createUIClass('GameUICommonTips')
local window = import("..utils.window")
local Enum = import("..utils.Enum")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local GLOBAL_Y = window.cy + 200 --Y坐标

GameUICommonTips.STATUS = Enum("OPEN","CLOSE")
function GameUICommonTips:ctor(delegate,autoClose)
	GameUICommonTips.super.ctor(self)
    if nil == autoClose then autoClose = false end
    self.autoClose = autoClose
    self.delegate = delegate
    self.status = self.STATUS.CLOSE
    self.display_time = 0
	self.___handle___ = scheduler.scheduleGlobal(handler(self, self.update_),1)
	self:setTouchEnabled(true)
	self:setTouchSwallowEnabled(false)
	self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
		if event.name == "began" then
        	return true
        elseif event.name == 'ended' then
        	self:closeButtonPressed()
    	end
	end)
end

function GameUICommonTips:closeButtonPressed()
	if self:IsOpen() and not self.isAnmate then
		self:ResetDisplayTime()
		self:UIAnimationMoveOut()
	end
end

function GameUICommonTips:update_()
	if self:IsOpen() then
		self.display_time = self.display_time + 1
		if self:ShouldAnimateOut() then
			if self.delegate and self.delegate.onTipsMoveOut then
				if not self.delegate.onTipsMoveOut(self.delegate,self) then
					self:ResetDisplayTime()
					self:UIAnimationMoveOut()
				end
			end
		end
	end
end

function GameUICommonTips:ShouldAnimateOut()
	return self.display_time >= self.autoClose
end

function GameUICommonTips:ResetDisplayTime()
	self.display_time = 0
end

function GameUICommonTips:onEnter()
	self:createUI()
end

function GameUICommonTips:createUI()
	local header_sp = display.newSprite("tips_bg_header_640x140.png"):align(display.TOP_CENTER, window.cx, GLOBAL_Y):addTo(self,2)
	self.header_sp = header_sp
	self.clipeNode = display.newClippingRegionNode(cc.rect(0,0,display.width,header_sp:getPositionY()-18)):addTo(self,1)
	self.content_sp_postion = {
		close = cc.p(window.cx,header_sp:getPositionY() + 140),
		open  = cc.p(window.cx,header_sp:getPositionY())
	}
	self.content_sp = display.newSprite("tips_bg_content_640x140.png")
		:addTo(self.clipeNode)
		:align(display.CENTER_TOP,self.content_sp_postion.close.x,self.content_sp_postion.close.y)
	self.content_label = UIKit:ttfLabel({
		size = 20,
		color= 0xf3f0b6,
		align = cc.TEXT_ALIGNMENT_CENTER,
		dimensions = cc.size(580,100),
		ellipsis = true,
	}):align(display.TOP_CENTER, 335, 100):addTo(self.content_sp)
end

function GameUICommonTips:GetContentTargetPosition(status)
	if status == self.STATUS.CLOSE then
		return self.content_sp_postion.close
	else
		return self.content_sp_postion.open
	end
end

function GameUICommonTips:ChangeStatus(isOpen)
	self.status = isOpen and self.STATUS.OPEN or self.STATUS.CLOSE
	self:ResetDisplayTime()
end

function GameUICommonTips:IsOpen()
	return self.status == self.STATUS.OPEN
end

function GameUICommonTips:SetMessage(title,content)
	print(title,content)
	self.content_label:setString(title .. "\n" .. content)
	self.content_label:align(display.TOP_CENTER, 335, 100)
	-- ...
end

function GameUICommonTips:showTips(title,content)
	if not self:IsOpen() then
		self:SetMessage(title,content)
		self:UIAnimationMoveIn()
	else
		self:SetMessage(title,content)
	end
	self:ChangeStatus(true)
end

function GameUICommonTips:onExit()
	if self.___handle___ then
		scheduler.unscheduleGlobal(self.___handle___)
	end
	self:ChangeStatus(false)
	self.delegate = nil
	self.autoClose = nil
end

function GameUICommonTips:UIAnimationMoveIn()
	self.header_sp:opacity(0)
	self.isAnmate = true
	local seq = transition.sequence({
		cc.FadeIn:create(0.1),
		cc.CallFunc:create(function()
			transition.execute(self.content_sp, cc.MoveTo:create(0.2,self:GetContentTargetPosition(self.STATUS.OPEN)), {
    			onComplete = function()
    				self.isAnmate = false
    				self:ChangeStatus(true)
    			end,
			})
		end)
	})
	self.header_sp:runAction(seq)
end

function GameUICommonTips:UIAnimationMoveOut()
	self.isAnmate = true
	transition.fadeOut(self.header_sp,{time = 0.2})
	transition.execute(self.content_sp,cc.FadeOut:create(0.2), 
	{
		onComplete = function()
			self.isAnmate = false
			self.content_sp:setPosition(self:GetContentTargetPosition(self.STATUS.CLOSE))
			self.content_sp:opacity(255)
			self:ChangeStatus(false)
			if self.delegate and self.delegate.onTipsMoveOut then
				self.delegate.onTipsMoveOut(self.delegate,self) 
			end
		end,
	})
end


return GameUICommonTips