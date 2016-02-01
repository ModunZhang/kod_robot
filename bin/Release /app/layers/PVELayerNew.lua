local pvemap = import("..map.pvemap")
local NormalMapAnchorBottomLeftReverseY = import("..map.NormalMapAnchorBottomLeftReverseY")
local PveSprite = import("..sprites.PveSprite")
local MapLayer = import(".MapLayer")
local PVELayerNew = class("PVELayerNew", MapLayer)



local map = {
    {"image", "pve_deco_1.png",3,3,1},
    {"image", "pve_deco_2.png",3,2,1},
    {"image", "pve_deco_3.png",3,2,1},
    {"image", "pve_deco_4.png",2,2,0.9},
    {"image", "pve_deco_5.png",1,1,0.9},
    {"image", "pve_deco_6.png",1,1,1},
    {"image", "pve_deco_7.png",1,1,1},
    {"image", "pve_deco_8.png",1,1,1},
    {"image", "pve_deco_9.png",1,1,1},
    {"image", "pve_deco_10.png",1,1,1},
    {"image", "pve_deco_11.png",1,1,1},
    {"image", "pve_deco_12.png",1,1,1},
    {"image", "pve_deco_13.png",1,1,1},
    {"image", "pve_deco_14.png",1,1,1},
    {"image", "pve_deco_15.png",1,1,1},
    {"image", "pve_deco_16.png",1,1,1},
    {"image", "pve_deco_17.png",1,1,1},
}

local pve_color = {
    cc.c3b(  0,   0,   0),
    cc.c3b(192, 207, 186),
    cc.c3b(164, 176, 143),
    cc.c3b(  0,   0,   0),
    cc.c3b(  0,   0,   0),

    cc.c3b(184, 184, 184),
    cc.c3b(212, 189, 172),
    cc.c3b(191, 163, 163),
    cc.c3b(158, 125, 126),
    cc.c3b(197, 201, 160),

    cc.c3b(201, 180, 160),
    cc.c3b(201, 172, 160),
    UIKit:hex2c3b(0xd1b7a7),
    UIKit:hex2c3b(0xd6afa3),
    UIKit:hex2c3b(0xcfa395),

    UIKit:hex2c3b(0xa6acc7),
    UIKit:hex2c3b(0x909ac7),
    UIKit:hex2c3b(0x7583bd),
    cc.c3b(166, 182, 186),
    cc.c3b(131, 142, 150),

    UIKit:hex2c3b(0x8c787e),
    UIKit:hex2c3b(0x937ea3),
    UIKit:hex2c3b(0x9a83ab),
    UIKit:hex2c3b(0xaa7db0),
}


local function bezierat(a,b,c,d,t)
    return (math.pow(1-t,3) * a +
        3*t*(math.pow(1-t,2))*b +
        3*math.pow(t,2)*(1-t)*c +
        math.pow(t,3)*d)
end

local function linerat(a,b,t)
    return a + (b - a) * t
end


