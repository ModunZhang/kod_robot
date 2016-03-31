local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local NormalMapAnchorBottomLeftReverseY = import("..map.NormalMapAnchorBottomLeftReverseY")
local MapLayer = import(".MapLayer")
local WorldLayer = class("WorldLayer", MapLayer)

local bigMapLength_value = GameDatas.AllianceInitData.intInit.bigMapLength.value
local middle_index = math.floor((bigMapLength_value-1)/2 + 0.5)
local ui_helper = WidgetAllianceHelper.new()
local TILE_LENGTH = 207
local CORNER_LENGTH = 47
local WIDTH, HEIGHT = bigMapLength_value, bigMapLength_value
local MAX_INDEX = WIDTH * HEIGHT - 1
local WORLD_WIDTH, WORLD_HEIGHT = WIDTH * TILE_LENGTH, HEIGHT * TILE_LENGTH
local SCENE_OFFSET = {x = 15, y = 70}
local worldsize = {
    width = WORLD_WIDTH + CORNER_LENGTH * 2 + SCENE_OFFSET.x * 2,
    height = WORLD_HEIGHT + CORNER_LENGTH * 2 + SCENE_OFFSET.y * 2 + 45,
}


function WorldLayer:ctor(scene,mapIndex)
    WorldLayer.super.ctor(self, scene, 1.0, 1.2)
    self.current_mapIndex = mapIndex
end
function WorldLayer:onEnter()
    self:CreateBg()
    self.scene_node = display.newNode():addTo(self)
        :align(display.LEFT_BOTTOM, SCENE_OFFSET.x, SCENE_OFFSET.y)
    self:CreateCorner()
    self:CreateEdge()
    self.map = self:CreateMap()

    local p = self:ConvertLogicPositionToMapPosition(middle_index, middle_index)
    display.newSprite("world_middle.jpg"):addTo(self.map):pos(p.x + 104, p.y+1)

    display.newSprite("world_crown_circle2.png")
        :addTo(self.map):pos(p.x+10, p.y)
    local circle = display.newSprite("world_crown_circle1.png")
        :addTo(self.map):pos(p.x+10, p.y)
    circle:runAction(cc.RepeatForever:create(transition.sequence({
        cc.CallFunc:create(function()
            circle:opacity(0)
            circle:scale(1)
        end),
        cc.FadeIn:create(0.5),
        cc.CallFunc:create(function() circle:fadeOut(2) end),
        cc.ScaleTo:create(2, 2),
    })))


    self.leveLayer = display.newNode():addTo(self.map,1)
    self.lineLayer = display.newNode():addTo(self.map,2)
    self.allianceLayer = display.newNode():addTo(self.map,3)
    self.moveLayer = display.newNode():addTo(self.map,4)
    self.lineSprites = {}
    self.levelSprites = {}
    self.allainceSprites = {}
    self.flagSprites = {}
    self:ZoomTo(1.1)
    local size = self.scene_node:getCascadeBoundingBox()
    self.scene_node:setContentSize(cc.size(size.width, size.height))
    math.randomseed(1)
end
function WorldLayer:onExit()
end
function WorldLayer:CreateBg()
    local sx, sy = math.ceil(worldsize.width / 634), math.ceil(worldsize.height / 1130)
    local offsetY = 0
    local sprite = display.newFilteredSprite("world_bg.jpg", "CUSTOM", json.encode({
        frag = "shaders/plane.fs",
        shaderName = "plane1",
        param = {1/sx, 1/sy, sx, sy}
    })):addTo(self):align(display.LEFT_BOTTOM, 0, offsetY)
    local size = sprite:getContentSize()
    sprite:setScaleX(sx)
    sprite:setScaleY(sy)

    display.newFilteredSprite("world_title2.jpg", "CUSTOM", json.encode({
        frag = "shaders/plane.fs",
        shaderName = "plane2",
        param = {1/sx, 1, sx, 1}
    })):addTo(self):align(display.LEFT_TOP,0,worldsize.height):setScaleX(sx)

    display.newSprite("world_title1.jpg")
        :addTo(self):align(display.LEFT_TOP,0,worldsize.height):scale(0.7)
