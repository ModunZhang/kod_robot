local UpgradeBuilding = import("..entity.UpgradeBuilding")
local Localize = import("..utils.Localize")
local SpriteConfig = import("..sprites.SpriteConfig")
local window = import("..utils.window")
local WidgetTimeBar = import("..widget.WidgetTimeBar")
local WidgetBuildingIntroduce = import("..widget.WidgetBuildingIntroduce")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUIBuildingSpeedUp = import("..ui.GameUIBuildingSpeedUp")
local GameUIHasBeenBuild = UIKit:createUIClass('GameUIHasBeenBuild', "GameUIWithCommonHeader")
local sharedSpriteFrameCache = cc.SpriteFrameCache:getInstance()
local NOT_ABLE_TO_UPGRADE = UpgradeBuilding.NOT_ABLE_TO_UPGRADE
local timer = app.timer
local UIKit = UIKit
local building_config_map = {
    ["keep"] = {scale = 0.3, offset = {x = 80, y = 74}},
    ["watchTower"] = {scale = 0.35, offset = {x = 90, y = 70}},
    ["warehouse"] = {scale = 0.5, offset = {x = 84, y = 70}},
    ["dragonEyrie"] = {scale = 0.35, offset = {x = 74, y = 70}},
    ["toolShop"] = {scale = 0.5, offset = {x = 80, y = 70}},
    ["materialDepot"] = {scale = 0.5, offset = {x = 70, y = 70}},
    ["barracks"] = {scale = 0.5, offset = {x = 80, y = 70}},
    ["blackSmith"] = {scale = 0.5, offset = {x = 75, y = 70}},
    ["foundry"] = {scale = 0.47, offset = {x = 75, y = 74}},
    ["stoneMason"] = {scale = 0.47, offset = {x = 76, y = 75}},
    ["lumbermill"] = {scale = 0.45, offset = {x = 80, y = 74}},
    ["mill"] = {scale = 0.45, offset = {x = 76, y = 74}},
    ["hospital"] = {scale = 0.5, offset = {x = 80, y = 75}},
    ["townHall"] = {scale = 0.45, offset = {x = 76, y = 74}},
    ["tradeGuild"] = {scale = 0.5, offset = {x = 74, y = 74}},
    ["academy"] = {scale = 0.5, offset = {x = 80, y = 74}},
    ["prison"] = {scale = 0.4, offset = {x = 80, y = 80}},
    ["hunterHall"] = {scale = 0.5, offset = {x = 74, y = 74}},
    ["trainingGround"] = {scale = 0.5, offset = {x = 76, y = 74}},
    ["stable"] = {scale = 0.46, offset = {x = 74, y = 74}},
    ["workshop"] = {scale = 0.46, offset = {x = 74, y = 74}},

    ["wall"] = {scale = 0.5, offset = {x = 74, y = 74}},
    ["tower"] = {scale = 0.5, offset = {x = 74, y = 74}},
    --
    ["dwelling"] = {scale = 0.8, offset = {x = 74, y = 74}},
    ["farmer"] = {scale = 0.8, offset = {x = 74, y = 74}},
    ["woodcutter"] = {scale = 0.8, offset = {x = 74, y = 74}},
    ["quarrier"] = {scale = 0.8, offset = {x = 74, y = 74}},
    ["miner"] = {scale = 0.8, offset = {x = 74, y = 74}},
}




