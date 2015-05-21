local GameUtils = GameUtils
local cocos_promise = import("..utils.cocos_promise")
local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local MaterialManager = import("..entity.MaterialManager")
local SoldierManager = import("..entity.SoldierManager")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local WidgetSoldierDetails = import('..widget.WidgetSoldierDetails')
local WidgetRecruitSoldier = class("WidgetRecruitSoldier", function(...)
    local node = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
    node:setNodeEventEnabled(true)
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            if type(node.blank_clicked) == "function" then
                node:blank_clicked()
            end
            node:Close()
        end
        return true
    end)
    return node
end)
local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special
local soldier_vs = GameDatas.ClientInitGame.soldier_vs
local function return_vs_soldiers_map(soldier_name)
    local strong_vs = {}
    local weak_vs = {}
    for k, v in pairs(soldier_vs[GameUtils:GetSoldierTypeByName(soldier_name)]) do
        if v == "strong" then
            table.insert(strong_vs, k)
        elseif v == "weak" then
            table.insert(weak_vs, k)
        end
    end
    return {strong_vs = strong_vs, weak_vs = weak_vs}
end
function WidgetRecruitSoldier:ctor(barracks, city, soldier_name, soldier_star)
    UIKit:RegistUI(self)
    self.barracks = barracks
    self.soldier_name = soldier_name
    self.star = soldier_star or city:GetSoldierManager():GetStarBySoldierType(soldier_name)
    local soldier_config, aaa = self:GetConfigBySoldierTypeAndStar(soldier_name, self.star)
    self.recruit_max = barracks:GetMaxRecruitSoldierCount()
    if soldier_config.citizen ~= 0 then
        self.recruit_max = math.floor(barracks:GetMaxRecruitSoldierCount()/soldier_config.citizen)
    end
    self.city = city

    local label_origin_x = 190
    -- bg
    local back_ground = WidgetUIBackGround.new({height=500,isFrame="yes"})
        :addTo(self):align(display.BOTTOM_CENTER, display.cx, 0)
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
            WidgetSoldierDetails.new(soldier_name, self.star):addTo(self)
        end)

    -- soldier bg
    local size = back_ground:getContentSize()
    self.back_ground = back_ground

    --
    local size = back_ground:getContentSize()
    local label = cc.ui.UILabel.new({
        text = _("强势对抗"),
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x5bb800)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x -12 , size.height - 85 - 11)

    local vs_map = return_vs_soldiers_map(soldier_name)
    local strong_vs = {}
    for i, v in ipairs(vs_map.strong_vs) do
        table.insert(strong_vs, Localize.soldier_category[v])
    end
    local soldier_name = cc.ui.UILabel.new({
        text = table.concat(strong_vs, ", "),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x + label:getContentSize().width - 12, size.height - 85 - 11)

    local label = cc.ui.UILabel.new({
        text = _("弱势对抗"),
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x890000)
    }):addTo(back_ground, 2)
        :align(display.LEFT_BOTTOM, label_origin_x-12, size.height - 120 - 11)

    local weak_vs = {}
    for i, v in ipairs(vs_map.weak_vs) do
        table.insert(weak_vs, Localize.soldier_category[v])
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
        :align(display.CENTER, size.width - 133, size.height - 100):scale(0.4)

    cc.ui.UILabel.new({
        text = _("维护费"),
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x615b44)
    }):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, size.width - 100, size.height - 90)

    -- upkeep
    self.upkeep = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground, 2)
        :align(display.CENTER, size.width - 75, size.height - 120)


    -- need bg
    local need =  WidgetUIBackGround.new({width=556,height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER,size.width/2, size.height/2 - 40):addTo(back_ground)

    -- needs
    local size = need:getContentSize()
    self.res_map = {}
    if soldier_config.specialMaterials then
        local margin_x = 100
        local length = size.width - margin_x * 2
        local origin_x, origin_y, gap_x = margin_x, 32, length / 3
        local specialMaterials = string.split(soldier_config.specialMaterials,",")
        table.insert(specialMaterials, { "citizen", "res_citizen_88x82.png" })
        for k,v in pairs(specialMaterials) do
            local x = origin_x + (k - 1) * gap_x
            local need_image,res_type
            if tolua.type(v) ~= "table" then
                local tmp = string.split(v, "_")
                need_image = UILib.soldier_metarial[tmp[1]]
                res_type = v
            else
                res_type = v[1]
                need_image = v[2]
            end
            if res_type ~= "citizen" then
                local icon_bg = cc.ui.UIImage.new("box_118x118.png"):addTo(need, 2)
                    :align(display.CENTER, x, size.height - origin_y)
                icon_bg:scale(46/icon_bg:getContentSize().width)
            end
            local icon_iamge = cc.ui.UIImage.new(need_image):addTo(need, 2)
                :align(display.CENTER, x, size.height - origin_y)
            icon_iamge:scale(38/icon_iamge:getContentSize().width)
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
    else
        local margin_x = 80
        local length = size.width - margin_x * 2
        local origin_x, origin_y, gap_x = margin_x, 30, length / 4
        local res_map = {
            { "food", "res_food_91x74.png" },
            { "wood", "res_wood_82x73.png" },
            { "iron", "res_iron_91x63.png" },
            { "stone", "res_stone_88x82.png" },
            { "citizen", "res_citizen_88x82.png" },
        }
        for i, v in pairs(res_map) do
            local res_type = v[1]
            local png = v[2]
            local x = origin_x + (i - 1) * gap_x
            local scale = 0.5
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
    end

    local slider_input = WidgetSliderWithInput.new({max = self.recruit_max,min=1}):addTo(back_ground):align(display.LEFT_CENTER, 25, 330)
        :SetSliderSize(445, 24)
        :OnSliderValueChanged(function(event)
            self:OnCountChanged(math.floor(event.value))
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.RIGHT,0)
    self.slider_input = slider_input

    local ok = self:GetRecruitSpecialTime()
    if ok or not soldier_config.specialMaterials then
        self:AddButtons()
    else
        -- 招募时间限制
        local time_bg = display.newSprite("back_ground_548X34.png")
            :align(display.BOTTOM_CENTER, back_ground:getContentSize().width/2, 50)
            :addTo(back_ground)
        local ok,time = self:GetRecruitSpecialTime()
        local re_string = ""
        if ok then
            re_string = _("招募开启中")
        else
            re_string = _("下一次开启招募:")..GameUtils:formatTimeStyle1(time-app.timer:GetServerTime())
        end
        self.re_status = UIKit:ttfLabel({
            text = re_string,
            size = 20,
            color = 0x514d3e
        }):addTo(time_bg)
            :align(display.CENTER, time_bg:getContentSize().width/2,time_bg:getContentSize().height/2)
    end


    self.back_ground = back_ground
end
function WidgetRecruitSoldier:AddButtons()
    local back_ground = self.back_ground
    local size = back_ground:getContentSize()
    local instant_button = WidgetPushButton.new(
        {normal = "green_btn_up_250x65.png",pressed = "green_btn_down_250x65.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(back_ground, 2)
        :align(display.CENTER, 160, 110)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("立即招募"),
            size = 24,
            color = 0xfff3c7,
            shadow = true
        }))
        :onButtonClicked(function(event)
            if City:GetUser():GetGemResource():GetValue()< tonumber(self.gem_label:getString())then
                UIKit:showMessageDialog(_("陛下"),_("您当前没有足够金龙币")):CreateOKButton(
                    {
                        listener = function ()
                            UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            self:Close()
                        end,
                        btn_name= _("前往商店")
                    }
                )
                return
            end

            if SPECIAL[self.soldier_name] then
                local not_enough_material = self:CheckMaterials(self.count)
                if not_enough_material then
                    UIKit:showMessageDialog(_("招募材料不足"),_("您当前没有足够材料"))
                else
                    NetManager:getInstantRecruitSpecialSoldierPromise(self.soldier_name, self.count)
                end
            else
                NetManager:getInstantRecruitNormalSoldierPromise(self.soldier_name, self.count)
            end

            if type(self.instant_button_clicked) == "function" then
                self:instant_button_clicked()
            end
            self:Close()
        end)
    self.instant_button = instant_button

    -- gem
    cc.ui.UIImage.new("gem_icon_62x61.png"):addTo(instant_button, 2)
        :align(display.CENTER, -100, -50):scale(0.5)

    -- gem count
    self.gem_label = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(instant_button, 2)
        :align(display.LEFT_CENTER, -100 + 20, -50)


    -- 招募
    self.normal_button = WidgetPushButton.new(
        {normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(back_ground, 2)
        :align(display.CENTER, size.width - 120, 110)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("招募"),
            size = 27,
            color = 0xfff3c7,
            shadow = true
        }))
        :onButtonClicked(function(event)
            local current_time = app.timer:GetServerTime()
            local left_time = self.barracks:GetRecruitEvent():LeftTime(current_time)
            local queue_need_gem = self.barracks:IsRecruting()
                and DataUtils:getGemByTimeInterval(left_time) or 0

            if SPECIAL[self.soldier_name] then
                local not_enough_material = self:CheckMaterials(self.count)
                local required_gems = DataUtils:buyResource(self:GetNeedResouce(self.count), {})
                if not_enough_material then
                    UIKit:showMessageDialog(_("招募材料不足"), _("您当前没有足够材料"))
                elseif queue_need_gem + required_gems > 0 then
                    local title = string.format("%s/%s", queue_need_gem > 0 and _("队列不足") or "", required_gems > 0 and _("资源不足") or "")
                    local content = string.format("%s%s%s", queue_need_gem > 0 and _("您当前没有足够的队列") or "", required_gems > 0 and _("您当前没有足够的资源") or "", _("是否花费魔法石立即补充"))

                    UIKit:showMessageDialog(title, content,function()
                        NetManager:getRecruitSpecialSoldierPromise(self.soldier_name, self.count)
                        self:Close()
                    end):CreateNeeds({value = queue_need_gem + required_gems})
                else
                    NetManager:getRecruitSpecialSoldierPromise(self.soldier_name, self.count)
                    self:Close()
                end
            else
                local required_gems = DataUtils:buyResource(self:GetNeedResouce(self.count), {})
                if queue_need_gem + required_gems > 0 then
                    local title = string.format("%s/%s", queue_need_gem > 0 and _("队列不足") or "", required_gems > 0 and _("资源不足") or "")
                    local content = string.format("%s%s%s", queue_need_gem > 0 and _("您当前没有足够的队列") or "", required_gems > 0 and _("您当前没有足够的资源") or "", _("是否花费魔法石立即补充"))
                    UIKit:showMessageDialog(title, content,function()
                        NetManager:getRecruitNormalSoldierPromise(self.soldier_name, self.count)
                        self:Close()
                    end):CreateNeeds({value = queue_need_gem + required_gems})
                else
                    NetManager:getRecruitNormalSoldierPromise(self.soldier_name, self.count)
                    self:Close()
                end
            end
        end)
    local anchorNode = display.newNode():addTo(back_ground, 3):pos(size.width - 120, 110)

    -- 时间glass
    cc.ui.UIImage.new("hourglass_30x38.png"):addTo(self.normal_button, 2)
        :align(display.LEFT_CENTER, -90, -55):scale(0.7)

    -- 时间
    local center = -20
    self.recruit_time = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(anchorNode, 2)
        :align(display.CENTER, center, -50)

    self.recruit_buff_time = cc.ui.UILabel.new({
        text = "(-00:00:00)",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x068329)
    }):addTo(anchorNode, 2)
        :align(display.CENTER, center, -70)
