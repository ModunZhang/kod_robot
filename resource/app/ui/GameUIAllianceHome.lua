local Localize = import("..utils.Localize")
local window = import("..utils.window")
local WidgetEventTabButtons = import("..widget.WidgetEventTabButtons")
local UIPageView = import("..ui.UIPageView")
local Flag = import("..entity.Flag")
local Alliance = import("..entity.Alliance")
local SoldierManager = import("..entity.SoldierManager")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local WidgetAllianceTop = import("..widget.WidgetAllianceTop")
local GameUIAllianceContribute = import(".GameUIAllianceContribute")
local GameUIHelp = import(".GameUIHelp")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local WidgetChat = import("..widget.WidgetChat")
local WidgetNumberTips = import("..widget.WidgetNumberTips")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetAutoOrder = import("..widget.WidgetAutoOrder")
local WidgetMarchEvents = import("app.widget.WidgetMarchEvents")
local GameUIAllianceHome = UIKit:createUIClass('GameUIAllianceHome')
local buildingName = GameDatas.AllianceInitData.buildingName
local Alliance_Manager = Alliance_Manager
local cc = cc
function GameUIAllianceHome:ctor(alliance)
    GameUIAllianceHome.super.ctor(self)
    self.alliance = alliance
end
function GameUIAllianceHome:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIAllianceHome:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIAllianceHome:IsDisplayOn()
    return self.visible_count > 0
end
function GameUIAllianceHome:FadeToSelf(isFullDisplay)
    self:setCascadeOpacityEnabled(true)
    local opacity = isFullDisplay == true and 255 or 0
    local p = isFullDisplay and 0 or 99999999
    transition.fadeTo(self, {opacity = opacity, time = 0.2,
        onComplete = function()
            self:pos(p, p)
        end
    })
end


function GameUIAllianceHome:onEnter()
    GameUIAllianceHome.super.onEnter(self)
    self.city = City
    self.visible_count = 1
    self.top = self:CreateTop()
    self.bottom = self:CreateBottom()


    local ratio = self.bottom:getScale()
    local rect1 = self.chat:getCascadeBoundingBox()
    local x, y = rect1.x, rect1.y + rect1.height - 2
    local march = WidgetMarchEvents.new(self.alliance, ratio):addTo(self):pos(x, y)
    self:AddMapChangeButton()
    self:InitArrow()
    if self.top then
        self.top:Refresh()
    end
    -- 中间按钮
    self:CreateOperationButton()
    self:AddOrRemoveListener(true)
end
function GameUIAllianceHome:onExit()
    self:AddOrRemoveListener(false)
    GameUIAllianceHome.super.onExit(self)
end
function GameUIAllianceHome:AddOrRemoveListener(isAdd)
    local city = self.city
    if isAdd then
        self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
        self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.MEMBER)
        self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.ALLIANCE_FIGHT)
        self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.FIGHT_REQUESTS)
        city:AddListenOnType(self, city.LISTEN_TYPE.UPGRADE_BUILDING)
        city:AddListenOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
        city:AddListenOnType(self,city.LISTEN_TYPE.HELPED_TO_TROOPS)
        city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
        city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
        local alliance_belvedere = self.alliance:GetAllianceBelvedere()
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnMarchDataChanged)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnCommingDataChanged)
        -- 添加到全局计时器中，以便显示各个阶段的时间
        app.timer:AddListener(self)
    else
        app.timer:RemoveListener(self)
        self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
        self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.MEMBER)
        self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.ALLIANCE_FIGHT)
        self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.FIGHT_REQUESTS)
        city:RemoveListenerOnType(self, city.LISTEN_TYPE.UPGRADE_BUILDING)
        city:RemoveListenerOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
        city:RemoveListenerOnType(self,city.LISTEN_TYPE.HELPED_TO_TROOPS)
        city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
        city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
        local alliance_belvedere = self.alliance:GetAllianceBelvedere()
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnMarchDataChanged)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnCommingDataChanged)
    end
end

function GameUIAllianceHome:AddMapChangeButton()
    WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OUR_ALLIANCE):addTo(self)
