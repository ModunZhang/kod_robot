local Alliance = import("..entity.Alliance")
local Sprite = import("..sprites.Sprite")
local AllianceLayer = import("..layers.AllianceLayer")
local GameUIAllianceHome = import("..ui.GameUIAllianceHome")
local MapScene = import(".MapScene")
local AllianceDetailScene = class("AllianceDetailScene", MapScene)

function AllianceDetailScene:OnAllianceDataChanged_operation(allianceData, operationType, deltaData)
    if operationType == "quit" and not deltaData then
        app:EnterMyCityScene()
    end
end
function AllianceDetailScene:OnAllianceDataChanged_mapIndex(allianceData, deltaData)
    Alliance_Manager:UpdateAllianceBy(allianceData.mapIndex, allianceData)
end
function AllianceDetailScene:OnAllianceDataChanged_basicInfo(allianceData, deltaData)
    if deltaData("basicInfo.terrain") then
        if allianceData._id == Alliance_Manager:GetMyAlliance()._id and self.my_terrain ~= allianceData.basicInfo.terrain then
            UIKit:showMessageDialog(nil,_("联盟地形已经改变"),function()
                app:EnterMyAllianceScene()
            end,nil,false,nil)
            self.my_terrain = allianceData.basicInfo.terrain
        else
            self:GetSceneLayer():LoadAllianceByIndex(allianceData.mapIndex, allianceData)
        end
    end
end
function AllianceDetailScene:OnAllianceDataChanged_members(allianceData, deltaData)
    local ok, value = deltaData("members.edit")
    if ok then
        for i,v in ipairs(value) do
            local mapObj = Alliance.FindMapObjectById(allianceData, v.mapId)
            if mapObj then
                self:GetSceneLayer()
                    :RefreshMapObjectByIndex(allianceData.mapIndex, mapObj, allianceData)
            end
        end
    end
end
function AllianceDetailScene:OnAllianceDataChanged_buildings(allianceData, deltaData)
    local ok, value = deltaData("buildings.edit")
    if ok then
        for i,v in ipairs(value) do
            self:GetSceneLayer()
                :RefreshBuildingByIndex(allianceData.mapIndex, v, allianceData)
        end
    end
end
function AllianceDetailScene:OnAllianceDataChanged_mapObjects(allianceData, deltaData)
    self:HandleMapObjects(allianceData, "remove", deltaData("mapObjects.remove"))
    self:HandleMapObjects(allianceData, "add", deltaData("mapObjects.add"))
    self:HandleMapObjects(allianceData, "edit", deltaData("mapObjects.edit"))
end
function AllianceDetailScene:HandleMapObjects(allianceData, op, ok, value)
    if not ok then return end
    if op == "edit" then
        for _,mapObj in pairs(value) do
            self:GetSceneLayer():RefreshMapObjectByIndex(allianceData.mapIndex, mapObj, allianceData)
        end
    elseif op == "add" then
        for _,mapObj in pairs(value) do
            self:GetSceneLayer():AddMapObjectByIndex(allianceData.mapIndex, mapObj, allianceData)
        end
    elseif op == "remove" then
        for _,mapObj in pairs(value) do
            self:GetSceneLayer():RemoveMapObjectByIndex(allianceData.mapIndex, mapObj)
        end
    end
end
function AllianceDetailScene:OnAllianceDataChanged_shrineEvents(allianceData, deltaData)
    for _,v in ipairs(allianceData.buildings) do
        if v.name == "shrine" then
            self:GetSceneLayer()
                :RefreshBuildingByIndex(allianceData.mapIndex, v, allianceData)
            return
        end
    end
end

