local IsoMapAnchorBottomLeft = import("..map.IsoMapAnchorBottomLeft")
local SpriteConfig = import("..sprites.SpriteConfig")
local UpgradingSprite = import("..sprites.UpgradingSprite")
local RuinSprite = import("..sprites.RuinSprite")
local TowerUpgradingSprite = import("..sprites.TowerUpgradingSprite")
local WallUpgradingSprite = import("..sprites.WallUpgradingSprite")
local RoadSprite = import("..sprites.RoadSprite")
local TileSprite = import("..sprites.TileSprite")
local TreeSprite = import("..sprites.TreeSprite")
local AirshipSprite = import("..sprites.AirshipSprite")
local FairGroundSprite = import("..sprites.FairGroundSprite")
local SingleTreeSprite = import("..sprites.SingleTreeSprite")
local BirdSprite = import("..sprites.BirdSprite")
local CitizenSprite = import("..sprites.CitizenSprite")
local SoldierSprite = import("..sprites.SoldierSprite")
local HelpedTroopsSprite = import("..sprites.HelpedTroopsSprite")
local SoldierManager = import("..entity.SoldierManager")
local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local Observer = import("..entity.Observer")
local MapLayer = import(".MapLayer")
local CityLayer = class("CityLayer", MapLayer)


local FunctionUpgradingSprite = import("..sprites.FunctionUpgradingSprite")
local BuildingSpriteRegister = setmetatable({
    warehouse       = import("..sprites.WareHouseSprite"),
    toolShop        = import("..sprites.ToolShopSprite"),
    blackSmith      = import("..sprites.BlackSmithSprite"),
    barracks        = import("..sprites.BarracksSprite"),
    dragonEyrie     = import("..sprites.DragonEyrieSprite"),
    hospital        = import("..sprites.HospitalSprite"),
    academy         = import("..sprites.AcademySprite"),
    townHall        = import("..sprites.TownHallSprite"),
    tradeGuild      = import("..sprites.TradeGuildSprite"),
    workshop        = import("..sprites.WorkShopSprite"),
}, {__index = function(t, k)
    return FunctionUpgradingSprite
end})



local floor = math.floor
local min = math.min
local random = math.random
local randomseed = math.randomseed
function CityLayer:GetClickedObject(world_x, world_y)
    local point = self:GetCityNode():convertToNodeSpace(cc.p(world_x, world_y))
    local logic_x, logic_y = self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)

    local clicked_helped_troops
    self:IteratorHelpedTroops(function(_, v)
        if v:isVisible() then
            local x, y = v:GetLogicPosition()
            if (logic_x == x and logic_y == y) or v:IsContainWorldPoint(world_x, world_y) then
                clicked_helped_troops = v
                return true
            end
        end
    end)
    if clicked_helped_troops then return clicked_helped_troops end

    local clicked_list = {
        logic_clicked = {},
        sprite_clicked = {}
    }
    self:IteratorClickAble(function(_, v)
        if v:isVisible() then
            local is_available = v:GetEntity():GetType() == "tower"
                or v:GetEntity():GetType() == "wall"
                or (v:GetEntity().IsUnlocked == nil and true or v:GetEntity():IsUnlocked())
            if is_available then
                local check = v:IsContainPointWithFullCheck(logic_x, logic_y, world_x, world_y)
                if check.logic_clicked then
                    table.insert(clicked_list.logic_clicked, v)
                end
                if check.sprite_clicked then
                    table.insert(clicked_list.sprite_clicked, v)
                end
            end
        end
    end)
    table.sort(clicked_list.logic_clicked, function(a, b)
        return a:getLocalZOrder() > b:getLocalZOrder()
    end)
    table.sort(clicked_list.sprite_clicked, function(a, b)
        return a:getLocalZOrder() > b:getLocalZOrder()
    end)
    if clicked_list.logic_clicked[1] then
        if clicked_list.logic_clicked[1]:GetEntity():GetType() == "wall" then
            clicked_list.logic_clicked[1] = self:GetCityGate()
        end
    end
    if clicked_list.sprite_clicked[1] then
        if clicked_list.sprite_clicked[1]:GetEntity():GetType() == "wall" then
            clicked_list.sprite_clicked[1] = self:GetCityGate()
        end
    end
    if self:IsEditMode() then
        local logic_clicked = clicked_list.logic_clicked
        while #logic_clicked > 0 do
            if logic_clicked[1]:GetEntity():IsHouse() or logic_clicked[1]:GetEntity():GetType() == "ruins" then
                break
            else
                table.remove(logic_clicked, 1)
            end
        end
        local sprite_clicked = clicked_list.sprite_clicked
        while #sprite_clicked > 0 do
            if sprite_clicked[1]:GetEntity():IsHouse() or sprite_clicked[1]:GetEntity():GetType() == "ruins" then
                break
            else
                table.remove(sprite_clicked, 1)
            end
        end
    end
    for _,v in ipairs(clicked_list.sprite_clicked) do
        print(v:GetEntity():GetType(), v:getLocalZOrder())
    end
    local building = clicked_list.logic_clicked[1] or clicked_list.sprite_clicked[1]
    if building then
        return building
    else
        local tile = self.scene:GetCity():GetTileByBuildingPosition(logic_x, logic_y)
        if tile and tile.location_id == 2 then
            return self.square
        end
    end
