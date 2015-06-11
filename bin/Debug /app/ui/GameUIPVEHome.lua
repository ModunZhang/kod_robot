local WidgetChangeMap = import("..widget.WidgetChangeMap")
local UIPageView = import("..ui.UIPageView")
local UILib = import("..ui.UILib")
local Localize_item = import("..utils.Localize_item")
local window = import("..utils.window")
local GameUIPVEHome = UIKit:createUIClass('GameUIPVEHome')
local WidgetPVEGetRewards = import("..widget.WidgetPVEGetRewards")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetUseItems = import("..widget.WidgetUseItems")
local ChatManager = import("..entity.ChatManager")
local WidgetChat = import("..widget.WidgetChat")
local light_gem = import("..particles.light_gem")
local WidgetPVEEvent = import("..widget.WidgetPVEEvent")
local pve_level = GameDatas.ClientInitGame.pve_level
local timer = app.timer


function GameUIPVEHome:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIPVEHome:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIPVEHome:FadeToSelf(isFullDisplay)
    self:stopAllActions()
    if isFullDisplay then
        self:show()
        transition.fadeIn(self, {
            time = 0.2,
        })
    else
        transition.fadeOut(self, {
            time = 0.2,
            onComplete = function()
                self:hide()
            end,
        })
    end
end


function GameUIPVEHome:ctor(user, scene)
    self.user = user
    self.layer = scene:GetSceneLayer()
    GameUIPVEHome.super.ctor(self, {type = UIKit.UITYPE.BACKGROUND})
end
function GameUIPVEHome:onEnter()
    self.visible_count = 1
    self:CreateTop()
    self.bottom = self:CreateBottom()

    local ratio = self.bottom:getScale()
    self.event_tab = WidgetPVEEvent.new(self.user, ratio)
    local rect1 = self.chat:getCascadeBoundingBox()
    local x, y = rect1.x, rect1.y + rect1.height - 2
    self.event_tab:addTo(self):pos(x, y)

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
    self.exploring:setString(string.format(_("探索度 %.2f%%"), pve_layer:ExploreDegree() * 100))
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
        UIKit:newGameUI('GameUIStore'):AddToCurrentScene(true)
    end):addTo(top_bg):align(display.RIGHT_TOP, size.width - 45, 85)
    local gem_icon = cc.ui.UIImage.new("gem_icon_62x61.png"):addTo(gem_button):pos(-60, -62)
    light_gem():addTo(gem_icon, 1022):pos(62/2, 61/2)

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

    local reward_btn = cc.ui.UIPushButton.new(
        {normal = "back_ground_box.png", pressed = "back_ground_box.png"}
        ,{})
        :addTo(top_bg, 1):align(display.CENTER, 80, 55):scale(0.8)
        :onButtonClicked(function(event)
            local reward = pve_level[self.layer:CurrentPVEMap():GetIndex()]
            WidgetPVEGetRewards.new({gemClass = self:GetRewardItemName(), count = reward.count}, self.layer:ExploreDegree() * 100):AddToCurrentScene(true)
        end)

    self.reward = display.newSprite(UILib.item[self:GetRewardItemName()],nil,nil,{class=cc.FilteredSpriteWithOne})
        :addTo(reward_btn):scale(0.6)
    local s = self.reward:getContentSize()
    light_gem():addTo(self.reward, 10):pos(s.width/2, s.height/2)
    self:RefreshRewards()




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

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)

    self.change_map = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.PVE):addTo(self)

    return bottom_bg
end

-- function GameUIPVEHome:SetBoxStatus(can_get)
--     self.box:show()
--     self.box_bg:setButtonEnabled(can_get)
--     if can_get then
--         self.box:getAnimation():stop()
--     else
--         self.box:getAnimation():playWithIndex(0)
--         self.box:getAnimation():gotoAndPause(85)
--     end
-- end
function GameUIPVEHome:GetRewards()
-- local index = self.layer:CurrentPVEMap():GetIndex()
-- local rewards = GameDatas.PlayerInitData.pveLevel[index]
-- local _1,name = unpack(string.split(rewards.itemName, ":"))
-- self.user:ResetPveData()
-- self.user:SetPveData(nil, {
--     {
--         type = "items",
--         name = name,
--         count = rewards.count,
--     },
-- }, nil)
-- local data = self.user:EncodePveDataAndResetFightRewardsData()
-- data.pveData.rewardedFloor = index
-- NetManager:getSetPveDataPromise(data):done(function()
--     local wp = self.box:getParent():convertToWorldSpace(cc.p(self.box:getPosition()))
--     UIKit:newGameUI("GameUIPveGetRewards", wp.x, wp.y):AddToCurrentScene(true)
--         :AddClickOutFunc(function(ui)
--             ui:LeftButtonClicked()
--             self:SetBoxStatus(not self.layer:CurrentPVEMap():IsRewarded())
--             GameGlobalUI:showTips(_("获得奖励"), Localize_item.item_name[name].."x"..rewards.count)
--         end)
-- end)
end
function GameUIPVEHome:RefreshRewards()
    self.reward:setTexture(UILib.item[self:GetRewardItemName()])
    if self.layer:CurrentPVEMap():IsRewarded() then
        self.reward:setFilter(filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1}))
        self.reward:removeAllChildren()
    else
        self.reward:clearFilter()
    end
end
function GameUIPVEHome:GetRewardItemName()
    local reward = pve_level[self.layer:CurrentPVEMap():GetIndex()]
    local _,itemName = unpack(string.split(reward.itemName, ":"))
    return itemName
end



return GameUIPVEHome