--
function AllianceDetailScene:OnAllianceDataChanged_marchEvents(allianceData, deltaData)
    -- 进攻
    self:HandleEvents("remove", false, deltaData("marchEvents.attackMarchEvents.remove"))
    self:HandleEvents("add", false, deltaData("marchEvents.attackMarchEvents.add"))
    self:HandleEvents("edit", false, deltaData("marchEvents.attackMarchEvents.edit"))
    -- 返回
    self:HandleEvents("remove", true, deltaData("marchEvents.attackMarchReturnEvents.remove"))
    self:HandleEvents("add", true, deltaData("marchEvents.attackMarchReturnEvents.add"))
    self:HandleEvents("edit", true, deltaData("marchEvents.attackMarchReturnEvents.edit"))

    self:HandleEvents("remove", false, deltaData("marchEvents.strikeMarchEvents.remove"))
    self:HandleEvents("add", false, deltaData("marchEvents.strikeMarchEvents.add"))
    self:HandleEvents("edit", false, deltaData("marchEvents.strikeMarchEvents.edit"))

    self:HandleEvents("remove", true, deltaData("marchEvents.strikeMarchReturnEvents.remove"))
    self:HandleEvents("add", true, deltaData("marchEvents.strikeMarchReturnEvents.add"))
    self:HandleEvents("edit", true, deltaData("marchEvents.strikeMarchReturnEvents.edit"))
end
function AllianceDetailScene:HandleEvents(op, isReturn, ok, value)
    if not ok then return end
    if op == "add"
        or op == "edit" then
        if isReturn then
            for _,event in pairs(value) do
                self:CreateOrUpdateOrDeleteCorpsByReturnEvent(event.id, event)
            end
        else
            for _,event in pairs(value) do
                self:CreateOrUpdateOrDeleteCorpsByEvent(event.id, event)
            end
        end
    elseif op == "remove" then
        for _,event in pairs(value) do
            self:GetSceneLayer():DeleteCorpsById(event.id)
        end
    end
end

function AllianceDetailScene:OnAllianceDataChanged_villageEvents(allianceData, deltaData)
    self:HandleVillage(allianceData, deltaData("villageEvents.add"))
    self:HandleVillage(allianceData, deltaData("villageEvents.remove"))
end
function AllianceDetailScene:HandleVillage(allianceData, ok, value)
    if not ok then return end
    for i,v in ipairs(value) do
        local mapObj = Alliance.FindMapObjectById(allianceData, v.villageData.id)
        if mapObj then
            self:GetSceneLayer()
                :RefreshMapObjectByIndex(allianceData.mapIndex, mapObj, allianceData)
        end
    end
end
-- other
function AllianceDetailScene:OnEnterMapIndex(mapIndex, data)
    self:CreateMarchEvents(data.mapData.marchEvents)
    self:GetSceneLayer():LoadAllianceByIndex(mapIndex, data.allianceData)
end
function AllianceDetailScene:OnMapDataChanged(allianceData, mapData, deltaData)
    local ok, value = deltaData("marchEvents.strikeMarchEvents")
    if ok then
        for id,_ in pairs(value) do
            local event = mapData.marchEvents.strikeMarchEvents[id]
            self:CreateOrUpdateOrDeleteCorpsByEvent(id, event)
        end
    end

    local ok, value = deltaData("marchEvents.strikeMarchReturnEvents")
    if ok then
        for id,_ in pairs(value) do
            local event = mapData.marchEvents.strikeMarchReturnEvents[id]
            self:CreateOrUpdateOrDeleteCorpsByReturnEvent(id, event)
        end
    end

    local ok, value = deltaData("marchEvents.attackMarchEvents")
    if ok then
        for id,_ in pairs(value) do
            local event = mapData.marchEvents.attackMarchEvents[id]
            self:CreateOrUpdateOrDeleteCorpsByEvent(id, event)
        end
    end

    local ok, value = deltaData("marchEvents.attackMarchReturnEvents")
    if ok then
        for id,_ in pairs(value) do
            local event = mapData.marchEvents.attackMarchReturnEvents[id]
            self:CreateOrUpdateOrDeleteCorpsByReturnEvent(id, event)
        end
    end
    if allianceData then
        for i,v in ipairs(getmetatable(deltaData).villageEvents_remove or {}) do
            local mapObj = Alliance.FindMapObjectById(allianceData, v.villageData.id)
            if mapObj then
                self:GetSceneLayer()
                    :RefreshMapObjectByIndex(allianceData.mapIndex, mapObj, allianceData)
            end
        end
        local ok, value = deltaData("villageEvents")
        if ok then
            for id,_ in pairs(value) do
                local event = mapData.villageEvents[id]
                if event ~= json.null then
                    local mapObj = Alliance.FindMapObjectById(allianceData, event.villageData.id)
                    if mapObj then
                        self:GetSceneLayer()
                            :RefreshMapObjectByIndex(allianceData.mapIndex, mapObj, allianceData)
                    end
                end
            end
        end
        if deltaData("marchEvents") then
            for _,v in ipairs(allianceData.buildings) do
                if v.name == "watchTower" then
                    self:GetSceneLayer()
                        :RefreshBuildingByIndex(allianceData.mapIndex, v, allianceData)
                    break
                end
            end
        end
    end
