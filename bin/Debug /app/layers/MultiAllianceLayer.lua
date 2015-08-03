local Enum = import("..utils.Enum")
local promise = import("..utils.promise")
local UILib = import("..ui.UILib")
local Alliance = import("..entity.Alliance")
local Observer = import("..entity.Observer")
local AllianceView = import(".AllianceView")
local MapLayer = import(".MapLayer")
local MultiAllianceLayer = class("MultiAllianceLayer", MapLayer)
local intInit = GameDatas.AllianceInitData.intInit
local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special
local ZORDER = Enum("BACKGROUND", "BUILDING", "INFO", "LINE", "CORPS")
local fmod = math.fmod
local ceil = math.ceil
local floor = math.floor
local min = math.min
local max = math.max
local timer = app.timer
local ipairs = ipairs
local pairs = pairs
local cc = cc
local MINE,FRIEND,ENEMY,VILLAGE_TAG = 1,2,3,4
MultiAllianceLayer.ARRANGE = Enum("H", "V")

function MultiAllianceLayer:ctor(scene, arrange, ...)
    self.refresh_village_node = display.newNode():addTo(self)
    self.my_allinace_id = Alliance_Manager:GetMyAlliance():Id()
    self.mine_player_id = Alliance_Manager:GetMyAlliance():GetSelf():Id()


    Observer.extend(self)
    MultiAllianceLayer.super.ctor(self, scene, 0.4, 1.2)
    self.info_action = display.newNode():addTo(self)
    self.track_id = nil
    self.arrange = arrange
    self.alliances = {...}
    self.alliance_views = {}
    self:InitBackground()
    self:InitBuildingNode()
    self:InitInfoNode()
    self:InitCorpsNode()
    self:InitLineNode()
    self:InitAllianceView()
    self:InitAllianceEvent()
    self:AddOrRemoveAllianceEvent(true)
    self:AddAllianceBelvedereEvent(true)
    self:StartCorpsTimer()
    self:Schedule()
    self:RefreshAllVillageEvents()


    -- local len = 0
    -- local count = 1
    -- for i = x - len, x + len do
    --     self:CreateCorps(
    --         count,
    --         {x = x, y = y, index = 1},
    --         {x = i, y = y + 10, index = 1},
    --         timer:GetServerTime(),
    --         timer:GetServerTime() + 100,
    --         "redDragon",
    --         {},
    --         ENEMY
    --     )
    --     count = count + 1
    -- end

    -- local soldier = "meatWagon"
    -- local count = 1
    -- local len = 10
    -- local star = 1
    -- for i = 12 - len, 12 + len, 3 do
    --     self:CreateCorps(
    --         count,
    --         {x = 12, y = 12, index = 1},
    --         {x = i, y = 12 + 10, index = 1},
    --         timer:GetServerTime(),
    --         timer:GetServerTime() + 100,
    --         "redDragon",
    --         {
    --             {name = soldier, star = star}
    --         },
    --         ENEMY
    --     )
    --     star = star + 1
    --     if star > 3 then star = 1 end
    --     count = count + 1
    -- end

    -- for i = 12 - len, 12 + len, 3 do
    --     self:CreateCorps(
    --         count,
    --         {x = 12, y = 12, index = 1},
    --         {x = 12 + 10, y = i, index = 1},
    --         timer:GetServerTime(),
    --         timer:GetServerTime() + 100,
    --         "redDragon",
    --         {
    --             {name = soldier, star = star}
    --         },
    --         ENEMY
    --     )
    --     star = star + 1
    --     if star > 3 then star = 1 end
    --     count = count + 1
    -- end

    -- for i = 12 - len, 12 + len, 3 do
    --     self:CreateCorps(
    --         count,
    --         {x = 12, y = 12, index = 1},
    --         {x = 12 - 10, y = i, index = 1},
    --         timer:GetServerTime(),
    --         timer:GetServerTime() + 100,
    --         "redDragon",
    --         {
    --             {name = soldier, star = star}
    --         },
    --         ENEMY
    --     )
    --     star = star + 1
    --     if star > 3 then star = 1 end
    --     count = count + 1
    -- end

    -- for i = 12 - len, 12 + len, 3 do
    --     self:CreateCorps(
    --         count,
    --         {x = 12, y = 12, index = 1},
    --         {x = i, y = 12 - 10, index = 1},
    --         timer:GetServerTime(),
    --         timer:GetServerTime() + 100,
    --         "redDragon",
    --         {
    --             {name = soldier, star = star}
    --         },
    --         ENEMY
    --     )
    --     star = star + 1
    --     if star > 3 then star = 1 end
    --     count = count + 1
    -- end
end
function MultiAllianceLayer:TrackCorpsById(id)
    if self.track_id then
        self:RemoveCorpsCircle(self.map_corps[self.track_id])
    end
    self.track_id = id
    if self.track_id then
        self:AddToCorpsCircle(self.map_corps[self.track_id])
    end
