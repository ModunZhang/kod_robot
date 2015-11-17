local Alliance = import("..entity.Alliance")
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIAllianceBase = class("GameUIAllianceBase",WidgetPopDialog)
local buildingName = GameDatas.AllianceMap.buildingName
function GameUIAllianceBase:ctor(alliance, x, y, name)
    GameUIAllianceBase.super.ctor(self,self:GetUIHeight(),"",display.top-200)
    self.alliance = alliance
    self.x = x
    self.y = y
    self.name = name
    setmetatable(self.alliance, Alliance)
end
function GameUIAllianceBase:onEnter()
    GameUIAllianceBase.super.onEnter(self)
    self:SetTitle(self:GetUITitle())
    self:InitBuildingImage()
    -- self:InitBuildingDese()
    -- self:InitBuildingInfo()
    self:InitEnterButton()
    -- self:FixedUI()
end
function GameUIAllianceBase:GetUITitle()
    return _("空地")
end
function GameUIAllianceBase:IsShowBuildingBox()
    return true
end
function GameUIAllianceBase:GetBuildImageSprite()
    local postion = {
        grassLand = 960,
        desert = 0,
        iceField = 480,
    }
    local x = postion[self:GetTerrain()]
    local sprite = cc.Sprite:create("tmxmaps/terrain1.png",cc.rect(x,0,480,480))
    sprite:setCascadeOpacityEnabled(true)
    return sprite
end
function GameUIAllianceBase:GetTerrain()
    return self.alliance.basicInfo.terrain
end
function GameUIAllianceBase:GetBuildImageInfomation(sprite)
    return 110/480,97,self:GetUIHeight() - 90
end
function GameUIAllianceBase:GetLevelLabelText()
    return self:GetObjectLevel() and _("等级") .. self:GetObjectLevel() or ""
end
function GameUIAllianceBase:InitBuildingImage()
    local body = self:GetBody()
    if self:IsShowBuildingBox() then
        display.newSprite("alliance_item_flag_box_126X126.png"):addTo(body):align(display.LEFT_CENTER, 30,self:GetUIHeight()-90):scale(136/126)
    end
    local sprite = self:GetBuildImageSprite()
    if not sprite then
        local building_image = display.newSprite(self:GetBuildingImage())
        local scale,x,y = self:GetBuildImageInfomation(building_image)
        building_image:addTo(body):pos(x,y)
        building_image:setAnchorPoint(cc.p(0.5,0.5))
        building_image:setScale(scale)
    else
        local scale,x,y = self:GetBuildImageInfomation(sprite)
        sprite:setAnchorPoint(cc.p(0.5,0.5)):addTo(body):pos(x,y)
        sprite:setScale(scale)
    end
    local level_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(138,34),cc.rect(15,10,136,64))
        :addTo(body):pos(96, self:GetUIHeight()-180)
    local label = UIKit:ttfLabel({
        text = self:GetLevelLabelText(),
        size = 20,
        color = 0x514d3e,
    }):align(display.CENTER, level_bg:getContentSize().width/2 , level_bg:getContentSize().height/2)
        :addTo(level_bg)
    self.level_bg = level_bg
    self.level_label = label
    local honour_icon = display.newSprite("honour_128x128.png"):align(display.CENTER, 20, level_bg:getContentSize().height/2)
        :addTo(level_bg)
        :scale(42/128)
    local honour_label= UIKit:ttfLabel({
        -- text = self:GetHonourLabelText(),
        text = "",
        size = 20,
        color = 0x514d3e,
    }):align(display.CENTER, level_bg:getContentSize().width/2 , level_bg:getContentSize().height/2)
        :addTo(level_bg)
    self.honour_icon = honour_icon
    self.honour_label = honour_label
end
function GameUIAllianceBase:GetBuildingDesc()
    return ""
end
function GameUIAllianceBase:InitBuildingDese()
    local body = self:GetBody()
    self.desc_label = UIKit:ttfLabel({
        text = self:GetBuildingDesc(),
        size = 18,
        color = 0x615b44,
        dimensions = cc.size(400,0)
    }):align(display.LEFT_TOP, 180, self:GetUIHeight()-20):addTo(body)

    self.process_bar_bg = display.newSprite("process_bg_394x40.png"):align(display.LEFT_TOP, 186, self:GetUIHeight()-30):addTo(body)
    self.progressTimer = UIKit:commonProgressTimer("process_color_394x40.png"):addTo(self.process_bar_bg):align(display.LEFT_BOTTOM,0,0)
    self.progressTimer:setPercentage(100)
    self.process_icon_bg =   display.newSprite("back_ground_43x43.png"):addTo(self.process_bar_bg):pos(10,20)
    local icon,scale = self:GetProcessIcon()
    self.process_icon =  display.newSprite(icon):addTo(self.process_icon_bg):pos(21,21):scale(scale)
    self.process_label = UIKit:ttfLabel({
        size = 20,
        color = 0xfff3c7,
        shadow = true,
        text = self:GetProcessLabelText()
    }):align(display.LEFT_CENTER,self.process_icon_bg:getPositionX() + 40,20):addTo(self.process_bar_bg)
end
function GameUIAllianceBase:InitBuildingInfo()
    if self.BuildingInfoNodes then
        for __,v in ipairs(self.BuildingInfoNodes) do
            v:removeFromParent(true)
        end
    end
    self.BuildingInfoNodes = {}
    local original_y = self:GetBuildingInfoOriginalY()
    local gap_y = 40
    local info_count = 0
    local info = self:GetBuildingInfo()
    for k,v in pairs(info) do
        local node = self:CreateItemWithLine(v)
            :align(display.CENTER, 380, original_y - gap_y*info_count)
            :addTo(self.body)
        table.insert(self.BuildingInfoNodes,node)
        info_count = info_count + 1
    end