end
function WorldLayer:CreateCorner()
    display.newSprite("world_tile.png"):pos(CORNER_LENGTH/2 + 2, CORNER_LENGTH/2 + 2)
        :addTo(self.scene_node):scale(1):rotation(-90)
    display.newSprite("world_tile.png"):pos(CORNER_LENGTH/2 + 2, CORNER_LENGTH*3/2 + TILE_LENGTH * HEIGHT - 2)
        :addTo(self.scene_node):scale(1):rotation(0)
    display.newSprite("world_tile.png"):pos(CORNER_LENGTH*3/2 + TILE_LENGTH * WIDTH - 2, CORNER_LENGTH/2 + 2)
        :addTo(self.scene_node):scale(1):rotation(180)
    display.newSprite("world_tile.png"):pos(CORNER_LENGTH*3/2 + TILE_LENGTH * WIDTH - 2, CORNER_LENGTH*3/2 + TILE_LENGTH * HEIGHT - 2)
        :addTo(self.scene_node):scale(1):rotation(90)
end
function WorldLayer:CreateEdge()
    -- left
    display.newFilteredSprite("world_edge.png", "CUSTOM", json.encode({
        frag = "shaders/nolimittex.fs",
        shaderName = "nolimittex1",
        unit_count = HEIGHT,
        unit_len = 1 / HEIGHT,
    })):pos(CORNER_LENGTH/2 + 1, CORNER_LENGTH + HEIGHT * TILE_LENGTH * 0.5)
        :addTo(self.scene_node):setScaleY(HEIGHT)


    -- right
    display.newFilteredSprite("world_edge.png", "CUSTOM", json.encode({
        frag = "shaders/nolimittex.fs",
        shaderName = "nolimittex2",
        unit_count = HEIGHT,
        unit_len = 1 / HEIGHT,
    })):pos(CORNER_LENGTH*3/2 + TILE_LENGTH * WIDTH - 1, CORNER_LENGTH + HEIGHT * TILE_LENGTH * 0.5)
        :addTo(self.scene_node):setScaleY(HEIGHT):flipX(true)


    -- up
    display.newFilteredSprite("world_edge.png", "CUSTOM", json.encode({
        frag = "shaders/nolimittex.fs",
        shaderName = "nolimittex3",
        unit_count = WIDTH,
        unit_len = 1 / WIDTH,
    })):pos(CORNER_LENGTH + WIDTH * TILE_LENGTH * 0.5, CORNER_LENGTH*3/2 + TILE_LENGTH * HEIGHT - 1)
        :addTo(self.scene_node):setScaleY(WIDTH):rotation(90)

    -- down
    display.newFilteredSprite("world_edge.png", "CUSTOM", json.encode({
        frag = "shaders/nolimittex.fs",
        shaderName = "nolimittex4",
        unit_count = WIDTH,
        unit_len = 1 / WIDTH,
    })):pos(CORNER_LENGTH + WIDTH * TILE_LENGTH * 0.5, CORNER_LENGTH/2 + 1)
        :addTo(self.scene_node):setScaleY(WIDTH):rotation(-90)
end
function WorldLayer:CreateMap()
    local clip = display.newClippingRegionNode(cc.rect(0, 0, WORLD_WIDTH, WORLD_HEIGHT))
                    :addTo(self.scene_node)
                    :align(display.LEFT_BOTTOM,CORNER_LENGTH,CORNER_LENGTH)

    GameUtils:LoadImagesWithFormat(function()
        cc.TMXTiledMap:create("tmxmaps/worldlayer.tmx")
        :align(display.LEFT_BOTTOM, 0, 0):addTo(clip)
    end, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565)

    self.normal_map = NormalMapAnchorBottomLeftReverseY.new{
        tile_w = TILE_LENGTH,
        tile_h = TILE_LENGTH,
        map_width = WIDTH,
        map_height = HEIGHT,
        base_x = 0,
        base_y = HEIGHT * TILE_LENGTH,
    }
    return clip