end
function CityLayer:OnTileLocked(city)
    self:OnTileChanged(city)
end
function CityLayer:OnTileUnlocked(city)
    self:OnTileChanged(city)
    print("OnTileUnlocked")
end
function CityLayer:OnTileChanged(city)
    self:UpdateRuinsVisibleWithCity(city)
    self:UpdateSingleTreeVisibleWithCity(city)
    self:UpdateAllDynamicWithCity(city)
end
function CityLayer:OnRoundUnlocked(round)
    print("OnRoundUnlocked", round)
end
function CityLayer:OnOccupyRuins(occupied_ruins)
    for _, occupy_ruin in pairs(occupied_ruins) do
        for _, ruin_sprite in pairs(self.ruins) do
            if occupy_ruin:IsSamePositionWith(ruin_sprite) then
                ruin_sprite:setVisible(false)
            end
        end
    end
end
function CityLayer:OnCreateDecorator(building)
    local city_node = self:GetCityNode()
    local house = self:CreateDecorator(building)
    city_node:addChild(house)
    table.insert(self.houses, house)

    -- self:NotifyObservers(function(listener)
    --     listener:OnCreateDecoratorSprite(house)
    -- end)
end
function CityLayer:OnDestoryDecorator(destory_decorator, release_ruins)
    for i, house in pairs(self.houses) do
        local x, y = house:GetLogicPosition()
        if destory_decorator:IsSamePositionWith(house) then
            -- self:NotifyObservers(function(listener)
            --     listener:OnDestoryDecoratorSprite(house)
            -- end)
            table.remove(self.houses, i):removeFromParent()
            break
        end
    end
    --
    for _, release_ruin in pairs(release_ruins) do
        for _, ruin_sprite in pairs(self.ruins) do
            if release_ruin:IsSamePositionWith(ruin_sprite) then
                ruin_sprite:setVisible(true)
            end
        end
    end
end
function CityLayer:OnSoliderStarCountChanged(soldier_manager, soldier_star_changed)
    self:UpdateSoldiersStar(soldier_manager, soldier_star_changed)
end
function CityLayer:OnSoliderCountChanged(soldier_manager, changed)
    self:UpdateSoldiersVisibleWithSoldierManager(soldier_manager)
end
function CityLayer:OnHelpedTroopsChanged(city)
    self:UpdateHelpedByTroopsVisible(city:GetHelpedByTroops())