end
function GameUIAllianceBase:InitEnterButton()
    if self.EnterButtonNodes then
        for __,v in ipairs(self.EnterButtonNodes) do
            v:removeFromParent(true)
        end
    end
    self.EnterButtonNodes = {}
    local buttons = self:GetEnterButtons()
    local width = 608
    local btn_width = 124
    local count = 0
    for _,v in ipairs(buttons) do
        local btn = v:align(display.RIGHT_TOP,width-count*btn_width, 10):addTo(self:GetBody())
        table.insert(self.EnterButtonNodes,btn)
        count = count + 1
    end
end
function GameUIAllianceBase:GetEnterButtons()
    if self:IsEmpty() then
        local move_city_button = self:BuildOneButton("icon_move_player_city.png",_("迁移城市")):onButtonClicked(function()
            WidgetUseItems.new():Create({
                item_name = "moveTheCity",
                locationX = self.x,
                locationY = self.y
            }):AddToCurrentScene()
            self:LeftButtonClicked()
        end)
        return {move_city_button}
    end
    if self:IsMonster() then
        local mid = self:GetMapObjectInfo().id
        local aid = self.alliance._id
        local attack_button = self:BuildOneButton("icon_move_player_city.png",_("进攻")):onButtonClicked(function()
            UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                NetManager:getAttackMonsterPromise(dragonType,soldiers, aid, mid):done(function()
                    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                    gameuialliancesendtroops:LeftButtonClicked()
                end)
            end,{targetIsMyAlliance = isMyAlliance,toLocation = toLocation,returnCloseAction = true}):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
        return {attack_button}
    end

    if self:IsVillage() then
        local bottons = {}
        local mid = self:GetMapObjectInfo().id
        local aid = self.alliance._id
        if Alliance_Manager:GetVillageEventsByMapId(self.alliance, mid) then
            local che_button = self:BuildOneButton("capture_38x56.png",_("撤军")):onButtonClicked(function()
                NetManager:getRetreatFromVillagePromise(self.alliance:GetAllianceVillageInfosById(mid).villageEvent.eventId)
                self:LeftButtonClicked()
            end)
            table.insert(bottons, che_button)
        end

        local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
            UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                NetManager:getAttackVillagePromise(dragonType,soldiers,aid,mid):done(function()
                    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                    gameuialliancesendtroops:LeftButtonClicked()
                end)
            end,{targetIsMyAlliance = isMyAlliance,toLocation = toLocation,returnCloseAction = true}):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
        table.insert(bottons, attack_button)
        return bottons
    end

    local mid = self:GetMemberId()
    local aid = self.alliance._id
    local attack_button = self:BuildOneButton("icon_move_player_city.png",_("攻打")):onButtonClicked(function()
        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
            NetManager:getAttackPlayerCityPromise(dragonType, soldiers, aid, mid):done(function()
                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                gameuialliancesendtroops:LeftButtonClicked()
            end)
        end,{targetIsMyAlliance = isMyAlliance,toLocation = toLocation,returnCloseAction = true}):AddToCurrentScene(true)
        self:LeftButtonClicked()
    end)
    return {attack_button}
end
function GameUIAllianceBase:BuildOneButton(image,title,music_info)
    local btn = WidgetPushButton.new({normal = "btn_138x110.png",pressed = "btn_pressed_138x110.png"},{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        }
        ,music_info)
    local s = btn:getCascadeBoundingBox().size
    display.newSprite(image):align(display.CENTER, -s.width/2, -s.height/2+12):addTo(btn)
    UIKit:ttfLabel({
        text =  title,
        size = 18,
        color = 0xffedae,
    }):align(display.CENTER, -s.width/2 , -s.height+25):addTo(btn)
    return btn
end
function GameUIAllianceBase:FixedUI()
-- self:GetLevelBg():hide()
-- self.process_bar_bg:hide()
end
function GameUIAllianceBase:GetUIHeight()
    return 242
end
function GameUIAllianceBase:GetObjectLevel()
    if not buildingName[self.name] then
        return 0
    end
    local mapInfo = self:GetMapObjectInfo()
    local type_ = buildingName[self.name].type
    if type_ == "member" then
        return self.alliance:GetMemberByMapObjectsId(mapInfo.id).level
    elseif type_ == "village" then
        return self.alliance:GetAllianceVillageInfosById(mapInfo.id).level
    elseif type_ == "monster" then
        return self.alliance:GetAllianceMonsterInfosById(mapInfo.id).level
    elseif type_ == "building" then
        return self.alliance:GetAllianceBuildingInfoByName(self.name).level
    else
        return 0
    end
end
function GameUIAllianceBase:IsVillage()
    if buildingName[self.name] then
        return buildingName[self.name].type == "village"
    end
end
function GameUIAllianceBase:IsMonster()
    return self.name == "monster"
end
function GameUIAllianceBase:IsAllianceBuilding()
    if buildingName[self.name] then
        return buildingName[self.name].type == "building"
    end
end
function GameUIAllianceBase:IsEmpty()
    return self.name == "empty"
end
function GameUIAllianceBase:GetMemberId()
    local mapInfo = self:GetMapObjectInfo()
    if mapInfo then
        local member = self.alliance:GetMemberByMapObjectsId(mapInfo.id)
        if member then
            return member.id
        end
    end
end
function GameUIAllianceBase:GetMapObjectInfo()
    for k,v in pairs(self.alliance.mapObjects) do
        local location = v.location
        if location.x == self.x and location.y == self.y then
            return v
        end
    end
end





return GameUIAllianceBase







