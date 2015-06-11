local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetPVEGetTaskRewards = class("WidgetPVEGetTaskRewards", WidgetPopDialog)


function WidgetPVEGetTaskRewards:ctor(soldierName, count, percent)
    WidgetPVEGetTaskRewards.super.ctor(self, 414, _("完成奖励"), display.cy + 250)
    self.soldierName = soldierName or "ranger"
    self.coinClass = "coinClass_1"
    self.count = count or 2500
    self.percent = percent or 0
end
function WidgetPVEGetTaskRewards:onEnter()
    WidgetPVEGetTaskRewards.super.onEnter(self)
    local s = self:GetBody():getContentSize()

    local soldier_bg = display.newSprite("red_bg_128x128.png")
        :addTo(self:GetBody()):pos(70, s.height - 90):scale(0.8)
    local s1 = soldier_bg:getContentSize()
    display.newSprite(UILib.black_soldier_image[self.soldierName][2]):addTo(soldier_bg):pos(s1.width/2, s1.height/2)
    display.newSprite("box_soldier_128x128.png"):addTo(soldier_bg):pos(s1.width/2, s1.height/2)

    UIKit:ttfLabel({text = _("击杀进度:"), size = 20, color = 0x403c2f}):addTo(self:GetBody())
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
    display.newSprite(UILib.item[self.coinClass]):addTo(bg):pos(75, s3.height/2):scale(0.8)

    UIKit:ttfLabel({
        text = _("银币").." x "..GameUtils:formatNumber(self.count),
        size = 22,
        color = 0x403c2f
    }):addTo(bg):align(display.LEFT_CENTER, 150, s3.height-35)

    UIKit:ttfLabel({
        text = _("击杀完成之后可获得大量银币，加油哦。"),
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
            local target,ok = User:GetPVEDatabase():GetTarget()
            if ok and target.count >= target.target then
                User:ResetPveData()
                User:SetPveData(nil, {
                    {
                        type = "resources",
                        name = "coin",
                        count = self.count,
                    },
                }, nil)
                local data = User:EncodePveDataAndResetFightRewardsData()
                local count = self.count
                NetManager:getSetPveDataPromise(data):done(function()
                    GameGlobalUI:showTips(_("获得奖励"), Localize.fight_reward.coin.."x"..GameUtils:formatNumber(count))
                end)
                User:GetPVEDatabase():NewTarget()
                self:getParent():GetHomePage().event_tab:PromiseOfSwitch()
                self:LeftButtonClicked()
            end
        end):setButtonEnabled(false)
    self:RefreshStatus()
end
function WidgetPVEGetTaskRewards:RefreshStatus()
    local target,ok = User:GetPVEDatabase():GetTarget()
    if target.count >= target.target then
        self.get_btn:setButtonEnabled(true)
        self.get_btn:setButtonLabelString(_("领取"))
    end
end





return WidgetPVEGetTaskRewards