end
function WorldLayer:LoadLevelBg(index)
    local x,y = self:IndexToLogic(index)
    local mx, my = middle_index, middle_index
    if x >= 0
        and x < bigMapLength_value
        and y >= 0
        and y < bigMapLength_value
        and not self.levelSprites[index]
        and (math.abs(x - mx) + math.abs(y - my)) % 2 == 0
    then
        local p = self:ConvertLogicPositionToMapPosition(x,y)
        local sp= display.newSprite("world_level_bg.png")
            :addTo(self.leveLayer):pos(p.x + 20, p.y - 70)
        local size = sp:getContentSize()
        UIKit:ttfLabel({
            text = math.max(math.abs(x - mx), math.abs(y - my)) + 1,
            size = 18,
            color = 0xd1cead,
        }):addTo(sp):align(display.CENTER, size.width/2, size.height/2)
        self.levelSprites[index] = sp
    end
end
function WorldLayer:GetRoundNumber(index)
    local x,y = self:IndexToLogic(index)
    local mx, my = middle_index, middle_index
    return math.max(math.abs(x - mx), math.abs(y - my)) + 1
end
local screen_rect = cc.rect(0, 0, display.width, display.height)
function WorldLayer:MoveAllianceFromTo(fromIndex, toIndex)
    self:RemoveAllianceBy(toIndex)
    local sour = self:ConvertLogicPositionToMapPosition(self:IndexToLogic(fromIndex))
    local dest = self:ConvertLogicPositionToMapPosition(self:IndexToLogic(toIndex))

    local degree = math.deg(cc.pGetAngle(cc.pSub(dest, sour), cc.p(0, 1)))
    local normal = cc.pNormalize(cc.pSub(dest, sour))
    local distance = cc.pGetLength(cc.pSub(dest, sour))
    local roads = {}
    for i = 0, math.huge do
        local length = 50 * i
        local x = dest.x - normal.x * length
        local y = dest.y - normal.y * length
        if length >= distance or
            not cc.rectContainsPoint(screen_rect, self.map:convertToWorldSpace(cc.p(x, y)))
        then
            break
        end
        sour.x, sour.y = x, y
        local sprite = display.newSprite("pve_road_point.png")
            :addTo(self.moveLayer):pos(x, y):rotation(degree):hide()
        table.insert(roads, 1, sprite)
    end

    local actions = {}
    local step_time = 1.0
    for i,v in ipairs(roads) do
        table.insert(actions, cc.CallFunc:create(function()
            v:show()
        end))
        table.insert(actions, cc.DelayTime:create(step_time))
    end
    local gap, scal, ft, offset = -65, 0.8, 0.5, -40
    UIKit:CreateMoveSoldiers(degree, {name = "ranger_3", star = 3}, scal)
        :addTo(self.moveLayer)
        :pos(sour.x + normal.x * (2 * gap + offset), sour.y + normal.y * (2 * gap + offset))
        :runAction(transition.sequence{
            cc.MoveTo:create(#roads * step_time, {
                x = dest.x + normal.x * (2 * gap + offset), y = dest.y + normal.y * (2 * gap + offset)
            }),
            cc.FadeOut:create(ft),
            cc.RemoveSelf:create(),
        })

    UIKit:CreateMoveSoldiers(degree, {name = "swordsman_3", star = 3}, scal)
        :addTo(self.moveLayer)
        :pos(sour.x + normal.x * (gap + offset), sour.y + normal.y * (gap + offset))
        :runAction(transition.sequence{
            cc.MoveTo:create(#roads * step_time, {
                x = dest.x + normal.x * (gap + offset), y = dest.y + normal.y * (gap + offset)
            }),
            cc.FadeOut:create(ft),
            cc.RemoveSelf:create(),
        })

    UIKit:CreateMoveSoldiers(degree, {name = "lancer_3", star = 3}, scal)
        :addTo(self.moveLayer)
        :pos(sour.x + normal.x * (offset + 10), sour.y + normal.y * (offset + 10))
        :runAction(transition.sequence{
            cc.MoveTo:create(#roads * step_time, {
                x = dest.x + normal.x * (offset + 10), y = dest.y + normal.y * (offset + 10)
            }),
            cc.FadeOut:create(ft),
            cc.RemoveSelf:create(),
        })

    table.insert(actions, cc.CallFunc:create(function()
        for i,v in ipairs(roads) do
            v:runAction(transition.sequence{
                cc.FadeOut:create(ft),
                cc.RemoveSelf:create(),
            })
        end
        self:LoadAllianceBy(toIndex, Alliance_Manager:GetMyAlliance().basicInfo)
    end))
    table.insert(actions, cc.CallFunc:create(function()
        self:RemoveAllianceBy(fromIndex)
    end))
    table.insert(actions, cc.DelayTime:create(0.5))
    table.insert(actions, cc.CallFunc:create(function()
        UIKit:newGameUI("GameUIMoveSuccess", fromIndex, toIndex):AddToCurrentScene(true)
        app:lockInput(false)
    end))
    table.insert(actions, cc.RemoveSelf:create())
    app:lockInput(true)
    display.newNode():addTo(self):runAction(transition.sequence(actions))
