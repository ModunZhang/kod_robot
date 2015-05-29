local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local promise = import("..utils.promise")
local GameUIWatchTowerTroopDetail = import("..ui.GameUIWatchTowerTroopDetail")
local WidgetMoveHouse = import("..widget.WidgetMoveHouse")
local TutorialLayer = import("..ui.TutorialLayer")
local GameUINpc = import("..ui.GameUINpc")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
local Sprite = import("..sprites.Sprite")
local SoldierManager = import("..entity.SoldierManager")
local User = import("..entity.User")
local NotifyItem = import("..entity.NotifyItem")
local CityScene = import(".CityScene")
local MyCityScene = class("MyCityScene", CityScene)
local ipairs = ipairs

function MyCityScene:ctor(...)
    self.util_node = display.newNode():addTo(self)
    MyCityScene.super.ctor(self, ...)
end
function MyCityScene:onEnter()
    MyCityScene.super.onEnter(self)
    self.home_page = self:CreateHomePage()

    self:GetCity():AddListenOnType(self, City.LISTEN_TYPE.UPGRADE_BUILDING)
    self:GetCity():GetUser():AddListenOnType(self, User.LISTEN_TYPE.BASIC)
    self:GetCity():GetSoldierManager():AddListenOnType(self, SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    self:GetCity():GetFirstBuildingByType("barracks"):AddBarracksListener(self)



    local alliance = Alliance_Manager:GetMyAlliance()
    local alliance_map = alliance:GetAllianceMap()
    alliance:AddListenOnType(self, alliance.LISTEN_TYPE.OPERATION)


    self.firstJoinAllianceRewardGeted = DataManager:getUserData().countInfo.firstJoinAllianceRewardGeted
    -- cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height)
    -- :onButtonClicked(function(event)
    --     event.target:setButtonEnabled(false)
    --     app:ReloadGame()
    -- end):setOpacity(0)
    -- UIKit:ttfLabel({
    --     text = _("reload"),
    --     size = 30,
    --     color = 0xffedae,
    --     align = cc.TEXT_ALIGNMENT_CENTER,
    -- }):addTo(self, 1000000)
    -- :align(display.RIGHT_TOP, display.width, display.height)
end
function MyCityScene:onExit()
    MyCityScene.super.onExit(self)
end
function MyCityScene:EnterEditMode()
    self:GetTopLayer():hide()
    self:GetHomePage():DisplayOff()
    local label = UIKit:ttfLabel(
        {
            text = _("选择一个空地,将小屋移动到这里"),
            size = 22,
            color = 0xffedae,
        })
    self.move_house_tip = display.newScale9Sprite("fte_label_background.png",display.cx,display.top-100,cc.size(label:getContentSize().width+60,label:getContentSize().height+20),cc.rect(20,20,330,28))
        :addTo(self)
    label:align(display.CENTER, self.move_house_tip:getContentSize().width/2, self.move_house_tip:getContentSize().height/2):addTo(self.move_house_tip)
    MyCityScene.super.EnterEditMode(self)
end
function MyCityScene:LeaveEditMode()
    self:GetTopLayer():show()
    self:GetHomePage():DisplayOn()
    self.move_house_tip:removeFromParent(true)
    MyCityScene.super.LeaveEditMode(self)
    self:GetSceneUILayer():removeChildByTag(WidgetMoveHouse.ADD_TAG, true)