end
function GameUIAllianceHome:OnMarchDataChanged()
    self:OnHelpToTroopsChanged()
end
function GameUIAllianceHome:OnCommingDataChanged()
    self:OnHelpToTroopsChanged()
end

function GameUIAllianceHome:OnHelpToTroopsChanged()
    self.operation_button_order:RefreshOrder()
end

function GameUIAllianceHome:InitArrow()
    local rect1 = self.bottom:getCascadeBoundingBox()
    local rect2 = self.top_bg:getCascadeBoundingBox()
    self.screen_rect = cc.rect(0, rect1.height, display.width, rect2.y - rect1.height)

    -- my alliance building
    self.alliance_building_arrows = {}
    -- enemys
    self.enemy_arrows = {}

    -- my city
    self.arrow = cc.ui.UIPushButton.new({normal = "location_arrow_up.png",
        pressed = "location_arrow_down.png"})
        :addTo(self, -1):align(display.TOP_CENTER):hide()
        :onButtonClicked(function()
            self:ReturnMyCity()
            local map = {
                woodVillage = 0,
                stoneVillage= 0,
                ironVillage = 0,
                foodVillage = 0,
                coinVillage = 0,
            }
            self.alliance:GetAllianceMap():IteratorAllObjects(function(_, entity)
                if entity:GetType() == "village" then
                    map[entity:GetName()] = map[entity:GetName()] + 1
                end
            end)
            for k,v in pairs(map) do
                print(Localize.village_name[k], v)
            end
        end)
    self.arrow_label = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xf5e8c4)
    }):addTo(self.arrow):rotation(90):align(display.LEFT_CENTER, 0, -40)
end
function GameUIAllianceHome:ReturnMyCity()
    local scene = display.getRunningScene()
    local alliance = scene:GetAlliance()
    local mapObject = alliance:GetAllianceMap():FindMapObjectById(alliance:GetSelf():MapId())
    local location = mapObject.location
    scene:GotoLogicPosition(location.x, location.y, alliance:Id())
end
function GameUIAllianceHome:CreateOperationButton()
    local order = WidgetAutoOrder.new(WidgetAutoOrder.ORIENTATION.BOTTOM_TO_TOP):addTo(self):pos(display.right-50,420)

    local first_row = 420
    local first_col = 177
    local label_padding = 100
    for i, v in ipairs({
        {"fight_62x70.png", _("战斗")},
    }) do
        local col = i - 1
        local y =  first_row + col*label_padding
        local button = WidgetPushButton.new({normal = v[1]})
            :onButtonClicked(handler(self, self.OnMidButtonClicked))
            :setButtonLabel("normal",cc.ui.UILabel.new({text = v[2],
                size = 16,
                font = UIKit:getFontFilePath(),
                color = UIKit:hex2c3b(0xf5e8c4)}
            )
            )
            :setButtonLabelOffset(0, -40)
        button:setTag(i)
        button:setTouchSwallowEnabled(true)

        function button:GetElementSize()
            return button:getCascadeBoundingBox().size
        end
        if i == 1 then
            local alliance = self.alliance
            local alliance_belvedere = alliance:GetAllianceBelvedere()
            local __,count = alliance_belvedere:HasEvents()
            self.alliance_belvedere_events_count = WidgetNumberTips.new():addTo(button):pos(20,-20)
            self.alliance_belvedere_events_count:SetNumber(count)
            print("CheckVisible----->1",count)
            function button:CheckVisible()
                local hasEvent,count = alliance_belvedere:HasEvents()
                if self.alliance_belvedere_events_count then
                    print("CheckVisible----->2",count)
                    self.alliance_belvedere_events_count:SetNumber(count)
                end
                return hasEvent
            end
        end
        order:AddElement(button)
    end
    order:RefreshOrder()
    self.operation_button_order = order
end
function GameUIAllianceHome:OnUpgradingBegin()
end
function GameUIAllianceHome:OnUpgrading()
end
function GameUIAllianceHome:OnUpgradingFinished()
    self.operation_button_order:RefreshOrder()
end
function GameUIAllianceHome:OnMilitaryTechEventsChanged()
    self.operation_button_order:RefreshOrder()