end
function WidgetRecruitSoldier:onEnter()
    self:SetSoldier(self.soldier_name, self.star)
    self.count = 1

    self.barracks:AddBarracksListener(self)
    self.city:GetResourceManager():AddObserver(self)

    self:OnResourceChanged(self.city:GetResourceManager())
    self:OnCountChanged(self.count)
    local max = self:GetCurrentMaxRecruitNum(self.res_total_map)
    self.slider_input:SetValue(max)

    self.city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    app.timer:AddListener(self)

    if #WidgetRecruitSoldier.open_callbacks > 0 then
        table.remove(WidgetRecruitSoldier.open_callbacks, 1)(self)
    end
end
function WidgetRecruitSoldier:onExit()
    self.barracks:RemoveBarracksListener(self)
    self.city:GetResourceManager():RemoveObserver(self)
    app.timer:RemoveListener(self)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    UIKit:getRegistry().removeObject(self.__cname)
end
function WidgetRecruitSoldier:OnTimer(current_time)
    if self.re_status then
        local ok,time = self:GetRecruitSpecialTime()
        if ok then
            self.re_status:setString(_("招募开启中"))
        else
            self.re_status:setString(_("下一次开启招募:")..GameUtils:formatTimeStyle1(time-current_time))
        end
    end
end
function WidgetRecruitSoldier:SetSoldier(soldier_name, star)
    local soldier_config, soldier_ui_config = self:GetConfigBySoldierTypeAndStar(soldier_name, star)
    -- title
    self.title:setString(Localize.soldier_name[soldier_name])

    display.newSprite(UILib.soldier_color_bg_images[soldier_name]):addTo(self.back_ground)
        :align(display.CENTER,84, self.back_ground:getContentSize().height - 84)

    self.soldier = cc.ui.UIPushButton.new({normal = soldier_ui_config,
        pressed = soldier_ui_config}):addTo(self.back_ground)
        :align(display.CENTER, 84, self.back_ground:getContentSize().height - 84)
        :onButtonClicked(function(event)
            WidgetSoldierDetails.new(soldier_name, self.star):addTo(self)
        end)

    local rect = self.soldier:getCascadeBoundingBox()
    display.newSprite("box_soldier_128x128.png"):addTo(self.soldier):align(display.CENTER, 0,0)


    self.soldier_config = soldier_config
    self.soldier_ui_config = soldier_ui_config
    return self