local Item = class("Item", WidgetUIBackGround)
function Item:ctor(parent_ui)
    self.parent_ui = parent_ui
    Item.super.ctor(self, {
        width = 568,
        height = 150,
        top_img = "back_ground_568x16_top.png",
        bottom_img = "back_ground_568x80_bottom.png",
        mid_img = "back_ground_568x28_mid.png",
        u_height = 16,
        b_height = 80,
        m_height = 28,
    })
    local back_ground = self
    local w, h = back_ground:getContentSize().width, back_ground:getContentSize().height
    local left_x, right_x = 5, 150

    display.newSprite("alliance_item_flag_box_126X126.png"):addTo(back_ground)
        :pos((left_x + right_x) / 2, h/2):scale(134/126)

    self.building_icon = cc.ui.UIImage.new("info_26x26.png"):addTo(back_ground)
        :align(display.CENTER, (left_x + right_x) / 2, h/2)

    local title_blue = display.newScale9Sprite("title_blue_430x30.png", 0,0, cc.size(412,30), cc.rect(10,10,410,10))
        :addTo(back_ground):align(display.LEFT_CENTER, right_x, h - 23)

    local size = title_blue:getContentSize()
    self.title_label = UIKit:ttfLabel({
        size = 22,
        color = 0xffedae,
    }):addTo(title_blue, 2):align(display.LEFT_CENTER, 23 - 5, size.height/2)

    self.condition_label = UIKit:ttfLabel({
        size = 20,
        color = 0x7e0000,
    }):addTo(back_ground, 2):align(display.LEFT_CENTER, 170 - 5, h/2)

    self.desc_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground, 2):align(display.LEFT_CENTER, 170 - 5, 35)

    self.progress = WidgetTimeBar.new(nil, "back_ground_166x84.png"):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, 185, h/2)

    WidgetPushButton.new({normal = "info_26x26.png",pressed = "info_26x26.png"})
        :addTo(self)
        :align(display.LEFT_BOTTOM, 15, 15)
        :onButtonClicked(function(event)
            local building = self.building
            UIKit:newWidgetUI("WidgetBuildingIntroduce", self.building):AddToCurrentScene(true)
        end):setContentSize(cc.size(150, 120))


    self.button = WidgetPushButton.new(
        {
        normal = "purple_btn_up_148x58.png",
        pressed = "purple_btn_down_148x58.png",
        disabled = "gray_btn_148x58.png",
        })
        :addTo(self):align(display.CENTER, w - 90, 40)
        :setButtonLabel(UIKit:ttfLabel({
            text = "",
            size = 24,
            color = 0xffedae,
        }))
        :onButtonClicked(function(event)
            local building = self.building
            if self.status == "free" then
                NetManager:getFreeSpeedUpPromise(building:EventType(), building:UniqueUpgradingKey())
            elseif self.status == "instant" then
                local city = building:BelongCity()
                if building:getUpgradeNowNeedGems() > city:GetUser():GetGemResource():GetValue() then
                    local dialog = UIKit:showMessageDialog()
                    dialog:SetTitle(_("提示"))
                    dialog:SetPopMessage(UpgradeBuilding.NOT_ABLE_TO_UPGRADE.GEM_NOT_ENOUGH)
                    dialog:CreateOKButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                self.parent_ui:LeftButtonClicked()
                            end,
                            btn_name = _("前往商店")
                        }
                    )
                    return
                end
                if city:IsFunctionBuilding(building) then
                    local location_id = city:GetLocationIdByBuilding(building)
                    NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
                elseif city:IsHouse(building) then
                    local tile = city:GetTileWhichBuildingBelongs(building)
                    local house_location = tile:GetBuildingLocation(building)
                    NetManager:getInstantUpgradeHouseByLocationPromise(tile.location_id, house_location)
                elseif city:IsGate(building) then
                    NetManager:getInstantUpgradeWallByLocationPromise()
                elseif city:IsTower(building) then
                    NetManager:getInstantUpgradeTowerPromise()
                end
            elseif self.status == "normal" then
                local illegal, is_pre_condition = building:IsAbleToUpgrade(false)
                local jump_building = building:GetPreConditionBuilding()
                local cur_scene = display.getRunningScene()
                if illegal and is_pre_condition
                    and type(jump_building) == "table"
                    and cur_scene.AddIndicateForBuilding then
                    UIKit:showMessageDialog(_("提示"), _("前置建筑条件不满足, 请前往。"), function()
                        local building_sprite = cur_scene:GetSceneLayer():FindBuildingSpriteByBuilding(jump_building, city)
                        local x,y = jump_building:GetMidLogicPosition()
                        cur_scene:GotoLogicPoint(x,y,40):next(function()
                            cur_scene:AddIndicateForBuilding(building_sprite)
                        end)
                        self.parent_ui:LeftButtonClicked()
                    end)
                    return
                end
                local city = building:BelongCity()
                if city:IsFunctionBuilding(building) then
                    local location_id = city:GetLocationIdByBuilding(building)
                    NetManager:getUpgradeBuildingByLocationPromise(location_id)
                elseif city:IsHouse(building) then
                    local tile = city:GetTileWhichBuildingBelongs(building)
                    local house_location = tile:GetBuildingLocation(building)

                    NetManager:getUpgradeHouseByLocationPromise(tile.location_id, house_location)
                elseif city:IsGate(building) then
                    NetManager:getUpgradeWallByLocationPromise()
                elseif city:IsTower(building) then
                    NetManager:getUpgradeTowerPromise()
                end
            elseif self.status == "building" then
                UIKit:newGameUI("GameUIBuildingSpeedUp", building):AddToCurrentScene(true)
            end
        end)


    self.gem_icon = display.newSprite("gem_icon_62x61.png")
        :addTo(self.button, 2):align(display.CENTER, -50, 50):scale(0.7)
    self.gem_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):addTo(self.gem_icon, 2):align(display.LEFT_CENTER, 60, 61/2)