end
function GameUIAllianceHome:OnSoldierStarEventsChanged()
    self.operation_button_order:RefreshOrder()
end
function GameUIAllianceHome:OnProductionTechnologyEventDataChanged()
    self.operation_button_order:RefreshOrder()
end

function GameUIAllianceHome:TopBg()
    local top_bg = display.newSprite("alliance_home_top_bg_768x116.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    if display.width >640 then
        top_bg:scale(display.width/768)
    end
    top_bg:setTouchEnabled(true)
    self.top_bg = top_bg

    top_bg:setTouchSwallowEnabled(true)
    local t_size = top_bg:getContentSize()

    -- 顶部背景,为按钮
    local top_self_bg = WidgetPushButton.new({normal = "button_blue_normal_314X88.png",
        pressed = "button_blue_pressed_314X88.png"})
        :onButtonClicked(handler(self, self.OnTopButtonClicked))
        :align(display.TOP_CENTER, t_size.width/2-160, t_size.height-4)
        :addTo(top_bg)
    local top_enemy_bg = WidgetPushButton.new({normal = "button_red_normal_314X88.png",
        pressed = "button_red_pressed_314X88.png"})
        :onButtonClicked(handler(self, self.OnTopButtonClicked))
        :align(display.TOP_CENTER, t_size.width/2+160, t_size.height-4)
        :addTo(top_bg)

    return top_self_bg,top_enemy_bg
end

function GameUIAllianceHome:TopTabButtons()
    self.page_top = WidgetAllianceTop.new(self.alliance):align(display.TOP_CENTER,self.top_bg:getContentSize().width/2,26)
        :addTo(self.top_bg)
end

function GameUIAllianceHome:CreateTop()
    local alliance = self.alliance
    local Top = {}
    local top_self_bg,top_enemy_bg = self:TopBg()
    -- 己方联盟名字
    local self_name_bg = display.newSprite("title_green_292X32.png")
        :align(display.LEFT_CENTER, -147,-26)
        :addTo(top_self_bg):flipX(true)
    self.self_name_bg = self_name_bg
    self.self_name_label = UIKit:ttfLabel(
        {
            text = "["..alliance:Tag().."] "..alliance:Name(),
            size = 18,
            color = 0xffedae,
            dimensions = cc.size(160,18),
            ellipsis = true
        }):align(display.LEFT_CENTER, 30, 20)
        :addTo(self_name_bg)
    -- 己方联盟旗帜
    local ui_helper = WidgetAllianceHelper.new()
    local self_flag = ui_helper:CreateFlagContentSprite(alliance:Flag()):scale(0.5)
    self_flag:align(display.CENTER, self_name_bg:getContentSize().width-100, -30):addTo(self_name_bg)
    self.self_flag = self_flag
    -- 敌方联盟名字
    local enemy_name_bg = display.newSprite("title_red_292X32.png")
        :align(display.RIGHT_CENTER, 147,-26)
        :addTo(top_enemy_bg)
    local enemy_name_label = UIKit:ttfLabel(
        {
            text = "",
            size = 18,
            color = 0xffedae,
            dimensions = cc.size(160,18),
            ellipsis = true
        }):align(display.LEFT_CENTER, 100, 20)
        :addTo(enemy_name_bg)
    local enemy_peace_label = UIKit:ttfLabel(
        {
            text = _("请求开战玩家"),
            size = 18,
            color = 0xffedae
        }):align(display.LEFT_CENTER, -20,-26)
        :addTo(top_enemy_bg)

    -- 和平期,战争期,准备期背景
    local period_bg = display.newSprite("box_104x104.png")
        :align(display.TOP_CENTER, self.top_bg:getContentSize().width/2,self.top_bg:getContentSize().height)
        :addTo(self.top_bg)

    local period_text = self:GetAlliancePeriod()
    local period_label = UIKit:ttfLabel(
        {
            text = period_text,
            size = 16,
            color = 0xbdb582
        }):align(display.TOP_CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height-14)
        :addTo(period_bg)
    self.time_label = UIKit:ttfLabel(
        {
            text = "",
            size = 18,
            color = 0xffedae
        }):align(display.BOTTOM_CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height/2-10)
        :addTo(period_bg)
    -- 己方战力
    local self_power_bg = display.newSprite("power_background_146x26.png")
        :align(display.LEFT_CENTER, -107, -65):addTo(top_self_bg)
    local our_num_icon = cc.ui.UIImage.new("power_24x29.png"):align(display.CENTER, -107, -65):addTo(top_self_bg)
    local self_power_label = UIKit:ttfLabel(
        {
            text = string.formatnumberthousands(alliance:Power()),
            size = 20,
            color = 0xbdb582
        }):align(display.LEFT_CENTER, 20, self_power_bg:getContentSize().height/2)
        :addTo(self_power_bg)
    -- 敌方战力
    local enemy_power_bg = display.newSprite("power_background_146x26.png")
        :align(display.LEFT_CENTER, -20, -65):addTo(top_enemy_bg)
    local enemy_num_icon = cc.ui.UIImage.new("power_24x29.png")
        :align(display.CENTER, 0, enemy_power_bg:getContentSize().height/2)
        :addTo(enemy_power_bg)
    local enemy_power_label = UIKit:ttfLabel(
        {
            text = "",
            size = 20,
            color = 0xbdb582
        }):align(display.LEFT_CENTER, 20, enemy_power_bg:getContentSize().height/2)
        :addTo(enemy_power_bg)

    self:TopTabButtons()

    local home = self
    function Top:Refresh()
        local alliance = home.alliance
        local status = alliance:Status()
        local enemyAlliance = Alliance_Manager:GetEnemyAlliance()
        period_label:setString(home:GetAlliancePeriod())
        -- 和平期
        if status=="peace" then
            enemy_name_bg:setVisible(false)
            enemy_peace_label:setVisible(true)
        else
            enemy_name_bg:setVisible(true)
            enemy_peace_label:setVisible(false)

            -- 敌方联盟旗帜
            if enemy_name_bg:getChildByTag(201) then
                enemy_name_bg:removeChildByTag(201, true)
            end
            if status=="fight" or status=="prepare" then
                local enemy_flag = ui_helper:CreateFlagContentSprite(enemyAlliance:Flag()):scale(0.5)
                enemy_flag:align(display.CENTER,100-enemy_flag:getCascadeBoundingBox().size.width, -30)
                    :addTo(enemy_name_bg)
                enemy_flag:setTag(201)
                enemy_name_label:setString("["..enemyAlliance:Tag().."] "..enemyAlliance:Name())
            elseif status=="protect" then
                local enemy_reprot_data = alliance:GetEnemyLastAllianceFightReportsData()
                local enemy_flag = ui_helper:CreateFlagContentSprite(Flag.new():DecodeFromJson(enemy_reprot_data.flag)):scale(0.5)
                enemy_flag:align(display.CENTER,100-enemy_flag:getCascadeBoundingBox().size.width, -30)
                    :addTo(enemy_name_bg)
                enemy_flag:setTag(201)
                enemy_name_label:setString("["..enemy_reprot_data.tag.."] "..enemy_reprot_data.name)
            end
        end
        if status=="fight"  then
            our_num_icon:setTexture("battle_33x33.png")
            enemy_num_icon:setTexture("battle_33x33.png")
            enemy_num_icon:scale(1.0)

            self:SetOurPowerOrKill(alliance:GetMyAllianceFightCountData().kill)
            self:SetEnemyPowerOrKill(alliance:GetEnemyAllianceFightCountData().kill)
        elseif status=="protect" then
            our_num_icon:setTexture("battle_33x33.png")
            enemy_num_icon:setTexture("battle_33x33.png")
            enemy_num_icon:scale(1.0)
            local our_reprot_data_kill = alliance:GetOurLastAllianceFightReportsData().kill
            local enemy_reprot_data_kill = alliance:GetEnemyLastAllianceFightReportsData().kill
            self:SetOurPowerOrKill(our_reprot_data_kill)

            self:SetEnemyPowerOrKill(enemy_reprot_data_kill)

        else
            if status~="peace" then
                enemy_num_icon:setTexture("power_24x29.png")
                self:SetEnemyPowerOrKill(enemyAlliance:Power())
                enemy_num_icon:scale(1.0)
            else
                enemy_num_icon:setTexture("res_citizen_44x50.png")
                enemy_num_icon:scale(0.7)
                self:SetEnemyPowerOrKill(alliance:GetFightRequestPlayerNum())
            end
            our_num_icon:setTexture("power_24x29.png")
            self:SetOurPowerOrKill(alliance:Power())
        end
    end
    function Top:SetOurPowerOrKill(num)
        self_power_label:setString(string.formatnumberthousands(num))
    end
    function Top:SetEnemyPowerOrKill(num)
        enemy_power_label:setString(string.formatnumberthousands(num))
    end
    return Top
end

function GameUIAllianceHome:OnAllianceFightRequestsChanged(request_num)
    if self.alliance:Status() == "peace" then
        self.top:SetEnemyPowerOrKill(request_num)
    end
end
function GameUIAllianceHome:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(self.city):addTo(self)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)
    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)
    return bottom_bg