end
function WidgetRecruitSoldier:GetConfigBySoldierTypeAndStar(soldier_name, star)
    local soldier_name_with_star = soldier_name..(star == nil and "" or string.format("_%d", star))
    local soldier_config = NORMAL[soldier_name_with_star] == nil and SPECIAL[soldier_name] or NORMAL[soldier_name_with_star]
    local soldier_ui_config = UILib.soldier_image[soldier_name][star]
    return soldier_config, soldier_ui_config
end
function WidgetRecruitSoldier:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint, x, y)
    return self
end
local app = app
local timer = app.timer
function WidgetRecruitSoldier:OnResourceChanged(resource_manager)
    local server_time = timer:GetServerTime()
    local res_map = {}
    if not self.soldier_config.specialMaterials then
        res_map.wood = resource_manager:GetWoodResource():GetResourceValueByCurrentTime(server_time)
        res_map.food = resource_manager:GetFoodResource():GetResourceValueByCurrentTime(server_time)
        res_map.iron = resource_manager:GetIronResource():GetResourceValueByCurrentTime(server_time)
        res_map.stone = resource_manager:GetStoneResource():GetResourceValueByCurrentTime(server_time)
        res_map.citizen = resource_manager:GetPopulationResource():GetNoneAllocatedByTime(server_time)
    else
        res_map.citizen = resource_manager:GetPopulationResource():GetNoneAllocatedByTime(server_time)
    end
    self.res_total_map = res_map
    self:CheckNeedResource(res_map, self.count)