end
-----
local SCENE_BACKGROUND = 1
local BACK_NODE = 2
local CITY_LAYER = 3
local SKY_LAYER = 4
local INFO_LAYER = 5
local CITY_BACKGROUND = 1
local ROAD_NODE = 2
local BUILDING_NODE = 3
local WEATHER_NODE = 4
function CityLayer:ctor(city_scene)
    Observer.extend(self)
    CityLayer.super.ctor(self, city_scene, 0.6, 1.5)
    self.scene = city_scene
    self.buildings = {}
    self.houses = {}
    self.towers = {}
    self.ruins = {}
    self.trees = {}
    self.tiles = {}
    self.walls = {}
    self.helpedByTroops = {}
    self.citizens = {}
    self:InitBackground()
    self:InitCity()
    self:InitWeather()
end
function CityLayer:GetLogicMap()
    return self.iso_map
end
function CityLayer:GetZOrderBy(sprite, x, y)
    local width, _ = self:GetLogicMap():GetSize()
    return (1 + width) * (x + y)
end
function CityLayer:ConvertLogicPositionToMapPosition(lx, ly)
    local map_pos = cc.p(self.iso_map:ConvertToMapPosition(lx, ly))
    return self:convertToNodeSpace(self:GetCityNode():convertToWorldSpace(map_pos))
end
function CityLayer:Terrain()
    return self.scene:GetCity():GetUser():Terrain()
end
--
function CityLayer:InitBackground()
    self:ReloadSceneBackground()
end
function CityLayer:InitCity()
    self.city_layer = display.newLayer():addTo(self, CITY_LAYER):align(display.BOTTOM_LEFT, 47, 158 + 250)
    self.sky_layer = display.newLayer():addTo(self, SKY_LAYER):align(display.BOTTOM_LEFT)
    self.info_layer = display.newLayer():addTo(self, INFO_LAYER):align(display.BOTTOM_LEFT)
    self.position_node = cc.TMXTiledMap:create("tmxmaps/city_road2.tmx"):addTo(self.city_layer):hide()
    self.city_node = display.newLayer():addTo(self.city_layer, BUILDING_NODE):align(display.BOTTOM_LEFT)
    local origin_point = self:GetPositionIndex(0, 0)
    self.iso_map = IsoMapAnchorBottomLeft.new({
        tile_w = 51,
        tile_h = 31,
        map_width = 50,
        map_height = 50,
        base_x = origin_point.x,
        base_y = origin_point.y
    })
end
function CityLayer:GetInfoLayer()
    return self.info_layer
end
function CityLayer:GetPositionIndex(x, y)
    return self:GetPositionLayer():getPositionAt(cc.p(x, y))
end
function CityLayer:GetPositionLayer()
    if not self.position_layer then
        self.position_layer = self.position_node:getLayer("layer1")
    end
    return self.position_layer
end
function CityLayer:GetCityNode()
    return self.city_node
end
function CityLayer:CheckCanUpgrade()
    self:IteratorCanUpgradingBuilding(function(_, sprite)
        sprite:CheckCondition()
    end)
end
--
function CityLayer:InitWeather()

end
function CityLayer:ChangeTerrain()
    self:ReloadSceneBackground()
    table.foreach(self.trees, function(_, v)
        v:ReloadSpriteCauseTerrainChanged()
    end)
    table.foreach(self.tiles, function(_, v)
        v:ReloadSpriteCauseTerrainChanged()
    end)
    table.foreach(self.single_tree, function(_, v)
        v:ReloadSpriteCauseTerrainChanged()
    end)
    table.foreach(self.buildings, function(_, v)
        v:ReloadSpriteCauseTerrainChanged()
    end)
    table.foreach(self.citizens, function(_, v)
        v:ReloadSpriteCauseTerrainChanged()
    end)
    -- if self.road then
    --     self.road:ReloadSpriteCauseTerrainChanged()
    -- end