end
function GameUIAllianceHome:OnTopButtonClicked(event)
    print("OnTopButtonClicked=",event.name)
    if event.name == "CLICKED_EVENT" then
        UIKit:newGameUI("GameUIAllianceBattle", self.city):AddToCurrentScene(true)
    end
end
function GameUIAllianceHome:OnMidButtonClicked(event)
    local tag = event.target:getTag()
    if not tag then return end
    if tag == 1 then -- 战斗
        local default_tab = 'march'
        local alliance = self.alliance
        local alliance_belvedere = alliance:GetAllianceBelvedere()
        local hasMarch,__ = alliance_belvedere:HasMyEvents()
        if not hasMarch then
            local hasComming,__ = alliance_belvedere:HasOtherEvents()
            if hasComming then
                default_tab = 'comming'
            end
        end
        UIKit:newGameUI('GameUIWathTowerRegion',self.city,default_tab):AddToCurrentScene(true)
    end
end

function GameUIAllianceHome:OnAllianceBasicChanged(alliance,changed_map)
    local alliance = self.alliance
    if changed_map.honour then
        self.page_top:SetHonour(GameUtils:formatNumber(changed_map.honour.new))
    elseif changed_map.status then
        self.top:Refresh()
    elseif changed_map.name then
        self.self_name_label:setString("["..alliance:Tag().."] "..changed_map.name.new)
    elseif changed_map.tag then
        self.self_name_label:setString("["..changed_map.tag.new.."] ".. alliance:Name())
    elseif changed_map.flag then
        self.self_flag:removeFromParent(true)
        -- 己方联盟旗帜
        local ui_helper = WidgetAllianceHelper.new()
        local self_flag = ui_helper:CreateFlagContentSprite(alliance:Flag()):scale(0.5)
        self_flag:align(display.CENTER, self.self_name_bg:getContentSize().width-100, -30):addTo(self.self_name_bg)
        self.self_flag = self_flag
    end
