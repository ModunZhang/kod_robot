--
-- Author: Kenny Dai
-- Date: 2015-05-13 11:41:47
--
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetSoldierDetails = import('..widget.WidgetSoldierDetails')
local WidgetUIBackGround = import('..widget.WidgetUIBackGround')
local UIScrollView = import(".UIScrollView")
local UILib = import(".UILib")
local Corps = import(".Corps")

local GameUIHelpDefence = UIKit:createUIClass("GameUIHelpDefence", "GameUIWithCommonHeader")

local soldier_arrange = {
    swordsman = {row = 4, col = 2},
    ranger = {row = 4, col = 2},
    lancer = {row = 3, col = 1},
    catapult = {row = 2, col = 1},

    horseArcher = {row = 3, col = 1},
    ballista = {row = 2, col = 1},
    skeletonWarrior = {row = 4, col = 2},
    skeletonArcher = {row = 4, col = 2},

    deathKnight = {row = 3, col = 1},
    meatWagon = {row = 2, col = 1},
    priest = {row = 3, col = 1},
    demonHunter = {row = 3, col = 1},

    paladin = {row = 4, col = 2},
    steamTank = {row = 2, col = 1},
    sentinel = {row = 4, col = 2},
    crossbowman = {row = 4, col = 2},
}
local soldier_ani_width = {
    swordsman = 180,
    ranger = 180,
    lancer = 180,
    catapult = 180,

    sentinel = 180,
    crossbowman = 180,
    horseArcher = 180,
    ballista = 180,

    skeletonWarrior = 180,
    skeletonArcher = 180,
    deathKnight = 180,
    meatWagon = 180,
}

function GameUIHelpDefence:ctor(city,helped_troop,details)
    GameUIHelpDefence.super.ctor(self,city, _("协防"))
    self.helped_troop = helped_troop
    self.details = details
    self.soldiers = details.soldiers
    self.dragon = details.dragon
    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_RECRUIT")
end
function GameUIHelpDefence:OnMoveInStage()
    GameUIHelpDefence.super.OnMoveInStage(self)
    local troop_show = self:CreateSoldierNode()
    local soldier_show_table = {}
    local soldiers = self.soldiers
    for i,soldier in ipairs(soldiers) do
        local soldier_level = soldier.star
        local soldier_config = self.city:GetUser():GetSoldierConfig(soldier.name)
        local soldier_number = soldier.count
        table.insert(soldier_show_table, {
            soldier_type = soldier.name,
            power = soldier_config.power * soldier_number,
            soldier_num = soldier_number,
            soldier_weight = soldier_config.load * soldier_number,
            soldier_citizen = soldier_config.citizen * soldier_number,
            soldier_star = soldier_level
        })
    end
    troop_show:ShowOrRefreasTroops(soldier_show_table)

    self:DragonPart()
    self:PlayerPart()
end
function GameUIHelpDefence:onExit()
    GameUIHelpDefence.super.onExit(self)