end
function WidgetRecruitSoldier:OnBeginRecruit()

end
function WidgetRecruitSoldier:OnRecruiting()

end
function WidgetRecruitSoldier:OnEndRecruit()
    local enable = self.count > 0
    -- self.normal_button:setButtonEnabled(self.barracks:IsRecruitEventEmpty() and enable)
end
function WidgetRecruitSoldier:OnInstantButtonClicked(func)
    self.instant_button_clicked = func
    return self
end
function WidgetRecruitSoldier:OnNormalButtonClicked(func)
    self.button_clicked = func
    return self
end
function WidgetRecruitSoldier:OnBlankClicked(func)
    self.blank_clicked = func
    return self
end
function WidgetRecruitSoldier:Close()
    self:removeFromParent()
    return self
end
function WidgetRecruitSoldier:OnCountChanged(count)
    -- 数量和时间
    local soldier_config = self.soldier_config
    local soldier_ui_config = self.soldier_ui_config
    local total_time = soldier_config.recruitTime * count
    -- self.soldier_current_count:setString(string.format("%d", count))
    self.upkeep:setString(string.format("%s%d/%s", count > 0 and "-" or "", soldier_config.consumeFoodPerHour * count, _("小时")))
    -- 检查资源
    local need_resource = self:CheckNeedResource(self.res_total_map, count)
    self.count = count

    local ok = self:GetRecruitSpecialTime()
    if ok or not soldier_config.specialMaterials then
        -- 按钮
        local enable = count > 0
        self.instant_button:setButtonEnabled(enable)
        self.recruit_time:setString(GameUtils:formatTimeStyle1(total_time))
        local buff_str = string.format("(-%s)", GameUtils:formatTimeStyle1(DataUtils:getSoldierRecruitBuffTime(soldier_config.type,total_time)))
        self.recruit_buff_time:setString(buff_str)
        local gem_resource, buy = DataUtils:buyResource(need_resource, {})
        local gem_time = DataUtils:getGemByTimeInterval(total_time-DataUtils:getSoldierRecruitBuffTime(soldier_config.type,total_time))
        self.gem_label:setString(gem_resource + gem_time)
    end