end
--
function CityLayer:ReloadSceneBackground()
    if self.background then
        self.background:removeFromParent()
    end
    self.background = display.newNode():addTo(self, SCENE_BACKGROUND)
    local terrain = self:Terrain()
    local left_1 = string.format("left_background_1_%s.jpg", terrain)
    local left_2 = string.format("left_background_2_%s.jpg", terrain)
    local right_1 = string.format("right_background_1_%s.jpg", terrain)
    local right_2 = string.format("right_background_2_%s.jpg", terrain)
    local left1 = display.newSprite(left_1):addTo(self.background):align(display.LEFT_BOTTOM)
    -- local left2 = display.newSprite(left_2):addTo(self.background):align(display.LEFT_BOTTOM, 0, left1:getContentSize().height)
    local square = display.newSprite(left_2, nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(self.background)
        :align(display.LEFT_BOTTOM, 0, left1:getContentSize().height)
    local right1 = display.newSprite(right_1):addTo(self.background):align(display.LEFT_BOTTOM, square:getContentSize().width, 0)
    local right2 = display.newSprite(right_2):addTo(self.background):align(display.LEFT_BOTTOM, square:getContentSize().width, right1:getContentSize().height)

    function square:GetEntity()
        return {
            GetType = function()
                return "square"
            end,
            GetLogicPosition = function()
                return -1, -1
            end,
        }
    end
    function square:BeginFlash(time)
        local start = 0
        self:setFilter(filter.newFilter("CUSTOM", json.encode({
            frag = "shaders/flashAt.fs",
            shaderName = "flash1",
            startTime = start,
            curTime = start,
            lastTime = 0.5,
            rect = {0.815,0.543,0.21,0.26},
            srm = {1.0, 1.54, -45, 0.4},
        })))
        self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
            start = start + dt
            if start > time then
                self:ResetFlashStatus()
            else
                self:getFilter():getGLProgramState():setUniformFloat("curTime", start)
            end
        end)
        self:scheduleUpdate()
    end
    function square:Flash(time)
        self:ResetFlashStatus()
        self:BeginFlash(time)
    end
    function square:ResetFlashStatus()
        self:unscheduleUpdate()
        self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
        self:clearFilter()
    end
    self.square = square
end
function CityLayer:InitWithCity(city)
    city:AddListenOnType(self, city.LISTEN_TYPE.UNLOCK_TILE)
    city:AddListenOnType(self, city.LISTEN_TYPE.LOCK_TILE)
    city:AddListenOnType(self, city.LISTEN_TYPE.UNLOCK_ROUND)
    city:AddListenOnType(self, city.LISTEN_TYPE.OCCUPY_RUINS)
    city:AddListenOnType(self, city.LISTEN_TYPE.CREATE_DECORATOR)
    city:AddListenOnType(self, city.LISTEN_TYPE.DESTROY_DECORATOR)
    city:AddListenOnType(self, city.LISTEN_TYPE.HELPED_BY_TROOPS)
    city:GetSoldierManager():AddListenOnType(self, SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)

    local city_node = self:GetCityNode()
    -- 加废墟
    math.randomseed(123456789)
    for k, ruin in pairs(city.ruins) do
        local building = self:CreateRuin(ruin):addTo(city_node)
        local tile = city:GetTileWhichBuildingBelongs(ruin)
        if tile.locked or city:GetDecoratorByPosition(ruin.x, ruin.y) then
            building:setVisible(false)
        else
            building:setVisible(true)
        end
        table.insert(self.ruins, building)
    end

    -- 加功能建筑
    for _, building in pairs(city:GetAllBuildings()) do
        local building_sprite = self:CreateBuilding(building, city):addTo(city_node)
        city:AddListenOnType(building_sprite, city.LISTEN_TYPE.LOCK_TILE)
        city:AddListenOnType(building_sprite, city.LISTEN_TYPE.UNLOCK_TILE)
        city:AddListenOnType(building_sprite, city.LISTEN_TYPE.UPGRADE_BUILDING)
        table.insert(self.buildings, building_sprite)
    end

    -- 加小屋
    for _, house in pairs(city:GetAllDecorators()) do
        local house = self:CreateDecorator(house):addTo(city_node)
        table.insert(self.houses, house)
    end

    -- 加树
    randomseed(DataManager:getUserData().countInfo.registerTime)
    local single_tree = {}
    city:IteratorTilesByFunc(function(x, y, tile)
        if (x == 1 and y == 1)
            or (x == 2 and y == 1)
            or (x == 1 and y == 2)
            or x == 5 then
            return
        end
        local grounds = tile:RandomGrounds(random(123456789))
        for _, v in pairs(grounds) do
            local tree = self:CreateSingleTree(v.x, v.y):addTo(city_node)
            table.insert(single_tree, tree)
            tree:setVisible(tile:IsUnlocked())
        end
    end)
    self.single_tree = single_tree

    -- 兵种
    self:RefreshSoldiers(city:GetSoldierManager())


    -- 协防的部队
    local helpedByTroops = {}
    for i, v in ipairs({
        {x = 15, y = 55},
        {x = 35, y = 55},
    }) do
        table.insert(helpedByTroops, HelpedTroopsSprite.new(self, i, v.x, v.y):addTo(city_node))
    end
    self.helpedByTroops = helpedByTroops

    -- pve 入口
    self.pve_airship = self:CreateAirship(-9, 4):addTo(city_node)
    self.fair_ground = self:CreateFairGround(60, 45):addTo(city_node)


    -- 更新其他需要动态生成的建筑
    self:UpdateAllDynamicWithCity(city)
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        dt = min(dt, 0.05)
        for i, v in ipairs(self.citizens) do
            v:Update(dt)
        end
    end)
    self:scheduleUpdate()

    for i = 1,1 do
        self:CreateBird(0, 0):scale(0.8):addTo(self.sky_layer)
    end
