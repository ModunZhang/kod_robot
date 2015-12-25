local GameUtils = GameUtils
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local WidgetSoldierDetails = import("..widget.WidgetSoldierDetails")
local UILib = import("..ui.UILib")
local StarBar = import("..ui.StarBar")
local WidgetSlider = import("..widget.WidgetSlider")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetTreatSoldier = class("WidgetTreatSoldier", function(...)
    local node = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
    node:setNodeEventEnabled(true)
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            node:blank_clicked()
        end
        return true
    end)
    return node
end)
local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special
local soldier_vs = GameDatas.ClientInitGame.soldier_vs
local app = app
local timer = app.timer

local SOLDIER_LOCALIZE_MAP = {
    ["infantry"] = _("步兵"),
    ["archer"] = _("弓手"),
    ["cavalry"] = _("骑兵"),
    ["siege"] = _("攻城"),
    ["wall"] = _("城墙"),
}

local function return_vs_soldiers_map(soldier_type)
    local strong_vs = {}
    local weak_vs = {}
    for k, v in pairs(soldier_vs[DataUtils:GetSoldierTypeByName(soldier_type)]) do
        if v == "strong" then
            table.insert(strong_vs, k)
        elseif v == "weak" then
            table.insert(weak_vs, k)
        end
    end
    return {strong_vs = strong_vs, weak_vs = weak_vs}
end

