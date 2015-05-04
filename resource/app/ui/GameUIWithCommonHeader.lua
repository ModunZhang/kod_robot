local GameUIBase = import('.GameUIBase')
local GameUIWithCommonHeader = class('GameUIWithCommonHeader', GameUIBase)
local window = import("..utils.window")
local WidgetBackGroundTabButtons = import('..widget.WidgetBackGroundTabButtons')

function GameUIWithCommonHeader:ctor(city, title)
    GameUIWithCommonHeader.super.ctor(self,{type = UIKit.UITYPE.WIDGET})
    self.title = title
    self.city = city
end

function GameUIWithCommonHeader:onEnter()
    GameUIWithCommonHeader.super.onEnter(self)
    self.__view = display.newLayer():addTo(self)

    local background = self:CreateBackGround()
    local titleBar = self:CreateTitle(self.title)
    -- 点击空白区域关闭
    self.control_close_layer = display.newLayer():addTo(self,100)
    self.control_close_layer:setTouchSwallowEnabled(false)
    self.control_close_layer:setNodeEventEnabled(true)
    local lbpoint = background:convertToWorldSpace({x = 0, y = 0})
    local size = background:getContentSize()
    local rtpoint = background:convertToWorldSpace({x = size.width, y = size.height})

    local lbpoint_title = titleBar:convertToWorldSpace({x = 0, y = 0})
    local size_title = titleBar:getContentSize()
    local rtpoint_title = titleBar:convertToWorldSpace({x = size_title.width, y = size_title.height})
    local is_began_out = false
    self.control_close_layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if self.disable_auto_close then
            return
        end
        if event.name == "began" then
            if not cc.rectContainsPoint(cc.rect(lbpoint.x, lbpoint.y, rtpoint.x - lbpoint.x, rtpoint.y - lbpoint.y), event)
                and not cc.rectContainsPoint(cc.rect(lbpoint_title.x, lbpoint_title.y, rtpoint_title.x - lbpoint_title.x, rtpoint_title.y - lbpoint_title.y), event)
            then
                is_began_out = true
            end
        elseif event.name == "ended" then
            if not cc.rectContainsPoint(cc.rect(lbpoint.x, lbpoint.y, rtpoint.x - lbpoint.x, rtpoint.y - lbpoint.y), event)
                and not cc.rectContainsPoint(cc.rect(lbpoint_title.x, lbpoint_title.y, rtpoint_title.x - lbpoint_title.x, rtpoint_title.y - lbpoint_title.y), event)
            then
                if is_began_out then
                    self:LeftButtonClicked()
                end
            else
                is_began_out = false
            end
        end
        return true
    end)

    self:CreateBetweenBgAndTitle()
    local home_button = self:CreateHomeButton():addTo(titleBar)
    local gem_button,gem_label = self:CreateShopButton()
    gem_button:addTo(titleBar)
    self.home_button = home_button
    self.__titleBar = titleBar
    if gem_label then
        self.__gem_label= gem_label
    end

end
function GameUIWithCommonHeader:DisableAutoClose()
    self.disable_auto_close = true
    return self
end
function GameUIWithCommonHeader:onExit()
    if self.__gem_label then
        self.city:GetResourceManager():RemoveObserver(self)
    end
    GameUIWithCommonHeader.super.onExit(self)
end

function GameUIWithCommonHeader:GetView()
    return self.__view
end

function GameUIWithCommonHeader:GetTitleBar()
    return self.__titleBar
end

function GameUIWithCommonHeader:GetGemLabel()
    return self.__gem_label
end
function GameUIWithCommonHeader:GetHomeButton()
    return self.home_button
end
function GameUIWithCommonHeader:OnMoveOutStage()
    GameUIWithCommonHeader.super.OnMoveOutStage(self)
end

function GameUIWithCommonHeader:OnMoveInStage()
    GameUIWithCommonHeader.super.OnMoveInStage(self)
    if self.__gem_label then
        self.city:GetResourceManager():AddObserver(self)
    end
end

function GameUIWithCommonHeader:UIAnimationMoveIn()
    self:GetView():pos(0,display.top + 200)
    -- self:GetTitleBar():opacity(0)
    self:BlurRenderScene()
    transition.fadeIn(self:GetTitleBar(),{
        time = 0.05,
        onComplete = function()
            transition.moveTo(self:GetView(),{
                x = 0,
                y = 0,
                time = 0.2,
                onComplete = function()
                    self:OnMoveInStage()
                end
            })
        end
    })
end

function GameUIWithCommonHeader:UIAnimationMoveOut()
    self:ResetRenderSceneState()
    transition.moveTo(self:GetView(),{
        x = 0,
        y = display.top + 200,
        time = 0.15,
        onComplete = function()
            transition.fadeOut(self:GetTitleBar(),{
                time = 0.05,
                onComplete = function()
                    self:OnMoveOutStage()
                end
            })
        end
    })
end

function GameUIWithCommonHeader:RightButtonClicked()
    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(false)
end

function GameUIWithCommonHeader:CreateTitle(title)
    local head_bg = cc.ui.UIImage.new("head_bg.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self):zorder(200)
    UIKit:ttfLabel({
        text = title,
        size = 30,
        color = 0xffedae,
        align = cc.TEXT_ALIGNMENT_LEFT,
        bold  = true
    }):addTo(head_bg):align(display.CENTER, head_bg:getContentSize().width / 2, head_bg:getContentSize().height - 35)
    return head_bg
end

function GameUIWithCommonHeader:CreateBackGround()
    return display.newSprite("common_bg_center.png"):align(display.CENTER_TOP, window.cx,window.top-40):addTo(self:GetView())
end

function GameUIWithCommonHeader:CreateHomeButton(on_clicked)
    local home_button = cc.ui.UIPushButton.new(
        {normal = "home_btn_up.png",pressed = "home_btn_down.png",disabled = "home_btn_disabled.png"}, nil, {down = "HOME_PAGE"})
        :onButtonClicked(function(event)
            if on_clicked then
                on_clicked()
            else
                self:LeftButtonClicked()
            end
        end)
        :align(display.LEFT_TOP, 50 , 86)
    cc.ui.UIImage.new("home_icon.png")
        :pos(34, -50)
        :addTo(home_button)
        :scale(0.8)
    return home_button
end

function GameUIWithCommonHeader:CreateShopButton(on_clicked)
    local gem_button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up.png", pressed = "gem_btn_down.png"}
    ):onButtonClicked(function(event)
        if on_clicked then
            on_clicked()
        else
            self:RightButtonClicked()
        end
    end)
    gem_button:align(display.RIGHT_TOP, 670, 86)
    cc.ui.UIImage.new("gem_icon_62x61.png")
        :addTo(gem_button)
        :pos(-60, -62)

    local gem_label = UIKit:ttfLabel({
        text = ""..string.formatnumberthousands(City:GetUser():GetGemResource():GetValue()),
        size = 20,
        color = 0xffd200,
        shadow = true
    }):addTo(gem_button):align(display.CENTER, -102, -32)

    return gem_button,gem_label
end

function GameUIWithCommonHeader:CreateBetweenBgAndTitle()
    print("->创建backgroud和title之间的中间层显示")
end

function GameUIWithCommonHeader:OnResourceChanged(resource_manager)
    self:GetGemLabel():setString(string.formatnumberthousands(self.city:GetUser():GetGemResource():GetValue()))
end

function GameUIWithCommonHeader:CreateTabButtons(param, func)
    return WidgetBackGroundTabButtons.new(param,
        func)
        :addTo(self:GetView(),2)
end

return GameUIWithCommonHeader






