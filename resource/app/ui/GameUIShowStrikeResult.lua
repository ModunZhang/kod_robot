--
-- Author: Danny He
-- Date: 2014-11-27 17:03:36
--
local GameUIShowStrikeResult = UIKit:createUIClass("GameUIShowStrikeResult")
local window = import("..utils.window")

-- callback:function()
function GameUIShowStrikeResult:ctor(dragonType,enemyPlayerId,interval)
	interval = interval or 5
	GameUIShowStrikeResult.super.ctor(self)
	self.interval_ = interval
	self.total_interval = interval
	self.dragonType = dragonType
	self.enemyPlayerId = enemyPlayerId
end

function GameUIShowStrikeResult:onEnter()
	GameUIShowStrikeResult.super.onEnter(self)
	self.shadow_layer = UIKit:shadowLayer():addTo(self)
	local bg = display.newSprite("show_strike_bg_407x125.png"):addTo(self.shadow_layer):pos(window.cx,window.cy)
	local box = display.newSprite("show_strike_box_366x40.png"):align(display.CENTER_BOTTOM,203,25):addTo(bg)
	local bg_of_process = display.newSprite("show_strike_process_bg_366x40.png"):pos(183,20):addTo(box)
	self.progress = UIKit:commonProgressTimer("show_strike_process_366x40.png"):pos(183,20):addTo(box)
	self.progress_label = UIKit:ttfLabel({
		text = self.total_interval  .. " S",
		size = 22,
		color= 0xfff3c7,
		shadow = true
	}):align(display.CENTER,183,20):addTo(box)
	self.status_label = UIKit:ttfLabel({
		text = _("正在前往目标突袭"),
		size = 20,
		color= 0x514d3e
	}):align(display.TOP_CENTER,203,110):addTo(bg)
	self.handlerOfupdate = self:schedule(handler(self, self.OnInterval),1)
end

function GameUIShowStrikeResult:OnInterval()
	if self.interval_ > 0 then
		self.interval_ = self.interval_ - 1 
		self.progress_label:setString(self.interval_ .. " S")
		self.progress:setPercentage((self.total_interval - self.interval_)/self.total_interval * 100)
	else
		self.handlerOfupdate:stop()
		NetManager:getStrikePlayerCityPromise(self.dragonType,self.enemyPlayerId)
		self:LeftButtonClicked()
	end
end

return GameUIShowStrikeResult