function WidgetTreatSoldier:ctor(soldier_type, star, treat_max)
    self.soldier_type = soldier_type
    self.treat_max = treat_max
    self.star = star

    local label_origin_x = 190

    -- bg
    local back_ground = WidgetUIBackGround.new({height=500}):addTo(self)

    back_ground:setTouchEnabled(true)

    -- title
    local size = back_ground:getContentSize()
    local title_blue = cc.ui.UIImage.new("title_blue_430x30.png"):addTo(back_ground, 2)
        :align(display.RIGHT_CENTER, size.width-10, size.height - 40)

    -- title label
    local size = title_blue:getContentSize()
    self.title = cc.ui.UILabel.new({
        size = 24,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(title_blue)
        :align(display.LEFT_CENTER, 10, size.height/2)
    -- info
    cc.ui.UIPushButton.new({normal = "i_btn_up_26x26.png",
        pressed = "i_btn_down_26x26.png"}):addTo(title_blue)
        :align(display.LEFT_CENTER, title_blue:getContentSize().width - 50, size.height/2)
        :onButtonClicked(function(event)
            WidgetSoldierDetails.new(self.soldier_type, self.star):addTo(self)
        end)

    -- soldier bg
    local size = back_ground:getContentSize()
    self.back_ground  = back_ground
    local width, height = 140, 130

    local size = back_ground:getContentSize()
    local label = cc.ui.UILabel.new({
        text = _("强势对抗"),
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x5bb800)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x -12, size.height - 85 - 11)

    local vs_map = return_vs_soldiers_map(soldier_type)
    local strong_vs = {}
    for i, v in ipairs(vs_map.strong_vs) do
        table.insert(strong_vs, SOLDIER_LOCALIZE_MAP[v])
    end
    local soldier_name = cc.ui.UILabel.new({
        text = table.concat(strong_vs, ", "),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x + label:getContentSize().width -12, size.height - 85 - 11)

    local label = cc.ui.UILabel.new({
        text = _("弱势对抗"),
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x890000)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x - 12, size.height - 120 - 11)

    local weak_vs = {}
    for i, v in ipairs(vs_map.weak_vs) do
        table.insert(weak_vs, SOLDIER_LOCALIZE_MAP[v])
    end
    local soldier_name = cc.ui.UILabel.new({
        text = table.concat(weak_vs, ", "),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x + label:getContentSize().width - 12, size.height - 120 - 11)


    -- food icon
    cc.ui.UIImage.new("res_food_91x74.png"):addTo(back_ground, 2)
        :align(display.CENTER, size.width - 153, size.height - 100):scale(0.4)

    cc.ui.UILabel.new({
        text = _("维护费"),
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x615b44)
    }):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, size.width - 100, size.height - 80)

    -- upkeep
    self.upkeep = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground, 2)
        :align(display.CENTER, size.width - 75, size.height - 110)


    -- progress
    self.slider_input = WidgetSliderWithInput.new({max = treat_max}):addTo(back_ground):align(display.LEFT_CENTER, 25, 330)
        :SetSliderSize(445, 24)
        :OnSliderValueChanged(function(event)
            self:OnCountChanged(math.floor(event.value))
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.RIGHT,20)



    -- need bg
    local need = WidgetUIBackGround.new({width=556,height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER,size.width/2, size.height/2 - 40):addTo(back_ground)


    -- needs
    local size = need:getContentSize()
    local margin_x = 120
    local length = size.width - margin_x * 2
    local origin_x, origin_y, gap_x = margin_x, 30, length / 3
    local res_map = {
        { "treatCoin", "res_coin_81x68.png" }
    }
    self.res_map = {}
    for i, v in pairs(res_map) do
        local res_type = v[1]
        local png = v[2]
        local x = 556/2
        local scale =  0.4
        cc.ui.UIImage.new(png):addTo(need, 2)
            :align(display.CENTER, x, size.height - origin_y):scale(scale)

        local total = cc.ui.UILabel.new({
            size = 20,
            font = UIKit:getFontFilePath(),
            align = cc.ui.TEXT_ALIGN_CENTER,
            color = UIKit:hex2c3b(0x403c2f)
        }):addTo(need, 2)
            :align(display.CENTER, x, size.height - origin_y - 36)

        local need = cc.ui.UILabel.new({
            size = 20,
            font = UIKit:getFontFilePath(),
            align = cc.ui.TEXT_ALIGN_CENTER,
            color = UIKit:hex2c3b(0x403c2f)
        -- color = display.COLOR_RED
        }):addTo(need, 2)
            :align(display.CENTER, x, size.height - origin_y - 56)

        self.res_map[res_type] = { total = total, need = need }
    end

    -- 立即治愈
    local size = back_ground:getContentSize()
    local instant_button = WidgetPushButton.new(
        {normal = "green_btn_up_250x66.png",pressed = "green_btn_down_250x66.png"},
        {scale9 = false},
        {
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(back_ground, 2)
        :align(display.CENTER, 160, 110)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("立即治愈"),
            size = 24,
            color = 0xfff3c7,
            shadow = true
        }))
        :onButtonClicked(function(event)
            local soldiers = {{name=self.soldier_type, count=self.count}}
            local treat_fun = function ()
                NetManager:getInstantTreatSoldiersPromise(soldiers)
                app:GetAudioManager():PlayeEffectSoundWithKey("INSTANT_TREATE_SOLDIER")
                self:instant_button_clicked()
            end
            if self.count<1 then
                UIKit:showMessageDialog(_("主人"),_("请设置要治愈的伤兵数"))
            elseif self.treat_now_gems > City:GetUser():GetGemValue() then
                UIKit:showMessageDialog(_("主人"),_("金龙币不足"))
                    :CreateOKButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                self:getParent():LeftButtonClicked()
                            end,
                            btn_name= _("前往商店")
                        })
            else
                if app:GetGameDefautlt():IsOpenGemRemind() then
                    UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                        string.formatnumberthousands(self.treat_now_gems)
                    ), function()
                        treat_fun()
                    end,true,true)
                else
                    treat_fun()
                end
            end
        end):SetFilter({
        disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })

    -- gem
    cc.ui.UIImage.new("gem_icon_62x61.png"):addTo(instant_button, 2)
        :align(display.CENTER, -100, -50):scale(0.5)

    -- gem count
    self.gem_label = cc.ui.UILabel.new({
        text = "600",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(instant_button, 2)
        :align(display.LEFT_CENTER, -100 + 20, -50)


    -- 治愈
    local button = WidgetPushButton.new(
        {normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"} ,
        {scale9 = false},
        {
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(back_ground, 2)
        :align(display.CENTER, size.width - 120, 110)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("治愈"),
            size = 24,
            color = 0xfff3c7,
            shadow = true

        }))
        :onButtonClicked(function(event)
            local soldiers = {{name=self.soldier_type, count=self.count}}
            local treat_fun = function ()
                NetManager:getTreatSoldiersPromise(soldiers)
                app:GetAudioManager():PlayeEffectSoundWithKey("TREATE_SOLDIER")
                self:button_clicked()
            end
            local isAbleToTreat, reason = User:CanTreat(soldiers)
            if self.count<1 then
                UIKit:showMessageDialog(_("主人"),_("请设置要治愈的伤兵数"))
            elseif City:GetUser():GetGemValue()< User:GetNormalTreatGems(soldiers) then
                UIKit:showMessageDialog(_("主人"),_("没有足够的金龙币补充资源"))
                    :CreateOKButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                self:getParent():LeftButtonClicked()
                            end,
                            btn_name= _("前往商店")
                        }
                    )
            elseif reason == "treating_and_lack_resource" then
                UIKit:showMessageDialog(_("主人"),_("正在治愈，资源不足"))
                    :CreateOKButtonWithPrice(
                        {
                            listener = treat_fun,
                            price = User:GetNormalTreatGems(soldiers)
                        }
                    )
                    :CreateCancelButton()
            elseif reason == "lack_resource" then
                UIKit:showMessageDialog(_("主人"),_("资源不足，是否花费金龙币补足"))
                    :CreateOKButtonWithPrice({
                        listener = treat_fun,
                        price = User:GetNormalTreatGems(soldiers)
                    })
                    :CreateCancelButton()
            elseif reason == "treating" then
                UIKit:showMessageDialog(_("主人"),_("正在治愈，是否花费魔法石立即完成"))
                    :CreateOKButtonWithPrice({
                        listener = treat_fun,
                        price = User:GetNormalTreatGems(soldiers)
                    })
                    :CreateCancelButton()
            else
                treat_fun()
            end
        end):SetFilter({
        disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })

    -- 时间glass
    cc.ui.UIImage.new("hourglass_30x38.png"):addTo(button, 2)
        :align(display.LEFT_CENTER, -90, -55):scale(0.7)

    -- 时间
    local center = -20
    self.treat_time = cc.ui.UILabel.new({
        -- text = "20:20:20",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(button, 2)
        :align(display.CENTER, center, -50)

    self.buff_treat_time = cc.ui.UILabel.new({
        text = "(-00:00:00)",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x068329)
    }):addTo(button, 2)
        :align(display.CENTER, center, -70)

    self.back_ground = back_ground
    local res_map = {}
    res_map.treatCoin = User:GetResValueByType("coin")
    for k, v in pairs(self.res_map) do
        local total = res_map[k]
        v.total:setString(GameUtils:formatNumber(total))
    end
    self.res_total_map = res_map
    self:SetSoldier(soldier_type, star)
    self:OnCountChanged(self:GetMaxTreatNum())
end
function WidgetTreatSoldier:onEnter()
    scheduleAt(self, function()
        local server_time = timer:GetServerTime()
        local res_map = {}
        res_map.treatCoin = User:GetResValueByType("coin")
        for k, v in pairs(self.res_map) do
            local total = res_map[k]
            v.total:setString(GameUtils:formatNumber(total))
        end
        self.res_total_map = res_map
        if not self.isSet then
            self.slider_input:SetValue(self:GetMaxTreatNum())
            self.isSet = true
        end
    end)
    User:AddListenOnType(self, "soldierStars")
end
function WidgetTreatSoldier:onExit()
    User:RemoveListenerOnType(self, "soldierStars")
end
function WidgetTreatSoldier:SetSoldier(soldier_type, star)
    local soldier_config, soldier_ui_config = self:GetConfigBySoldierTypeAndStar(soldier_type, star)
    -- title
    self.title:setString(Localize.soldier_name[soldier_type])


    display.newSprite(UILib.soldier_color_bg_images[self.soldier_type]):addTo(self.back_ground)
        :align(display.CENTER,  86, self.back_ground:getContentSize().height-86):scale(130/128)
    self.soldier = cc.ui.UIPushButton.new({normal = soldier_ui_config,
        pressed = soldier_ui_config}):addTo(self.back_ground)
        :align(display.CENTER, 86, self.back_ground:getContentSize().height - 86)
        :onButtonClicked(function(event)
            WidgetSoldierDetails.new(self.soldier_type, self.star):addTo(self)
        end)
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(self.soldier):align(display.BOTTOM_CENTER,-10, -60)
    display.newSprite("i_icon_20x20.png"):addTo(soldier_star_bg):align(display.LEFT_CENTER,5, 11)
    self.soldier_star = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = star,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(soldier_star_bg):align(display.CENTER,58, 11)

    local rect = self.soldier:getCascadeBoundingBox()
    display.newSprite("box_soldier_128x128.png"):addTo(self.soldier):align(display.CENTER, 0,0)
    self.soldier_config = soldier_config
    self.soldier_ui_config = soldier_ui_config
    return self
end
function WidgetTreatSoldier:GetMaxTreatNum()
    local soldier_config = self.soldier_config
    local total = User:GetResValueByType("coin")
    local temp_max = math.floor(total / soldier_config.treatCoin)
    local max_count = math.min(self.treat_max,temp_max)
    return max_count
end
function WidgetTreatSoldier:OnUserDataChanged_soldierStars(userData, deltaData)
    local ok, value = deltaData("soldierStars")
    if ok then
        for soldier_name,star in pairs(value) do
            if soldier_name == self.soldier_type then
                self.star =  star
                local soldier_config, soldier_ui_config = self:GetConfigBySoldierTypeAndStar(soldier_name, self.star)
                self.soldier:setButtonImage(cc.ui.UIPushButton.NORMAL, soldier_ui_config, true)
                self.soldier:setButtonImage(cc.ui.UIPushButton.PRESSED, soldier_ui_config, true)
                self.soldier_star:setNum(self.star)
                self.soldier_config = soldier_config
                self.soldier_ui_config = soldier_ui_config
            end
        end
    end
end
function WidgetTreatSoldier:GetConfigBySoldierTypeAndStar(soldier_type, star)
    local soldier_type_with_star = soldier_type..(star == nil and "" or string.format("_%d", star))
    local soldier_config = NORMAL[soldier_type_with_star] == nil and SPECIAL[soldier_type] or NORMAL[soldier_type_with_star]
    local soldier_ui_config = UILib.soldier_image[soldier_type]
    return soldier_config, soldier_ui_config
end
function WidgetTreatSoldier:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint, x, y)
    return self
