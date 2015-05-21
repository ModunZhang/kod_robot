local cocos_promise = import('..utils.cocos_promise')
local promise = import('..utils.promise')
local TabButtons = import('.TabButtons')
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog= import("..widget.WidgetPopDialog")
local WidgetUseItems= import("..widget.WidgetUseItems")
local Localize = import("..utils.Localize")
local SpriteConfig = import("..sprites.SpriteConfig")
local window = import('..utils.window')
local intInit = GameDatas.PlayerInitData.intInit
local GameUIKeep = UIKit:createUIClass('GameUIKeep',"GameUIUpgradeBuilding")

local building_config_map = {
    ["keep"] = {scale = 0.3, offset = {x = 80, y = 74}},
    ["watchTower"] = {scale = 0.4, offset = {x = 80, y = 70}},
    ["warehouse"] = {scale = 0.5, offset = {x = 70, y = 70}},
    ["dragonEyrie"] = {scale = 0.35, offset = {x = 70, y = 70}},
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
}

function GameUIKeep:ctor(city,building,default_tab)
    GameUIKeep.super.ctor(self,city,_("城堡"),building,default_tab)
end

function GameUIKeep:OnMoveInStage()
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "info",
        },
    }, function(tag)
        if tag == 'info' then
            if not self.info_layer then
                self.info_layer = display.newLayer():addTo(self:GetView())
                self:CreateCanBeUnlockedBuildingBG()
                self:CreateCanBeUnlockedBuildingListView()
                self:CreateCityBasicInfo()
                self.city:AddListenOnType(self, City.LISTEN_TYPE.CITY_NAME)
            end
            self.info_layer:setVisible(true)
        else
            if self.info_layer then
                self.info_layer:setVisible(false)
            end
        end
    end):pos(window.cx, window.bottom + 34)
    GameUIKeep.super.OnMoveInStage(self)
end

function GameUIKeep:onExit()
    self.city:RemoveListenerOnType(self, City.LISTEN_TYPE.CITY_NAME)
    GameUIKeep.super.onExit(self)
end

function GameUIKeep:CreateCityBasicInfo()

    -- 建筑图片 放置区域左右边框
    local left_frame = cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, display.cx-250, display.top-175)
        :addTo(self.info_layer)
    left_frame:setFlippedX(true)
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, display.cx-145, display.top-175)
        :addTo(self.info_layer)

    local building_cp = building_config_map[self.building:GetType()]
    local build_png = SpriteConfig[self.building:GetType()]:GetConfigByLevel(self.building:GetLevel()).png
    local building_image = display.newSprite(build_png, 0, 0)
        :addTo(left_frame):pos(building_cp.offset.x, building_cp.offset.y)
        :scale(building_cp.scale)

    local city_postion = "0,0"
    if not Alliance_Manager:GetMyAlliance():IsDefault() then
        local alliance = Alliance_Manager:GetMyAlliance()
        local mapObject = alliance:GetAllianceMap():FindMapObjectById(alliance:GetSelf():MapId())
        local x, y = mapObject:GetLogicPosition()
        city_postion = x..","..y
    end
    self:CreateLineItem({
        title_1 =  _("城市坐标"),
        title_2 =  "("..city_postion..")",
    }):align(display.LEFT_CENTER, display.cx-120, display.top-160)
        :addTo(self.info_layer)
    -- 修改地形
    self:CreateLineItem({
        title_1 =  _("城市地形"),
        title_2 =  Localize.terrain[User:Terrain()],
        button_label =  _("修改"),
        listener =  function ()
            self:CreateChangeTerrainWindow()
        end,
    }):align(display.LEFT_CENTER, display.cx-120, display.top-240)
        :addTo(self.info_layer)
end