end
---
function CityLayer:EnterEditMode()
    table.foreach(self.ruins, function(_, v)
        v:EnterEditMode()
    end)
end
function CityLayer:LeaveEditMode()
    table.foreach(self.ruins, function(_, v)
        v:LeaveEditMode()
    end)
end
function CityLayer:IsEditMode()
    local is_edit_mode = false
    table.foreach(self.ruins, function(_, v)
        if v:IsEditMode() then
            is_edit_mode = true
            return true
        end
    end)
    return is_edit_mode
end
function CityLayer:UpdateAllDynamicWithCity(city)
    -- self:UpdateLockedTilesWithCity(city)
    self:UpdateTilesWithCity(city)
    self:UpdateTreesWithCity(city)
    self:UpdateWallsWithCity(city)
    self:UpdateSoldiersVisibleWithSoldierManager(city:GetSoldierManager())
    self:UpdateHelpedByTroopsVisible(city:GetHelpedByTroops())
    self:UpdateCitizen(city)
end
function CityLayer:UpdateRuinsVisibleWithCity(city)
    table.foreach(self.ruins, function(_, ruin)
        local building_entity = ruin:GetEntity()
        local tile = city:GetTileWhichBuildingBelongs(building_entity)
        if tile.locked or city:GetDecoratorByPosition(building_entity:GetLogicPosition()) then
            ruin:setVisible(false)
        else
            ruin:setVisible(true)
        end
    end)
end
function CityLayer:UpdateSingleTreeVisibleWithCity(city)
    table.foreach(self.single_tree, function(_, tree)
        tree:setVisible(city:GetTileByBuildingPosition(tree.x, tree.y):IsUnlocked())
    end)
end
-- function CityLayer:UpdateLockedTilesWithCity(city)
--     local city_node = self:GetCityNode()
--     for _, v in pairs(self.locked_tiles) do
--         v:removeFromParent()
--     end
--     self.locked_tiles = {}
--     city:IteratorTilesByFunc(function(x, y, tile)
--         local building = city:GetBuildingByLocationId(tile.location_id)
--         if tile:NeedWalls() and tile.locked and not building:IsUnlocking() then
--             table.insert(self.locked_tiles, self:CreateLockedTileSpriteWithTile(tile):addTo(city_node))
--         end
--     end)
-- end
function CityLayer:UpdateTilesWithCity(city)
    local city_node = self:GetCityNode()
    for _, v in pairs(self.tiles) do
        v:removeFromParent()
    end
    self.tiles = {}
    math.randomseed(123456789)
    city:IteratorTilesByFunc(function(x, y, tile)
        if tile.locked or (tile.x == 2 and tile.y == 5) then
            table.insert(self.tiles, self:CreateTileWithTile(tile):addTo(city_node))
        end
    end)
    self:NotifyObservers(function(listener)
        listener:OnTilesChanged(self.tiles)
    end)