end
function AllianceDetailScene:OnMapAllianceChanged(allianceData, deltaData)
    if deltaData == json.null then
        self:GetSceneLayer():LoadAllianceByIndex(allianceData.mapIndex, nil)
        return
    end
    if deltaData("basicInfo") then
        self:OnAllianceDataChanged_basicInfo(allianceData, deltaData)
    end
    if deltaData("members") then
        self:OnAllianceDataChanged_members(allianceData, deltaData)
    end
    if deltaData("buildings") then
        self:OnAllianceDataChanged_buildings(allianceData, deltaData)
    end
    if deltaData("mapObjects") then
        self:OnAllianceDataChanged_mapObjects(allianceData, deltaData)
    end
    if deltaData("marchEvents") then
        self:OnAllianceDataChanged_marchEvents(allianceData, deltaData)
    end
    if deltaData("villageEvents") then
        self:OnAllianceDataChanged_villageEvents(allianceData, deltaData)
    end
end


function AllianceDetailScene:CreateMarchEvents(marchEvents)
    for _,event in pairs(marchEvents.strikeMarchEvents) do
        if event ~= json.null then
            self:CreateOrUpdateOrDeleteCorpsByEvent(event.id, event)
        end
    end
    for _,event in pairs(marchEvents.strikeMarchReturnEvents) do
        if event ~= json.null then
            self:CreateOrUpdateOrDeleteCorpsByReturnEvent(event.id,event)
        end
    end
    for _,event in pairs(marchEvents.attackMarchEvents) do
        if event ~= json.null then
            self:CreateOrUpdateOrDeleteCorpsByEvent(event.id, event)
        end
    end
    for _,event in pairs(marchEvents.attackMarchReturnEvents) do
        if event ~= json.null then
            self:CreateOrUpdateOrDeleteCorpsByReturnEvent(event.id,event)
        end
    end
end
function AllianceDetailScene:RefreshVillageEvents(alliance, villageEvents)
    for _,event in pairs(villageEvents) do
        if event ~= json.null then
            local mapObj = Alliance.FindMapObjectById(alliance, event.villageData.id)
            if mapObj then
                self:GetSceneLayer()
                    :RefreshMapObjectByIndex(alliance.mapIndex, mapObj, alliance)
            end
        end
    end
end
function AllianceDetailScene:CreateOrUpdateOrDeleteCorpsByEvent(id, event)
    if event == json.null then
        self:GetSceneLayer():DeleteCorpsById(id)
    elseif event then
        self:GetSceneLayer():CreateOrUpdateCorpsBy(event, false)
    end
end
function AllianceDetailScene:CreateOrUpdateOrDeleteCorpsByReturnEvent(id, event)
    if event == json.null then
        self:GetSceneLayer():DeleteCorpsById(id)
    elseif event then
        self:GetSceneLayer():CreateOrUpdateCorpsBy(event, true)
    end
end











-----------








local intInit = GameDatas.AllianceInitData.intInit
local ALLIANCE_WIDTH, ALLIANCE_HEIGHT = intInit.allianceRegionMapWidth.value, intInit.allianceRegionMapHeight.value
function AllianceDetailScene:ctor(location)
    AllianceDetailScene.super.ctor(self)
    self.util_node = display.newNode():addTo(self)
    self.fetchtimer = display.newNode():addTo(self)
    self.location = location
    self.goto_x = x
    self.goto_y = y
