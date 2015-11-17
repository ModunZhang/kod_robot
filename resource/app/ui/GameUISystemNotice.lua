--
-- Author: Kenny Dai
-- Date: 2015-05-27 10:02:24
--
local GameUIBase = import('.GameUIBase')
local GameUISystemNotice = class("GameUISystemNotice", GameUIBase)

function GameUISystemNotice:ctor(delegate,notice_type,notice_content)
    GameUISystemNotice.super.ctor(self,{type = UIKit.UITYPE.WIDGET})
    self:setTouchEnabled(false)
    self.notice_type = notice_type
    self.notice_content = notice_content
    self.delegate = delegate
end
function GameUISystemNotice:onEnter()
    local back = display.newSprite("back_ground_366x66.png"):addTo(self):pos(display.cx,display.top - 200)
	back:opacity(0)
	self.back = back
    local back_width,back_height = back:getContentSize().width, back:getContentSize().height
    local clipNode = display.newClippingRegionNode(cc.rect(40,0,back_width-80,back_height)):addTo(back)
    local notice_label = UIKit:ttfLabel({
        size = 24,
    }):align(display.LEFT_CENTER, back_width,back_height/2)
        :addTo(clipNode)
    self.notice_label = notice_label
    
end
function GameUISystemNotice:showNotice(notice_type,notice_content)
	self:ChangeStatus(true)
	self.notice_label:setString(notice_content)
	self.notice_label:setColor(UIKit:hex2c4b(notice_type == "warning" and 0xff5400 or 0xffedae))
	local back = self.back
    local time_scale = self.notice_label:getContentSize().width/366
    transition.fadeTo(back, {opacity = 255, time = 2,
        onComplete = function()
            transition.moveTo(self.notice_label, {x = -self.notice_label:getContentSize().width, y = back:getContentSize().height/2, time = 6 * (time_scale > 1 and time_scale or 1),
                onComplete = function()
                    transition.fadeTo(back, {opacity = 0, time = 2,onComplete = function ()
                        if self.delegate and self.delegate.onNoticeMoveOut then
                            self.delegate.onNoticeMoveOut(self.delegate,self)
                        end
                        self.notice_label:setPositionX(back:getContentSize().width)
						self:ChangeStatus(false)
                    end})
                end
            })
        end
    })
end
function GameUISystemNotice:IsOpen()
	return self.isOpen
end
function GameUISystemNotice:ChangeStatus(isOpen)
	self.isOpen = isOpen
end
return GameUISystemNotice