end
local CIRCLE_TAG = 4356
function MultiAllianceLayer:AddToCorpsCircle(corps)
    if not corps then return end
    if corps:getChildByTag(CIRCLE_TAG) then return end
    local sprite = display.newSprite("tmp_monster_circle.png")
        :addTo(corps, -1, CIRCLE_TAG)
    sprite:runAction(
        cc.RepeatForever:create(
            transition.sequence{
                cc.ScaleTo:create(0.5/2, 1.2),
                cc.ScaleTo:create(0.5/2, 1.1),
            }
        )
    )
    sprite:setColor(cc.c3b(96,255,0))
end
function MultiAllianceLayer:RemoveCorpsCircle(corps)
    if corps and corps:getChildByTag(CIRCLE_TAG) then
        corps:removeChildByTag(CIRCLE_TAG)
    end
end
function MultiAllianceLayer:Schedule()
    self.info_action:schedule(function()
        local scale = self:getScale()
        local l = max(0.5, scale) - 0.5
        local r = 0.8 - min(0.8, scale)
        self:GetInfoNode():opacity(l / (l + r) * 255)
    end, 0.1)
end
function MultiAllianceLayer:onCleanup()
    self:AddOrRemoveAllianceEvent(false)
    self:AddAllianceBelvedereEvent(false)
end
function MultiAllianceLayer:InitBackground()
    self:ReloadBackGround()
end
function MultiAllianceLayer:ChangeTerrain()
    self:ReloadBackGround()
    for _, v in ipairs(self.alliance_views) do
        v:ChangeTerrain()
    end
end
function MultiAllianceLayer:ReloadBackGround()
    if self.background then
        self.background:removeFromParent()
    end
    print("self:GetMapFileByArrangeAndTerrain()", self:GetMapFileByArrangeAndTerrain())
    self.background = cc.TMXTiledMap:create(self:GetMapFileByArrangeAndTerrain()):addTo(self, ZORDER.BACKGROUND)
end
function MultiAllianceLayer:GetMapFileByArrangeAndTerrain()
    local terrains = self:GetTerrains()
    if #terrains == 1 then
        return string.format("tmxmaps/alliance_%s.tmx", unpack(terrains))
    end
    local terrain1, terrain2 = unpack(terrains)
    local arrange = MultiAllianceLayer.ARRANGE.H == self.arrange and "h" or "v"
    return string.format("tmxmaps/alliance_%s_%s_%s.tmx", arrange, terrain1, terrain2)
end
function MultiAllianceLayer:GetTerrains()
    if #self.alliances == 1 then
        return {self.alliances[1]:Terrain()}
    end
    local first, second = unpack(self.alliances)
    return {first:Terrain(), second:Terrain()}
end
function MultiAllianceLayer:InitBuildingNode()
    self.building = display.newNode():addTo(self, ZORDER.BUILDING)
end
function MultiAllianceLayer:InitInfoNode()
    self.info = display.newNode():addTo(self, ZORDER.INFO)
end
function MultiAllianceLayer:InitCorpsNode()
    self.corps = display.newNode():addTo(self, ZORDER.CORPS)
    self.map_corps = {}
    self.map_dead = {}
end
function MultiAllianceLayer:InitLineNode()
    self.lines = display.newNode():addTo(self, ZORDER.LINE)
    self.map_lines = {}
end
function MultiAllianceLayer:GetBackGround()
    return self.background
end
function MultiAllianceLayer:GetBuildingNode()
    return self.building
end
function MultiAllianceLayer:GetInfoNode()
    return self.info
end
function MultiAllianceLayer:GetCorpsNode()
    return self.corps
end
function MultiAllianceLayer:GetLineNode()
    return self.lines
end
function MultiAllianceLayer:GetAllianceViews()
    return self.alliance_views
end
function MultiAllianceLayer:InitAllianceView()
    local alliance_view1, alliance_view2
    if #self.alliances == 1 then
        alliance_view1 = AllianceView.new(self, self.alliances[1]):addTo(self)
        self.alliance_views = {alliance_view1}
        return
    end
    if MultiAllianceLayer.ARRANGE.H == self.arrange then
        alliance_view1 = AllianceView.new(self, self.alliances[1], 0):addTo(self)
        alliance_view2 = AllianceView.new(self, self.alliances[2], intInit.allianceRegionMapWidth.value):addTo(self)
        -- local sx, sy = alliance_view1:GetLogicMap():ConvertToMapPosition(50.5, -3.5)
        -- local ex, ey = alliance_view1:GetLogicMap():ConvertToMapPosition(50.5, 51.5)
        -- display.newLine({{sx, sy}, {ex, ey}},
        --     {borderColor = cc.c4f(1.0, 0.0, 0.0, 1.0),
        --         borderWidth = 5}):addTo(self.building)
    else
        alliance_view1 = AllianceView.new(self, self.alliances[1], 0, intInit.allianceRegionMapHeight.value * 2 + 2):addTo(self)
        alliance_view2 = AllianceView.new(self, self.alliances[2], 0, intInit.allianceRegionMapHeight.value + 2):addTo(self)
        -- local sx, sy = alliance_view1:GetLogicMap():ConvertToMapPosition(-0.5, 51.5)
        -- local ex, ey = alliance_view1:GetLogicMap():ConvertToMapPosition(51.5, 51.5)
        -- display.newLine({{sx, sy}, {ex, ey}},
        --     {borderColor = cc.c4f(1.0, 0.0, 0.0, 1.0),
        --         borderWidth = 5}):addTo(self.building)
    end
    self.alliance_views = {alliance_view1, alliance_view2}