end
function AllianceDetailScene:onEnter()
    AllianceDetailScene.super.onEnter(self)

    display.newSprite("city_filter.png"):addTo(self,10):opacity(110)
    :scale(display.width / 640):pos(display.cx, display.cy)

    Alliance_Manager:ClearCache()
    Alliance_Manager:UpdateAllianceBy(Alliance_Manager:GetMyAlliance().mapIndex, Alliance_Manager:GetMyAlliance())

    local alliance = Alliance_Manager:GetMyAlliance()
    if self.location then
        if self.location.x and self.location.y then
            local x,y = DataUtils:GetAbsolutePosition(self.location.mapIndex, self.location.x , self.location.y)
            self:GotoPosition(x,y)
        else
            self:GotoAllianceByIndex(self.location.mapIndex)
        end
        if self.location.callback then
            self.location.callback(self)
        end
    else
        local mapObj = alliance:FindMapObjectById(alliance:GetSelf().mapId)
        local x,y = DataUtils:GetAbsolutePosition(alliance.mapIndex, mapObj.location.x, mapObj.location.y)
        self:GotoPosition(x,y)
    end
    self:GetSceneLayer():ZoomTo(0.65)
    alliance:AddListenOnType(self, "mapIndex")
    alliance:AddListenOnType(self, "basicInfo")
    alliance:AddListenOnType(self, "members")
    alliance:AddListenOnType(self, "buildings")
    alliance:AddListenOnType(self, "mapObjects")
    alliance:AddListenOnType(self, "marchEvents")
    alliance:AddListenOnType(self, "villageEvents")
    alliance:AddListenOnType(self, "shrineEvents")
    alliance:AddListenOnType(self, "operation")
    Alliance_Manager:AddHandle(self)

    self:CreateMarchEvents(alliance.marchEvents)
    -- self:RefreshVillageEvents(alliance.villageEvents)
    self:CreateMarchEvents(Alliance_Manager:GetMyAllianceMapData().marchEvents)
    self:RefreshVillageEvents(alliance, Alliance_Manager:GetMyAllianceMapData().villageEvents)
    self.my_terrain = alliance.basicInfo.terrain
    -- cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height)
    -- :onButtonClicked(function(event)
    --     app:onEnterBackground()
    -- end)

    -- cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height - 100)
    -- :onButtonClicked(function(event)
    --     app:onEnterForeground()
    -- end)

    if app:GetAudioManager():GetLastPlayedFileName() == "sfx_city" then
        app:GetAudioManager():PlayGameMusicAutoCheckScene()
    end
end
function AllianceDetailScene:onExit()
    self.fetchtimer:stopAllActions()
    if self.current_allinace_index
        and not Alliance_Manager:GetMyAlliance():IsDefault() then
        NetManager:getLeaveMapIndexPromise(self.current_allinace_index)
    end
    Alliance_Manager:ClearAllHandles()
    Alliance_Manager:ClearCache()
    Alliance_Manager:ResetCurrentMapData()
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "mapIndex")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "basicInfo")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "members")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "buildings")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "mapObjects")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "marchEvents")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "villageEvents")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "shrineEvents")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "operation")
end
function AllianceDetailScene:ViewIndex()
    return self.current_allinace_index
end
function AllianceDetailScene:FetchAllianceDatasByIndex(index, func)
    if Alliance_Manager:GetMyAlliance().mapIndex == index then
        if self.GetHomePage and self:GetHomePage() then
            self:GetHomePage():HideLoading()
        end
        self.fetchtimer:stopAllActions()
        self.fetch_index = nil
        self.current_allinace_index = nil
        if type(func) == "function" then
            func()
        end
    elseif self.current_allinace_index ~= index then
        self:StartTimer(index, func)
    end