end
function MyCityScene:CreateSceneUILayer()
    local scene_node = self
    local city = self.city
    local scene_layer = self:GetSceneLayer()
    local scene_ui_layer = display.newLayer()
    scene_ui_layer:setTouchEnabled(true)
    scene_ui_layer:setTouchSwallowEnabled(false)
    scene_ui_layer.action_node = display.newNode():addTo(scene_ui_layer)
    -- function scene_ui_layer:ShowIndicatorOnBuilding(building_sprite)
    --     if not self.indicator then
    --         self.building__ = building_sprite
    --         self.indicator = display.newNode():addTo(self):zorder(1001)
    --         local r = 30
    --         local len = 50
    --         local x = math.sin(math.rad(r)) * len
    --         local y = math.sin(math.rad(90 - r)) * len
    --         display.newSprite("arrow_home.png")
    --             :addTo(self.indicator)
    --             :align(display.BOTTOM_CENTER, 10, 10)
    --             :rotation(r)
    --             :runAction(cc.RepeatForever:create(transition.sequence{
    --                 cc.MoveBy:create(0.4, cc.p(-x, -y)),
    --                 cc.MoveBy:create(0.4, cc.p(x, y)),
    --             }))
    --         self.action_node:stopAllActions()
    --         self.action_node:performWithDelay(function()
    --             self:HideIndicator()
    --         end, 4.0)
    --     end
    -- end
    -- function scene_ui_layer:HideIndicator()
    --     if self.indicator then
    --         self.action_node:stopAllActions()
    --         self.indicator:removeFromParent()
    --         self.indicator = nil
    --     end
    -- end
    function scene_ui_layer:Schedule()
        display.newNode():addTo(self):schedule(function()
            if scene_layer:getScale() < (scene_layer:GetScaleRange()) * 1.3 then
                if self.is_show == nil or self.is_show == true then
                    scene_layer:HideLevelUpNode()
                    scene_node:GetTopLayer():stopAllActions()
                    transition.fadeTo(scene_node:GetTopLayer(), {
                        opacity = 0,
                        time = 0.5,
                        onComplete = function()
                            scene_node:GetTopLayer():hide()
                        end,
                    })
                    self.is_show = false
                end
            else
                if self.is_show == nil or self.is_show == false then
                    scene_layer:ShowLevelUpNode()
                    scene_node:GetTopLayer():stopAllActions()
                    transition.fadeTo(scene_node:GetTopLayer(), {
                        opacity = 255,
                        time = 0.5,
                        onComplete = function()
                            scene_node:GetTopLayer():show()
                        end,
                    })
                    self.is_show = true
                end
            end
        end, 1)
        display.newNode():addTo(self):schedule(function()
            -- local building = self.building__
            -- if self.indicator and building then
            --     local wp = building:convertToWorldSpace(cc.p(building:GetSpriteTopPosition()))
            --     local lp = self.indicator:getParent():convertToNodeSpace(wp)
            --     self.indicator:pos(lp.x, lp.y)
            -- end
            local widget = self:getChildByTag(WidgetMoveHouse.ADD_TAG)
            if widget and widget.move_to_ruins then
                local wp = widget.move_to_ruins:GetWorldPosition()
                widget:pos(wp.x, wp.y)
                widget.building_image:scale(scene_layer:getScale())
            end
        end, 0.0001)
    end
    scene_ui_layer:Schedule()
    return scene_ui_layer
end
function MyCityScene:IteratorLockButtons(func)
    for i,v in ipairs(self:GetTopLayer():getChildren()) do
        if func(v) then
            return
        end
    end
end
function MyCityScene:NewLockButtonFromBuildingSprite(building_sprite)
    local wp = building_sprite:GetWorldPosition()
    local lp = self:GetTopLayer():convertToNodeSpace(wp)
    local button = cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
        :addTo(self:GetTopLayer()):pos(lp.x,lp.y)
        :onButtonClicked(function()
            if self.city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(self.city) > 0 then
                UIKit:newGameUI("GameUIUnlockBuilding", self.city, building_sprite:GetEntity()):AddToCurrentScene(true)
            else
                UIKit:showMessageDialog(_("提示"), _("升级城堡解锁此建筑"))
                    :CreateOKButton(
                        {
                            listener = function()
                                local building_sprite = self:GetSceneLayer():FindBuildingSpriteByBuilding(self.city:GetFirstBuildingByType("keep"), self.city)
                                local x,y = self.city:GetFirstBuildingByType("keep"):GetMidLogicPosition()
                                self:GotoLogicPoint(x,y,40):next(function()
                                    self:AddIndicateForBuilding(building_sprite)
                                end)
                            end,
                            btn_name= _("前往")
                        }
                    )
            end
        end)
    button.sprite = building_sprite
    return button
end
-- 给对应建筑添加指示动画
function MyCityScene:AddIndicateForBuilding(building_sprite)
    Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building_sprite))):next(function()
        self:OpenUI(building_sprite, "upgrade")
    end)
end
function MyCityScene:GetHomePage()
    return self.home_page
end
function MyCityScene:OnOperation(alliance, op)
    if op == "join" and
        Alliance_Manager:HasBeenJoinedAlliance() and
        not self.firstJoinAllianceRewardGeted
    then
        self:GetHomePage():PromiseOfFteAllianceMap()
    end