end
function MultiAllianceLayer:AddOrRemoveAllianceEvent(isAdd)
    if isAdd then
        for _, v in ipairs(self.alliances) do
            v:AddListenOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventDataChanged)
            v:AddListenOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchReturnEventDataChanged)
            v:AddListenOnType(self,Alliance.LISTEN_TYPE.OnStrikeMarchEventDataChanged)
            v:AddListenOnType(self,Alliance.LISTEN_TYPE.OnStrikeMarchReturnEventDataChanged)
            v:AddListenOnType(self,Alliance.LISTEN_TYPE.OnMarchEventRefreshed)
            v:AddListenOnType(self,Alliance.LISTEN_TYPE.OnVillageEventsDataChanged)
        end
    else
        for _, v in ipairs(self.alliances) do
            v:RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventDataChanged)
            v:RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchReturnEventDataChanged)
            v:RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnStrikeMarchEventDataChanged)
            v:RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnStrikeMarchReturnEventDataChanged)
            v:RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnMarchEventRefreshed)
            v:RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnVillageEventsDataChanged)
        end
    end
end
function MultiAllianceLayer:OnVillageEventsDataChanged(changed_map)
    for k,v in pairs(changed_map.removed or {}) do
        self:RefreshVillageEvent(v, false)
    end
    for _,v in ipairs(self.alliances) do
        v:IteratorVillageEvents(function(village)
            self:RefreshVillageEvent(village, true)
        end)
    end
end
function MultiAllianceLayer:RefreshAllVillageEvents()
    self.refresh_village_node:stopAllActions()
    self.refresh_village_node:performWithDelay(function()
        for i,v in ipairs(self.alliances) do
            v:IteratorVillageEvents(function(event)
                self:RefreshVillageEvent(event, true)
            end)
        end
    end, 0.1)
end
function MultiAllianceLayer:RefreshVillageEvent(village_event, is_add)
    for i,v in ipairs(self.alliance_views) do
        local obj = v:GetMapObjects()[village_event:VillageData().id]
        if obj then
            local player_data = village_event:PlayerData()
            local aid = player_data.alliance.id
            local pid = player_data.id
            local flag = obj:getChildByTag(VILLAGE_TAG)
            if is_add then
                local ally = pid == self.mine_player_id and MINE or (self.my_allinace_id == aid and FRIEND or ENEMY)
                if flag then
                    flag:SetAlly(ally)
                else
                    local x,y = obj:GetSpriteTopPosition()
                    self:CreateVillageFlag(ally)
                        :addTo(obj, 1, VILLAGE_TAG)
                        :pos(x,y+50):scale(1.5)
                end
            elseif flag then
                obj:removeChildByTag(VILLAGE_TAG)
            end
        end
    end
end
local flag_map = {
    [MINE] = {"village_flag_mine.png", "village_icon_mine.png"},
    [FRIEND] = {"village_flag_friend.png", "village_icon_friend.png"},
    [ENEMY] = {"village_flag_enemy.png", "village_icon_enemy.png"},
}
function MultiAllianceLayer:CreateVillageFlag(e)
    local head,circle = unpack(flag_map[e])
    local flag = display.newSprite(head)
    flag:setAnchorPoint(cc.p(0.5, 0.62))
    local p = flag:getAnchorPointInPoints()
    display.newSprite(circle)
        :addTo(flag,0,1):pos(p.x, p.y)
        :runAction(
            cc.RepeatForever:create(transition.sequence{cc.RotateBy:create(2, -360)})
        )
    function flag:SetAlly(e)
        local head,circle = unpack(flag_map[e])
        self:setTexture(head)
        self:getChildByTag(1):setTexture(circle)
    end
    return flag
end
function MultiAllianceLayer:AddAllianceBelvedereEvent(isAdd)
    local alliance_belvedere = self:GetMyAlliance():GetAllianceBelvedere()
    if isAdd then
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.CheckNotHaveTheEventIf)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnCommingDataChanged)
    else
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.CheckNotHaveTheEventIf)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnCommingDataChanged)
    end
