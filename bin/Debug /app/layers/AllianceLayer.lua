local Enum = import("..utils.Enum")
local promise = import("..utils.promise")
local Localize = import("..utils.Localize")
local cocos_promise = import("..utils.cocos_promise")
local UILib = import("..ui.UILib")
local Alliance = import("..entity.Alliance")
local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local fire = import("..particles.fire")
local smoke_city = import("..particles.smoke_city")
local NormalMapAnchorBottomLeftReverseY = import("..map.NormalMapAnchorBottomLeftReverseY")
local MapLayer = import(".MapLayer")
local AllianceLayer = class("AllianceLayer", MapLayer)
local ZORDER = Enum("BACKGROUND", "EMPTY", "OBJECT", "INFO", "LINE", "CORPS")
local monsters = GameDatas.AllianceInitData.monsters
local AllianceMap = GameDatas.AllianceMap
local buildingName = AllianceMap.buildingName
local ui_helper = WidgetAllianceHelper.new()
local decorator_image = UILib.decorator_image
local alliance_building = UILib.alliance_building
local other_alliance_building = UILib.other_alliance_building
local intInit = GameDatas.AllianceInitData.intInit
local bigMapLength_value = intInit.bigMapLength.value
local MAP_LEGNTH_WIDTH = bigMapLength_value
local MAP_LEGNTH_HEIGHT = bigMapLength_value
local TILE_WIDTH = 160
local ALLIANCE_WIDTH, ALLIANCE_HEIGHT = intInit.allianceRegionMapWidth.value, intInit.allianceRegionMapHeight.value
local worldsize = {width = ALLIANCE_WIDTH * 160 * MAP_LEGNTH_WIDTH, height = ALLIANCE_HEIGHT * 160 * MAP_LEGNTH_HEIGHT}
local timer = app.timer
local MINE,FRIEND,ENEMY = 1,2,3
local SPRITE_TAG = 112
local CLOUD_TAG = 120
local function createBuildingSprite(png)
    return display.newSprite(png, nil, nil, {class=cc.FilteredSpriteWithOne})
end
local function getZorderByXY(x, y)
    return x + ALLIANCE_WIDTH * y
end
function AllianceLayer:ctor(scene)
    AllianceLayer.super.ctor(self, scene, 0.4, 1.2)
end
function AllianceLayer:onEnter()
    self:InitAllianceMap()
    self.map = self:CreateMap()
    self.background_node = display.newNode():addTo(self.map, ZORDER.BACKGROUND)
    self.objects_node = display.newNode():addTo(self.map, ZORDER.OBJECT)
    self.lines_node = display.newNode():addTo(self.map, ZORDER.LINE)
    self.corps_node = display.newNode():addTo(self, ZORDER.CORPS)
    self.info_node = display.newNode():addTo(self, ZORDER.INFO)
    self.empty_node = display.newNode():addTo(self, ZORDER.EMPTY)
    self.map_lines = {}
    self.map_corps = {}
    self.map_dead = {}

    self:StartCorpsTimer()




    -- local x,y = 15, 15
    -- local len = 0
    -- local count = 1
    -- for i = x - len, x + len do
    --     self:CreateOrUpdateCorps(
    --         count,
    --         {x = x, y = y, index = 0},
    --         {x = i, y = y + 10, index = 0},
    --         timer:GetServerTime(),
    --         timer:GetServerTime() + 100,
    --         "redDragon",
    --         {{name = "swordsman", star = 1}},
    --         FRIEND,
    --         "hello"
    --     )
    --     count = count + 1
    -- end
    scheduleAt(self, function()
        if self:getScale() < (self:GetScaleRange()) * 1.5 then
            if self.is_show == nil or self.is_show == true then
                self.info_node:fadeOut(0.5)
                self.is_show = false
            end
        else
            if self.is_show == nil or self.is_show == false then
                self.info_node:fadeIn(0.5)
                self.is_show = true
            end
        end
    end)
