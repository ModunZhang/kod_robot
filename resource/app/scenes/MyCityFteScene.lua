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
local MyCityScene = import(".MyCityScene")
local MyCityFteScene = class("MyCityFteScene", MyCityScene)

function MyCityFteScene:ctor(...)
    MyCityFteScene.super.ctor(self, ...)
    self.clicked_callbacks = {}
end
function MyCityFteScene:onEnterTransitionFinish()
    self:RunFte()
end
function MyCityFteScene:PromiseOfClickBuilding(x, y, for_build, msg, arrow_param)
    self:BeginClickFte()
    self:GetSceneLayer()
        :FindBuildingBy(x, y)
        :next(function(building)
            local mid,top = building:GetWorldPosition()
            local info_layer = self:GetSceneLayer():GetInfoLayer()
            local middle_point = info_layer:convertToNodeSpace(mid)
            local top_point = info_layer:convertToNodeSpace(top)

            local str
            if not msg then
                if building:GetEntity():GetType() == "ruins" then
                    str = string.format(_("点击空地：建造%s"), Localize.building_name[for_build])
                else
                    str = string.format(_("点击建筑：%s"), Localize.building_name[building:GetEntity():GetType()])
                end
            end

            info_layer:removeAllChildren()
            local arrow = WidgetFteArrow.new(msg or str)
                :addTo(info_layer, 1, 119):TurnDown():pos(top_point.x, top_point.y + 50)
            if arrow_param then
                if arrow_param.direction == "up" then
                    arrow:TurnUp():pos(top_point.x + 0, top_point.y - 300)
                end
            end


            local mx, my = building:GetEntity():GetMidLogicPosition()
            self:GotoLogicPoint(mx, my, 5)
            :next(function()
                local rect
                if info_layer:getChildByTag(119) then
                    local rect1 = info_layer:getChildByTag(119):getCascadeBoundingBox()
                    local rect2 = building:getCascadeBoundingBox()
                    rect = cc.rectUnion(rect1, rect2)
                else
                    rect = building:getCascadeBoundingBox()
                end
                self:GetFteLayer():FocusOnRect(rect)
            end)

        end)

    local p = promise.new()
    table.insert(self.clicked_callbacks, function(building)
        local x_, y_ = building:GetEntity():GetLogicPosition()
        if x == x_ and y == y_ then
            p:resolve()
            return true
        end
    end)
    return p
end
function MyCityFteScene:BeginClickFte()
    self.clicked_callbacks = {}
    self:GetFteLayer():FocusOnRect()
    self:GetFteLayer():Enable()
    self:GetSceneLayer():GetInfoLayer():removeAllChildren()
end
function MyCityFteScene:EndClickFte()
    self.clicked_callbacks = {}
    self:GetFteLayer():FocusOnRect()
    self:GetFteLayer():Disable()
    self:GetSceneLayer():GetInfoLayer():removeAllChildren()
end
function MyCityFteScene:CheckClickPromise(building, func)
    if #self.clicked_callbacks > 0 then
        if self.clicked_callbacks[1](building) then
            table.remove(self.clicked_callbacks, 1)
            func()
            self:EndClickFte()
        end
    else
        func()
    end
end
function MyCityFteScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self.event_manager:TouchCounts() ~= 0 or
        self.util_node:getNumberOfRunningActions() > 0 then 
        return 
    end

    local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true);self.util_node:performWithDelay(function()app:lockInput()end,0.3)
        Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building))):next(function()
            self:CheckClickPromise(building, function()
                self:OpenUI(building)
            end)
        end)
    end
