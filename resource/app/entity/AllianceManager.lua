local Alliance = import(".Alliance")
local AllianceManager = class("AllianceManager")

function AllianceManager:ctor()
    self.my_alliance = Alliance.new()
    self.my_alliance:SetIsMyAlliance(true)
    self.handles = {}
    self.alliance_caches = {}
    self.my_alliance_mapData = {
        marchEvents = {
            strikeMarchEvents = {} ,
            strikeMarchReturnEvents = {} ,
            attackMarchEvents = {},
            attackMarchReturnEvents = {} ,
        },
        villageEvents = {}
    }
    self:ResetCurrentMapData()
end
function AllianceManager:GetMyAllianceMapData()
    return self.my_alliance_mapData
end
function AllianceManager:GetMyAllianceMarchEvents()
    return self.my_alliance_mapData.marchEvents
end
function AllianceManager:HasToMyCityEvents()
    local marchEvents = self:GetMyAllianceMarchEvents()
    for k,event in pairs(marchEvents.attackMarchEvents) do
        if event ~= json.null
            and event.defencePlayerData
            and event.defencePlayerData.id == User._id
            and event.fromAlliance.id ~= self.my_alliance._id then
            return true
        end
    end
    for k,event in pairs(marchEvents.strikeMarchEvents) do
        if event ~= json.null
            and event.defencePlayerData
            and event.defencePlayerData.id == User._id
            and event.fromAlliance.id ~= self.my_alliance._id then
            return true
        end
    end
    return false
end
function AllianceManager:GetToMineMarchEvents()
    local to_my_events = {}
    local marchEvents = self:GetMyAllianceMarchEvents()
    for k,kindsOfEvents in pairs(marchEvents) do
        for id,event in pairs(kindsOfEvents) do
            if event ~= json.null
                and event.defencePlayerData
                and event.defencePlayerData.id == User:Id() then
                event.eventType = k
                table.insert(to_my_events, event)
            end
        end
    end
    return to_my_events
end
-- 获取和自己有关的行军事件
function AllianceManager:GetAboutMyMarchEvents()
    if self:GetMyAlliance():IsDefault() then
        return {},{}
    end
    local to_my_events = self:GetToMineMarchEvents()
    local out_march_events = UtilsForEvent:GetAllMyMarchEvents()
    return to_my_events,out_march_events
end
function AllianceManager:HasToMyAllianceEvents()
    local marchEvents = self:GetMyAllianceMarchEvents()
    for k,event in pairs(marchEvents.attackMarchEvents) do
        if event ~= json.null
            and event.toAlliance.id == self.my_alliance._id
            and event.fromAlliance.id ~= self.my_alliance._id then
            return true
        end
    end
    for k,event in pairs(marchEvents.strikeMarchEvents) do
        if event ~= json.null
            and event.toAlliance.id == self.my_alliance._id
            and event.fromAlliance.id ~= self.my_alliance._id then
            return true
        end
    end
    return false
end
function AllianceManager:GetMyBeAttackingEvent()
    local to_my_events = {}
    local marchEvents = self:GetMyAllianceMarchEvents()
    for k,kindsOfEvents in pairs(marchEvents) do
        for id,event in pairs(kindsOfEvents) do
            if event ~= json.null
                and event.defencePlayerData
                and event.defencePlayerData.id == User:Id()
                and event.fromAlliance.id ~= self:GetMyAlliance()._id then
                event.eventType = k
                table.insert(to_my_events, event)
            end
        end
    end
    return to_my_events
end
function AllianceManager:GetToMyAllianceMarchEvents()
    local to_my_events = {}
    local marchEvents = self:GetMyAllianceMarchEvents()
    for k,kindsOfEvents in pairs(marchEvents) do
        for id,event in pairs(kindsOfEvents) do
            if event ~= json.null
                and event.toAlliance.id == self.my_alliance._id
                and event.fromAlliance.id ~= self.my_alliance._id then
                event.eventType = k
                table.insert(to_my_events, event)
            end
        end
    end
    return to_my_events
end
function AllianceManager:GetVillageEventsByMapId(alliance, mapId)
    for k,v in pairs(alliance.villageEvents) do
        if v.villageData.id == mapId then
            return v
        end
    end
    for k,v in pairs(self.my_alliance_mapData.villageEvents) do
        if v ~= json.null and v.villageData.id == mapId then
            return v
        end
    end
    for k,v in pairs(self:GetCurrentMapData().villageEvents) do
        if v ~= json.null and v.villageData.id == mapId then
            return v
        end
    end
end
function AllianceManager:GetMyAllianceVillageEventsByMapId(alliance, mapId)
    for k,v in pairs(alliance.villageEvents) do
        if v.villageData.id == mapId then
            return v
        end
    end
    for k,v in pairs(self.my_alliance_mapData.villageEvents) do
        if v ~= json.null and v.villageData.id == mapId then
            return v
        end
    end
