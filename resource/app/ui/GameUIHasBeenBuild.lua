local UpgradeBuilding = import("..entity.UpgradeBuilding")
local Localize = import("..utils.Localize")
local SpriteConfig = import("..sprites.SpriteConfig")
local window = import("..utils.window")
local WidgetTimeBar = import("..widget.WidgetTimeBar")
local WidgetBuildingIntroduce = import("..widget.WidgetBuildingIntroduce")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetBuyBuildingQueue = import("..widget.WidgetBuyBuildingQueue")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUIBuildingSpeedUp = import("..ui.GameUIBuildingSpeedUp")
local GameUIHasBeenBuild = UIKit:createUIClass('GameUIHasBeenBuild', "GameUIWithCommonHeader")
local NOT_ABLE_TO_UPGRADE = UpgradeBuilding.NOT_ABLE_TO_UPGRADE
local timer = app.timer
local building_config_map = {
    ["keep"] = {scale = 0.25, offset = {x = 10, y = -20}},
    ["watchTower"] = {scale = 0.3, offset = {x = 10, y = -10}},
    ["warehouse"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["dragonEyrie"] = {scale = 0.3, offset = {x = 0, y = -10}},
    ["toolShop"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["materialDepot"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["armyCamp"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["barracks"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["blackSmith"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["foundry"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["stoneMason"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["lumbermill"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["mill"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["hospital"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["townHall"] = {scale = 0.4, offset = {x = 10, y = -10}},
    ["tradeGuild"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["academy"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["prison"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["hunterHall"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["trainingGround"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["stable"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["workshop"] = {scale = 0.5, offset = {x = 10, y = -10}},
    ["wall"] = {scale = 0.5, offset = {x = 0, y = -10}},
    ["tower"] = {scale = 0.5, offset = {x = 0, y = -10}},
    --
    ["dwelling"] = {scale = 0.8, offset = {x = 0, y = -10}},
    ["farmer"] = {scale = 0.8, offset = {x = 0, y = -10}},
    ["woodcutter"] = {scale = 0.8, offset = {x = 0, y = -10}},
    ["quarrier"] = {scale = 0.8, offset = {x = 0, y = -10}},
    ["miner"] = {scale = 0.8, offset = {x = 0, y = -10}},
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

    display.newSprite("bg_134x134.png"):addTo(back_ground):pos((left_x + right_x) / 2, h/2)

    self.building_icon = cc.ui.UIImage.new("info_26x26.png")
        :addTo(back_ground):align(display.CENTER, (left_x + right_x) / 2, h/2)

    local title_blue = cc.ui.UIImage.new("title_blue_412x30.png", {scale9 = true})
        :addTo(back_ground):align(display.LEFT_CENTER, right_x, h - 23)

    local size = title_blue:getContentSize()
    self.title_label = cc.ui.UILabel.new({
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(title_blue, 2)
        :align(display.LEFT_CENTER, 23 - 5, size.height/2)


    self.condition_label = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x7e0000)
    }):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, 170 - 5, h/2)



    self.desc_label = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, 170 - 5, 35)

    self.gem_bg = display.newSprite("back_ground_97x20.png")
        :addTo(back_ground, 2)
        :align(display.CENTER, w - 90, h/2+10)

    display.newSprite("gem_icon_62x61.png")
        :addTo(self.gem_bg, 2)
        :align(display.CENTER, 20, 20/2)
        :scale(0.4)

    self.gem_label = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0xfff3c7)
    }):addTo(self.gem_bg, 2):align(display.LEFT_CENTER, 40, 20/2)

    self.progress = WidgetTimeBar.new(nil, "back_ground_138x34.png"):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, 185, h/2)

    self.speed_up = WidgetPushButton.new(
        {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }
    ):addTo(back_ground):align(display.CENTER, w - 90, 40)
        :setButtonLabel(cc.ui.UILabel.new({
            text = _("加速"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xffedae)}))
end
function Item:SetBuildingType(building_type, level)
    local config = SpriteConfig[building_type]
    local png = SpriteConfig[building_type]:GetConfigByLevel(level).png
    self.title_label:setString(Localize.building_name[building_type])
    self.building_icon:setTexture(png)
    self.building_icon:scale(building_config_map[building_type].scale)
    self.building_icon:removeAllChildren()
    local p = self.building_icon:getAnchorPointInPoints()
    for _,v in ipairs(config:GetStaticImagesByLevel()) do
        display.newSprite(v):addTo(self.building_icon):pos(p.x, p.y)
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
function Item:RebindEventListener()
    local w, h = self:getContentSize().width, self:getContentSize().height

    if self.info_btn then
        self.info_btn:removeFromParent()
    end
    self.info_btn = WidgetPushButton.new(
        {normal = "info_26x26.png",pressed = "info_26x26.png"})
        :addTo(self)
        :align(display.CENTER, 32, 32)
        :onButtonClicked(function(event)
            local building = self.building
            UIKit:newWidgetUI("WidgetBuildingIntroduce", self.building):AddToCurrentScene(true)
        end)

    if self.free_speedUp then
        self.free_speedUp:removeFromParent()
    end
    self.free_speedUp = WidgetPushButton.new(
        {normal = "purple_btn_up_148x58.png",pressed = "purple_btn_down_148x58.png"})
        :addTo(self)
        :align(display.CENTER, w - 90, 40)
        :setButtonLabel(cc.ui.UILabel.new({
            text = _("免费加速"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xffedae)}))
        :onButtonClicked(function(event)
            local building = self.building
            NetManager:getFreeSpeedUpPromise(building:EventType(), building:UniqueUpgradingKey())
        end)

    if self.instant_build then
        self.instant_build:removeFromParent()
    end
    self.instant_build = WidgetPushButton.new(
        {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"})
        :addTo(self)
        :align(display.CENTER, w - 90, 40)
        :setButtonLabel(cc.ui.UILabel.new({
            text = _("升级"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xffedae)})):onButtonClicked(function(event)
        local building = self.building
        local city = building:BelongCity()
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
            end)


    if self.normal_build then
        self.normal_build:removeFromParent()
    end
    self.normal_build = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }):addTo(self)
        :align(display.CENTER, w - 90, 40)
        :setButtonLabel(cc.ui.UILabel.new({
            text = _("升级"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xffedae)})):onButtonClicked(function(event)
        local building = self.building
        local city = building:BelongCity()
        local illegal, is_pre_condition = building:IsAbleToUpgrade(false)
        local jump_building = building:GetPreConditionBuilding()
        local cur_scene = display.getRunningScene()
        if illegal and is_pre_condition
            and type(jump_building) == "table"
            and cur_scene.AddIndicateForBuilding then
            UIKit:showMessageDialog(_("提示"), _("前置建筑条件不满足, 请前往。"), function()
                local building_sprite = cur_scene:GetSceneLayer():FindBuildingSpriteByBuilding(jump_building, city)
                cur_scene:GotoLogicPoint(jump_building:GetMidLogicPosition())
                cur_scene:AddIndicateForBuilding(building_sprite)
                self.parent_ui:LeftButtonClicked()
            end)
            return
        end

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
            end)

    if self.speed_up then
        self.speed_up:removeFromParent()
    end
    self.speed_up = WidgetPushButton.new(
        {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }
    ):addTo(self):align(display.CENTER, w - 90, 40)
        :setButtonLabel(cc.ui.UILabel.new({
            text = _("加速"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xffedae)}))
        :onButtonClicked(function(event)
            UIKit:newGameUI("GameUIBuildingSpeedUp", self.building):AddToCurrentScene(true)
        end)
end
function Item:UpdateByBuilding(building, current_time)
    self.building = building
    self:SetBuildingType(building:GetType(), building:GetLevel())
    repeat
        if building:IsUpgrading() then
            assert(current_time ~= 0)
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
                self.gem_label:setString(building:getUpgradeNowNeedGems())
            end
            self:SetConditionLabel(illegal, UIKit:hex2c3b(0x7e0000))
        else
            self:ChangeStatus("normal")
            self:SetConditionLabel(_("满足条件"), UIKit:hex2c3b(0x007c23))
        end
    until true
    self:UpdateDesc(building)
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
        else
            self.desc_label:setString(string.format("%s%d", _("正在升级到 等级"), building:GetNextLevel()))
        end
    else
        if building:IsMaxLevel() then
            self.desc_label:setString(string.format("%s", _("已经到最大等级了")))
        else
            self.desc_label:setString(string.format("%s%d%s%d", _("从等级"), building:GetLevel(), _("升级到等级"), building:GetNextLevel()))
        end
    end
end
function Item:ChangeStatus(status)
    if self.status == status then
        return
    end
    if status == "instant" then
        self:HideFreeSpeedUp()
        self:HideNormalButton()
        self:HideProgress()

        self:ShowInstantButton()
    elseif status == "free" then
        self:HideNormalButton()
        self:HideInstantButton()

        self:ShowProgress()
        self:ShowFreeSpeedUp()
    elseif status == "normal" then
        self:HideFreeSpeedUp()
        self:HideInstantButton()
        self:HideProgress()

        self:ShowNormalButton()
    elseif status == "building" then
        self:HideFreeSpeedUp()
        self:HideInstantButton()
        self:HideNormalButton()

        self:ShowProgress()
        self.speed_up:setVisible(true)
    elseif status == "disable" then
        self:HideFreeSpeedUp()
        self:HideInstantButton()
        self:HideProgress()
        self:ShowNormalButton()
    elseif status == "max" then
        self:HideFreeSpeedUp()
        self:HideInstantButton()
        self:HideNormalButton()
        self:HideProgress()
        self.speed_up:hide()
        self.condition_label:hide()
    end
    self.status = status
    return self
end
function Item:HideInstantButton()
    self.gem_bg:setVisible(false)
    self.instant_build:setVisible(false)
end
function Item:ShowInstantButton()
    self.speed_up:setVisible(false)
    self.gem_bg:setVisible(true)
    self.instant_build:setVisible(true)
end
function Item:HideNormalButton()
    self.normal_build:setVisible(false)
end
function Item:ShowNormalButton()
    self.speed_up:setVisible(false)
    self.normal_build:setVisible(true)
end
function Item:HideProgress()
    self.progress:setVisible(false)
end
function Item:ShowProgress()
    self.progress:setVisible(true)
end
function Item:ShowFreeSpeedUp()
    self.speed_up:setVisible(false)
    self.free_speedUp:show()
end
function Item:HideFreeSpeedUp()
    self.free_speedUp:hide()
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
    self:RefreshCurrentList()
end
function GameUIHasBeenBuild:RefreshAllItems()
    local list = self.house_list_view or self.function_list_view or {}
    for i,v in ipairs(list.items_ or {}) do
        self:UpdateContent(v:getContent(), v.idx_)
    end
end
function GameUIHasBeenBuild:LoadBuildingQueue()
    local back_ground = cc.ui.UIImage.new("back_ground_534x46.png"):align(display.CENTER, window.cx, window.top - 120)
    local check = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "wow_40x40.png" })
        :addTo(back_ground)
        :align(display.CENTER, 30, back_ground:getContentSize().height/2)
    check:setTouchEnabled(false)
    local building_label = cc.ui.UILabel.new({
        text = _("建筑队列"),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x797154)
    }):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, 60, back_ground:getContentSize().height/2)

    WidgetPushButton.new(
        {normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(back_ground)
        :align(display.CENTER, back_ground:getContentSize().width - 25, back_ground:getContentSize().height/2)
        :onButtonClicked(function ( event )
            if event.name == "CLICKED_EVENT" then
                UIKit:newWidgetUI("WidgetBuyBuildingQueue"):AddToCurrentScene()
            end
        end)


    function back_ground:SetBuildingQueue(current, max)
        local enable = current > 0
        check:setButtonSelected(enable)
        local str = string.format("%s %d/%d", _("建筑队列"), current, max)
        if building_label:getString() ~= str then
            building_label:setString(str)
        end
    end

    return back_ground
end
function GameUIHasBeenBuild:UpdateBuildingQueue(city)
    self.queue:SetBuildingQueue(city:GetAvailableBuildQueueCounts(), city:BuildQueueCounts())
end
function GameUIHasBeenBuild:TabButtons()
    self:CreateTabButtons({
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
        if tag == "function" then
            self:UnloadHouseListView()

            self:LoadFunctionListView()
        elseif tag == "resource" then
            self:UnloadFunctionListView()

            self:LoadHouseListView()
        end
    end):pos(window.cx, window.bottom + 34)
end
-- function
function GameUIHasBeenBuild:RefreshCurrentList()
    if self.house_list_view then
        self:UnloadHouseListView()
        self:LoadHouseListView()
    end
    if self.function_list_view then
        self:UnloadFunctionListView()
        self:LoadFunctionListView()
    end
end
function GameUIHasBeenBuild:LoadFunctionListView()
    if not self.function_list_view then
        self.function_list_view , self.function_list_node= self:CreateListView(self.build_city:GetBuildingsIsUnlocked())
        self.function_list_view:reload()
    end
end
function GameUIHasBeenBuild:UnloadFunctionListView()
    if self.function_list_view then
        self.function_list_view:removeFromParent()
        self.function_list_node:removeFromParent()
    end
    self.function_list_view = nil
    self.function_list_node = nil
end
-- house
function GameUIHasBeenBuild:LoadHouseListView()
    if not self.house_list_view then
        self.house_list_view, self.house_list_node= self:CreateListView(self.build_city:GetHousesWhichIsBuilded())
        self.house_list_view:reload()
    end
end
function GameUIHasBeenBuild:UnloadHouseListView()
    if self.house_list_view then
        self.house_list_view:removeFromParent()
        self.house_list_node:removeFromParent()
    end
    self.house_list_view = nil
    self.house_list_node = nil
end
---
function GameUIHasBeenBuild:CreateListView(buildings)
    self.buildings = buildings
    local list_view ,listnode=  UIKit:commonListView({
        async = true, --异步加载
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 568, 680),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(self:GetView()):align(display.BOTTOM_CENTER,window.cx,window.bottom_top + 20)
    list_view:setRedundancyViewVal(list_view:getViewRect().height)
    list_view:setDelegate(handler(self, self.sourceDelegate))
    list_view:reload()
    return list_view,listnode
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
        content:RebindEventListener()
        self:UpdateContent(content, idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    end
end
function GameUIHasBeenBuild:UpdateContent(content, idx)
    content:UpdateByBuilding(self.buildings[idx], timer:GetServerTime())
end
return GameUIHasBeenBuild