end
local ui_map = setmetatable({
    ruins          = {"GameUIFteBuild"            ,                           },
    keep           = {"GameUIFteKeep"             ,        "upgrade",         },
    watchTower     = {"GameUIWatchTower"          ,                           },
    warehouse      = {"GameUIWarehouse"           ,        "upgrade",         },
    dragonEyrie    = {"GameUIFteDragonEyrieMain"  ,         "dragon",         },
    barracks       = {"GameUIFteBarracks"         ,        "recruit",         },
    hospital       = {"GameUIFteHospital"         ,           "heal",         },
    academy        = {"GameUIFteAcademy"          ,     "technology",         },
    materialDepot  = {"GameUIFteMaterialDepot"    ,           "info",         },
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
function MyCityFteScene:OpenUI(building, default_tab)
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
            app:EnterPVEFteScene(1)
        else
            UIKit:showMessageDialog(_("陛下"),_("必须有一条空闲的龙，才能进入pve"))
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




-- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
function MyCityFteScene:RunFte()
    self.touch_layer:removeFromParent()
    self:GetFteLayer():LockAll()

    cocos_promise.defer():next(function()
        if not check("HateDragon") or
            not check("DefenceDragon") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfHateDragonAndDefence()
        end
    end):next(function()
        if not check("BuildHouseAt_3_3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfBuildFirstHouse(18, 12, "dwelling")
        end
    end):next(function()
        if not check("FinishBuildHouseAt_3_1") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteWaitFinish()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_2") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfFirstUpgradeKeep()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_2") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteFreeSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_barracks_1") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUnlockBuilding("barracks")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_barracks_1") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("RecruitSoldier_swordsman") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfRecruitSoldier("swordsman")
        end
    end):next(function()
        if not check("BuildHouseAt_5_3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfBuildHouse(8, 22, "farmer")
        end
    end):next(function()
        if not check("FinishBuildHouseAt_5_1") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteWaitFinish()
        end
    end):next(function()
        if not check("FightWithNpc1") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfExplorePve()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUpgradeKeepForHospital()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_3") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_hospital_1") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUnlockBuilding("hospital")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_hospital_1") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("TreatSoldier") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfHeal()
        end
    end):next(function()
        if not check("BuildHouseAt_6_3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfBuildWoodcutter()
        end
    end):next(function()
        if not check("FinishBuildHouseAt_6_3") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteWaitFinish()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_4") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUpgradeKeepForAcademy()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_4") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_academy_1") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUnlockBuilding("academy")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_academy_1") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("Research") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfResearch()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_5") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUpgradeKeepForMaterialDepot()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_5") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_materialDepot_1") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfUnlockBuilding("materialDepot")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_materialDepot_1") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("FightWithNpc2") or not check("FightWithNpc3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfCheckMaterials()
        end
    end):next(function()
        if not check("RecruitSoldier_skeletonWarrior") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfRecruitSpecial()
        end
    end):next(function()
        if not check("BuildHouseAt_7_3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfBuildQuarrier()
        end
    end):next(function()
        if not check("FinishBuildHouseAt_7_3") then
            self:GetFteLayer():UnlockAll()
            return self:GetHomePage():PromiseOfFteWaitFinish()
        end
    end):next(function()
        if not check("BuildHouseAt_8_3") then
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfBuildHouse(28, 12, "miner", _("建造矿工小屋"))
        end
    end):next(function()
        self:GetFteLayer():UnlockAll()
        return self:PromiseOfFteEnd()
    end)
end
function MyCityFteScene:PromiseOfHateDragonAndDefence()
    return GameUINpc:PromiseOfSay(
        {words = _("我们到了。。。现在你的伤也恢复的差不多了，让我们来测试一下你觉醒者的能力吧。。。"), brow = "smile"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(18, 8)
    end):next(function()
        return UIKit:PromiseOfOpen("GameUIFteDragonEyrieMain")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityFteScene:PromiseOfBuildFirstHouse(x, y, house_type)
    return GameUINpc:PromiseOfSay(
        {words = _("拥有了驾驭龙族的力量，一定能击败邪恶的黑龙，重建帝国的荣耀！"), brow = "angry"},
        {words = _("不过可惜这座城市太弱小了，我们得重头开始发展。建造住宅为城市提供空闲城民，用于生产资源和招募部队。。。"), brow = "sad"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfBuildHouse(x, y, house_type)
    end)
end
function MyCityFteScene:PromiseOfBuildHouse(x, y, house_type, msg)
    return self:PromiseOfClickBuilding(x, y, house_type, msg)
        :next(function()
            return UIKit:PromiseOfOpen("GameUIFteBuild")
        end):next(function(ui)
        return ui:PromiseOfFte(house_type)
        end)
end
function MyCityFteScene:PromiseOfFirstUpgradeKeep()
    return GameUINpc:PromiseOfSay(
        {words = _("非常好，现在我们来升级城堡！城堡等级越高，可以解锁更多建筑。。。")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfUpgradeKeep()
    end)
end
function MyCityFteScene:PromiseOfUnlockBuilding(building_type)
    local x,y = self:GetCity():GetFirstBuildingByType(building_type):GetMidLogicPosition()

    local tutorial = TutorialLayer.new():addTo(self, 2001)
    return cocos_promise.defer(function()
        WidgetFteArrow.new(string.format(_("点击解锁%s"), Localize.building_name[building_type]))
        :TurnUp():align(display.TOP_CENTER, 0, -50)
        :addTo(self:GetLockButtonsByBuildingType(building_type), 1, 123)

        return self:GotoLogicPoint(x, y, 5):next(function()
            tutorial:SetTouchObject(self:GetLockButtonsByBuildingType(building_type))
        end):next(function()
            return UIKit:PromiseOfOpen("GameUIUnlockBuilding")
        end):next(function(ui)
            tutorial:removeFromParent()
            self:GetLockButtonsByBuildingType(building_type):removeChildByTag(123)
            return ui:PormiseOfFte()
        end)

    end)

end
function MyCityFteScene:PromiseOfRecruitSoldier()
    return GameUINpc:PromiseOfSay(
        {words = _("年轻人，带兵打仗可不是过家家，如果你信得过我这把老骨头，就让我来教教你。。。"), npc = "man"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(6, 29)
    end):next(function()
        return UIKit:PromiseOfOpen("GameUIFteBarracks")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityFteScene:PromiseOfExplorePve()
    return GameUINpc:PromiseOfSay(
        {words = _("很好，我没有看错你！从今天起，我，皇家骑士克里冈，愿带领我的手下追随大人征战四方。。。"), npc = "man"}
    ):next(function()
        mockData.GetSoldier()
        GameGlobalUI:showTips(
            _("获得奖励"),
            NotifyItem.new({type = "soldiers", name = "swordsman", count = 100},
                {type = "soldiers", name = "ranger", count = 100})
        )
    end):next(function()
        return GameUINpc:PromiseOfSay(
            {words = _("领主大人，光靠城市基本的资源产出，无法满足我们的发展需求。。。"), npc = "man"},
            {words = _("我倒是知道一个地方，有些危险，但有着丰富的物资，也许我们尝试着探索。。。"), npc = "man"}
        )
    end):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(-9, 4, nil, _("点击飞艇进入探险地图"))
    end):next(function()
        return promise.new()
    end)
end
function MyCityFteScene:PromiseOfActiveVip()
    return GameUINpc:PromiseOfSay(
        {words = _("领主大人，你跑到哪里去了，人家可是找了你半天了。。。我们得抓紧时间解锁更多建筑！"), brow = "smile"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:GetHomePage():PromiseOfActivePromise()
    end)
end
function MyCityFteScene:PromiseOfUpgradeKeepForHospital()
    return GameUINpc:PromiseOfSay(
        {words = _("领主大人, 你跑到那里去了...有士兵受伤了?我们需要解锁医院来治愈他们")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfUpgradeKeep(_("升级城堡来解锁医院"))
    end)
end
function MyCityFteScene:PromiseOfUpgradeKeepForAcademy()
    return GameUINpc:PromiseOfSay(
        {words = _("领主大人, 解锁学院可以研发科技, 获得额外木材产出加成...")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfUpgradeKeep(_("升级城堡来解锁学院"))
    end)
end
function MyCityFteScene:PromiseOfUpgradeKeepForMaterialDepot()
    return GameUINpc:PromiseOfSay(
        {words = _("领主大人, 你听过灵魂石吗?那是用来召唤亡灵战士的...不过我不确定我们有这玩意儿"), npc = "man"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfUpgradeKeep(_("升级城堡来解锁材料库房"))
    end)
end
function MyCityFteScene:PromiseOfUpgradeKeep(msg)
    return self:PromiseOfClickBuilding(8, 8, nil, msg, {
        direction = "up"
    }):next(function()
        return UIKit:PromiseOfOpen("GameUIFteKeep")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityFteScene:PromiseOfBuildWoodcutter()
    return GameUINpc:PromiseOfSay(
        {words = _("领主大人, 建造和升级建筑需要大量的木材. 建造木工小屋能不停产出木材")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfBuildHouse(18, 22, "woodcutter", _("建造木工小屋"))
    end)
end
function MyCityFteScene:PromiseOfHeal()
    return self:PromiseOfClickBuilding(16, 29)
    :next(function()
        return UIKit:PromiseOfOpen("GameUIFteHospital")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityFteScene:PromiseOfResearch()
    return self:PromiseOfClickBuilding(26, 29)
    :next(function()
        return UIKit:PromiseOfOpen("GameUIFteAcademy")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityFteScene:PromiseOfCheckMaterials()
    return self:PromiseOfClickBuilding(26, 19)
    :next(function()
        return UIKit:PromiseOfOpen("GameUIFteMaterialDepot")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityFteScene:PromiseOfRecruitSpecial()
    ui_map.barracks[2] = "specialRecruit"
    return self:PromiseOfClickBuilding(6, 29)
    :next(function()
        return UIKit:PromiseOfOpen("GameUIFteBarracks")
    end):next(function(ui)
        return ui:PromiseOfFteSpecial()
    end)
end
function MyCityFteScene:PromiseOfBuildQuarrier()
    return GameUINpc:PromiseOfSay(
        {words = _("建造石匠小屋和矿工小屋,就算领主大人不在,工人们也会不停生产资源")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfBuildHouse(28, 22, "quarrier", _("建造石匠小屋"))
    end)
end
local FTE_MARK_TAG = 120
function MyCityFteScene:PromiseOfFteEnd()
    local r = self:GetHomePage().quest_bar_bg:getCascadeBoundingBox()
    WidgetFteMark.new():addTo(self, 4000, FTE_MARK_TAG):Size(r.width, r.height)
        :pos(r.x + r.width/2, r.y + r.height/2)

    GameUINpc:PromiseOfSay(
        {words = _("看来大人你已经能够顺利接管这座城市了。。。如果不知道该干什么可以点击左上角的推荐任务"), rect = r}
    ):next(function()
        self:removeChildByTag(FTE_MARK_TAG)
        if ext.registereForRemoteNotifications then
            ext.registereForRemoteNotifications()
        end
        app:GetPushManager():CancelAll()
        UIKit:closeAllUI(true)
        app:EnterUserMode()
        app:EnterMyCityScene()
    end)
end



return MyCityFteScene
