end
function WidgetTreatSoldier:OnInstantButtonClicked(func)
    self.instant_button_clicked = func
    return self
end
function WidgetTreatSoldier:OnNormalButtonClicked(func)
    self.button_clicked = func
    return self
end
function WidgetTreatSoldier:OnBlankClicked(func)
    self.blank_clicked = func
    return self
end
function WidgetTreatSoldier:OnCountChanged(count)
    local soldier_config = self.soldier_config
    local soldier_ui_config = self.soldier_ui_config
    local total_time = soldier_config.treatTime * count
    self.upkeep:setString(string.format("%s%d/".._("小时"), count > 0 and "-" or "", soldier_config.consumeFoodPerHour * count))
    self.treat_time:setString(GameUtils:formatTimeStyle1(total_time))
    self.buff_treat_time:setString("(-"..GameUtils:formatTimeStyle1(User:GetTechReduceTreatTime(total_time))..")")

    local total_map = self.res_total_map == nil and {} or self.res_total_map
    local current_res_map = {}
    for k, v in pairs(self.res_map) do
        local total = total_map[k] == nil and 0 or total_map[k]
        local current = soldier_config[k] * count
        local rs_k = "coin"
        current_res_map[rs_k] = current
        local color = total >= current and UIKit:hex2c3b(0x403c2f) or display.COLOR_RED
        v.need:setString(string.format("/ %s", GameUtils:formatNumber(current)))
        v.total:setColor(color)
        v.need:setColor(color)
    end
    self.count = count
    self.treat_now_gems = DataUtils:buyResource(current_res_map, {}) + DataUtils:getGemByTimeInterval(total_time)
    self.gem_label:setString(self.treat_now_gems)
end
return WidgetTreatSoldier








































