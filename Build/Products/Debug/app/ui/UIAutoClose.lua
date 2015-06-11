--TODO:这里需要把此类继承GameUIBase 方便统一管理(后台统一关闭界面,半透明背景效果,提示框管理 etc)

local GameUIBase = import('.GameUIBase')

local UIAutoClose = class('UIAutoClose', GameUIBase)
local BODY_TAG = 2101
function UIAutoClose:ctor(params)
    UIAutoClose.super.ctor(self,params)
    local node = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
    node:setNodeEventEnabled(true)
    local is_began_out = false
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            if self.disable then
                return
            end
            local body = self:getChildByTag(BODY_TAG)
            local lbpoint = body:convertToWorldSpace({x = 0, y = 0})
            local size = body:getContentSize()
            local rtpoint = body:convertToWorldSpace({x = size.width, y = size.height})
            if not cc.rectContainsPoint(cc.rect(lbpoint.x, lbpoint.y, rtpoint.x - lbpoint.x, rtpoint.y - lbpoint.y), event) then
                is_began_out = true
            end
        elseif event.name == "ended" then
            if self.disable then
                return
            end
            local body = self:getChildByTag(BODY_TAG)
            local lbpoint = body:convertToWorldSpace({x = 0, y = 0})
            local size = body:getContentSize()
            local rtpoint = body:convertToWorldSpace({x = size.width, y = size.height})
            if not cc.rectContainsPoint(cc.rect(lbpoint.x, lbpoint.y, rtpoint.x - lbpoint.x, rtpoint.y - lbpoint.y), event) then
                if is_began_out then
                    if type(self.out_func) == "function" then
                        self:out_func()
                    else
                        self:LeftButtonClicked()
                    end
                end
            else
                is_began_out = false
            end
        end
        return true
    end)
    node:addTo(self)
end

function UIAutoClose:addTouchAbleChild(body)
    -- body:setTouchEnabled(true)
    -- function body:isTouchInViewRect( event)
    --     local viewRect = self:convertToWorldSpace(cc.p(0, 0))
    --     viewRect.width = self:getContentSize().width
    --     viewRect.height = self:getContentSize().height
    --     return cc.rectContainsPoint(viewRect, cc.p(event.x, event.y))
    -- end
    -- body:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(event)
    --     if ("began" == event.name or "moved" == event.name or "ended" == event.name)
    --         and body:isTouchInViewRect(event) then
    --         return true
    --     else
    --         return false
    --     end
    -- end)
    body:setTag(BODY_TAG)
    self:addChild(body)
end

function UIAutoClose:onCleanup()
    UIAutoClose.super.onCleanup(self)
    if self.clean_func then
        self.clean_func()
    end
end

function UIAutoClose:DisableAutoClose(disable)
    if type(disable) ~= 'boolean'  then
        disable = true
    end
    self.disable = disable
end

function UIAutoClose:addCloseCleanFunc(func)
    self.clean_func=func
end

function UIAutoClose:AddClickOutFunc(out_func)
    self.out_func = out_func
end
return UIAutoClose