end
function AllianceDetailScene:StartTimer(index, func)
    if self.fetch_index == index then return end
    if self.GetHomePage and self:GetHomePage() then
        self:GetHomePage():ShowLoading()
    end
    self.fetchtimer:stopAllActions()
    self.fetchtimer:performWithDelay(function()
        self.fetch_index = index
        NetManager:getEnterMapIndexPromise(index)
            :done(function(response)
                self.current_allinace_index = index
                Alliance_Manager:OnEnterMapIndex(index, response.msg)
                if self.GetHomePage and self:GetHomePage() then
                    self:GetHomePage():RefreshTop(true)
                    self:GetHomePage():HideLoading()
                end
                if type(func) == "function" then
                    func()
                end
            end)
    end, 0.2)
end
function AllianceDetailScene:CreateHomePage()
    local home_page = GameUIAllianceHome.new(Alliance_Manager:GetMyAlliance()):addTo(self,10)
    home_page:setTouchSwallowEnabled(false)
    return home_page
end
function AllianceDetailScene:GetHomePage()
    return self.home_page
end
function AllianceDetailScene:CreateSceneLayer()
    return AllianceLayer.new(self)
end
function AllianceDetailScene:GotoAllianceByIndex(index)
    self:GotoAllianceByXY(self:GetSceneLayer():IndexToLogic(index))
    self:FetchAllianceDatasByIndex(index)