end
function GameUIAllianceHome:OnMemberChanged(alliance)
    local self_member = alliance:GetMemeberById(DataManager:getUserData()._id)
    self.page_top:SetLoyalty(GameUtils:formatNumber(self_member.loyalty))
end
-- function GameUIAllianceHome:OnAllianceCountInfoChanged(alliance,countInfo)
--     self.count = 0
--     local status = self.alliance:Status()
--     if status=="fight" or status=="protect" then
--         print("self.count",self.count)
--         LuaUtils:outputTable("GameUIAllianceHome:OnAllianceCountInfoChanged==countInfo", countInfo)
--         self.count = self.count + 1
--         if countInfo.kill then
--             self.top:SetOurPowerOrKill(countInfo.kill)
--         end
--         if countInfo.beKilled then
--             self.top:SetEnemyPowerOrKill(countInfo.beKilled)
--         end
--     end
-- end
local deg = math.deg
local ceil = math.ceil
local point = cc.p
local pSub = cc.pSub
local pGetAngle = cc.pGetAngle
local pGetLength = cc.pGetLength
local rectContainsPoint = cc.rectContainsPoint
local RIGHT_CENTER = display.RIGHT_CENTER
local LEFT_CENTER = display.LEFT_CENTER
local MID_POINT = point(display.cx, display.cy)
local function pGetIntersectPoint(pt1,pt2,pt3,pt4)
    local s,t, ret = 0,0,false
    ret,s,t = cc.pIsLineIntersect(pt1,pt2,pt3,pt4,s,t)
    if ret then
        return point(pt1.x + s * (pt2.x - pt1.x), pt1.y + s * (pt2.y - pt1.y)), s
    else
        return point(0,0), s
    end