end
function MyCityScene:onEnterTransitionFinish()
    MyCityScene.super.onEnterTransitionFinish(self)
    if ext.registereForRemoteNotifications then
        ext.registereForRemoteNotifications()
    end
    app:sendApnIdIf()

    if Alliance_Manager:HasBeenJoinedAlliance() then
        return
    end
    local userdefault = cc.UserDefault:getInstance()
    local city_key = DataManager:getUserData()._id.."_first_in_city_scene"
    if not userdefault:getBoolForKey(city_key) and
        Alliance_Manager:GetMyAlliance():IsDefault() then

        userdefault:setBoolForKey(city_key, true)
        userdefault:flush()

        app:lockInput(true)
        cocos_promise.defer(function()app:lockInput(false);end)
            :next(function()
                return GameUINpc:PromiseOfSay(
                    {words = _("领主大人，这个世界上的觉醒者并不只有你一人。介入他们或者创建联盟邀请他们加入，会让我们发展得更顺利")}
                )
            end):next(function()
            self:GetHomePage():PromiseOfFteAlliance()
            return GameUINpc:PromiseOfLeave()
            end)
    else
        self:GetHomePage():PromiseOfFteAlliance()
    end
end
function MyCityScene:CreateHomePage()
    if UIKit:GetUIInstance("GameUIHome") then
        UIKit:GetUIInstance("GameUIHome"):removeFromParent()
    end
    local home = UIKit:newGameUI('GameUIHome', self:GetCity()):AddToScene(self)
    home:setLocalZOrder(10)
    home:setTouchSwallowEnabled(false)
    return home
end
function MyCityScene:onExit()
    self:GetCity():GetUser():RemoveListenerOnType(self, User.LISTEN_TYPE.BASIC)
    self.home_page = nil
    MyCityScene.super.onExit(self)
end
function MyCityScene:GetLockButtonsByBuildingType(building_type)
    local lock_button
    local location_id = self:GetCity():GetLocationIdByBuildingType(building_type)
    self:IteratorLockButtons(function(v)
        print(v.sprite:GetEntity().location_id, location_id)
        if v.sprite:GetEntity().location_id == location_id then
            lock_button = v
            return true
        end
    end)
    assert(lock_button, building_type)
    return lock_button
end
function MyCityScene:OnSoliderStarCountChanged(soldier_manager, soldier_star_changed)
    self:GetSceneLayer():OnSoliderStarCountChanged(soldier_manager, soldier_star_changed)
end
function MyCityScene:OnUserBasicChanged(user, changed)
    MyCityScene.super.OnUserBasicChanged(self, user, changed)
    if changed.terrain then
        self:ChangeTerrain(changed.terrain.new)
    end
    if changed.power then
        self:GetHomePage():ShowPowerAni(cc.p(display.cx, display.cy), changed.power.old)
    end
end
function MyCityScene:OnUpgradingBegin()
    app:GetAudioManager():PlayeEffectSoundWithKey("UI_BUILDING_UPGRADE_START")
    self:GetSceneLayer():CheckCanUpgrade()
    -- local can_unlock = self.city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(self.city) > 0
    -- self:IteratorLockButtons(function(v)
    --     -- v:setVisible(can_unlock)
    -- end)
end
function MyCityScene:OnUpgrading()

end
function MyCityScene:OnUpgradingFinished(building)
    if building:GetType() == "wall" then
        self:GetSceneLayer():UpdateWallsWithCity(self:GetCity())
    end
    self:GetSceneLayer():CheckCanUpgrade()
    app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")

    -- local can_unlock = self.city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(self.city) > 0
    -- self:IteratorLockButtons(function(v)
    --     v:setVisible(can_unlock)
    -- end)
end

function MyCityScene:OnBeginRecruit()
end
function MyCityScene:OnRecruiting()
end
function MyCityScene:OnEndRecruit(barracks, event, soldier_type)
    local star = self:GetCity():GetSoldierManager():GetStarBySoldierType(soldier_type)
    self:GetSceneLayer():MoveBarracksSoldiers(soldier_type)
end
function MyCityScene:OnTilesChanged(tiles)
    self:GetTopLayer():removeAllChildren()
    -- local can_unlock = self.city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(self.city) > 0
    local city = self:GetCity()
    table.foreach(tiles, function(_, tile)
        local tile_entity = tile:GetEntity()
        if (city:IsTileCanbeUnlockAt(tile_entity.x, tile_entity.y)) then
            local building = city:GetBuildingByLocationId(tile_entity.location_id)
            if building and not building:IsUpgrading() then
                self:NewLockButtonFromBuildingSprite(tile)
                -- :setVisible(can_unlock)
            end
        end
    end)
    print("#self:GetTopLayer():getChildren()", #self:GetTopLayer():getChildren())
end
function MyCityScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self.event_manager:TouchCounts() ~= 0 or
        self.util_node:getNumberOfRunningActions() > 0 then return end

    local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true);self.util_node:performWithDelay(function()app:lockInput()end,0.3)
        Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building))):next(function()
            if self:IsEditMode() then
                self:GetSceneUILayer():getChildByTag(WidgetMoveHouse.ADD_TAG):SetMoveToRuins(building)
                return
            end
            self:OpenUI(building)
        end)
    elseif self:IsEditMode() then
        self:LeaveEditMode()
    end