end
function AllianceManager:GetAllianceByCache(key)
    local cache_alliance = self.alliance_caches[key]
    if cache_alliance and self:GetMyAlliance()._id ~= cache_alliance._id then
        setmetatable(cache_alliance, Alliance)
    end
    return cache_alliance
end
function AllianceManager:RemoveAlliance(alliance)
    self:RemoveAllianceCache(alliance.mapIndex)
    self:RemoveAllianceCache(alliance._id)
end
function AllianceManager:RemoveAllianceCache(key)
    self.alliance_caches[key] = nil
end
function AllianceManager:UpdateAllianceBy(key, alliance)
    if alliance == json.null then
        self.alliance_caches[key] = nil
    else
        self.alliance_caches[key] = alliance
        self.alliance_caches[alliance._id] = alliance
    end
end
function AllianceManager:ClearCache()
    self.alliance_caches = {}
end
function AllianceManager:GetCurrentMapData()
    return self.currentMapData
end
function AllianceManager:ResetCurrentMapData()
    self.currentMapData = {
        marchEvents = {
            strikeMarchEvents = {} ,
            strikeMarchReturnEvents = {} ,
            attackMarchEvents = {},
            attackMarchReturnEvents = {} ,
        },
        villageEvents = {},
    }
end
local terrainStyle = GameDatas.AllianceMap.terrainStyle
function AllianceManager:OnEnterMapIndex(mapIndex, data)
    local allianceData = data.allianceData
    self:UpdateAllianceBy(mapIndex, allianceData)
    if allianceData == json.null then
        self:setMapDataByIndex(mapIndex, nil)
    else
        local basicInfo = allianceData.basicInfo
        local key = string.format("%s_%d", basicInfo.terrain, basicInfo.terrainStyle)
        self:setMapDataByIndex(allianceData.mapIndex, terrainStyle[key].index)
    end
    for k,v in pairs(self.alliance_caches) do
        if type(k) == "number" then
            if self.alliance_caches[v._id].mapIndex ~= k then
                self.alliance_caches[k] = nil
            end
        end
    end
    self.currentMapData = data.mapData
    for k,v in pairs(self.handles) do
        if v.OnEnterMapIndex then
            v.OnEnterMapIndex(v, mapIndex, data)
        end
    end
end
local function removeJsonNull(t)
    for k,v in pairs(t) do
        if v == json.null then
            t[k] = nil
        end
    end
end
function AllianceManager:OnMapDataChanged(mapIndex, currentMapData, deltaData)
    for _,v in pairs(self.handles) do
        if v.OnMapDataChanged then
            v.OnMapDataChanged(v, self:GetAllianceByCache(mapIndex), currentMapData, deltaData)
        end
    end
    removeJsonNull(currentMapData.villageEvents)
    for _,t in pairs(currentMapData.marchEvents) do
        removeJsonNull(t)
    end
end
function AllianceManager:OnMapAllianceChanged(allianceData, deltaData)
    for _,v in pairs(self.handles) do
        if v.OnMapAllianceChanged then
            v.OnMapAllianceChanged(v, allianceData, deltaData)
        end
    end
end
function AllianceManager:AddHandle(handle)
    self.handles[handle] = handle
end
function AllianceManager:RemoveHandle(handle)
    self.handles[handle] = nil
end
function AllianceManager:ClearAllHandles()
    self.handles = {}
end


function AllianceManager:HasBeenJoinedAlliance()
    return DataManager:getUserData().countInfo.firstJoinAllianceRewardGeted or
        not self:GetMyAlliance():IsDefault()
end

function AllianceManager:GetMyAlliance()
    return self.my_alliance
end

function AllianceManager:OnUserDataChanged(user_data,time,deltaData)
    local allianceId = user_data.allianceId
    local my_alliance = self:GetMyAlliance()
    if (allianceId == json.null or not allianceId) and not my_alliance:IsDefault() then
        self.my_alliance_mapData = {
            marchEvents = {
                strikeMarchEvents = {} ,
                strikeMarchReturnEvents = {} ,
                attackMarchEvents = {},
                attackMarchReturnEvents = {} ,
            },
            villageEvents = {}
        }
        my_alliance:Reset(deltaData)
        app:GetChatManager():emptyAllianceChannel()
        DataManager:setUserAllianceData(json.null)
    end
end

