local window = import('..utils.window')
local UIListView = import('.UIListView')
local WidgetSoldierDetails = import('..widget.WidgetSoldierDetails')
local WidgetUIBackGround = import('..widget.WidgetUIBackGround')
local WidgetSoldierBox = import('..widget.WidgetSoldierBox')
local WidgetInfoWithTitle = import('..widget.WidgetInfoWithTitle')
local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetInfo = import('..widget.WidgetInfo')
local Localize = import('..utils.Localize')
local GameUIPResourceBuilding = UIKit:createUIClass('GameUIPResourceBuilding',"GameUIUpgradeBuilding")
local intInit = GameDatas.PlayerInitData.intInit
local buildings = GameDatas.Buildings.buildings
local P_RESOURCE_BUILDING_TYPE = {
    "foundry",
    "stoneMason" ,
    "lumbermill" ,
    "mill" ,
}
local P_RESOURCE_BUILDING_TYPE_TO_NAME ={
    ["foundry"] = _("锻造工坊"),
    ["stoneMason"] = _("石匠工坊"),
    ["lumbermill"] = _("锯木工房"),
    ["mill"] = _("磨坊"),
}

local P_RESOURCE_BUILDING_TYPE_TO_RESOURCE ={
    ["foundry"] = _("铁矿产量"),
    ["stoneMason"] = _("石材产量"),
    ["lumbermill"] = _("木材产量"),
    ["mill"] = _("粮食产量"),
}

function GameUIPResourceBuilding:ctor(city,building)
    GameUIPResourceBuilding.super.ctor(self,city,P_RESOURCE_BUILDING_TYPE_TO_NAME[building:GetType()],building)
end

function GameUIPResourceBuilding:CreateBetweenBgAndTitle()
    GameUIPResourceBuilding.super.CreateBetweenBgAndTitle(self)

    -- 加入军用帐篷info_layer
    self.info_layer = display.newLayer():addTo(self:GetView())
end

function GameUIPResourceBuilding:OnMoveInStage()
    GameUIPResourceBuilding.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "info",
        },
    },function(tag)
        if tag == 'info' then
            self.info_layer:setVisible(true)
        else
            self.info_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)
    self:ProduceIncreasePart()
    self:RebuildPart()
end


-- 构建对应资源生产加成条件是否达成部分
function GameUIPResourceBuilding:ProduceIncreasePart()
    -- 是否达成标识
    local building_x,building_y = self.building:GetLogicPosition()

    -- 匹配对应关系的小屋数量
    local house_count = #self.city:GetHousesAroundFunctionBuildingByType(self.building , self.building:GetHouseType(), 2)

    -- 周围小屋数量 3/6 是否达成
    local first_count = house_count>3 and 3 or house_count
    local info = {
        {
            _("达到")..first_count.."/3",string.format(_("+5%%%s"),
                P_RESOURCE_BUILDING_TYPE_TO_RESOURCE[self.building:GetType()]),
            house_count>2 and "yes_40x40.png" or "no_40x40.png"
        },
        {
            _("达到")..first_count.."/6",string.format(_("+5%%%s"),
                P_RESOURCE_BUILDING_TYPE_TO_RESOURCE[self.building:GetType()]),
            house_count>5 and "yes_40x40.png" or "no_40x40.png"
        },
    }
    -- bg
    local bg = WidgetInfoWithTitle.new({
        title = string.format(_("周围2格范围的%s数量"),Localize.building_name[self.building:GetHouseType()]),
        h = 146,
        info = info
    }):align(display.CENTER, display.cx, display.top-200):addTo(self.info_layer)

    local bg_size = bg:getContentSize()

end