end

function WorldLayer:LoadAlliance()
    local indexes = self:GetAvailableIndex()
    local key_map = {}
    for i,v in ipairs(indexes) do
        key_map[tostring(v)] = json.null
    end
    if not next(indexes) then
        if UIKit:GetUIInstance("GameUIWorldMap") then
            UIKit:GetUIInstance("GameUIWorldMap"):HideLoading()
        end
        return
    end
    NetManager:getMapAllianceDatasPromise(self:GetAvailableIndex()):done(function(response)
        for k,v in pairs(response.msg.datas) do
            key_map[k] = v
        end
        for k,v in pairs(key_map) do
            if self.LoadAllianceBy then
                self:LoadAllianceBy(k,v)
            end
        end
        if UIKit:GetUIInstance("GameUIWorldMap") then
            UIKit:GetUIInstance("GameUIWorldMap"):HideLoading()
        end
        if self.GetMiddleLogicPosition then
            local x,y = self:GetMiddleLogicPosition()
            self.middle_pos = {x = x, y = y}
        end
    end)
end
function WorldLayer:LoadAllianceBy(mapIndex, alliance)
    if alliance == json.null then
        self:RemoveAllianceBy(mapIndex)
    else
        self:CreateOrUpdateAllianceBy(mapIndex, alliance)
    end
end
function WorldLayer:RemoveAllianceBy(mapIndex)
    local mapIndex = tostring(mapIndex)
    if self.allainceSprites[mapIndex] then
        self.allainceSprites[mapIndex]:removeFromParent()
        self.allainceSprites[mapIndex] = nil
    end
    if not self.flagSprites[mapIndex] then
        self:CreateFlag(mapIndex)
    end
end
function WorldLayer:CreateOrUpdateAllianceBy(mapIndex, alliance)
    local mapIndex = tostring(mapIndex)
    if not self.allainceSprites[mapIndex] then
        self:CreateAllianceSprite(mapIndex, alliance)
    else
        self:UpdateAllianceSprite(mapIndex, alliance)
    end

    if self.flagSprites[mapIndex] then
        self.flagSprites[mapIndex]:removeFromParent()
        self.flagSprites[mapIndex] = nil
    end
    return self.allainceSprites[mapIndex]
