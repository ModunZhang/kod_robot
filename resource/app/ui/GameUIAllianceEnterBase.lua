--
-- Author: Danny He
-- Date: 2014-12-29 11:34:54
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIAllianceEnterBase = class("GameUIAllianceEnterBase",WidgetPopDialog)
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Localize = import("..utils.Localize")
local WidgetUseItems = import("..widget.WidgetUseItems")

-- building is allianceobject
function GameUIAllianceEnterBase:ctor(building,isMyAlliance,my_alliance,enemy_alliance)
    GameUIAllianceEnterBase.super.ctor(self,self:GetUIHeight(),"",display.top-200)
    self.building = building
    self.my_alliance = my_alliance
    self.isMyAlliance = isMyAlliance
    self.enemy_alliance = enemy_alliance
end

function GameUIAllianceEnterBase:IsMyAlliance()
    return self.isMyAlliance
end

function GameUIAllianceEnterBase:GetBuilding()
    return self.building
end

function GameUIAllianceEnterBase:GetMyAlliance()
    return self.my_alliance
end

function GameUIAllianceEnterBase:GetEnemyAlliance()
    return self.enemy_alliance
end

function GameUIAllianceEnterBase:GetBuildingType()
    return self:GetBuilding():GetType()
end

function GameUIAllianceEnterBase:GetUIHeight()
    return 242
end

function GameUIAllianceEnterBase:GetUITitle()
    return _("空地")
end


function GameUIAllianceEnterBase:onEnter()
    GameUIAllianceEnterBase.super.onEnter(self)
    self:SetTitle(self:GetUITitle())
    self:InitBuildingImage()
    self:InitBuildingDese()
    self:InitBuildingInfo()
    self:InitEnterButton()
    self:FixedUI()
end

function GameUIAllianceEnterBase:RefreshUI()
    self:InitBuildingInfo()
    self:InitEnterButton()
end

function GameUIAllianceEnterBase:GetBuildingInfo()
    return
        {
            {
                {_("坐标"),0x797154},
                {self:GetLocation(),0x403c2f},
            }
        }
end

function GameUIAllianceEnterBase:GetLogicPosition()
    local building = self:GetBuilding()
    local x,y = building:GetLogicPosition()
    return {x = x , y = y}
end

function GameUIAllianceEnterBase:GetLocation()
    local building = self:GetBuilding()
    local x,y = building:GetLogicPosition()
    return x .. "," .. y
end

function GameUIAllianceEnterBase:GetTerrain()
    local alliance = self:IsMyAlliance() and self:GetMyAlliance() or self:GetEnemyAlliance()
    return alliance:Terrain()
end

function GameUIAllianceEnterBase:GetBuildImageSprite()
    local postion = {
        grassLand = 960,
        desert = 0,
        iceField = 480,
    }
    local x = postion[self:GetTerrain()]
    local sprite = cc.Sprite:create("tmxmaps/terrain.png",cc.rect(x,0,480,480))
    sprite:setCascadeOpacityEnabled(true)
    return sprite
end

function GameUIAllianceEnterBase:GetBuildingImage()
    return ""
end

function GameUIAllianceEnterBase:GetBuildImageInfomation(sprite)
    return 110/480,97,self:GetUIHeight() - 90 
end

function GameUIAllianceEnterBase:InitBuildingImage()
    local body = self:GetBody()
    -- 建筑图片 放置区域左右边框
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.LEFT_CENTER, 30,self:GetUIHeight()-90)
        :addTo(body):flipX(true)
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.RIGHT_CENTER, 163, self:GetUIHeight()-90)
        :addTo(body)
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
    local level_bg = display.newSprite("back_ground_138x34.png"):addTo(body):pos(96, self:GetUIHeight()-180)
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
        text = self:GetHonourLabelText(),
        size = 20,
        color = 0x514d3e,
    }):align(display.CENTER, level_bg:getContentSize().width/2 , level_bg:getContentSize().height/2)
        :addTo(level_bg)
    self.honour_icon = honour_icon
    self.honour_label = honour_label
end

function GameUIAllianceEnterBase:GetLevelBg()
    return self.level_bg
end

function GameUIAllianceEnterBase:GetLevelLabelText()
    return self:GetBuilding().level and _("等级") .. self:GetBuilding().level or ""
end

function GameUIAllianceEnterBase:GetHonourLabelText()
    return "1000"
end

function GameUIAllianceEnterBase:GetLevelLabel()
    return self.level_label
end

function GameUIAllianceEnterBase:GetHonourIcon()
    return self.honour_icon
end