end
function CityLayer:UpdateTreesWithCity(city)
    local city_node = self:GetCityNode()
    for k, v in pairs(self.trees) do
        v:removeFromParent()
    end
    self.trees = {}
    math.randomseed(123456789)
    city:IteratorTilesByFunc(function(x, y, tile)
        if tile:IsOutOfWalls() and tile.x ~= 2 then
            table.insert(self.trees, self:CreateTreeWithTile(tile):addTo(city_node))
        end
    end)
end
function CityLayer:UpdateWallsWithCity(city)
    local city_node = self:GetCityNode()
    local old_walls = self.walls
    local new_walls = {}
    local _, level = SpriteConfig["wall"]:GetConfigByLevel(city:GetGate():GetLevel())
    for _, v in pairs(city:GetWalls()) do
        table.insert(new_walls, self:CreateWall(v, level):addTo(city_node))
    end
    self.walls = new_walls

    -- self:NotifyObservers(function(listener)
    --     listener:OnGateChanged(old_walls, new_walls)
    -- end)

    for _, v in pairs(old_walls) do
        v:DestorySelf()
    end
    self:UpdateTowersWithCity(city)
end
function CityLayer:UpdateTowersWithCity(city)
    local city_node = self:GetCityNode()
    local old_towers = self.towers
    local new_towers = {}
    local _, level = SpriteConfig["wall"]:GetConfigByLevel(city:GetGate():GetLevel())
    for k, v in pairs(city:GetVisibleTowers()) do
        table.insert(new_towers, self:CreateTower(v, level):addTo(city_node))
    end
    self.towers = new_towers

    -- self:NotifyObservers(function(listener)
    --     listener:OnTowersChanged(old_towers, new_towers)
    -- end)

    for k, v in pairs(old_towers) do
        v:DestorySelf()
    end
end
function CityLayer:UpdateSoldiersVisibleWithSoldierManager(soldier_manager)
    local map = soldier_manager:GetSoldierMap()
    self:IteratorSoldiers(function(_, v)
        local type_, star = v:GetSoldierTypeAndStar()
        local is_visible = map[type_] > 0
        v:setVisible(is_visible)
    end)
end
function CityLayer:UpdateSoldiersStar(soldier_manager)
    local need_refresh = false
    self:IteratorSoldiers(function(_, v)
        local type_, star_old = v:GetSoldierTypeAndStar()
        local star_now = soldier_manager:GetStarBySoldierType(type_)
        if star_now ~= star_old then
            need_refresh = true
        end
    end)
    if need_refresh then
        self:RefreshSoldiers(soldier_manager)
    end
end
function CityLayer:RefreshSoldiers(soldier_manager)
    for _,v in pairs(self.soldiers or {}) do
        v:removeFromParent()
    end
    local soldiers = {}
    for i, v in ipairs({
        {x = 6, y = 18, soldier_type = "skeletonWarrior", scale = 1},
        {x = 4, y = 18, soldier_type = "skeletonArcher", scale = 1},
        {x = 8, y = 18, soldier_type = "deathKnight", scale = 1},
        {x = 2, y = 18, soldier_type = "meatWagon", scale = 1},

        {x = 8, y = 15.5, soldier_type = "lancer", scale = 1},
        {x = 6, y = 15.5, soldier_type = "swordsman", scale = 1},
        {x = 4, y = 15.5, soldier_type = "ranger", scale = 1},
        {x = 2, y = 15.5, soldier_type = "catapult", scale = 0.8},

        {x = 8, y = 13, soldier_type = "horseArcher", scale = 1},
        {x = 6, y = 13, soldier_type = "sentinel", scale = 1},
        {x = 4, y = 13, soldier_type = "crossbowman", scale = 1},
        {x = 2, y = 13, soldier_type = "ballista", scale = 0.8},
    }) do
        local star = soldier_manager:GetStarBySoldierType(v.soldier_type)
        local soldier = self:CreateSoldier(v.soldier_type, star, v.x, v.y):addTo(self:GetCityNode())
        local x, y = soldier:getPosition()
        soldier:pos(x, y + 25):scale(v.scale)
        table.insert(soldiers, soldier)
    end
    self.soldiers = soldiers

    self:UpdateSoldiersVisibleWithSoldierManager(soldier_manager)
