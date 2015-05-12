local WidgetChangeMap = import("..widget.WidgetChangeMap")
local UIPageView = import("..ui.UIPageView")
local UILib = import("..ui.UILib")
local window = import("..utils.window")
local GameUIPVEHome = UIKit:createUIClass('GameUIPVEHome')
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetUseItems = import("..widget.WidgetUseItems")
local RichText = import("..widget.RichText")
local ChatManager = import("..entity.ChatManager")
local WidgetChat = import("..widget.WidgetChat")
local timer = app.timer


function GameUIPVEHome:DisplayOn()

end
function GameUIPVEHome:DisplayOff()

end
function GameUIPVEHome:ctor(user, scene)
    self.user = user
    self.scene = scene
    self.layer = scene:GetSceneLayer()
    GameUIPVEHome.super.ctor(self)
end
function GameUIPVEHome:onEnter()
    self:CreateTop()
    self:CreateBottom()
    self:OnExploreChanged(self.layer)
    self:OnResourceChanged(self.user)

    self:AddOrRemoveListener(true)
end
function GameUIPVEHome:onExit()
    self:AddOrRemoveListener(false)
end
function GameUIPVEHome:AddOrRemoveListener(isAdd)
    if isAdd then
        self.layer:AddPVEListener(self)
        self.user:AddListenOnType(self, self.user.LISTEN_TYPE.RESOURCE)
    else
        self.layer:RemovePVEListener(self)
        self.user:RemoveListenerOnType(self, self.user.LISTEN_TYPE.RESOURCE)
    end
end
function GameUIPVEHome:OnResourceChanged(user)
    local strength_resouce = user:GetStrengthResource()
    local current_strength = strength_resouce:GetResourceValueByCurrentTime(timer:GetServerTime())
    local limit = strength_resouce:GetValueLimit()
    self.strenth:setString(string.format("%d/%d", current_strength, limit))
    self.gem_label:setString(string.formatnumberthousands(user:GetGemResource():GetValue()))
end
function GameUIPVEHome:OnExploreChanged(pve_layer)
    self.exploring:setString(string.format("探索度 %.2f%%", pve_layer:ExploreDegree() * 100))
end
function GameUIPVEHome:CreateTop()
    local top_bg = display.newSprite("head_bg.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    local size = top_bg:getContentSize()
    top_bg:setTouchEnabled(true)

    cc.ui.UIPushButton.new(
        {normal = "return_btn_up_202x93.png", pressed = "return_btn_down_202x93.png"}
    ):addTo(top_bg)
        :align(display.LEFT_CENTER, 20, -5)
        :onButtonClicked(function()
            UIKit:showMessageDialog(_("返回起点"),_("返回当前关卡的起点需要消耗您10个金龙币,您是否同意?"))
                :CreateOKButton({
                    listener =  function()
                        self.user:SetPveData(nil, nil, 10)
                        self.layer:ResetCharPos()
                        NetManager:getSetPveDataPromise(
                            self.user:EncodePveDataAndResetFightRewardsData()
                        ):fail(function()
                            -- 失败回滚
                            local location = DataManager:getUserData().pve.location
                            self.user:GetPVEDatabase():SetCharPosition(location.x, location.y, location.z)
                            self.layer:MoveCharTo(self.user:GetPVEDatabase():GetCharPosition())
                        end)
                    end
                }):CreateCancelButton()

        end):setButtonLabel(cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("返回起点"),
        size = 18,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xffedae)})):setButtonLabelOffset(-20, 0)

    local gem_button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up.png", pressed = "gem_btn_down.png"}
    ):onButtonClicked(function(event)
        UIKit:newGameUI('GameUIShop', City):AddToCurrentScene(true)
    end):addTo(top_bg):align(display.RIGHT_TOP, size.width - 45, 85)
    cc.ui.UIImage.new("gem_icon_62x61.png"):addTo(gem_button):pos(-60, -62)
    self.gem_label = UIKit:ttfLabel({
        text = ""..string.formatnumberthousands(City:GetUser():GetGemResource():GetValue()),
        size = 20,
        color = 0xffd200,
        shadow = true
    }):addTo(gem_button):align(display.CENTER, -102, -32)


    local pve_back = display.newSprite("back_ground_pve.png")
        :addTo(top_bg):align(display.RIGHT_TOP, size.width - 45, 20)
    self.pve_back = pve_back
    local size = pve_back:getContentSize()
    display.newSprite("dragon_lv_icon.png"):addTo(pve_back):pos(20, 25)
    local add_btn = cc.ui.UIPushButton.new(
        {normal = "add_btn_up.png",pressed = "add_btn_down.png"}
        ,{})
        :addTo(pve_back):align(display.CENTER, size.width - 25, 25)
        :onButtonClicked(function ( event )
            WidgetUseItems.new():Create({
                item_type = WidgetUseItems.USE_TYPE.STAMINA
            }):AddToCurrentScene()
        end)
    display.newSprite("+.png"):addTo(add_btn)

    self.strenth = UIKit:ttfLabel({
        size = 20,
        color = 0xffedae,
    }):addTo(pve_back):align(display.CENTER, size.width / 2, 25)

    local box = cc.ui.UIPushButton.new(
        {normal = "back_ground_box.png", pressed = "back_ground_box.png"}
        ,{})
        :addTo(top_bg, 1):align(display.CENTER, 80, 55):scale(0.8)
        :onButtonClicked(function(event)
            self.box:getAnimation():playWithIndex(0, -1, 0)
            -- self.box:getAnimation():gotoAndPause(85)
        end)
    self.box_bg = box
    self.box = ccs.Armature:create("lanse"):addTo(box)
        :align(display.CENTER, - 20, 10):scale(0.25)

    UIKit:ttfLabel({
        text = string.format("%d. %s", self.layer:CurrentPVEMap():GetIndex(), self.layer:CurrentPVEMap():Name()),
        size = 22,
        color = 0xffedae,
    }):addTo(top_bg):align(display.LEFT_CENTER, 130, 65)

    self.exploring = UIKit:ttfLabel({
        size = 16,
        color = 0xffedae,
    }):addTo(top_bg):align(display.LEFT_CENTER, 130, 45)
end

function GameUIPVEHome:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(City):addTo(self)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)
    WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)
    self.change_map = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.PVE):addTo(self)
end



return GameUIPVEHome