end
function AllianceDetailScene:GotoAllianceByXY(x, y)
    local point = self:GetSceneLayer():ConvertLogicPositionToAlliancePosition(x,y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function AllianceDetailScene:GotoPosition(x,y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x,y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function AllianceDetailScene:OnTouchBegan(...)
    AllianceDetailScene.super.OnTouchBegan(self, ...)
    self:GetSceneLayer():TrackCorpsById(nil)
end
function AllianceDetailScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self:IsFingerOn() or self.util_node:getNumberOfRunningActions() > 0 then
        return
    end
    local mapObj = self:GetSceneLayer():GetClickedObject(x, y)
    if mapObj then
        local alliance = Alliance_Manager:GetAllianceByCache(mapObj.index)
        local type_ = Alliance:GetMapObjectType(mapObj)
        app:GetAudioManager():PlayeEffectSoundWithKey("HOME_PAGE")
        if alliance then
            if type_ == "member"
                or type_ == "village"
                or type_ == "building" then
                app:lockInput(true)
                self.util_node:performWithDelay(function()app:lockInput(false)end,0.5)
                Sprite:PromiseOfFlash(mapObj.obj):next(function()
                    self:OpenUI(alliance, mapObj)
                end)
            elseif type_ == "empty"
                and mapObj.index == Alliance_Manager:GetMyAlliance().mapIndex then
                app:lockInput(true)
                self.util_node:performWithDelay(function()app:lockInput(false)end,0.5)
                self:GetSceneLayer()
                    :PromiseOfFlashEmptyGround(mapObj.index, mapObj.x, mapObj.y)
                    :next(function()
                        self:OpenUI(alliance, mapObj)
                    end)
            elseif type_ == "monster" then
                app:lockInput(true)
                self.util_node:performWithDelay(function()app:lockInput(false)end,0.5)
                self:GetSceneLayer()
                    :PromiseOfFlashEmptyGround(mapObj.index, mapObj.x, mapObj.y)
                    :next(function()
                        self:OpenUI(alliance, mapObj)
                    end)
            elseif type_ == "nouse" then
                return
            else
                self:OpenUI(alliance, mapObj)
            end
        else
            if type_ == "empty" then
                return
            end
            local scale_map = {
                tower1 = 1,
                tower2 = 1,
                crown = 3
            }
            self.util_node:performWithDelay(function()app:lockInput(false)end,0.5)
            self:GetSceneLayer()
            :PromiseOfFlashEmptyGround(mapObj.index,mapObj.x,mapObj.y,scale_map[type_])
            :next(function()
                if type_ == "crown" then
                    UIKit:newGameUI("GameUIThroneMain"):AddToCurrentScene()
                elseif type_ == "tower1" or type_ == "tower2" then
                    UIKit:showMessageDialog(_("提示"), _("即将开放"))
                end
            end)
        end
    else
        app:GetAudioManager():PlayeEffectSoundWithKey("NORMAL_DOWN")
        UIKit:newWidgetUI("WidgetWorldAllianceInfo",nil,self:GetSceneLayer():GetMapIndexByWorldPosition(x, y)):AddToCurrentScene()
    end
end
function AllianceDetailScene:OpenUI(alliance,mapObj)
    if Alliance:GetMapObjectType(mapObj) ~= "building" then
        self:EnterNotAllianceBuilding(alliance,mapObj)
    else
        self:EnterAllianceBuilding(alliance,mapObj)
    end
end
function AllianceDetailScene:OnSceneMove()
    AllianceDetailScene.super.OnSceneMove(self)
    self:UpdateVisibleAllianceBg()
    self:FetchAllianceDatasByIndex(self:GetSceneLayer():GetMiddleAllianceIndex())
    if not self.home_page then
        self.home_page = self:CreateHomePage()
    end
end
function AllianceDetailScene:UpdateVisibleAllianceBg()
    local old_visibles = self.visible_alliances or {}
    local new_visibles = {}
    for _,k in pairs(self:GetSceneLayer():GetVisibleAllianceIndexs()) do
        if not old_visibles[k] then
            self:GetSceneLayer():LoadAllianceByIndex(k, Alliance_Manager:GetAllianceByCache(k))
            new_visibles[k] = true
        end
        new_visibles[k] = true
    end
    self.visible_alliances = new_visibles
end
function AllianceDetailScene:EnterAllianceBuilding(alliance,mapObj)
    if mapObj.name then
        local building_name = mapObj.name
        local class_name = ""
        if building_name == 'shrine' then
            class_name = "GameUIAllianceShrineEnter"
        elseif building_name == 'palace' then
            class_name = "GameUIAlliancePalaceEnter"
        elseif building_name == 'shop' then
            class_name = "GameUIAllianceShopEnter"
        elseif building_name == 'orderHall' then
            class_name = "GameUIAllianceOrderHallEnter"
        elseif building_name == 'watchTower' then
            class_name = "GameUIAllianceWatchTowerEnter"
        elseif building_name == 'bloodSpring' and alliance._id == Alliance_Manager:GetMyAlliance()._id then
            UIKit:showMessageDialog(_("提示"), _("此建筑即将开放"))
            return
        else
            print("没有此建筑--->",building_name)
            return
        end
        UIKit:newGameUI(class_name,mapObj,alliance):AddToCurrentScene(true)
    end
end

function AllianceDetailScene:EnterNotAllianceBuilding(alliance,mapObj)
    local isMyAlliance = true
    local type_ = Alliance:GetMapObjectType(mapObj)
    print("type_=====",type_)
    local class_name = ""

    if type_ == "empty" then
        if alliance.mapIndex == Alliance_Manager:GetMyAlliance().mapIndex then
            class_name = "GameUIAllianceEnterBase"
        else
            return
        end
    elseif type_ == 'member' then
        app:GetAudioManager():PlayBuildingEffectByType("keep")
        class_name = "GameUIAllianceCityEnter"
    elseif type_ == 'decorate' then
        -- class_name = "GameUIAllianceDecorateEnter"
        return
    elseif type_ == 'village' then
        app:GetAudioManager():PlayBuildingEffectByType("warehouse")
        class_name = "GameUIAllianceVillageEnter"
        -- if not alliance:FindAllianceVillagesInfoByObject(mapObj) then -- 废墟
        --     class_name = "GameUIAllianceRuinsEnter"
        -- end
    elseif type_ == 'monster' then
        if not alliance:FindAllianceMonsterInfoByObject(mapObj) then
            return
        end
        class_name = "GameUIAllianceMosterEnter"
    end
    UIKit:newGameUI(class_name,mapObj or type_,alliance):AddToCurrentScene(true)

end
function AllianceDetailScene:TwinkleShrine()
    local mapObject = self:GetSceneLayer():FindMapObject(Alliance_Manager:GetMyAlliance().mapIndex, 8, 12)
    self:performWithDelay(function()
        Sprite:PromiseOfFlash(mapObject.obj):next(function()
            Sprite:PromiseOfFlash(mapObject.obj):next(function()
                end)Sprite:PromiseOfFlash(mapObject.obj)
        end)
    end, 1)
end
return AllianceDetailScene



