end
function MultiAllianceLayer:ConvertLogicPositionToMapPosition(lx, ly, alliance_id)
    local alliance_vew = self.alliance_views[self:GetAllianceViewIndexById(alliance_id)]
    local map_pos = cc.p(alliance_vew:GetLogicMap():ConvertToMapPosition(lx, ly))
    return self:convertToNodeSpace(self.background:convertToWorldSpace(map_pos))
end
function MultiAllianceLayer:GetAllianceViewIndexById(id)
    for i,v in ipairs(self.alliances) do
        if v:Id() == id then
            return i
        end
    end
    return 1
end
function MultiAllianceLayer:GetAlliances()
    return self.alliances
end

function MultiAllianceLayer:GetMyAlliance()
    return Alliance_Manager:GetMyAlliance()
end

function MultiAllianceLayer:GetEnemyAlliance()
    return Alliance_Manager:GetEnemyAlliance()
end

function MultiAllianceLayer:InitAllianceEvent()
    for _, v in ipairs(self.alliances) do
        self:CreateAllianceCorps(v)
    end
end
function MultiAllianceLayer:StartCorpsTimer()
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        local time = timer:GetServerTime()
        for id, corps in pairs(self.map_corps) do
            if corps then
                local march_info = corps.march_info
                local total_time = march_info.finish_time - march_info.start_time
                local elapse_time = time - march_info.start_time
                if elapse_time <= total_time then
                    local len = march_info.speed * elapse_time
                    local cur_vec = cc.pAdd(cc.pMul(march_info.normal, len), march_info.start_info.real)
                    corps:pos(cur_vec.x, cur_vec.y)

                    -- 更新线
                    local line = self.map_lines[id]
                    local program = line:getFilter():getGLProgramState()
                    program:setUniformFloat("percent", fmod(time - floor(time), 1.0))
                    program:setUniformFloat("elapse", line.is_enemy and (cc.pGetLength(cc.pSub(cur_vec, march_info.origin_start)) / march_info.origin_length) or 0)

                    if self.track_id == id then
                        self:GotoMapPositionInMiddle(cur_vec.x, cur_vec.y)
                    end
                else
                    self:DeleteCorpsById(id)
                end
            end
        end
    end)
    self:scheduleUpdate()
end
function MultiAllianceLayer:CreateAllianceCorps(alliance)
    if alliance:IsMyAlliance() then -- 如果是返回事件 无条件显示
        table.foreachi(alliance:GetAttackMarchEvents(),function(_,event)
            self:CreateCorpsIf(event)
        end)
    table.foreachi(alliance:GetAttackMarchReturnEvents(),function(_,event)
        self:CreateCorpsIf(event)
    end)
    table.foreachi(alliance:GetStrikeMarchEvents(),function(_,event)
        self:CreateCorpsIf(event)
    end)
    table.foreachi(alliance:GetStrikeMarchReturnEvents(),function(_,event)
        self:CreateCorpsIf(event)
    end)
    else
        --敌方联盟
        local my_alliance_belvedere = self:GetMyAlliance():GetAllianceBelvedere()
        local my_alliance_watch_tower_level = my_alliance_belvedere:GetWatchTowerLevel()
        table.foreachi(alliance:GetAttackMarchEvents(),function(_,event)
            self:CreateEnemyTroopsIf(event,my_alliance_belvedere,my_alliance_watch_tower_level)
        end)
        table.foreachi(alliance:GetAttackMarchReturnEvents(),function(_,event)
            self:CreateEnemyTroopsIf(event,my_alliance_belvedere,my_alliance_watch_tower_level)
        end)
        table.foreachi(alliance:GetStrikeMarchEvents(),function(_,event)
            self:CreateEnemyTroopsIf(event,my_alliance_belvedere,my_alliance_watch_tower_level)
        end)
        table.foreachi(alliance:GetStrikeMarchReturnEvents(),function(_,event)
            self:CreateEnemyTroopsIf(event,my_alliance_belvedere,my_alliance_watch_tower_level)
        end)
    end
end
--过滤敌方对我的行军路线
function MultiAllianceLayer:CreateEnemyTroopsIf(event,my_alliance_belvedere,my_alliance_watch_tower_level)
    if event:IsReturnEvent() then -- 如果是返回事件 无条件显示
        self:CreateCorpsIf(event)
        return
    end
    if event.MARCH_EVENT_PLAYER_ROLE.RECEIVER  == event:GetPlayerRole() then
        if event:GetTime() <= my_alliance_belvedere:GetWarningTime(my_alliance_watch_tower_level) then
            self:CreateCorpsIf(event)
        end
    elseif my_alliance_belvedere:CanDisplayEnemyAllianceMarchEventNotAttackMe(my_alliance_watch_tower_level)  then
        self:CreateCorpsIf(event)
    end
end