end
local ANI_TAG = 123
local PROTECT_TAG = 110
function WorldLayer:CreateAllianceSprite(index, alliance)
    local index = tostring(index)
    local p = self:ConvertLogicPositionToMapPosition(self:IndexToLogic(index))

    local ismiddle = tonumber(index) == self:LogicToIndex(middle_index, middle_index)

    local node = display.newNode():addTo(self.allianceLayer):pos(p.x, p.y):zorder(index)
    if ismiddle then
        node:scale(1.5)
    end
    node.alliance = alliance

    local sprite = display.newSprite(string.format("world_alliance_%s.png", alliance.terrain))
        :addTo(node, 0, 1)
    if device.platform ~= 'winrt' then
        sprite:scale(0.8)
    else
        sprite:scale(1.2)
    end
    if ismiddle then
        sprite:pos(10, 10)
    elseif index ~= Alliance_Manager:GetMyAlliance().mapIndex then
        math.randomseed(tonumber(index) + 12345)
        local s_x,s_y = self:Offset(index)
        sprite:pos(s_x,s_y)
    end
    local size = sprite:getContentSize()
    local banner = display.newSprite("alliance_banner.png")
        :addTo(sprite):pos(size.width/2, 0)
    sprite.name = UIKit:ttfLabel({
        size = 24,
        color = 0xffedae,
        text = string.format("[%s]%s", alliance.tag, alliance.name),
        ellipsis = true,
        dimensions = cc.size(100,15),
    }):addTo(sprite):align(display.CENTER, size.width/2, 5):scale(0.5)
    local round = self:GetRoundNumber(index)
    if round <= 3 then
        local half = sprite.name:getContentSize().width / 4
        sprite.round = display.newSprite(string.format("world_icon%d.png", round))
            :addTo(sprite):pos(size.width/2 - half - 14, 2):scale(28/40)
    end


    sprite.flagstr = alliance.flag
    sprite.flag = ui_helper:CreateFlagContentSprite(alliance.flag)
        :addTo(sprite, 10):align(display.CENTER, 100, 90):scale(0.4)
    if Alliance_Manager:GetMyAlliance().mapIndex == tonumber(index) then
        display.newSprite("icon_current_position.png")
            :addTo(node, 0, 2):scale(0.8)
            :pos(sprite:getPositionX(), sprite:getPositionY() + sprite:getContentSize().height / 2)
    end
    if self.current_mapIndex == tonumber(index) and Alliance_Manager:GetMyAlliance().mapIndex ~= self.current_mapIndex then
        display.newSprite("icon_current_position_1.png")
            :addTo(node, 0, 2):scale(0.8)
            :pos(sprite:getPositionX(), sprite:getPositionY() + sprite:getContentSize().height / 2)
    end
    local isFight, from, to = self:IsFightWithOtherAlliance(alliance, index)
    if isFight then
        ccs.Armature:create("duizhan")
            :addTo(sprite, 1, ANI_TAG)
            :pos(size.width/2, size.height/2 + 80)
            :getAnimation():playWithIndex(0)

        self:CraeteLineWith(from, to)
    else
        self:DeleteLineWith(index)
    end

    if self:IsProtect(alliance) then
        self:CreateProtect():addTo(sprite, 1, PROTECT_TAG)
            :pos(size.width/2, size.height/2 + 40)
    end

    self.allainceSprites[index] = node
end
function WorldLayer:IsProtect(aln)
    return self:GetAllianceStatus(aln) == "protect"
end
function WorldLayer:GetAllianceStatus(aln)
    local status, mapIndex = unpack(string.split(aln.status, "__"))
    if mapIndex then
        return status, tonumber(mapIndex)
    end
    return status
end
function WorldLayer:CreateProtect()
    local protect = display.newSprite("protect_1.png"):scale(0.8)
    protect:runAction(cc.RepeatForever:create(
        transition.sequence{
            cc.FadeTo:create(1, 255 * 0.7),
            cc.FadeTo:create(1, 255 * 1.0),
        }))
    local size = protect:getContentSize()
    display.newSprite("protect_2.png")
        :addTo(protect):pos(size.width/2, size.height/2)
        :opacity(255 * 0.7):runAction(cc.RepeatForever:create(
        transition.sequence{
            cc.FadeTo:create(1, 255 * 1.0),
            cc.FadeTo:create(1, 255 * 0.7),
        }))
    return protect