end
function WidgetRecruitSoldier:CheckNeedResource(total_resouce, count)
    local soldier_config = self.soldier_config
    local current_res_map = {}
    local total_map = total_resouce
    for k, v in pairs(self.res_map) do
        local total,current
        if soldier_config.specialMaterials then
            if k == "citizen" then
                total = total_map[k] == nil and 0 or total_map[k]
                current = soldier_config[k] * count
                current_res_map[k] = current
            else
                local temp = string.split(k, "_")
                total = self.city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.SOLDIER)[temp[1]]
                current = count * tonumber(temp[2])
            end
        else
            total = total_map[k] == nil and 0 or total_map[k]
            current = soldier_config[k] * count
            current_res_map[k] = current
        end
        local color = total >= current
            -- and UIKit:hex2c3b(0x403c2f)
            and display.COLOR_BLUE
            or display.COLOR_RED
        v.total:setString(string.format("%s", GameUtils:formatNumber(total)))
        -- v.total:setColor(color)
        v.need:setString(string.format("/ %s", GameUtils:formatNumber(current)))
        v.need:setColor(color)
    end
    return current_res_map
end
function WidgetRecruitSoldier:GetCurrentMaxRecruitNum(total_resouce)
    local soldier_config = self.soldier_config
    local total_map = total_resouce
    local max_count = math.huge
    for k, v in pairs(self.res_map) do
        local total,temp_max
        if soldier_config.specialMaterials then
            if k == "citizen" then
                total = total_map[k] == nil and 0 or total_map[k]
                temp_max = math.floor(total / soldier_config[k])
            else
                local temp = string.split(k, "_")
                total = self.city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.SOLDIER)[temp[1]]
                temp_max = math.floor(total/tonumber(temp[2]))
            end
        else
            total = total_map[k] == nil and 0 or total_map[k]
            temp_max = math.floor(total / soldier_config[k])
        end
        max_count = math.min(max_count,temp_max)
    end
    max_count = math.min(max_count,self.recruit_max)
    max_count = max_count == 0 and 1 or max_count
    return max_count