function GameUIKeep:CreateLineItem(params)
    -- 分割线
    local line = display.newSprite("dividing_line.png")
    local line_size = line:getContentSize()
    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = params.title_1,
            font = UIKit:getFontFilePath(),
            size = 16,
            color = UIKit:hex2c3b(0x665f49)
        }):align(display.LEFT_BOTTOM, 0, 34)
        :addTo(line)
    local value_label = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = params.title_2,
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0x29261c)
        }):align(display.LEFT_BOTTOM, 0, 2)
        :addTo(line)
    if params.button_label then
        local button = WidgetPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"}
            ,{}
            ,{
                disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
            })
            :setButtonLabel(UIKit:ttfLabel({
                text = params.button_label,
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    params.listener()
                end
            end)
            :align(display.RIGHT_BOTTOM, line_size.width, 5)
            :addTo(line)
    end
    function line:SetValue(value)
        value_label:setString(value)
    end
    return line
end

function GameUIKeep:CreateCanBeUnlockedBuildingBG()
    -- 主背景
    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("可解锁建筑"),
        font = UIKit:getFontFilePath(),
        size = 24,
        color = UIKit:hex2c3b(0x403c2f)})
        :align(display.CENTER,window.cx, window.bottom_top+600)
        :addTo(self.info_layer)
    -- tips
    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("提示:升级城堡获得解锁建筑机会!"),
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x403c2f)})
        :align(display.CENTER, display.cx,display.top-850)
        :addTo(self.info_layer)
end

function GameUIKeep:CreateCanBeUnlockedBuildingListView()
    local building_introduces = Localize.building_description


    self.building_listview ,self.listnode=  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 495),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    self.listnode:addTo(self.info_layer):pos(window.cx,window.bottom_top + 60)
    self.listnode:align(display.BOTTOM_CENTER)
    local buildings = GameDatas.Buildings.buildings
    local unlock_index = 1
    for i,v in ipairs(buildings) do
        if v.location<21 then
            local unlock_building = City:GetBuildingByLocationId(v.location)
            local tile = City:GetTileByLocationId(v.location)

            local b_x,b_y =tile.x,tile.y
            -- 建筑是否可解锁
            local canUnlock = City:IsTileCanbeUnlockAt(b_x,b_y)
            -- 建筑已经解锁
            local isUnlocked = City:IsUnLockedAtIndex(b_x,b_y)
            local content = cc.ui.UIGroup.new()
            local item = self.building_listview:newItem()
            item:setItemSize(568, 144)
            local item_width, item_height = item:getItemSize()

            if canUnlock or isUnlocked then
                content:addWidget(WidgetPushButton.new({normal = "back_ground_568X142.png",pressed = "back_ground_568X142.png"})
                    :onButtonClicked(function(event)
                        if event.name == "CLICKED_EVENT" then
                            if canUnlock then
                                self:LeftButtonClicked()
                                display.getRunningScene():GotoLogicPoint(unlock_building:GetMidLogicPosition())
                            end
                        end
                    end))

            else
                content:addWidget(display.newSprite("back_ground_568X142.png"))
            end

            local title_bg = display.newSprite("title_blue_412x30.png"):pos(70,46)
            content:addWidget(title_bg)
            -- building name
            UIKit:ttfLabel({
                text = _(Localize.building_name[unlock_building:GetType()]),
                size = 22,
                color = 0xffedae}):align(display.CENTER_LEFT, 14, title_bg:getContentSize().height/2)
                :addTo(title_bg)
            if canUnlock then
                display.newSprite("activity_next_32x37.png"):align(display.CENTER, 260, 0):addTo(content, 10)
            end

            UIKit:ttfLabel({
                text = isUnlocked and  _("已解锁") or _("未解锁"),
                size = 18,
                color = isUnlocked and 0x0db13c or 0xffedae}):align(display.CENTER_RIGHT, title_bg:getContentSize().width-30, title_bg:getContentSize().height/2)
                :addTo(title_bg)

            -- building introduce
            local building_tip = UIKit:ttfLabel({
                text = building_introduces[unlock_building:GetType()],
                size = 20,
                aglin = ui.TEXT_ALIGN_LEFT,
                valign = ui.TEXT_VALIGN_CENTER,
                dimensions = cc.size(374, 0),
                color = 0x615b44}):align(display.CENTER_LEFT, -120, -10)
            content:addWidget(building_tip)

            -- 建筑图片 放置区域左右边框
            local filp_bg = cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, -item_width/2+30, 0):scale(0.9)
            filp_bg:setFlippedX(true)
            content:addWidget(filp_bg)
            content:addWidget(cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, -item_width/2+125, 0):scale(0.9))

            local building_cp = building_config_map[unlock_building:GetType()]

            local build_png = SpriteConfig[unlock_building:GetType()]:GetConfigByLevel(unlock_building:GetLevel()==0 and 1 or unlock_building:GetLevel()).png
            local building_image = display.newSprite(build_png, building_cp.offset.x, building_cp.offset.y,{class=cc.FilteredSpriteWithOne})
                :scale(building_cp.scale)
                :addTo(filp_bg)
            if not isUnlocked then
                local my_filter = filter
                local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
                building_image:setFilter(filters)
            end
            item:addContent(content)

            self.building_listview:addItem(item,isUnlocked and unlock_index)
            if isUnlocked then
                unlock_index = unlock_index + 1
            end
        end
    end
    self.building_listview:reload()
