local Enum = import("..utils.Enum")
local WidgetPushTransparentButton = import(".WidgetPushTransparentButton")
local WidgetDropItem = class("WidgetDropItem",function()
    return display.newNode()
end)
WidgetDropItem.STATE = Enum("open","close")

local ClipHeight = 188
local Animate_Time_Inteval = 0.2

function WidgetDropItem:ctor(params, callback)
    self.params = params
    self.state_ = self.STATE.close
    self.callback = callback
    self:onEnter()
end

function WidgetDropItem:onEnter()
    local header = display.newSprite("drop_down_box_content_562x58.png"):align(display.LEFT_BOTTOM,2,0):addTo(self)
    self.header = header
    WidgetPushTransparentButton.new(cc.rect(0,0,562,58))
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(header)
        :onButtonClicked(handler(self, self.OnBoxButtonClicked))
    local button = cc.ui.UIPushButton.new({normal = "drop_down_box_button_normal_52x44.png",pressed = "drop_down_box_button_light_52x44.png"})
        :align(display.RIGHT_BOTTOM, 554,7):addTo(header)
        :onButtonClicked(handler(self, self.OnBoxButtonClicked))
    self.arrow = display.newSprite("shrine_page_control_26x34.png"):addTo(button):pos(-26,22)
    self.arrow:setRotation(90)
    self.title_label = UIKit:ttfLabel({
        text = self.params.title,
        size = 20,
        color = 0x5d563f
    }):align(display.LEFT_CENTER, 20, 29):addTo(header)
end


function WidgetDropItem:GetState()
    return self.state_
end

function WidgetDropItem:OnBoxButtonClicked( event )
    if self.lock_ then return end
    self.lock_ = true
    if self:GetState() == self.STATE.close then
        self:OnOpen()
    else
        self:OnClose(true)
    end
end
function WidgetDropItem:OnClose(ani)
    ani = ani == nil and true or ani
    if self.content_box then
        self.content_box:removeFromParent()
        self.content_box = nil
    end
    self.state_ = self.STATE.close
    self.lock_ = false
    self.arrow:flipY(false)
    if type(self.callback) == "function" then
        self.callback(nil, ani)
    end
end
function WidgetDropItem:OnOpen(ani)
    ani = ani == nil and true or ani
    self.state_ = self.STATE.open
    self.lock_ = false
    self.arrow:flipY(true)
    if type(self.callback) == "function" then
        self.callback(self, ani)
    end
end
function WidgetDropItem:GetContent()
    if not self.content_box then
        self.content_box = display.newScale9Sprite("drop_down_box_bg_572x304.png"):align(display.CENTER_TOP):addTo(self, -1):pos(2, 0)
    end
    return self.content_box
end
function WidgetDropItem:CreateRewardsPanel(task)
    local content = self:GetContent()

    local extend = (#task:GetRewards() - 4)
    content:size(572, 304 + (extend > 0 and extend or 0) * 40)

    local size = content:getContentSize()
    local desc = UIKit:ttfLabel({
        text = task:Desc(),
        size = 18,
        color = 0x615b44,
        dimensions = cc.size(500,0)
    }):align(display.LEFT_TOP, 40, size.height - 30):addTo(content)

    local under_y = 20
    local base_under_line = size.height - 110 - under_y
    UIKit:ttfLabel({
        text = _("任务奖励"),
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, 572/2, size.height - 100):addTo(content)

    display.newScale9Sprite("dividing_line.png",0,0,cc.size(550,2),cc.rect(10,2,382,2)):align(display.CENTER, 572/2, base_under_line):addTo(content)

    local base_y = base_under_line
    local gap_y = 20
    for i,v in ipairs(task:GetRewards()) do
        local cur_y = base_y - gap_y
        cc.ui.UIImage.new(v:Icon()):align(display.CENTER, 572/2 - 230, cur_y):addTo(content):setLayoutSize(30, 30)
        UIKit:ttfLabel({
            text = v:Desc(),
            size = 20,
            color = 0x403c2f,
        }):align(display.CENTER, 572/2 - 180, cur_y):addTo(content)
        UIKit:ttfLabel({
            text = v:CountDesc(),
            size = 20,
            color = 0x403c2f,
        }):align(display.CENTER, 572/2 + 220, cur_y):addTo(content)
        if i ~= #task:GetRewards() then
            display.newScale9Sprite("dividing_line.png",0,0,cc.size(550,2),cc.rect(10,2,382,2)):align(display.CENTER, 572/2, cur_y - under_y):addTo(content)
        end
        base_y = cur_y - under_y
    end
end

function WidgetDropItem:align(anchorPoint, x, y)
    display.align(self,anchorPoint,x,y)
    local anchorPoint = display.ANCHOR_POINTS[anchorPoint]
    local header = self.header
    local size = header:getContentSize()
    local header_anchorPoint = header:getAnchorPoint()
    header:setPosition(header:getPositionX()+size.width*(header_anchorPoint.x - anchorPoint.x),header:getPositionY()+size.height*(header_anchorPoint.y - anchorPoint.y))
    return self
end

return WidgetDropItem