-------------- changed of marchevent
--瞭望塔事件
function MultiAllianceLayer:OnCommingDataChanged()
    self:InitAllianceEvent()
end

function MultiAllianceLayer:CheckNotHaveTheEventIf(event)
    return not self:IsExistCorps(event:Id())
end
--如果是重新登陆数据刷新 刷新所有行军路线
function MultiAllianceLayer:OnMarchEventRefreshed(eventName,alliance)
    self:InitAllianceEvent()
end

function MultiAllianceLayer:OnAttackMarchEventDataChanged(changed_map,alliance)
    self:ManagerCorpsFromChangedMap(changed_map,false,alliance)
end

function MultiAllianceLayer:OnAttackMarchReturnEventDataChanged(changed_map,alliance)
    self:ManagerCorpsFromChangedMap(changed_map,false,alliance)
end

function MultiAllianceLayer:OnStrikeMarchEventDataChanged(changed_map,alliance)
    self:ManagerCorpsFromChangedMap(changed_map,true,alliance)
end

function MultiAllianceLayer:OnStrikeMarchReturnEventDataChanged(changed_map,alliance)
    self:ManagerCorpsFromChangedMap(changed_map,true,alliance)
end

function MultiAllianceLayer:ManagerCorpsFromChangedMap(changed_map,is_strkie,alliance)
    if alliance:IsMyAlliance() then
        if changed_map.removed then
            table.foreachi(changed_map.removed,function(_,marchEvent)
                local time = math.ceil(marchEvent:ArriveTime() - app.timer:GetServerTime())
                if time < 5 then -- 5秒内误差也认为是部队到达,不是撤退引起的删除行军事件
                    local player_role = marchEvent:GetPlayerRole()
                    if player_role == marchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER then
                        if is_strkie then
                            app:GetAudioManager():PlayeEffectSoundWithKey("STRIKE_PLAYER_ARRIVE")
                        else
                            if not marchEvent:IsReturnEvent() then
                                app:GetAudioManager():PlayeEffectSoundWithKey("ATTACK_PLAYER_ARRIVE")
                            end
                        end
                    end
                end
                self:DeleteCorpsById(marchEvent:Id())
            end)
        elseif changed_map.edited then
            table.foreachi(changed_map.edited,function(_,marchEvent)
                self:CreateCorpsIf(marchEvent)
            end)
        elseif changed_map.added then
            table.foreachi(changed_map.added,function(_,marchEvent)
                self:CreateCorpsIf(marchEvent, true)
            end)
        end
    else
        local my_alliance_belvedere = self:GetMyAlliance():GetAllianceBelvedere()
        local my_alliance_watch_tower_level = my_alliance_belvedere:GetWatchTowerLevel()

        if changed_map.removed then
            table.foreachi(changed_map.removed,function(_,marchEvent)
                self:DeleteCorpsById(marchEvent:Id())
            end)
        elseif changed_map.edited then
            table.foreachi(changed_map.edited,function(_,marchEvent)
                self:CreateEnemyTroopsIf(marchEvent,my_alliance_belvedere,my_alliance_watch_tower_level)
            end)
        elseif changed_map.added then
            table.foreachi(changed_map.added,function(_,marchEvent)
                self:CreateEnemyTroopsIf(marchEvent,my_alliance_belvedere,my_alliance_watch_tower_level)
            end)
        end
    end
end

--适配数据给界面 如果已有路线会更新
function MultiAllianceLayer:CreateCorpsIf(marchEvent, is_added_event)
    local from,from_alliance_id = marchEvent:FromLocation()
    from.index = self:GetAllianceViewIndexById(from_alliance_id)
    local to,to_alliance_id   = marchEvent:TargetLocation()
    to.index = self:GetAllianceViewIndexById(to_alliance_id)
    local is_enemy = false
    if not marchEvent:IsReturnEvent() then
        is_enemy = self:GetMyAlliance():Id() ~= from_alliance_id
    else -- return
        is_enemy = self:GetMyAlliance():Id() ~= to_alliance_id
    end
    local ally = ENEMY
    if not is_enemy then
        if not marchEvent:IsReturnEvent() then
            if marchEvent:GetPlayerRole() == marchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER  then
                ally = MINE
            else
                ally = FRIEND
            end
        else -- return
            if marchEvent:GetPlayerRole() == marchEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER  then
                ally = MINE
        else
            ally = FRIEND
        end
        end
    end
    local player_data = marchEvent:AttackPlayerData()
    self:CreateCorps(
        marchEvent:Id(),
        from,
        to,
        marchEvent:StartTime(),
        marchEvent:ArriveTime(),
        marchEvent:AttackPlayerData().dragon.type,
        marchEvent:AttackPlayerData().soldiers,
        ally,
        player_data.name
    )
    if is_added_event and ally == MINE and not marchEvent:IsReturnEvent() then
        self:TrackCorpsById(marchEvent:Id())
    end
    if marchEvent:IsReturnEvent() then
        self:CreateDeadEvent(marchEvent)
    end