end

function GameUIKeep:CreateModifyCityNameWindow()
    WidgetUseItems.new():Create({item_type = WidgetUseItems.USE_TYPE.CHANGE_CITY_NAME}):AddToCurrentScene()
end

function GameUIKeep:CreateChangeTerrainWindow()
    local layer = WidgetPopDialog.new(450,_("城市地形修改")):addTo(self,201)
    local body = layer:GetBody()

    local bg1 = display.newScale9Sprite("back_ground_104x132.png",x,y,cc.size(580,264),cc.rect(10,10,84,112))
        :addTo(body):align(display.CENTER,304, 294)

    self.terrain_eff_label = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x514d3e)
    }):addTo(bg1):align(display.CENTER,304,30)


    -- 草地
    local grass_box = display.newSprite("box_132x132_1.png")
        :align(display.CENTER, 110, 180):addTo(bg1)
    local box_size = grass_box:getContentSize()
    local grass = display.newSprite("icon_grass_132x132.png")
        :align(display.CENTER, box_size.width/2,box_size.height/2):addTo(grass_box)
    -- 沙漠
    local icefield_box = display.newSprite("box_132x132_1.png")
        :align(display.CENTER, 295, 180):addTo(bg1)
    local icefield = display.newSprite("icon_icefield_132x132.png")
        :align(display.CENTER, box_size.width/2,box_size.height/2):addTo(icefield_box)
    -- 雪地
    local desert_box = display.newSprite("box_132x132_1.png")
        :align(display.CENTER, 482, 180):addTo(bg1)
    local desert = display.newSprite("icon_desert_132x132.png")
        :align(display.CENTER, box_size.width/2,box_size.height/2):addTo(desert_box)

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
        :setButtonsLayoutMargin(0, 130, 0, 0)
        :onButtonSelectChanged(function(event)
            -- self.selected_rebuild_to_building = rebuild_list[event.selected]
            local t_name = {
                {
                    _("草地"),
                    _("绿龙"),
                },
                {
                    _("雪地"),
                    _("蓝龙"),
                },
                {
                    _("沙漠"),
                    _("红龙"),
                },
            }
            self.terrain_eff_label:setString(string.format(_("%s地形能提升50%% %s的活力回复速度"),t_name[event.selected][1],t_name[event.selected][2]))

        end)
        :align(display.CENTER, 80 , 50)
        :addTo(bg1)

    local terrain = User:Terrain()
    local default_index = 0
    if terrain == "grassLand" then
        default_index = 1
    elseif terrain == "iceField" then
        default_index = 2
    elseif terrain == "desert" then
        default_index = 3
    end


    group:getButtonAtIndex(default_index):setButtonSelected(true)
    local bg2 = WidgetUIBackGround.new({width = 568,height = 140},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :addTo(body):align(display.CENTER, 304, 84)

    local prop_bg = display.newSprite("box_118x118.png")
        :align(display.LEFT_CENTER, 10, 70):addTo(bg2)
    display.newSprite("change_city_name.png")
        :align(display.CENTER, 59, 59):addTo(prop_bg):scale(100/128)
    local num_bg = display.newSprite("back_ground_118x36.png")
        :align(display.CENTER, 480, 100):addTo(bg2)
    local gem_img = display.newSprite("gem_icon_62x61.png")
        :align(display.LEFT_CENTER, -4, 16):addTo(num_bg):scale(0.7)
    self.number = cc.ui.UILabel.new({
        size = 20,
        text = intInit.changeTerrainNeedGemCount.value,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x423f32)
    }):addTo(num_bg):align(display.CENTER,60,18)

    local label_1 = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("变换地形"),
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0x514d3e)
        }):align(display.LEFT_CENTER, 140, 110)
        :addTo(bg2)

    local label_2 = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("提供兵种招募，升级增加每次招募的最大数量"),
            font = UIKit:getFontFilePath(),
            size = 20,
            dimensions = cc.size(260,100),
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_TOP, 140, 80)
        :addTo(bg2)
    -- 回复按钮
    local buy_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("购买使用"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)})

    buy_label:enableShadow()
    WidgetPushButton.new(
        {normal = "green_btn_up_148x58.png", pressed = "green_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(buy_label)
        :addTo(bg2):align(display.CENTER, 480, 45)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if User:GetGemResource():GetValue()<intInit.changeTerrainNeedGemCount.value then
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
                end
                local selected_index = 1
                for i=1,group:getButtonsCount() do
                    if group:getButtonAtIndex(i):isButtonSelected() then
                        selected_index = i
                        break
                    end
                end
                if selected_index==default_index then
                    UIKit:showMessageDialog(_("提示"),_("请选择不同的地形"))
                    return
                end
                if selected_index == 1 then
                    NetManager:getChangeToGrassPromise():done(function()
                        self:PlayCloudAnimation()
                    end)
                elseif selected_index == 2 then
                    NetManager:getChangeToIceFieldPromise():done(function()
                        self:PlayCloudAnimation()
                    end)
                elseif selected_index == 3 then
                    NetManager:getChangeToDesertPromise():done(function()
                        self:PlayCloudAnimation()
                    end)
                end
            end
        end)
end
function GameUIKeep:PlayCloudAnimation()
    local armature = ccs.Armature:create("Cloud_Animation"):addTo(display.getRunningScene(),5000):pos(display.cx, display.cy)
    cc.LayerColor:create(UIKit:hex2c4b(0x00ffffff)):addTo(display.getRunningScene(),5000):runAction(
        transition.sequence{
            cc.CallFunc:create(function() armature:getAnimation():play("Animation1", -1, 0) end),
            cc.FadeIn:create(0.75),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(function() armature:getAnimation():play("Animation4", -1, 0) end),
            cc.CallFunc:create(function() self:LeftButtonClicked() end),
            cc.FadeOut:create(0.75),
            cc.CallFunc:create(function() 
                armature:removeFromParent()
            end),
        }
    )
end
function GameUIKeep:CreateBackGroundWithTitle(title_string)
    local leyer = display.newColorLayer(cc.c4b(0,0,0,127))
    local body = WidgetUIBackGround.new({height=450}):align(display.TOP_CENTER,display.cx,display.top-200)
        :addTo(leyer)
    local rb_size = body:getContentSize()
    local title = display.newSprite("title_blue_600x56.png"):align(display.CENTER, rb_size.width/2, rb_size.height)
        :addTo(body)
    local title_label = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = title_string,
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0xffedae)
        }):align(display.CENTER, title:getContentSize().width/2, title:getContentSize().height/2)
        :addTo(title)
    -- close button
    cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"})
        :onButtonClicked(function(event)
            leyer:removeFromParent()
        end):align(display.CENTER, title:getContentSize().width-10, title:getContentSize().height-10)
        :addTo(title)
    function leyer:addToBody(node)
        node:addTo(body)
        return node
    end
    return leyer
end



return GameUIKeep