function PVELayerNew:ctor(scene, user, level)
    PVELayerNew.super.ctor(self, scene, 0.5, 1.5)
    local pvemap = pvemap[level]
    self.user = user
    self.level = level
    self.normal_map = NormalMapAnchorBottomLeftReverseY.new({
        tile_w = pvemap.tilewidth,
        tile_h = pvemap.tileheight,
        map_width = pvemap.width,
        map_height = pvemap.height,
        base_x = 0,
        base_y = pvemap.height * pvemap.tileheight,
    })

    local color = pve_color[self.level]
    local suffix = device.platform == "winrt" and "png" or "jpg"
    local img = string.format("pve_background.%s", suffix)
    GameUtils:LoadImagesWithFormat(function()
        self.background = display.newNode():addTo(self)
        for i = 1, 4 do
            local bg = display.newSprite(img)
            :addTo(self.background)
            :align(display.LEFT_BOTTOM, 0, (i-1) * 800)
            bg:setColor(color + cc.c3b(bg:getColor()))
        end
    end, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565)
    setAliasTexParametersForKey(img)

    self.cloud_layer = display.newNode():addTo(self, 100)

    for i = 1, 3 do
        display.newSprite(string.format("pve_cloud_%d.png", i % 2 + 1)):addTo(self.cloud_layer)
        :opacity(180):runAction(cc.RepeatForever:create(transition.sequence{
            cc.MoveTo:create(0, cc.p(1000, self:getContentSize().height*i/4)),
            cc.MoveTo:create(10, cc.p(-1000, self:getContentSize().height*i/4)),
            cc.DelayTime:create(math.random(10, 20)),
        }))
    end
    self.fte_layer = display.newNode():addTo(self, 10)


    self.roads = {}
    self.seq_npc = {}
    assert(#pvemap.layers[2].objects == 1)
    for i,v in ipairs(pvemap.layers[2].objects) do
        local lines = {}
        for i,line in ipairs(v.polyline) do
            local lx,ly = math.floor((line.x + v.x - 1)/80), math.floor((line.y + v.y - 1)/80)
            local x,y = self.normal_map:ConvertToMapPosition(lx,ly)
            table.insert(lines, {x = x, y = y})
            table.insert(self.seq_npc, {x = lx, y = ly})
        end
        while #lines >= 2 do
            local dx,dy = math.abs(lines[2].x - lines[1].x), math.abs(lines[2].y - lines[1].y)
            local f = 100
            local ux1,uy1,ux2,uy2
            if dy / dx <= 1 then
                ux1 = linerat(lines[1].x, lines[2].x, 0.33)
                uy1 = linerat(lines[1].y, lines[2].y, 0.33) + math.random(f) - f*0.5

                ux2 = linerat(lines[1].x, lines[2].x, 0.66)
                uy2 = linerat(lines[1].y, lines[2].y, 0.66) + math.random(f) - f*0.5
            else
                ux1 = linerat(lines[1].x, lines[2].x, 0.33) + math.random(f) - f*0.5
                uy1 = linerat(lines[1].y, lines[2].y, 0.33)

                ux2 = linerat(lines[1].x, lines[2].x, 0.66) + math.random(f) - f*0.5
                uy2 = linerat(lines[1].y, lines[2].y, 0.66)
            end
            local g = math.ceil(math.sqrt((lines[2].x - lines[1].x)^2 + (lines[2].y - lines[1].y)^2) / 30)
            local roads = {}
            for i = 1, g - 1 do
                local x = bezierat(lines[1].x, ux1, ux2, lines[2].x, i * 1/g)
                local y = bezierat(lines[1].y, uy1, uy2, lines[2].y, i * 1/g)
                local nx = bezierat(lines[1].x, ux1, ux2, lines[2].x, i * 1/g + 0.1)
                local ny = bezierat(lines[1].y, uy1, uy2, lines[2].y, i * 1/g + 0.1)
                local road = display.newNode():addTo(self):pos(x,y):scale(0.8)
                    :rotation(-math.deg(cc.pGetAngle({x = 0, y = 1}, {x = nx - x, y = ny - y})))
                local r = display.newSprite("pve_road_point2.png"):addTo(road)
                local r1 = display.newSprite("pve_road_point.png"):addTo(road)
                r:setColor(color + cc.c3b(r:getColor()))
                r1:setColor(color + cc.c3b(r1:getColor()))
                table.insert(roads, r1)
            end
            self.roads[#self.roads + 1] = roads
            table.remove(lines, 1)
        end
    end


    self.npcs = {}
    local data = pvemap.layers[1].data
    for ly = 1, pvemap.height do
        for lx = 1, pvemap.width do
            local index = (ly-1) * pvemap.width + lx
            local gid = data[index]
            if map[gid] then
                local type,png,w,h,s = unpack(map[gid])
                local obj
                if gid == 15 or gid == 16 or gid == 14 then
                    obj = PveSprite.new(self, string.format("%d_%d", level, self:GetNpcIndex(lx - 1, ly - 1)), lx - 1, ly - 1, gid)
                elseif type == "image" then
                    obj = display.newSprite(png)
                    obj:setColor(color + cc.c3b(obj:getColor()))
                end
                local x,y = self.normal_map:ConvertToMapPosition(lx - 1, ly - 1)
                local ox,oy = self.normal_map:ConvertToLocalPosition((w - 1)/2, (h - 1)/2)
                obj:addTo(self):pos(x+ox, y+oy):scale(s)

                if gid == 15 or gid == 16 or gid == 14 then
                    self:RegisterNpc(obj, lx - 1, ly - 1)
                end
            end
        end
    end

    if not self.user:IsStagePassed(self.level) then
        local airship = display.newSprite("airship.png"):addTo(self):scale(0.5)
        airship:setAnchorPoint(cc.p(0.4, 0.6))
        airship:runAction(cc.RepeatForever:create(transition.sequence{
            cc.MoveBy:create(2, cc.p(0, 5)),
            cc.MoveBy:create(2, cc.p(0, -5))
        }))
        self.airship = airship

        local armature = ccs.Armature:create("feiting"):addTo(airship)
        local p = airship:getAnchorPointInPoints()
        armature:align(display.CENTER, p.x + 10, p.y):getAnimation():playWithIndex(0)
        armature:getAnimation():setSpeedScale(2)


        airship.battery = display.newSprite("battery_bg.png"):addTo(airship):pos(130, 235)
        local x,y = 14, 18
        for i = 1, 5 do
            display.newSprite("battery_cell.png")
                :addTo(airship.battery,0,i):pos((i-1) * 7 + x, (i-1) * 4 + y)
                :runAction(cc.RepeatForever:create(transition.sequence{
                    cc.TintTo:create(0.7, 0, 0, 0),
                    cc.TintTo:create(0.7, 200, 200, 200)
                }))
            display.newSprite("battery_cell.png")
                :addTo(airship.battery,0, 5 + i):pos((i-1) * 7 + x, (i-1) * 4 + y)
        end
    end
end
function PVELayerNew:ConvertLogicPositionToMapPosition(lx, ly)
    return self:convertToNodeSpace(self.background:convertToWorldSpace(cc.p(self.normal_map:ConvertToMapPosition(lx, ly))))
end
function PVELayerNew:GetZOrderBy(sprite, x, y)
    return 0
end
function PVELayerNew:GetLogicMap()
    return self.normal_map
end
function PVELayerNew:GetClickedObject(world_x, world_y)
    local point = self.background:convertToNodeSpace(cc.p(world_x, world_y))
    local logic_x, logic_y = self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
    local npc = self:GetNpcBy(logic_x, logic_y)
    for _,v in pairs(self.npcs) do
        if v:IsContainWorldPoint(world_x, world_y) then
            npc = v
        end
    end
    if npc and self.user:IsPveNameEnable(npc:GetPveName()) then
        return npc
    end
end
function PVELayerNew:GotoPve()
    local find,x,y
    for i,v in ipairs(self.seq_npc) do
        local npc = self:GetNpcBy(v.x, v.y)
        if self.user:IsPveNameEnable(npc:GetPveName()) then
            find,x,y = npc,v.x,v.y
        else
            break
        end
    end
    local point
    if find then
        point = self:ConvertLogicPositionToMapPosition(4.5,y)
    else
        point = self:ConvertLogicPositionToMapPosition(4.5,0)
    end
    self:GotoMapPositionInMiddle(point.x, point.y)

    self:RefreshPve()
    self:MoveAirship()
    scheduleAt(self, function()
        self:RefreshBattery()
    end)
end
function PVELayerNew:RegisterNpc(obj,X,Y)
    local w,h = self.normal_map:GetSize()
    self.npcs[string.format("%d_%d", X, Y)] = obj
end
function PVELayerNew:GetNpcBy(X, Y)
    local w,h = self.normal_map:GetSize()
    return self.npcs[string.format("%d_%d", X, Y)]
end
function PVELayerNew:GetNpcIndex(X,Y)
    for i,v in ipairs(self.seq_npc) do
        if v.x == X and v.y == Y then
            return i
        end
    end
end
function PVELayerNew:GetNpcByIndex(index)
    local v = self.seq_npc[index]
    return self:GetNpcBy(v.x, v.y)
end
function PVELayerNew:RefreshPve()
    local index = 0
    for i,v in ipairs(self.seq_npc) do
        local v = self.seq_npc[i]
        if self.user:IsPveNameEnable(self:GetNpcBy(v.x, v.y):GetPveName()) then
            index = i
        else
            break
        end
    end
    for i = 1, index do
        for _,road in ipairs(self.roads[i] or {}) do
            road:show()
        end
    end
    for i = index, #self.roads do
        for _,road in ipairs(self.roads[i] or {}) do
            road:hide()
        end
    end

    for i = 1, #self.seq_npc do
        local be = self.seq_npc[i - 1]
        local v = self.seq_npc[i]
        self:GetNpcBy(v.x, v.y)
            :SetStars(self.user:GetPveSectionStarByName(self:GetNpcBy(v.x, v.y):GetPveName()))
        if be then
            if self.user:GetPveSectionStarByName(self:GetNpcBy(be.x, be.y):GetPveName()) > 0 then
                self:GetNpcBy(v.x, v.y):SetEnable(true)
            else
                self:GetNpcBy(v.x, v.y):SetEnable(false)
            end
        else
            self:GetNpcBy(v.x, v.y):SetEnable(true)
        end
    end
end
function PVELayerNew:MoveAirship(ani)
    local target, map_y
    for i = 1, #self.seq_npc do
        local be = self.seq_npc[i - 1]
        local v = self.seq_npc[i]
        if be then
            if self.user:GetPveSectionStarByName(self:GetNpcBy(be.x, be.y):GetPveName()) > 0 then
                target = self:GetNpcBy(v.x, v.y)
                map_y = v.y
            end
        else
            target = self:GetNpcBy(v.x, v.y)
            map_y = v.y
        end
    end
    if self.airship then
        local x,y = target:getPosition()
        self.airship:moveTo(ani and 1 or 0, x + 50, y + 30)
        local old_x, old_y = self:getPosition()
        local point = self:ConvertLogicPositionToMapPosition(4.5, map_y)
        self:GotoMapPositionInMiddle(point.x, point.y)
        local new_x, new_y = self:getPosition()
        self:setPosition(cc.p(old_x, old_y))
        self:moveTo(1, new_x, new_y)
    end
end
function PVELayerNew:RefreshBattery()
    if self.airship then
        local battery = self.airship.battery
        local limit = self.user:GetResProduction("stamina").limit
        local value = self.user:GetResValueByType("stamina")
        local ratio = value / limit
        ratio = ratio > 1 and 1 or ratio
        if ratio >= 1.0 then
            for i = 1, 5 do
                battery:getChildByTag(i):hide()
                battery:getChildByTag(i + 5):show()
            end
        else
            local num = math.ceil(ratio / 0.2)
            num = num <= 0 and 1 or num
            for i = 1, 5 do
                battery:getChildByTag(i):setVisible(i == num)
                battery:getChildByTag(i + 5):setVisible(i < num)
            end
        end
    end
end
function PVELayerNew:GetFteLayer()
    return self.fte_layer
end
---
function PVELayerNew:getContentSize()
    if not self.content_size then
        local w,h = self.normal_map:GetSize()
        self.content_size = {width = self.normal_map.tile_w * w, height = self.normal_map.tile_h * h}
    end
    return self.content_size
end

return PVELayerNew