end
local corps_scale = 1.2
local dragon_dir_map = {
    [0] = {"flying_45", -corps_scale}, -- x-,y+
    {"flying_45", -corps_scale}, -- x-,y+
    {"flying_-45", -corps_scale}, -- x-

    {"flying_-45", -corps_scale}, -- x-,y-
    {"flying_-45", corps_scale}, -- y+
    {"flying_-45", corps_scale}, -- x+,y+

    {"flying_45", corps_scale}, -- x+
    {"flying_45", corps_scale}, -- x+,y-
    {"flying_45", corps_scale}, -- y-
}
local soldier_scale = 1
local soldier_dir_map = {
    [0] = {"move_45", - corps_scale, soldier_scale}, -- x-,y+
    {"move_45", - corps_scale, soldier_scale}, -- x-,y+
    {"move_-45", - corps_scale, soldier_scale}, -- x-

    {"move_-45", - corps_scale, soldier_scale}, -- x-,y-
    {"move_-45", corps_scale, soldier_scale}, -- y+
    {"move_-45", corps_scale, soldier_scale}, -- x+,y+

    {"move_45", corps_scale, soldier_scale}, -- x+
    {"move_45", corps_scale, soldier_scale}, -- x+,y-
    {"move_45", corps_scale, soldier_scale}, -- y-
}
local soldier_config = {
    ----
    ["swordsman"] = {
        count = 4,
        {"bubing_1"},
        {"bubing_2"},
        {"bubing_3"},
    },
    ["ranger"] = {
        count = 4,
        {"gongjianshou_1"},
        {"gongjianshou_2"},
        {"gongjianshou_3"},
    },
    ["lancer"] = {
        count = 2,
        {"qibing_1"},
        {"qibing_2"},
        {"qibing_3"},
    },
    ["catapult"] = {
        count = 1,
        {  "toushiche"},
        {"toushiche_2"},
        {"toushiche_3"},
    },

    -----
    ["sentinel"] = {
        count = 4,
        {"shaobing_1"},
        {"shaobing_2"},
        {"shaobing_3"},
    },
    ["crossbowman"] = {
        count = 4,
        {"nugongshou_1"},
        {"nugongshou_2"},
        {"nugongshou_3"},
    },
    ["horseArcher"] = {
        count = 2,
        {"youqibing_1"},
        {"youqibing_2"},
        {"youqibing_3"},
    },
    ["ballista"] = {
        count = 1,
        {"nuche_1"},
        {"nuche_2"},
        {"nuche_3"},
    },
    ----
    ["skeletonWarrior"] = {
        count = 4,
        {"kulouyongshi"},
        {"kulouyongshi"},
        {"kulouyongshi"},
    },
    ["skeletonArcher"] = {
        count = 4,
        {"kulousheshou"},
        {"kulousheshou"},
        {"kulousheshou"},
    },
    ["deathKnight"] = {
        count = 2,
        {"siwangqishi"},
        {"siwangqishi"},
        {"siwangqishi"},
    },
    ["meatWagon"] = {
        count = 1,
        {"jiaorouche"},
        {"jiaorouche"},
        {"jiaorouche"},
    },
}

local len = 30
local location_map = {
    [1] = {
        {0, 0},
    },
    [2] = {
        {0, len * 0.5},
        {0, - len * 0.5},
    },
    [4] = {
        {len * 0.5, len * 0.5},
        {- len * 0.5, len * 0.5},
        {len * 0.5, - len * 0.5},
        {- len * 0.5, - len * 0.5},
    },
}
local function move_soldiers(corps, ani, dir_index, first_soldier)
    local is_special = SPECIAL[first_soldier.name]
    local star = is_special and 3 or (first_soldier.star or 1)
    local config = soldier_config[first_soldier.name]
    local ani_name = unpack(config[star])
    local _,_,s = unpack(soldier_dir_map[dir_index])
    local create_function
    if ani == "move_45" then
        create_function = UIKit.CreateSoldierMove45Ani
    elseif ani == "move_-45" then
        create_function = UIKit.CreateSoldierMoveNeg45Ani
    else
        assert(false)
    end
    for i,v in ipairs(location_map[config.count]) do
        local x,y = unpack(v)
        create_function(UIKit, ani_name):addTo(corps):pos(x,y)
    end