end
function CityLayer:UpdateHelpedByTroopsVisible(helped_by_troops)
    self:IteratorHelpedTroops(function(i, v)
        v:setVisible(helped_by_troops[i] ~= nil)
    end)
end
function CityLayer:IteratorHelpedTroops(func)
    table.foreach(self.helpedByTroops, func)
end
function CityLayer:UpdateCitizen(city)
    local count = 0
    city:IteratorTilesByFunc(function(x, y, tile)
        if tile:IsConnected() then
            count = count + 1
        end
    end)
    for i = #self.citizens + 1, count do
        table.insert(self.citizens, self:CreateCitizen(city, 0, 0):addTo(self:GetCityNode()))
    end
end
-- promise
function CityLayer:FindBuildingBy(x, y)
    local building
    self:IteratorClickAble(function(_, v)
        local x_, y_ = v:GetLogicPosition()
        if x_ == x and y_ == y then
            building = v
            return true
        end
    end)
    assert(building, "没有找到建筑")
    return cocos_promise.defer(function()
        return building
    end)
end
function CityLayer:IteratorFunctionsBuildings(func)
    table.foreach(self.buildings, func)
end
function CityLayer:IteratorDecoratorBuildings(func)
    table.foreach(self.houses, func)
end
function CityLayer:IteratorFunctionsBuildings(func)
    table.foreach(self.buildings, func)
end
function CityLayer:IteratorSoldiers(func)
    table.foreach(self.soldiers, func)
end
function CityLayer:IteratorInnnerBuildings(func)
    local handle = false
    local handle_func = function(k, v)
        if func(k, v) then
            handle = true
            return true
        end
    end
    repeat
        table.foreach(self.buildings, handle_func)
        if handle then break end
        table.foreach(self.houses, handle_func)
    until true
end
function CityLayer:IteratorCanUpgradingBuilding(func)
    for k,v in pairs(self.buildings) do
        if func(k, v) then
            return
        end
    end
    for k,v in pairs(self.houses) do
        if func(k, v) then
            return
        end
    end
    for k,v in pairs(self.towers) do
        if func(k, v) then
            return
        end
    end
    for k,v in pairs(self.walls) do
        if v:GetEntity():IsGate() and func(k, v) then
            return
        end
    end
end
function CityLayer:FindBuildingSpriteByBuilding(buildingEntity,city)
    local find_sprite
    table.foreach(self.buildings, function(k, building)
        if building:GetEntity()==buildingEntity then
            find_sprite = building
            return true
        end
    end)
    if find_sprite then return find_sprite end
    table.foreach(self.houses, function(k, house)
        if house:GetEntity() == buildingEntity then
            find_sprite = house
            return true
        end
    end)
    if find_sprite then return find_sprite end
    table.foreach(self.ruins, function(k, ruin)
        if ruin:GetEntity() == buildingEntity then
            find_sprite = ruin
            return true
        end
    end)
    if find_sprite then return find_sprite end
    local near_tower = city:GetNearGateTower()
    if  near_tower == buildingEntity then
        table.foreach(self.towers, function(k, tower)
            if tower:GetEntity()==near_tower then
                find_sprite = tower
                return true
            end
        end)
    end
    if find_sprite then return find_sprite end
    table.foreach(self.walls, function(k, wall)
        if wall:GetEntity()==buildingEntity then
            find_sprite = wall
            return true
        end
    end)
    if find_sprite then return find_sprite end