-- 构建改建建筑部分
function GameUIPResourceBuilding:RebuildPart()
    local bg = WidgetUIBackGround.new({height=584,isFrame = "yes"}):align(display.CENTER, display.cx, display.top-570):addTo(self.info_layer)
    local bg_size = bg:getContentSize()
    -- title bg
    local title_bg = display.newSprite("title_blue_586x34.png"):align(display.TOP_CENTER, bg_size.width/2, bg_size.height-24):addTo(bg)
    local title_bg_size = title_bg:getContentSize()

    -- title label
    UIKit:ttfLabel(
        {
            text = _("改建"),
            size = 22,
            color =0xffedae,
            shadow= true
        }):align(display.CENTER, title_bg_size.width/2 ,title_bg_size.height/2)
        :addTo(title_bg)
    -- 可改建为其他三个类型
    -- 建筑iamge
    local building_image_width = 120
    local gap_x = (bg_size.width - building_image_width*3)/4
    local add_count = 0
    local rebuild_list = {}
    for k,r_type in pairs(P_RESOURCE_BUILDING_TYPE) do
        if self.building:GetType()~= r_type then
            local next_x =  gap_x*(add_count+1) + building_image_width/2+add_count*building_image_width
            local item_flag = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.CENTER, next_x, 450):addTo(bg)

            -- local build_png = SpriteConfig[r_type]:GetConfigByLevel(self.building:GetLevel()).png
            -- local builing_icon = display.newSprite(build_png)
            --     :align(display.CENTER, item_flag:getContentSize().width/2, item_flag:getContentSize().height/2)
            --     :addTo(item_flag)
            local config = SpriteConfig[r_type]:GetConfigByLevel(self.building:GetLevel())
            local configs = SpriteConfig[r_type]:GetAnimationConfigsByLevel(self.building:GetLevel())
            local building_image = display.newSprite(config.png, 0, 0)
                :align(display.CENTER, item_flag:getContentSize().width/2, item_flag:getContentSize().height/2)
                :addTo(item_flag)
            local p = building_image:getAnchorPointInPoints()
            for _,v in ipairs(configs) do
                if v.deco_type == "animation" then
                    local offset = v.offset
                    local armature = ccs.Armature:create(v.deco_name)
                        :addTo(building_image):scale(v.scale or 1)
                        :align(display.CENTER, offset.x or p.x, offset.y or p.y)
                    armature:getAnimation():setSpeedScale(2)
                    armature:getAnimation():playWithIndex(0)
                end
            end
            -- building name label
            local name_bg = display.newSprite("back_ground_134x30.png")
                :align(display.CENTER, next_x ,350)
                :addTo(bg)

            UIKit:ttfLabel(
                {
                    text = Localize.building_name[r_type],
                    size = 20,
                    color = 0xffedae
                }):align(display.CENTER, name_bg:getContentSize().width/2 ,name_bg:getContentSize().height/2)
                :addTo(name_bg)
            rebuild_list[add_count+1] = r_type
            building_image:setScale(building_image_width/building_image:getContentSize().width)
            add_count = add_count + 1
        end
    end
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",

    }
    local group = cc.ui.UICheckBoxButtonGroup.new(display.LEFT_TO_RIGHT):addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
        :align(display.LEFT_CENTER))
        :addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.LEFT_CENTER))
        :addButton(cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.LEFT_CENTER))
        :setButtonsLayoutMargin(0, 125, 0, 0)
        :onButtonSelectChanged(function(event)
            self.selected_rebuild_to_building = rebuild_list[event.selected]
            printf("Option %d selected, Option %d unselected", event.selected, event.last)
            print( self.selected_rebuild_to_building,"选中")
        end)
        :align(display.CENTER, 95 , 270)
        :addTo(bg)
    group:getButtonAtIndex(1):setButtonSelected(true)

    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = string.format(_("满足下列条件,可将%s改建成以上建筑,改建后该建筑的等级保留"),Localize.building_name[self.building:GetType()] ),
            font = UIKit:getFontFilePath(),
            size = 18,
            dimensions = cc.size(500,0),
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.CENTER, bg_size.width/2 ,230)
        :addTo(bg)

    local after_rebuild_max_house_num = City:GetMaxHouseCanBeBuilt(self.building:GetHouseType())-self.building:GetMaxHouseNum()
    -- 魔法石数量是否满足转换条件
    local need_gems = 100
    local info = {
        {
            string.format(_("%s数量"),Localize.building_name[self.building:GetHouseType()]),
            string.format(_("≤%d"),after_rebuild_max_house_num),
            #City:GetBuildingByType(self.building:GetHouseType())<=after_rebuild_max_house_num and "yes_40x40.png" or "no_40x40.png"
        },
        {
            _("金龙币"),
            string.format("%d/"..intInit.switchProductionBuilding.value,City:GetUser():GetGemResource():GetValue()),
            City:GetUser():GetGemResource():GetValue()>need_gems and "yes_40x40.png" or "no_40x40.png"
        },
    }
    -- bg
    local bg = WidgetInfo.new({
        h = 100,
        info = info
    }):align(display.CENTER, bg_size.width/2, 140):addTo(bg)


    cc.ui.UIPushButton.new({normal = "green_btn_up_250x66.png",pressed = "green_btn_down_250x66.png"})
        :setButtonLabel(UIKit:ttfLabel({text = _("立即转换"), size = 22, color = 0xffedae,shadow = true}))
        :onButtonClicked(function(event)
            if self:CheckSwitch(self.selected_rebuild_to_building) then
                if app:GetGameDefautlt():IsOpenGemRemind() then
                    UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                        string.formatnumberthousands(intInit.switchProductionBuilding.value)
                    ), function()
                        NetManager:getSwitchBuildingPromise(City:GetLocationIdByBuilding(self.building),self.selected_rebuild_to_building)
                        self:LeftButtonClicked()
                    end,true,true)
                else
                    NetManager:getSwitchBuildingPromise(City:GetLocationIdByBuilding(self.building),self.selected_rebuild_to_building)
                    self:LeftButtonClicked()
                end
            end
        end)
        :align(display.CENTER_RIGHT, bg_size.width-20, 50)
        :addTo(bg)