end
function MultiAllianceLayer:CreateCorps(id, start_pos, end_pos, start_time, finish_time, dragonType, soldiers, ally, banner_name)
    if finish_time <= timer:GetServerTime() then return end
    local march_info = self:GetMarchInfoWith(id, start_pos, end_pos)
    if start_time == march_info.start_time and
        finish_time == march_info.finish_time then
        return
    end
    march_info.start_time = start_time
    march_info.finish_time = finish_time
    march_info.speed = (march_info.length / (finish_time - start_time))
    if not self.map_corps[id] then
        local index = math.floor(march_info.degree / 45) + 4
        if index < 0 or index > 8 then index = 1 end
        local corps = display.newNode():addTo(self:GetCorpsNode())
        local ani,scalex
        local is_strike = not soldiers or #soldiers == 0
        if is_strike then
            ani,scalex = unpack(dragon_dir_map[index])
            local dragon_ani = UILib.dragon_animations[dragonType or "redDragon"][1]
            if ani == "flying_45" then
                UIKit:CreateDragonFly45Ani(dragon_ani):addTo(corps)
            elseif ani == "flying_-45" then
                UIKit:CreateDragonFlyNeg45Ani(dragon_ani):addTo(corps)
            else
                assert(false)
            end
        else
            ani,scalex = unpack(soldier_dir_map[index])
            move_soldiers(corps, ani, index, soldiers[1])
        end
        if ally == MINE or ally == FRIEND then
            if banner_name then
                UIKit:CreateNameBanner(banner_name, dragonType)
                    :addTo(corps, 1):pos(0, 80):setScaleX(scalex > 0 and 1 or -1)
            end
        end
        corps:setScaleX(scalex)
        corps:setScaleY(math.abs(scalex))
        corps.march_info = march_info
        corps:pos(march_info.start_info.real.x, march_info.start_info.real.y)
        self.map_corps[id] = corps
        self:CreateLine(id, march_info, ally)
    else
        self:UpdateCorpsBy(self.map_corps[id], march_info)
    end
    return corps
end
function MultiAllianceLayer:UpdateCorpsBy(corps, march_info)
    local x,y = corps:getPosition()
    local cur_pos = {x = x, y = y}
    march_info.start_info.real = cur_pos
    march_info.start_time = timer:GetServerTime()
    march_info.length = cc.pGetLength(cc.pSub(march_info.end_info.real, cur_pos))
    march_info.speed = (march_info.length / (march_info.finish_time - march_info.start_time))
    corps.march_info = march_info
end
function MultiAllianceLayer:DeleteCorpsById(id)
    if self.map_dead[id] then
        self.map_dead[id]:removeFromParent()
        self.map_dead[id] = nil
    end
    if self.map_corps[id] then
        self.map_corps[id]:removeFromParent()
        self.map_corps[id] = nil
        self:DeleteLineById(id)
    else
        print("部队已经被删除了", id)
    end
end
function MultiAllianceLayer:DeleteAllCorps()
    for id, _ in pairs(self.map_corps) do
        self:DeleteCorpsById(id)
    end
end
function MultiAllianceLayer:IsExistCorps(id)
    return self.map_corps[id] ~= nil
end
local line_ally_map = {
    [MINE] = "arrow_green_22x32.png",
    [FRIEND] = "arrow_blue_22x32.png",
    [ENEMY] = "arrow_red_22x32.png",
}
function MultiAllianceLayer:CreateLine(id, march_info, ally)
    if self.map_lines[id] then
        self.map_lines[id]:removeFromParent()
    end
    local middle = cc.pMidpoint(march_info.start_info.real, march_info.end_info.real)
    local scale = march_info.length / 32
    local unit_count = math.floor(scale)
    local sprite = display.newSprite(line_ally_map[ally]
        , nil, nil, {class=cc.FilteredSpriteWithOne})
        :addTo(self:GetLineNode())
        :pos(middle.x, middle.y)
        :rotation(march_info.degree)
    sprite:setFilter(filter.newFilter("CUSTOM",
        json.encode({
            frag = "shaders/multi_tex.fs",
            shaderName = "lineShader_"..id,
            unit_count = unit_count,
            unit_len = 1 / unit_count,
            percent = 0,
            elapse = 0,
        })
    ))
    sprite:setScaleY(scale)
    sprite.is_enemy = ally == ENEMY
    self.map_lines[id] = sprite
    return sprite
end
function MultiAllianceLayer:GetMarchInfoWith(id, logic_start_point, logic_end_point)
    assert(logic_start_point.index and logic_end_point.index,"")
    local spt = self.alliance_views[logic_start_point.index]:GetLogicMap():WrapConvertToMapPosition(logic_start_point.x, logic_start_point.y)
    local ept = self.alliance_views[logic_end_point.index]:GetLogicMap():WrapConvertToMapPosition(logic_end_point.x, logic_end_point.y)
    local vector = cc.pSub(ept, spt)
    local degree = math.deg(cc.pGetAngle(vector, {x = 0, y = 1}))
    local length = cc.pGetLength(vector)
    return {
        origin_start = spt,
        origin_length = length,
        start_info = {real = spt, logic = logic_start_point},
        end_info = {real = ept, logic = logic_end_point},
        degree = degree,
        length = length,
        normal = cc.pNormalize(vector)
    }