end
function AllianceLayer:onCleanup()
    local count = 0
    for k,v in pairs(self.alliance_bg) do
        count = count + 1
    end
    -- print_("===============")
    -- print_("alliance_nomanland.1:", #self.alliance_nomanland[1])
    -- print_("alliance_nomanland.2:", #self.alliance_nomanland[2])
    -- print_("alliance_nomanland.3:", #self.alliance_nomanland[3])
    -- print_("alliance_nomanland.4:", #self.alliance_nomanland[4])
    -- print_("alliance_objects:", count)
    -- print_("alliance_objects_free.1:", #self.alliance_objects_free[1])
    -- print_("alliance_objects_free.2:", #self.alliance_objects_free[2])
    -- print_("alliance_objects_free.3:", #self.alliance_objects_free[3])
    -- print_("alliance_objects_free.4:", #self.alliance_objects_free[4])
    -- print_("alliance_objects_free.5:", #self.alliance_objects_free[5])
    -- print_("alliance_objects_free.6:", #self.alliance_objects_free[6])
    -- print_("alliance_bg:", count)
    -- print_("alliance_bg_free.desert:", #self.alliance_bg_free.desert)
    -- print_("alliance_bg_free.grassLand:", #self.alliance_bg_free.grassLand)
    -- print_("alliance_bg_free.iceField:", #self.alliance_bg_free.iceField)
    -- print_("===============")
    for _,v1 in pairs(self.alliance_nomanland) do
        for _,v2 in pairs(v1) do
            v2:release()
        end
    end

    for _,v1 in pairs(self.alliance_bg_free) do
        for _,v2 in pairs(v1) do
            v2:release()
        end
    end

    for _,v1 in pairs(self.alliance_objects_free) do
        for _,v2 in pairs(v1) do
            v2:release()
        end
    end
end
function AllianceLayer:InitAllianceMap()
    self.alliance_nomanland = {
        {},
        {},
        {},
        {},
    }

    self.alliance_objects = {}
    self.alliance_objects_free = {
        {},
        {},
        {},
        {},
        {},
        {},
    }

    self.alliance_bg = {}
    self.alliance_bg_free = {
        desert = {},
        grassLand = {},
        iceField = {},
    }
    -- display.newNode():addTo(self):schedule(function()
    --     local count = 0
    --     for k,v in pairs(self.alliance_bg) do
    --         count = count + 1
    --     end

    --     print("alliance_objects:", count)
    --     print("alliance_objects_free.1:", #self.alliance_objects_free[1])
    --     print("alliance_objects_free.2:", #self.alliance_objects_free[2])
    --     print("alliance_objects_free.3:", #self.alliance_objects_free[3])
    --     print("alliance_objects_free.4:", #self.alliance_objects_free[4])
    --     print("alliance_objects_free.5:", #self.alliance_objects_free[5])
    --     print("alliance_objects_free.6:", #self.alliance_objects_free[6])
    --     print("alliance_bg:", count)
    --     print("alliance_bg_free.desert:", #self.alliance_bg_free.desert)
    --     print("alliance_bg_free.grassLand:", #self.alliance_bg_free.grassLand)
    --     print("alliance_bg_free.iceField:", #self.alliance_bg_free.iceField)
    --     print("===============")
    -- end, 5)
end
function AllianceLayer:CreateMap()
    local map = display.newNode():addTo(self)

    self.normal_map = NormalMapAnchorBottomLeftReverseY.new{
        tile_w = TILE_WIDTH,
        tile_h = TILE_WIDTH,
        map_width = ALLIANCE_WIDTH * MAP_LEGNTH_WIDTH,
        map_height = ALLIANCE_HEIGHT * MAP_LEGNTH_HEIGHT,
        base_x = 0,
        base_y = ALLIANCE_HEIGHT * MAP_LEGNTH_HEIGHT * TILE_WIDTH,
    }

    self.alliance_logic_map = NormalMapAnchorBottomLeftReverseY.new{
        tile_w = TILE_WIDTH * ALLIANCE_WIDTH,
        tile_h = TILE_WIDTH * ALLIANCE_HEIGHT,
        map_width = MAP_LEGNTH_WIDTH,
        map_height = MAP_LEGNTH_HEIGHT,
        base_x = 0,
        base_y = ALLIANCE_HEIGHT * MAP_LEGNTH_HEIGHT * TILE_WIDTH,
    }

    self.inner_alliance_logic_map = NormalMapAnchorBottomLeftReverseY.new{
        tile_w = TILE_WIDTH,
        tile_h = TILE_WIDTH,
        map_width = ALLIANCE_WIDTH,
        map_height = ALLIANCE_HEIGHT,
        base_x = 0,
        base_y = intInit.allianceRegionMapHeight.value * TILE_WIDTH
    }

    return map
end
function AllianceLayer:StartCorpsTimer()
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
                    program:setUniformFloat("percent", math.fmod(time - math.floor(time), 1.0))
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
local function getAllyFromEvent(event)
    if event.attackPlayerData.id == User._id then
        return MINE
    end
    local alliance_id = event.fromAlliance.id
    if alliance_id == Alliance_Manager:GetMyAlliance()._id then
        return FRIEND
    end
    return ENEMY
end
function AllianceLayer:CreateOrUpdateCorpsBy(event, isreturn)
    local myid = Alliance_Manager:GetMyAlliance()._id
    if isreturn then
        local sour_index
        if myid == event.toAlliance.id then
            sour_index = Alliance_Manager:GetMyAlliance().mapIndex
        else
            sour_index = event.toAlliance.mapIndex
        end

        local dest_index
        if myid == event.fromAlliance.id then
            dest_index = Alliance_Manager:GetMyAlliance().mapIndex
        else
            dest_index = event.fromAlliance.mapIndex
        end
        self:CreateOrUpdateCorps(
            event.id,
            {x = event.toAlliance.location.x, y = event.toAlliance.location.y, index = sour_index},
            {x = event.fromAlliance.location.x, y = event.fromAlliance.location.y, index = dest_index},
            event.startTime / 1000,
            event.arriveTime / 1000,
            event.attackPlayerData.dragon.type,
            event.attackPlayerData.soldiers,
            getAllyFromEvent(event),
            string.format("[%s]%s", event.fromAlliance.tag, event.attackPlayerData.name)
        )        

        if event.marchType == "monster"
        or event.marchType == "village" then
            self:CreateDeadEvent(event)
        end
    else
        local sour_index
        if myid == event.fromAlliance.id then
            sour_index = Alliance_Manager:GetMyAlliance().mapIndex
        else
            sour_index = event.fromAlliance.mapIndex
        end
        
        local dest_index
        if myid == event.toAlliance.id then
            dest_index = Alliance_Manager:GetMyAlliance().mapIndex
        else
            dest_index = event.toAlliance.mapIndex
        end
        self:CreateOrUpdateCorps(
            event.id,
            {x = event.fromAlliance.location.x, y = event.fromAlliance.location.y, index = sour_index},
            {x = event.toAlliance.location.x, y = event.toAlliance.location.y, index = dest_index},
            event.startTime / 1000,
            event.arriveTime / 1000,
            event.attackPlayerData.dragon.type,
            event.attackPlayerData.soldiers,
            getAllyFromEvent(event),
            string.format("[%s]%s", event.fromAlliance.tag, event.attackPlayerData.name)
        )
    end
end
function AllianceLayer:CreateOrUpdateCorps(id, start_pos, end_pos, start_time, finish_time, dragonType, soldiers, ally, banner_name)
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
        local corps = display.newNode():addTo(self.corps_node)
        local is_strike = not soldiers or #soldiers == 0
        if is_strike then
            UIKit:CreateDragonByDegree(march_info.degree, 1.2, dragonType):addTo(corps)
        else
            UIKit:CreateMoveSoldiers(march_info.degree, soldiers[1]):addTo(corps)
        end
        if (ally == MINE or ally == FRIEND) and banner_name then
            UIKit:CreateNameBanner(banner_name, dragonType):addTo(corps, 1):pos(0, 80)
        end
        corps.march_info = march_info
        corps:pos(march_info.start_info.real.x, march_info.start_info.real.y)
        self.map_corps[id] = corps
        self:CreateLine(id, march_info, ally)
    else
        self:UpdateCorpsBy(self.map_corps[id], march_info)
    end
    return corps
end
local resource_map = {
    food = true,
    wood = true,
    iron = true,
    coin = true,
    stone = true,
}
function AllianceLayer:CreateDeadEvent(event)
    local myid = Alliance_Manager:GetMyAlliance()._id
    local id_corps = event.id
    if not self:IsExistCorps(id_corps) or self.map_dead[id_corps] then return end
    local is_dead = false
    if event.marchType == "monster" then
        is_dead = not not next(event.attackPlayerData.rewards)
    -- elseif event.marchType == "village" then
    --     local alliance = Alliance_Manager:GetAllianceByCache(event.toAlliance.id)
    --     if alliance and event.toAlliance.id ~= Alliance_Manager:GetMyAlliance()._id then
    --         if not Alliance.GetAllianceVillageInfosById(alliance, event.defenceVillageData.id) then
    --             is_dead = true
    --         end
    --     end
    end
    if is_dead then
        local mapIndex
        if myid == event.toAlliance.id then
            mapIndex = Alliance_Manager:GetMyAlliance().mapIndex
        else
            mapIndex = event.toAlliance.mapIndex
        end
        local point = self:RealPosition(mapIndex, 
                                      event.toAlliance.location.x, 
                                      event.toAlliance.location.y)
        self.map_dead[id_corps] = self:CreateDeadSpriteByEvent(event)
                                    :addTo(self.objects_node, point.x*point.y):pos(point.x,point.y)
    end
end
function AllianceLayer:CreateDeadSpriteByEvent(event)
    local sprite
    if event.marchType == "village" then
        local config = SpriteConfig[event.defenceVillageData.name]
        :GetConfigByLevel(tonumber(event.defenceVillageData.level))
        sprite = display.newSprite(config.png):scale(config.scale)
        local size = sprite:getContentSize()
        fire():addTo(sprite):pos(size.width/2, 30)
    else
        sprite = display.newSprite("warriors_tomb_80x72.png")
    end
    return sprite
end
function AllianceLayer:UpdateCorpsBy(corps, march_info)
    local x,y = corps:getPosition()
    local cur_pos = {x = x, y = y}
    march_info.start_info.real = cur_pos
    march_info.start_time = timer:GetServerTime()
    march_info.length = cc.pGetLength(cc.pSub(march_info.end_info.real, cur_pos))
    march_info.speed = (march_info.length / (march_info.finish_time - march_info.start_time))
    corps.march_info = march_info
end
function AllianceLayer:GetMarchInfoWith(id, logic_start_point, logic_end_point)
    local spt = self:RealPosition(logic_start_point.index, logic_start_point.x, logic_start_point.y)
    local ept = self:RealPosition(logic_end_point.index, logic_end_point.x, logic_end_point.y)
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
function AllianceLayer:DeleteCorpsById(id)
    if self.map_dead[id] then
        self.map_dead[id]:removeFromParent()
        self.map_dead[id] = nil
    end
    if self.map_corps[id] then
        self.map_corps[id]:removeFromParent()
        self.map_corps[id] = nil
    end
    if self.map_lines[id] then
        self.map_lines[id]:removeFromParent()
        self.map_lines[id] = nil
    end
end
function AllianceLayer:IsExistCorps(id)
    return self.map_corps[id] ~= nil
end
local line_ally_map = {
    [MINE] = "arrow_green_22x32.png",
    [FRIEND] = "arrow_blue_22x32.png",
    [ENEMY] = "arrow_red_22x32.png",
}
function AllianceLayer:CreateLine(id, march_info, ally)
    if self.map_lines[id] then
        self.map_lines[id]:removeFromParent()
    end
    local middle = cc.pMidpoint(march_info.start_info.real, march_info.end_info.real)
    local scale = march_info.length / 32
    local unit_count = math.floor(scale)
    local sprite = createBuildingSprite(line_ally_map[ally])
        :addTo(self.lines_node)
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
function AllianceLayer:GetMiddleAllianceIndex()
    local point = self.map:convertToNodeSpace(cc.p(display.cx, display.cy))
    return self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))
end
function AllianceLayer:GetMiddlePosition()
    local point = self.map:convertToNodeSpace(cc.p(display.cx, display.cy))
    local logic_x, logic_y = self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
    return logic_x, logic_y
end
function AllianceLayer:GetVisibleAllianceIndexs()
    local t = {}
    local point = self.map:convertToNodeSpace(cc.p(0, display.height))
    t[1] = self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))

    local point = self.map:convertToNodeSpace(cc.p(0, 0))
    t[2] = self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))

    local point = self.map:convertToNodeSpace(cc.p(display.width, display.height))
    t[3] = self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))

    local point = self.map:convertToNodeSpace(cc.p(display.width, 0))
    t[4] = self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))
    return t
end
function AllianceLayer:GetLogicMap()
    return self.normal_map
end
function AllianceLayer:RealPosition(index, lx, ly)
    local x,y = self:IndexToLogic(index)
    return self:ConvertLogicPositionToMapPosition(ALLIANCE_WIDTH * x + lx, ALLIANCE_HEIGHT * y + ly)
end
function AllianceLayer:IndexToLogic(index)
    return index % MAP_LEGNTH_WIDTH, math.floor(index / MAP_LEGNTH_WIDTH)
end
function AllianceLayer:LogicToIndex(x, y)
    return x + y * MAP_LEGNTH_WIDTH
end
function AllianceLayer:GetInnerAllianceLogicMap()
    return self.inner_alliance_logic_map
end
function AllianceLayer:GetAllianceLogicMap()
    return self.alliance_logic_map
end
function AllianceLayer:ConvertLogicPositionToAlliancePosition(lx, ly)
    return self:convertToNodeSpace(self.map:convertToWorldSpace(cc.p(self.alliance_logic_map:ConvertToMapPosition(lx, ly))))
end
function AllianceLayer:ConvertLogicPositionToMapPosition(lx, ly)
    return self:convertToNodeSpace(self.map:convertToWorldSpace(cc.p(self.normal_map:ConvertToMapPosition(lx, ly))))
end
function AllianceLayer:GetClickedObject(world_x, world_y)
    local point = self.map:convertToNodeSpace(cc.p(world_x, world_y))
    local logic_x, logic_y = self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
    local index = self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))
    local x,y = logic_x % ALLIANCE_WIDTH, logic_y % ALLIANCE_HEIGHT
    if x == 0
    or x == ALLIANCE_WIDTH - 1
    or y == 0
    or y == ALLIANCE_HEIGHT - 1 then
        return {index = index, x = x, y = y, name = "nouse"}
    end
    return self:FindMapObject(index, x, y)
end
function AllianceLayer:GetMapIndexByWorldPosition(world_x, world_y)
    local point = self.map:convertToNodeSpace(cc.p(world_x, world_y))
    local logic_x, logic_y = self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
    local index = self:LogicToIndex(self:GetAllianceLogicMap():ConvertToLogicPosition(point.x, point.y))
    return index
end
local buildingName = GameDatas.AllianceMap.buildingName
function AllianceLayer:FindMapObject(index, x, y)
    local alliance_object = self.alliance_objects[index]
    if alliance_object.nomanland then return end
    if alliance_object then
        for k,v in pairs(alliance_object.mapObjects) do
            if v.x == x and v.y == y then
                return {index = index, x = v.x, y = v.y, name = v.name, obj = v}
            end
        end
        for k,v in pairs(alliance_object.buildings) do
            if v.x == x and v.y == y then
                return {index = index, x = v.x, y = v.y, name = v.name, obj = v}
            end
        end
        for k,v in pairs(alliance_object.decorators) do
            v.location = {x = v.x, y = v.y}
            if Alliance:IsContainPointWithMapObj(v, x, y) then
                local x,y = Alliance:GetMidLogicPositionWithMapObj(v)
                return {index = index, x = x, y = y, name = v.name, obj = v}
            end
        end
    end
    return {index = index, x = x, y = y, name = "empty"}
end
function AllianceLayer:AddMapObjectByIndex(index, mapObject, alliance)
    local alliance_object = self.alliance_objects[index]
    if alliance_object then
        if not alliance_object.mapObjects[mapObject.id] then
            local sprite = self:AddMapObject(alliance_object, mapObject, alliance)
            if sprite then
                self:RefreshSpriteInfo(sprite, mapObject, alliance)
            end
        end
    end
end
function AllianceLayer:RemoveMapObjectByIndex(index, mapObject)
    local alliance_object = self.alliance_objects[index]
    if alliance_object then
        if alliance_object.mapObjects[mapObject.id] then
            self:RemoveMapObject(alliance_object.mapObjects[mapObject.id])
            alliance_object.mapObjects[mapObject.id] = nil
        end
    end
end
function AllianceLayer:RefreshMapObjectByIndex(index, mapObject, alliance)
    local alliance_object = self.alliance_objects[index]
    if alliance_object then
        local sprite = alliance_object.mapObjects[mapObject.id]
        if sprite then
            self:RefreshMapObjectPosition(sprite, mapObject)
            self:RefreshSpriteInfo(sprite, mapObject, alliance)
        end
    end
end
function AllianceLayer:RefreshBuildingByIndex(index, building, alliance)
    local alliance_object = self.alliance_objects[index]
    if alliance_object then
        local sprite = alliance_object.buildings[building.name]
        if sprite then
            local x,y = self:GetBannerPos(index, sprite.x, sprite.y)
            sprite.info.level:setString(building.level)
            sprite.info:pos(x, y):zorder(x * y)
            if alliance and 
                alliance._id == Alliance_Manager:GetMyAlliance()._id then
                local door = sprite:getChildByTag(SPRITE_TAG).door
                local light = sprite:getChildByTag(SPRITE_TAG).light
                if building.name == "shrine" and door then
                    door:setVisible(#alliance.shrineEvents > 0)
                elseif building.name == "watchTower" and light then
                    light:setVisible(Alliance_Manager:HasToMyAllianceEvents())
                end
            end
        end
    end
end
function AllianceLayer:LoadAllianceByIndex(index, alliance)
    local allianceData = (alliance ~= nil and alliance ~= json.null) and alliance or nil
    local isMyAlliance = index == Alliance_Manager:GetMyAlliance().mapIndex
    self:FreeInvisible()
    self:LoadBackground(index, allianceData)
    self:LoadObjects(index, allianceData, function(objects_node)
        if allianceData then
            local map_obj_id = {}
            for k,v in pairs(allianceData.mapObjects) do
                map_obj_id[v.id] = true
            end
            for _,mapObj in pairs(allianceData.mapObjects) do
                local sprite = objects_node.mapObjects[mapObj.id]
                if not sprite then
                    sprite = self:AddMapObject(objects_node, mapObj, allianceData)
                end
                if sprite then
                    self:RefreshSpriteInfo(sprite, mapObj, allianceData)
                end
            end
            local mapObjects = objects_node.mapObjects
            for id,v in pairs(mapObjects) do
                if not map_obj_id[id] then
                    self:RemoveMapObject(v)
                    mapObjects[id] = nil
                end
            end
            for name,v in pairs(objects_node.buildings) do
                if name ~= "bloodSpring" then
                    local b = Alliance.FindAllianceBuildingInfoByName(allianceData, name)
                    v.info.level:setString(b.level)
                    local sprite = v:getChildByTag(SPRITE_TAG)
                    local size = sprite:getContentSize()
                    if name == "shrine" then
                        if not sprite.door and isMyAlliance then
                            sprite.door = ccs.Armature:create("chuansongmen")
                                          :addTo(sprite,0):pos(size.width/2, size.height/2)
                            sprite.door:getAnimation():playWithIndex(0)
                            sprite.door:setVisible(#allianceData.shrineEvents > 0)
                        end
                    elseif name == "watchTower" then
                        if not sprite.light and isMyAlliance then
                            sprite.light = ccs.Armature:create("shengdi")
                                           :addTo(sprite):pos(size.width/2, size.height/2)
                            local bone = sprite.light:getBone("Layer1")
                            bone:addDisplay(display.newNode(), 0)
                            bone:changeDisplayWithIndex(0, true)
                            sprite.light:setAnchorPoint(cc.p(0.5, 0.34))
                            sprite.light:getAnimation():playWithIndex(0)
                            sprite.light:setVisible(Alliance_Manager:HasToMyAllianceEvents())
                        end
                    end
                end
            end
        else
            if Alliance_Manager:getMapDataByIndex(index) then

            elseif not objects_node:getChildByTag(CLOUD_TAG) then
                self:CreateClouds():addTo(objects_node, 999999, CLOUD_TAG)
            end
        end
    end)
end
function AllianceLayer:RemoveMapObject(mapObj)
    if mapObj.info then
        mapObj.info:removeFromParent()
    end
    mapObj:removeFromParent()
end
function AllianceLayer:AddMapObject(objects_node, mapObj, alliance)
    local x,y = mapObj.location.x, mapObj.location.y
    local mapObject = objects_node.mapObjects[mapObj.id]
    local sprite
    if mapObj.name == "member" then
        sprite = createBuildingSprite("my_keep_1.png")
    elseif mapObj.name == "woodVillage"
        or mapObj.name == "stoneVillage"
        or mapObj.name == "ironVillage"
        or mapObj.name == "foodVillage"
        or mapObj.name == "coinVillage"
    then
        local info = Alliance.GetAllianceVillageInfosById(alliance, mapObj.id)
        local config = SpriteConfig[mapObj.name]:GetConfigByLevel(info.level)
        sprite = createBuildingSprite(config.png):scale(config.scale)
    elseif mapObj.name == "monster" then
        local info = Alliance.GetAllianceMonsterInfosById(alliance, mapObj.id)
        local corps = string.split(monsters[info.level].soldiers, ";")
        local soldiers = string.split(corps[info.index + 1], ",")
        sprite = UIKit:CreateMonster(soldiers[1])
    else
        return 
        -- print_(mapObj.name)
        --todo
        -- assert(false)
    end
    local node = display.newNode()
    sprite:addTo(node, 0, SPRITE_TAG)
    node.info = self:CreateInfoBanner()
    node.name = mapObj.name
    objects_node.mapObjects[mapObj.id] = node:addTo(objects_node)
    self:RefreshMapObjectPosition(node, mapObj)
    self:AddFuncToBuilding(node)
    return node
end
local function resetStatus(sprite)
    sprite:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
    sprite:unscheduleUpdate()
    sprite:clearFilter()
end
local function beginFlash(sprite, lastTime)
    sprite.time = 0
    sprite:setFilter(filter.newFilter("CUSTOM", json.encode({
        frag = "shaders/flash.fs",
        shaderName = "flash",
        ratio = math.fmod(sprite.time, lastTime) / lastTime,
    })))
    sprite:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        sprite.time = sprite.time + dt
        if sprite.time > lastTime then
            resetStatus(sprite)
        else
            sprite:getFilter()
            :getGLProgramState()
            :setUniformFloat("ratio", math.fmod(sprite.time, lastTime) / lastTime)
        end
    end)
    sprite:scheduleUpdate()
end
function AllianceLayer:AddFuncToBuilding(building)
    function building:Flash(time)
        self:ResetFlashStatus()
        self:BeginFlash(time)
    end
    function building:ResetFlashStatus()
        resetStatus(self:getChildByTag(SPRITE_TAG))
        if self.part then
            resetStatus(self.part)
        end
    end
    function building:BeginFlash(lastTime)
        beginFlash(self:getChildByTag(SPRITE_TAG), lastTime)
        if self.part then
            beginFlash(self.part, lastTime)
        end
    end
    return building
end
local flag_map = {
    [MINE] = {"village_flag_mine.png", "village_icon_mine.png"},
    [FRIEND] = {"village_flag_friend.png", "village_icon_friend.png"},
    [ENEMY] = {"village_flag_enemy.png", "village_icon_enemy.png"},
}
local FIRE_TAG = 11900
local SMOKE_TAG = 12000
local VILLAGE_TAG = 120990
function AllianceLayer:RefreshSpriteInfo(sprite, mapObj, alliance)
    local info = sprite.info
    local isenemy = User.allianceId ~= alliance._id
    local banners = isenemy and UILib.enemy_city_banner or UILib.my_city_banner
    if mapObj.name == "member" then
        local member = Alliance.GetMemberByMapObjectsId(alliance, mapObj.id)
        local config = SpriteConfig[isenemy and "other_keep" or "my_keep"]
            :GetConfigByLevel(member.keepLevel)
        sprite:getChildByTag(SPRITE_TAG):setTexture(config.png)

        info.banner:setTexture(banners[member.helpedByTroopsCount])
        info.level:setString(member.keepLevel)
        info.name:setString(string.format("[%s]%s", alliance.basicInfo.tag, member.name))

        if member.isProtected then
            if sprite:getChildByTag(SMOKE_TAG) then
                sprite:removeChildByTag(SMOKE_TAG)
            end
            if not sprite:getChildByTag(FIRE_TAG) then
                fire():addTo(sprite, 2, FIRE_TAG):pos(0,-50)
            end
        else
            if sprite:getChildByTag(FIRE_TAG) then
                sprite:removeChildByTag(FIRE_TAG)
            end
            local attackTime = (timer:GetServerTime() - member.lastBeAttackedTime / 1000)
            local is_smoke = attackTime < 10 * 60
            if is_smoke then
                if not sprite:getChildByTag(SMOKE_TAG) then
                    smoke_city():addTo(sprite, 2, SMOKE_TAG):pos(-20,-20)
                end
            else
                if sprite:getChildByTag(SMOKE_TAG) then
                    sprite:removeChildByTag(SMOKE_TAG)
                end
            end
        end
    elseif mapObj.name == "monster" then
        local banners = UILib.enemy_city_banner
        local monster = Alliance.GetAllianceMonsterInfosById(alliance, mapObj.id)
        local corps = string.split(monsters[monster.level].soldiers, ";")
        local soldiers = string.split(corps[monster.index + 1], ",")
        info.banner:setTexture("none_banner.png")
        info.level:setString(monster.level)
        info.name:setString(Localize.soldier_name[string.split(soldiers[1], '_')[1]])
    elseif mapObj.name == "woodVillage"
        or mapObj.name == "stoneVillage"
        or mapObj.name == "ironVillage"
        or mapObj.name == "foodVillage"
        or mapObj.name == "coinVillage" then
        local banner = "none_banner.png"
        local village = Alliance.GetAllianceVillageInfosById(alliance, mapObj.id)
        local event = Alliance_Manager:GetVillageEventsByMapId(alliance, mapObj.id)
        if event then
            local ally = ENEMY
            if UtilsForEvent:IsMyVillageEvent(event) then
                ally = MINE
                banner = UILib.my_city_banner[0]
            elseif UtilsForEvent:IsFriendEvent(event) then
                ally = FRIEND
                banner = UILib.my_city_banner[0]
            else
                banner = UILib.enemy_city_banner[0]
            end
            local flag = sprite:getChildByTag(VILLAGE_TAG)
            if sprite:getChildByTag(VILLAGE_TAG) then
                local head,circle = unpack(flag_map[ally])
                flag:setTexture(head)
                flag:getChildByTag(1):setTexture(circle)
            else
                self:CreateVillageFlag(ally)
                    :addTo(sprite,2,VILLAGE_TAG):pos(0, 150):scale(1.5)
            end
        elseif not event and sprite:getChildByTag(VILLAGE_TAG) then
            sprite:getChildByTag(VILLAGE_TAG):removeFromParent()
        end
        info.banner:setTexture(banner)
        info.level:setString(village.level)
        info.name:setString(Localize.village_name[mapObj.name])
    end
    local x,y = self:GetBannerPos(alliance.mapIndex, mapObj.location.x, mapObj.location.y)
    info:pos(x, y):zorder(x * y)
end
function AllianceLayer:GetBannerPos(mapIndex, x, y)
    local ax,ay = DataUtils:GetAbsolutePosition(mapIndex, x, y)
    local x,y = self:GetLogicMap():ConvertToMapPosition(ax, ay)
    return x, y - 50
end
function AllianceLayer:CreateInfoBanner(banners)
    local info = display.newNode():scale(0.8):addTo(self.info_node)
    local banners = banners or UILib.my_city_banner
    info.banner = display.newSprite(banners[0])
        :addTo(info):align(display.CENTER_TOP)
    info.level = UIKit:ttfLabel({
        text = "1",
        size = 22,
        color = 0xffedae,
    }):addTo(info.banner):align(display.CENTER, 30, 30)
    info.name = UIKit:ttfLabel({
        size = 20,
        color = 0xffedae,
    }):addTo(info.banner):align(display.LEFT_CENTER, 60, 32)
    return info
end
function AllianceLayer:CreateVillageFlag(e)
    local head,circle = unpack(flag_map[e])
    local flag = display.newSprite(head)
    flag:setAnchorPoint(cc.p(0.5, 0.62))
    local p = flag:getAnchorPointInPoints()
    display.newSprite(circle)
        :addTo(flag,0,1):pos(p.x, p.y)
        :runAction(
            cc.RepeatForever:create(transition.sequence{cc.RotateBy:create(2, -360)})
        )
    return flag
end
function AllianceLayer:RefreshMapObjectPosition(sprite, mapObject)
    local x,y = mapObject.location.x, mapObject.location.y
    sprite.x = x
    sprite.y = y
    sprite:zorder(getZorderByXY(x, y)):pos(self:GetInnerMapPosition(x, y))
end
function AllianceLayer:FreeInvisible()
    local background = self.background_node
    for k,v in pairs(self.alliance_bg) do
        local x,y = v:getPosition()
        local size = v:getContentSize()
        local left_bottom = background:convertToWorldSpace({x = x, y = y})
        local right_top = background:convertToWorldSpace({x = x + size.width, y = y + size.height})
        local r = cc.rect(left_bottom.x, left_bottom.y, right_top.x - left_bottom.x, right_top.y - left_bottom.y)
        local left_bottom_in = cc.rectContainsPoint(r, {x = 0, y = 0})
        local left_top_in = cc.rectContainsPoint(r, {x = 0, y = display.height})
        local right_bottom_in = cc.rectContainsPoint(r, {x = display.width, y = 0})
        local right_top_in = cc.rectContainsPoint(r, {x = display.width, y = display.height})
        if not left_bottom_in and not right_top_in and not left_top_in and not right_bottom_in then
            self:FreeBackground(self.alliance_bg[k])
            self.alliance_bg[k] = nil
            self:FreeObjects(self.alliance_objects[k])
            self.alliance_objects[k] = nil
        end
    end
end
local terrains = {
    [0] = "desert",
    "grassLand",
    "iceField",
}
function AllianceLayer:LoadObjects(index, alliance, func)
    local terrain, style = self:GetMapInfoByIndex(index, alliance)
    local alliance_obj = self.alliance_objects[index]
    if not alliance_obj then
        local isnomanland = not (Alliance_Manager:getMapDataByIndex(index))
        local new_obj = self:GetFreeObjects(terrain, style, index, alliance, isnomanland)
        self.alliance_objects[index] = new_obj:addTo(self.objects_node, index)
            :pos(
                self:GetAllianceLogicMap()
                    :ConvertToLeftBottomMapPosition(self:IndexToLogic(index))
            )
        -- new_obj:release()
        if type(func) == "function" then
            func(new_obj)
        end
    else
        if alliance and (alliance_obj.nomanland or alliance_obj.style ~= style) then
            self:FreeObjects(alliance_obj)
            self.alliance_objects[index] = nil
            return self:LoadObjects(index, alliance, func)
        elseif not alliance and not alliance_obj.nomanland then
            self:FreeObjects(alliance_obj)
            self.alliance_objects[index] = nil
            return self:LoadObjects(index, alliance, func)
        elseif alliance_obj.terrain ~= terrain then
            self:ReloadObjectsByTerrain(alliance_obj, terrain)
        end
        if type(func) == "function" then
            func(alliance_obj)
        end
    end
end
function AllianceLayer:FreeObjects(obj)
    if not obj then return end

    obj:removeChildByTag(CLOUD_TAG)

    if obj.nomanland then
        if obj:getParent() then
            obj:retain()
            obj:getParent():removeChild(obj, false)
        end
        table.insert(self.alliance_nomanland[obj.nomanland_style], obj)
        return
    end

    for k,v in pairs(obj.mapObjects) do
        self:RemoveMapObject(v)
    end

    for name,v in pairs(obj.buildings) do
        v.info:hide()
        local sprite = v:getChildByTag(SPRITE_TAG)
        if name == "shrine" then
            if v.door then
                v.door:removeFromParent()
                v.door = nil
            end
        elseif name == "watchTower" then
            if v.light then
                v.light:removeFromParent()
                v.light = nil
            end
        end
    end

    obj.mapObjects = {}
    if obj:getParent() then
        obj:retain()
        obj:getParent():removeChild(obj, false)
    end
    table.insert(self.alliance_objects_free[obj.style], obj)
end
function AllianceLayer:GetFreeObjects(terrain, style, index, alliance, isnomanland)
    if not alliance and isnomanland then
        local nomanland_style = (index % 1 + 1)
        local obj = table.remove(self.alliance_nomanland[nomanland_style], 1)
        if obj then
            if obj.terrain ~= terrain then
                self:ReloadObjectsByTerrain(obj, terrain)
            end
            return obj
        else
            local obj = display.newNode()
            self:CreateNoManLand(obj, terrain, index)
            obj.terrain = terrain
            obj.nomanland = true
            obj.nomanland_style = nomanland_style
            -- obj:retain()
            return obj
        end
    end

    local obj = table.remove(self.alliance_objects_free[style], 1)
    if obj then
        self:RefreshAllianceBuildings(obj, index)
        if obj.terrain ~= terrain then
            self:ReloadObjectsByTerrain(obj, terrain)
        end
        return obj
    else
        local obj = display.newNode()
        self:CreateAllianceObjects(obj, terrain, style, index, alliance)
        self:RefreshAllianceBuildings(obj, index)
        obj.mapObjects = {}
        obj.terrain = terrain
        obj.style = style
        -- obj:retain()
        return obj
    end
end
function AllianceLayer:RefreshAllianceBuildings(obj, index)
    local ismyaln = Alliance_Manager:GetMyAlliance().mapIndex == index
    local building_png = ismyaln and UILib.alliance_building
                      or UILib.other_alliance_building
    local banner = ismyaln and UILib.my_city_banner[0]
                or UILib.enemy_city_banner[0]
    for name,v in pairs(obj.buildings) do
        local x,y = self:GetBannerPos(index, v.x, v.y)
        v.info:show():pos(x, y):zorder(x * y)
        v.info.banner:setTexture(banner)
        v.info.name:setString(Localize.alliance_buildings[name])
        v:getChildByTag(SPRITE_TAG):setTexture(building_png[name])
    end
end
function AllianceLayer:ReloadObjectsByTerrain(obj_node, terrain)
    obj_node.terrain = terrain
    for k,v in pairs(obj_node.decorators) do
        if not v.is_ani then
            v:setTexture(decorator_image[terrain][v.name])
        end
    end
end
function AllianceLayer:CreateClouds()
    local node = display.newNode()
    for i = 1, 50 do
        self:CreateCloud():addTo(node):Run()
    end
    return node
end
function AllianceLayer:CreateCloud()
    local sprite = display.newSprite(string.format("cloud_%d.png", math.random(4)))
    function sprite:Run()
        local x = math.random(25 * TILE_WIDTH) + TILE_WIDTH
        local y = math.random(1 + (ALLIANCE_HEIGHT - 2) * TILE_WIDTH)
        local dis = ALLIANCE_WIDTH * TILE_WIDTH - x - TILE_WIDTH
        time = dis / (math.random(10) + 20)
        self:opacity(128):pos(x,y)
        self:runAction(cc.Spawn:create({
            transition.sequence{
                cc.MoveBy:create(time, cc.p(dis, 0)),
                cc.CallFunc:create(function()
                    self:Run()
                end)
            },
            transition.sequence{
                cc.FadeIn:create(time/4),
                cc.DelayTime:create(time * 2/4),
                cc.FadeTo:create(time/4,0)
            }}))
    end
    return sprite
end
local animap = {
    decorate_tree_7 = "lupai",
    decorate_tree_8 = "yewaiyindi",
    decorate_tree_9 = "zhihuishi",
}
function AllianceLayer:CreateAllianceObjects(obj_node, terrain, style, index, alliance)
    local decorators = {}
    local buildings = {}
    for _,v in ipairs(AllianceMap[string.format("allianceMap_%d", style)]) do
        local name = v.name
        local size = buildingName[name]
        local x,y = (2 * v.x - size.width + 1) / 2, (2 * v.y - size.height + 1) / 2
        local deco_png = decorator_image[terrain][name]
        local config_png = (index == Alliance_Manager:GetMyAlliance().mapIndex) and alliance_building or other_alliance_building
        local building_png = config_png[name]
        if animap[name] then
            local decorator = ccs.Armature:create(animap[name])
                                :addTo(obj_node, getZorderByXY(x, y))
                                :pos(self:GetInnerMapPosition(x,y))
            decorator:getAnimation():playWithIndex(0)
            decorator.x = v.x
            decorator.y = v.y
            decorator.name = name
            decorator.is_ani = true
            table.insert(decorators, decorator)
        elseif deco_png then
            local decorator = display.newSprite(deco_png)
                :addTo(obj_node, getZorderByXY(x, y))
                :pos(self:GetInnerMapPosition(x,y))
            decorator.x = v.x
            decorator.y = v.y
            decorator.name = name
            table.insert(decorators, decorator)
        elseif building_png then
            local node = display.newNode()
                :addTo(obj_node, getZorderByXY(x, y))
                :pos(self:GetInnerMapPosition(x,y))
            local sprite = createBuildingSprite(building_png)
                :addTo(node, 0, SPRITE_TAG)
            if name == "palace" then
                sprite:setAnchorPoint(cc.p(0.5, 0.4))
            elseif name == "orderHall" then
                sprite:setAnchorPoint(cc.p(0.5, 0.35))
            elseif name == "bloodSpring" then
                sprite:scale(0.7):setAnchorPoint(cc.p(0.5, 0.4))
                local size = sprite:getContentSize()
                ccs.Armature:create("longpengquan"):addTo(sprite)
                :pos(size.width/2, size.height/2):getAnimation():playWithIndex(0)
            elseif name == "shrine" then
                local size = sprite:getContentSize()
                node.part = createBuildingSprite("alliance_shrine_2.png")
                            :addTo(sprite, 1):pos(size.width/2, size.height/2)
            end
            node.x = v.x
            node.y = v.y
            node.name = name
            local x,y = self:GetBannerPos(index, v.x, v.y)
            node.info = self:CreateInfoBanner():pos(x, y):zorder(x * y)
            buildings[name] = node
            self:AddFuncToBuilding(node)
        else
            assert(false, name)
        end
    end
    obj_node.decorators = decorators
    obj_node.buildings = buildings
end
local NoManMap = GameDatas.NoManMap
function AllianceLayer:CreateNoManLand(obj_node, terrain, index)
    local decorators = {}
    local style = math.random(4)
    for _,v in ipairs(NoManMap[string.format("noManMap_%d", style)]) do
        local name = v.name
        local size = buildingName[name]
        if size then
            local x,y = (2 * v.x - size.width + 1) / 2, (2 * v.y - size.height + 1) / 2
            local deco_png = decorator_image[terrain][name]
            local building_png = alliance_building[name]
            if animap[name] then
                local decorator = ccs.Armature:create(animap[name])
                                    :addTo(obj_node, getZorderByXY(x, y))
                                    :pos(self:GetInnerMapPosition(x,y))
                decorator:getAnimation():playWithIndex(0)
                decorator.x = v.x
                decorator.y = v.y
                decorator.name = name
                decorator.is_ani = true
                table.insert(decorators, decorator)
            elseif deco_png then
                local decorator = display.newSprite(deco_png)
                    :addTo(obj_node, getZorderByXY(x, y))
                    :pos(self:GetInnerMapPosition(x,y))
                decorator.x = x
                decorator.y = y
                decorator.name = name
                table.insert(decorators, decorator)
            end
        end
    end
    ccs.Armature:create("daqizi")
    :addTo(obj_node, getZorderByXY(15,15))
    :pos(self:GetInnerMapPosition(15,15))
    :getAnimation():playWithIndex(0)

    obj_node.decorators = decorators
end
function AllianceLayer:GetInnerMapPosition(xOrPosition, y)
    if type(xOrPosition) == "table" then
        return self:GetInnerAllianceLogicMap():ConvertToMapPosition(xOrPosition.x, xOrPosition.y)
    end
    return self:GetInnerAllianceLogicMap():ConvertToMapPosition(xOrPosition, y)
end
function AllianceLayer:LoadBackground(index, alliance)
    local terrain = self:GetMapInfoByIndex(index, alliance)
    if not self.alliance_bg[index] then
        local new_bg = self:GetFreeBackground(terrain)
        self:FreeBackground(self.alliance_bg[index])
        local x,y = self:GetAllianceLogicMap()
                    :ConvertToLeftBottomMapPosition(self:IndexToLogic(index))
        self.alliance_bg[index] = new_bg:addTo(self.background_node, -index):pos(x,y)
        -- new_bg:release()
    elseif self.alliance_bg[index].terrain ~= terrain then
        self:FreeBackground(self.alliance_bg[index])
        self.alliance_bg[index] = nil
        self:LoadBackground(index, alliance)
    end
end
function AllianceLayer:GetRightDownTerrain(index)
    local right_terrain
    local down_terrain
    
    local x,y = self:IndexToLogic(index)
    if x + 1 >= 0 
   and x + 1 < bigMapLength_value 
   and y >= 0
   and y < bigMapLength_value
   then
        local mapIndex = self:LogicToIndex(x + 1, y)
        local aln = Alliance_Manager:GetAllianceByCache(mapIndex)
        right_terrain = self:GetMapInfoByIndex(mapIndex, aln)
    end

    if x >= 0 
   and x < bigMapLength_value 
   and y + 1 >= 0
   and y + 1 < bigMapLength_value
   then
        local mapIndex = self:LogicToIndex(x, y + 1)
        local aln = Alliance_Manager:GetAllianceByCache(mapIndex)
        down_terrain = self:GetMapInfoByIndex(mapIndex, aln)
    end

    return right_terrain, down_terrain
end
function AllianceLayer:FreeBackground(bg)
    if not bg then return end
    if bg:getParent() then
        bg:retain()
        table.insert(self.alliance_bg_free[bg.terrain], bg)
        bg:getParent():removeChild(bg, false)
    else
        table.insert(self.alliance_bg_free[bg.terrain], bg)
    end
end
local terrain_map = {
    grassLand = {
        "unlock_tile_surface_3_grassLand.png",
        "unlock_tile_surface_4_grassLand.png",
        "unlock_tile_surface_5_grassLand.png",
        "unlock_tile_surface_6_grassLand.png",
    },
    desert = {
        "005.png",
        "006.png",
        "007.png",
        "008.png",
    },
    iceField = {
        "unlock_tile_surface_4_iceField.png",
        "unlock_tile_surface_5_iceField.png",
        "unlock_tile_surface_6_iceField.png",
        "unlock_tile_surface_7_iceField.png",
    }
}
function AllianceLayer:GetFreeBackground(terrain)
    local bg = table.remove(self.alliance_bg_free[terrain], 1)
    if bg then
        return bg
    else
        local map
        if terrain == "grassLand" then
            map = self:CreateGrassLandBg()
        elseif terrain == "iceField" then
            map = self:CreateIceFieldBg()
        elseif terrain == "desert" then
            map = self:CreateDesertBg()
        else
            -- map = cc.TMXTiledMap:create(string.format("tmxmaps/alliance_%s1.tmx", terrain))
            -- local LEN = 115
            -- display.newSprite(string.format("%s_plus_right.png", terrain))
            --     :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, 0)
            -- for i = 0, 9 do
            --     display.newSprite(string.format("%s_plus_right.png", terrain))
            --         :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, i * 480 + 160)
            -- end
            -- for i = 0, 9 do
            --     display.newSprite(string.format("%s_plus_down.png", terrain))
            --         :addTo(map):align(display.LEFT_TOP, i * 480, LEN)
            -- end
            -- display.newSprite(string.format("%s_plus_down.png", terrain))
            --     :addTo(map):align(display.LEFT_TOP, 10 * 480 - 320, LEN)

            -- display.newSprite(string.format("%s_plus.png", terrain))
            --     :addTo(map):align(display.LEFT_TOP, map:getContentSize().width, 0)


            -- math.randomseed(12345)
            -- local random = math.random
            -- local array = terrain_map[terrain]
            -- if #array > 0 then
            --     local sx,sy,ex,ey = self.inner_alliance_logic_map:GetRegion()
            --     local span = 0
            --     for i = 1, 60 do
            --         local x = random(sx + span, ex - span)
            --         local y = random(sy + span, ey - span)
            --         display.newSprite(array[random(#array)]):addTo(map, 1000):pos(x, y)
            --     end
            -- end
        end
        self:LoadMiddleTerrain(map, terrain)
        -- map:retain()
        map.terrain = terrain
        return map
    end
end
local random = math.random
function AllianceLayer:LoadMiddleTerrain(map, terrain)
    math.randomseed(12345)
    local array = terrain_map[terrain]
    if #array > 0 then
        local sx,sy,ex,ey = self.inner_alliance_logic_map:GetRegion()
        local span = 0
        for i = 1, 60 do
            local x = random(sx + span, ex - span)
            local y = random(sy + span, ey - span)
            display.newSprite(array[random(#array)])
            :addTo(map, 1000):pos(x, y)
        end
    end
end
function AllianceLayer:CreateDesertBg()
    local terrain = "desert"
    local map = cc.TMXTiledMap:create(string.format("tmxmaps/alliance_%s1.tmx", terrain))
    local width = map:getContentSize().width
    local LEN = 160
    display.newSprite(string.format("plus_right_%s.png", terrain))
        :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, 0)
    for i = 0, 9 do
        display.newSprite(string.format("plus_right_%s.png", terrain))
            :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, i * 480 + 160)
    end
    local w = 0
    math.randomseed(737)
    while true do
        local index = math.random(2)
        local png = string.format("plus_down%d_%s.png", index, terrain)
        local sprite = display.newSprite(png):addTo(map)
        local size = sprite:getContentSize()
        local offset = (index == 1 and -10 or -10)
        local x = (index == 1 and 0 or 0)
        local y = (index == 1 and 5 or 10)
        sprite:align(display.LEFT_TOP, w + x, y)
        w = size.width + w + offset
        if w > width then
            break
        end
    end
    display.newSprite("plus_down1_desert.png"):addTo(map)
    :align(display.RIGHT_TOP, width, 20)
    return map
end
function AllianceLayer:CreateIceFieldBg()
    local terrain = "iceField"
    local map = cc.TMXTiledMap:create(string.format("tmxmaps/alliance_%s1.tmx", terrain))
    local width = map:getContentSize().width

    local LEN = 160
    display.newSprite(string.format("plus_right_%s.png", terrain))
        :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, 0)
    for i = 0, 9 do
        display.newSprite(string.format("plus_right_%s.png", terrain))
            :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, i * 480 + 160)
    end
    local w = 0
    math.randomseed(737)
    while true do
        local index = math.random(2)
        local png = string.format("plus_down%d_%s.png", index, terrain)
        local sprite = display.newSprite(png):addTo(map)
        local size = sprite:getContentSize()
        local offset = (index == 1 and -25 or -90)
        local x = (index == 1 and -5 or -5)
        local y = (index == 1 and 20 or 18)
        sprite:align(display.LEFT_TOP, w + x, y)
        w = size.width + w + offset
        if w > width then
            break
        end
    end
    display.newSprite("plus_down1_iceField.png"):addTo(map)
    :align(display.RIGHT_TOP, width, 20)
    return map
end
function AllianceLayer:CreateGrassLandBg()
    local terrain = "grassLand"
    local map = cc.TMXTiledMap:create(string.format("tmxmaps/alliance_%s1.tmx", terrain))
    local width = map:getContentSize().width

    local LEN = 160
    display.newSprite(string.format("plus_right_%s.png", terrain))
        :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, 0)
    for i = 0, 9 do
        display.newSprite(string.format("plus_right_%s.png", terrain))
            :addTo(map):align(display.LEFT_BOTTOM, map:getContentSize().width - LEN, i * 480 + 160)
    end
    local w = 0
    math.randomseed(737)
    while true do
        local index = math.random(2)
        local png = string.format("plus_down%d_grassLand.png", index)
        local sprite = display.newSprite(png):addTo(map)
        local size = sprite:getContentSize()
        local offset = (index == 1 and -40 or -60)
        local x = (index == 1 and -20 or -30)
        local y = (index == 1 and 30 or 38)
        sprite:align(display.LEFT_TOP, w + x, y)
        w = size.width + w + offset
        if w > width then
            break
        end
    end
    return map
end
function AllianceLayer:GetMapInfoByIndex(index, alliance)
    local terrain, style
    if (alliance == nil or alliance == json.null) then
        terrain, style = Alliance_Manager:getMapDataByIndex(index)
    else
        terrain, style = alliance.basicInfo.terrain, alliance.basicInfo.terrainStyle
    end
    terrain = terrain == nil and terrains[index % 3] or terrain
    style = style == nil and math.random(6) or style
    return terrain, style
end

local CLICK_EMPTY_TAG = 911
function AllianceLayer:PromiseOfFlashEmptyGround(mapIndex, x, y)
    self:RemoveClickNode()
    local point = self:RealPosition(mapIndex, x, y)
    local p = promise.new()
    display.newSprite("click_empty.png")
        :addTo(self.empty_node, 10000, CLICK_EMPTY_TAG)
        :pos(point.x, point.y):opacity(0)
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
function AllianceLayer:RemoveClickNode()
    self.empty_node:removeChildByTag(CLICK_EMPTY_TAG)
end
function AllianceLayer:TrackCorpsById(id)
    if self.track_id then
        self:RemoveCorpsCircle(self.map_corps[self.track_id])
    end
    self.track_id = id
    if self.track_id then
        self:AddToCorpsCircle(self.map_corps[self.track_id])
    end
end
local CIRCLE_TAG = 4356
function AllianceLayer:AddToCorpsCircle(corps)
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
function AllianceLayer:RemoveCorpsCircle(corps)
    if corps and corps:getChildByTag(CIRCLE_TAG) then
        corps:removeChildByTag(CIRCLE_TAG)
    end
end
--
function AllianceLayer:getContentSize()
    return worldsize
end


return AllianceLayer