function GameUIAllianceEnterBase:GetHonourLabel()
    return self.honour_label
end

function GameUIAllianceEnterBase:FixedUI()
    self:GetLevelBg():hide()
    self.process_bar_bg:hide()
end

function GameUIAllianceEnterBase:InitBuildingDese()
    local body = self:GetBody()
    self.desc_label = UIKit:ttfLabel({
        text = self:GetBuildingDesc(),
        size = 18,
        color = 0x797154,
        dimensions = cc.size(400,0)
    }):align(display.LEFT_TOP, 180, self:GetUIHeight()-20):addTo(body)

    self.process_bar_bg = display.newSprite("Progress_bar_1.png"):align(display.LEFT_TOP, 180, self:GetUIHeight()-30):addTo(body)
    self.progressTimer = UIKit:commonProgressTimer("progress_bar_366x34.png"):addTo(self.process_bar_bg):align(display.LEFT_BOTTOM,0,0):scale(386/366)
    self.progressTimer:setPercentage(100)
    self.process_icon_bg =   display.newSprite("back_ground_43x43.png"):addTo(self.process_bar_bg):pos(10,18)
    local icon,scale = self:GetProcessIcon()
    self.process_icon =  display.newSprite(icon):addTo(self.process_icon_bg):pos(21,21):scale(scale)
    self.process_label = UIKit:ttfLabel({
        size = 20,
        color = 0xfff3c7,
        shadow = true,
        text = self:GetProcessLabelText()
    }):align(display.LEFT_CENTER,self.process_icon_bg:getPositionX() + 40,self.process_icon_bg:getPositionY()):addTo(self.process_bar_bg)
end

function GameUIAllianceEnterBase:GetProgressTimer()
    return  self.progressTimer
end

function GameUIAllianceEnterBase:GetProcessLabel()
    return self.process_label
end

function GameUIAllianceEnterBase:GetBuildingInfoOriginalY()
    return self.desc_label:getPositionY()-self.desc_label:getContentSize().height-40
end

function GameUIAllianceEnterBase:InitBuildingInfo()
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

function GameUIAllianceEnterBase:CreateItemWithLine(params)
    local line = display.newSprite("dividing_line.png")
    local size = line:getContentSize()
    UIKit:ttfLabel({
        text = params[1][1],
        size = 20,
        color = params[1][2],
    }):align(display.LEFT_BOTTOM, 0, 6)
        :addTo(line)
    if params[2] then
        local label = UIKit:ttfLabel({
            text = params[2][1],
            size = 20,
            color = params[2][2],
        }):align(display.RIGHT_BOTTOM, size.width, 6)
            :addTo(line)
        label:setTag(100)
    end
    if params[2] and params[2][3] then
        line:setTag(params[2][3])
    end
    return line
end

function GameUIAllianceEnterBase:GetInfoLabelByTag(tag)
    local line = self:GetBody():getChildByTag(tag)
    if line then
        return line:getChildByTag(100)
    else
        return nil
    end
end

function GameUIAllianceEnterBase:InitEnterButton()
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
function GameUIAllianceEnterBase:GetEnterButtonByIndex( idx )
    return self.EnterButtonNodes[idx]
end
function GameUIAllianceEnterBase:GetEnterButtons()
    if self:IsMyAlliance() then
        local move_city_button = self:BuildOneButton("icon_move_city.png",_("迁移城市")):onButtonClicked(function()
            if self:GetMyAlliance():Status() == 'fight' then
                UIKit:showMessageDialog(nil, _("战争期不能移动"),function()end)
                return
            end
            local location = self:GetLogicPosition()
            WidgetUseItems.new():Create({
                item_type = WidgetUseItems.USE_TYPE.MOVE_THE_CITY,
                locationX=location.x,
                locationY=location.y
            }):AddToCurrentScene()
            self:LeftButtonClicked()
        end)
        return {move_city_button}
    else
        return {}
    end
end


function GameUIAllianceEnterBase:BuildOneButton(image,title,music_info)
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

function GameUIAllianceEnterBase:GetDescLabel()
    return self.desc_label
end

function GameUIAllianceEnterBase:GetProcessIcon()
    return "wall_36x41.png",1
end

function GameUIAllianceEnterBase:GetProcessLabelText()
    return "100/100"
end

function GameUIAllianceEnterBase:GetBuildingDesc()
    return _("联盟将军可将联盟建筑移动到空地,玩家可将自己的城市移动到空地处,空地定期刷新放逐者的村落,树木,山脉和湖泊")
end

return GameUIAllianceEnterBase