end
function Item:SetBuildingType(building_type, level)
    local config = SpriteConfig[building_type]
    local png = SpriteConfig[building_type]:GetConfigByLevel(level).png
    self.title_label:setString(Localize.building_name[building_type])
    self.building_icon:setTexture(png)
    self.building_icon:setPosition(building_config_map[building_type].offset.x,building_config_map[building_type].offset.y)
    self.building_icon:scale(building_config_map[building_type].scale)
    self.building_icon:removeAllChildren()
    local p = self.building_icon:getAnchorPointInPoints()
    for _,v in ipairs(config:GetStaticImagesByLevel()) do
        local frame = sharedSpriteFrameCache:getSpriteFrame(v)
        if frame then
            display.newSprite("#"..v):addTo(self.building_icon):pos(p.x, p.y)
        end
    end
    return self
end
function Item:SetConditionLabel(label, color)
    self.condition_label:show():setString(label)
    if color then
        self.condition_label:setColor(color)
    end
    return self
end
function Item:UpdateByBuilding(building, current_time)
    self.building = building
    repeat
        if building:IsUpgrading() then
            local can_free_speedUp = building:GetUpgradingLeftTimeByCurrentTime(current_time) <= DataUtils:getFreeSpeedUpLimitTime()
            self:ChangeStatus(can_free_speedUp and "free" or "building")
            self:UpdateProgress(building)
            break
        end
        if building:IsMaxLevel() then
            self:ChangeStatus("max")
            break
        end
        local illegal, is_pre_condition = building:IsAbleToUpgrade(false)
        if illegal then
            if is_pre_condition then
                self:ChangeStatus("disable")
            else
                self:ChangeStatus("instant")
                self.gem_label:setString(string.formatnumberthousands(building:getUpgradeNowNeedGems()))
            end
            self:SetConditionLabel(illegal, UIKit:hex2c3b(0x7e0000))
        else
            self:ChangeStatus("normal")
            self:SetConditionLabel(_("满足条件"), UIKit:hex2c3b(0x007c23))
        end
    until true
end
function Item:UpdateProgress(building)
    if building:IsUpgrading() then
        local time = timer:GetServerTime()
        local str = GameUtils:formatTimeStyle1(building:GetUpgradingLeftTimeByCurrentTime(time))
        local percent = building:GetUpgradingPercentByCurrentTime(time)
        self.progress:SetProgressInfo(str, percent)
    end
end
function Item:UpdateDesc(building)
    if building:IsUpgrading() then
        if building:GetNextLevel() == 1 then
            self.desc_label:setString(building:IsHouse() and _("正在建造") or _("正在解锁"))
            self.desc_label:setPositionY(35)
        else
            self.desc_label:setString(string.format(_("正在升级到等级%d"), building:GetNextLevel()))
            self.desc_label:setPositionY(35)
        end
    else
        if building:IsMaxLevel() then
            self.desc_label:setString(_("已经到最大等级了"))
            self.desc_label:setPositionY(70)
        else
            self.desc_label:setString(string.format(_("从等级%d升级到等级%d"), building:GetLevel(), building:GetNextLevel()))
            self.desc_label:setPositionY(35)
        end
    end
end
local is_building_map = {
    free = true,
    building = true,
}
function Item:ChangeStatus(status)
    if self.status == status then
        return
    end
    local button = self.button:show()
    self.gem_icon:hide()
    if status == "instant" then
        button:setButtonEnabled(true)
        self.gem_icon:show()
        button:show()
        button:setButtonLabelString(_("立即建造"))
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, "green_btn_up_148x58.png", true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, "green_btn_down_148x58.png", true)

        self.condition_label:show()
    elseif status == "free" then
        button:setButtonEnabled(true)
        button:setButtonLabelString(_("免费加速"))
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, "purple_btn_up_148x58.png", true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, "purple_btn_down_148x58.png", true)

        self.condition_label:hide()
    elseif status == "normal" then
        button:setButtonEnabled(true)
        button:setButtonLabelString(_("建造"))
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, "yellow_btn_up_148x58.png", true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, "yellow_btn_down_148x58.png", true)

        self.condition_label:show()
    elseif status == "building" then
        button:setButtonEnabled(true)
        button:setButtonLabelString(_("加速"))
        button:setButtonImage(cc.ui.UIPushButton.NORMAL, "green_btn_up_148x58.png", true)
        button:setButtonImage(cc.ui.UIPushButton.PRESSED, "green_btn_down_148x58.png", true)

        self.condition_label:hide()
    elseif status == "disable" then
        button:setButtonEnabled(false)
        button:setButtonLabelString(_("建造"))

        self.condition_label:show()
    elseif status == "max" then
        button:hide()
        self.condition_label:hide()
    end
    self.status = status
    local is_building = is_building_map[status]
    if is_building then
        self.progress:show()
    else
        self.progress:hide()
    end
    self:UpdateDesc(self.building)
    return self
end