function AllianceManager:OnAllianceDataChanged(allianceData,refresh_time,deltaData)
    self:GetMyAlliance():OnAllianceDataChanged(allianceData,refresh_time,deltaData)
    local scene_name = display.getRunningScene().__cname
    if allianceData and not deltaData then
        if scene_name == "AllianceDetailScene" then
            local scene = display.getRunningScene()
            scene.current_allinace_index = nil
            scene.fetchtimer:stopAllActions()
            if not self:GetMyAlliance():IsDefault() then
                app:EnterMyAllianceScene()
            end
        end
        if allianceData.basicInfo.status == 'prepare'
            or allianceData.basicInfo.status == 'fight' then
            self:RefreshAllianceSceneIf()
        end
    end
    if deltaData then
        if self.my_mapIndex and
            self.my_mapIndex ~= allianceData.mapIndex then
            local mapIndex = self.my_mapIndex
            UIKit:showMessageDialogWithParams({
                content = _("联盟已经迁移"),
                ok_callback = function()
                    if UIKit:GetUIInstance("GameUIWorldMap") then
                        UIKit:GetUIInstance("GameUIWorldMap"):LeftButtonClicked()
                    end
                    UIKit:newGameUI("GameUIWorldMap", mapIndex, allianceData.mapIndex):AddToCurrentScene()
                end,
                auto_close = false,
                user_data = '__alliance_move_tips__'
            })
        end
        if self.status and self.status ~= allianceData.basicInfo.status then
            self:RefreshAllianceSceneIf(self.status)

            if self.status == "prepare"
                and allianceData.basicInfo.status == "fight" then
                app:GetAudioManager():PlayeEffectSoundWithKey("BATTLE_START")
            end

            local enter_fight = self.status ~= "prepare"
                and allianceData.basicInfo.status == "prepare"
            local enter_peace = self.status ~= "protect"
                and allianceData.basicInfo.status == "protect"
            -- if audio.isMusicPlaying() and
            --    (enter_fight or enter_peace) then
            --     local last_music_loop = app:GetAudioManager().last_music_loop
            --     app:GetAudioManager().last_music_loop = true
            --     app:GetAudioManager():StopMusic()
            --     app:GetAudioManager().last_music_loop = last_music_loop
            --     app:GetAudioManager():PlayGameMusicAutoCheckScene()
            -- end
        end
    end
    self.my_mapIndex = allianceData.mapIndex
    self.status = allianceData.basicInfo.status
end


function AllianceManager:setMapIndexData(mapIndexData)
    self.mapIndexData = mapIndexData
end
local terrainStyle = GameDatas.AllianceMap.terrainStyle
function AllianceManager:getMapDataByIndex(index)
    if self.mapIndexData == json.null then return end
    local key = self.mapIndexData[tostring(index)]
    if not key then return end
    for _,v in pairs(terrainStyle) do
        if v.index == key then
            local terrain, style = unpack(string.split(v.style, "_"))
            return terrain, tonumber(style)
        end
    end
end
function AllianceManager:setMapDataByIndex(index, data)
    if self.mapIndexData == json.null then return end
    self.mapIndexData[tostring(index)] = data
end
-- json decode to a alliance
function AllianceManager:DecodeAllianceFromJson( json_data )
    local alliance = Alliance.new()
    alliance:OnAllianceDataChanged(json_data)
    return alliance
end
--判断是否进入对战地图
function AllianceManager:RefreshAllianceSceneIf(old_alliance_status)
    local my_alliance = self:GetMyAlliance()
    local my_alliance_status = my_alliance.basicInfo.status
    local scene_name = display.getRunningScene().__cname
    if (my_alliance_status == 'protect') then
        self.tipUserWar = false
        if old_alliance_status == "" then return end
        print("==========>RefreshAllianceSceneIf", old_alliance_status, my_alliance_status)
        if scene_name == 'AllianceDetailScene' or scene_name == 'MyCityScene' then
            if not UIKit:GetUIInstance('GameUIWarSummary') then
                UIKit:newGameUI("GameUIWarSummary"):AddToCurrentScene(true)
            end
        end
    end
    if (my_alliance_status == 'prepare' or my_alliance_status == 'fight') then
        if scene_name == 'AllianceDetailScene' then
            if not self.tipUserWar then
                self.tipUserWar = true
                if not UIKit:isMessageDialogShowWithUserData("__alliance_war_tips__") then
                    UIKit:showMessageDialog(nil,_("联盟对战已开始，您将进入自己联盟对战地图。"),function()
                        app:EnterMyAllianceScene()
                    end,nil,false,nil,"__alliance_war_tips__")
                end
            end
        elseif scene_name == 'MyCityScene' then
            if not self.tipUserWar then
                self.tipUserWar = true
                if not UIKit:isMessageDialogShowWithUserData("__alliance_war_tips__") then
                    UIKit:showMessageDialogWithParams({
                        content = _("联盟对战已开始，您将进入自己联盟对战地图。"),
                        ok_callback = function()
                            app:EnterMyAllianceScene()
                        end,
                        cancel_callback = function()end,
                        auto_close = false,
                        user_data = '__alliance_war_tips__'
                    })
                end
            end
            -- elseif scene_name == 'MainScene' then
            --     if not self.tipUserWar then
            --         self.tipUserWar = true
            --         local dialog = UIKit:getMessageDialogWithParams({
            --             content = _("联盟对战已开始，您将进入自己联盟对战地图。"),
            --             ok_callback = function()
            --                 app:EnterMyAllianceScene()
            --             end,
            --             cancel_callback = function()end,
            --             auto_close = false,
            --             user_data = '__alliance_war_tips__'
            --         })
            --         UIKit:addMessageDialogWillShow(dialog)
            --     end
        end
    end

end

return AllianceManager