end
function GameUIHelpDefence:CreateSoldierNode()
    local view = self:GetView()
    local parent = self
    local grass_width,grass_height = 611,275
    local TroopShow = display.newNode()
    TroopShow:setContentSize(cc.size(grass_width,grass_height))
    TroopShow:align(display.BOTTOM_LEFT, window.cx-304, window.top_bottom-250)
    local land_image = {
        desert = "battle_bg_desert_611x275.png",
        iceField = "battle_bg_iceField_611x275.png",
        grassLand = "battle_bg_grass_611x275.png"
    }
    local land_bg = land_image[User.basicInfo.terrain]
    display.newSprite(land_bg)
        :align(display.LEFT_BOTTOM,window.cx-304, window.top_bottom-250):addTo(view)
    TroopShow.offset_x = 0
    TroopShow.bound_box_width = grass_width

    local scrollView = UIScrollView.new({
        viewRect = cc.rect(window.cx-304, window.top_bottom-250, 611, 275),
    }):addScrollNode(TroopShow)
        :setBounceable(false)
        :setDirection(UIScrollView.DIRECTION_HORIZONTAL)
        :addTo(view)
    -- 战斗力，人口，负重信息展示背景框
    local info_bg = cc.LayerColor:create(UIKit:hex2c4b(0x7a000000))
        :pos(window.left+14, window.top-343)
        :addTo(view)
    info_bg:setTouchEnabled(false)
    info_bg:setContentSize(620, 46)
    -- line
    local line = display.newSprite("line_624x4.png")
        :align(display.CENTER, window.cx+2, window.top-343)
        :addTo(self:GetView())

    local function createInfoItem(title,value)
        local info = cc.Layer:create()
        local split_str = string.split(value, "/")
        local total_width
        if #split_str > 1 then
            local num_1 = tonumber(split_str[1])
            local num_2 = tonumber(split_str[2])
            local value_label_1 = UIKit:ttfLabel({
                text = string.formatnumberthousands(num_1),
                size = 18,
                color = num_1 > num_2 and 0x7e0000 or 0xffedae,
            })
            local value_label_2 = UIKit:ttfLabel({
                text = "/"..string.formatnumberthousands(num_2),
                size = 18,
                color = 0xffedae,
            })
            total_width = value_label_1:getContentSize().width + value_label_2:getContentSize().width
            value_label_1:align(display.BOTTOM_LEFT,0,0)
                :addTo(info)
            value_label_2:align(display.BOTTOM_LEFT,value_label_1:getContentSize().width,0)
                :addTo(info)
            info:setContentSize(total_width, 45)
        else
            local value_label = UIKit:ttfLabel({
                text = string.formatnumberthousands(value),
                size = 18,
                color = 0xffedae,
            })
            value_label:align(display.BOTTOM_CENTER,value_label:getContentSize().width/2,0)
                :addTo(info)
            total_width = value_label:getContentSize().width
            info:setContentSize(total_width, 45)
        end
        UIKit:ttfLabel({
            text = title,
            size = 16,
            color = 0xbbae80,
        }):align(display.BOTTOM_CENTER,total_width/2,20)
            :addTo(info)
        return info
    end

    function TroopShow:RefreshScrollNode(current_x)
        -- 因为士兵动画的锚点为CENTER，需要的滑动区域的宽度需要多加士兵动画设计宽度180/2
        current_x = current_x - 180/2
        if current_x<grass_width then
            table.insert(self.soldier_crops,display.newSprite(land_bg)
                :align(display.LEFT_BOTTOM,0,0):addTo(self))
        end
        if current_x<0 then
            local need_bg_count = math.ceil(math.abs(current_x)/grass_width)
            for i=1,need_bg_count do
                table.insert(self.soldier_crops,display.newSprite(land_bg)
                    :align(display.LEFT_BOTTOM,-grass_width*i,0):addTo(self))
            end
            self.offset_x = grass_width -(math.abs(current_x)-(need_bg_count-1)*grass_width)
            self.bound_box_width = math.abs(current_x)+grass_width
        else
            self.offset_x = 0
            self.bound_box_width = grass_width
        end
    end
    function TroopShow:getCascadeBoundingBox()
        local rc
        local func = tolua.getcfunction(self, "getCascadeBoundingBox")
        if func then
            rc = func(self)
        end

        rc.origin = {x=rc.x+self.offset_x, y=rc.y}
        rc.size = {width=self.bound_box_width, height=rc.height}
        rc.width=self.bound_box_width
        rc.x=rc.x+self.offset_x
        rc.containsPoint = isPointIn
        return rc
    end
    function TroopShow:SetPower(power)
        local power_item = createInfoItem(_("战斗力"),power)
            :align(display.CENTER,200,0)
            :addTo(info_bg)
        return self
    end
    function TroopShow:SetCitizen(citizen)
        local citizen_item = createInfoItem(_("部队人口"),citizen)
        citizen_item:align(display.CENTER,410-citizen_item:getContentSize().width/2,0)
            :addTo(info_bg)
        return self
    end
    function TroopShow:NewCorps(soldier,soldier_power,star)
        local arrange = soldier_arrange[soldier]
        local corps = Corps.new(soldier, star , arrange.row, arrange.col)
        local label = display.newSprite("back_ground_122x24.png")
            :align(display.CENTER, 0, -50)
            :addTo(corps)
        display.newSprite("dragon_strength_27x31.png"):pos(10,label:getContentSize().height/2)
            :addTo(label)
        UIKit:ttfLabel({
            text = string.formatnumberthousands(soldier_power),
            size = 18,
            color = 0xffedae,
        }):align(display.CENTER,label:getContentSize().width/2,label:getContentSize().height/2)
            :addTo(label)
        return corps
    end
    function TroopShow:SetSoldiers(soldiers)
        self.soldiers = soldiers
    end
    function TroopShow:GetSoldiers()
        return self.soldiers
    end
    function TroopShow:RemoveAllSoldierCrops()
        if self.soldier_crops then
            for i,v in ipairs(self.soldier_crops) do
                v:removeFromParent(true)
            end
        end
        self.offset_x = 0
        self.bound_box_width = grass_width
    end
    function TroopShow:ShowOrRefreasTroops(soldiers)
        -- 按兵种战力排序
        table.sort(soldiers, function(a, b)
            return a.power > b.power
        end)

        -- 更新
        self:SetSoldiers(soldiers)
        self:RemoveAllSoldierCrops()
        local y  = 110
        local x = 681
        local total_power , total_weight, total_citizen =0,0,0
        self.soldier_crops = {}
        for index,v in pairs(soldiers) do
            local corp = self:NewCorps(v.soldier_type,v.power,v.soldier_star):addTo(self,2)
            if v.soldier_type ~= "catapult" and v.soldier_type ~= "ballista" and v.soldier_type ~= "meatWagon" then
                corp:PlayAnimation("idle_90")
            else
                corp:PlayAnimation("move_90")
            end
            table.insert(self.soldier_crops,corp)
            x = x - soldier_ani_width[v.soldier_type]

            corp:pos(x,y)
            total_power = total_power + v.power
            total_weight = total_weight + v.soldier_weight
            total_citizen = total_citizen + v.soldier_citizen
        end
        self:RefreshScrollNode(x)
        info_bg:removeAllChildren()
        self:SetPower(total_power)
        self:SetCitizen(total_citizen)
    end

    return TroopShow