end
function WorldLayer:CraeteLineWith(from, to)
    local line_key = string.format("%d_%d", from, to)
    if self.lineSprites[line_key] then return end
    math.randomseed(tonumber(from) + 12345)
    local fromx,fromy = self:Offset(from)
    local p1 = self:ConvertLogicPositionToMapPosition(self:IndexToLogic(from))
    p1.x = p1.x + fromx
    p1.y = p1.y + fromy
    math.randomseed(tonumber(to) + 12345)
    local tox,toy = self:Offset(to)
    local p2 = self:ConvertLogicPositionToMapPosition(self:IndexToLogic(to))
    p2.x = p2.x + tox
    p2.y = p2.y + toy
    local length = cc.pGetLength(cc.pSub(p1,p2))
    local PNG_LENGTH = 17
    local unit_count = math.ceil(length / PNG_LENGTH)
    local degree = math.deg(cc.pGetAngle(cc.pSub(p1, p2), cc.p(0, 1)))
    local sprite = display.newSprite("fight_line_6x17.png", nil, nil,
        {class=cc.FilteredSpriteWithOne})
        :addTo(self.lineLayer)
        :pos((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5)
        :rotation(degree)

    sprite:setScaleY(unit_count)
    sprite:setFilter(filter.newFilter("CUSTOM",
        json.encode({
            frag = "shaders/multi_tex.fs",
            shaderName = "lineShader_"..unit_count,
            unit_count = unit_count,
            unit_len = 1 / unit_count,
            percent = 0,
            elapse = 0,
        })
    ))
    self.lineSprites[line_key] = sprite
end
function WorldLayer:DeleteLineWith(mapIndex)
    for k,v in pairs(self.lineSprites) do
        local fromstr, tostr = unpack(string.split(k, "_"))
        if tonumber(fromstr) == tonumber(mapIndex) or
            tonumber(tostr) == tonumber(mapIndex)
        then
            self.lineSprites[k]:removeFromParent()
            self.lineSprites[k] = nil
            return
        end
    end
end
function WorldLayer:UpdateAllianceSprite(index, alliance)
    local index = tostring(index)
    local sprite = self.allainceSprites[index]:getChildByTag(1)
    local size = sprite:getContentSize()
    sprite:setTexture(string.format("world_alliance_%s.png", alliance.terrain))
    sprite.name:setString(string.format("[%s]%s", alliance.tag, alliance.name))

    local round = self:GetRoundNumber(index)
    if round <= 3 then
        local png = string.format("world_icon%d.png", round)
        if sprite.round then
            sprite.round:setTexture(png)
        else
            sprite.round = display.newSprite(png):addTo(sprite):scale(28/40)
        end
        local half = sprite.name:getContentSize().width / 4
        sprite.round:pos(size.width/2 - half - 14, 2)
    elseif sprite.round then
        sprite.round:removeFromParent()
        sprite.round = nil
    end


    if sprite.flagstr ~= alliance.flag then
        sprite.flag:SetFlag(alliance.flag)
    end
    local isFight, from, to = self:IsFightWithOtherAlliance(alliance, index)
    if not isFight then
        if sprite:getChildByTag(ANI_TAG) then
            sprite:removeChildByTag(ANI_TAG)
        end
        self:DeleteLineWith(index)
    else
        if not sprite:getChildByTag(ANI_TAG) then
            ccs.Armature:create("duizhan")
                :addTo(sprite, 1, ANI_TAG)
                :pos(size.width/2, size.height/2 + 80)
                :getAnimation():playWithIndex(0)
        end
        self:CraeteLineWith(from, to)
    end
    if self:IsProtect(alliance) then
        if not sprite:getChildByTag(PROTECT_TAG) then
            self:CreateProtect():addTo(sprite, 1, PROTECT_TAG)
                :pos(size.width/2, size.height/2 + 40)
        end
    elseif sprite:getChildByTag(PROTECT_TAG) then
        sprite:removeChildByTag(PROTECT_TAG)
    end
end
function WorldLayer:IsFightWithOtherAlliance(aln, index)
    local my_aln = Alliance_Manager:GetMyAlliance()
    if my_aln:GetEnemyAllianceId()
        and (aln.id == my_aln._id
        or aln.id == my_aln:GetEnemyAllianceId()) then
        local mindx = my_aln.mapIndex
        local eindx = my_aln:GetEnemyAllianceMapIndex()
        return (my_aln.basicInfo.status == "fight"
            or my_aln.basicInfo.status == "prepare")
            ,math.min(mindx, eindx), math.max(mindx, eindx)
    end

    local status, mapIndex = self:GetAllianceStatus(aln)
    if status == "fight" or status == "prepare" then
        return true, math.min(index, mapIndex), math.max(index, mapIndex)
    end
end
function WorldLayer:CreateFlag(index)
    local indexstr = tostring(index)
    local p = self:ConvertLogicPositionToMapPosition(self:IndexToLogic(index))
    local node
    if tonumber(index) == self:LogicToIndex(middle_index, middle_index) then
        node = display.newNode():addTo(self.allianceLayer):pos(p.x,p.y)
        display.newSprite("crystalThrone.png"):addTo(node):pos(15,15):scale(0.3)
    else
        math.randomseed(tonumber(index) + 12345)
        node = display.newNode():addTo(self.allianceLayer):pos(p.x, p.y)
        local sprite = ccs.Armature:create("daqizi"):addTo(node):scale(0.4)
        local s_x,s_y = self:Offset(index)
        sprite:pos(s_x,s_y)
        local ani = sprite:getAnimation()
        ani:playWithIndex(0)
        ani:gotoAndPlay(math.random(71) - 1)
        if self.current_mapIndex == tonumber(index) and Alliance_Manager:GetMyAlliance().mapIndex ~= self.current_mapIndex then
            display.newSprite("icon_current_position_1.png")
                :addTo(node, 0, 2):scale(0.8)
                :pos(sprite:getPositionX(), sprite:getPositionY() + sprite:getContentSize().height / 2 - 20)
        end
    end
    self.flagSprites[indexstr] = node
end
function WorldLayer:Offset(index)
    local x,y = 30 - math.random(60), 30 - math.random(60)
    if tonumber(index) == self:LogicToIndex(middle_index-1, middle_index-1) then
        x,y =-40, 40
    elseif tonumber(index) == self:LogicToIndex(middle_index, middle_index-1) then
        x,y =0, 40
    elseif tonumber(index) == self:LogicToIndex(middle_index+1, middle_index-1) then
        x,y =40, 40
    elseif tonumber(index) == self:LogicToIndex(middle_index-1, middle_index) then
        x,y =-40, 0
    elseif tonumber(index) == self:LogicToIndex(middle_index+1, middle_index) then
        x,y =40, 0
    elseif tonumber(index) == self:LogicToIndex(middle_index-1, middle_index+1) then
        x,y =-40, -40
    elseif tonumber(index) == self:LogicToIndex(middle_index, middle_index+1) then
        x,y =0, -40
    elseif tonumber(index) == self:LogicToIndex(middle_index+1, middle_index+1) then
        x,y =40, -40
    end
    return x,y
end
function WorldLayer:IndexToLogic(index)
    local index = tonumber(index)
    return index % WIDTH, math.floor(index / WIDTH)
end
function WorldLayer:LogicToIndex(x, y)
    return x + y * WIDTH
end
function WorldLayer:GetLogicMap()
    return self.normal_map
end
function WorldLayer:ConverToScenePosition(lx, ly)
    return self.map:getParent():convertToNodeSpace(self.map:convertToWorldSpace(cc.p(self.normal_map:ConvertToMapPosition(lx, ly))))
end
function WorldLayer:ConvertScreenPositionToLogicPosition(sx, sy)
    local p = self.map:convertToNodeSpace(cc.p(sx, sy))
    return self.normal_map:ConvertToLogicPosition(p.x, p.y)
end
function WorldLayer:ConverToWorldSpace(lx, ly)
    return self.map:convertToWorldSpace(cc.p(self.normal_map:ConvertToMapPosition(lx, ly)))
end
function WorldLayer:ConvertLogicPositionToMapPosition(lx, ly)
    return self.map:convertToNodeSpace(self.map:convertToWorldSpace(cc.p(self.normal_map:ConvertToMapPosition(lx, ly))))
end
function WorldLayer:GetAvailableIndex()
    local t = {}
    local x,y = self:GetLeftTopLogicPosition()
    for i = x - 3, x + 3 do
        for j = y - 2, y + 4 do
            if i >= 0 and i < WIDTH and j >= 0 and j < HEIGHT then
                table.insert(t, self:LogicToIndex(i,j))
            end
        end
    end
    return t
end
function WorldLayer:GetLeftTopLogicPosition()
    local point = self.map:convertToNodeSpace(cc.p(0, display.height))
    return self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
end
function WorldLayer:GetMiddleLogicPosition()
    local point = self.map:convertToNodeSpace(cc.p(display.cy, display.cy))
    return self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
end
function WorldLayer:GetClickedObject(world_x, world_y)
    local point = self.map:convertToNodeSpace(cc.p(world_x, world_y))
    local logic_x, logic_y = self:GetLogicMap():ConvertToLogicPosition(point.x, point.y)
    if logic_x < 0 or logic_x >= WIDTH or logic_y < 0 or logic_y >= HEIGHT then
        return nil, false
    end
    local index = self:LogicToIndex(logic_x, logic_y)
    return self.allainceSprites[tostring(index)] , index
end
function WorldLayer:getContentSize()
    return worldsize
end


return WorldLayer









