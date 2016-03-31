--
-- Author: Kenny Dai
-- Date: 2016-03-04 19:59:55
--
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetPushButton = import(".WidgetPushButton")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetSliderWithInput = import(".WidgetSliderWithInput")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local UILib = import("..ui.UILib")
local StarBar = import("..ui.StarBar")
local UIListView = import("..ui.UIListView")


local WidgetSelectSoldiers = class("WidgetSelectSoldiers", WidgetPopDialog)

function WidgetSelectSoldiers:ctor(max_citizen,isDefence,callback,settingSoldiers,index_soldiers,index)
    WidgetSelectSoldiers.super.ctor(self,704,_("选择兵种"))
    self.max_citizen = max_citizen
    self.isDefence = isDefence -- 是否为驻防士兵操作
    self.callback = callback
    self.settingSoldiers = settingSoldiers
    self.index_soldiers = index_soldiers -- 当前配置的士兵格子已经配置的士兵
    self.index = index -- 当前配置的士兵格子index
end

function WidgetSelectSoldiers:onEnter()
    WidgetSelectSoldiers.super.onEnter(self)
    self:SoldiersList()
end

function WidgetSelectSoldiers:SoldiersList()
    local body = self.body
    local rb_size = body:getContentSize()
    local list ,listnode =  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 570),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:align(display.BOTTOM_CENTER)
    listnode:addTo(body):pos(rb_size.width/2, 100)
    self.soldier_listview = list

    local soldiers = {}
    local soldier_map = {
        "swordsman_1",
        "ranger_1",
        "lancer_1",
        "catapult_1",
        "sentinel_1",
        "crossbowman_1",
        "horseArcher_1",
        "ballista_1",
        "swordsman_2",
        "ranger_2",
        "lancer_2",
        "catapult_2",
        "sentinel_2",
        "crossbowman_2",
        "horseArcher_2",
        "ballista_2",
        "swordsman_3",
        "ranger_3",
        "lancer_3",
        "catapult_3",
        "sentinel_3",
        "crossbowman_3",
        "horseArcher_3",
        "ballista_3",
        "skeletonWarrior",
        "skeletonArcher",
        "deathKnight",
        "meatWagon",
    }
    local user_soldiers = User.soldiers
    local has_soldiers = false
    for _,name in pairs(soldier_map) do
        local max_num = self:GetMaxSelectSoldier(name)
        if max_num > 0 then
            self:CreateSoldierItem(name,max_num)
            has_soldiers = true
        end
    end
    list:reload()
    if not has_soldiers then
        return
    end
    for i,item in ipairs(list:getItems()) do
        local soldier_type = item:GetSoldier()
        if soldier_type == self.index_soldiers.name then
            item:SetSliderValue(self.index_soldiers.count)
            list:showItemWithPos(i)
        end
    end
    self.isMax = self.index_soldiers.name ~= nil
    self.max_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
        :setButtonLabel(UIKit:commonButtonLable({
            text = self.isMax and _("最小") or _("最大"),
            color = 0xfff3c7
        })):align(display.BOTTOM_CENTER,rb_size.width/2, 20)
        :onButtonClicked(function(event)
            self:MaxBtnClicked()
        end):addTo(body)
    if self.index_soldiers.name and self.index_soldiers.count then
        WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
            :setButtonLabel(UIKit:commonButtonLable({
                text = _("撤销"),
                color = 0xfff3c7
            })):align(display.BOTTOM_CENTER,100, 20)
            :onButtonClicked(function(event)
                self.callback()
                self:LeftButtonClicked()
            end):addTo(body)
        WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
            :setButtonLabel(UIKit:commonButtonLable({
                text = _("确定"),
                color = 0xfff3c7
            })):align(display.BOTTOM_CENTER,rb_size.width - 100, 20)
            :onButtonClicked(function(event)
                self.callback(self.soldier_type,self.soldier_count)
                self:LeftButtonClicked()
            end):addTo(body)
    else
        WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
            :setButtonLabel(UIKit:commonButtonLable({
                text = _("确定"),
                color = 0xfff3c7
            })):align(display.BOTTOM_CENTER,rb_size.width - 100, 20)
            :onButtonClicked(function(event)
                self.callback(self.soldier_type,self.soldier_count)
                self:LeftButtonClicked()
            end):addTo(body)
        self.max_btn:setPositionX(100)
    end