end
function GameUIHelpDefence:DragonPart()
    local dragon = self.dragon

    local dragon_frame = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_CENTER, window.left+47,window.top-425)
        :addTo(self:GetView())

    local dragon_bg = display.newSprite("dragon_bg_114x114.png")
        :align(display.LEFT_CENTER, 7,dragon_frame:getContentSize().height/2)
        :addTo(dragon_frame)
    local dragon_img = cc.ui.UIImage.new(UILib.dragon_head[dragon.type])
        :align(display.CENTER, dragon_bg:getContentSize().width/2, dragon_bg:getContentSize().height/2+5)
        :addTo(dragon_bg)
    local box_bg = display.newSprite("box_426X126.png")
        :align(display.LEFT_CENTER, dragon_frame:getContentSize().width, dragon_frame:getContentSize().height/2)
        :addTo(dragon_frame)
    -- 龙，等级
    local dragon_name = UIKit:ttfLabel({
        text = Localize.dragon[dragon.type].."（LV ".. dragon.level..")",
        size = 22,
        color = 0x514d3e,
    }):align(display.LEFT_CENTER,10,100)
        :addTo(box_bg)
    -- 龙活力
    UIKit:ttfLabel({
        text = _("生命值"),
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_CENTER,10,60)
        :addTo(box_bg)
    local dragon_vitality = UIKit:ttfLabel({
        text = string.formatnumberthousands(dragon.hp),
        size = 20,
        color = 0x514d3e,
    }):align(display.RIGHT_CENTER,416,60)
        :addTo(box_bg)

    -- 龙力量
    UIKit:ttfLabel({
        text = _("力量"),
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_CENTER,10,30)
        :addTo(box_bg)
    local dragon_power = UIKit:ttfLabel({
        text = string.formatnumberthousands(DataUtils:getDragonTotalStrengthFromJson(dragon.star,dragon.level,dragon.skills,dragon.equipments)),
        size = 20,
        color = 0x514d3e,
    }):align(display.RIGHT_CENTER,416,30)
        :addTo(box_bg)

end
function GameUIHelpDefence:PlayerPart()
    local player = self.details.player
    local view = self:GetView()
    local head_frame = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_CENTER, window.left+47,window.top-565)
        :addTo(view)

    UIKit:GetPlayerCommonIcon(player.icon):addTo(head_frame):align(display.CENTER, head_frame:getContentSize().width/2, head_frame:getContentSize().height/2)

    local title_bg = display.newScale9Sprite("title_blue_430x30.png",0,0,cc.size(412,30),cc.rect(10,10,410,10))
        :align(display.LEFT_CENTER,
            head_frame:getPositionX() + head_frame:getContentSize().width + 10 ,
            head_frame:getPositionY() + head_frame:getContentSize().height/2 - 15)
        :addTo(view)
    UIKit:ttfLabel({
        text = player.name,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,10,title_bg:getContentSize().height/2)
        :addTo(title_bg)

    UIKit:createLineItem(
        {
            width = 395,
            text_1 = _("战斗力"),
            text_2 = string.formatnumberthousands(player.power),
        }
    ):align(display.LEFT_CENTER,head_frame:getPositionX() + head_frame:getContentSize().width + 20 , head_frame:getPositionY() - 20)
        :addTo(view)
    UIKit:createLineItem(
        {
            width = 395,
            text_1 = _("等级"),
            text_2 = User:GetPlayerLevelByExp(player.levelExp),
        }
    ):align(display.LEFT_CENTER,head_frame:getPositionX() + head_frame:getContentSize().width + 20 , head_frame:getPositionY() - head_frame:getContentSize().height/2)
        :addTo(view)

end
return GameUIHelpDefence






