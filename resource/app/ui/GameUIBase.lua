--
-- Author: dannyhe
-- Date: 2014-08-01 16:18:16
-- GameUIBase is a CCLayer
local cocos_promise = import("..utils.cocos_promise")
local window = import("..utils.window")
local TutorialLayer = import(".TutorialLayer")
local UIListView = import(".UIListView")
local WidgetBackGroundTabButtons = import('..widget.WidgetBackGroundTabButtons')
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local Enum = import("..utils.Enum")

local GameUIBase = class('GameUIBase', function()
    local layer = display.newLayer()
    layer:setContentSize(cc.size(display.width, display.height))
    layer:setNodeEventEnabled(true)
    return layer
end)


function GameUIBase:ctor(params)
    self.__isBase = true
    params = checktable(params)
    self.__type  = params.type or UIKit.UITYPE.WIDGET
    UIKit:CheckOpenUI(self, true)
    return true
end

--------------------------------------
function GameUIBase:onEnter()
    print("onEnter->",self.__cname)
    if ext.closeKeyboard then
        ext.closeKeyboard()
    end
end

function GameUIBase:onEnterTransitionFinish()
    print("onEnterTransitionFinish->")
end

function GameUIBase:onExitTransitionStart()
    print("onExitTransitionStart->")
end

function GameUIBase:BlurRenderScene()
    -- if type(display.getRunningScene().BlurRenderScene) == "function" then
    --     print("GameUIBase:BlurRenderScene--->")
    --     display.getRunningScene():BlurRenderScene()
    -- end
    local scene = display.getRunningScene()
    if scene.GetHomePage and scene:GetHomePage() then
        scene:GetHomePage():DisplayOff()
    end
end

function GameUIBase:ResetRenderSceneState()
    -- if type(display.getRunningScene().ResetRenderState) == "function" then
    --     display.getRunningScene():ResetRenderState()
    -- end
    local scene = display.getRunningScene()
    if scene.GetHomePage and scene:GetHomePage() then
        scene:GetHomePage():DisplayOn()
    end
end

function GameUIBase:onExit()
    print("onExit--->")
end


function GameUIBase:onCleanup()
    print("onCleanup->",self.__cname)
    GameGlobalUI:clearMessageQueue()
    if UIKit:getRegistry().isObjectExists(self.__cname) then
        UIKit:getRegistry().removeObject(self.__cname)
    end
    UIKit:CheckCloseUI(self.__cname)
end


-- overwrite in subclass
--------------------------------------

function GameUIBase:OnMoveInStage()
-- app:lockInput(false)
    UIKit:CheckOpenUI(self)
end

function GameUIBase:OnMoveOutStage()
    self:removeFromParent(true)
end


-- public methods
--------------------------------------

function GameUIBase:IsAnimaShow()
    return self.moveInAnima
end

function GameUIBase:LeftButtonClicked()
    if self:isVisible() then
        if self.moveInAnima then
            self:UIAnimationMoveOut()
        else
            self:OnMoveOutStage() -- fix
        end
    end
end

function GameUIBase:AddToScene(scene,anima)
    if scene and tolua.type(scene) == 'cc.Scene' then
        scene:addChild(self, 2000)
        self.moveInAnima = anima == nil and false or anima
        if self.moveInAnima then
            self:UIAnimationMoveIn()
        else
            self:OnMoveInStage()
        end
    end
    return self
end

function GameUIBase:AddToCurrentScene(anima)
    return self:AddToScene(display.getRunningScene(),anima)
end

-- ui入场动画
function GameUIBase:UIAnimationMoveIn()
    -- self:opacity(0)
    -- transition.fadeIn(self,{
    --     time = 0.15,
    --     onComplete = function()
    --         self:OnMoveInStage()
    --     end
    -- })
    self:OnMoveInStage()
end

-- ui 出场动画
function GameUIBase:UIAnimationMoveOut()
   -- transition.fadeOut(self,{
   --      time = 0.15,
   --      onComplete = function()
   --          self:OnMoveOutStage()
   --      end
   --  })
    self:OnMoveOutStage()
end

-- Private Methods
--------------------------------------

--

function GameUIBase:CreateBackGround()
    return display.newSprite("common_bg_center.png"):align(display.CENTER_TOP, window.cx,window.top-40):addTo(self)
end
function GameUIBase:CreateTitle(title)
    local head_bg = cc.ui.UIImage.new("head_bg.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    dump(head_bg)
    return UIKit:ttfLabel({
        text = title,
        size = 30,
        color = 0xffedae,
        align = cc.TEXT_ALIGNMENT_LEFT,
        bold  = true
    })
        :addTo(head_bg)
        :align(display.CENTER, head_bg:getContentSize().width / 2, head_bg:getContentSize().height - 35)
end
function GameUIBase:CreateHomeButton(on_clicked)
    local home_button = cc.ui.UIPushButton.new(
        {normal = "home_btn_up.png",pressed = "home_btn_down.png"}, nil, {down = "HOME_PAGE"})
        :onButtonClicked(function(event)
            if on_clicked then
                on_clicked()
            else
                self:LeftButtonClicked()
            end
        end)
        :align(display.LEFT_TOP, window.cx-314 , window.top-5)
        :addTo(self)

    cc.ui.UIImage.new("home_icon.png")
        :pos(34, -50)
        :addTo(home_button)
        :scale(0.8)
    return home_button
end
function GameUIBase:CreateShopButton(on_clicked)
    local gem_button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up.png", pressed = "gem_btn_down.png"}
    ):onButtonClicked(function(event)
        if on_clicked then
            on_clicked()
        else
            self:LeftButtonClicked()
        end
    end):addTo(self)
    gem_button:align(display.RIGHT_TOP, window.cx+314, window.top-5)
    cc.ui.UIImage.new("gem_icon_62x61.png")
        :addTo(gem_button)
        :pos(-60, -62)

    return UIKit:ttfLabel({
        text = ""..string.formatnumberthousands(City:GetUser():GetGemResource():GetValue()),
        size = 20,
        color = 0xffd200,
        shadow = true
    })
        :addTo(gem_button)
        :align(display.CENTER, -102, -32)
end
function GameUIBase:CreateTabButtons(param, func)
    return WidgetBackGroundTabButtons.new(param,
        func)
        :addTo(self)
end

function GameUIBase:CreateVerticalListView(...)
    return self:CreateVerticalListViewDetached(...):addTo(self)
end
function GameUIBase:CreateVerticalListViewDetached(left_bottom_x, left_bottom_y, right_top_x, right_top_y)
    local width, height = right_top_x - left_bottom_x, right_top_y - left_bottom_y
    return UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a000000),
        viewRect = cc.rect(left_bottom_x, left_bottom_y, width, height),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }
end


-- fte
local FTE_TAG = 119
function GameUIBase:GetFteLayer()
    if not self:getChildByTag(FTE_TAG) then
        return self:CreateFteLayer()
    end
    return self:getChildByTag(FTE_TAG):Enable()
end
function GameUIBase:CreateFteLayer()
    return TutorialLayer.new():addTo(self, 2000, FTE_TAG):Enable()
end
function GameUIBase:DestroyFteLayer()
    self:removeChildByTag(FTE_TAG)
end

return GameUIBase