end
function CityLayer:IteratorClickAble(func)
    local handle = false
    local handle_func = function(k, v)
        if func(k, v) then
            handle = true
            return true
        end
    end
    repeat
        table.foreach(self.buildings, handle_func)
        if handle then break end
        table.foreach(self.houses, handle_func)
        if handle then break end
        table.foreach(self.towers, handle_func)
        if handle then break end
        table.foreach(self.walls, handle_func)
        if handle then break end
        table.foreach(self.ruins, handle_func)
        if handle then break end
        if self.pve_airship then
            handle_func(nil, self.pve_airship)
        end
        if self.fair_ground then
            handle_func(nil, self.fair_ground)
        end
    until true
end
function CityLayer:IteratorRuins(func)
    table.foreach(self.ruins, func)
end
function CityLayer:GetCityGate()
    local gate
    table.foreach(self.walls, function(_, v)
        if v:GetEntity():IsGate() then
            gate = v
            return true
        end
    end)
    return gate
end
function CityLayer:GetWalls()
    return self.walls
end
function CityLayer:GetTowers()
    return self.towers
end
function CityLayer:CreateRoadWithTile(tile)
    local x, y = self.iso_map:ConvertToMapPosition(tile:GetMidLogicPosition())
    return RoadSprite.new(self, tile, x, y)
end
function CityLayer:CreateTileWithTile(tile)
    local x, y = self.iso_map:ConvertToMapPosition(tile:GetMidLogicPosition())
    return TileSprite.new(self, tile, x, y)
end
function CityLayer:CreateTreeWithTile(tile)
    local x, y = self.iso_map:ConvertToMapPosition(tile:GetMidLogicPosition())
    return TreeSprite.new(self, tile, x, y)
end
function CityLayer:CreateWall(wall, level)
    return WallUpgradingSprite.new(self, wall, level)
end
function CityLayer:CreateTower(tower, level)
    return TowerUpgradingSprite.new(self, tower, level)
end
function CityLayer:CreateRuin(ruin)
    return RuinSprite.new(self, ruin)
end
function CityLayer:CreateDecorator(house)
    return UpgradingSprite.new(self, house)
end
function CityLayer:CreateBuilding(building, city)
    return BuildingSpriteRegister[building:GetType()].new(self, building, city)
end
function CityLayer:CreateSingleTree(logic_x, logic_y)
    return SingleTreeSprite.new(self, logic_x, logic_y)
end
function CityLayer:CreateBird(city, x, y)
    return BirdSprite.new(self, city, x, y)
end
function CityLayer:CreateCitizen(city, logic_x, logic_y)
    return CitizenSprite.new(self, city, logic_x, logic_y)
end
function CityLayer:CreateSoldier(soldier_type, star, logic_x, logic_y)
    return SoldierSprite.new(self, soldier_type, star, logic_x, logic_y)
end
function CityLayer:CreateAirship(logic_x, logic_y)
    return AirshipSprite.new(self, logic_x, logic_y)
end
function CityLayer:CreateFairGround(logic_x, logic_y)
    return FairGroundSprite.new(self, logic_x, logic_y)
end

----- override
function CityLayer:getContentSize()
    if not self.content_size then
        self.content_size = self.background:getCascadeBoundingBox()
    end
    return self.content_size
end
function CityLayer:UpdateWeather()
    local size = self:getContentSize()
    local pos = self:convertToNodeSpace(cc.p(display.cx, display.cy))
    self.weather_glstate:setUniformVec2("u_position", {x = pos.x / size.width, y = pos.y / size.height})
end
function CityLayer:HideLevelUpNode()
    self:IteratorCanUpgradingBuilding(function(_, sprite)
        sprite:HideLevelUpNode()
    end)
end
function CityLayer:ShowLevelUpNode()
    self:IteratorCanUpgradingBuilding(function(_, sprite)
        sprite:ShowLevelUpNode()
    end)
end

return CityLayer








