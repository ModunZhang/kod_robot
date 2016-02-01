local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local window = import("..utils.window")
local BuildingRegister = import("..entity.BuildingRegister")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local SpriteConfig = import("..sprites.SpriteConfig")
local house_levelup_config = GameDatas.HouseLevelUp

local GameUIBuild = UIKit:createUIClass('GameUIBuild', "GameUIWithCommonHeader")

local base_items = {
    { label = _("住宅"), building_type = "dwelling", png = SpriteConfig["dwelling"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("木工小屋"), building_type = "woodcutter", png = SpriteConfig["woodcutter"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("石匠小屋"), building_type = "quarrier", png = SpriteConfig["quarrier"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("矿工小屋"), building_type = "miner", png = SpriteConfig["miner"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("农夫小屋"), building_type = "farmer", png = SpriteConfig["farmer"]:GetConfigByLevel(1).png, scale = 1 },
}
function GameUIBuild:ctor(city, building, p1, p2, need_tips, build_name)
    GameUIBuild.super.ctor(self, city, _("待建地基"))
    self.build_city = city
    self.select_ruins = building
    self.need_tips = need_tips
    self.build_name = build_name
    print(self.need_tips, self.build_name)
    self.select_ruins_list = city:GetNeighbourRuinWithSpecificRuin(building)
    app:GetAudioManager():PlayBuildingEffectByType("woodcutter")
end
function GameUIBuild:OnMoveInStage()
    self.queue = self:LoadBuildingQueue():addTo(self:GetView())
    self:UpdateBuildingQueue(self.build_city)

    local list_view ,listnode =  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 760),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }, true, false)
    listnode:addTo(self:GetView()):align(display.BOTTOM_CENTER,window.cx,window.bottom_top - 60)
    self.base_resource_building_items = {}
    self.base_list_view = list_view
    for i, v in ipairs(base_items) do
        local item = self:CreateItemWithListView(self.base_list_view)
        item.building = v
        item:SetType(v, handler(self, self.OnBuildOnItem))
        self.base_list_view:addItem(item)
        table.insert(self.base_resource_building_items, item)
        if self.need_tips and self.build_name == v.building_type then
            WidgetFteArrow.new(_("点击建造小屋"))
            :addTo(item, 100):TurnRight():align(display.RIGHT_CENTER, 380, 40)
        end
    end
    self.base_list_view:reload()
    self:OnCityChanged()

    GameUIBuild.super.OnMoveInStage(self)
end
function GameUIBuild:LoadBuildingQueue()
    local back_ground = display.newScale9Sprite("back_ground_166x84.png", 0,0,cc.size(534,46),cc.rect(15,10,136,64))
        :align(display.CENTER, window.cx, window.top - 120)
    local check = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "wow_40x40.png" })
        :addTo(back_ground)
        :align(display.CENTER, 30, back_ground:getContentSize().height/2)
    check:setTouchEnabled(false)
    local building_label = cc.ui.UILabel.new({
        text = _("建筑队列"),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x615b44)
    }):addTo(back_ground, 2)
        :align(display.LEFT_CENTER, 60, back_ground:getContentSize().height/2)


    if User.basicInfo.buildQueue < 2 then
        WidgetPushButton.new(
            {normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"}
            ,{}
            ,{
                disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
            })
            :addTo(back_ground)
            :align(display.CENTER, back_ground:getContentSize().width - 25, back_ground:getContentSize().height/2)
            -- :setButtonEnabled(false)
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
function GameUIBuild:UpdateBuildingQueue(city)
    self.queue:SetBuildingQueue(city:GetAvailableBuildQueueCounts(), city:GetUser().basicInfo.buildQueue)
end
function GameUIBuild:OnCityChanged()
    table.foreachi(self.base_resource_building_items or {}, function(i, v)
        local building_type = base_items[i].building_type
        local number = #self.build_city:GetDecoratorsByType(building_type)
        local max_number = City:GetMaxHouseCanBeBuilt(building_type)
        local building = BuildingRegister[building_type].new({building_type = building_type, level = 1, finishTime = 0})
        v:SetNumber(number, max_number)
        if building then
            if self.build_city:GetAvailableBuildQueueCounts() <= 0 then
                v:SetCondition(_("建造队列不足"), display.COLOR_RED)
            elseif building:GetCitizen() > self.build_city:GetUser():GetResProduction("citizen").limit then
                v:SetBuildEnable(false)
                v:SetCondition(_("城民上限不足,请首先升级或建造小屋"), display.COLOR_RED)
            elseif number >= max_number then
                v:SetBuildEnable(false)
                v:SetCondition(_("已达到最大建筑数量"), display.COLOR_RED)
            else
                v:SetBuildEnable(true)
                v:SetCondition(_("满足条件"))
            end
        end
    end)
end
function GameUIBuild:OnBuildOnItem(item)
    local city = self.build_city
    local User = city:GetUser()
    local max = User.basicInfo.buildQueue
    local current_time = app.timer:GetServerTime()
    local upgrading_buildings = city:GetUpgradingBuildingsWithOrder(current_time)
    local current = max - #upgrading_buildings

    local m = User.buildingMaterials
    local config = house_levelup_config[item.building.building_type]

    -- 升级所需资源不足
    local wood = User:GetResValueByType("wood")
    local iron = User:GetResValueByType("iron")
    local stone = User:GetResValueByType("stone")
    local citizen = User:GetResValueByType("citizen")
    local is_resource_enough = wood<config[1].wood
        or stone<config[1].stone
        or iron<config[1].iron
        or citizen<config[1].citizen
        or m.tiles<config[1].tiles
        or m.tools<config[1].tools
        or m.blueprints<config[1].blueprints
        or m.pulley<config[1].pulley

    local resource_gems = 0
    if is_resource_enough then
        local has_resourcce = {
            wood = wood,
            iron = iron,
            stone = stone,
            citizen = citizen
        }

        local resource_config = DataUtils:getBuildingUpgradeRequired(item.building.building_type, 1)
        resource_gems = resource_gems + DataUtils:buyResource(resource_config.resources, has_resourcce)
        resource_gems = resource_gems + DataUtils:buyMaterial(resource_config.materials, m)
    end
    if current > 0 and resource_gems == 0 then
        self:BuildWithRuins(self.select_ruins, item.building.building_type)
    else
        local dialog =  UIKit:showMessageDialog()
        local required_gems = 0
        if current <= 0 then
            local event = User:GetBuildingEventByLocation(self:GetCurrentLocation(upgrading_buildings[1]))
            if event then
                local time = UtilsForEvent:GetEventInfo(event)
                required_gems = DataUtils:getGemByTimeInterval(time)
            end
        end
        dialog:SetTitle(_("提示"))
        local message  = ""
        if resource_gems>0 then
            message = message .. _("您当前资源不足，补足需要金龙币").. "\n"
        end
        if current<=0 then
            message = message .. _("您当前没有空闲的建筑队列,是否花费魔法石立即完成上一个队列").. "\n"
        end
        local need_gem = required_gems+resource_gems
        dialog:SetPopMessage(message):CreateOKButtonWithPrice(
            {
                listener =  function()
                    if need_gem > User:GetGemValue() then
                        UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                            {
                                listener =  function ()
                                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    self:LeftButtonClicked()
                                end,
                                btn_name = _("前往商店")
                            }
                        )
                    else
                        self:BuildWithRuins(self.select_ruins, item.building.building_type)
                    end
                end,
                btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                price = need_gem
            }
        )
    end