end
function GameUIPResourceBuilding:CheckSwitch(switch_to_building_type)
    local current_building = self.building
    local city = current_building:BelongCity()
    if city:GetUser():GetGemResource():GetValue()<intInit.switchProductionBuilding.value then
        UIKit:showMessageDialog(_("提示"),_("金龙币不足"))
            :CreateOKButton(
                {
                    listener = function ()
                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                        self:LeftButtonClicked()
                    end,
                    btn_name= _("前往商店")
                }
            )
        return
    elseif (city:GetMaxHouseCanBeBuilt(current_building:GetHouseType())-current_building:GetMaxHouseNum())<#city:GetBuildingByType(current_building:GetHouseType()) then
        UIKit:showMessageDialog(_("提示"),_("小屋数量过多"))
        return
    elseif current_building:IsUpgrading() then
        UIKit:showMessageDialog(_("提示"),_("建筑正在升级"))
        return
    end

    local config
    for i,v in ipairs(buildings) do
        if v.name==switch_to_building_type then
            config = v
        end
    end
    -- 等级大于5级时有升级前置条件
    if current_building:GetLevel()>5 then
        local configParams = string.split(config.preCondition,"_")
        local preType = configParams[1]
        local preName = configParams[2]
        local preLevel = tonumber(configParams[3])
        local limit
        if preType == "building" then
            local find_buildings = city:GetBuildingByType(preName)
            for i,v in ipairs(find_buildings) do
                if v:GetLevel()>=current_building:GetLevel()+preLevel then
                    limit = true
                end
            end
        else
            city:IteratorDecoratorBuildingsByFunc(function (index,house)
                if house:GetType() == preName and house:GetLevel()>=current_building:GetLevel()+preLevel then
                    limit = true
                end
            end)
        end
        if not limit then
            UIKit:showMessageDialog(_("提示"),string.format(_("前置建筑%s等级需要大于等于%d级"),Localize.building_name[preName],current_building:GetLevel()+preLevel))
                :CreateOKButton(
                    {
                        listener = function ()
                            self:GotoPreconditionBuilding(preName)
                        end,
                        btn_name= _("前往")
                    }
                )
            return
        end
    end
    return true
end
function GameUIPResourceBuilding:GotoPreconditionBuilding(preName)
    local jump_building = self.building:BelongCity():PreconditionByBuildingType(preName) or city:GetRuinsNotBeenOccupied()[1] or preName
    UIKit:GotoPreconditionBuilding(jump_building)
    self:LeftButtonClicked()
end
return GameUIPResourceBuilding











