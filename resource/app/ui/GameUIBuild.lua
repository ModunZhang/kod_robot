local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local window = import("..utils.window")
local BuildingRegister = import("..entity.BuildingRegister")
local MaterialManager = import("..entity.MaterialManager")
local WidgetBuyBuildingQueue = import("..widget.WidgetBuyBuildingQueue")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local SpriteConfig = import("..sprites.SpriteConfig")
local house_levelup_config = GameDatas.HouseLevelUp

local GameUIBuild = UIKit:createUIClass('GameUIBuild', "GameUIWithCommonHeader")

local base_items = {
    { label = _("住宅"), building_type = "dwelling", png = SpriteConfig["dwelling"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("农夫小屋"), building_type = "farmer", png = SpriteConfig["farmer"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("木工小屋"), building_type = "woodcutter", png = SpriteConfig["woodcutter"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("石匠小屋"), building_type = "quarrier", png = SpriteConfig["quarrier"]:GetConfigByLevel(1).png, scale = 1 },
    { label = _("矿工小屋"), building_type = "miner", png = SpriteConfig["miner"]:GetConfigByLevel(1).png, scale = 1 },
}
function GameUIBuild:ctor(city, building)
    GameUIBuild.super.ctor(self, city, _("待建地基"))
    self.build_city = city
    self.select_ruins = building
    self.select_ruins_list = city:GetNeighbourRuinWithSpecificRuin(building)
    self.build_city:AddListenOnType(self, self.build_city.LISTEN_TYPE.UPGRADE_BUILDING)
    app:GetAudioManager():PlayBuildingEffectByType("woodcutter")
end
function GameUIBuild:OnMoveInStage()
    GameUIBuild.super.OnMoveInStage(self)

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
    end
    self.base_list_view:reload()
    self:OnCityChanged()
end
function GameUIBuild:onExit()
    self.build_city:RemoveListenerOnType(self, self.build_city.LISTEN_TYPE.UPGRADE_BUILDING)
    GameUIBuild.super.onExit(self)
end
function GameUIBuild:LoadBuildingQueue()
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
        color = UIKit:hex2c3b(0x615b44)
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
        -- :setButtonEnabled(false)
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
function GameUIBuild:UpdateBuildingQueue(city)
    self.queue:SetBuildingQueue(city:GetAvailableBuildQueueCounts(), city:BuildQueueCounts())
end
function GameUIBuild:OnUpgradingBegin(building)
    self:OnCityChanged()
end
function GameUIBuild:OnUpgrading()

end
function GameUIBuild:OnUpgradingFinished(building)
    self:OnCityChanged()
end
function GameUIBuild:OnCityChanged()
    local citizen = self.build_city:GetResourceManager():GetPopulationResource():GetValueLimit()
    table.foreachi(self.base_resource_building_items, function(i, v)
        local building_type = base_items[i].building_type
        local number = #self.build_city:GetDecoratorsByType(building_type)
        local max_number = City:GetMaxHouseCanBeBuilt(building_type)
        local building = BuildingRegister[building_type].new({building_type = building_type, level = 1, finishTime = 0})
        v:SetNumber(number, max_number)
        if building then
            if building:GetCitizen() > citizen then
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
    local max = city.build_queue
    local current_time = app.timer:GetServerTime()
    local upgrading_buildings = city:GetUpgradingBuildingsWithOrder(current_time)
    local current = max - #upgrading_buildings

    local m =city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)
    local config = house_levelup_config[item.building.building_type]

    -- 升级所需资源不足
    local wood = city.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = city.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = city.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local citizen = city.resource_manager:GetPopulationResource():GetNoneAllocatedByTime(app.timer:GetServerTime())
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
            required_gems = DataUtils:getGemByTimeInterval(upgrading_buildings[1]:GetUpgradingLeftTimeByCurrentTime(current_time))
        end
        dialog:SetTitle(_("提示"))
        local message  = ""
        if resource_gems>0 then
            message = message .. _("您当前资源不足，补足需要金龙币").. resource_gems.. "\n"
        end
        if current<=0 then
            message = message .. _("您当前没有空闲的建筑队列,是否花费魔法石立即完成上一个队列").. "\n"
        end
        local need_gem = required_gems+resource_gems
        dialog:SetPopMessage(message)
        dialog:CreateNeeds({value = need_gem})
        if need_gem > User:GetGemResource():GetValue() then
            dialog:CreateOKButton(
                {
                    llistener =  function ()
                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                        self:LeftButtonClicked()
                    end,
                    btn_name = _("前往商店")
                }
            )
        else
            dialog:CreateOKButton(
                {
                    listener =  function()
                        self:BuildWithRuins(self.select_ruins, item.building.building_type)
                    end
                }
            )
        end
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
    local frame = display.newSprite("bg_134x134.png"):addTo(back_ground):pos((left_x + right_x) / 2, h/2)
    local info_btn = WidgetPushButton.new(
        {normal = "info_26x26.png",pressed = "info_26x26.png"})
        :addTo(frame)
        :align(display.CENTER, 16, 16)


    local building_icon = display.newSprite(SpriteConfig["dwelling"]:GetConfigByLevel(1).png)
        :addTo(back_ground):align(display.BOTTOM_CENTER, (left_x + right_x) / 2, 30)

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


    -- local btn_info = WidgetPushButton.new(
    --     {normal = "info_26x26.png",pressed = "info_26x26.png"})
    --     :addTo(back_ground)
    --     :align(display.LEFT_BOTTOM, 10, 10)

    local condition_label = cc.ui.UILabel.new({
        text = _("已达到最大建筑数量"),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x615b44)
    }):addTo(back_ground)
        :align(display.LEFT_CENTER, 175, 80)

    local number_label = cc.ui.UILabel.new({
        text = _("建筑数量").."5 / 5",
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
        if title_label:getString() ~= item_info.label then
            title_label:setString(item_info.label)
        end
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

--- fte
function GameUIBuild:Lock()
    self.base_list_view:getScrollNode():setTouchEnabled(false)
    return cocos_promise.defer(function() return self end)
end
function GameUIBuild:Find(building_type)
    local item
    table.foreach(self.base_resource_building_items, function(_, v)
        if v.building.building_type == building_type then
            item = v:GetBuildButton()
            return true
        end
    end)
    return cocos_promise.defer(function()
        if not item then
            promise.reject({code = -1, msg = "没有找到对应item"}, building_type)
        end
        return item
    end)
end


return GameUIBuild


