end
local ui_map = setmetatable({
    ruins          = {"GameUIBuild"               ,                           },
    keep           = {"GameUIKeep"                ,        "upgrade",         },
    watchTower     = {"GameUIWatchTower"          ,                           },
    warehouse      = {"GameUIWarehouse"           ,        "upgrade",         },
    dragonEyrie    = {"GameUIDragonEyrieMain"     ,         "dragon",         },
    barracks       = {"GameUIBarracks"            ,        "recruit",         },
    hospital       = {"GameUIHospital"            ,           "heal",         },
    academy        = {"GameUIAcademy"             ,     "technology",         },
    materialDepot  = {"GameUIMaterialDepot"       ,           "info",         },
    blackSmith     = {"GameUIBlackSmith"          ,},
    foundry        = {"GameUIPResourceBuilding"   ,},
    stoneMason     = {"GameUIPResourceBuilding"   ,},
    lumbermill     = {"GameUIPResourceBuilding"   ,},
    mill           = {"GameUIPResourceBuilding"   ,},
    tradeGuild     = {"GameUITradeGuild"          ,            "buy",         },
    townHall       = {"GameUITownHall"            , "administration",         },
    toolShop       = {"GameUIToolShop"            ,    "manufacture",         },
    trainingGround = {"GameUIMilitaryTechBuilding",           "tech",         },
    hunterHall     = {"GameUIMilitaryTechBuilding",           "tech",         },
    stable         = {"GameUIMilitaryTechBuilding",           "tech",         },
    workshop       = {"GameUIMilitaryTechBuilding",           "tech",         },
    dwelling       = {"GameUIDwelling"            ,        "citizen",         },
    farmer         = {"GameUIResource"            ,},
    woodcutter     = {"GameUIResource"            ,},
    quarrier       = {"GameUIResource"            ,},
    miner          = {"GameUIResource"            ,},
    wall           = {"GameUIWall"                ,       "military",         },
    tower          = {"GameUITower"               ,},
    airship        = {},
    FairGround     = {},
    square         = {},
}, {__index = function() assert(false) end})
function MyCityScene:OpenUI(building, default_tab)
    local city = self:GetCity()
    if iskindof(building, "HelpedTroopsSprite") then
        local helped = city:GetHelpedByTroops()[building:GetIndex()]
        local user = self.city:GetUser()
        NetManager:getHelpDefenceTroopDetailPromise(user:Id(),helped.id):done(function(response)
            LuaUtils:outputTable("response", response)
            UIKit:newGameUI("GameUIHelpDefence",self.city, helped ,response.msg.troopDetail):AddToCurrentScene(true)
        end)
        return
    end
    local entity = building:GetEntity()
    if entity:GetType() == "wall" then
        entity = city:GetGate()
    elseif entity:GetType() == "tower" then
        entity = city:GetTower()
    end
    local type_ = entity:GetType()
    local uiarrays = ui_map[type_]
    if type_ == "ruins" and not self:IsEditMode() then
        UIKit:newGameUI(uiarrays[1], city, entity, uiarrays[2], uiarrays[3]):AddToScene(self, true)
    elseif type_ == "airship" then
        local dragon_manger = city:GetDragonEyrie():GetDragonManager()
        local dragon_type = dragon_manger:GetCanFightPowerfulDragonType()
        if #dragon_type > 0 or dragon_manger:GetDefenceDragon() then
            local _,_,index = self.city:GetUser():GetPVEDatabase():GetCharPosition()
            app:EnterPVEScene(index)
        else
            UIKit:showMessageDialog(_("主人"),_("需要一条空闲状态的魔龙才能探险"))
        end
        app:GetAudioManager():PlayeEffectSoundWithKey("AIRSHIP")
    elseif type_ == "FairGround" then
        UIKit:newGameUI("GameUIGacha", self.city):AddToScene(self, true):DisableAutoClose()
    elseif type_ == "square" then
        UIKit:newGameUI("GameUISquare", self.city):AddToScene(self, true)
    else
        UIKit:newGameUI(uiarrays[1], city, entity, default_tab or uiarrays[2], uiarrays[3]):AddToScene(self, true)
    end
end

return MyCityScene






























