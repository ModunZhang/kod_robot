local Localize_item = import("..utils.Localize_item")
local UILib = import("..ui.UILib")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetPVEGetRewards = class("WidgetPVEGetRewards", WidgetPopDialog)


function WidgetPVEGetRewards:ctor(reward, percent)
    WidgetPVEGetRewards.super.ctor(self, 414, _("完成奖励"), display.cy + 250)
    self.gemClass = reward.gemClass or "gemClass_1"
    self.count = reward.count or 1
    self.percent = percent or 0
end
function WidgetPVEGetRewards:onEnter()
    WidgetPVEGetRewards.super.onEnter(self)
    local s = self:GetBody():getContentSize()

    display.newSprite("pve_icon_airship.png"):addTo(self:GetBody())
        :pos(70, s.height - 90)

    UIKit:ttfLabel({text = _("关卡探索进度"), size = 20, color = 0x403c2f}):addTo(self:GetBody())
        :align(display.LEFT_CENTER, 130, s.height - 60)

    local pbg = display.newSprite("progress_bar_458x40_1.png"):addTo(self:GetBody())
        :align(display.LEFT_CENTER, 130, s.height - 120)
    local s2 = pbg:getContentSize()
    UIKit:commonProgressTimer("progress_bar_458x40_2.png"):addTo(pbg)
        :align(display.LEFT_CENTER, 0, s2.height/2):setPercentage(self.percent)

    UIKit:ttfLabel({text = string.format("%d%%", self.percent), size = 22, color = 0xffedae, shadow = true}):addTo(pbg,1)
        :align(display.CENTER, s2.width/2, s2.height/2)

    local bg = display.newSprite("pve_background_568x151.png"):addTo(self:GetBody())
        :pos(s.width/2, s.height - 230)
    local s3 = bg:getContentSize()

    display.newSprite("box_118x118.png"):addTo(bg):pos(75, s3.height/2)
    display.newSprite(UILib.item[self.gemClass]):addTo(bg):pos(75, s3.height/2):scale(0.8)

    UIKit:ttfLabel({
        text = Localize_item.item_name[self.gemClass].." x"..self.count, 
        size = 22, 
        color = 0x403c2f
        })
        :addTo(bg):align(display.LEFT_CENTER, 150, s3.height-35)

    UIKit:ttfLabel({
        text = _("探索进度达到100%可以领取，我看好你哟。"),
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(380, 70),
        margin = 1,
        lineHeight = 35,
    }):addTo(bg):align(display.LEFT_TOP, 150, s3.height-60)


    self.get_btn = cc.ui.UIPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png", disabled = "grey_btn_186x66.png"})
        :addTo(self:GetBody()):pos(s.width/2, 60)
        :setButtonLabel(UIKit:ttfLabel({text = _("领取"), size = 24, color = 0xffedae}))
        :onButtonClicked(function()
            User:ResetPveData()
            User:SetPveData(nil, {
                {
                    type = "items",
                    name = self.gemClass,
                    count = self.count,
                },
            }, nil)
            local data = User:EncodePveDataAndResetFightRewardsData()
            data.pveData.rewardedFloor = User:GetCurrentPVEMap():GetIndex()
            NetManager:getSetPveDataPromise(data):done(function()
                if display.getRunningScene().__cname == "PVEScene" then
                    display.getRunningScene():GetHomePage():RefreshRewards()
                end
                self:RefreshStatus()
                GameGlobalUI:showTips(_("获得奖励"), Localize_item.item_name[self.gemClass].."x"..self.count)
            end)

            self:LeftButtonClicked()
        end)
    self:RefreshStatus()
end
function WidgetPVEGetRewards:RefreshStatus()
    self.get_btn:setButtonEnabled(self.percent >= 100 and not User:GetCurrentPVEMap():IsRewarded())
    self.get_btn:setButtonLabelString(User:GetCurrentPVEMap():IsRewarded() and _("已领取") or _("领取"))
end





return WidgetPVEGetRewards