end
function MultiAllianceLayer:DeleteLineById(id)
    if self.map_lines[id] then
        self.map_lines[id]:removeFromParent()
        self.map_lines[id] = nil
    end
end
function MultiAllianceLayer:DeleteAllLines()
    for id, _ in pairs(self.map_lines) do
        self:DeleteLineById(id)
    end
end
local map_dead_image = {
    monster = "warriors_tomb_80x72.png",
    village = "ruin_2.png"
}
function MultiAllianceLayer:CreateDeadEvent(marchEvent)
    local id_corps = marchEvent:Id()
    if not self:IsExistCorps(id_corps) then return end
    local event_type = marchEvent:MarchType()
    local dead_image = map_dead_image[event_type]
    if not dead_image then return end
    local id_dead
    if event_type == "monster" then
        id_dead = marchEvent:DefenceMonsterData().id
        -- elseif event_type == "village" then
        -- id_dead = marchEvent:DefenceVillageData().id
    else
        return
    end
    if not self.map_dead[id_corps] and next(marchEvent:AttackPlayerData().rewards) then
        local point = self.map_corps[id_corps].march_info.start_info.logic
        local alliance_view = self.alliance_views[point.index]
        local x,y = alliance_view:GetLogicMap():ConvertToMapPosition(point.x, point.y)
        local z = alliance_view:GetZOrderBy(nil, point.x, point.y)
        self.map_dead[id_corps] = display.newSprite(dead_image):addTo(self:GetBuildingNode(),z):pos(x,y)
    end
end




function MultiAllianceLayer:GetClickedObject(world_x, world_y)
    local logic_x, logic_y, alliance_view = self:GetAllianceCoordWithPoint(world_x, world_y)
    return alliance_view:GetClickedObject(world_x, world_y), self:GetMyAlliance():Id() == alliance_view:GetAlliance():Id()
end
local CLICK_EMPTY_TAG = 911
function MultiAllianceLayer:PromiseOfFlashEmptyGround(building, is_my_alliance)
    local alliance_view
    for i,v in ipairs(self.alliance_views) do
        if is_my_alliance and v:GetAlliance():Id() == self:GetMyAlliance():Id() then
            alliance_view = v
            break
        end
        if not is_my_alliance and v:GetAlliance():Id() ~= self:GetMyAlliance():Id() then
            alliance_view = v
            break
        end
    end
    self:RemoveClickNode()
    local click_node = display.newSprite("click_empty.png"):addTo(self:GetBuildingNode(), 10000, CLICK_EMPTY_TAG)
    local logic_map = alliance_view:GetLogicMap()
    local lx,ly = building:GetEntity():GetLogicPosition()
    local p = promise.new()
    click_node:pos(logic_map:ConvertToMapPosition(lx,ly)):opacity(0)
        :runAction(
            transition.sequence{
                cc.FadeTo:create(0.15, 255),
                cc.FadeTo:create(0.15, 0),
                cc.CallFunc:create(function()
                    p:resolve()
                    self:RemoveClickNode()
                end)
            }
        )
    return p
end
function MultiAllianceLayer:AddClickNode()
    self:RemoveClickNode()
    return display.newNode():addTo(self:GetBuildingNode(), 10000, CLICK_EMPTY_TAG)
end
function MultiAllianceLayer:RemoveClickNode()
    self:GetBuildingNode():removeChildByTag(CLICK_EMPTY_TAG)
end

----- override
function MultiAllianceLayer:getContentSize()
    if not self.content_size then
        local layer = self.background:getLayer("layer1")
        self.content_size = layer:getContentSize()
    end
    return self.content_size
end
function MultiAllianceLayer:GetCurrentViewAllianceCoordinate()
    local logic_x, logic_y, alliance_view = self:GetAllianceCoordWithPoint(display.cx, display.cy)
    return logic_x, logic_y, alliance_view
end
function MultiAllianceLayer:GetAllianceCoordWithPoint(x, y)
    local point = self:GetBuildingNode():convertToNodeSpace(cc.p(x, y))
    local logic_x, logic_y, alliance_view
    if #self.alliance_views == 1 then
        logic_x, logic_y = self.alliance_views[1]:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
        return logic_x, logic_y, unpack(self.alliance_views)
    end
    if self.arrange == MultiAllianceLayer.ARRANGE.H then
        local left_allaince, right_alliance = unpack(self.alliance_views)
        logic_x, logic_y = right_alliance:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
        alliance_view = right_alliance
        if logic_x < 0 then
            logic_x, logic_y = left_allaince:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
            alliance_view = left_allaince
        end
    else
        local up_alliance, down_alliance = unpack(self.alliance_views)
        logic_x, logic_y = down_alliance:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
        alliance_view = down_alliance
        if logic_y < 0 then
            logic_x, logic_y = up_alliance:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
            alliance_view = up_alliance
        end
    end
    return logic_x, logic_y, alliance_view
end







return MultiAllianceLayer




