end
function WidgetRecruitSoldier:GetNeedResouce(count)
    local soldier_config = self.soldier_config
    local need_res_map = {}
    if  soldier_config.specialMaterials then
        local left = self.res_total_map["citizen"] - soldier_config["citizen"] * count
        need_res_map["citizen"] = left >= 0 and 0 or -left
    else
        for res_type, value in pairs(self.res_total_map) do
            local left = value - soldier_config[res_type] * count
            need_res_map[res_type] = left >= 0 and 0 or -left
        end
    end
    return need_res_map
end
function WidgetRecruitSoldier:CheckMaterials(count)
    local soldier_config = self.soldier_config
    if soldier_config.specialMaterials then
        local specialMaterials = string.split(soldier_config.specialMaterials,",")
        for k,v in pairs(specialMaterials) do
            local temp = string.split(v, "_")
            local total = self.city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.SOLDIER)[temp[1]]
            if total< count then
                return v
            end
        end
    end
end
function WidgetRecruitSoldier:OnSoliderStarCountChanged(soldier_manager,star_changed_map)
    for i,v in pairs(star_changed_map) do
        if v == self.soldier_name then
            self.star =  soldier_manager:GetStarBySoldierType(v)
            local soldier_config, soldier_ui_config = self:GetConfigBySoldierTypeAndStar(soldier_name, self.star)
            self.soldier:setButtonImage(cc.ui.UIPushButton.NORMAL, soldier_ui_config, true)
            self.soldier:setButtonImage(cc.ui.UIPushButton.PRESSED, soldier_ui_config, true)
            self.soldier_config = soldier_config
            self.soldier_ui_config = soldier_ui_config
        end
    end
end

-- fte
local mockData = import("..fte.mockData")
local promise = import("..utils.promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
WidgetRecruitSoldier.open_callbacks = {}
function WidgetRecruitSoldier:PormiseOfOpen()
    local p = promise.new()
    WidgetRecruitSoldier.open_callbacks = {}
    table.insert(WidgetRecruitSoldier.open_callbacks, function(ui)
        p:resolve(ui)
    end)
    return p
end
function WidgetRecruitSoldier:Find()
    return self.normal_button
end
function WidgetRecruitSoldier:PormiseOfFte()
    local fte_layer = self:getParent():GetFteLayer()
    fte_layer:Enable():SetTouchObject(self:Find())

    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        self:Find():setButtonEnabled(false)

        mockData.RecruitSoldier(self.soldier_name, self.count)

        self:Close()
    end)

    local r = self:Find():getBoundingBox()
    WidgetFteArrow.new(_("立即开始招募，招募士兵会消耗城民")):addTo(fte_layer)
        :TurnRight():align(display.RIGHT_CENTER, r.x - 20, r.y + r.height/2)

    return self.city:PromiseOfRecruitSoldier("swordsman"):next(function()
        fte_layer:removeFromParent()
    end)
end

function WidgetRecruitSoldier:PromiseOfFteSpecial()
    self:AddButtons()
    self:OnCountChanged(self.count)
    local fte_layer = self:getParent():GetFteLayer()
    fte_layer:Enable():SetTouchObject(self:Find())

    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        self:Find():setButtonEnabled(false)

        mockData.RecruitSoldier(self.soldier_name, self.count)

        self:Close()
    end)

    local r = self:Find():getBoundingBox()
    WidgetFteArrow.new(_("点击招募")):addTo(fte_layer)
        :TurnRight():align(display.RIGHT_CENTER, r.x - 20, r.y + r.height/2)

    return self.city:PromiseOfRecruitSoldier("skeletonWarrior"):next(function()
        fte_layer:removeFromParent()
    end)
end

function WidgetRecruitSoldier:GetRecruitSpecialTime()
    local re_time = DataUtils:GetNextRecruitTime()
    return tolua.type(re_time) == "boolean", re_time
end


return WidgetRecruitSoldier