end
function WidgetSelectSoldiers:CreateSoldierItem(soldier_type,max_num)
    local content =  WidgetUIBackGround.new({width = 556,height = 128},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
    local star = UtilsForSoldier:SoldierStarByName(User,soldier_type)
    -- 士兵头像
    local soldier_ui_config = UILib.soldier_image[soldier_type]
    WidgetPushButton.new({normal = UILib.soldier_color_bg_images[soldier_type],pressed = UILib.soldier_color_bg_images[soldier_type]})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newWidgetUI("WidgetSoldierDetails", soldier_type, star):AddToCurrentScene()
            end
        end):addTo(content)
        :align(display.CENTER,65,64):scale(104/128)

    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,65,64):addTo(content):scale(104/128)
    local soldier_head_bg  = display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):pos(soldier_head_icon:getContentSize().width/2,soldier_head_icon:getContentSize().height/2)
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_head_icon):align(display.BOTTOM_CENTER,soldier_head_icon:getContentSize().width/2 - 10, 4)
    local soldier_star = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = star,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(soldier_star_bg):align(display.CENTER,58, 11)
    display.newSprite("i_icon_20x20.png"):addTo(soldier_star_bg):align(display.LEFT_CENTER,5, 11)

    local slider = WidgetSliderWithInput.new({max = max_num,min = 0,bar = "slider_bg_461x24.png", progress = "slider_progress_445x14.png"})
        :OnSliderValueChanged(function(event)
            self:DelegateValue(event.target)
        end)
        :addTo(content)
        :align(display.RIGHT_CENTER, content:getContentSize().width - 10,  60)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.TOP,60)
        :scale(0.92)
    local list = self.soldier_listview
    local item = list:newItem()
    item:addContent(content)
    item:setItemSize(556,135)
    list:addItem(item)
    function item:ResetSlider()
        slider:SetValue(0)
    end
    function item:SetSliderValue(value)
        slider:SetValue(value)
    end
    function item:IsSliderSame(slider_tar)
        return slider_tar == slider.slider
    end
    function item:GetSoldier()
        return soldier_type,slider:GetValue()
    end
end
function WidgetSelectSoldiers:GetMaxSelectSoldier(soldier_type)
    local max_citizen = self.max_citizen
    local max_soldier = 0
    local soldier_count = User.soldiers[soldier_type] - self:GetSettingSoldierCountByName(soldier_type)
    if self.isDefence and User.defenceTroop and User.defenceTroop ~= json.null then
        for i,v in ipairs(User.defenceTroop.soldiers) do
            if v.name == soldier_type then
                soldier_count = soldier_count + v.count
            end
        end
    end
    if soldier_count > 0 then
        local soldier_unit_citizen = UtilsForSoldier:GetSoldierConfig(User,soldier_type).citizen
        local curren_max_citizen = soldier_unit_citizen * soldier_count
        max_soldier = curren_max_citizen > max_citizen and math.floor(max_citizen/soldier_unit_citizen) or soldier_count
    end
    return max_soldier
end
function WidgetSelectSoldiers:DelegateValue(target)
    for i,item in ipairs(self.soldier_listview:getItems()) do
        if item:IsSliderSame(target) then
            self.soldier_type,self.soldier_count = item:GetSoldier()
            if self.soldier_count == 0 then
                if self.max_btn then
                    self.max_btn:setButtonLabel(UIKit:commonButtonLable({
                        text = _("最大"),
                        color = 0xfff3c7
                    }))
                    self.isMax = false
                end
            else
                if self.max_btn then
                    self.max_btn:setButtonLabel(UIKit:commonButtonLable({
                        text = _("最小"),
                        color = 0xfff3c7
                    }))
                    self.isMax = true
                end
            end
        else
            item:ResetSlider()
        end
    end
end
function WidgetSelectSoldiers:GetSettingSoldierCountByName(name)
    local settingCount = 0
    for i,soldier in ipairs(self.settingSoldiers) do
        if soldier.name == name and (self.index_soldiers.name ~= name or i ~= self.index) then
            settingCount = settingCount + soldier.count
        end
    end
    return settingCount
end
-- 根据一格最大带兵量获取按战斗力排序的士兵列表
function WidgetSelectSoldiers:GetSortSoldierMax()
    local max_citizen = self.max_citizen
    local max_soldier = 0
    local sort_soldiers = {}
    for soldier_type,soldier_count in pairs(User.soldiers) do
        soldier_count = soldier_count - self:GetSettingSoldierCountByName(soldier_type)
        local config = UtilsForSoldier:GetSoldierConfig(User,soldier_type)
        if self.isDefence and User.defenceTroop and User.defenceTroop ~= json.null then
            for i,v in ipairs(User.defenceTroop.soldiers) do
                if v.name == soldier_type then
                    soldier_count = soldier_count + v.count
                end
            end
        end
        if soldier_count > 0 then
            local soldier_unit_citizen = config.citizen
            local curren_max_citizen = soldier_unit_citizen * soldier_count
            max_soldier = curren_max_citizen > max_citizen and math.floor(max_citizen/soldier_unit_citizen) or soldier_count
            table.insert(sort_soldiers, {name = soldier_type,count = max_soldier,power = max_soldier * config.power})
        end
    end
    table.sort( sort_soldiers, function ( a,b )
        return a.power > b.power
    end )
    return sort_soldiers
end
function WidgetSelectSoldiers:MaxBtnClicked()
    if self.isMax then
        self.max_btn:setButtonLabel(UIKit:commonButtonLable({
            text = _("最大"),
            color = 0xfff3c7
        }))
        for i,item in ipairs(self.soldier_listview:getItems()) do
            item:ResetSlider()
        end
    else
        self.max_btn:setButtonLabel(UIKit:commonButtonLable({
            text = _("最小"),
            color = 0xfff3c7
        }))
        local max_soldier = self:GetSortSoldierMax()[1]
        for i,item in ipairs(self.soldier_listview:getItems()) do
            local item_type = item:GetSoldier()
            if item_type == max_soldier.name then
                item:SetSliderValue(max_soldier.count)
                self.soldier_listview:showItemWithPos(i)
            else
                item:ResetSlider()
            end
        end
    end
end
return WidgetSelectSoldiers