end
function GameUIAllianceHome:OnSceneMove(logic_x, logic_y, alliance_view)
    if self.alliance:IsDefault() then return end
    self:UpdateCoordinate(logic_x, logic_y, alliance_view)
    self:UpdateAllArrows(logic_x, logic_y, alliance_view)
end
function GameUIAllianceHome:UpdateCoordinate(logic_x, logic_y, alliance_view)
    local coordinate_str = string.format("%d, %d", logic_x, logic_y)
    local is_mine
    if alliance_view then
        is_mine = alliance_view:GetAlliance():Id() == self.alliance:Id() and _("我方") or _("敌方")
    else
        is_mine = _("坐标")
    end
    self.page_top:SetCoordinateTitle(is_mine)
    self.page_top:SetCoordinate(coordinate_str)
end
function GameUIAllianceHome:UpdateAllArrows(logic_x, logic_y, alliance_view)
    local layer = alliance_view:GetLayer()
    local screen_rect = self.screen_rect
    local alliance = self.alliance
    local x,y = alliance:GetAllianceMap():FindMapObjectById(alliance:GetSelf():MapId()):GetMidLogicPosition()
    self:UpdateMyCityArrows(screen_rect, alliance, layer, x,y)
    self:UpdateMyAllianceBuildingArrows(screen_rect, alliance, layer)
    if Alliance_Manager:HaveEnemyAlliance() then
        self:UpdateEnemyArrows(screen_rect, Alliance_Manager:GetEnemyAlliance(), layer, logic_x, logic_y)
    end
end
function GameUIAllianceHome:UpdateMyCityArrows(screen_rect, alliance, layer, x, y)
    local map_point = layer:ConvertLogicPositionToMapPosition(x, y, alliance:Id())
    local world_point = layer:convertToWorldSpace(map_point)
    if not rectContainsPoint(screen_rect, world_point) then
        local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
        if p and degree then
            degree = degree + 180
            self.arrow:show():pos(p.x, p.y):rotation(degree)

            local isflip = (degree > 0 and degree < 180)
            local distance = ceil(pGetLength(pSub(world_point, p)) / 80)
            self.arrow_label:align(isflip and RIGHT_CENTER or LEFT_CENTER)
                :scale(isflip and -1 or 1):setString(string.format("%dM", distance))
        end
    else
        self.arrow:hide()
    end
end
function GameUIAllianceHome:UpdateMyAllianceBuildingArrows(screen_rect, alliance, layer)
    local id = alliance:Id()
    local count = 1
    alliance:GetAllianceMap():IteratorAllianceBuildings(function(_, v)
        local arrow = self:GetMyAllianceArrow(count)
        local x,y = v:GetMidLogicPosition()
        local map_point = layer:ConvertLogicPositionToMapPosition(x, y, id)
        local world_point = layer:convertToWorldSpace(map_point)
        if not rectContainsPoint(screen_rect, world_point) then
            local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
            if p and degree then
                arrow:show():pos(p.x, p.y):rotation(degree + 180)
            end
        else
            arrow:hide()
        end
        count = count + 1
    end)
    local alliance_building_arrows = self.alliance_building_arrows
    for i = count, #alliance_building_arrows do
        alliance_building_arrows[i]:hide()
    end
end
function GameUIAllianceHome:GetMyAllianceArrow(count)
    if not self.alliance_building_arrows[count] then
        self.alliance_building_arrows[count] = display.newSprite("arrow_blue-hd.png")
            :addTo(self, -2):align(display.TOP_CENTER):hide()
    end
    return self.alliance_building_arrows[count]