function GameUIHasBeenBuild:ctor(city)
    GameUIHasBeenBuild.super.ctor(self, city, _("建筑列表"))
    self.build_city = city
end
function GameUIHasBeenBuild:OnMoveInStage()
    timer:AddListener(self)
    self.build_city:AddListenOnType(self, self.build_city.LISTEN_TYPE.UPGRADE_BUILDING)
    GameUIHasBeenBuild.super.OnMoveInStage(self)

    self.queue = self:LoadBuildingQueue():addTo(self:GetView())
    self:UpdateBuildingQueue(self.build_city)

    self.building_list_view = self:CreateListView()

    self:TabButtons()
end
function GameUIHasBeenBuild:onExit()
    timer:RemoveListener(self)
    self.build_city:RemoveListenerOnType(self, self.build_city.LISTEN_TYPE.UPGRADE_BUILDING)
    GameUIHasBeenBuild.super.onExit(self)
end
function GameUIHasBeenBuild:OnTimer(time)
    self:RefreshAllItems()
end
function GameUIHasBeenBuild:OnUpgradingBegin(building, current_time, city)
    self:UpdateBuildingQueue(city)
    self:RefreshAllItems()
end
function GameUIHasBeenBuild:OnUpgrading(building, current_time, city)
end
function GameUIHasBeenBuild:OnUpgradingFinished(building, city)
    self:UpdateBuildingQueue(city)
    self:RefreshCurrentList(self.tabs:GetSelectedButtonTag())
end
function GameUIHasBeenBuild:RefreshAllItems()
    local time = timer:GetServerTime()
    for i,v in ipairs(self.building_list_view.items_) do
        v:getContent():UpdateByBuilding(self.buildings[v.idx_], time)
    end
end
function GameUIHasBeenBuild:LoadBuildingQueue()
    local back_ground = display.newScale9Sprite("back_ground_166x84.png", 0,0,cc.size(534,46),cc.rect(15,10,136,64))
        :align(display.CENTER, window.cx, window.top - 120)
    local check = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "wow_40x40.png" })
        :addTo(back_ground)
        :align(display.CENTER, 30, back_ground:getContentSize().height/2)
    check:setTouchEnabled(false)
    local building_label = UIKit:ttfLabel({
        text = _("建筑队列"),
        size = 20,
        color = 0x615b44,
    }):addTo(back_ground, 2):align(display.LEFT_CENTER, 60, back_ground:getContentSize().height/2)

    if City:BuildQueueCounts() < 2 then
        WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
            :addTo(back_ground)
            :align(display.CENTER, back_ground:getContentSize().width - 25, back_ground:getContentSize().height/2)
            :onButtonClicked(function ( event )
                if event.name == "CLICKED_EVENT" then
                    UIKit:newGameUI("GameUIActivityRewardNew",4):AddToCurrentScene(true)
                end
            end)
    end

    function back_ground:SetBuildingQueue(current, max)
        local enable = current > 0
        check:setButtonSelected(enable)
        building_label:setString(string.format(_("建筑队列 %d/%d"), current, max))
    end

    return back_ground
end
function GameUIHasBeenBuild:UpdateBuildingQueue(city)
    self.queue:SetBuildingQueue(city:GetAvailableBuildQueueCounts(), city:BuildQueueCounts())
end
function GameUIHasBeenBuild:TabButtons()
    self.tabs = self:CreateTabButtons({
        {
            label = _("功能建筑"),
            tag = "function",
            default = true
        },
        {
            label = _("资源建筑"),
            tag = "resource",
        },
    },
    function(tag)
        self:RefreshCurrentList(tag)
    end):pos(window.cx, window.bottom + 34)
end
function GameUIHasBeenBuild:RefreshCurrentList(tag)
    self.building_list_view:removeAllItems()
    if tag == "function" then
        self.buildings = self.build_city:GetBuildingsIsUnlocked()
    else
        self.buildings = self.build_city:GetHousesWhichIsBuilded()
    end
    self.building_list_view:reload()
end
function GameUIHasBeenBuild:CreateListView()
    local list_view, listnode = UIKit:commonListView({
        async = true, --异步加载
        iscleanup = false,
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 568, 680),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(self:GetView()):align(display.BOTTOM_CENTER,window.cx,window.bottom_top + 20)
    list_view:setRedundancyViewVal(list_view:getViewRect().height)
    list_view:setDelegate(handler(self, self.sourceDelegate))
    return list_view, listnode
end
function GameUIHasBeenBuild:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.buildings
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = Item.new(self)
            item:addContent(content)
        else
            content = item:getContent()
            content.status = nil
        end
        local building = self.buildings[idx]
        content:SetBuildingType(building:GetType(), building:GetLevel())
        content:UpdateByBuilding(building, timer:GetServerTime())
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    end
end


return GameUIHasBeenBuild