end
function GameUIBuild:GetCurrentLocation(building)
    if building:GetType() == "wall" then
        return 21
    elseif building:GetType() == "tower" then
        return 22
    end
    local City = building:BelongCity()
    local tile = City:GetTileWhichBuildingBelongs(building)
    if City:IsFunctionBuilding(building) then
        return tile.location_id
    else
        local houseLocation = tile:GetBuildingLocation(building)
        return tile.location_id, houseLocation
    end
end
function GameUIBuild:BuildWithRuins(select_ruins, building_type)
    local x, y = select_ruins:GetLogicPosition()
    local w, h = select_ruins.w, select_ruins.h
    local tile = self.build_city:GetTileWhichBuildingBelongs(select_ruins)
    local house_location = tile:GetBuildingLocation(select_ruins)
    NetManager:getCreateHouseByLocationPromise(tile.location_id,
        house_location, building_type):done(function()
        self:LeftButtonClicked()
        end)
end

function GameUIBuild:CreateItemWithListView(list_view)
    local item = list_view:newItem()
    local back_ground = WidgetUIBackGround.new({
        width = 568,
        height = 150,
        top_img = "back_ground_568x16_top.png",
        bottom_img = "back_ground_568x80_bottom.png",
        mid_img = "back_ground_568x28_mid.png",
        u_height = 16,
        b_height = 80,
        m_height = 28,
    })
    item:addContent(back_ground)

    local w, h = back_ground:getContentSize().width, back_ground:getContentSize().height
    item:setItemSize(w, h)


    local left_x, right_x = 5, 150
    local frame = display.newSprite("alliance_item_flag_box_126X126.png"):addTo(back_ground):pos((left_x + right_x) / 2, h/2):scale(134/126)
    -- local info_btn = WidgetPushButton.new(
    --     {normal = "info_26x26.png",pressed = "info_26x26.png"})
    --     :addTo(frame)
    --     :align(display.CENTER, 16, 16)


    local building_icon = display.newSprite(SpriteConfig["dwelling"]:GetConfigByLevel(1).png)
        :addTo(back_ground):align(display.BOTTOM_CENTER, (left_x + right_x) / 2, 15)

    WidgetPushButton.new({normal = "info_26x26.png",pressed = "info_26x26.png"})
        :addTo(back_ground)
        :align(display.LEFT_BOTTOM, 15, 15)
        :onButtonClicked(function(event)
            local building_type = item.building.building_type
            local building = BuildingRegister[building_type].new({building_type = building_type, level = 1, finishTime = 0})
            UIKit:newWidgetUI("WidgetBuildingIntroduce", building):AddToCurrentScene(true)
        end):setContentSize(cc.size(150, 120))

    local title_blue = display.newScale9Sprite("title_blue_430x30.png",0, 0,cc.size(410,30),cc.rect(15,10,400,10))
        :addTo(back_ground):align(display.LEFT_CENTER, right_x, h - 23)

    local size = title_blue:getContentSize()
    local title_label = cc.ui.UILabel.new({
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(title_blue, 2)
        :align(display.LEFT_CENTER, 30, size.height/2)


    local condition_label = cc.ui.UILabel.new({
        text = _("已达到最大建筑数量"),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x615b44)
    }):addTo(back_ground)
        :align(display.LEFT_CENTER, 175, 80)

    local number_label = cc.ui.UILabel.new({
        text = _("建筑数量 5/5"),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground)
        :align(display.LEFT_CENTER, 175, 40)

    local build_btn = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabel(cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("建造"),
            size = 24,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xfff3c7)}))
        :addTo(back_ground)
        :pos(w - 90, 40)



    function item:SetType(item_info, on_build)
        building_icon:setTexture(item_info.png)
        building_icon:scale(item_info.scale)
        title_label:setString(item_info.label)
        build_btn:onButtonClicked(function(event)
            on_build(self)
        end)
    end
    function item:SetNumber(number, max_number)
        number_label:setString(_("数量")..string.format(" %d/%d", number, max_number))
        if number == max_number then
            self:SetCondition(_("已达到最大建筑数量"))
            self:SetBuildEnable(false)
        else
            self:SetCondition(_("满足条件"))
            self:SetBuildEnable(true)
        end
    end
    function item:SetCondition(condition, color)
        condition_label:setString(_(condition))
        condition_label:setColor(color == nil and UIKit:hex2c3b(0x007c23) or UIKit:hex2c3b(0x7e0000))
    end
    function item:SetBuildEnable(is_enable)
        build_btn:setButtonEnabled(is_enable)
    end
    function item:GetBuildButton()
        return build_btn
    end

    return item
end

return GameUIBuild