end
function GameUIAllianceHome:UpdateEnemyArrows(screen_rect, enemy_alliance, layer, logic_x, logic_y)
    local id = enemy_alliance:Id()
    local count = 1
    enemy_alliance:GetAllianceMap():IteratorCities(function(_, v)
        if count > 10 then return true end
        local x,y = v:GetMidLogicPosition()
        local dx, dy = (logic_x - x), (logic_y - y)
        if dx^2 + dy^2 > 1 then
            local arrow = self:GetEnemyArrow(count)
            local map_point = layer:ConvertLogicPositionToMapPosition(x, y, id)
            local world_point = layer:convertToWorldSpace(map_point)
            if not rectContainsPoint(screen_rect, world_point) then
                local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
                if p and degree then
                    arrow:show():pos(p.x, p.y):rotation(degree + 180)
                end
            else
                arrow:hide()
            end
            count = count + 1
        end
    end)
    local enemy_arrows = self.enemy_arrows
    for i = count, #enemy_arrows do
        enemy_arrows[i]:hide()
    end
end
function GameUIAllianceHome:GetEnemyArrow(count)
    if not self.enemy_arrows[count] then
        self.enemy_arrows[count] = display.newSprite("arrow_red-hd.png")
            :addTo(self, -2):align(display.TOP_CENTER):hide()
    end
    return self.enemy_arrows[count]
end
function GameUIAllianceHome:GetIntersectPoint(screen_rect, point1, point2, normal)
    local points = self:GetPointsWithScreenRect(screen_rect)
    for i = 1, #points do
        local p1, p2
        if i ~= #points then
            p1 = points[i]
            p2 = points[i + 1]
        else
            p1 = points[i]
            p2 = points[1]
        end
        local p,s = pGetIntersectPoint(point1, point2, p1, p2)
        if s > 0 and rectContainsPoint(screen_rect, p) then
            return p, deg(pGetAngle(pSub(point1, point2), normal or point(0, 1)))
        end
    end
end
function GameUIAllianceHome:GetPointsWithScreenRect(screen_rect)
    local x,y,w,h = screen_rect.x, screen_rect.y, screen_rect.width, screen_rect.height
    return {
        point(x + w, y),
        point(x + w, y + h),
        point(x, y + h),
        point(x, y),
    }
end
function GameUIAllianceHome:OnAllianceFightChanged(alliance,allianceFight)
    local status = self.alliance:Status()
    if status=="fight" then
        local our , enemy
        if self.alliance:Id() == allianceFight.attackAllianceId  then
            our = allianceFight.attackAllianceCountData
            enemy = allianceFight.defenceAllianceCountData
        else
            our = allianceFight.defenceAllianceCountData
            enemy = allianceFight.attackAllianceCountData
        end
        if our and enemy then
            self.top:SetOurPowerOrKill(our.kill)
            self.top:SetEnemyPowerOrKill(enemy.kill)
        end
    end
end
function GameUIAllianceHome:OnTimer(current_time)
    local status = self.alliance:Status()
    if status ~= "peace" then
        local statusFinishTime = self.alliance:StatusFinishTime()
        -- print("OnTimer == ",math.floor(statusFinishTime/1000)>current_time,math.floor(statusFinishTime/1000),current_time)
        if math.floor(statusFinishTime/1000)>current_time then
            self.time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-current_time))
        end
    else
        local statusStartTime = self.alliance:StatusStartTime()
        if current_time>= math.floor(statusStartTime/1000) then
            self.time_label:setString(GameUtils:formatTimeStyle1(current_time-math.floor(statusStartTime/1000)))
        end
    end
end

function GameUIAllianceHome:GetAlliancePeriod()
    local period = ""
    local status = self.alliance:Status()
    if status == "peace" then
        period = _("和平期")
    elseif status == "prepare" then
        period = _("准备期")
    elseif status == "fight" then
        period = _("战争期")
    elseif status == "protect" then
        period = _("保护期")
    end
    return period
end

return GameUIAllianceHome



